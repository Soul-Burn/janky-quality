local lib = require("__janky-quality__/lib/lib")

for _, quality in pairs(lib.qualities) do
    lib.add_prototype({ type = "sprite", name = "jq_quality_icon_" .. quality.level, filename = quality.icon, size = 16 })
end

require("__janky-quality__/prototypes/quality_enhancing_machines")
require("__janky-quality__/prototypes/items_and_entities")
require("__janky-quality__/prototypes/recipe_qualities")
require("__janky-quality__/prototypes/recipes_with_quality_upgrades")
