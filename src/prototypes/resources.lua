local miner_slots = 3

for _, qm in pairs(libq.quality_modules) do
    lib.add_prototype({ name = libq.name_with_quality_module("basic-solid", miner_slots, qm), type = "resource-category" })
end

for _, resource in pairs(data.raw.resource) do
    if not resource.category or resource.category == "basic-solid" then
        for _, qm in pairs(libq.quality_modules) do
            local new_resource = table.deepcopy(resource)
            new_resource.name = libq.name_with_quality_module(resource.name, miner_slots, qm)
            new_resource.localised_name = {
                "jq.with-qm",
                resource.localised_name or { "entity-name." .. resource.name },
                { "jq.with-quality", { "jq.quality-module-" .. qm.mod_level }, { "jq.quality-" .. qm.mod_quality } },
            }
            new_resource.category = libq.name_with_quality_module("basic-solid", miner_slots, qm)

            local _, results = lib.get_canonic_recipe(resource.minable)
            new_resource.minable.results = libq.transform_results_with_probabilities(results, miner_slots, qm)

            lib.add_prototype(new_resource)
        end
    end
end

lib.flush_prototypes()
