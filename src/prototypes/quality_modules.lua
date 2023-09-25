local lib = require("__janky-quality__/lib/lib")

for i = 1, 3 do
    lib.add_prototype(
            {
                category = "quality",
                icon = "__janky-quality__/graphics/quality_module_" .. i .. ".png",
                icon_size = 96,
                localised_description = { "item-description.quality-module" },
                name = "quality-module-" .. i,
                order = "c[quality]-a[quality-module-" .. i .. "]",
                stack_size = 50,
                subgroup = "module",
                type = "item"
            }
    )
end

lib.add_prototype(
        {
            enabled = false,
            energy_required = 15,
            ingredients = { { "advanced-circuit", 5 }, { "electronic-circuit", 5 } },
            name = "quality-module-1",
            result = "quality-module-1",
            type = "recipe"
        }
)
lib.add_prototype(
        {
            enabled = false,
            energy_required = 30,
            ingredients = { { "quality-module-1", 4 }, { "advanced-circuit", 5 }, { "processing-unit", 5 } },
            name = "quality-module-2",
            result = "quality-module-2",
            type = "recipe"
        }
)
lib.add_prototype(
        {
            enabled = false,
            energy_required = 60,
            ingredients = { { "quality-module-2", 5 }, { "advanced-circuit", 5 }, { "processing-unit", 5 } },
            name = "quality-module-3",
            result = "quality-module-3",
            type = "recipe"
        }
)

lib.flush_prototypes()
