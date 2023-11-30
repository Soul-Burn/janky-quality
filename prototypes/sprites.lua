local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

for _, quality in pairs(libq.qualities) do
    lib.add_prototype { type = "sprite", name = "jq_quality_icon_" .. quality.level, filename = quality.icon, size = 32, scale = 0.5 }
end

for _, qm in pairs(libq.quality_modules) do
    lib.add_prototype { type = "sprite", name = "jq_quality_module_icon_" .. qm.name, filename = qm.icon, size = 64, scale = 0.5 }
end

lib.flush_prototypes()
