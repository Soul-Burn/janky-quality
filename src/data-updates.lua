local data_util = require("__flib__/data-util")

local qualities = {
    { level = 1, modifier = 0, icon = "__janky-quality__/graphics/quality_1.png" },
    { level = 2, modifier = 1, icon = "__janky-quality__/graphics/quality_2.png" },
    { level = 3, modifier = 2, icon = "__janky-quality__/graphics/quality_3.png" },
    { level = 4, modifier = 3, icon = "__janky-quality__/graphics/quality_4.png" },
    { level = 5, modifier = 5, icon = "__janky-quality__/graphics/quality_5.png" },
}

local new_prototypes = {}

for _, quality in pairs(qualities) do
    local sprite = {
        type = "sprite",
        name = "jq_quality_icon_" .. quality.level,
        filename = quality.icon,
        size = 16,
    }
    table.insert(new_prototypes, sprite)
end

local function name_with_quality(name, quality)
    if quality.level == 1 then
        return name
    end
    return name .. "-quality-" .. quality.level
end

local function name_without_quality(name)
    return string.match(name, "(.+)-quality%-%d") or name
end

local function find_quality(name)
    return tonumber(string.match(name, "-quality%-(%d)")) or 1
end

local quality_modules = {
    { name = "1@1", max_quality = 3, modifier = 0.01, icon = "__janky-quality__/graphics/quality_module_1.png" },
    { name = "2@1", max_quality = 4, modifier = 0.0150, icon = "__janky-quality__/graphics/quality_module_2.png" },
}

for _, quality in pairs(qualities) do
    table.insert(quality_modules, {
        name = "3@" .. quality.level,
        max_quality = 5,
        modifier = 0.0248 * (1.0 + 0.3 * quality.modifier),
        icon = "__janky-quality__/graphics/quality_module_3.png",
    })
end

local slot_counts = { 2, 3, 4 }

-- Quality enhancing machines
local function name_with_quality_module(name, module_count, quality_module)
    return name .. "-qm-" .. module_count .. "x" .. quality_module.name
end

table.insert(new_prototypes, { name = "quality-module-programming", type = "recipe-category" })

for _, recipe_category in pairs(data.raw["recipe-category"]) do
    for _, q in pairs(quality_modules) do
        for _, module_count in pairs(slot_counts) do
            table.insert(new_prototypes, { name = name_with_quality_module(recipe_category.name, module_count, q), type = "recipe-category" })
        end
    end
end

(function()
    for _, machine in pairs(data.raw["assembling-machine"]) do
        if machine.module_specification and machine.module_specification.module_slots > 0 then
            for _, q in pairs(quality_modules) do
                local slots = machine.module_specification.module_slots
                local new_machine = data_util.copy_prototype(machine, name_with_quality_module(machine.name, slots, q))
                for i, cat in pairs(new_machine.crafting_categories) do
                    new_machine.crafting_categories[i] = name_with_quality_module(cat, slots, q)
                end
                new_machine.module_specification.module_slots = 0
                table.insert(new_prototypes, new_machine)

                local item = data.raw.item[machine.name]
                local new_item = data_util.copy_prototype(item, name_with_quality_module(machine.name, slots, q))
                new_item.icons = data_util.create_icons(item, { { icon = q.icon, icon_size = 96, scale = 0.25, shift = { 0, 6 } } })
                table.insert(new_prototypes, new_item)
            end
        end
    end
end)()

data:extend(new_prototypes)
new_prototypes = {}

local function copy_and_add_prototype(p, quality)
    local new_p = data_util.copy_prototype(p, name_with_quality(p.name, quality))
    new_p.icons = data_util.create_icons(p, { { icon = quality.icon, icon_size = 16, scale = 1, shift = { -6, 8 } } })
    if new_p.placed_as_equipment_result then
        new_p.placed_as_equipment_result = name_with_quality(p.name, quality)
    end
    table.insert(new_prototypes, new_p)
    return new_p
end

