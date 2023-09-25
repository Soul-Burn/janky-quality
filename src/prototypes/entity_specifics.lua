local lib = require("__janky-quality__/lib/lib")

return {
    ["electric-pole"] = function(p, quality)
        p.supply_area_distance = p.supply_area_distance + quality.modifier
        p.maximum_wire_distance = p.maximum_wire_distance + 2 * quality.modifier
    end,
    ["module"] = function(p, quality)
        if p.limitation then
            local new_limitations = {}
            for _, limitation in pairs(p.limitation) do
                for _, q in pairs(lib.qualities) do
                    if q.level ~= 1 then
                        table.insert(new_limitations, lib.name_with_quality(limitation, q))
                    end
                end
            end
            for _, limitation in pairs(new_limitations) do
                table.insert(p.limitation, limitation)
            end
        end

        local effect
        if p.category == "productivity" then
            effect = p.effect.productivity
        elseif p.category == "speed" then
            effect = p.effect.speed
        elseif p.category == "effectivity" then
            effect = p.effect.consumption
        end
        if effect then
            effect.bonus = effect.bonus * (1 + 0.3 * quality.modifier)
        end
    end,
    ["rail-planner"] = function(p, quality)
        p.place_result = nil
        p.type = "item"
    end,
}
