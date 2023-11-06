local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

local function all_fluid(recipe_part)
    if not recipe_part then
        return False
    end
    for _, item in pairs(recipe_part) do
        if item.type ~= "fluid" then
            return False
        end
    end
    return #recipe_part ~= 0
end

for _, p in pairs(data.raw.recipe) do
    for _, quality in pairs(libq.qualities) do
        if quality.level ~= 1 then
            local new_recipe = libq.copy_prototype(p, quality)
            if new_recipe.main_product and new_recipe.main_product ~= "" then
                new_recipe.main_product = libq.name_with_quality(new_recipe.main_product, quality)
            end

            local function handle_recipe_part(parts)
                if not parts then
                    return
                end
                for _, part in pairs(parts) do
                    if part.type == "fluid" then
                        part.name = libq.name_without_quality(part.name)
                    elseif part.type == "item" then
                        part.name = libq.name_with_quality(libq.name_without_quality(part.name), quality)
                    else
                        log(serpent.block(p))
                        log(serpent.block(parts))
                        error("Invalid recipe")
                    end
                end
            end

            local add_prototype = true
            for _, recipe_root in pairs({ new_recipe, new_recipe.normal, new_recipe.expensive }) do
                if recipe_root then
                    recipe_root.ingredients, recipe_root.results = lib.get_canonic_recipe(recipe_root)
                    if all_fluid(recipe_root.ingredients) then
                        add_prototype = false
                    end
                    handle_recipe_part(recipe_root.ingredients)
                    handle_recipe_part(recipe_root.results)
                    recipe_root.hide_from_player_crafting = true
                    recipe_root.allow_as_intermediate = false
                end
            end
            if add_prototype then
                lib.add_prototype(new_recipe)
            end
        end
    end
end

lib.flush_prototypes()
