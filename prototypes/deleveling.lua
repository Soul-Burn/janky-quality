local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

local entity = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
local tint = { r = 0.5, g = 0.5, b = 1, a = 1 }
entity.animation.layers[1].tint = tint
entity.animation.layers[1].hr_version.tint = tint
entity.icon = lib.p.gfx .. "deleveler.png"
entity.icon_mipmaps = 0
entity.crafting_speed = 1
entity.crafting_categories = { "jq-deleveling" }
entity.minable.result = "jq-deleveler"
entity.name = "jq-deleveler"
entity.localised_name = { "jq.deleveler" }
entity.next_upgrade = nil
entity.type = "furnace"
entity.source_inventory_size = 1
entity.result_inventory_size = libq.qualities[#libq.qualities].modifier + 1
entity.allowed_effects = { }
entity.module_specification = { }
entity.cant_insert_at_source_message_key = "jq.cant-delevel"
lib.add_prototype(entity)

lib.add_prototype {
    icon = lib.p.gfx .. "deleveler.png",
    icon_size = 64,
    name = "jq-deleveler",
    localised_name = { "jq.deleveler" },
    order = "d[deleveler]",
    place_result = "jq-deleveler",
    stack_size = 50,
    subgroup = "production-machine",
    type = "item",
    order = "zz",
}

lib.add_prototype { name = "jq-deleveling", type = "recipe-category" }
lib.add_prototype { group = "jq-deleveling", name = "jq-deleveling", type = "item-subgroup" }
lib.add_prototype {
    icon = lib.p.gfx .. "deleveler.png",
    icon_size = 64,
    name = "jq-deleveling",
    localised_name = { "jq.deleveling" },
    order = "z",
    type = "item-group"
}

lib.add_prototype {
    enabled = false,
    energy_required = 0.5,
    ingredients = {
        { "iron-plate", 5 },
        { "electronic-circuit", 5 },
        { "iron-gear-wheel", 10 },
    },
    name = "jq-deleveler",
    result = "jq-deleveler",
    type = "recipe"
}

table.insert(data.raw.technology["quality-module"].effects, { recipe = "jq-deleveler", type = "unlock-recipe" })

lib.flush_prototypes()

local function handle_item(item)
    local found_quality = libq.find_quality(item.name)
    if found_quality == 1 then
        return
    end

    local new_recipe = {
        enabled = true,
        name = "jq-deleveling-" .. item.name,
        localised_name = { "jq.deleveling", item.localised_name or item.name },
        icon = lib.p.gfx .. "deleveler.png",
        icon_size = 64,
        type = "recipe",
        subgroup = "jq-deleveling",
        category = "jq-deleveling",
        hide_from_player_crafting = true,
        allow_as_intermediate = false,
        ingredients = { { type = "item", name = item.name, amount = 1 } },
        results = { },
    }

    local name_without_quality = libq.name_without_quality(item.name)
    local result_count = libq.qualities[found_quality].modifier + 1
    if item.stack_size == 1 then
        for _ = 1, result_count do
            table.insert(new_recipe.results, { type = "item", name = name_without_quality, amount = 1 })
        end
    else
        table.insert(new_recipe.results, { type = "item", name = name_without_quality, amount = result_count })
    end

    lib.add_prototype(new_recipe)
end

for category, _ in pairs(defines.prototypes.item) do
    for _, item in pairs(data.raw[category]) do
        handle_item(item)
    end
end

lib.flush_prototypes()
