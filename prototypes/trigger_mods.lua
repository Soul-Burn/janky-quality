local libq = require("__janky-quality__/lib/quality")

local mods = {}

function mods.effect(effect, quality)
    if not effect then
        return
    end
    for _, e in pairs(effect.type and { effect } or effect) do
        if e.damage then
            e.damage.amount = e.damage.amount * (1.0 + 0.3 * quality.modifier)
        end
        mods.trigger(e.action, quality)
        if e.sticker then
            e.sticker = libq.name_with_quality(libq.name_without_quality(e.sticker), quality)
        end
        if e.type == "create-fire" then
            e.entity_name = libq.name_with_quality(libq.name_without_quality(e.entity_name), quality)
        end
    end
end

function mods.delivery(delivery, quality)
    if not delivery then
        return
    end
    for _, d in pairs(delivery.type and { delivery } or delivery) do
        mods.effect(d.source_effects, quality)
        mods.effect(d.target_effects, quality)
        for _, name in pairs({ "projectile", "beam", "stream" }) do
            if d[name] then
                d[name] = libq.name_with_quality(libq.name_without_quality(d[name]), quality)
            end
        end
    end
end

function mods.trigger(trigger, quality)
    if not trigger then
        return nil
    end
    for _, t in pairs(trigger.type and { trigger } or trigger) do
        mods.effect(t.range_effects, quality)
        mods.delivery(t.action_delivery, quality)
    end
    return trigger
end

function mods.ammo(ammo, quality)
    if not ammo or not ammo.ammo_type then
        return nil
    end
    local ammo_type = ammo.ammo_type
    for _, at in pairs(ammo_type.category and { ammo_type } or ammo_type) do
        mods.trigger(at.action, quality)
    end
    return ammo
end

return mods
