# Features

Quality modules inspired by FFF-375, but very janky!

* Quality modules as items. Can't be placed directly in machines. Use module to drag around relevant machines to insert, right click drag to remove.
* Various crafting machine variations with baked-in quality modules. For use with bots, assemblers can craft these from base machine and modules.
* Quality upgrades for many items, inspired by the FFF.
* Recycling according to FFF.
* Deleveling turns quality items into several normal items. Useful for utilizing quality science. 

# Compatibility

* Vanilla
* Wasn't tested and probably won't work with any overhauls
* Will not work with huge overhauls due to recipe counts

# Settings

## Startup

* Show programming baked machines from base and module on player - Unneeded with selection tool.
* Enabled/disable additional quality bonuses not in the FFF - Reasonable upgrades like lamp range and fuel values.
* Extra quality bonuses string - A simple way to add extra quality bonuses. See source homepage for details.
* Recycling efficiency - Portion of ingredients of items returned by the recycler. Default: 0.25.
* Alternate item quality icon position - Moves the quality icon to the top left, so it is more visible on compacted belts.
* No quality on item/subgroup/group - Used for compatibility with mods.

## Runtime

* Show quality only in certain proximity - Used in megabases where performance suffers due to overlay count
* Tick rate for updating proximity overlays - Used in conjunction with the above to aid performance.

# Modding interface

This mod has a modding interface, for simple addition of new quality bonuses. See source code page for more details. 

# Known issues

* Quality production works with probability recipes. Results can sometimes disappear or output several items. In large quantities this averages out.
* Researching all technologies (/cheat) is slow. This is an engine issue.
* Quality indicators do not appear on ghosts or GUIs.
* Some quality indicators look strange on recipes and equipment.
* Mining drills do not get the bonuses from the FFF.

# Future plans

* More SA quality bonuses (some capsules, miners)
* More extra non-SA quality bonuses (vehicle speed, tile speed)
