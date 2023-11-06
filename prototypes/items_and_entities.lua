local flib_table = require("__flib__/table")
local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

local cat_weird = {
    "player-port", "simple-entity-with-force", "simple-entity-with-owner", "infinity-container", "infinity-pipe", "linked-container", "linked-belt",
}

local cat_without_bonuses = {
    "arithmetic-combinator", "decider-combinator", "constant-combinator", "power-switch", "programmable-speaker",
    "rail-chain-signal", "rail-signal", "train-stop", "heat-interface", "electric-energy-interface", "spidertron-remote",
    "item", "item-with-entity-data", "item-with-inventory", "selection-tool", "explosion", "belt-immunity-equipment",
}

local cat_without_sa_bonuses = {
    "container", "logistic-container", "storage-tank", "pipe", "pipe-to-ground", "pump", "offshore-pump", "heat-pipe",
    "splitter", "transport-belt", "underground-belt", "loader", "loader-1x1", "cargo-wagon", "fluid-wagon", "locomotive",
    "combat-robot", "capsule", "lamp", "smoke-with-trigger",
}

local cat_with_sa_bonuses = { "wall", "gate" }

local all_cat_set = util.list_to_map(flib_table.array_merge({ cat_without_bonuses, cat_without_sa_bonuses, cat_with_sa_bonuses, cat_weird }))

local function handle_category(category_name, func)
    for _, p in pairs(data.raw[category_name]) do
        for _, quality in pairs(libq.qualities) do
            if quality.level ~= 1 then
                local new_entity = lib.add_prototype(libq.copy_prototype(p, quality))
                if new_entity.max_health then
                    new_entity.max_health = new_entity.max_health * (1 + 0.3 * quality.modifier)
                end
                if new_entity.rocket_launch_product then
                    new_entity.rocket_launch_product[1] = libq.name_with_quality(new_entity.rocket_launch_product[1], quality)
                end
                if func then
                    assert(not all_cat_set[category_name], "Category '" .. category_name .. "' appears in auto items")
                    func(new_entity, quality)
                end
            end
        end
    end
end

for category, func in pairs(jq_entity_mods.entity_mods) do
    all_cat_set[category] = nil
    handle_category(category, func)
end

for category, _ in pairs(all_cat_set) do
    handle_category(category, nil)
end

lib.flush_prototypes()
