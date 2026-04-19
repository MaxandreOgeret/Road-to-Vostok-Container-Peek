# Container Peek

<p align="center">
  <img src="doc/screenshot.png" alt="Container Peek screenshot" />
</p>

`Container Peek` is a `Road to Vostok` mod that shows a compact loot window when you aim at a container inside interaction range.

## Features

- Shows a compact loot menu when the game itself considers a container interactable.
- Uses the game's `Interactor` ray and HUD prompt instead of a separate scene scan.
- Limits activation range to `2.5m`.
- Shows item, total stack weight, and condition columns with a sticky table header.
- Uses a real scrollbar for longer containers.
- Supports optional rarity-colored item names.
- Lets you transfer the selected entry or take everything from the current container.
- Plays the same error beep the base game uses when transfer fails because there is no inventory space.
- Supports rebinding through Mod Configuration Menu when MCM is installed.

## Controls

- `Mouse Wheel`: Move the selection in the loot list
- `F`: Transfer the selected entry to inventory
- `R`: Take all items from the current container

These defaults can be rebound in MCM.

## Known Behavior

- The preview groups identical item names into a single row.
- Because of that grouping, `F` transfers the first matching stack for the selected name, not a specific stack instance.
- `R` stops on the first failed insert so partial take-all stays predictable when inventory space runs out.
- The condition column is shown only for item types that plausibly use durability.

## Repository Layout

- `mod.txt`
- `ContainerPeek/Main.gd`
- `ContainerPeek/Config.gd`
- `ContainerPeek/ConfigSupport.gd`
- `ContainerPeek/ItemSupport.gd`

Main runtime split:

- `Main.gd`: scene lifecycle, target resolution, menu UI, and transfer flow
- `Config.gd`: MCM registration and input action setup
- `ConfigSupport.gd`: runtime config fallback reads and binding label helpers
- `ItemSupport.gd`: container item summaries, rarity, weight, condition, and selection helpers

## Build

Create the mod archive from the repository root:

```bash
zip -r ContainerPeek.zip mod.txt ContainerPeek
```

The archive root must contain:

- `mod.txt`
- `ContainerPeek/`

## Install

Copy `ContainerPeek.zip` into the game mods folder:

```text
~/.steam/debian-installation/steamapps/common/Road to Vostok/mods/
```

Then restart the game fully.

## Requirements

- `Road to Vostok`
- The community mod loader format used by the game
- `Mod Configuration Menu` is optional, but needed for the in-game keybind and rarity-color settings UI

## References

- Community loader install and mod format: <https://github.com/ametrocavich/vostok-mod-loader>
- Current container script reference and live fields from a working community mod: <https://modworkshop.net/mod/55135>
