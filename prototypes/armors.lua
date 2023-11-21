local libq = require("__janky-quality__/lib/quality")

for _, character in pairs(data.raw.character) do
    for _, animation in pairs(character.animations) do
        if animation.armors then
            local new_armors = {}
            for _, armor in pairs(animation.armors) do
                for _, q in pairs(libq.qualities) do
                    table.insert(new_armors, libq.name_with_quality(armor, q))
                end
            end
            animation.armors = new_armors
        end
    end
end