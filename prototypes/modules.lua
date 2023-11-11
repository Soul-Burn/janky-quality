local libq = require("__janky-quality__/lib/quality")

-- Limitations must be done on all modules
for _, p in pairs(data.raw.module) do
    if p.limitation then
        local new_limitations = {}
        for _, limitation in pairs(p.limitation) do
            for _, q in pairs(libq.qualities) do
                local limitation_name = libq.name_with_quality(limitation, q)
                if data.raw.recipe[limitation_name] then
                    table.insert(new_limitations, limitation_name)
                end
            end
        end
        for _, limitation in pairs(new_limitations) do
            table.insert(p.limitation, limitation)
        end
    end
end
