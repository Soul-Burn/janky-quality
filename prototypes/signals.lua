local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

lib.add_prototype { group = "signals", name = "virtual-signal-quality", type = "item-subgroup", order = "q" }

for _, q in pairs(libq.qualities) do
    lib.add_prototype {
        name = "quality-" .. q.level,
        localised_name = { "jq.quality-" .. q.level },
        icon = q.icon,
        icon_size = 32,
        type = "virtual-signal",
        subgroup = "virtual-signal-quality",
    }
end

lib.flush_prototypes()
