local data_util = require("__flib__/data-util")

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
    { level = 1, modifier = 0, icon = "__janky-quality__/graphics/quality_1.png" },
    { level = 2, modifier = 1, icon = "__janky-quality__/graphics/quality_2.png" },
    { level = 3, modifier = 2, icon = "__janky-quality__/graphics/quality_3.png" },
    { level = 4, modifier = 3, icon = "__janky-quality__/graphics/quality_4.png" },
    { level = 5, modifier = 5, icon = "__janky-quality__/graphics/quality_5.png" },
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
    { name = "1@1", max_quality = 3, modifier = 0.01, icon = "__janky-quality__/graphics/quality_module_1.png" },
    { name = "2@1", max_quality = 4, modifier = 0.0150, icon = "__janky-quality__/graphics/quality_module_2.png" },
}

for _, quality in pairs(lib.qualities) do
    table.insert(lib.quality_modules, {
        name = "3@" .. quality.level,
        max_quality = 5,
        modifier = 0.0248 * (1.0 + 0.3 * quality.modifier),
        icon = "__janky-quality__/graphics/quality_module_3.png",
    })
end

function lib.name_with_quality_module(name, module_count, quality_module)
    return name .. "-qm-" .. module_count .. "x" .. quality_module.name
end

function lib.split_quality_modules(name)
    return string.match(name, "(.+)-qm%-(%d)x(.+)")
end

lib.slot_counts = { 2, 3, 4 }

function lib.copy_and_add_prototype(p, quality)
    local new_p = data_util.copy_prototype(p, lib.name_with_quality(p.name, quality))
    new_p.icons = data_util.create_icons(p, { { icon = quality.icon, icon_size = 16, scale = 1, shift = { -6, 8 } } })
    if new_p.placed_as_equipment_result then
        new_p.placed_as_equipment_result = lib.name_with_quality(p.name, quality)
    end
    lib.add_prototype(new_p)
    return new_p
end

return lib
