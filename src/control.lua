lib = require("__janky-quality__/lib/lib")

--on_entity_died,
--on_player_mined_entity,
--on_robot_mined_entity,
--script_raised_destroy,

local function handle_build(event)
    local ent = event.created_entity or event.entity or event.destination
    if ent == nil then
        return
    end
    local found_quality = lib.find_quality(ent.name)
    if found_quality ~= 1 then
        local bb = ent.bounding_box
        local off_x = (bb.left_top.x - bb.right_bottom.x) / 2 + 0.15
        local off_y = (bb.right_bottom.y - bb.left_top.y) / 2 - 0.15
        rendering.draw_sprite { target = ent, surface = ent.surface, sprite = ("jq_quality_icon_" .. found_quality), target_offset = { off_x, off_y }, only_in_alt_mode = true }
    end
    local _, found_slots, found_module = lib.split_quality_modules(lib.name_without_quality(ent.name))
    if found_slots and found_module then
        found_slots = tonumber(found_slots)
        local bb = ent.bounding_box
        local off_y = (bb.right_bottom.y - bb.left_top.y) * 0.25
        for i = 1, found_slots do
            local off_x = 0.5 * (i - 0.5 * found_slots - 0.5)
            rendering.draw_sprite { target = ent, surface = ent.surface, sprite = ("jq_quality_module_icon_" .. found_module), target_offset = { off_x, off_y }, only_in_alt_mode = true }
        end
    end
end

local events = { "on_built_entity", "on_robot_built_entity", "on_entity_cloned", "script_raised_built", "script_raised_revive" }
for _, event in pairs(events) do
    script.on_event(defines.events[event], handle_build)
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
            local _, _, found_module = lib.split_quality_modules(lib.name_without_quality(recipe.name))
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
                for _, quality in pairs(lib.qualities) do
                    local name = lib.name_with_quality(effect.recipe, quality)
                    force.recipes[name].enabled = true
                    for _, quality_module in pairs(lib.quality_modules) do
                        for _, module_count in pairs(lib.slot_counts) do
                            force.recipes[lib.name_with_quality_module(name, module_count, quality_module)].enabled = true
                            local qem_name = lib.name_with_quality(lib.name_with_quality_module(effect.recipe, module_count, quality_module), quality)
                            if quality_module.mod_level <= max_quality_level and force.recipes["programming-quality-" .. qem_name] then
                                force.recipes["programming-quality-" .. qem_name].enabled = true
                                force.recipes["deprogramming-quality-" .. qem_name].enabled = true
                            end
                        end
                    end
                end
            end
        end
    end
end

script.on_event(defines.events.on_research_finished, handle_research)
script.on_event(defines.events.on_technology_effects_reset, handle_technology_rest)
