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
            for i, v in pairs(path) do
                path[i] = tonumber(v) or v
            end
            for i = 1, #path - 1 do
                op = op[path[i]]
                if not op and skip_missing then
                    goto continue
                end
            end
            local last = path[#path]
            if op[last] or not skip_missing then
                op[last] = modifier(op[last], quality)
            end
            :: continue ::
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
function m.add(modifier, max_value)
    return function(value, quality)
        local new_value = (value or 0) + modifier * quality.modifier
        if max_value and max_value < new_value then
            return max_value
        end
        return new_value
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

-- Modifier that applies func to an array
function m.array(func)
    return function(value, quality)
        local result = {}
        for _, entry in pairs(value) do
            table.insert(result, func(entry, quality))
        end
        return result
    end
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

function m.combine(mod1, mod2)
    return function(value, quality)
        mod1(value, quality)
        mod2(value, quality)
    end
end

return m
