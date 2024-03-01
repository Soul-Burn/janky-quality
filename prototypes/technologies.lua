local data_util = require("__flib__/data-util")
local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

for _, technology in pairs(data.raw.technology) do
    if technology.effects then
        local new_effects = {}
        for _, effect in pairs(technology.effects) do
            if effect.type ==  "turret-attack" and not libq.forbids_quality(effect.turret_id) then
                for _, quality in pairs(libq.qualities) do
                    if quality.level ~= 1 then
                        local ta_effect = table.deepcopy(effect)
                        ta_effect.turret_id = libq.name_with_quality(ta_effect.turret_id, quality)
                        table.insert(new_effects, ta_effect)
                    end
                end
            end
        end
        lib.table_extend(technology.effects, new_effects)
    end
end

local default_recipes, _ = lib.partition_array(data.raw.recipe, function(recipe)
    if recipe.normal then
        return recipe.normal.enabled ~= false
    end
    return recipe.enabled ~= false
end)

lib.add_prototype {
    effects = lib.map(default_recipes, function(recipe)
        return { type = "unlock-recipe", recipe = recipe.name }
    end),
    icon = "__core__/graphics/empty.png",
    icon_size = 1,
    enabled = true,
    hidden = true,
    name = "jq_default_recipes",
    type = "technology",
    unit = { count = 1, ingredients = {}, time = 1 },
}

lib.flush_prototypes()

local recipe_category_to_slots = libq.get_recipe_category_to_slots()

local quality_module_level_to_quality_modules = { }

for _, quality_module in pairs(libq.quality_modules) do
    while quality_module.mod_level > #quality_module_level_to_quality_modules do
        table.insert(quality_module_level_to_quality_modules, {})
    end
end

for _, quality_module in pairs(libq.quality_modules) do
    for i, group in pairs(quality_module_level_to_quality_modules) do
        if quality_module.mod_level <= i and quality_module.mod_quality <= libq.quality_modules[i].max_quality then
            table.insert(group, quality_module)
            break
        end
    end
end

for _, technology in pairs(data.raw.technology) do
    local recipes = {}
    for _, effect in pairs(technology.effects or {}) do
        if effect.type == "unlock-recipe" then
            table.insert(recipes, effect.recipe)
        end
    end
    if #recipes > 0 then
        local all_seen = util.list_to_map(recipes)

        for qm_level, quality_modules in pairs(quality_module_level_to_quality_modules) do
            local new_recipes = {}

            local function add_recipe(name)
                if data.raw.recipe[name] and not all_seen[name] then
                    all_seen[name] = true
                    table.insert(new_recipes, name)
                end
            end

            for _, recipe in pairs(recipes) do
                local slots_list = recipe_category_to_slots[data.raw.recipe[recipe].category or "crafting"] or {}
                for q_level = 1, libq.quality_modules[qm_level].max_quality do
                    local name = libq.name_with_quality(recipe, q_level)
                    add_recipe(name)
                    for module_count, _ in pairs(slots_list) do
                        for _, quality_module in pairs(quality_modules) do
                            add_recipe(libq.name_with_quality_module(name, module_count, quality_module))
                        end
                    end
                end

                local entity_prototype = data.raw["assembling-machine"][recipe] or data.raw["furnace"][recipe] or data.raw["mining-drill"][recipe]
                local slots = entity_prototype and entity_prototype.module_specification and entity_prototype.module_specification.module_slots
                for module_count = 1, (slots or 0) do
                    for i = 1, qm_level do
                        for _, quality_module in pairs(quality_module_level_to_quality_modules[i]) do
                            for q_level = 1, libq.quality_modules[qm_level].max_quality do
                                local qem_name = libq.name_with_quality(libq.name_with_quality_module(recipe, module_count, quality_module), q_level)
                                add_recipe("programming-quality-" .. qem_name)
                                add_recipe("deprogramming-quality-" .. qem_name)
                            end
                        end
                    end
                end
            end

            lib.add_prototype {
                effects = lib.map(new_recipes, function(recipe)
                    return { type = "unlock-recipe", recipe = recipe }
                end),
                icons = data_util.create_icons(technology),
                hidden = true,
                name = technology.name .. "-with-quality-" .. qm_level,
                type = "technology",
                unit = { count = 1, ingredients = {}, time = 1 },
            }
        end
    end
end

lib.flush_prototypes()
