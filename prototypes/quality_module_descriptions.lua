local libq = require("__janky-quality__/lib/quality")

for _, qm in pairs(libq.quality_modules) do
    local module = data.raw["selection-tool"][libq.name_with_quality("quality-module-" .. qm.mod_level, qm.mod_quality)]
    module.localised_description = { "jq.quality-module-description", math.floor(qm.modifier * 10000)/100 }
end
