local function handle_recipe(recipe)
    if recipe.subgroup and (recipe.subgroup == "fill-barrel" or recipe.subgroup == "empty-barrel") then
        return
    end
    for _, quality_module in pairs(libq.quality_modules) do
        for _, module_count in pairs(libq.slot_counts) do
            local new_recipe = table.deepcopy(recipe)
            lib.add_prototype(new_recipe)
            new_recipe.name = libq.name_with_quality_module(new_recipe.name, module_count, quality_module)
            new_recipe.category = libq.name_with_quality_module((new_recipe.category or "crafting"), module_count, quality_module)

            for _, recipe_root in pairs({ new_recipe, new_recipe.normal, new_recipe.expensive }) do
                if recipe_root then
                    recipe_root.ingredients, recipe_root.results = lib.get_canonic_recipe(recipe_root)
                    recipe_root.results = libq.transform_results_with_probabilities(recipe_root.results, module_count, quality_module)
                    recipe_root.hide_from_player_crafting = true
                    recipe_root.allow_as_intermediate = false

                    if ((new_recipe.icon == nil and new_recipe.icons == nil) or new_recipe.subgroup == nil) and recipe_root.main_product == nil then
                        if new_recipe.main_product then
                            recipe_root.main_product = new_recipe.main_product
                        elseif data.raw.fluid[libq.name_without_quality(recipe.name)] then
                            new_recipe.main_product = libq.name_without_quality(recipe.name)
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
