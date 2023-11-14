local lib = require("__janky-quality__/lib/lib")

local nq = {}

local cats = {
    "fluid", "player-port", "simple-entity-with-force", "simple-entity-with-owner", "infinity-container", "infinity-pipe",
    "linked-container", "linked-belt", "electric-energy-interface", "blueprint", "copy-paste-tool", "deconstruction-item", "upgrade-item",
    "blueprint-book", "mining-tool",
}

for _, cat in pairs(cats) do
    for _, p in pairs(data.raw[cat]) do
        nq[p.name] = true
    end
end

local groups = { "other", "ee-tools", "creative-mod_creative-tools" }
local subgroup_set = util.list_to_map { "textplates" }

for _, group in pairs(groups) do
    for _, subgroup in pairs(data.raw["item-subgroup"]) do
        if subgroup.group == group then
            subgroup_set[subgroup.name] = true
        end
    end
end

for cat, _ in pairs(defines.prototypes.item) do
    for _, item in pairs(data.raw[cat]) do
        if subgroup_set[item.subgroup] then
            nq[item.name] = true
        end
    end
end

local entity_categories_with_placed = { "constant-combinator" }

for _, cat in pairs(entity_categories_with_placed) do
    for _, entity in pairs(data.raw[cat]) do
        local _, results = lib.get_canonic_recipe(entity.minable)
        if results then
            for _, result in pairs(results) do
                if nq[result.name] then
                    nq[entity.name] = true
                    break
                end
            end
        end
        if entity.placeable_by then
            for _, item_to_place in pairs(entity.placeable_by.item and { entity.placeable_by } or entity.placeable_by) do
                if nq[item_to_place.item] then
                    nq[entity.name] = true
                    break
                end
            end
        end
    end
end

local entity_categories_with_minable = { "container", "tile" }

for _, cat in pairs(entity_categories_with_minable) do
    for _, entity in pairs(data.raw[cat]) do
        if (not entity.minable or not (entity.minable.result or entity.minable.results)) and not data.raw.item[entity.name] then
            nq[entity.name] = true
        end
    end
end

return nq
