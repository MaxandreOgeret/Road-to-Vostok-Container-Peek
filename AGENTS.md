# Agent Instructions

This repository contains `Container Peek`, a Road to Vostok mod written in GDScript. Treat it as a game mod with live-game compatibility requirements, not as a standalone app.

## Core Workflow

- Read the relevant code before changing behavior. The main runtime is `ContainerPeek/Main.gd`; support code lives in `PanelSupport.gd`, `ItemSupport.gd`, `ItemListState.gd`, `TargetSupport.gd`, `GameInputSupport.gd`, `Config.gd`, and `Compat/XPSkillsCompat.gd`.
- Keep changes KISS. Prefer a small direct change that fits the existing helpers over new abstractions or broad refactors.
- Preserve user changes. The worktree may be dirty; do not revert unrelated edits unless explicitly asked.
- When changing gameplay behavior, update the matching docs in `README.md`, `DESCRIPTION.md`, `DESCRIPTION.bbcode`, `CHANGELOG.md`, and any relevant file under `doc/`.
- When changing runtime code, run `./scripts/lint.sh` before reporting completion.
- When changing packaging or runtime behavior, run `./scripts/build_vmz.sh`.
- Always deploy after runtime changes with `./scripts/deploy.sh`, unless the user explicitly says not to. The default deploy target is `~/.steam/debian-installation/steamapps/common/Road to Vostok/mods/`.

## Base Game Source

- The decompiled base game source is available under `decomp/`.
- Refer to `decomp/` when changing behavior that mirrors or depends on vanilla game logic.
- Important references:
  - `decomp/Scripts/Interface.gd` for transfer, stacking, grid creation, reset, click, and error feedback behavior.
  - `decomp/Scripts/Item.gd` for item amount, weight, value, condition, and tooltip-adjacent semantics.
  - `decomp/Scripts/Tooltip.gd` for condition and rarity display behavior.
  - `decomp/Scripts/ItemData.gd` for rarity enum semantics when available.
- If local code intentionally mirrors decompiled game behavior, update `doc/game-sync.md` when that mirrored behavior changes.

## UI And Cursor Rules

- The loot table groups identical display names into one row. `F` transfers the first matching stack for the selected grouped name; do not change this to transfer all matching stacks unless explicitly requested and validated against large items.
- `R` take-all should stop at the first failed insert to keep partial transfers predictable.
- Cursor behavior is documented in `doc/cursor-behavior.md`. Keep that file aligned with any selection, scrolling, sorting, removal, or rummage reveal changes.
- If a selected grouped row disappears after transfer, the cursor should preserve its row position where possible, moving to the row above when the removed row was last.
- Rummaging placeholder rows must use the same visible columns and column widths as real rows and headers.
- The `Item` column is always visible. Other data columns are controlled independently by MCM settings.
- Sort cycling must only expose sort modes that are currently available: `Name` is always available; rarity sorting follows the rarity-color setting; data-column sorting follows enabled data columns.

## Configuration

- MCM defaults are defined in `ContainerPeek/Config.gd`.
- Runtime settings are cached in `ContainerPeek/Main.gd` by `_sync_runtime_settings()`. When adding a setting, wire both the config default and the runtime cache.
- If a setting changes the layout, include it in render/header state so the UI rebuilds immediately.
- Debug logging settings are session-only and should reset on startup.

## Validation

- Use:
  - `./scripts/lint.sh` for `gdlint` plus `gdformat --check`.
  - `./scripts/build_vmz.sh` to build `ContainerPeek.vmz` and `ContainerPeek.zip`.
  - `./scripts/deploy.sh` to build and copy the VMZ into the local game mods directory.
- If lint asks for formatting, run `gdformat` on the touched `.gd` files, then rerun `./scripts/lint.sh`.
- Mention any validation or deployment command failures in the final response.

## Packaging

- `scripts/build_vmz.sh` intentionally packages only:
  - `mod.txt`
  - `ContainerPeek/`
  - `ContainerPeek_LICENSE`
  - `ContainerPeek_NOTICE`
- Do not add repo-only files to the VMZ package unless the user explicitly requests a packaging change.

## Documentation Notes

- `README.md` is the main project documentation.
- `DESCRIPTION.md` and `DESCRIPTION.bbcode` are mod-page-facing descriptions; keep them concise and user-facing.
- `CHANGELOG.md` should receive an `Unreleased` entry for behavior, UI, config, packaging, or compatibility changes.
- `doc/game-sync.md` is the checklist for logic mirrored from the base game.
- `doc/cursor-behavior.md` is the source of truth for cursor and viewport policy.
