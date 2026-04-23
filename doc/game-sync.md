# Game Sync Notes

This mod intentionally mirrors a small set of `Road to Vostok` runtime behaviors instead of inventing its own rules. Those ports are the most likely places to go stale after a game update.

Use this file as the resync checklist after decompiling a new build.

Last verified against the decompiled game data currently in this repository, which reports:

- `Godot Engine v4.6.1.stable.official.14d19694e`

## How To Use This File

1. Decompile the current game scripts from `RTV.pck`.
2. Re-check the upstream functions listed below.
3. Compare them against the local mod functions listed below.
4. If upstream changed, update the mod logic first, then update this file.

## Synced Behaviors

### Transfer Order And Stacking

- Local code:
  - `ContainerPeek/Main.gd` `_try_direct_slot_transfer`
- Upstream source:
  - `res://Scripts/Interface.gd`
  - `FastTransfer()`
  - `ContextTransfer()`
  - `AutoStack(slotData, targetGrid)`
  - `Create(slotData, targetGrid, useDrop)`
- What is mirrored:
  - Container-to-inventory transfer must try `AutoStack(...)` first.
  - If stacking does not consume the item, it must fall back to `Create(...)`.
  - Success should still use the game's normal click/reset flow.
  - Failure should still use the game's error feedback.
- Why this matters:
  - Without the `AutoStack(...)` pass, ammo and other stackables get dropped into empty slots instead of merging into existing stacks.
- Signs this is stale:
  - Ammo hotkey transfer stops stacking.
  - Transfer behavior differs from the game's context menu.
  - Partial stacks behave differently than vanilla.

### Slot Weight Calculation

- Local code:
  - `ContainerPeek/ItemSupport.gd` `slot_total_weight`
- Upstream source:
  - `res://Scripts/Item.gd`
  - `Weight()`
- What is mirrored:
  - Base weight starts from `slotData.itemData.weight`.
  - `Ammo` scales by `slotData.amount / slotData.itemData.defaultAmount`.
  - `Magazine` adds loaded ammo weight from `slotData.itemData.compatible[0]`.
  - `Weapon` adds loaded ammo weight from `slotData.itemData.ammo`.
  - Chambered weapons add one extra round.
  - All `slotData.nested` item weights are added.
  - Final value is rounded with `snappedf(..., 0.01)`.
- Why this matters:
  - Peek weights must match what the game shows for ammo stacks, loaded magazines, loaded weapons, and nested gear.
- Signs this is stale:
  - Ammo stacks show inflated or tiny weights.
  - Loaded mags or guns weigh less or more than the base game tooltip/UI.
  - Attachments or nested armor stop affecting displayed weight.

### Slot Value Calculation

- Local code:
  - `ContainerPeek/ItemSupport.gd` `slot_total_value`
- Upstream source:
  - `res://Scripts/Item.gd`
  - `Value()`
- What is mirrored:
  - Base value starts from `slotData.itemData.value`.
  - `Ammo` and `Matches` scale by `slotData.amount / slotData.itemData.defaultAmount`.
  - `Magazine` adds loaded ammo value from `slotData.itemData.compatible[0]`.
  - `Weapon` adds loaded ammo value from `slotData.itemData.ammo`.
  - Chambered weapons add one extra round.
  - All non-`Electronics` items are multiplied by `slotData.condition * 0.01`.
  - `Cat` becomes zero value when `gameData.catDead` is true.
  - All `slotData.nested` item values are added.
  - Final value is rounded with `roundf(...)`.
- Why this matters:
  - Peek prices should match the game's tooltip and inventory totals instead of drifting from live ammo, condition, or nested-item value changes.
- Signs this is stale:
  - The value column disagrees with the vanilla tooltip.
  - Damaged non-electronics keep showing full price.
  - Loaded magazines or weapons do not gain value from inserted rounds.

### Summary Amount Semantics

- Local code:
  - `ContainerPeek/ItemSupport.gd` `slot_summary_amount`
- Upstream source:
  - `res://Scripts/Item.gd`
  - the amount display logic in `UpdateDetails()` and related item UI paths
- What is mirrored:
  - `slot.amount` is not a generic "item count".
  - For `Ammo`, `amount` is the actual stack count and should be shown as multiplicity.
  - For magazines and weapons, `amount` represents loaded rounds and must not become `x30`, `x45`, etc. in the peek list.
  - Other stackable items can still use `amount` as multiplicity.
- Why this matters:
  - The peek window groups items by display name, so using the wrong multiplicity makes magazines and weapons look like multiple copies.
- Signs this is stale:
  - A single magazine shows up as `x30`.
  - A loaded weapon appears as multiple items.
  - Stack counts diverge from what the player would infer from vanilla UI.

### Condition Visibility Rules

- Local code:
  - `ContainerPeek/ItemSupport.gd` `slot_condition_percent`
  - `ContainerPeek/ItemSupport.gd` `slot_shows_condition`
- Upstream source:
  - `res://Scripts/Item.gd`
  - `res://Scripts/Tooltip.gd`
- What is mirrored:
  - Always show condition for `Weapon`.
  - Show condition for `Armor` and `Helmet`.
  - Show condition for `Rig` only when it has nested armor.
  - Otherwise show condition only when `itemData.showCondition` is enabled.
- Why this matters:
  - The peek window should follow the same condition visibility rules as the game's item UI and tooltip.
- Signs this is stale:
  - Helmets or armor lose condition in the peek list.
  - Rigs without armor show condition when they should not.
  - New item classes gain or lose condition in vanilla but not in the mod.

### Rarity Enum And Color Semantics

- Local code:
  - `ContainerPeek/ItemSupport.gd` `rarity_color`
  - `ContainerPeek/ItemSupport.gd` `normalize_rarity_value`
- Upstream source:
  - `res://Scripts/ItemData.gd`
  - `enum Rarity { Common, Rare, Legendary, Null }`
  - `res://Scripts/Tooltip.gd`
- What is mirrored:
  - Real game rarity tiers are `Common`, `Rare`, `Legendary`, `Null`.
  - The base tooltip colors are `Common -> green`, `Rare -> red`, `Legendary -> dark violet`.
  - The mod allows custom colors, but the tier mapping itself follows the game enum.
- Why this matters:
  - If the game adds or renames rarity tiers, the mod's color mapping and config labels can silently become wrong.
- Signs this is stale:
  - Rare items render with the wrong tier name.
  - Items fall into the wrong rarity bucket.
  - A future update introduces a new rarity tier that the mod ignores.

## Not Covered Here

These parts use game resources or game state, but are not direct code ports:

- Shelter rummage bypass uses `GameData.shelter`.
- Rummage audio uses the game's `Craft_Generic` audio event and `AudioInstance2D` scene.
- Candidate interaction range uses live node fields with a `2.5m` fallback.

They can still break after an update, but there is no single upstream function currently being mirrored line-for-line.
