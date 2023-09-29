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

for _, recipe in pairs(data.raw.recipe) do
    for _, quality_module in pairs(lib.quality_modules) do
        for _, module_count in pairs(lib.slot_counts) do
            local effective_quality = module_count * quality_module.modifier
            local new_recipe = table.deepcopy(recipe)
            lib.add_prototype(new_recipe)
            new_recipe.name = lib.name_with_quality_module(new_recipe.name, module_count, quality_module)
            new_recipe.category = lib.name_with_quality_module((new_recipe.category or "crafting"), module_count, quality_module)
            if new_recipe.result then
                new_recipe.results = { { type = "item", name = new_recipe.result, amount = new_recipe.result_amount } }
                new_recipe.result = nil
                new_recipe.result_amount = nil
            end
            if ((new_recipe.icon == nil and new_recipe.icons == nil) or new_recipe.subgroup == nil) and new_recipe.main_product == nil and new_recipe.normal == nil then
                if data.raw.fluid[lib.name_without_quality(recipe.name)] then
                    new_recipe.main_product = lib.name_without_quality(recipe.name)
                else
                    new_recipe.main_product = recipe.name
                end
            end

            local function handle_recipe_part(results)
                if results == nil then
                    return
                end
                local new_results = {}
                for _, part in pairs(results) do
                    if part.type == "fluid" then
                        table.insert(new_results, part)
                    else
                        if part.name == nil then
                            part.name = part[1]
                            part.amount = part[2]
                            part.type = "item"
                        end
                        local found_quality = lib.find_quality(part.name)
                        local probabilities = make_probabilities(effective_quality, quality_module.max_quality - found_quality + 1)
                        for i, prob in pairs(probabilities) do
                            local new_part = table.deepcopy(part)
                            new_part.name = lib.name_with_quality(lib.name_without_quality(new_part.name), { level = found_quality - 1 + i })
                            new_part.probability = prob * (part.probability or 1.0)
                            if new_part.min_amount == nil and new_part.amount == nil then
                                new_part.amount = 1
                            end
                            table.insert(new_results, new_part)
                        end
                    end
                end
                return new_results
            end

            for _, recipe_root in pairs({ new_recipe, new_recipe.normal, new_recipe.expensive }) do
                if recipe_root then
                    recipe_root.results = handle_recipe_part(recipe_root.results)
                    recipe_root.hide_from_player_crafting = true
                    recipe_root.allow_as_intermediate = false
                end
            end
        end
    end
end

lib.flush_prototypes()
