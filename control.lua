require("util")
local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

local proximity_distance_setting_name = "jq-indicator-proximity-distance"
local proximity_tick_setting_name = "jq-indicator-proximity-tick"

local function make_area(bounding_box, radius)
    local bb = bounding_box
    local center_x, center_y = (bb.right_bottom.x + bb.left_top.x) / 2, (bb.right_bottom.y + bb.left_top.y) / 2
    return { { center_x - radius, center_y - radius }, { center_x + radius, center_y + radius } }
end

local function should_set_resource(quality_module, res_qm_name)
    if quality_module and res_qm_name then
        return quality_module.name > res_qm_name
    end
    return quality_module or res_qm_name
end

local function set_resources_around_miner(entity, module_count, quality_module)
    local search_area = make_area(entity.bounding_box, entity.prototype.mining_drill_radius)
    for _, resource in pairs(entity.surface.find_entities_filtered { area = search_area, type = "resource" }) do
        if string.match(resource.prototype.resource_category, "basic%-solid") then
            local name, _, res_qm_name = libq.split_quality_modules(resource.name)
            if not name then
                name = resource.name
            end
            if quality_module then
                name = libq.name_with_quality_module(name, module_count, quality_module)
            end
            if should_set_resource(quality_module, res_qm_name) then
                local new_resource = resource.surface.create_entity { name = name, amount = resource.amount, position = resource.position }
                new_resource.graphics_variation = resource.graphics_variation
                resource.destroy()
            end
        end
    end
end

local function handle_removal(event)
    local entity = event.entity
    if not entity then
        return
    end
    if entity.type == "mining-drill" then
        set_resources_around_miner(entity)

        local search_area = make_area(entity.bounding_box, entity.prototype.mining_drill_radius + 1)
        for _, miner in pairs(entity.surface.find_entities_filtered { area = search_area, type = "mining-drill" }) do
            if miner ~= entity then
                local _, found_slots, found_module = libq.split_quality_modules(libq.name_without_quality(miner.name))
                if found_slots and found_module then
                    local qm = lib.find_by_prop(libq.quality_modules, "name", found_module)
                    set_resources_around_miner(miner, found_slots, qm)
                end
            end
        end
    end
end

local function draw_quality_on_entity(entity)
    local ids = {}
    local found_quality = libq.find_quality(entity.name)
    if found_quality ~= 1 then
        local bb = entity.bounding_box
        local off_x = (bb.left_top.x - bb.right_bottom.x) / 2 + 0.15
        local off_y = (bb.right_bottom.y - bb.left_top.y) / 2 - 0.15
        table.insert(ids, rendering.draw_sprite {
            target = entity,
            surface = entity.surface,
            sprite = ("jq_quality_icon_" .. found_quality),
            target_offset = { off_x, off_y },
            only_in_alt_mode = true,
        })
    end
    local _, found_slots, found_module = libq.split_quality_modules(libq.name_without_quality(entity.name))
    if found_slots and found_module then
        found_slots = tonumber(found_slots)
        local bb = entity.bounding_box
        local off_y = (bb.right_bottom.y - bb.left_top.y) * 0.25
        for i = 1, found_slots do
            local off_x = 0.5 * (i - 0.5 * found_slots - 0.5)
            table.insert(ids, rendering.draw_sprite {
                target = entity,
                surface = entity.surface,
                sprite = ("jq_quality_module_icon_" .. found_module),
                target_offset = { off_x, off_y },
                only_in_alt_mode = true,
            })
        end
    end
    return ids
end

local function handle_build(event)
    local ent = event.created_entity or event.entity or event.destination
    if not ent then
        return
    end

    if settings.global[proximity_distance_setting_name].value == -1 then
        draw_quality_on_entity(ent)
    end

    if ent.type == "mining-drill" then
        local _, found_slots, found_module = libq.split_quality_modules(libq.name_without_quality(ent.name))
        if found_slots and found_module then
            local qm = lib.find_by_prop(libq.quality_modules, "name", found_module)
            set_resources_around_miner(ent, found_slots, qm)
        end
    end
