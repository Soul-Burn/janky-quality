local data_util = require("__flib__/data-util")
local lib = require("__janky-quality__/lib/lib")

local function mult_modifier(names_and_modifiers)
    return function(p, quality)
        for name, modifier in pairs(names_and_modifiers) do
            p[name] = p[name] * (1 + modifier * quality.modifier)
        end
    end
end

local function attack_parameters_modifier(modifier)
    return function(p, quality)
        p.attack_parameters.range = p.attack_parameters.range * (1 + modifier * quality.modifier)
    end
end

local function power_modifier(name, modifier)
    return function(p, quality)
        local value, unit = data_util.get_energy_value(p[name])
        p[name] = (value * (1 + modifier * quality.modifier)) .. unit
    end
end

return {
    ["lab"] = mult_modifier({ researching_speed = 0.3 }),
    ["assembling-machine"] = mult_modifier({ crafting_speed = 0.3 }),
    ["furnace"] = mult_modifier({ crafting_speed = 0.3 }),
    ["rocket-silo"] = mult_modifier({ crafting_speed = 0.3 }),
    ["mining-drill"] = mult_modifier({ mining_speed = 0.3 }),
    ["inserter"] = mult_modifier({ rotation_speed = 0.3, extension_speed = 0.3 }),
    ["repair-tool"] = mult_modifier({ durability = 0.3 }),
    ["gun"] = attack_parameters_modifier(0.1),
    ["turret"] = attack_parameters_modifier(0.1),
    ["ammo-turret"] = attack_parameters_modifier(0.1),
    ["electric-turret"] = attack_parameters_modifier(0.1),
    ["fluid-turret"] = attack_parameters_modifier(0.1),
    ["beacon"] = power_modifier("energy_usage", -0.12),
    ["solar-panel"] = power_modifier("production", 0.3),
    ["solar-panel-equipment"] = power_modifier("power", 0.3),
    ["construction-robot"] = power_modifier("max_energy", 0.3),
    ["logistic-robot"] = power_modifier("max_energy", 0.3),
    ["energy-shield-equipment"] = mult_modifier({ max_shield_value = 0.3 }),
    ["movement-bonus-equipment"] = mult_modifier({ movement_bonus = 0.3 }),
    ["battery-equipment"] = function(p, quality)
        local value, unit = data_util.get_energy_value(p.energy_source.buffer_capacity)
        p.energy_source.buffer_capacity = (value * (1 + 0.3 * quality.modifier)) .. unit
    end,
    ["accumulator"] = function(p, quality)
        local value, unit = data_util.get_energy_value(p.energy_source.buffer_capacity)
        p.energy_source.buffer_capacity = (value * (1 + 0.3 * quality.modifier)) .. unit
    end,
    ["spider-vehicle"] = function(p, quality)
        p.inventory_size = p.inventory_size + 10 * quality.modifier
        p.equipment_grid = lib.name_with_quality(p.equipment_grid, quality)
    end,
    ["armor"] = function(p, quality)
        p.inventory_size_bonus = (p.inventory_size_bonus or 0) + 10 * quality.modifier
        p.durability = (p.durability or 0) * (1 + 0.3 * quality.modifier)
        if p.equipment_grid then
            p.equipment_grid = lib.name_with_quality(p.equipment_grid, quality)
        end
    end,
    ["lamp"] = function(p, quality)
        if p.light then
            p.light.size = p.light.size * (1 + 0.3 * quality.modifier)
        end
        if p.light_when_colored then
            p.light_when_colored.size = p.light_when_colored.size * (1 + 0.3 * quality.modifier)
        end
    end,
    ["electric-pole"] = function(p, quality)
        p.supply_area_distance = p.supply_area_distance + quality.modifier
        p.maximum_wire_distance = p.maximum_wire_distance + 2 * quality.modifier
    end,
    ["module"] = function(p, quality)
        if p.limitation then
            local new_limitations = {}
            for _, limitation in pairs(p.limitation) do
                for _, q in pairs(lib.qualities) do
                    if q.level ~= 1 then
                        table.insert(new_limitations, lib.name_with_quality(limitation, q))
                    end
                end
            end
            for _, limitation in pairs(new_limitations) do
                table.insert(p.limitation, limitation)
            end
        end

        local effect
        if p.category == "productivity" then
            effect = p.effect.productivity
        elseif p.category == "speed" then
            effect = p.effect.speed
        elseif p.category == "effectivity" then
            effect = p.effect.consumption
        end
        if effect then
            effect.bonus = effect.bonus * (1 + 0.3 * quality.modifier)
        end
    end,
    ["rail-planner"] = function(p, quality)
        p.place_result = nil
        p.type = "item"
    end,
}
