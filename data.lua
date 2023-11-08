local lib = require("__janky-quality__/lib/lib")

-- This is imported in data stage, for use with other mods.
jq_entity_mods = require(lib.p.prot .. "entity_mods")

lib.table_update(jq_entity_mods.entity_mods, require(lib.p.prot .. "quality_bonuses"))

if settings.startup["jq-use-extra-bonuses"].value then
    lib.table_update(jq_entity_mods.entity_mods, require(lib.p.prot .. "quality_bonuses_extra"))
end

lib.table_update(jq_entity_mods.no_quality, require(lib.p.prot .. "no_quality"))

require(lib.p.prot .. "tips_and_tricks")
