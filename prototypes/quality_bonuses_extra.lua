local lib = require("__janky-quality__/lib/lib")
local m = require(lib.p.prot .. "entity_mods")

return {
    ["__all__"] = m.mod { ["fuel_value.?"] = m.energy(0.3) },
    ["lamp"] = m.mod { ["light.size"] = m.mult(0.3), ["light_when_colored.size"] = m.mult(0.3) },
    ["mining-drill"] = m.default_mod("mining_speed"),
    ["pipe-to-ground"] = m.mod { ["fluid_box.pipe_connections.2.max_underground_distance"] = m.add(2) },
}
