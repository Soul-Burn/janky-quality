local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")
local trigger_mods = require(lib.p.prot .. "trigger_mods")
local m = jq_entity_mods

return {
    ["__item__"] = m.mod { ["rocket_launch_product.1.?"] = m.with_quality, flags = m.flags { "hide-from-bonus-gui", "hide-from-fuel-tooltip" } },
    ["__entity__"] = m.mod { ["max_health.?"] = m.mult(0.3), ["next_upgrade.?"] = m.with_quality, flags = m.flags { "hidden" } },
    ["lab"] = m.default_mod { "researching_speed" },
    ["assembling-machine"] = m.default_mod { "crafting_speed" },
    ["furnace"] = m.default_mod { "crafting_speed" },
    ["rocket-silo"] = m.default_mod { "crafting_speed" },
    ["inserter"] = m.mod { rotation_speed = m.mult(0.3), extension_speed = m.mult(0.3), ["energy_per_movement.?"] = m.div(0.3), ["energy_per_rotation.?"] = m.div(0.3) },
    ["repair-tool"] = m.default_mod { "durability" },
    ["tool"] = m.mod { durability = m.mult(1.0) },
    ["gun"] = m.default_attack_parameters,
    ["turret"] = m.default_attack_parameters,
    ["ammo-turret"] = m.default_attack_parameters,
    ["electric-turret"] = m.default_attack_parameters,
    ["fluid-turret"] = m.default_attack_parameters,
    ["active-defense-equipment"] = m.default_attack_parameters,
    ["beacon"] = m.mod { energy_usage = m.div(0.3) },
    ["radar"] = m.default_mod { "max_distance_of_sector_revealed", "max_distance_of_nearby_sector_revealed" },
    ["reactor"] = m.default_mod { "consumption" },
    ["boiler"] = m.default_mod { "energy_consumption" },
    ["burner-generator"] = m.default_mod { "max_power_output" },
    ["generator"] = m.default_mod { "fluid_usage_per_tick" },
    ["solar-panel"] = m.default_mod { "production" },
    ["solar-panel-equipment"] = m.default_mod { "power" },
    ["generator-equipment"] = m.default_mod { "power" },
    ["equipment-grid"] = m.mod { width = m.add(1), height = m.add(1) },
    ["construction-robot"] = m.default_mod { "max_energy" },
    ["logistic-robot"] = m.default_mod { "max_energy" },
    ["roboport"] = m.default_roboport_mod,
    ["roboport-equipment"] = m.default_roboport_mod,
    ["energy-shield-equipment"] = m.combine(m.mod { ["max_shield_value"] = m.mult(0.3) }, m.default_energy_source_mod),
    ["movement-bonus-equipment"] = m.default_mod { "movement_bonus" },
    ["artillery-turret"] = m.mod { gun = m.with_quality },
    ["artillery-wagon"] = m.mod { gun = m.with_quality },
    ["battery-equipment"] = m.default_energy_source_mod,
    ["accumulator"] = m.default_energy_source_mod,
    ["spider-vehicle"] = m.mod { inventory_size = m.add(10), equipment_grid = m.with_quality, ["guns.?"] = m.array(m.with_quality) },
    ["car"] = m.mod { inventory_size = m.add(10), ["equipment_grid.?"] = m.with_quality, ["guns.?"] = m.array(m.with_quality) },
    ["armor"] = m.mod { inventory_size_bonus = m.add(10), durability = m.mult(0.3), equipment_grid = m.with_quality },
    ["electric-pole"] = m.mod { supply_area_distance = m.add(1, 64), maximum_wire_distance = m.add(2, 64) },
    ["ammo"] = trigger_mods.ammo,
    ["projectile"] = m.mod { action = trigger_mods.trigger, final_action = trigger_mods.trigger },
    ["artillery-projectile"] = m.mod { action = trigger_mods.trigger, final_action = trigger_mods.trigger },
    ["land-mine"] = m.mod { action = trigger_mods.trigger, final_action = trigger_mods.trigger },
    ["stream"] = m.mod { initial_action = trigger_mods.trigger, action = trigger_mods.trigger },
    ["beam"] = m.mod { action = trigger_mods.trigger },
    ["sticker"] = m.default_mod { "damage_per_tick.amount.?" },
    ["fire"] = m.default_mod { "damage_per_tick.amount.?" },
    ["capsule"] = m.mod { ["capsule_action.attack_parameters.?"] = trigger_mods.ammo },
    ["night-vision-equipment"] = function(p, quality)
        p.color_lookup[1][2] = lib.p.gfx .. "nv-quality-" .. quality.level .. ".png"
        local ratio = quality.modifier / libq.max_modifier
        p.darkness_to_turn_on = (1 - ratio) * p.darkness_to_turn_on
    end,
    ["rail-planner"] = m.mod { straight_rail = m.with_quality, curved_rail = m.with_quality },
    ["straight-rail"] = function(p, quality)
        if p.minable and p.minable.results and p.minable.results[1] then
            p.minable.results[1].name = libq.name_with_quality(p.minable.results[1].name, quality)
        end
    end,
    ["curved-rail"] = function(p, quality)
        if p.minable and p.minable.results and p.minable.results[1] then
            p.minable.results[1].name = libq.name_with_quality(p.minable.results[1].name, quality)
        end
    end,
    ["module"] = function(p, quality)
        for effect_name, sign in pairs { speed = 1, productivity = 1, consumption = -1, pollution = -1 } do
            local effect = p.effect[effect_name]
            if effect and effect.bonus * sign > 0 then
                effect.bonus = effect.bonus * (1 + 0.3 * quality.modifier)
            end
        end
        if p.beacon_tint then
            p.beacon_tint.tertiary = quality.color
        end
    end,
    ["tile"] = function(p, quality)
        if p.minable then
            local _, results = lib.get_canonic_recipe(p.minable)
            if results then
                results[1].name = libq.name_with_quality(libq.name_without_quality(results[1].name), quality)
                p.minable.results = results
            end
        end
        if p.next_direction then
            p.next_direction = libq.name_with_quality(p.next_direction, quality)
        end
    end,
}
