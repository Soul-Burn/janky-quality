local libq = require("__janky-quality__/lib/quality")

for _, character in pairs(data.raw.character) do
    for _, animation in pairs(character.animations) do
        if animation.armors then
            local new_armors = {}
            for _, armor in pairs(animation.armors) do
                if not libq.forbids_quality(armor) then
                    for _, q in pairs(libq.qualities) do
                        table.insert(new_armors, libq.name_with_quality(armor, q))
                    end
                end
            end
            animation.armors = new_armors
        end
    end
    local new_categories = {}
    for _, crafting_category in pairs(character.crafting_categories or {"crafting"}) do
        table.insert(new_categories, crafting_category)
        table.insert(new_categories, libq.name_with_quality_forbidden(crafting_category))
    end
    character.crafting_categories = new_categories
end