end

for _, event in pairs { "on_built_entity", "on_robot_built_entity", "on_entity_cloned", "script_raised_built", "script_raised_revive" } do
    script.on_event(defines.events[event], handle_build)
end

for _, event in pairs { "on_entity_died", "on_player_mined_entity", "on_robot_mined_entity", "script_raised_destroy" } do
    script.on_event(defines.events[event], handle_removal, { { filter = "type", type = "mining-drill" } })
end

local function research_event(event)
    if event.research and event.research.name:match("%-with%-quality%-") then
        return
    end
    local technologies = (event.force or event.research.force).technologies
    local max_level = 0
    for i, tech in pairs { "quality-module", "quality-module-2", "quality-module-3" } do
        if technologies[tech].researched then
            max_level = i
        end
    end
    for tech_name, technology in pairs(technologies) do
        if technology.researched then
            for i = 1, max_level do
                local tech_with_quality = technologies[tech_name .. "-with-quality-" .. i]
                if tech_with_quality then
                    tech_with_quality.researched = true
                end
            end
        end
    end
end

script.on_event(defines.events.on_research_finished, research_event)
script.on_event(defines.events.on_technology_effects_reset, research_event)

local function inventory_getter(name)
    return function(entity)
        return entity.get_inventory(name)
    end
end

local function module_inventory_getter(entity)
    return entity.get_module_inventory()
end

local function transfer_from_entity_to_entity_or_player_or_spill(old_entity, new_entity, player)
    local inventory = player.get_main_inventory()
    for _, getter in pairs { inventory_getter(defines.inventory.assembling_machine_input), inventory_getter(defines.inventory.assembling_machine_output), module_inventory_getter } do
        local new_inventory = getter(new_entity)
        for item, count in pairs(getter(old_entity).get_contents()) do
            local count_left = count - new_inventory.insert { name = item, count = count }
            if count_left > 0 then
                count_left = count_left - inventory.insert { name = item, count = count_left }
                if count_left > 0 then
                    player.surface.spill_item_stack(player.position, { name = item, count = count_left }, true, player.force, false)
                end
            end
        end
    end
end

local allowed_quality_module_types = util.list_to_map { "furnace", "assembling-machine", "mining-drill" }

