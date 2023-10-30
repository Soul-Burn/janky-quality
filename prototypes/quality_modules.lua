local lib = require("__janky-quality__/lib/lib")

for i = 1, 3 do
    lib.add_prototype(
            {
                category = "quality",
                icon = lib.p.gfx .. "quality-module-" .. i .. "-icon.png",
                icon_size = 64,
                localised_name = {"jq.quality-module-" .. i},
                localised_description = { "item-description.quality-module" },
                name = "quality-module-" .. i,
                order = "c[quality]-a[quality-module-" .. i .. "]",
                stack_size = 50,
                subgroup = "module",
                type = "selection-tool",

                selection_mode = "blueprint",
                selection_color = {1, 1, 1},
                selection_cursor_box_type = "entity",
                entity_type_filters = {"assembling-machine", "furnace", "mining-drill"},

                alt_selection_mode = "nothing",
                alt_selection_color = {1, 0, 0},
                alt_selection_cursor_box_type = "entity",
                alt_entity_type_filters = {},

                reverse_selection_mode = "blueprint",
                reverse_selection_color = {0.5, 0.5, 0.5},
                reverse_selection_cursor_box_type = "entity",
                reverse_entity_type_filters = {"assembling-machine", "furnace", "mining-drill"},
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
            icon = lib.p.gfx .. "quality-module-1-tech.png",
            icon_size = 256,
            scale = 1,
            name = "quality-module",
            localised_name = {"jq.quality-module"},
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
            icon = lib.p.gfx .. "quality-module-2-tech.png",
            icon_size = 256,
            name = "quality-module-2",
            localised_name = {"jq.quality-module-2"},
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
            effects = { { recipe = "quality-module-3", type = "unlock-recipe" } },
            icon = lib.p.gfx .. "quality-module-3-tech.png",
            icon_size = 256,
            name = "quality-module-3",
            localised_name = {"jq.quality-module-3"},
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
