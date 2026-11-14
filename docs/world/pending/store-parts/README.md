# Park: `WorldStore.parts`, re-cut for the new store (World, 2026-11-14; EP brief of 11-14 on Rendering's grant 0e606aaa)

Rendering's grant (`docs/rendering/pending/marks-baked/grant-world-store.patch`) adds a read-only `parts` that mirrors **today's** `heightDelta`: the craters' sum and the least groove, `y < 0 ? min(x, y) : x`. It applies to HEAD and is right for HEAD. It stops being right the moment globe-step2 lands: that park changes what the store holds and how it combines. So I re-cut it **on the stack** (globe-step2, a-world-01, planet-sizes, gw1c-world, then this) so that `parts` cannot drift from the height: both are the same code.

| File | What |
| :--- | :--- |
| `store-parts.diff` | `sim/world/store.gd` (`parts`, `partsX`, `combine`, and `_scan`, the one scan the height and the parts both read) and three rows in `sim/world/tools/globe_check.gd`. World's files only: **no grant needed from anyone** |

## What it does

- `_scan(S, q, skip)` is the body of `heightDeltaX`, unchanged. It returns the marks' sum and leaves the deepest groove and the highest lip in two statics (`_pg`, `_pl`), set at the very end, after the flatten's field read, which may read the store again. `combine(sum, groove, lip)` is the formula and the floor/ceiling hold, written once. `heightDeltaX` is `combine(_scan(...), _pg, _pl)`: **no allocation on the height's hot path.**
- `parts(S, q)` and `partsX(S, q, skip)` return a `PackedFloat64Array [sum, groove, lip]`:
  - **sum**: craters and merged marks (the profile out to two radii), a heap's cone, and, with `craters.json globe.flatten` on, the level floor's lift (it reads the field, so it is in the sum);
  - **groove**: the deepest groove (trench, scar, scorch; 0 for none);
  - **lip**: the highest lip of a trench.
  Not clamped: `combine` holds the floor and the ceiling. A record another supersedes is skipped, as in `heightDelta`.
- **Not a Vector3.** My first cut returned a Vector3 and it failed `field_crater_check` and `field_trench_check` (the store read -99.561 against -99.5612...): a Vector3 is 32-bit and the store's height is read at 64. Rendering: do not carry the parts in a Vector3 or Vector2 either, if the sum and the rest are subtracted at full precision (the tile bake's `heightDelta` less the sum).
- A pure refactor: **the golden is byte for byte HEAD's** (`golden.gd` re-recorded in the scratch tree on the final code, identical to `sim/core/test/golden.json` on HEAD).

## What Rendering must change from their grant

- It returns a **PackedFloat64Array of three**, not a Vector2 (the lip is the third part). The tile rule in their README stands: the tile carries `heightDelta` less the sum, and the lift takes off only the sum. The vertex stage's 16 bowls draw `profile` of craters only: a heap, a merged mark and a flatten lift are in the sum here, so they come off the tile and are **not drawn by the vertex stage** unless Rendering draws them too (or carries them on the tile by reading the sum as the craters' bowls alone). That choice is theirs; say and it is one more part.
- The old `y < 0 ? min(x, y) : x` is gone: a groove through a rim now cuts down from the rim (`sum + groove`), and the lip is added. Nothing outside the store should write that formula: call `WorldStore.combine`.
- If they land before globe-step2: their grant is right on HEAD. When globe-step2 lands it goes stale (no SCAR/HEAP/MERGE, no lip, no superseded skip, the old formula). Land this park in its place, on the stack.

## Gates (scratch tree of the full stack; one Godot at a time)

| Gate | Result |
| :--- | :--- |
| `GLOBE` (3 new rows: `heightDelta` is `combine(parts)` bit for bit at all 697 points of a crater + scar + heap, with and without a skip; all three parts are read; an empty store has none) | 0 failed |
| `FIELDCRATER`, `FIELDTRENCH`, `STORE`, `CRATERS`, `CRATERFLATTEN` | 0 failed each |
| golden (`sim/core/tools/golden.gd`) | identical to HEAD's |

Runs: `docs/world/runs/store-parts/`.

## NEEDS FROM EP

- Tell Rendering: approve their grant for HEAD as is, but use this park from globe-step2 on, with the parts as a PackedFloat64Array of three and `WorldStore.combine(sum, groove, lip)`.
- Lands after gw1c-world (it edits the same function): the diff stands on the stack as listed.

## RISKS

- `_pg` and `_pl` are statics: safe because a scan sets them last and the caller reads them at once (the sim is single-threaded); a later change that reads the store between `_scan` and the read would break it.
- Not timed (shared machine): the hot path gained one function call and no allocation.
