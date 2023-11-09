local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")
local m = require(lib.p.prot .. "entity_mods")

m.all_entities_mod = m.combine(m.all_entities_mod, m.mod { ["fuel_value.?"] = m.energy(0.3) })

return {
    ["lamp"] = m.mod { ["light.size"] = m.mult(0.3), ["light_when_colored.size"] = m.mult(0.3) },
    ["mining-drill"] = m.default_mod("mining_speed"),
    ["pipe-to-ground"] = m.mod { ["fluid_box.pipe_connections.2.max_underground_distance"] = m.add(2) },
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
