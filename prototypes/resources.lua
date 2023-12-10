local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

local all_slots = {}
for _, miner in pairs(data.raw["mining-drill"]) do
    if miner.module_specification and miner.module_specification.module_slots and miner.module_specification.module_slots > 0 then
        if lib.contains(miner.resource_categories, "basic-solid") then
            all_slots[miner.module_specification.module_slots] = true
        end
    end
end

for module_slots in pairs(all_slots) do
    for _, qm in pairs(libq.quality_modules) do
        lib.add_prototype { name = libq.name_with_quality_module("basic-solid", module_slots, qm), type = "resource-category" }
    end

    for _, resource in pairs(data.raw.resource) do
        if not resource.category or resource.category == "basic-solid" then
            for _, qm in pairs(libq.quality_modules) do
                local new_resource = table.deepcopy(resource)
                new_resource.name = libq.name_with_quality_module(resource.name, module_slots, qm)
                new_resource.localised_name = {
                    "jq.with-qm",
                    resource.localised_name or { "entity-name." .. resource.name },
                    { "jq.with-quality", { "jq.quality-module-name", qm.mod_level }, { "jq.quality-" .. qm.mod_quality } },
                    module_slots,
                }
                new_resource.category = libq.name_with_quality_module("basic-solid", module_slots, qm)

                local _, results = lib.get_canonic_recipe(resource.minable)
                new_resource.minable.results = libq.transform_results_with_probabilities(results, module_slots, qm)

                lib.add_prototype(new_resource)
            end
        end
    end
end

lib.flush_prototypes()
