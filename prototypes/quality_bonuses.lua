local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")
local m = require(lib.p.prot .. "entity_mods.lua")
local trigger_mods = require(lib.p.prot .. "trigger_mods.lua")

return {
    ["lab"] = m.default_mod("researching_speed"),
    ["assembling-machine"] = m.default_mod("crafting_speed"),
    ["furnace"] = m.default_mod("crafting_speed"),
    ["rocket-silo"] = m.default_mod("crafting_speed"),
    ["inserter"] = m.mod({ rotation_speed = m.mult(0.3), extension_speed = m.mult(0.3) }),
    ["repair-tool"] = m.default_mod("durability"),
    ["tool"] = m.default_mod("durability"),
    ["gun"] = m.default_attack_parameters,
    ["turret"] = m.default_attack_parameters,
    ["ammo-turret"] = m.default_attack_parameters,
    ["electric-turret"] = m.default_attack_parameters,
    ["fluid-turret"] = m.default_attack_parameters,
    ["active-defense-equipment"] = m.default_attack_parameters,
    ["beacon"] = m.mod({ energy_usage = m.energy(-0.12) }),
    ["radar"] = m.mod({ max_distance_of_sector_revealed = m.mult(0.3), max_distance_of_nearby_sector_revealed = m.mult(0.3) }),
    ["reactor"] = m.default_energy_mod("consumption"),
    ["boiler"] = m.default_energy_mod("energy_consumption"),
    ["burner-generator"] = m.default_energy_mod("max_power_output"),
    ["generator"] = m.default_mod("fluid_usage_per_tick"),
    ["solar-panel"] = m.default_energy_mod("production"),
    ["solar-panel-equipment"] = m.default_energy_mod("power"),
    ["generator-equipment"] = m.default_energy_mod("power"),
    ["equipment-grid"] = m.mod { width = m.add(1), height = m.add(1) },
    ["construction-robot"] = m.default_energy_mod("max_energy"),
    ["logistic-robot"] = m.default_energy_mod("max_energy"),
    ["roboport"] = m.default_energy_mod("charging_energy"),
    ["roboport-equipment"] = m.default_energy_mod("charging_energy"),
    ["energy-shield-equipment"] = m.default_mod("max_shield_value"),
    ["movement-bonus-equipment"] = m.default_mod("movement_bonus"),
    ["artillery-turret"] = m.mod({ gun = m.with_quality }),
    ["artillery-wagon"] = m.mod({ gun = m.with_quality }),
    ["battery-equipment"] = m.default_energy_mod("energy_source.buffer_capacity"),
    ["accumulator"] = m.default_energy_mod("energy_source.buffer_capacity"),
    ["spider-vehicle"] = m.mod({ inventory_size = m.add(10), equipment_grid = m.with_quality }),
    ["armor"] = m.mod({ inventory_size_bonus = m.add(10), durability = m.mult(0.3), equipment_grid = m.with_quality }),
    ["electric-pole"] = m.mod({ supply_area_distance = m.add(1, 64), maximum_wire_distance = m.add(2, 64) }),
    ["night-vision-equipment"] = function(p, quality)
        p.color_lookup[1][2] = lib.p.gfx .. "nv-quality-" .. quality.level .. ".png"
    end,
    ["module"] = function(p, quality)
        if p.limitation then
            local new_limitations = {}
            for _, limitation in pairs(p.limitation) do
                for _, q in pairs(libq.qualities) do
                    local limitation_name = libq.name_with_quality(limitation, q)
                    if q.level ~= 1 and data.raw.recipe[limitation_name] then
                        table.insert(new_limitations, limitation_name)
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
        p.straight_rail = libq.name_with_quality(p.straight_rail, quality)
        p.curved_rail = libq.name_with_quality(p.curved_rail, quality)
    end,
    ["straight-rail"] = function(p, quality)
        p.minable.results[1].name = libq.name_with_quality("rail", quality)
    end,
    ["curved-rail"] = function(p, quality)
        p.minable.results[1].name = libq.name_with_quality("rail", quality)
    end,
    ["projectile"] = trigger_mods.action,
    ["artillery-projectile"] = trigger_mods.action,
    ["land-mine"] = trigger_mods.action,
    ["ammo"] = trigger_mods.ammo,
    ["stream"] = function(p, quality)
        trigger_mods.trigger(p.initial_action, quality)
        trigger_mods.trigger(p.action, quality)
    end,
    ["sticker"] = m.mod({ ["damage_per_tick.amount.?"] = m.mult(0.3) }),
    ["fire"] = m.mod({ ["damage_per_tick.amount.?"] = m.mult(0.3) }),
    ["capsule"] = function(p, quality)
        trigger_mods.ammo(p.capsule_action.attack_parameters, quality)
    end,
}
