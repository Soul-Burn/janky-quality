local flib_table = require("__flib__/table")
local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

local cat_without_bonuses = {
    "arithmetic-combinator", "decider-combinator", "constant-combinator", "power-switch", "programmable-speaker",
    "rail-chain-signal", "rail-signal", "train-stop", "heat-interface", "spidertron-remote", "virtual-signal",
    "item", "item-with-entity-data", "item-with-inventory", "selection-tool", "explosion", "belt-immunity-equipment", "wall", "gate",
}

local cat_without_sa_bonuses = {
    "container", "logistic-container", "storage-tank", "pipe", "pipe-to-ground", "pump", "offshore-pump", "heat-pipe",
    "splitter", "transport-belt", "underground-belt", "loader", "loader-1x1", "cargo-wagon", "fluid-wagon", "locomotive",
    "combat-robot", "capsule", "lamp", "smoke-with-trigger", "mining-drill",
}

local all_cat_set = util.list_to_map(flib_table.array_merge { cat_without_bonuses, cat_without_sa_bonuses })
lib.table_update(all_cat_set, jq_entity_mods.entity_mods)
for cat in pairs(all_cat_set) do
    if cat:match("__") then
        all_cat_set[cat] = nil
    end
end

local all_entities_mod = jq_entity_mods.entity_mods["__all__"]
local cat_to_super_cat_mod = {}
for super_cat, cats in pairs(defines.prototypes) do
    for cat in pairs(cats) do
        cat_to_super_cat_mod[cat] = jq_entity_mods.entity_mods["__" .. super_cat .. "__"]
    end
end

for category_name in pairs(all_cat_set) do
    local category = data.raw[category_name]
    for _, p in pairs(category) do
        if not libq.forbids_quality(p.name) then
            for _, quality in pairs(libq.qualities) do
                if quality.level ~= 1 then
                    local new_p = lib.add_prototype(libq.copy_prototype(p, quality))
                    for _, mod in pairs { all_entities_mod, cat_to_super_cat_mod[category_name], jq_entity_mods.entity_mods[category_name] } do
                        if mod then
                            mod(new_p, quality)
                        end
                    end
                end
            end
        end
    end
end

lib.flush_prototypes()
