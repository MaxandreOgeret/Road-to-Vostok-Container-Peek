# Container Peek

<p align="center">
  <img src="doc/screenshot.png" alt="Container Peek screenshot" />
</p>

`Container Peek` is a `Road to Vostok` mod that opens a compact loot window when you look at a container that the game considers interactable.

## Overview

The mod follows the game's own interaction logic instead of running a separate container scan. It uses the live interactor target, respects the container's interaction range when that information is available, and falls back to `2.5m` when it is not. The peek window hides when the game is paused so it does not overlap the pause menu.

The loot window shows item names, total displayed weight, and condition in a compact table with a fixed header and a real scrollbar. Rarity colors can be enabled for item names, and the selected row keeps its rarity color instead of switching to a neutral highlight color.

The mod also supports an optional rummaging system for first-time inspection. When rummaging is enabled, grouped item rows are revealed over time with a spinner, a single skeleton placeholder row, and optional audio based on the game's `Craft_Generic` sound. In shelters, rummaging is skipped entirely and the full contents are shown immediately.

Transfer behavior is designed to stay close to the base game. You can transfer the selected entry or take all visible contents, and failed transfers use the same error feedback the game already uses when inventory space runs out.

## Controls

By default, the mouse wheel moves the selection in the loot list, `F` transfers the selected entry to your inventory, and `R` transfers everything from the current container. These bindings can be changed in Mod Configuration Menu when MCM is installed.

## Behavior Notes

The preview groups identical item names into a single row. Because of that grouping, transferring a selected row moves the first matching stack for that name rather than a specific stack instance.

When `Rummage Time / Item` is greater than `0`, newly inspected containers reveal grouped rows over time. Setting that value to `0` restores the immediate display behavior. Empty containers still spend one rummage interval in the loading state before showing `Empty`, unless rummaging has been disabled.

`Take All` is unavailable while rummaging is still in progress. When `Take All` fails because the inventory is full, it stops at the first failed insert so the result stays predictable.

The condition column is only shown for item types that the game itself treats as condition-bearing, such as weapons, armor, helmets, rigs with armor inserts, and items that explicitly enable `showCondition`. Rarity color settings only apply to the game's real rarity tiers: `Common`, `Rare`, and `Legendary`.

## Configuration

When Mod Configuration Menu is installed, the mod exposes settings for the transfer keybind, the take-all keybind, rarity colors, rummage timing, rummage audio, menu opacity, and the three supported rarity color overrides.

`Rummage Time / Item` controls how long each grouped item row takes to appear during first inspection, and a value of `0` disables rummaging completely. `Rummage Audio` enables or disables the rummaging sound effect during reveal. `Menu Opacity` changes the background opacity of the panel without affecting text readability.

## Repository Layout

The packaged mod consists of `mod.txt` and the `ContainerPeek/` directory. The runtime logic is split across `ContainerPeek/Main.gd`, which handles scene lifecycle, UI, targeting, and transfer flow; `ContainerPeek/Config.gd`, which registers the MCM settings and input actions; `ContainerPeek/ConfigSupport.gd`, which provides runtime configuration helpers; and `ContainerPeek/ItemSupport.gd`, which handles item summaries, rarity, weight, condition, and selection helpers.

The repository also includes [doc/game-sync.md](/home/mackou/project/vostok_lootmenu/doc/game-sync.md:1), which documents the parts of the mod that intentionally mirror decompiled game logic and should be reviewed after a game update.

## Build

Create the mod archive from the repository root with the following command:

```bash
zip -r ContainerPeek.zip mod.txt ContainerPeek
```

The root of the archive must contain `mod.txt` and the `ContainerPeek/` directory.

## Installation

Copy `ContainerPeek.zip` into the game's mod folder at `~/.steam/debian-installation/steamapps/common/Road to Vostok/mods/`, then restart the game completely.

## Requirements

The mod requires `Road to Vostok` and the community mod loader format used by the game. `Mod Configuration Menu` is optional, but it is required if you want to change bindings or adjust the rummage, audio, opacity, and rarity color settings in game.

## References

The loader format and installation details are documented at <https://github.com/ametrocavich/vostok-mod-loader>. The container script reference that helped shape the live-field handling is available at <https://modworkshop.net/mod/55135>.
