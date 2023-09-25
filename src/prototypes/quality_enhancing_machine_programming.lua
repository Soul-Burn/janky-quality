local data_util = require("__flib__/data-util")
local lib = require("__janky-quality__/lib/lib")

local subgroups = {}

for _, assembler in pairs(data.raw["assembling-machine"]) do
    local item = data.raw.item[assembler.name]
    local name, module_count, module_name = lib.split_quality_modules(item.name)
    if name ~= nil and module_count ~= nil and module_name ~= nil then
        local assembler_name_with_quality = lib.name_with_quality(name, { level = lib.find_quality(item.name) })
        local tier, quality_level = string.match(module_name, "(%d)@(%d)")
        local module_item_name = lib.name_with_quality("quality-module-" .. tier, { level = tonumber(quality_level) })
        lib.add_prototype(
                {
                    enabled = true,
                    icons = data_util.create_icons(assembler),
                    ingredients = { { module_item_name, module_count }, { assembler_name_with_quality, 1 } },
                    name = "programming-quality-" .. item.name,
                    result = item.name,
                    type = "recipe",
                    subgroup = "quality-programming-" .. item.subgroup,
                }
        )
        lib.add_prototype(
                {
                    enabled = true,
                    icons = data_util.create_icons(assembler), -- todo "X"
                    ingredients = { { item.name, 1 } },
                    name = "deprogramming-quality-" .. item.name,
                    results = { { module_item_name, module_count }, { assembler_name_with_quality, 1 } },
                    type = "recipe",
                    subgroup = "quality-deprogramming-" .. item.subgroup,
                }
        )
        subgroups[item.subgroup] = true
    end
end

for subgroup_name, _ in pairs(subgroups) do
    local subgroup = data.raw["item-subgroup"][subgroup_name]
    lib.add_prototype({ group = "quality-programming", name = "quality-programming-" .. subgroup_name, order = subgroup.order, type = "item-subgroup" })
    lib.add_prototype({ group = "quality-programming", name = "quality-deprogramming-" .. subgroup_name, order = subgroup.order, type = "item-subgroup" })
end

lib.add_prototype(
        {
            icon = "__janky-quality__/graphics/quality_module_1.png",
            icon_size = 96,
            name = "quality-programming",
            order = "z",
            type = "item-group",
        }
)

lib.flush_prototypes()
