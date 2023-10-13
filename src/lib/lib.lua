local lib = {}
lib.p = {
    root = "__janky-quality__/",
    prot = "__janky-quality__/prototypes/",
    gfx = "__janky-quality__/graphics/",
}

local new_prototypes = {}

function lib.as_set(t)
    local new = {}
    for _, v in pairs(t) do
        new[v] = true
    end
    return new
end

function lib.extend(t, t2)
    for k, v in pairs(t2) do
        t[k] = v
    end
end

function lib.find_by_predicate(t, predicate)
    for _, item in pairs(t) do
        if predicate(item) then
            return item
        end
    end
    return nil
end

function lib.split(str, sep)
    local res = {}
    for cn in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(res, cn)
    end
    return res
end

function lib.get_canonic_parts(parts)
    if parts == nil then
        return nil
    end
    local new_parts = {}
    for _, part in ipairs(parts) do
        if part.name == nil then
            table.insert(new_parts, { type = "item", name = part[1], amount = part[2] })
        else
            local new_result = table.deepcopy(part)
            new_result.type = new_result.type or "item"
            table.insert(new_parts, new_result)
        end
    end
    return new_parts
end

function lib.get_canonic_recipe(recipe_root)
    local ingredients = lib.get_canonic_parts(recipe_root.ingredients)
    local results = lib.get_canonic_parts(recipe_root.results)
    if recipe_root.results == nil and recipe_root.result then
        results = { { type = "item", name = recipe_root.result, amount = recipe_root.result_count or 1 } }
    end
    return ingredients, results
end

function lib.normalize_probability(part)
    if not part.probability then
        return table.deepcopy(part)
    end
    local amount = part.amount
    if part.amount_min and part.amount_max then
        amount = (part.amount_min + part.amount_max) / 2.0
    end
    local v = amount * part.probability
    local vc = math.ceil(v)
    local spread = math.min(vc, (part.amount_max or part.amount) - vc)
    return { type = part.type, name = part.name, amount_min = vc - spread, amount_max = vc + spread, probability = v / vc }
end

function lib.add_prototype(prototype)
    table.insert(new_prototypes, prototype)
end

function lib.flush_prototypes()
    if next(new_prototypes) ~= nil then
        data:extend(new_prototypes)
        new_prototypes = {}
    end
end

return lib
