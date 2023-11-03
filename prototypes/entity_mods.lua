local data_util = require("__flib__/data-util")
local libq = require("__janky-quality__/lib/quality")

local m = {}
m.entity_mods = {}

-- General modification function, works by path and function. Can be used as the top level modification function.
function m.mod(names_and_modifiers)
    return function(p, quality)
        for name, modifier in pairs(names_and_modifiers) do
            local op = p
            local path = util.split(name, ".")
            local skip_missing = false
            if path[#path] == "?" then
                skip_missing = true
                path[#path] = nil
            end
            for i = 1, #path - 1 do
                op = op[path[i]]
                if not op and skip_missing then
                    return
                end
            end
            local last = path[#path]
            if not op[last] and skip_missing then
                return
            end
            op[last] = modifier(op[last], quality)
        end
    end
end

-- Multiplicative modifier
function m.mult(modifier)
    return function(value, quality)
        return (value or 0.0) * (1.0 + modifier * quality.modifier)
    end
end

-- Additive modifier
function m.add(modifier)
    return function(value, quality)
        return (value or 0) + modifier * quality.modifier
    end
end

-- Energy modifier
function m.energy(modifier)
    local mult = m.mult(modifier)
    return function(value, quality)
        local clean_value, unit = data_util.get_energy_value(value)
        return mult(clean_value, quality) .. unit
    end
end

-- Modifier that adds quality to property
function m.with_quality(value, quality)
    return value and libq.name_with_quality(value, quality)
end

-- Default high level modification function
function m.default_mod(name)
    return m.mod({ [name] = m.mult(0.3) })
end

-- Default high level modification function for energy objects
function m.default_energy_mod(name)
    return m.mod({ [name] = m.energy(0.3) })
end

-- Default high level modification function for attack_parameters
m.default_attack_parameters = m.mod({ ["attack_parameters.range"] = m.mult(0.1) })

return m
