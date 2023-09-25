local data_util = require("__flib__/data-util")
local lib = require("__janky-quality__/lib/lib")

lib.add_prototype({ name = "quality-module-programming", type = "recipe-category" })

for _, recipe_category in pairs(data.raw["recipe-category"]) do
    for _, q in pairs(lib.quality_modules) do
        for _, module_count in pairs(lib.slot_counts) do
            lib.add_prototype({ name = lib.name_with_quality_module(recipe_category.name, module_count, q), type = "recipe-category" })
        end
    end
end

for _, machine in pairs(data.raw["assembling-machine"]) do
    if machine.module_specification and machine.module_specification.module_slots > 0 then
        for _, q in pairs(lib.quality_modules) do
            local slots = machine.module_specification.module_slots
            local new_machine = data_util.copy_prototype(machine, lib.name_with_quality_module(machine.name, slots, q))
            for i, cat in pairs(new_machine.crafting_categories) do
                new_machine.crafting_categories[i] = lib.name_with_quality_module(cat, slots, q)
            end
            new_machine.module_specification.module_slots = 0
            lib.add_prototype(new_machine)

            local item = data.raw.item[machine.name]
            local new_item = data_util.copy_prototype(item, lib.name_with_quality_module(machine.name, slots, q))
            new_item.icons = data_util.create_icons(item, { { icon = q.icon, icon_size = 96, scale = 0.25, shift = { 0, 6 } } })
            lib.add_prototype(new_item)
        end
    end
end

lib.flush_prototypes()
