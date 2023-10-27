require("util")
local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

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
    if entity == nil then
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

local function handle_build(event)
    local ent = event.created_entity or event.entity or event.destination
    if ent == nil then
        return
    end
    local found_quality = libq.find_quality(ent.name)
    if found_quality ~= 1 then
        local bb = ent.bounding_box
        local off_x = (bb.left_top.x - bb.right_bottom.x) / 2 + 0.15
        local off_y = (bb.right_bottom.y - bb.left_top.y) / 2 - 0.15
        rendering.draw_sprite { target = ent, surface = ent.surface, sprite = ("jq_quality_icon_" .. found_quality), target_offset = { off_x, off_y }, only_in_alt_mode = true }
    end
    local _, found_slots, found_module = libq.split_quality_modules(libq.name_without_quality(ent.name))
    if found_slots and found_module then
        found_slots = tonumber(found_slots)
        local bb = ent.bounding_box
        local off_y = (bb.right_bottom.y - bb.left_top.y) * 0.25
        for i = 1, found_slots do
            local off_x = 0.5 * (i - 0.5 * found_slots - 0.5)
            rendering.draw_sprite { target = ent, surface = ent.surface, sprite = ("jq_quality_module_icon_" .. found_module), target_offset = { off_x, off_y }, only_in_alt_mode = true }
        end
    end

    if ent.type == "mining-drill" then
        if found_slots and found_module then
            local qm = lib.find_by_prop(libq.quality_modules, "name", found_module)
            set_resources_around_miner(ent, found_slots, qm)
        end
    end
end

for _, event in pairs({ "on_built_entity", "on_robot_built_entity", "on_entity_cloned", "script_raised_built", "script_raised_revive" }) do
    script.on_event(defines.events[event], handle_build)
end

for _, event in pairs({ "on_entity_died", "on_player_mined_entity", "on_robot_mined_entity", "script_raised_destroy" }) do
    script.on_event(defines.events[event], handle_removal, { { filter = "type", type = "mining-drill" } })
end

local function get_max_quality_mod_level(force)
    if force.technologies["quality-module-3"].researched then
        return 3
    end
    if force.technologies["quality-module-2"].researched then
        return 2
    end
    if force.technologies["quality-module"].researched then
        return 1
    end
    return 0
end

local function quality_unlock(force)
    local max_quality_level = get_max_quality_mod_level(force)
    for _, recipe in pairs(force.recipes) do
        local assembler_name = string.match(recipe.name, "programming%-quality%-(.+)%-qum%-")
        if not recipe.enabled and assembler_name and force.recipes[assembler_name] and force.recipes[assembler_name].enabled then
            local _, _, found_module = libq.split_quality_modules(libq.name_without_quality(recipe.name))
            local level, _ = string.match(found_module, "(%d)@(%d)")
            if tonumber(level) <= max_quality_level then
                recipe.enabled = true
            end
        end
    end
end

local function handle_technology_rest(event)
    quality_unlock(event.force)
end

local function handle_research(event)
    local tech = event.research
    local force = tech.force

    if string.match(tech.name, "quality%-module") then
        quality_unlock(force)
    end

    local max_quality_level = get_max_quality_mod_level(force)
    if tech.effects then
        for _, effect in pairs(tech.effects) do
            if effect.type == "unlock-recipe" then
                for _, quality in pairs(libq.qualities) do
                    local name = libq.name_with_quality(effect.recipe, quality)
                    local recipe = force.recipes[name]
                    if not recipe then
                        break
                    end
                    recipe.enabled = true
                    (function()
                        for _, quality_module in pairs(libq.quality_modules) do
                            for _, module_count in pairs(libq.slot_counts) do
                                local q_recipe = force.recipes[libq.name_with_quality_module(name, module_count, quality_module)]
                                if not q_recipe then
                                    return
                                end
                                q_recipe.enabled = true
                                local qem_name = libq.name_with_quality(libq.name_with_quality_module(effect.recipe, module_count, quality_module), quality)
                                if quality_module.mod_level <= max_quality_level and force.recipes["programming-quality-" .. qem_name] then
                                    force.recipes["programming-quality-" .. qem_name].enabled = true
                                    force.recipes["deprogramming-quality-" .. qem_name].enabled = true
                                end
                            end
                        end
                    end)()
                end
            end
        end
    end
end

script.on_event(defines.events.on_research_finished, handle_research)
script.on_event(defines.events.on_technology_effects_reset, handle_technology_rest)

local function transfer_from_entity_to_entity_or_player_or_spill(old_entity, new_entity, player)
    local inventory = player.get_main_inventory()
    for _, define in pairs({ defines.inventory.assembling_machine_input, defines.inventory.assembling_machine_output }) do
        local new_inventory = new_entity.get_inventory(define)
        for item, count in pairs(old_entity.get_inventory(define).get_contents()) do
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

local allowed_quality_module_types = util.list_to_map({ "furnace", "assembling-machine", "mining-drill" })

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
        if allowed_quality_module_types[entity.type] and not libq.split_quality_modules(libq.name_without_quality(entity.name)) and can_reach then
            local module_inventory = entity.get_module_inventory()
            if module_inventory and module_inventory.is_empty() then
                if inventory.get_item_count(event.item) + player.cursor_stack.count < #module_inventory then
                    player.create_local_flying_text { text = { "jq.not-enough-modules" }, position = entity.position }
                    any_cant_build = true
                    break
                end
                if player.cursor_stack.count >= #module_inventory then
                    player.cursor_stack.count = player.cursor_stack.count - #module_inventory
                else
                    inventory.remove({ name = event.item, count = #module_inventory - player.cursor_stack.count })
                    player.cursor_stack.count = 0
                    local new_stack, inventory_slot = inventory.find_item_stack(event.item)
                    if new_stack then
                        player.cursor_stack.swap_stack(new_stack)
                        player.hand_location = { inventory = defines.inventory.character_main, slot = inventory_slot }
                    end
                end
                local recipe = is_crafter and entity.get_recipe()
                local new_entity = entity.surface.create_entity {
                    name = libq.name_with_quality(
                            libq.name_with_quality_module(libq.name_without_quality(entity.name), #module_inventory, quality_module),
                            libq.find_quality(entity.name)
                    ),
                    position = entity.position,
                    direction = entity.direction,
                    recipe = recipe and libq.name_with_quality_module(
                            libq.name_with_quality(libq.name_without_quality(recipe.name), libq.find_quality(recipe.name)),
                            #module_inventory, quality_module
                    ) or nil,
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
                else
                    new_entity.mining_progress = entity.mining_progress
                end
                if player.opened == entity then
                    player.opened = new_entity
                end
                entity.destroy { raise_destroy = true }
                any_modified = true
            end
        end
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
        local entity_name, module_count, quality_module = libq.split_quality_modules(libq.name_without_quality(entity.name))
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
            local new_entity = entity.surface.create_entity {
                name = entity_name,
                position = entity.position,
                direction = entity.direction,
                recipe = recipe and libq.split_quality_modules(recipe.name) or nil,
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
            else
                new_entity.mining_progress = entity.mining_progress
            end
            if player.opened == entity then
                player.opened = new_entity
            end
            entity.destroy { raise_destroy = true }
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
script.on_event(defines.events.on_player_reverse_selected_area, selected_downgrade)