local function selected_upgrade(event)
    local quality = libq.find_quality(event.item)
    local tier = string.match(libq.name_without_quality(event.item), "quality%-module%-(%d)")
    if not tier or not quality then
        return
    end
    local player = game.get_player(event.player_index)
    local quality_module = lib.find_by_prop(libq.quality_modules, "name", tier .. "@" .. quality)
    if not quality_module then
        player.create_local_flying_text { text = { "jq.missing-quality-module-upgrade", game.item_prototypes[event.item].localised_name }, create_at_cursor = true }
        player.play_sound { path = "utility/cannot_build" }
        return
    end
    local inventory = player.get_main_inventory()
    local any_modified = false
    local any_cant_build = false
    for _, entity in pairs(event.entities) do
        local is_crafter = entity.type ~= "mining-drill"
        local can_reach = player.can_reach_entity(entity)
        if not can_reach then
            player.create_local_flying_text { text = { "cant-reach" }, position = entity.position }
            any_cant_build = true
        end
        if not allowed_quality_module_types[entity.type] or libq.split_quality_modules(libq.name_without_quality(entity.name)) or not can_reach then
            goto continue
        end
        local module_inventory = entity.get_module_inventory()
        if not module_inventory or #module_inventory == 0 then
            goto continue
        end

        local empty_slots = #module_inventory
        for existing_module, count in pairs(module_inventory.get_contents()) do
            local module_prototype = game.item_prototypes[existing_module]
            empty_slots = empty_slots - count
            if module_prototype.module_effects and module_prototype.module_effects.speed and module_prototype.module_effects.speed.bonus and module_prototype.module_effects.speed.bonus > 0 then
                player.create_local_flying_text { text = { "jq.cant-speed-quality" }, position = entity.position }
                goto continue
            end
        end
        local module_start, module_end, module_inc = empty_slots, 1, -1
        if event.name == defines.events.on_player_alt_selected_area then
            module_start, module_end, module_inc = 1, empty_slots, 1
        end
        local new_machine_name, module_count
        for i = module_start, module_end, module_inc do
            new_machine_name = libq.name_with_quality(
                libq.name_with_quality_module(libq.name_without_quality(entity.name), i, quality_module),
                libq.find_quality(entity.name)
            )
            if game.entity_prototypes[new_machine_name] then
                module_count = i
                break
            end
        end
        if not new_machine_name or not module_count then
            player.create_local_flying_text { text = { "jq.too-many-existing-modules" }, position = entity.position }
            any_cant_build = true
            goto continue
        end
        if inventory.get_item_count(event.item) + player.cursor_stack.count < module_count then
            player.create_local_flying_text { text = { "jq.not-enough-modules" }, position = entity.position }
            any_cant_build = true
            break
        end
        if player.cursor_stack.count >= module_count then
            player.cursor_stack.count = player.cursor_stack.count - module_count
        else
            inventory.remove { name = event.item, count = module_count - player.cursor_stack.count }
            if player.cursor_stack.valid_for_read then
                player.cursor_stack.count = 0
            end
            local new_stack, inventory_slot = inventory.find_item_stack(event.item)
            if new_stack then
                player.cursor_stack.swap_stack(new_stack)
                player.hand_location = { inventory = defines.inventory.character_main, slot = inventory_slot }
            end
        end
        local recipe = is_crafter and entity.get_recipe()
        local new_recipe_name
        if recipe then
            if libq.is_name_with_quality_forbidden(recipe.category) then
                new_recipe_name = recipe.name
            else
                local found_quality = libq.find_quality(recipe.name)
                new_recipe_name = libq.name_with_quality(libq.name_without_quality(recipe.name), found_quality)
                if found_quality < quality_module.max_quality then
                    new_recipe_name = libq.name_with_quality_module(new_recipe_name, module_count, quality_module)
                end
            end
        end
        local new_entity = entity.surface.create_entity {
            name = new_machine_name,
            position = entity.position,
            direction = entity.direction,
            recipe = new_recipe_name,
            force = player.force,
            player = player,
            raise_built = true,
            create_build_effect_smoke = false,
        }
        if is_crafter then
            new_entity.crafting_progress = entity.crafting_progress
            if entity.type == "furnace" and recipe then
                local new_inventory = new_entity.get_inventory(defines.inventory.assembling_machine_input)
                for _, part in pairs(recipe.ingredients) do
                    new_inventory.insert { name = part.name, count = part.amount }
                end
            end
            transfer_from_entity_to_entity_or_player_or_spill(entity, new_entity, player)
            for fluid, amount in pairs(entity.get_fluid_contents()) do
                new_entity.insert_fluid { name = fluid, amount = amount }
            end
        else
            new_entity.mining_progress = entity.mining_progress
        end
        if player.opened == entity then
            player.opened = new_entity
        end
        entity.destroy { raise_destroy = true }
        new_entity.update_connections()
        new_entity.rotate()
        new_entity.rotate { reverse = true }
        any_modified = true
        :: continue ::
    end
    if any_modified then
        player.play_sound { path = "utility/inventory_move" }
    end
    if any_cant_build then
        player.play_sound { path = "utility/cannot_build" }
    end
end

