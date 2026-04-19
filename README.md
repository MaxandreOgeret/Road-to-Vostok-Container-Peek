# Container Peek

<p align="center">
  <img src="doc/screenshot.png" alt="Container Peek screenshot" />
</p>

`Container Peek` is a `Road to Vostok` mod that shows a compact loot window when you aim at a container inside interaction range.

## Features

- Shows a small on-screen menu when the cursor or crosshair is on a valid container.
- Uses direct cursor ray hits first, then falls back to an anchor-based check for containers with awkward colliders.
- Limits activation range to `2.5m`.
- Lets you move the highlighted item with `F`.
- Lets you take everything from the current container with `R`.
- Plays the same error beep the base game uses when transfer fails because there is no inventory space.

## Controls

- `Mouse Wheel`: Move the selection in the loot list
- `F`: Transfer the selected entry to inventory
- `R`: Take all items from the current container

## Known Behavior

- The preview groups identical item names into a single row.
- Because of that grouping, `F` transfers the first matching stack for the selected name, not a specific stack instance.
- `R` stops on the first failed insert so partial take-all stays predictable when inventory space runs out.

## Repository Layout

- `mod.txt`
- `ContainerPeek/Main.gd`

`Main.gd` contains the full runtime logic:

- target detection
- menu UI
- scroll handling
- direct inventory transfer

## Build

Create the mod archive from the repository root:

```bash
zip -r ContainerPeek.vmz mod.txt ContainerPeek
```

The archive root must contain:

- `mod.txt`
- `ContainerPeek/Main.gd`

## Install

Copy `ContainerPeek.vmz` into the game mods folder:

```text
~/.steam/debian-installation/steamapps/common/Road to Vostok/mods/
```

Then restart the game fully.

## Requirements

- `Road to Vostok`
- The community mod loader format used by the game

## References

- Community loader install and mod format: <https://github.com/ametrocavich/vostok-mod-loader>
- Current container script reference and live fields from a working community mod: <https://modworkshop.net/mod/55135>
