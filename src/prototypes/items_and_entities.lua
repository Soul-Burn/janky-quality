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

local all_cat = {
    "accumulator", "artillery-turret", "beacon", "boiler", "burner-generator", "arithmetic-combinator", "decider-combinator", "constant-combinator",
    "container", "logistic-container", "assembling-machine", "rocket-silo", "furnace", "combat-robot", "construction-robot",
    "logistic-robot", "gate", "generator", "heat-interface", "heat-pipe", "inserter", "lab", "lamp", "land-mine", "mining-drill", "offshore-pump",
    "pipe", "pipe-to-ground", "power-switch", "programmable-speaker", "pump", "radar",
    "rail-chain-signal", "rail-signal", "reactor", "roboport", "solar-panel", "storage-tank", "train-stop", "splitter", "transport-belt",
    "underground-belt", "turret", "ammo-turret", "electric-turret", "fluid-turret", "car", "artillery-wagon", "cargo-wagon", "fluid-wagon",
    "locomotive", "spider-vehicle", "wall",
    "active-defense-equipment", "battery-equipment", "belt-immunity-equipment", "energy-shield-equipment", "generator-equipment",
    "movement-bonus-equipment", "night-vision-equipment", "roboport-equipment", "solar-panel-equipment", "capsule", "gun", "ammo", "armor",
    "repair-tool", "tool", "loader", "loader-1x1", "spidertron-remote", "electric-energy-interface"
}
local all_cat_str = ";" .. table.concat(all_cat, ";") .. ";"

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
                    assert(string.find(all_cat_str, ";" .. category_name .. ";") == nil, "Category '" .. category_name .. "' appears in auto items")
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
