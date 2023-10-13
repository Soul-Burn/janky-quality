local data_util = require("__flib__/data-util")
local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

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

function m.default_mod(name)
    return m.mod({ [name] = m.mult(0.3) })
end

function m.default_energy_mod(name)
    return m.mod({ [name] = m.energy(0.3) })
end

m.default_attack_parameters = m.mod({ ["attack_parameters.range"] = m.mult(0.1) })

m.entity_mods = {}

return m
