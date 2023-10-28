local lib = require("__janky-quality__/lib/lib")

local max_ingredients = 1
for _, recipe in pairs(data.raw.recipe) do
    for _, recipe_root in pairs({recipe, recipe.normal, recipe.expensive}) do
        if recipe_root.ingredients and #recipe_root.ingredients > max_ingredients then
            max_ingredients = #recipe_root.ingredients
        end
    end
end

local entity = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
local tint = { r = 0, g = 1, b = 0, a = 1 }
entity.animation.layers[1].tint = tint
entity.animation.layers[1].hr_version.tint = tint
entity.icon = lib.p.gfx .. "recycle.png"
entity.icon_mipmaps = 0
entity.crafting_speed = 1
entity.crafting_categories = { "jq-recycling" }
entity.minable.result = "jq-recycler"
entity.name = "jq-recycler"
entity.localised_name = {"jq.recycler"}
entity.next_upgrade = nil
entity.type = "furnace"
entity.source_inventory_size = 1
entity.result_inventory_size = max_ingredients
entity.allowed_effects = { "speed", "consumption", "pollution" }
entity.module_specification = { module_slots = 4 }
entity.cant_insert_at_source_message_key = "jq.cant-recycle",
lib.add_prototype(entity)

lib.add_prototype({
    icon = lib.p.gfx .. "recycle.png",
    icon_size = 64,
    name = "jq-recycler",
    localised_name = { "jq.recycler" },
    order = "d[recycler]",
    place_result = "jq-recycler",
    stack_size = 50,
    subgroup = "production-machine",
    type = "item",
})

lib.add_prototype({ name = "jq-recycling", type = "recipe-category" })
lib.add_prototype({ group = "jq-recycling", name = "jq-recycling", type = "item-subgroup" })
lib.add_prototype({
    icon = lib.p.gfx .. "recycle.png",
    icon_size = 64,
    name = "jq-recycling",
    localised_name = { "jq.recycling" },
    order = "z",
    type = "item-group"
})

lib.add_prototype(
        {
            enabled = false,
            energy_required = 0.5,
            ingredients = {
                { "steel-plate", 5 },
                { "advanced-circuit", 5 },
                { "iron-gear-wheel", 10 },
            },
            name = "jq-recycler",
            result = "jq-recycler",
            type = "recipe"
        }
)

lib.add_prototype(
        {
            effects = { { recipe = "jq-recycler", type = "unlock-recipe" } },
            icon = lib.p.gfx .. "recycle.png",
            icon_size = 64,
            scale = 1,
            name = "jq-recycler",
            localised_name = {"jq.recycler"},
            order = "a-b-d",
            prerequisites = { "quality-module", "advanced-electronics-2" },
            type = "technology",
            unit = {
                count = 75,
                ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 } },
                time = 30
            },
            upgrade = true
        }
)

lib.flush_prototypes()

local recyclable_categories = util.list_to_map({ "crafting", "basic-crafting", "advanced-crafting", "crafting-with-fluid" })
local recycling_probability = 0.25

local items_to_skip = util.list_to_map({
    "player-port", "simple-entity-with-force", "simple-entity-with-owner", "simple-entity",
    "infinity-chest", "infinity-pipe", "linked-chest", "linked-belt",
})

function handle_item(item)
    if items_to_skip[item.name] then
        return
    end
    local new_recipe = {
        enabled = true,
        name = "jq-recycling-" .. item.name,
        localised_name = { "jq.recycling", item.localised_name or item.name },
        icon = "__core__/graphics/cancel.png",
        icon_size = 64,
        type = "recipe",
        subgroup = "jq-recycling",
        category = "jq-recycling",
        hide_from_player_crafting = true,
        allow_as_intermediate = false,
    }
    lib.add_prototype(new_recipe)

    local new_ingredients = { { type = "item", name = item.name, amount = 1 } }
    local recipe = data.raw.recipe[item.name]
    if recipe == nil or (recipe.category and recyclable_categories[recipe.category] == nil) then
        new_recipe.ingredients = new_ingredients
        new_recipe.results = { lib.normalize_probability({ type = "item", name = item.name, amount = 1, probability = recycling_probability, catalyst_amount = 0 }) }
        return
    end
    new_recipe.order = recipe.order

    function handle_root(root)
        if root == nil or (root.result == nil and root.results == nil) then
            return nil
        end
        local new_root = {
            hide_from_player_crafting = true,
            allow_as_intermediate = false,
            category = "jq-recycling",
            ingredients = new_ingredients,
            energy_required = 0.5,
        }
        local ingredients, results = lib.get_canonic_recipe(root)
        assert(#results == 1, "Recipe with too many results " .. serpent.block(results))
        assert(results[1].name == item.name, "Wrong item name " .. serpent.block(item) .. " " .. serpent.block(results))
        assert(results[1].type == "item", "Wrong item type " .. serpent.block(results))
        new_root.results = {}
        for _, ingredient in pairs(ingredients) do
            if ingredient.type == "item" then
                local new_i = lib.normalize_probability({
                    type = "item", name = ingredient.name, amount = ingredient.amount, probability = recycling_probability / results[1].amount, catalyst_amount = 0
                })
                table.insert(new_root.results, new_i)
            end
        end
        return new_root
    end

    lib.table_update(new_recipe, handle_root(recipe) or {})
    new_recipe.normal = handle_root(recipe.normal)
    new_recipe.expensive = handle_root(recipe.expensive)
end

for _, category in pairs({ "item", "capsule", "item-with-entity-data", "armor", "gun" }) do
    for _, item in pairs(data.raw[category]) do
        handle_item(item)
    end
end

lib.flush_prototypes()
