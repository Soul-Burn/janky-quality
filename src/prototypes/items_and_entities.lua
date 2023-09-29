local flib_table = require("__flib__/table")
local lib = require("__janky-quality__/lib/lib")

-- Handle items without entities
for _, p in pairs(data.raw.item) do
    if p.place_result == nil and p.placed_as_equipment_result == nil then
        for _, quality in pairs(lib.qualities) do
            if quality.level ~= 1 then
                lib.copy_and_add_prototype(p, quality)
            end
        end
    end
end

local cat_without_bonuses = {
    "arithmetic-combinator", "decider-combinator", "constant-combinator", "power-switch", "programmable-speaker",
    "rail-chain-signal", "rail-signal", "train-stop", "heat-interface", "electric-energy-interface", "spidertron-remote"
}

local cat_without_sa_bonuses = {
    "container", "logistic-container", "storage-tank", "pipe", "pipe-to-ground", "pump", "offshore-pump", "heat-pipe",
    "splitter", "transport-belt", "underground-belt", "loader", "loader-1x1", "cargo-wagon", "fluid-wagon", "locomotive", "car",
    "belt-immunity-equipment", "combat-robot", "capsule",
}

local cat_with_sa_bonuses = {
    "boiler", "burner-generator", "ammo", "generator", "land-mine", "radar", "reactor", "wall", "gate",
    "active-defense-equipment", "generator-equipment", "night-vision-equipment",
}

local all_cat = flib_table.array_merge({ cat_without_bonuses, cat_without_sa_bonuses, cat_with_sa_bonuses })
local all_cat_set = {}
for _, cat in pairs(all_cat) do
    all_cat_set[cat] = true
end

-- Handle items with entities
local function handle_category(category_name, func)
    for _, p in pairs(data.raw[category_name]) do
        for _, quality in pairs(lib.qualities) do
            if quality.level ~= 1 then
                local new_entity = lib.copy_and_add_prototype(p, quality)
                if new_entity.max_health then
                    new_entity.max_health = new_entity.max_health * (1 + 0.3 * quality.modifier)
                end
                if func then
                    assert(all_cat_set[category_name] == nil, "Category '" .. category_name .. "' appears in auto items")
                    func(new_entity, quality)
                end
                for _, sub_category in pairs({ "item", "item-with-entity-data", "item-with-inventory" }) do
                    local item = data.raw[sub_category][p.name]
                    if item then
                        lib.copy_and_add_prototype(item, quality)
                        break
                    end
                end
            end
        end
    end
end

for category, func in pairs(require("__janky-quality__/prototypes/entity_specifics.lua")) do
    handle_category(category, func)
end

for _, category in pairs(all_cat) do
    handle_category(category, nil)
end

lib.flush_prototypes()
