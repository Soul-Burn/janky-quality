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

    local main_product = recipe.name
    local recipe_proto = table.deepcopy(recipe)
    for _, recipe_root in pairs { recipe_proto, recipe_proto.normal, recipe_proto.expensive } do
        if recipe_root then
            recipe_root.enabled = false
            recipe_root.ingredients, recipe_root.results = lib.get_canonic_recipe(recipe_root)
            local single_result = recipe_root.results and #recipe_root.results == 1 and recipe_root.results[1].name
            if recipe_root.ingredients and recipe_root.results then
                -- we don't want to fluids to split into more output boxes so we split them early
                local quality_forbidden_results, quality_results, non_catalyst_results, catalyst_results = libq.split_forbidden_and_catalysts(recipe_root)
                recipe_root.non_catalyst_results = non_catalyst_results
                if #quality_results == 0 or #non_catalyst_results == 0 then
                    return
                end
                recipe_root.results = catalyst_results
                lib.table_extend(recipe_root.results, quality_forbidden_results)
            end

            recipe_root.hide_from_player_crafting = true
            recipe_root.allow_as_intermediate = false

            if libq.forbids_quality(libq.name_without_quality(recipe.name)) then
                main_product = libq.name_without_quality(recipe.name)
            elseif single_result then
                main_product = single_result
            end
        end
    end

    if ((not recipe_proto.icon and not recipe_proto.icons) or not recipe_proto.subgroup) then
        for _, recipe_root in pairs { recipe_proto, recipe_proto.normal, recipe_proto.expensive } do
            if recipe_root and not recipe_root.main_product then
                recipe_root.main_product = main_product
            end
        end
    end

    for _, quality_module in pairs(libq.quality_modules) do
        for module_count, _ in pairs(recipe_category_to_slots[recipe_category]) do
            local new_recipe = table.deepcopy(recipe_proto)
            new_recipe.name = libq.name_with_quality_module(new_recipe.name, module_count, quality_module)
            new_recipe.category = libq.name_with_quality_module(recipe_category, module_count, quality_module)

            for _, recipe_root in pairs({ new_recipe, new_recipe.normal, new_recipe.expensive }) do
                if recipe_root and recipe_root.non_catalyst_results then
                    local quality_results = libq.transform_results_with_probabilities(recipe_root.non_catalyst_results, module_count, quality_module)
                    lib.table_extend(recipe_root.results, quality_results)
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
