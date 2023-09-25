local lib = require("__janky-quality__/lib/lib")

for _, grid in pairs(data.raw["equipment-grid"]) do
    for _, quality in pairs(lib.qualities) do
        if quality.level ~= 1 then
            local new_grid = table.deepcopy(grid)
            new_grid.name = lib.name_with_quality(new_grid.name, quality)
            new_grid.width = new_grid.width + quality.modifier
            new_grid.height = new_grid.height + quality.modifier
            lib.add_prototype(new_grid)
        end
    end
end

lib.flush_prototypes()
