# Container Peek

Container Peek lets you check a container's contents the moment you aim at it, without opening the full inventory screen first.

[![Mod Showcase](https://img.youtube.com/vi/SILqqw-1Vd0/0.jpg)](https://www.youtube.com/watch?v=SILqqw-1Vd0)

## What It Does

Instead of stopping to open every crate, drawer, freezer, shelf, or cabinet just to see whether it is worth looting, you get a compact loot window that appears only when the game already considers that container interactable.

The goal is simple: faster looting, less menu friction, and better flow.

## Features

- Compact loot preview window for containers in range
- Fixed table header with a real scrollable list
- Native-style item category icons with an optional toggle
- Weight, condition, and value columns
- Mouse wheel row selection
- `F` to take the selected item
- `R` to take all
- `V` to cycle sorting by name, rarity, weight, and value
- Aim-aware hiding while a primary or secondary weapon is held
- Optional shared input capture for controls that overlap with game bindings
- Optional rarity-colored item names
- Optional rummaging behavior with a rotating icon for slower first inspection
- Optional compatibility with XP & Skills System

## Why Use It

The base loot loop often forces you to fully open a container before you can decide whether it is even worth touching. Container Peek removes that dead time while staying close to the game's own interaction rules and visual style.

It is meant to feel like a faster extension of the existing loot flow, not a separate overlay mod fighting the game.

## Configuration

If you use Mod Configuration Menu, you can:

- Rebind take, take-all, and sort keys
- Enable or disable rarity colors
- Enable or disable category icons
- Enable or disable shared input capture
- Tune rummaging delay and audio
- Control whether the mod is enabled in the shelter
- Control whether rummaging applies in the shelter
- Adjust panel opacity, position, and scale
- Enable optional compatibility with XP & Skills System

Debug logging options are session-only and reset to disabled when the game starts.

## Compatibility

- Works with Mod Configuration Menu
- Includes an optional compatibility hook for XP & Skills System, so popup inspection can trigger that mod's container XP and scavenger bonus path

## Source Code

https://github.com/MaxandreOgeret/Road-to-Vostok-Container-Peek

## Audio Sources

Custom corpse rummaging audio sources:

- https://pixabay.com/sound-effects/film-special-effects-woven-nylon-bag-rustling-and-unzipping-62127/

## Third-Party Asset Notices

- The bundled corpse rummaging MP3 files are third-party Pixabay assets and are not covered by the GPL license for the mod code.
- The bundled ammo icon `ammo.svg` is a third-party asset and is not covered by the GPL license for the mod code.
- Ammo icon attribution: Bullet by Andhika Pramanto from Noun Project (CC BY 3.0)
