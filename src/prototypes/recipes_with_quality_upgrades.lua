local function make_probabilities(effective_quality, max_quality)
    if max_quality <= 1 then
        return { 1.0 }
    end
    local probabilities = { 1.0 - effective_quality }
    local left = effective_quality
    for i = 2, (max_quality - 1) do
        probabilities[i] = left * 0.9
        left = left * 0.1
    end
    probabilities[max_quality] = left
    return probabilities
end

local function handle_recipe(recipe)
    if recipe.subgroup and (recipe.subgroup == "fill-barrel" or recipe.subgroup == "empty-barrel") then
        return
    end
    for _, quality_module in pairs(lib.quality_modules) do
        for _, module_count in pairs(lib.slot_counts) do
            local effective_quality = module_count * quality_module.modifier
            local new_recipe = table.deepcopy(recipe)
            lib.add_prototype(new_recipe)
            new_recipe.name = lib.name_with_quality_module(new_recipe.name, module_count, quality_module)
            new_recipe.category = lib.name_with_quality_module((new_recipe.category or "crafting"), module_count, quality_module)

            local function handle_recipe_part(results)
                if results == nil then
                    return
                end
                local new_results = {}
                for _, part in pairs(results) do
                    if part.type == "fluid" then
                        table.insert(new_results, part)
                    else
                        local found_quality = lib.find_quality(part.name)
                        local probabilities = make_probabilities(effective_quality, quality_module.max_quality - found_quality + 1)
                        for i, prob in pairs(probabilities) do
                            local new_part = table.deepcopy(part)
                            new_part.name = lib.name_with_quality(lib.name_without_quality(new_part.name), { level = found_quality - 1 + i })
                            new_part.probability = prob * (part.probability or 1.0)
                            table.insert(new_results, new_part)
                        end
                    end
                end
                return new_results
            end

            for _, recipe_root in pairs({ new_recipe, new_recipe.normal, new_recipe.expensive }) do
                if recipe_root then
                    recipe_root.ingredients, recipe_root.results = lib.get_canonic_recipe(recipe_root)
                    recipe_root.results = handle_recipe_part(recipe_root.results)
                    recipe_root.hide_from_player_crafting = true
                    recipe_root.allow_as_intermediate = false

                    if ((new_recipe.icon == nil and new_recipe.icons == nil) or new_recipe.subgroup == nil) and recipe_root.main_product == nil then
                        if new_recipe.main_product then
                            recipe_root.main_product = new_recipe.main_product
                        elseif data.raw.fluid[lib.name_without_quality(recipe.name)] then
                            new_recipe.main_product = lib.name_without_quality(recipe.name)
                        else
                            new_recipe.main_product = recipe.name
                        end
                    end
                end
            end
        end
    end
end

for _, recipe in pairs(data.raw.recipe) do
    handle_recipe(recipe)
end

lib.flush_prototypes()
