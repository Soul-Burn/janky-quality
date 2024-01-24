local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

for recipe_category in pairs(data.raw["recipe-category"]) do
    for _, quality in pairs(libq.qualities) do
        if quality.level ~= 1 then
            lib.add_prototype { name = libq.name_with_quality(recipe_category, quality), type = "recipe-category" }
        end
    end
end

local function all_forbidden_quality(recipe_part)
    if not recipe_part then
        return false
    end
    for _, item in pairs(recipe_part) do
        if not libq.forbids_quality(item.name) then
            return false
        end
    end
    return true
end

for _, recipe in pairs(data.raw.recipe) do
    local all_forbidden_recipe_name
    for _, quality in pairs(libq.qualities) do
        if quality.level ~= 1 then
            local new_recipe = libq.copy_prototype(recipe, quality)
            if new_recipe.main_product and new_recipe.main_product ~= "" and not libq.forbids_quality(new_recipe.main_product) then
                new_recipe.main_product = libq.name_with_quality(new_recipe.main_product, quality)
            end

            local function handle_recipe_part(parts)
                if not parts then
                    return
                end
                for _, part in pairs(parts) do
                    part.name = libq.name_without_quality(part.name)
                    if not libq.forbids_quality(part.name) then
                        part.name = libq.name_with_quality(part.name, quality)
                    end
                end
            end

            local add_prototype = true
            for _, recipe_root in pairs { new_recipe, new_recipe.normal, new_recipe.expensive } do
                if recipe_root then
                    recipe_root.enabled = false
                    recipe_root.ingredients, recipe_root.results = lib.get_canonic_recipe(recipe_root)
                    if recipe_root.ingredients and recipe_root.results then
                        if all_forbidden_quality(recipe_root.ingredients) then
                            add_prototype = false
                        end
                        local _, quality_results, non_catalyst_results, _ = libq.split_forbidden_and_catalysts(recipe_root)
                        if #quality_results == 0 or #non_catalyst_results == 0 then
                            all_forbidden_recipe_name = libq.name_with_quality_forbidden(recipe.category or "crafting")
                        end
                        handle_recipe_part(recipe_root.ingredients)
                        handle_recipe_part(recipe_root.results)
                        recipe_root.hide_from_player_crafting = true
                        recipe_root.allow_as_intermediate = false
                    end
                end
            end
            if add_prototype then
                new_recipe.category = all_forbidden_recipe_name or libq.name_with_quality(recipe.category or "crafting", quality)
                lib.add_prototype(new_recipe)
            end
        end
    end
    if all_forbidden_recipe_name then
        recipe.category = all_forbidden_recipe_name
    end
end

lib.flush_prototypes()
