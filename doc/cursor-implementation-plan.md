# Cursor Implementation Plan

## Goal

Implement the cursor and viewport behavior described in `doc/cursor-behavior.md` without overloading `ContainerPeek/Main.gd`.

## Architecture Decision

- Keep a single policy module.
- Extend `ContainerPeek/ItemListState.gd`.
- Do not add a second helper.
- Do not introduce a framework-like layer of extra models or abstractions.

Reason:

- reveal order
- selected item identity
- anchored viewport row `N`
- logical viewport window

These are one coherent list-state problem.

## State Ownership

`ItemListState.gd` should own only the minimal canonical state:

- reveal order per target
- selected item identity `I`
- anchored row `N`
- current window start
- whether anchoring is active
- whether the user has made manual navigation input for the current target

It must not own:

- UI nodes
- spacer heights
- scroll container state
- presentation objects

## Derived Model Contract

`ItemListState.gd` should expose one pure derived-model entry point that returns:

- sorted visible names
- selected item name
- selected global index within visible names
- window start
- window end
- selected viewport row, derived from `selected_index - window_start` when useful
- whether the viewport is full
- whether anchoring is active
- whether render should snap to top

`ContainerPeek/Main.gd` should render only from that model.

KISS requirement:

- prefer one main derive method plus a few small reset/navigation helpers
- avoid a large API surface
- avoid storing duplicate forms of the same state
- avoid splitting the logic across multiple files
- fix the confirmed bug with the smallest possible change set before considering broader refactors

KISS rule:

- store `I`
- store `N`
- store `window_start`
- store whether manual input has happened for the current target
- derive everything else

In particular:

- derive `selected_index` by locating `I` in the sorted visible list
- derive `window_end` from `window_start`
- derive the selected viewport row from `selected_index - window_start`

## Minimal API

Keep the helper API small. The intended shape is:

- one main derive method for current list/window state
- one reset-all method
- one reset-target method
- one sort-reset method
- one manual-navigation method

Small private helpers are fine, but do not decompose this into many public rule-specific methods unless they are clearly necessary.

## Mode Split

Treat the non-full and full viewport cases as separate modes.

### Non-Full Mode

- the `I`/`N` invariant does not apply
- the viewport stays top-pinned
- preserve the existing top-pinned non-full behavior
- before any user input, keep `N = 1` and allow `I` to change if a newly revealed item appears above the current top item
- after user input, manual navigation may redefine the current selected item/row until the viewport becomes full

### Full Mode

- when the viewport first becomes full, capture `I` and `N`
- preserve both during rummaging
- if newly revealed items would move `I`, recompute the logical window so `I` remains at row `N`
- if the user manually navigates, the newly selected item becomes the new `I` and its current row becomes the new `N`

## Rendering Strategy

Reintroduce logical window rendering.

This is required because the agreed behavior cannot be implemented cleanly with full-list rendering plus `ensure_visible`.

`ContainerPeek/Main.gd` should:

- collect current inputs
- ask `ItemListState.gd` for the derived model
- render only the returned window
- add top and bottom spacers
- apply explicit top reset only when requested by the model
- keep the selected rendered row fully inside the visible scroll viewport

Render-layer rule:

- the selected row being logically inside the derived window is not sufficient
- the selected rendered control must also be fully visible inside the `ScrollContainer` viewport
- unconditional `scroll_to_top` on render is incompatible with this rule
- scroll behavior must follow the derived model rather than override it every frame
- the current confirmed bug is exactly this: after manual scrolling, the logical selection/window are correct but the rendered row can still end up partially outside the visible viewport because render-time top-scroll overrides the model

KISS interpretation for this bug:

- do not add new policy state to fix a render-layer problem
- do not add another helper module
- prefer reusing the existing selected-row visibility scroll path over inventing a new scroll framework
- make `snap_to_top` conditional instead of unconditional
- only keep top-scroll for actual reset cases such as sort reset, target change, panel close, and reopen

`ContainerPeek/Main.gd` must not reimplement cursor, anchor, or viewport policy.

## Reset Correctness

Target-level reset must clear all target-scoped policy state, not only selection state.

That includes:

- selected item identity
- anchored row
- window start
- anchored/manual-input flags
- reveal-order state for that target

Reason:

- `doc/cursor-behavior.md` treats target change, panel close, and panel reopen as explicit reset points
- leaving reveal-order state behind would make resets incomplete and could leak previous rummage state into the next session

## Compatibility Requirements

Preserve the existing good behavior while implementing the new rules:

- hidden-information-safe reveal order
- selection by item identity after anchoring
- sort change resets cursor and viewport to the top
- target change, panel close, and panel reopen reset the anchor state
- transfer/removal that makes the viewport non-full drops back to non-full mode
- pre-input non-full mode keeps the cursor on the top row even if `I` changes

## Verification

After implementation work:

- run `./scripts/lint.sh`
- fix formatting if needed
- run `./scripts/deploy.sh`
- compare the resulting code paths against `doc/cursor-behavior.md`
- compare the resulting log output against the same behavior rules
- verify in logs that the selected row's visual bounds stay within the scroll viewport after manual navigation
- verify that render-time scroll behavior matches the derived window instead of forcing top-scroll
- verify that target reset clears reveal-order state as well as selection/anchor state

## Current Known Bug

The current known bug to fix first is:

- once the viewport is full and the user scrolls down, the selected item can be logically anchored correctly but still render partially outside the visible viewport

The plan for that fix is:

- stop forcing top-scroll on every render
- make render-time scroll behavior conditional on the derived model
- ensure the selected rendered row is fully visible after manual navigation and after subsequent rummage updates
- implement this by changing as little policy/state code as possible and fixing the render behavior where the bug actually lives

## KISS Guardrails

While implementing:

- do not add another state helper unless absolutely forced by the code
- do not store both indices and viewport-row state when one can be derived from the other
- do not let `ContainerPeek/Main.gd` regain cursor/window policy logic
- prefer direct, readable code over generalized abstractions
- keep debug logging selective and transition-focused so the useful lines are not drowned out by repetitive reset noise
- for the current bug, prefer a small correction to scroll application over expanding the model or adding extra state