-- Handle items without entities
(function()
    for _, p in pairs(data.raw.item) do
        if p.place_result == nil and p.placed_as_equipment_result == nil then
            for _, quality in pairs(qualities) do
                if quality.level ~= 1 then
                    copy_and_add_prototype(p, quality)
                end
            end
        end
    end
end)()

local all_cat = {
    "accumulator", "artillery-turret", "beacon", "boiler", "burner-generator", "arithmetic-combinator", "decider-combinator", "constant-combinator",
    "container", "logistic-container", "assembling-machine", "rocket-silo", "furnace", "combat-robot", "construction-robot",
    "logistic-robot", "gate", "generator", "heat-interface", "heat-pipe", "inserter", "lab", "lamp", "land-mine", "mining-drill", "offshore-pump",
    "pipe", "pipe-to-ground", "power-switch", "programmable-speaker", "pump", "radar",
    "rail-chain-signal", "rail-signal", "reactor", "roboport", "solar-panel", "storage-tank", "train-stop", "splitter", "transport-belt",
    "underground-belt", "turret", "ammo-turret", "electric-turret", "fluid-turret", "car", "artillery-wagon", "cargo-wagon", "fluid-wagon",
    "locomotive", "spider-vehicle", "wall",
    "active-defense-equipment", "battery-equipment", "belt-immunity-equipment", "energy-shield-equipment", "generator-equipment",
    "movement-bonus-equipment", "night-vision-equipment", "roboport-equipment", "solar-panel-equipment", "capsule", "gun", "ammo", "armor",
    "repair-tool", "tool", "loader", "loader-1x1", "spidertron-remote", "electric-energy-interface"
}

-- Handle items with entities
local function handle_category(category_name, func)
    for _, p in pairs(data.raw[category_name]) do
        for _, quality in pairs(qualities) do
            if quality.level ~= 1 then
                local new_entity = copy_and_add_prototype(p, quality)
                if new_entity.max_health then
                    new_entity.max_health = new_entity.max_health * (1 + 0.3 * quality.modifier)
                end
                if func then
                    if all_cat[category_name] then
                        assert(false, "Category appears twice!")
                    end
                    func(new_entity, quality)
                end
                for _, sub_category in pairs({ "item", "item-with-entity-data", "item-with-inventory" }) do
                    local item = data.raw[sub_category][p.name]
                    if item then
                        copy_and_add_prototype(item, quality)
                        break
                    end
                end
            end
        end
    end
end

handle_category("electric-pole", function(p, quality)
    p.supply_area_distance = p.supply_area_distance + quality.modifier
    p.maximum_wire_distance = p.maximum_wire_distance + 2 * quality.modifier
end)

handle_category("module", function(p, quality)
    if p.limitation then
        local new_limitations = {}
        for _, limitation in pairs(p.limitation) do
            for _, q in pairs(qualities) do
                if q.level ~= 1 then
                    table.insert(new_limitations, name_with_quality(limitation, q))
                end
            end
        end
        for _, limitation in pairs(new_limitations) do
            table.insert(p.limitation, limitation)
        end
    end

    local effect
    if p.category == "productivity" then
        effect = p.effect.productivity
    elseif p.category == "speed" then
        effect = p.effect.speed
    elseif p.category == "effectivity" then
        effect = p.effect.consumption
    end
    if effect then
        effect.bonus = effect.bonus * (1 + 0.3 * quality.modifier)
    end
end)

handle_category("rail-planner", function(p, quality)
    p.place_result = nil
    p.type = "item"
end)

for _, category in pairs(all_cat) do
    handle_category(category, nil)
end

