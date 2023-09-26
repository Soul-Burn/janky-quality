local lib = require("__janky-quality__/lib/lib")

for _, quality in pairs(lib.qualities) do
    lib.add_prototype({ type = "sprite", name = "jq_quality_icon_" .. quality.level, filename = quality.icon, size = 16 })
end

for _, qm in pairs(lib.quality_modules) do
    lib.add_prototype({ type = "sprite", name = "jq_quality_module_icon_" .. qm.name, filename = qm.icon, size = 64, scale = 0.5 })
end

require(jq_prot .. "quality_enhancing_machines")
require(jq_prot .. "quality_modules")
require(jq_prot .. "equipment_grid")
require(jq_prot .. "items_and_entities")
require(jq_prot .. "recipe_qualities")
require(jq_prot .. "recipes_with_quality_upgrades")
require(jq_prot .. "quality_enhancing_machine_programming")
