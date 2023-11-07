local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

local recipe_category_to_slots = libq.get_recipe_category_to_slots()

for recipe_category, slots_counts in pairs(recipe_category_to_slots) do
    for _, q in pairs(libq.quality_modules) do
        for slot_count, _ in pairs(slots_counts) do
            lib.add_prototype({ name = libq.name_with_quality_module(recipe_category, slot_count, q), type = "recipe-category" })
        end
    end
end

local function handle_recipe(recipe)
    local recipe_category = recipe.category or "crafting"
    if not recipe_category_to_slots[recipe_category] then
        return
    end
    for _, quality_module in pairs(libq.quality_modules) do
        for module_count, _ in pairs(recipe_category_to_slots[recipe_category]) do
            local new_recipe = table.deepcopy(recipe)
            new_recipe.name = libq.name_with_quality_module(new_recipe.name, module_count, quality_module)
            new_recipe.category = libq.name_with_quality_module(recipe_category, module_count, quality_module)

            for _, recipe_root in pairs({ new_recipe, new_recipe.normal, new_recipe.expensive }) do
                if recipe_root then
                    recipe_root.ingredients, recipe_root.results = lib.get_canonic_recipe(recipe_root)
                    local single_result = recipe_root.results and #recipe_root.results == 1 and recipe_root.results[1].name
                    if recipe_root.ingredients and recipe_root.results then
                        -- we don't want to fluids to split into more output boxes so we split them early
                        local fluid_results, item_results = lib.partition_array(recipe_root.results, function(item)
                            return item.type == "fluid"
                        end)
                        local non_catalyst_results, catalyst_results = lib.split_by_catalysts({ ingredients = recipe_root.ingredients, results = item_results })
                        recipe_root.results = catalyst_results
                        lib.table_extend(recipe_root.results, libq.transform_results_with_probabilities(non_catalyst_results, module_count, quality_module))
                        lib.table_extend(recipe_root.results, fluid_results)
                    end

                    recipe_root.hide_from_player_crafting = true
                    recipe_root.allow_as_intermediate = false

                    if ((not new_recipe.icon and not new_recipe.icons) or not new_recipe.subgroup) and not recipe_root.main_product then
                        if new_recipe.main_product then
                            recipe_root.main_product = new_recipe.main_product
                        elseif data.raw.fluid[libq.name_without_quality(recipe.name)] then
                            new_recipe.main_product = libq.name_without_quality(recipe.name)
                        elseif single_result then
                            new_recipe.main_product = single_result
                        else
                            new_recipe.main_product = recipe.name
                        end
                    end
                end
            end

            lib.add_prototype(new_recipe)
        end
    end
end

for _, recipe in pairs(data.raw.recipe) do
    handle_recipe(recipe)
end

lib.flush_prototypes()
