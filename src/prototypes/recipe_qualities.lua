for _, p in pairs(data.raw.recipe) do
    for _, quality in pairs(lib.qualities) do
        if quality.level ~= 1 then
            local new_recipe = lib.copy_and_add_prototype(p, quality)
            if new_recipe.main_product and new_recipe.main_product ~= "" then
                new_recipe.main_product = lib.name_with_quality(new_recipe.main_product, quality)
            end

            local function handle_recipe_part(parts)
                if parts == nil then
                    return
                end
                for _, part in pairs(parts) do
                    if part.type == "fluid" then
                        part.name = lib.name_without_quality(part.name)
                    elseif part.type == "item" or part.name then
                        part.name = lib.name_with_quality(lib.name_without_quality(part.name), quality)
                    else
                        part[1] = lib.name_with_quality(lib.name_without_quality(part[1]), quality)
                    end
                end
            end

            for _, recipe_root in pairs({ new_recipe, new_recipe.normal, new_recipe.expensive }) do
                if recipe_root then
                    handle_recipe_part(recipe_root.ingredients)
                    handle_recipe_part(recipe_root.results)
                    if recipe_root.result then
                        recipe_root.result = lib.name_with_quality(lib.name_without_quality(recipe_root.result), quality)
                    end
                    recipe_root.hide_from_player_crafting = true
                    recipe_root.allow_as_intermediate = false
                end
            end
        end
    end
end

lib.flush_prototypes()