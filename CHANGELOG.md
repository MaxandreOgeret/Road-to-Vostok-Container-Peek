# Changelog

## Unreleased

- Restricted VMZ packaging to the runtime mod files plus prefixed `ContainerPeek_LICENSE` and `ContainerPeek_NOTICE` attribution files.

## 1.5.1

- Closing the peek panel now also works when the held primary or secondary weapon starts firing.
- Added Mod Configuration Menu sliders for horizontal position offset, vertical position offset, and UI scale.

## 1.5.0

- Replaced the rummage text spinner with a rotating native combine icon.
- Removed the container-name title bar from the peek panel for a more compact layout.
- Added aim-aware hiding: aiming with a primary or secondary weapon closes the current peek panel until the player looks away and back.
- Added `Capture Shared Inputs`, enabled by default, to prevent shared keybinds such as mouse wheel from also triggering game actions while the peek menu is open.
- Made debug logging toggles session-only so they reset to disabled on game start.
- Reordered Mod Configuration Menu options into clearer groups.

## 1.4.0

- Added item category icons to the peek menu, with a config toggle to disable them.
- Refreshed compatibility against the latest game update.
- Simplified the peek panel UI builders.
- Randomized rummage reveal order so discovery is no longer tied to the active sort mode.
- Pinned the passive rummage view to the top until the player manually scrolls.
- Set the default rummage time to `0.5s` per item.

## 1.3.4

- Added GitHub Actions linting for GDScript.
- Added automated `.vmz` packaging.
- Added a distributable `.zip` containing the `.vmz`.
- CI uploads the `.vmz` as the workflow artifact.

## 1.3.2

- Added optional `XP & Skills System` compatibility hooks.
- Added compatibility notes and a dedicated mod-page description.
- Ignored local build artifacts in the repo.

## 1.3.1

- Matched vanilla transfer stacking.
- Smoothed list scrolling.
- Updated the README.

## 1.2.0

- Cleaned up dead code.
- Added condition and weight columns.
- Split the main file and added color options.

## 1.1.0

- Added key rebinding.
- Fixed interactable checks.
- Reduced FPS drops in larger areas.
- Reduced CPU usage.

## 1.0.1

- Improved the README.
- Fixed a crash when exiting the safe house.
- Added a screenshot.

## 1.0.0

- Initial public baseline.
- Moved toward the game’s native look.
