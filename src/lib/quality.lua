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
    if quality.level == 1 then
        return name
    end
    return name .. "-quality-" .. quality.level
end

function libq.name_without_quality(name)
    return string.match(name, "(.+)-quality%-%d") or name
end

function libq.find_quality(name)
    return tonumber(string.match(name, "-quality%-(%d)")) or 1
end

libq.quality_modules = {
    { name = "1@1", mod_level = 1, mod_quality = 1, max_quality = 3, modifier = 0.0100, icon = lib.p.gfx .. "quality-module-1-overlay.png" },
    { name = "2@1", mod_level = 2, mod_quality = 1, max_quality = 4, modifier = 0.0150, icon = lib.p.gfx .. "quality-module-2-overlay.png" },
}

for _, quality in pairs(libq.qualities) do
    local name = "3@" .. quality.level
    table.insert(libq.quality_modules, {
        name = name,
        max_quality = 5,
        mod_level = 3,
        mod_quality = quality.level,
        modifier = 0.0248 * (1.0 + 0.3 * quality.modifier),
        icon = lib.p.gfx .. "quality-module-" .. name .. "-overlay.png",
    })
end

function libq.name_with_quality_module(name, module_count, quality_module)
    return name .. "-qum-" .. module_count .. "x" .. quality_module.name
end

function libq.split_quality_modules(name)
    return string.match(name, "(.+)-qum%-(%d)x(.+)")
end

libq.slot_counts = { 2, 3, 4 }

function libq.copy_prototype(p, quality)
    local new_p = data_util.copy_prototype(p, libq.name_with_quality(p.name, quality))
    local mid_name = { "?", { "item-name." .. p.name }, { "entity-name." .. p.name }, { "fluid-name." .. p.name }, p.name }
    if p.localised_name then
        mid_name = { "", p.localised_name }
    end
    new_p.localised_name = { "jq.with-quality", mid_name, { "jq.quality-" .. quality.level } }
    new_p.icons = data_util.create_icons(p, { { icon = quality.icon_overlay, icon_size = 64, scale = 0.5, icon_mipmaps = 0 } })
    if new_p.icons and #new_p.icons == 3 then
        new_p.icons[1].scale = 0.5 -- This is a hack that makes icons actually stack correctly. No idea why it works.
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

    if string.find(p.type, "-equipment") and new_p.sprite then
        if new_p.sprite.layers == nil then
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

    if new_p.placed_as_equipment_result then
        new_p.placed_as_equipment_result = libq.name_with_quality(p.name, quality)
    end
    if p.order then
        new_p.order = libq.name_with_quality(p.order, quality)
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
    if results == nil then
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
                new_part.name = libq.name_with_quality(libq.name_without_quality(new_part.name), { level = found_quality - 1 + i })
                new_part.probability = prob * (part.probability or 1.0)
                table.insert(new_results, new_part)
            end
        end
    end
    return new_results
end

return libq
