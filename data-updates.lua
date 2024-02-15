local lib = require("__janky-quality__/lib/lib")

log("Recipe count before JQ: " .. table_size(data.raw.recipe))

lib.table_update(jq_entity_mods.no_quality, require(lib.p.prot .. "no_quality"))

local imports = {
    "sprites",
    "character",
    "beacons",
    "quality_modules",
    "recycling",
    "resources",
    "quality_enhancing_machines",
    "recipe_qualities",
    "items_and_entities",
    "recipes_with_quality_upgrades",
    "quality_enhancing_machine_programming",
    "deleveling",
    "signals",
    "quality_module_descriptions",
}

for _, import in pairs(imports) do
    require(lib.p.prot .. import)
end

log("Recipe count after JQ: " .. table_size(data.raw.recipe))
