local data_util = require("__flib__/data-util")
local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

for recipe_category, _ in pairs(libq.get_recipe_category_to_slots()) do
    lib.add_prototype { name = libq.name_with_quality_forbidden(recipe_category), type = "recipe-category" }
end

lib.flush_prototypes()

local function handle_category(category_name)
    for _, machine in pairs(data.raw[category_name]) do
        if machine.module_specification and machine.module_specification.module_slots and machine.module_specification.module_slots > 0 then
            for _, qm in pairs(libq.quality_modules) do
                local slots = machine.module_specification.module_slots
                local new_machine = data_util.copy_prototype(machine, libq.name_with_quality_module(machine.name, slots, qm))
                if new_machine.crafting_categories then
                    local new_crafting_categories = {}
                    for _, cat in pairs(new_machine.crafting_categories) do
                        table.insert(new_crafting_categories, libq.name_with_quality_module(cat, slots, qm))
                        table.insert(new_crafting_categories, libq.name_with_quality_forbidden(cat))
                    end
                    new_machine.crafting_categories = new_crafting_categories
                elseif new_machine.resource_categories then
                    if new_machine.resource_categories[1] == "basic-solid" then
                        table.insert(new_machine.resource_categories, libq.name_with_quality_module("basic-solid", slots, qm))
                    end
                end
                new_machine.allowed_effects = { "consumption", "pollution" }
                new_machine.module_specification.module_slots = 0
                if new_machine.result_inventory_size then
                    new_machine.result_inventory_size = new_machine.result_inventory_size * qm.max_quality
                end

                new_machine.minable.results = {
                    { type = "item", name = libq.qm_name_to_module_item(qm.name), amount = slots },
                    { type = "item", name = machine.name, amount = 1 },
                }

                new_machine.localised_name = {
                    "jq.with-qm",
                    machine.localised_name or { "entity-name." .. machine.name },
                    { "jq.with-quality", { "jq.quality-module-" .. qm.mod_level }, { "jq.quality-" .. qm.mod_quality } },
                }

                local description = { "", { "jq.qual-description" } }

                for _, q in pairs(libq.qualities) do

                    local probability_desc = { "" }
                    for i, prob in pairs(libq.make_probabilities(slots * qm.modifier, qm.max_quality - q.level + 1)) do
                        table.insert(probability_desc, { "jq.qual-percent", prob * 100, i + q.level - 1 })
                        table.insert(probability_desc, ", ")
                    end
                    probability_desc[#probability_desc] = nil
                    table.insert(description, { "", { "jq.qual-line", q.level, probability_desc } })
                end

                new_machine.localised_description = description

                lib.add_prototype(new_machine)

                local item = data.raw.item[machine.name]
                local new_item = data_util.copy_prototype(item, libq.name_with_quality_module(machine.name, slots, qm), true)
                new_item.icons = data_util.create_icons(item, { { icon = qm.icon, icon_size = 64, scale = 0.5, icon_mipmaps = 0 } })
                new_item.order = libq.name_with_quality_module(item.order, 0, qm)
                new_item.localised_name = new_machine.localised_name
                lib.add_prototype(new_item)
            end
        end
        lib.table_extend(machine.crafting_categories, lib.map(machine.crafting_categories or {}, libq.name_with_quality_forbidden))
    end
end

handle_category("assembling-machine")
handle_category("furnace")
handle_category("mining-drill")

lib.flush_prototypes()
