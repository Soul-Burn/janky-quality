local lib = require("__janky-quality__/lib/lib")

-- This is imported in data stage, for use with other mods.
jq_entity_mods = require(lib.p.prot .. "entity_mods.lua")

lib.table_update(jq_entity_mods.entity_mods, require(lib.p.prot .. "quality_bonuses.lua"))

if settings.startup["jq-use-extra-bonuses"].value then
    lib.table_update(jq_entity_mods.entity_mods, require(lib.p.prot .. "quality_bonuses_extra.lua"))
end

require(lib.p.prot .. "tips_and_tricks.lua")