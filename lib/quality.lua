local lib = require("__janky-quality__/lib/lib")
local data_util = require("__flib__/data-util")

local libq = {}

libq.qualities = {
    { level = 1, modifier = 0, icon = lib.p.gfx .. "quality-1.png", icon_overlay = lib.p.gfx .. "quality-1-overlay.png" },
    { level = 2, modifier = 1, icon = lib.p.gfx .. "quality-2.png", icon_overlay = lib.p.gfx .. "quality-2-overlay.png" },
    { level = 3, modifier = 2, icon = lib.p.gfx .. "quality-3.png", icon_overlay = lib.p.gfx .. "quality-3-overlay.png" },
    { level = 4, modifier = 3, icon = lib.p.gfx .. "quality-4.png", icon_overlay = lib.p.gfx .. "quality-4-overlay.png" },
    { level = 5, modifier = 5, icon = lib.p.gfx .. "quality-5.png", icon_overlay = lib.p.gfx .. "quality-5-overlay.png" },
}

function libq.name_with_quality(name, quality)
    local level = type(quality) == "table" and quality.level or quality
    return level == 1 and name or name .. "-quality-" .. level
end

function libq.name_without_quality(name)
    return string.match(name, "(.+)-quality%-%d") or name
end

function libq.find_quality(name)
    return tonumber(string.match(name, "-quality%-(%d)")) or 1
end

libq.quality_modules = {
    { name = "1@1", mod_level = 1, mod_quality = 1, max_quality = 3, modifier = 0.0100, icon = lib.p.gfx .. "quality-module-1@1-overlay.png" },
    { name = "2@1", mod_level = 2, mod_quality = 1, max_quality = 4, modifier = 0.0150, icon = lib.p.gfx .. "quality-module-2@1-overlay.png" },
    { name = "3@1", mod_level = 3, mod_quality = 1, max_quality = 5, modifier = 0.0248, icon = lib.p.gfx .. "quality-module-3@1-overlay.png" },
}

local qm_to_add = {}
for _, qm in pairs(libq.quality_modules) do
    for _, quality in pairs(libq.qualities) do
        if quality.level ~= 1 then
            local new_qm = table.deepcopy(qm)
            new_qm.name = new_qm.mod_level .. "@" .. quality.level
            new_qm.modifier = new_qm.modifier * (1.0 + 0.3 * quality.modifier)
            new_qm.icon = lib.p.gfx .. "quality-module-" .. new_qm.name .. "-overlay.png",
            table.insert(qm_to_add, new_qm)
        end
    end
end
lib.table_extend(libq.quality_modules, qm_to_add)

function libq.name_with_quality_module(name, module_count, quality_module)
    return name .. "-qum-" .. module_count .. "x" .. quality_module.name
end

function libq.split_quality_modules(name)
    return string.match(name, "(.+)-qum%-(%d)x(.+)")
end

function libq.qm_name_to_module_item(qm_name)
    local module_tier, module_quality = string.match(qm_name, "(%d)@(%d)")
    return libq.name_with_quality("quality-module-" .. module_tier, tonumber(module_quality))
end

function libq.get_recipe_category_to_slots()
    local crafting_machines = util.list_to_map({ "assembling-machine", "furnace" })
    local recipe_category_to_slots = {}

    local function add_to_category_to_slots(category, slots)
        if slots > 0 then
            if not recipe_category_to_slots[category] then
                recipe_category_to_slots[category] = {}
            end
            recipe_category_to_slots[category][slots] = true
        end
    end

    if data then
        for machine_category, _ in pairs(crafting_machines) do
            for _, machine in pairs(data.raw[machine_category]) do
                for _, crafting_category in pairs(machine.crafting_categories) do
                    if machine.module_specification then
                        add_to_category_to_slots(crafting_category, machine.module_specification.module_slots)
                    end
                end
            end
        end
    elseif game then
        for _, entity in pairs(game.entity_prototypes) do
            if crafting_machines[entity.type] and entity.module_inventory_size and entity.module_inventory_size > 0 then
                for category, _ in pairs(entity.crafting_categories) do
                    add_to_category_to_slots(category, entity.module_inventory_size or 0)
                end
            end
        end
    end

    return recipe_category_to_slots