local function selected_downgrade(event)
    if not string.match(libq.name_without_quality(event.item), "quality%-module%-(%d)") then
        return
    end

    local player = game.get_player(event.player_index)
    local any_modified = false
    local any_cant_build = false
    for _, entity in pairs(event.entities) do
        local can_reach = player.can_reach_entity(entity)
        if not can_reach then
            player.create_local_flying_text { text = { "cant-reach" }, position = entity.position }
            any_cant_build = true
        end
        local is_crafter = entity.type ~= "mining-drill"
        local base_entity_name, module_count, quality_module = libq.split_quality_modules(libq.name_without_quality(entity.name))
        if allowed_quality_module_types[entity.type] and quality_module and player.can_reach_entity(entity) then
            local qm_name = libq.qm_name_to_module_item(quality_module)
            module_count = tonumber(module_count)
            local modules_inserted = player.insert { name = qm_name, count = module_count }
            if modules_inserted < module_count then
                if modules_inserted > 0 then
                    player.remove_item { name = qm_name, count = modules_inserted }
                end
                player.create_local_flying_text { text = { "inventory-full-message.main" }, create_at_cursor = true }
                player.play_sound { path = "utility/console_message" }
                any_cant_build = true
                break
            end
            local recipe = is_crafter and entity.get_recipe()
            local new_recipe_name
            if recipe then
                if string.match(recipe.name, "^programming%-quality%-") then
                    new_recipe_name = recipe.name
                else
                    new_recipe_name = libq.split_quality_modules(recipe.name) or recipe.name
                end
            end
            local new_entity = entity.surface.create_entity {
                name = libq.name_with_quality(base_entity_name, libq.find_quality(entity.name)),
                position = entity.position,
                direction = entity.direction,
                recipe = new_recipe_name,
                force = player.force,
                player = player,
                raise_built = true,
                create_build_effect_smoke = false,
            }
            if is_crafter then
                new_entity.crafting_progress = entity.crafting_progress
                if entity.type == "furnace" and recipe then
                    local new_inventory = new_entity.get_inventory(defines.inventory.assembling_machine_input)
                    for _, part in pairs(recipe.ingredients) do
                        new_inventory.insert { name = part.name, count = part.amount }
                    end
                end
                transfer_from_entity_to_entity_or_player_or_spill(entity, new_entity, player)
                for fluid, amount in pairs(entity.get_fluid_contents()) do
                    new_entity.insert_fluid { name = fluid, amount = amount }
                end
            else
                new_entity.mining_progress = entity.mining_progress
            end
            if player.opened == entity then
                player.opened = new_entity
            end
            entity.destroy { raise_destroy = true }
            new_entity.update_connections()
            new_entity.rotate()
            new_entity.rotate { reverse = true }
            any_modified = true
        end
    end
    if any_modified then
        player.play_sound { path = "utility/inventory_move" }
    end
    if any_cant_build then
        player.play_sound { path = "utility/cannot_build" }
    end
end

script.on_event(defines.events.on_player_selected_area, selected_upgrade)
script.on_event(defines.events.on_player_alt_selected_area, selected_upgrade)
script.on_event(defines.events.on_player_reverse_selected_area, selected_downgrade)

script.on_init(function()
    for _, force in pairs(game.forces) do
        force.technologies["jq_default_recipes"].researched = true
    end
end)

local update_block_size = 16

local function get_chunk_top_left(pos, x_off, y_off)
    return { pos.x - pos.x % update_block_size + x_off, pos.y - pos.y % update_block_size + y_off }
end

local function area_from_top_left(top_left)
    return { top_left, { top_left[1] + update_block_size, top_left[2] + update_block_size } }
end

local debug_cycles = false

local function find_chunks(index, distance)
    local half_length = math.ceil(distance / update_block_size)
    local side_length = half_length * 2 + 1

    local x_off = (index % side_length - half_length) * update_block_size
    local y_off = (math.floor(index / side_length) - half_length) * update_block_size

    local chunks = {}
    for _, player in pairs(game.players) do
        if player.connected then
            if player.selected then
                table.insert(chunks, { player.surface, get_chunk_top_left(player.selected.position, x_off, y_off) })
            end
            table.insert(chunks, { player.surface, get_chunk_top_left(player.position, x_off, y_off) })
        end
    end
    return chunks
end

