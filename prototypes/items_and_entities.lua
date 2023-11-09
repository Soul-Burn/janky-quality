local flib_table = require("__flib__/table")
local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

local cat_without_bonuses = {
    "arithmetic-combinator", "decider-combinator", "constant-combinator", "power-switch", "programmable-speaker",
    "rail-chain-signal", "rail-signal", "train-stop", "heat-interface", "spidertron-remote",
    "item", "item-with-entity-data", "item-with-inventory", "selection-tool", "explosion", "belt-immunity-equipment", "wall", "gate",
}

local cat_without_sa_bonuses = {
    "container", "logistic-container", "storage-tank", "pipe", "pipe-to-ground", "pump", "offshore-pump", "heat-pipe",
    "splitter", "transport-belt", "underground-belt", "loader", "loader-1x1", "cargo-wagon", "fluid-wagon", "locomotive",
    "combat-robot", "capsule", "lamp", "smoke-with-trigger",
}

local all_cat_set = util.list_to_map(flib_table.array_merge({ cat_without_bonuses, cat_without_sa_bonuses }))
lib.table_update(all_cat_set, jq_entity_mods.entity_mods)
all_cat_set["__all__"] = nil
local all_entities_mod = jq_entity_mods.entity_mods["__all__"]

for category_name, _ in pairs(all_cat_set) do
    local category = data.raw[category_name]
    for _, p in pairs(category) do
        if not libq.forbids_quality(p.name) then
            for _, quality in pairs(libq.qualities) do
                if quality.level ~= 1 then
                    local new_p = lib.add_prototype(libq.copy_prototype(p, quality))
                    all_entities_mod(new_p, quality)
                    if jq_entity_mods.entity_mods[category_name] then
                        jq_entity_mods.entity_mods[category_name](new_p, quality)
                    end
                end
            end
        end
    end
end

lib.flush_prototypes()
