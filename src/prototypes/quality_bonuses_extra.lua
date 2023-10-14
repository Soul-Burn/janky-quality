local lib = require("__janky-quality__/lib/lib")
local m = require(lib.p.prot .. "entity_mods.lua")

return {
    ["lamp"] = m.mod({ ["light.size"] = m.mult(0.3), ["light_when_colored.size"] = m.mult(0.3) }),
    ["mining-drill"] = m.default_mod("mining_speed"),
}
