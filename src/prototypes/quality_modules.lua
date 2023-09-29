for i = 1, 3 do
    lib.add_prototype(
            {
                category = "quality",
                icon = jq_gfx .. "quality-module-" .. i .. ".png",
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

lib.add_prototype(
        {
            effects = { { recipe = "quality-module-1", type = "unlock-recipe" } },
            icon = jq_gfx .. "quality-module-1-tech.png",
            icon_size = 256,
            scale = 1,
            name = "quality-module",
            order = "i-i-a",
            prerequisites = { "modules" },
            type = "technology",
            unit = {
                count = 50,
                ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 } },
                time = 30,
            },
            upgrade = true
        }
)

lib.add_prototype(
        {
            effects = { { recipe = "quality-module-2", type = "unlock-recipe" } },
            icon = jq_gfx .. "quality-module-2-tech.png",
            icon_size = 256,
            name = "quality-module-2",
            order = "i-i-b",
            prerequisites = { "quality-module", "advanced-electronics-2" },
            type = "technology",
            unit = {
                count = 75,
                ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 } },
                time = 30
            },
            upgrade = true
        })

lib.add_prototype(
        {
            effects = {
                {
                    recipe = "quality-module-3",
                    type = "unlock-recipe"
                }
            },
            icon = jq_gfx .. "quality-module-3-tech.png",
            icon_size = 256,
            name = "quality-module-3",
            order = "i-i-c",
            prerequisites = { "quality-module-2", "production-science-pack" },
            type = "technology",
            unit = {
                count = 300,
                ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 }, { "production-science-pack", 1 } },
                time = 60
            },
            upgrade = true
        }
)

lib.flush_prototypes()
