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
                    elseif part.type == "item" then
                        part.name = lib.name_with_quality(lib.name_without_quality(part.name), quality)
                    else
                        log(serpent.block(p))
                        log(serpent.block(parts))
                        error("Invalid recipe")
                    end
                end
            end

            for _, recipe_root in pairs({ new_recipe, new_recipe.normal, new_recipe.expensive }) do
                if recipe_root then
                    recipe_root.ingredients, recipe_root.results = lib.get_canonic_recipe(recipe_root)
                    handle_recipe_part(recipe_root.ingredients)
                    handle_recipe_part(recipe_root.results)
                    recipe_root.hide_from_player_crafting = true
                    recipe_root.allow_as_intermediate = false
                end
            end
        end
    end
end

lib.flush_prototypes()
