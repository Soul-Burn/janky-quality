local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

local recipe_category_to_slots = libq.get_recipe_category_to_slots()
local basic_recipes = { }
for _, recipe in pairs(data.raw.recipe) do
    if not libq.split_quality_modules(recipe.name) and libq.find_quality(recipe.name) == 1 then
        table.insert(basic_recipes, recipe.name)
    end
end

-- Limitations must be done on all modules
for _, p in pairs(data.raw.module) do
    local has_speed = p.effect and p.effect.speed and p.effect.speed.bonus and p.effect.speed.bonus > 0
    if not p.limitation and has_speed then
        p.limitation = table.deepcopy(basic_recipes)
    end
    if p.limitation then
        local new_limitations = {}
        for _, limitation in pairs(p.limitation) do
            for _, q in pairs(libq.qualities) do
                local limitation_name = libq.name_with_quality(limitation, q)
                if data.raw.recipe[limitation_name] then
                    table.insert(new_limitations, limitation_name)
                end
            end
        end
        lib.table_extend(p.limitation, new_limitations)

        if not has_speed then
            local new_limitations_with_qm = {}
            for _, limitation in pairs(new_limitations) do
                for slots, _ in pairs(recipe_category_to_slots[data.raw.recipe[limitation].category or "crafting"] or {}) do
                    for _, qm in pairs(libq.quality_modules) do
                        local limitation_with_qm = libq.name_with_quality_module(limitation, slots, qm)
                        if data.raw.recipe[limitation_with_qm] then
                            table.insert(new_limitations_with_qm, limitation_with_qm)
                        end
                    end
                end
            end
            lib.table_extend(p.limitation, new_limitations_with_qm)
        end
    end
end
