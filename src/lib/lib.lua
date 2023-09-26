local data_util = require("__flib__/data-util")

jq_root = "__janky-quality__/"
jq_prot = jq_root .. "prototypes/"
jq_gfx = jq_root .. "graphics/"

local lib = {}
local new_prototypes = {}

function lib.add_prototype(prototype)
    table.insert(new_prototypes, prototype)
end

function lib.flush_prototypes()
    if next(new_prototypes) ~= nil then
        data:extend(new_prototypes)
        new_prototypes = {}
    end
end

lib.qualities = {
    { level = 1, modifier = 0, icon = jq_gfx .. "quality-1.png", icon_overlay = jq_gfx .. "quality-1-overlay.png" },
    { level = 2, modifier = 1, icon = jq_gfx .. "quality-2.png", icon_overlay = jq_gfx .. "quality-2-overlay.png" },
    { level = 3, modifier = 2, icon = jq_gfx .. "quality-3.png", icon_overlay = jq_gfx .. "quality-3-overlay.png" },
    { level = 4, modifier = 3, icon = jq_gfx .. "quality-4.png", icon_overlay = jq_gfx .. "quality-4-overlay.png" },
    { level = 5, modifier = 5, icon = jq_gfx .. "quality-5.png", icon_overlay = jq_gfx .. "quality-5-overlay.png" },
}

function lib.name_with_quality(name, quality)
    if quality.level == 1 then
        return name
    end
    return name .. "-quality-" .. quality.level
end

function lib.name_without_quality(name)
    return string.match(name, "(.+)-quality%-%d") or name
end

function lib.find_quality(name)
    return tonumber(string.match(name, "-quality%-(%d)")) or 1
end

lib.quality_modules = {
    { name = "1@1", max_quality = 3, modifier = 0.0100, icon = jq_gfx .. "quality-module-1-overlay.png" },
    { name = "2@1", max_quality = 4, modifier = 0.0150, icon = jq_gfx .. "quality-module-2-overlay.png" },
}

for _, quality in pairs(lib.qualities) do
    local name = "3@" .. quality.level
    table.insert(lib.quality_modules, {
        name = name,
        max_quality = 5,
        modifier = 0.0248 * (1.0 + 0.3 * quality.modifier),
        icon = jq_gfx .. "quality-module-" .. name .. "-overlay.png",
    })
end

function lib.name_with_quality_module(name, module_count, quality_module)
    return name .. "-qum-" .. module_count .. "x" .. quality_module.name
end

function lib.split_quality_modules(name)
    return string.match(name, "(.+)-qum%-(%d)x(.+)")
end

lib.slot_counts = { 2, 3, 4 }

function lib.copy_and_add_prototype(p, quality)
    local new_p = data_util.copy_prototype(p, lib.name_with_quality(p.name, quality))
    new_p.icons = data_util.create_icons(p, { { icon = quality.icon_overlay, icon_size = 64, scale = 1, icon_mipmaps = 0 } })
    if new_p.icons ~= nil then
        new_p.icons[1].scale = 1
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
        new_p.placed_as_equipment_result = lib.name_with_quality(p.name, quality)
    end
    if p.order then
        new_p.order = lib.name_with_quality(p.order, quality)
    end
    lib.add_prototype(new_p)
    return new_p
end

return lib
