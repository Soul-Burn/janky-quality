local lib = require("__janky-quality__/lib/lib")

--on_entity_died,
--on_player_mined_entity,
--on_robot_mined_entity,
--script_raised_destroy,

local function handle_build(event)
    local ent = event.created_entity or event.entity or event.destination
    if ent == nil then
        return
    end
    local found_quality = lib.find_quality(ent.name)
    if found_quality == 1 then
        return
    end

    local bb = ent.bounding_box
    local off_x = (bb.left_top.x - bb.right_bottom.x) / 2 + 0.15
    local off_y = (bb.right_bottom.y - bb.left_top.y) / 2 - 0.15
    rendering.draw_sprite { target = ent, surface = ent.surface, sprite = ("jq_quality_icon_" .. found_quality), target_offset = { off_x, off_y } }
end

local events = { "on_built_entity", "on_robot_built_entity", "on_entity_cloned", "script_raised_built", "script_raised_revive" }
for _, event in pairs(events) do
    script.on_event(defines.events[event], handle_build)
end
