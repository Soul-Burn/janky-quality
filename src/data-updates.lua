local util = require("util")

local sha256 = require("lib/sha256")

local disable_direct_recipes = settings.startup["fm-disable-direct-recipes"].value
local disable_blank_recipes = settings.startup["fm-disable-blank-recipes"].value


-- Utils
local function copy_icons(prototype)
  if prototype.icon then
    return {
      {
        icon = prototype.icon,
        icon_size = prototype.icon_size,
        icon_mipmaps = prototype.icon_mipmaps,
      }
    }
  else
    local copy = util.table.deepcopy(prototype.icons)
    for _, icon in ipairs(copy) do
      icon.icon_size = icon.icon_size or prototype.icon_size
      icon.icon_mipmaps = icon.icon_mipmaps or prototype.icon_mipmaps
    end
    return copy
  end
end

local function extract_level(name)
  return name:match("-(%d+)$") or "1"
end

local names = {}

function names.blank(name)
  local level = extract_level(name)
  return "fm-blank-module" .. (level == "1" and "" or "-" .. level)
end

function names.program(name)
  return "fm-program-module-" .. name
end

function names.erase(name)
  return "fm-erase-module-" .. name
end


-- Subgroups
local module_subgroups = {}
for _, module in pairs(data.raw.module) do
  module_subgroups[module.subgroup] = data.raw["item-subgroup"][module.subgroup]
end
for _, subgroup in pairs(module_subgroups) do
  local function make_subgroup(name)
    return {
      name = name .. "-" .. subgroup.name,
      type = "item-subgroup",
      group = subgroup.group,
      order = subgroup.order .. "-" .. name,
    }
  end
  data:extend({
    make_subgroup("fm-blank"),
    make_subgroup("fm-program"),
    make_subgroup("fm-erase"),
  })
end


-- Ingredients
local function translate_ingredient_name(name)
  return data.raw.module[name] and names.blank(name) or name
end

local function calculate_recipe_identifier(recipe)
  local identifiers = {}
  for _, item in ipairs(recipe.ingredients) do
    local key = translate_ingredient_name(item.name or item[1])
    local value = item.amount or item[2]
    table.insert(identifiers, key .. "=" .. value)
  end
  table.sort(identifiers)
  table.insert(identifiers, tostring(recipe.energy_required))
  table.insert(identifiers, data.raw.module[recipe.name].subgroup)
  return sha256.hash256(table.concat(identifiers, "|"))
end

function names.blank_from(recipe)
  return "fm-blank-module-from-" .. calculate_recipe_identifier(recipe)
end


-- Items and recipes
local function new_blank_module_item(recipe)
  local level = extract_level(recipe.name)
  return {
    name = names.blank(recipe.name),
    type = "item",
    localised_name = {"item-name.fm-blank", level},
    icons = {
      {
        icon = "__base__/graphics/technology/module.png",
        icon_size = 256,
      },
      {
        icon = "__base__/graphics/icons/signal/signal_" .. level .. ".png",
        icon_size = 64,
        scale = 32 / 64 * 0.5,
        shift = {-10, 10},
      },
    },
    stack_size = 50,
    subgroup = "fm-blank-" .. data.raw.module[recipe.name].subgroup,
    order = level,
  }
end

local function new_program_recipe(recipe)
  local name = recipe.name
  local icons = copy_icons((recipe.icon or recipe.icons) and recipe or data.raw.module[name])
  table.insert(icons, {
    icon = "__base__/graphics/technology/advanced-electronics-2.png",
    icon_size = 256,
    scale = 32 / 256 * 0.6,
    shift = {-8, 8},
  })

  return {
    name = names.program(name),
    type = "recipe",
    localised_name = {"recipe-name.fm-program", {"item-name." .. name}},
    ingredients = {{name = names.blank(name), amount = 1}},
    result = name,
    allow_as_intermediate = false,
    always_show_products = true,
    enabled = false,
    icons = icons,
    subgroup = "fm-program-" .. data.raw.module[recipe.name].subgroup,
    order = data.raw.module[name].order,
  }
end

local function new_erase_recipe(recipe)
  local name = recipe.name
  local icons = copy_icons((recipe.icon or recipe.icons) and recipe or data.raw.module[name])
  table.insert(icons, {
    icon = "__core__/graphics/cancel.png",
    icon_size = 64,
    scale = 32 / 64 * 0.5,
    shift = {-10, 10},
  })

  return {
    name = names.erase(name),
    type = "recipe",
    localised_name = {"recipe-name.fm-erase", {"item-name." .. name}},
    ingredients = {{name = name, amount = 1}},
    result = names.blank(name),
    allow_as_intermediate = false,
    allow_intermediates = false,
    always_show_products = true,
    enabled = false,
    icons = icons,
    subgroup = "fm-erase-" .. data.raw.module[recipe.name].subgroup,
    order = data.raw.module[name].order,
  }
end

local function translate_to_blank_recipe(recipe)
  local new_ingredients = {}
  for _, ingredient in ipairs(recipe.ingredients) do
    table.insert(new_ingredients, {
      name = translate_ingredient_name(ingredient.name or ingredient[1]),
      amount = ingredient.amount or ingredient[2],
      type = ingredient.type,
    })
  end

  return {
    name = names.blank_from(recipe),
    type = "recipe",
    ingredients = new_ingredients,
    result = names.blank(recipe.name),
    allow_as_intermediate = true,
    enabled = false,
    energy_required = recipe.energy_required,
    order = extract_level(recipe.name),
    subgroup = "fm-blank-" .. data.raw.module[recipe.name].subgroup,
    category = recipe.category,
    hidden = disable_blank_recipes,
  }
end

-- We use a temporary table to de-dupe recipes
local new_prototypes = {}
local function add_prototype(prototype)
  new_prototypes[prototype.name] = prototype
end
for _, module in pairs(data.raw.module) do
  local module_recipe = data.raw.recipe[module.name]
  if module_recipe then
    add_prototype(new_blank_module_item(module_recipe))
    add_prototype(new_program_recipe(module_recipe))
    add_prototype(new_erase_recipe(module_recipe))
    add_prototype(translate_to_blank_recipe(module_recipe))
  end
end
for _, item in pairs(new_prototypes) do
  data:extend({item})
end

-- Technologies
for _, technology in pairs(data.raw.technology) do
  if technology.effects then
    local new_unlocks = {}
    local original_module_unlock_indexes = {}

    for i, effect in ipairs(technology.effects) do
      if effect.type == "unlock-recipe" and data.raw.module[effect.recipe] then
        local recipe = data.raw.recipe[effect.recipe]
        if recipe and not recipe.hidden then
          if not disable_blank_recipes then
            new_unlocks[names.blank_from(recipe)] = true
          end
          new_unlocks[names.program(recipe.name)] = true
          new_unlocks[names.erase(recipe.name)] = true
        end
        table.insert(original_module_unlock_indexes, i)
      end
    end

    -- Remove direct recipes
    if disable_direct_recipes then
      for i = #original_module_unlock_indexes, 1, -1 do
        table.remove(technology.effects, original_module_unlock_indexes[i])
      end
    end

    -- Add new recipes
    for recipe, _ in pairs(new_unlocks) do
      table.insert(technology.effects, {type = "unlock-recipe", recipe = recipe})
    end
  end
end

if disable_direct_recipes then
  for _, module in pairs(data.raw.module) do
    data.raw.recipe[module.name].hidden = true
  end
end
