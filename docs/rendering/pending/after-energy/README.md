# after_check under the energy model and the dash (for GW1a, with A-ENERGY-04)

Parked by Rendering on 2026-11-14 at the EP's word. Simulation's A-ENERGY-04 (`docs/architecture/pending/energy-on/`) turns the energy model and the dash on in main's data. With it, one of my 15 checks fails: `after_check`'s "the match has a rush in it". **Land it with A-ENERGY-04, in GW1a.** `after_rush.diff` (sha1 479239d6, 88 lines, `render/tools/after_check.gd` only) applies on main today and on top of globe-default (which adds `main.strip_ground = true` to the same check).

## Why it failed

The check's real match was AI against AI, seed 7, 900 ticks, the match whose tick 307 once drew six after-images round a fighter. It asked that the five were reached, so Legal's limit (m12: at most five ghosts round one fighter) is tried in a real match. With the energy model and the dash, the fight moves:

| Seed (900 ticks, the data's model) | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|
| most drawn round a fighter | 0 | 2 | 2 | 3 | 2 | 0 | 0 | 0 | 2 | **5** |

## The change

The check is re-scripted, not pinned, so it tests what ships:
- from `--seed` (7) it plays a further seed at a time, up to `MATCHES` (20) matches, and stops at the first that reaches the five (seed 16 today: ten matches, about 45 seconds);
- the other two assertions (never more than five, and the number drawn equal to VFX's tally on every tick) hold over every match played;
- the message names the matches and the seed that reached five.

GW1a lands its other data groups (pad, computer opponent, match-ending rules) after this. Each may move the fight again, and twenty seeds leave room for that. If none reaches five, it fails and says so. The fall-back would be a pinned match with `"power": false, "dash": false`, which Simulation keeps as a setup.

## Proof

`docs/rendering/runs/611c1c2b/after-energy-on.txt` and `after-energy-on-2.txt`, on scratch trees of main 611c1c2b:
- **main + energy-on, the check as on main:** fails 1 (the rush: 0 drawn), as Simulation reported;
- **main + energy-on, re-scripted:** passes. The five are reached on seed 16, the tenth match; at most five are drawn, and the number drawn equals VFX's tally on every tick (peaks 5 and 4);
- **main as it is, re-scripted:** passes on seed 7, the first match, as before;
- **main + energy-on with this park:** the five ground checks pass, and the render gates pass 19 of 20.

The one that fails is Camera's `split_sweep`, 7 failures, the same twice (`split-sweep-energy-on.txt`):
- a real match where a fighter is out of his pane for 1.2 s;
- the crossing start: a brightness dip, a fighter past the screen's edge, the camera outside the avenue on 2 of 9 closing ticks.

It passes on main, and this park doesn't touch it, so it's energy-on's. It isn't in Simulation's table; it's Camera's check to read under the energy model.
