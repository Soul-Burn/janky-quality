local lib = require("__janky-quality__/lib/lib")
local libq = require("__janky-quality__/lib/quality")

for _, p in pairs(data.raw.item) do
    if p.place_as_tile then
        for _, quality in pairs(libq.qualities) do
            if quality.level ~= 1 then
                local handled = {}
                local tile_name = p.place_as_tile.result
                while tile_name and not handled[tile_name] do
                    local tile = lib.add_prototype(libq.copy_prototype(data.raw.tile[tile_name], quality))
                    if tile.minable then
                        local _, results = lib.get_canonic_recipe(tile.minable)
                        assert(#results == 1, "Tile with weird number of results: " .. #results)
                        results[1].name = libq.name_with_quality(libq.name_without_quality(results[1].name), quality)
                        tile.minable.results = results
                    end
                    handled[tile_name] = true
                    tile_name = tile.next_direction
                    if tile.next_direction then
                        tile.next_direction = libq.name_with_quality(tile.next_direction, quality)
                    end
                end
            end
        end
    end
end
