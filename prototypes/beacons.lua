local lib = require("__janky-quality__/lib/lib")

if not settings.startup["jq-beacon-overlay"].value then
    return
end

for _, beacon in pairs(data.raw.beacon) do
    if beacon.graphics_set and beacon.graphics_set.module_visualisations and beacon.graphics_set.module_visualisations[1].slots then
        for i, slot in pairs(beacon.graphics_set.module_visualisations[1].slots) do
            if #slot == 4 then
                local quality_layer = table.deepcopy(slot[2])
                quality_layer.pictures.filename = lib.p.gfx .. "beacon-quality-mask-" .. i .. ".png"
                quality_layer.pictures.hr_version.filename = lib.p.gfx .. "hr-beacon-quality-mask-" .. i .. ".png"
                quality_layer.apply_module_tint = "tertiary"
                table.insert(slot, quality_layer)
            end
        end
    end
end
