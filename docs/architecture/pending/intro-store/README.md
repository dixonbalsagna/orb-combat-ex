# Parked: a played intro and a skipped one start the same match on a planet (GW1b, before the flip)

Simulation, 2026-11-21, sprint A1. A real fault my check found once the flip is in. **It must land before GW1b's step 20**, or parity's "composed intros" row is red on the planet. It includes a small grant to World's `sim/world/store.gd`.

## What was wrong

My intro promises that whatever is composed, and whether it played or was skipped, the state at the clock is the same (`sim/core/intro.gd`'s header). It keeps the two entrance craters in the order of the start spots whoever landed first, but only in `S.craters`. On a planet each dig also writes a record into World's planet store, and the played intro wrote those in **landing order**. When the right spot's fighter lands first, the skip's store reads [left, right] and the played one's [right, left]. The store's running hash reads its records in order, so the state hash differed. Everything else at the clock matched: positions, craters, the ground, buildings, the generator. The two records were the same, swapped (`docs/sim/runs/b0e20f9a-gw1b/golden-plan/intro_probe.gd.txt`).

On the hand-made arena there's no planet store, which is why parity never saw it. Today's two entrance craters don't overlap, so nothing in play differed yet. But a later crater over one of them sums its height and rims in record order, so the fight itself could part.

## The fix

- **World's grant, `store.gd`: `WorldStore.swapBlocks(S, mid)`.** The records [0, mid) and [mid, n) change places, and the running hash is folded again from the first record, each at its kind's length (a new `LEN` table: crater 12, crack 11, scorch 9, trench 11, as `add`, `addCrack`, `addScorch` and `addTrench` push them). The index is dropped and rebuilt on its next read; SimField's memos see the new hash and rebuild.
- **Mine, `intro.gd`: one line where the intro already swaps `S.craters`.** When the left spot's fighter lands second, the store's two landings' blocks are swapped the same way. The block boundary is the store's count just before this dig: the store is empty when a match starts (`SimCore`), and a landing's dig can add more than its crater (cracks on paved ground), so it swaps blocks, not two records.

| Patch | Files | Owner | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- | :--- |
| `intro-store.patch` | `sim/core/intro.gd` | mine | e6214dca6aa3275b1a492cfd044bfa3be2c5e7ab | 7ea9e274db70 |
| `grant-world-store.patch` | `sim/world/store.gd` | World, as a grant | f12828acb303b0cbcbebb202c434c3ec94673c25 | 6cd964c570b0 |

Apply on main (b0e20f9a) after GW1b's steps 1 to 4 (checked): `git -c core.autocrlf=false apply grant-world-store.patch intro-store.patch`.

**World approved the grant** (2026-11-21, through the EP). World carries the same remap into its globe-step2 re-cut for GW1c (O_SUP). This park goes into the GW1b stack before step 20; `../gw1b-golden/` goes in at step 20.

## Proof

Records in `docs/sim/runs/b0e20f9a-gw1b/golden-plan/`.
- **On the arena (steps 1 to 4): the golden is byte for byte** with and without the fix (the arena's store is empty, so nothing is swapped).
- **With the flip:** parity's "composed intros" row, red without the fix ("the state at the clock is not the one the setup's skip gives"), **passes**, and so does "composed intros (golden)". Parity exit 0 through `gate.mjs`, every row, with `../gw1b-golden/` in.
- **Not covered here:** World's own store checks with the new function. `swapBlocks` has one caller today.
