local lib = {}
lib.p = {
    root = "__janky-quality__/",
    prot = "__janky-quality__/prototypes/",
    gfx = "__janky-quality__/graphics/",
}

local new_prototypes = {}

function lib.table_size(t)
    local size = 0
    for _, _ in pairs(t) do
        size = size + 1
    end
    return size
end

function lib.table_update(t, t2)
    for k, v in pairs(t2) do
        t[k] = v
    end
end

function lib.table_extend(t, t2)
    for _, v in ipairs(t2) do
        t[#t + 1] = v
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

function lib.find_by_prop(t, name, value)
    return lib.find_by_predicate(t, function(item)
        return item[name] == value
    end)
end

function lib.get_canonic_parts(parts)
    if not parts then
        return nil
    end
    local new_parts = {}
    for _, part in ipairs(parts) do
        if not part.name then
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
    if not recipe_root.results and recipe_root.result then
        results = { { type = "item", name = recipe_root.result, amount = recipe_root.result_count or recipe_root.count or 1 } }
    end
    return ingredients, results
end

function lib.split_by_catalysts(recipe_root)
    local non_catalysts = {}
    local catalysts = {}
    for _, part in pairs(recipe_root.results) do
        local catalyst_amount = part.catalyst_amount or (lib.find_by_prop(recipe_root.ingredients, "name", part.name) or { amount = 0 }).amount
        if catalyst_amount == 0 then
            -- No catalyst
            table.insert(non_catalysts, part)
        elseif (part.amount and part.amount <= catalyst_amount) or (part.amount_max and part.amount_max <= catalyst_amount) then
            -- All catalyst
            table.insert(catalysts, part)
        elseif part.amount then
            -- Partial catalyst (amount)
            local cata_part = table.deepcopy(part)
            cata_part.amount = catalyst_amount
            table.insert(catalysts, cata_part)
            local non_cata_part = table.deepcopy(part)
            non_cata_part.amount = part.amount - catalyst_amount
            table.insert(non_catalysts, non_cata_part)
        elseif part.amount_min and part.amount_max then
            -- Partial catalyst (amount min and max)
            local cata_part = table.deepcopy(part)
            if catalyst_amount < part.amount_min then
                cata_part.amount = catalyst_amount
            else
                cata_part.amount_max = catalyst_amount
            end
            table.insert(catalysts, cata_part)
            local non_cata_part = table.deepcopy(part)
            non_cata_part.amount_min = non_cata_part.amount_min - catalyst_amount
            non_cata_part.amount_max = non_cata_part.amount_max - catalyst_amount
            table.insert(catalysts, non_cata_part)
        end
    end
    return non_catalysts, catalysts
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
    return { type = part.type, name = part.name, amount_min = vc - spread, amount_max = vc + spread, probability = v / vc, catalyst_amount = part.catalyst_amount }
end

function lib.add_prototype(prototype)
    table.insert(new_prototypes, prototype)
    return prototype
end

function lib.flush_prototypes()
    if next(new_prototypes) then
        data:extend(new_prototypes)
        new_prototypes = {}
    end
end

return lib
