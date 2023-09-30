lib.add_prototype({ name = "quality-module-programming", type = "recipe-category" })

for _, recipe_category in pairs(data.raw["recipe-category"]) do
    for _, q in pairs(lib.quality_modules) do
        for _, module_count in pairs(lib.slot_counts) do
            lib.add_prototype({ name = lib.name_with_quality_module(recipe_category.name, module_count, q), type = "recipe-category" })
        end
    end
end

local function handle_category(category_name)
    for _, machine in pairs(data.raw[category_name]) do
        if machine.module_specification and machine.module_specification.module_slots > 0 then
            for _, qm in pairs(lib.quality_modules) do
                local slots = machine.module_specification.module_slots
                local new_machine = data_util.copy_prototype(machine, lib.name_with_quality_module(machine.name, slots, qm))
                for i, cat in pairs(new_machine.crafting_categories) do
                    new_machine.crafting_categories[i] = lib.name_with_quality_module(cat, slots, qm)
                end
                new_machine.allowed_effects = { "consumption", "pollution" }
                new_machine.module_specification.module_slots = 0

                new_machine.localised_name = {
                    "jq.with-qm",
                    {machine.localised_name or "entity-name." .. machine.name},
                    { "jq.with-quality", { "jq.quality-module-" .. qm.mod_level }, { "jq.quality-" .. qm.mod_quality } },
                }

                lib.add_prototype(new_machine)

                local item = data.raw.item[machine.name]
                local new_item = data_util.copy_prototype(item, lib.name_with_quality_module(machine.name, slots, qm), true)
                new_item.icons = data_util.create_icons(item, { { icon = qm.icon, icon_size = 64, scale = 0.5, icon_mipmaps = 0 } })
                new_item.order = lib.name_with_quality_module(item.order, 0, qm)
                new_item.localised_name = new_machine.localised_name
                lib.add_prototype(new_item)
            end
        end
    end
end

handle_category("assembling-machine")
handle_category("furnace")

lib.flush_prototypes()