end

function libq.copy_prototype(p, quality)
    local new_p = table.deepcopy(p)
    local mid_name = { "?", { "item-name." .. new_p.name }, { "entity-name." .. new_p.name }, { "fluid-name." .. new_p.name }, new_p.name }
    if new_p.localised_name then
        mid_name = { "", new_p.localised_name }
    end
    new_p.localised_name = { "jq.with-quality", mid_name, { "jq.quality-" .. quality.level } }
    new_p.name = libq.name_with_quality(new_p.name, quality)

    new_p.icons = data_util.create_icons(new_p, { { icon = quality.icon_overlay, icon_size = 64, scale = 0.5, icon_mipmaps = 0 } })
    if new_p.icons and #new_p.icons == 3 then
        new_p.icons[1].scale = 0.5 -- This is a hack that makes icons actually stack correctly. No idea why it works.
    end

    if new_p.place_result then
        new_p.place_result = libq.name_with_quality(new_p.place_result, quality)
    end

    if new_p.placed_as_equipment_result then
        new_p.placed_as_equipment_result = libq.name_with_quality(new_p.placed_as_equipment_result, quality)
    end

    if new_p.placeable_by then
        for _, item_to_place in pairs(new_p.placeable_by.item and { new_p.placeable_by } or new_p.placeable_by) do
            item_to_place.item = libq.name_with_quality(item_to_place.item, quality)
        end
    end

    if new_p.minable then
        local _, results = lib.get_canonic_recipe(new_p.minable)
        if results then
            for _, result in pairs(results) do
                if result.name == p.name then
                    result.name = libq.name_with_quality(result.name, quality)
                end
            end
            new_p.minable.results = results
        end
    end

    local picture_overlay = { filename = quality.icon_overlay, size = 64, scale = 0.25, mipmap_count = 0 }
    if new_p.type == "item" and new_p.pictures then
        if new_p.pictures.layers then
            table.insert(new_p.pictures.layers, picture_overlay)
        else
            for i, picture in pairs(new_p.pictures) do
                new_p.pictures[i] = { layers = { table.deepcopy(picture), picture_overlay } }
            end
        end
    end

    if string.find(new_p.type, "-equipment") and new_p.sprite then
        if not new_p.sprite.layers then
            new_p.sprite.layers = { table.deepcopy(new_p.sprite) }
            new_p.sprite.height = nil
            new_p.sprite.width = nil
            new_p.sprite.scale = nil
            new_p.sprite.priority = nil
            new_p.sprite.hr_version = nil
            new_p.sprite.filename = nil
        end
        table.insert(new_p.sprite.layers, { filename = quality.icon, height = 16, width = 16 })
    end

    if new_p.order then
        new_p.order = libq.name_with_quality(new_p.order, quality)
    end

    return new_p
end

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

function libq.transform_results_with_probabilities(results, module_count, quality_module)
    if not results then
        return
    end
    local new_results = {}
    for _, part in pairs(results) do
        if part.type == "fluid" then
            table.insert(new_results, part)
        else
            local found_quality = libq.find_quality(part.name)
            local probabilities = make_probabilities(module_count * quality_module.modifier, quality_module.max_quality - found_quality + 1)
            for i, prob in pairs(probabilities) do
                local new_part = table.deepcopy(part)
                new_part.name = libq.name_with_quality(libq.name_without_quality(new_part.name), found_quality - 1 + i)
                new_part.probability = prob * (part.probability or 1.0)
                table.insert(new_results, new_part)
            end
        end
    end
    return new_results
end

return libq