local function do_for_index(overlay_data, index, distance, debug_data)
    if index == 0 then
        for _, overlays in pairs(overlay_data.last_cycle) do
            for _, overlay in pairs(overlays) do
                rendering.destroy(overlay)
                if debug_data then
                    debug_data.destroyed = debug_data.destroyed + 1
                end
            end
        end
        overlay_data.last_cycle = overlay_data.current_cycle
        overlay_data.current_cycle = {}
        overlay_data.visited_chunks = {}
    end
    local entities = {}
    local forces = {}
    for _, force in pairs(game.forces) do
        table.insert(forces, force)
    end
    for _, chunk in pairs(find_chunks(index, distance)) do
        local surface = chunk[1]
        local top_left = chunk[2]
        local area = area_from_top_left(top_left)
        local chunk_name = surface.index .. ":" .. top_left[1] .. "," .. top_left[2]
        if not overlay_data.visited_chunks[chunk_name] then
            overlay_data.visited_chunks[chunk_name] = true
            for _, entity in pairs(surface.find_entities_filtered { force = forces, area = area }) do
                if entity.unit_number then
                    entities[entity.unit_number] = entity
                end
            end
            if debug_data then
                table.insert(global.rects, rendering.draw_rectangle { surface = surface, color = { 1, 0, 0, 0 }, left_top = area[1], right_bottom = area[2] })
            end
        end
    end
    local last_cycle = overlay_data.last_cycle
    local current_cycle = overlay_data.current_cycle
    for unit_number, entity in pairs(entities) do
        if not current_cycle[unit_number] then
            current_cycle[unit_number] = last_cycle[unit_number] or draw_quality_on_entity(entity)
            if debug_data then
                if current_cycle[unit_number] and not last_cycle[unit_number] and next(current_cycle[unit_number]) then
                    debug_data.created = debug_data.created + 1
                    game.print("Created entity: " .. entity.name .. " @ " .. entity.gps_tag)
                end
            end
            last_cycle[unit_number] = nil
        end
    end
end

script.on_event(defines.events.on_tick, function(event)
    local ticks_per_cycle = settings.global[proximity_tick_setting_name].value
    local distance = settings.global[proximity_distance_setting_name].value
    if distance > -1 then
        global.overlay_data = global.overlay_data or {}
        local overlay_data = global.overlay_data
        overlay_data.current_cycle = overlay_data.current_cycle or {}
        overlay_data.last_cycle = overlay_data.last_cycle or {}
        overlay_data.visited_chunks = overlay_data.visited_chunks or {}

        local debug_data
        if debug_cycles then
            for _, id in pairs(global.rects or {}) do
                rendering.destroy(id)
            end
            global.rects = {}
            debug_data = { created = 0, destroyed = 0 }
        end

        local half_length = math.ceil(distance / update_block_size)
        local side_length = half_length * 2 + 1
        local cycle_length = side_length * side_length
        local cycle_frames_per_tick = cycle_length / ticks_per_cycle

        local current_float = (event.tick % (cycle_length * ticks_per_cycle)) * cycle_frames_per_tick
        local current = math.floor(current_float - 0.0001)
        local previous = math.ceil(current_float - cycle_frames_per_tick)

        for index = previous, current do
            do_for_index(overlay_data, index % cycle_length, distance, debug_data)
        end

        if debug_cycles and (debug_data.created > 0 or debug_data.destroyed > 0) then
            game.print("Created: " .. debug_data.created .. " Destroyed: " .. debug_data.destroyed)
        end
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting == proximity_distance_setting_name then
        local distance = settings.global[proximity_distance_setting_name].value
        rendering.clear("janky-quality")
        if distance == -1 then
            local forces = {}
            for _, force in pairs(game.forces) do
                if #force.players > 0 then
                    table.insert(forces, force)
                end
            end

            for _, surface in pairs(game.surfaces) do
                for _, entity in pairs(surface.find_entities_filtered { force = forces }) do
                    draw_quality_on_entity(entity)
                end
            end
        end
    end
end)
