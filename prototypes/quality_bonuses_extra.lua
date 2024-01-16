local lib = require("__janky-quality__/lib/lib")
local m = require(lib.p.prot .. "entity_mods")

return {
    ["__item__"] = m.mod { ["fuel_value.?"] = m.energy(0.3) },
    ["lamp"] = m.default_mod { "light.size.?", "light_when_colored.size.?" },
    ["mining-drill"] = m.default_mod { "mining_speed" },
    ["pipe-to-ground"] = m.mod { ["fluid_box.pipe_connections.2.max_underground_distance.?"] = m.add(2) },
    ["tile"] = function(p, quality)
        if p.walking_speed_modifier then
            p.walking_speed_modifier = p.walking_speed_modifier * (1.0 + 0.1 * quality.modifier)
        end
        if p.vehicle_friction_modifier then
            p.vehicle_friction_modifier = p.vehicle_friction_modifier * (1.0 + 0.1 * quality.modifier)
        end
        p.tint = {}
        for i, c in pairs(quality.color) do
            p.tint[i] = 0.25 * (c - 1) + 1
        end
    end
}
