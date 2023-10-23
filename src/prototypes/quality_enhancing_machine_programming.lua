local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

local subgroups = {}

local function handle_category(category_name)
    for _, assembler in pairs(data.raw[category_name]) do
        local item = data.raw.item[assembler.name]
        local name, module_count, module_name = libq.split_quality_modules(item.name)
        if name ~= nil and module_count ~= nil and module_name ~= nil then
            local assembler_name_with_quality = libq.name_with_quality(name, { level = libq.find_quality(item.name) })
            local tier, quality_level = string.match(module_name, "(%d)@(%d)")
            local module_item_name = libq.name_with_quality("quality-module-" .. tier, { level = tonumber(quality_level) })
            lib.add_prototype(
                    {
                        icons = table.deepcopy(item.icons),
                        ingredients = { { module_item_name, module_count }, { assembler_name_with_quality, 1 } },
                        name = "programming-quality-" .. item.name,
                        localised_name = {"jq.programming", assembler.localised_name},
                        result = item.name,
                        type = "recipe",
                        subgroup = "quality-programming-" .. item.subgroup,
                        enabled = false,
                        allow_as_intermediate = false,
                        allow_intermediates = false,
                        hide_from_stats = true,
                    }
            )
            lib.add_prototype(
                    {
                        icons = table.deepcopy(item.icons), -- todo "X"
                        ingredients = { { item.name, 1 } },
                        name = "deprogramming-quality-" .. item.name,
                        localised_name = {"jq.deprogramming", assembler.localised_name},
                        results = { { module_item_name, module_count }, { assembler_name_with_quality, 1 } },
                        type = "recipe",
                        subgroup = "quality-deprogramming-" .. item.subgroup,
                        enabled = false,
                        allow_as_intermediate = false,
                        allow_intermediates = false,
                        hide_from_stats = true,
                    }
            )
            subgroups[item.subgroup] = true
        end
    end
end

handle_category("assembling-machine")
handle_category("furnace")
handle_category("mining-drill")

for subgroup_name, _ in pairs(subgroups) do
    local subgroup = data.raw["item-subgroup"][subgroup_name]
    lib.add_prototype({ group = "quality-programming", name = "quality-programming-" .. subgroup_name, order = "a-" .. subgroup.order, type = "item-subgroup" })
    lib.add_prototype({ group = "quality-programming", name = "quality-deprogramming-" .. subgroup_name, order = "b-" .. subgroup.order, type = "item-subgroup" })
end

lib.add_prototype(
        {
            icon = lib.p.gfx .. "quality-module-1.png",
            icon_size = 96,
            name = "quality-programming",
            localised_name = {"jq.quality-programming"},
            order = "z",
            type = "item-group",
        }
)

lib.flush_prototypes()
