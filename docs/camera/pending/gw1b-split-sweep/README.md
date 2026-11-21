# Parked: split_sweep on the GW1b stack (gw1b-split-sweep)

Camera, 2026-11-21, the EP's GW1b gate item. On main + the 44-line stack (`docs/ep/reviews/GW1b-stack.txt` without the lake group), split_sweep failed 23 rows. Main alone passes, and so does the stack without the flip (`world.json` mode back to arena). **All 23 come from the flip**: 22 are a pin, and one is a small real camera fault, fixed here.

**Apply after the 44-line stack** (it touches `split_rig.gd` after gw1b-scape-side and gw1b-keep-human, and uses World's `WorldPin.arena()` from `pins-gw1b.diff`): `git -c core.autocrlf=false apply gw1b-split-sweep.patch` (sha1 14013964). Two files, mine.

| File | What |
| :--- | :--- |
| `render/camera/tests/split_sweep.gd` | **A pin.** The staged rows play the hand-made arena they were built on (`WorldPin.arena()`, as World's 25 checks do). The real matches play the data's default world, the planet, which is Orb's game after the flip |
| `render/camera/split_rig.gd` | **The fix.** The split trigger's wide hold now ends once the one view is *drawn* at its floor |

## The pin: 22 staged rows

These are launch split, arena turn, depth foreground, dolly, intro resize, the default opening and crossing start. They stage places, streets, depths and turns on the arena; on the planet those places aren't there. With the pin they pass, as they did before the flip.

## The fix: real match 3 human 1 on the planet

- **The failure:** 71 of 2,874 one-view ticks showed a fighter under 60% of the split line (the limit is 2%).
- **What happened:** in runs of about 20 ticks, while the pair flew apart, the one view was drawn at its hard floor (0.032 of the height, 23 px) before the split opened. The trigger adds a wide hold while the pair still moves apart (`WIDE_HOLD`, the "flying around the world" beat). Its own comment says it runs "only between the split line and the floor", but it tested the size the fight would like (`r_now`). The scroll governor had already zoomed the drawn view to the floor for speed, so the hold went on with nothing left to zoom out.
- **Why it shows now:** GW1b's slower flight makes the separation take longer, so more ticks fall in the hold.
- **The change:** the hold ends when the drawn view is at its floor. The split then opens as the floor is reached, eased as always, with no cut and no flap: the closest layout changes stay 0.90 s apart.

## Proof (`docs/camera/runs/c860b5a7/gw1b-split-sweep/runs.txt`)

| Run | split_sweep |
| :--- | :--- |
| main alone; the stack without the flip | pass; pass |
| the stack | 23 rows fail |
| + the pin | 1 (real match 3 human 1) |
| + the pin + the fix | **pass** |
| main + the fix alone | pass |

## Not this park: four more camera checks are red on the 44-line stack, with or without it

| Check | On the stack | On the stack without the flip | Cause |
| :--- | :--- | :--- | :--- |
| `cross_ko_check` | 1 (a jolt of 0.093 in the across shot) | pass | the flip |
| `swing_places_check` | 3 (a landmark at the wider edge not seen) | pass | the flip |
| `chase_rush_check` | 1 (a 4-tap chain caught him twice, not 3 times) | 1 | GW1b's data (the slower flight) |
| `split_vision_check` | 1 (only 1 merge to judge) | 1 | GW1b's data |

Classified in `../gw1b-camera-checks/` (the second park), which also holds this fix's before-and-after reading on one-view frames (`docs/camera/runs/c860b5a7/gw1b-split-sweep/one-view-before-after.txt`).
