for _, qm in pairs(libq.quality_modules) do
    lib.add_prototype({ name = libq.name_with_quality_module("basic-solid", 3, qm), type = "resource-category" })
end

for _, resource in pairs(data.lib.resource) do
    if resource.category == "basic-solid" then
        for _, qm in pairs(libq.quality_modules) do
            local new_resource = table.deepcopy(resource)
            new_resource.name = libq.name_with_quality_module(resource.name, 3, qm)
            new_resource.localised_name = {
                "jq.with-qm",
                resource.localised_name or { "entity-name." .. resource.name },
                { "jq.with-quality", { "jq.quality-module-" .. qm.mod_level }, { "jq.quality-" .. qm.mod_quality } },
            }
            new_resource.category = libq.name_with_quality_module("basic-solid", 3, qm)
            local _, results = lib.get_canonic_recipe(resource.minable)

            -- TODO split lib to lib and libq!!

            new_resource.minable.results = handle_results(results, probabilities)
            lib.add_prototype(new_resource)
        end
    end
end

lib.flush_prototypes()
