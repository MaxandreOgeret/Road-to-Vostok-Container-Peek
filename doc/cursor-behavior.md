# Cursor Behavior Notes

These statements are treated as true for the current loot table behavior:

- The UI is functionally a table-like list with a single active row cursor/selection.
- The table is sorted according to the active sort mode.
- The list is dynamic: new items are added over time as rummaging reveals more entries.
- Newly revealed items can appear either above or below the current cursor, depending on where they fall in the active sort order.
- The table has a limited viewport with `n` visible items.
- Additional items may exist above or below the current viewport and therefore be hidden from view.
- The cursor is intended to remain within the viewport at all times.

## Pre-Input Non-Full Rule

Before the user has made any input, the cursor stays on the top row.

- The table starts empty.
- Once the first item is added, `N = 1`.
- While the viewport is not yet fully populated and the user has not made any input, `N` must remain constant at `1`.
- If a newly revealed item is inserted above the current item during this phase, `N` stays `1` and `I` changes to the new top item.

## Full Viewport Invariant

When the viewport is fully populated and the user is rummaging:

- Let `I` be the selected item identity.
- Let `N` be the cursor's row position within the viewport.
- When the viewport first becomes fully populated, `N` is whatever row the selected item occupies at that moment.
- During the rummaging process, both `I` and `N` must remain constant.
- This means the cursor must stay on item `I`, and item `I` must remain at viewport row `N`.
- If newly revealed items would otherwise change the viewport row of `I`, the viewport/window must adjust as needed so that `I` remains at row `N`.
- If the user manually changes the selection, the newly selected item becomes the new `I`, and its current viewport row becomes the new `N`.

This invariant does not apply while the viewport still has unpopulated rows.
During that non-full phase, the pre-input non-full rule above applies until the user makes an input.

If transfer/removal causes the viewport to stop being fully populated, the full-viewport invariant no longer applies and behavior falls back to the non-full-viewport case.

## Sort Change Reset Rule

When the user changes sort mode:

- The current full-viewport invariant is intentionally reset.
- The cursor must jump back to the top row of the newly sorted list.
- The viewport must also reset to the top of the newly sorted list.

## Explicit Reset Points

The current cursor/viewport anchoring state is explicitly reset on:

- target change
- panel close
- panel reopen
