local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")
local trigger_mods = require(lib.p.prot .. "trigger_mods")

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
                if not op then
                    if skip_missing then
                        goto continue
                    end
                    log(serpent.block(p))
                    assert(false, "Failed modifying \"" .. p.name .. "\" with path \"" .. name .. "\"")
                end
            end
            local last = path[#path]
            if op[last] or not skip_missing then
                local value, unit = lib.get_energy_value(op[last])
                if value and unit then
                    op[last] = modifier(value, quality) .. unit
                else
                    op[last] = modifier(op[last], quality)
                end
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

-- Division modifier
function m.div(modifier)
    return function(value, quality)
        return (value or 0.0) / (1.0 + modifier * quality.modifier)
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
-- deprecated
m.energy = m.mult

-- Modifier that adds quality to property
function m.with_quality(value, quality)
    return value and libq.name_with_quality(value, quality)
end

-- Adds flags
function m.flags(flags)
    return function(value, quality)
        return lib.table_extend(value or {}, flags)
    end
end

-- Modifier that applies func to an array
function m.array(func)
    return function(value, quality)
        return lib.map(value, function(entry)
            return func(entry, quality)
        end)
    end
end

-- Combines 2 modifiers into one
function m.combine(mod1, mod2)
    return function(value, quality)
        mod1(value, quality)
        mod2(value, quality)
    end
end

-- Default high level modification function
function m.default_mod(names)
    local mods = {}
    for _, name in pairs(names) do
        mods[name] = m.mult(0.3)
    end
    return m.mod(mods)
end

-- Default energy source mod
m.default_energy_source_mod = m.default_mod {
    "energy_source.buffer_capacity.?", "energy_source.input_flow_limit.?", "energy_source.output_flow_limit.?"
}

-- Default roboport mod
m.default_roboport_mod = m.combine(m.default_mod { "charging_energy" }, m.default_energy_source_mod)

-- Default high level modification function for attack_parameters
m.default_attack_parameters = m.mod { ["attack_parameters.range"] = m.mult(0.1), attack_parameters = trigger_mods.ammo }

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
        for _, part_definition in pairs(util.split(cat_definition or "", ",")) do
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
