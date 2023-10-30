# Factorio-janky-quality
Factorio mod that adds "quality", inspired by [FFF #375](https://factorio.com/blog/post/fff-375). 
See the mod page on the [Mod portal](https://mods.factorio.com/mod/janky-quality)

## Features

* Quality modules as items - not actual modules you can put in machines
* Various crafting machine variations with baked in quality modules, assemble from machine and modules
* Quality upgrades for many items, inspired by the FFF
* Recycling

## Modding interface

During data phase, use the "jq_entity_mods" global to define new quality bonuses. Update `jq_entity_mods.entity_mods` with modifier functions.
See `entity_mods.lua` and `quality_bonuses.lua` for examples.
