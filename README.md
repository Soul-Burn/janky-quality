# Factorio-janky-quality
Factorio mod that adds "quality", inspired by [FFF #375](https://factorio.com/blog/post/fff-375). 
See the mod page on the [Mod portal](https://mods.factorio.com/mod/janky-quality)

## Features

* Quality modules as items - not actual modules you can put in machines
* Various crafting machine variations with baked in quality modules, assemble from machine and modules
* Quality upgrades for many items, inspired by the FFF
* Recycling and deleveling

## Modding interface

This mod supports adding quality bonuses in several ways. A simple method through a mod setting, and a more complete way by writing a mod.

Modifiers are applied per category. Each part includes a path inside the prototype, and a function to apply. See the [Factorio prototype documentation](https://lua-api.factorio.com/latest/index-prototype.html) for reference.

Common functions that are allowed are:

* mult - A multiplicative modifier e.g. `mult 0.3` would increase values by 30% per quality modifier
* add - An additive modifier e.g. `add 2` would increase values by 2 per quality modifier
* with_quality - A special modifier that is applied to string references e.g. `with_quality` could choose a quality gun or equipment grid

All operations resolve energy fields correctly

Paths are separated with `.` symbols. A number can be used as entry into table. Finishing the path with `.?` considers the path optional.

Usually, bonuses are added to the exiting modification, but using `-` as prefix to the category will override the existing modification.

The special category `__all__` applies to all processed prototypes.
Other super categories are available as in `defines.prototypes` such as `__entity__` and `__item__` to applies to all entities or items.
Useful for modifications like health or fuel values.

### Simple

In the mod settings, an import string can be placed. The format is as follows:

* Categories are separated by `;`
* Category definition is separated by `:`
* Modification parts are separated by `,`
* Modification definition is separated by `=`
* Modification parameters are separated by space ` `

For example:

    car:effectivity=mult 0.3;-armor:equipment_grid=with_quality

### Advanced

During data phase, the `jq_entity_mods` global can be used to define new quality bonuses. The method `jq_entity_mods.update_mods` accepts a table mapping categories to mods.  
See `quality_bonuses.lua` and `quality_bonuses_extras.lua` for examples, and `entity_mods.lua` for the library.  

Set dependency on this mod to ensure your mod's data phase runs after this one.