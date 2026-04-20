# Container Peek

<p align="center">
  <img src="doc/screenshot.png" alt="Container Peek screenshot" />
</p>

`Container Peek` is a `Road to Vostok` mod that shows a compact loot window when you aim at a container inside interaction range.

## Features

- Shows a compact loot menu when the game itself considers a container interactable.
- Uses the game's `Interactor` ray and HUD prompt instead of a separate scene scan.
- Uses the container's own interaction range when available, with a `2.5m` fallback.
- Hides cleanly when the game is paused so the peek menu does not sit on top of pause UI.
- Shows item, total stack weight, and condition columns with a sticky table header.
- Uses a real scrollbar for longer containers.
- Supports optional rarity-colored item names.
- Keeps rarity coloring visible even on the currently selected row.
- Supports optional first-look rummaging with a configurable per-item reveal delay, single-row skeleton placeholder, spinner, and loading indicator.
- Can play the base game's `Craft_Generic` rummage sound while revealing rows, with randomized start offsets into the clip.
- Skips rummaging entirely in the shelter and shows full contents immediately there.
- Supports configurable menu background opacity.
- Lets you transfer the selected entry or take everything from the current container.
- Plays the same error beep the base game uses when transfer fails because there is no inventory space.
- Supports rebinding and UI color/audio settings through Mod Configuration Menu when MCM is installed.

## Controls

- `Mouse Wheel`: Move the selection in the loot list
- `F`: Transfer the selected entry to inventory
- `R`: Take all items from the current container

These defaults can be rebound in MCM.

## Known Behavior

- The preview groups identical item names into a single row.
- When rummage delay is above `0`, new containers reveal grouped rows over time; setting it to `0` keeps the current instant list behavior.
- Empty containers still spend one rummage interval showing the loading state before `Empty`, unless rummaging is disabled.
- Because of that grouping, `F` transfers the first matching stack for the selected name, not a specific stack instance.
- `R` is unavailable while rummaging is still in progress.
- `R` stops on the first failed insert so partial take-all stays predictable when inventory space runs out.
- The condition column is shown only for item types the game itself treats as condition-bearing: weapons, armor, helmets, rigs with armor inserts, and items with `showCondition`.
- Rarity color settings only use the game's actual rarity tiers: `Common`, `Rare`, and `Legendary`.

## MCM Settings

- `Transfer Selected`: keybind for moving the selected row to inventory.
- `Take All`: keybind for moving all visible contents to inventory.
- `Rarity Colors`: toggles rarity-colored item names.
- `Rummage Time / Item`: per-row reveal delay for first-time container inspection. `0` disables rummaging.
- `Rummage Audio`: toggles the rummaging sound effect during reveal.
- `Menu Opacity`: controls panel background opacity without affecting text opacity.
- `Common Color`, `Rare Color`, `Legendary Color`: override preview colors for the game's supported rarity tiers.

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
- `doc/game-sync.md`: upstream game-code behaviors intentionally mirrored by the mod and worth re-checking after game updates

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
- `Mod Configuration Menu` is optional, but needed for the in-game keybind, rummage, opacity, audio, and rarity-color settings UI

## References

- Community loader install and mod format: <https://github.com/ametrocavich/vostok-mod-loader>
- Current container script reference and live fields from a working community mod: <https://modworkshop.net/mod/55135>
