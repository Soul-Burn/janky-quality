local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

for _, quality in pairs(libq.qualities) do
    lib.add_prototype({ type = "sprite", name = "jq_quality_icon_" .. quality.level, filename = quality.icon, size = 16 })
end

for _, qm in pairs(libq.quality_modules) do
    lib.add_prototype({ type = "sprite", name = "jq_quality_module_icon_" .. qm.name, filename = qm.icon, size = 64, scale = 0.5 })
end

log("Recipe count before JQ: " .. lib.table_size(data.raw.recipe))

require(lib.p.prot .. "quality_modules")
require(lib.p.prot .. "recycling")
require(lib.p.prot .. "resources")
require(lib.p.prot .. "quality_enhancing_machines")
require(lib.p.prot .. "recipe_qualities")
require(lib.p.prot .. "items_and_entities")
require(lib.p.prot .. "recipes_with_quality_upgrades")
require(lib.p.prot .. "quality_enhancing_machine_programming")

log("Recipe count after JQ: " .. lib.table_size(data.raw.recipe))