-- Recipes for qualities
(function()
    for _, p in pairs(data.raw.recipe) do
        for _, quality in pairs(qualities) do
            if quality.level ~= 1 then
                local new_recipe = copy_and_add_prototype(p, quality)
                if new_recipe.main_product and new_recipe.main_product ~= "" then
                    new_recipe.main_product = name_with_quality(new_recipe.main_product, quality)
                end

                local function handle_recipe_part(parts)
                    if parts == nil then
                        return
                    end
                    for _, part in pairs(parts) do
                        if part.type == "fluid" then
                            part.name = name_without_quality(part.name)
                        elseif part.type == "item" or part.name then
                            part.name = name_with_quality(name_without_quality(part.name), quality)
                        else
                            part[1] = name_with_quality(name_without_quality(part[1]), quality)
                        end
                    end
                end

                for _, recipe_root in pairs({ new_recipe, new_recipe.normal, new_recipe.expensive }) do
                    if recipe_root then
                        handle_recipe_part(recipe_root.ingredients)
                        handle_recipe_part(recipe_root.results)
                        if recipe_root.result then
                            recipe_root.result = name_with_quality(name_without_quality(recipe_root.result), quality)
                        end
                        recipe_root.hide_from_player_crafting = true
                        recipe_root.allow_as_intermediate = false
                    end
                end
            end
        end
    end
end)()

data:extend(new_prototypes)
new_prototypes = {}

local function make_probabilities(effective_quality, max_quality)
    if max_quality <= 1 then
        return { 1.0 }
    end
    local probabilities = { 1.0 - effective_quality }
    local left = effective_quality
    for i = 2, (max_quality - 1) do
        probabilities[i] = left * 0.9
        left = left * 0.1
    end
    probabilities[max_quality] = left
    return probabilities
end

-- Recipes with quality upgrades
(function()
    for _, recipe in pairs(data.raw.recipe) do
        for _, quality_module in pairs(quality_modules) do
            for _, module_count in pairs(slot_counts) do
                local effective_quality = module_count * quality_module.modifier
                local new_recipe = table.deepcopy(recipe)
                table.insert(new_prototypes, new_recipe)
                new_recipe.name = name_with_quality_module(new_recipe.name, module_count, quality_module)
                new_recipe.category = name_with_quality_module((new_recipe.category or "crafting"), module_count, quality_module)
                if new_recipe.result then
                    new_recipe.results = { { type = "item", name = new_recipe.result, amount = new_recipe.result_amount } }
                    new_recipe.result = nil
                    new_recipe.result_amount = nil
                end
                if ((new_recipe.icon == nil and new_recipe.icons == nil) or new_recipe.subgroup == nil) and new_recipe.main_product == nil and new_recipe.normal == nil then
                    if data.raw.fluid[name_without_quality(recipe.name)] then
                        new_recipe.main_product = name_without_quality(recipe.name)
                    else
                        new_recipe.main_product = recipe.name
                    end
                end

                local function handle_recipe_part(results)
                    if results == nil then
                        return
                    end
                    local new_results = {}
                    for _, part in pairs(results) do
                        if part.type == "fluid" then
                            table.insert(new_results, part)
                        else
                            if part.name == nil then
                                part.name = part[1]
                                part.amount = part[2]
                                part.type = "item"
                            end
                            local found_quality = find_quality(part.name)
                            local probabilities = make_probabilities(effective_quality, quality_module.max_quality - found_quality + 1)
                            for i, prob in pairs(probabilities) do
                                local new_part = table.deepcopy(part)
                                new_part.name = name_with_quality(name_without_quality(new_part.name), { level = found_quality - 1 + i })
                                new_part.probability = prob * (part.probability or 1.0)
                                if new_part.min_amount == nil and new_part.amount == nil then
                                    new_part.amount = 1
                                end
                                table.insert(new_results, new_part)
                            end
                        end
                    end
                    return new_results
                end

                for _, recipe_root in pairs({ new_recipe, new_recipe.normal, new_recipe.expensive }) do
                    if recipe_root then
                        recipe_root.results = handle_recipe_part(recipe_root.results)
                        recipe_root.hide_from_player_crafting = true
                        recipe_root.allow_as_intermediate = false
                    end
                end
            end
        end
    end
end)()

data:extend(new_prototypes)
new_prototypes = {}
