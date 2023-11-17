local lib = require("__janky-quality__/lib/lib")
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
        local clean_value, unit = lib.get_energy_value(value)
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

-- Default roboport mod
m.default_roboport_mod = m.mod {
    ["charging_energy"] = m.energy(0.3),
    ["energy_source.buffer_capacity.?"] = m.energy(0.3),
    ["energy_source.input_flow_limit.?"] = m.energy(0.3),
    ["energy_source.output_flow_limit.?"] = m.energy(0.3),
}

-- Default high level modification function for attack_parameters
m.default_attack_parameters = m.mod { ["attack_parameters.range"] = m.mult(0.1) }

-- Combines 2 modifiers into one
function m.combine(mod1, mod2)
    return function(value, quality)
        mod1(value, quality)
        mod2(value, quality)
    end
end

-- Updates the modifier list with a new table. Prefix category with "-" to replace
function m.update_mods(new_mods)
    for cat, mod in pairs(new_mods) do
        if cat:sub(1, 1) == "-" then
            cat = cat:sub(2)
        elseif m.entity_mods[cat] then
            mod = m.combine(m.entity_mods[cat], mod)
        end
        m.entity_mods[cat] = mod
    end
end

m.no_quality = {}

local mod_params_counts = { add = { 1, 2 }, mult = { 1, 1 }, energy = { 1, 1 }, with_quality = { 0, 0 } }

function m.import_mods(import_string)
    local new_mods = {}
    for _, full_cat in pairs(util.split(import_string, ";")) do
        local cat, cat_definition = table.unpack(util.split(full_cat, ":"))
        local paths_and_modifiers = {}
        for _, part_definition in pairs(util.split(cat_definition, ",")) do
            local path, mod_definition = table.unpack(util.split(part_definition, "="))
            local mod_params = util.split(mod_definition, " ")
            local mod_name = mod_params[1]
            local param_count = #mod_params - 1
            mod_params[1] = nil
            local counts = mod_params_counts[mod_name]
            assert(counts, "Invalid mod name " .. mod_name .. " in mod string " .. import_string)
            assert(counts[1] <= param_count and param_count <= counts[2], "Invalid params " .. serpent.block(mod_params) .. " in mod string " .. import_string)
            local mod = m[mod_name]
            if counts[1] ~= 0 or counts[2] ~= 0 then
                mod = mod(table.unpack(lib.map(mod_params, tonumber)))
            end
            paths_and_modifiers[path] = mod
        end
        new_mods[cat] = m.mod(paths_and_modifiers)
    end
    m.update_mods(new_mods)
end

return m
