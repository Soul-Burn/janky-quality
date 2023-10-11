local m = {}

function m.mod(names_and_modifiers)
    return function(p, quality)
        for name, modifier in pairs(names_and_modifiers) do
            local op = p
            local path = lib.split(name, ".")
            for i = 1, #path - 1 do
                op = op[path[i]]
            end
            local last = path[#path]
            op[last] = modifier(op[last], quality)
        end
    end
end

function m.mult(modifier)
    return function(value, quality)
        return (value or 0.0) * (1.0 + modifier * quality.modifier)
    end
end

function m.add(modifier)
    return function(value, quality)
        return (value or 0) + modifier * quality.modifier
    end
end

function m.energy(modifier)
    local mult = m.mult(modifier)
    return function(value, quality)
        local clean_value, unit = data_util.get_energy_value(value)
        return mult(clean_value, quality) .. unit
    end
end

function m.with_quality(value, quality)
    return value and libq.name_with_quality(value, quality)
end

local function default_mod(name)
    return m.mod({ [name] = m.mult(0.3) })
end

local function default_energy_mod(name)
    return m.mod({ [name] = m.energy(0.3) })
end

local default_attack_parameters = m.mod({ ["attack_parameters.range"] = m.mult(0.1) })

return {
    ["lab"] = default_mod("researching_speed"),
    ["assembling-machine"] = default_mod("crafting_speed"),
    ["furnace"] = default_mod("crafting_speed"),
    ["rocket-silo"] = default_mod("crafting_speed"),
    ["mining-drill"] = default_mod("mining_speed"),
    ["inserter"] = m.mod({ rotation_speed = m.mult(0.3), extension_speed = m.mult(0.3) }),
    ["repair-tool"] = default_mod("durability"),
    ["tool"] = default_mod("durability"),
    ["gun"] = default_attack_parameters,
    ["turret"] = default_attack_parameters,
    ["ammo-turret"] = default_attack_parameters,
    ["electric-turret"] = default_attack_parameters,
    ["fluid-turret"] = default_attack_parameters,
    ["beacon"] = m.mod({ energy_usage = m.energy(-0.12) }),
    ["solar-panel"] = default_energy_mod("production"),
    ["solar-panel-equipment"] = default_energy_mod("power"),
    ["construction-robot"] = default_energy_mod("max_energy"),
    ["logistic-robot"] = default_energy_mod("max_energy"),
    ["roboport"] = default_energy_mod("charging_energy"),
    ["roboport-equipment"] = default_energy_mod("charging_energy"),
    ["energy-shield-equipment"] = default_mod("max_shield_value"),
    ["movement-bonus-equipment"] = default_mod("movement_bonus"),
    ["artillery-turret"] = m.mod({ gun = m.with_quality }),
    ["artillery-wagon"] = m.mod({ gun = m.with_quality }),
    ["battery-equipment"] = default_energy_mod("energy_source.buffer_capacity"),
    ["accumulator"] = default_energy_mod("energy_source.buffer_capacity"),
    ["spider-vehicle"] = m.mod({ inventory_size = m.add(10), equipment_grid = m.with_quality }),
    ["armor"] = m.mod({ inventory_size_bonus = m.add(10), durability = m.mult(0.3), equipment_grid = m.with_quality }),
    ["lamp"] = m.mod({ ["light.size"] = m.mult(0.3), ["light_when_colored.size"] = m.mult(0.3) }),
    ["electric-pole"] = m.mod({ supply_area_distance = m.add(1), maximum_wire_distance = m.add(2) }),
    ["module"] = function(p, quality)
        if p.limitation then
            local new_limitations = {}
            for _, limitation in pairs(p.limitation) do
                for _, q in pairs(libq.qualities) do
                    if q.level ~= 1 then
                        table.insert(new_limitations, libq.name_with_quality(limitation, q))
                    end
                end
            end
            for _, limitation in pairs(new_limitations) do
                table.insert(p.limitation, limitation)
            end
        end

        local effect = p.effect[p.category]
        if effect then
            effect.bonus = effect.bonus * (1 + 0.3 * quality.modifier)
        end
    end,
    ["rail-planner"] = function(p, quality)
        p.place_result = nil
        p.type = "item"
    end,
}
