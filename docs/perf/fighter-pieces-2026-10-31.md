# Where the fighters' frame time goes, by piece (Performance and Platform, 2026-10-31)

For the EP, on cut 2 of `swing-tick-2026-10-31.md` (the Performance level's script time): `r_fighters`, which `quality-range.md` 2.2 put at 0.74 ms mean and 1.18 p95 for the pair, "rigs, skin, damage". I guessed at the rig; this measures it. **The guess was wrong: the skin, damage, materials and uniforms are 13% of it. 87% is the animation solver, `AnimFighter.solve`, which runs inside `FighterView.update`.** That moves cut 2 from Rendering to Animation.

## Method

Scratch stage tree (HEAD e8a95e35's `render/` and `sim/`, which equal HEAD a1b8bfd8 for the three files timed: `fighter_view.gd`, `anim_fighter.gd`, `anim_body.gd`), `hook-stages.mjs` then `hook-fighters.mjs` (coarse: `fv_*` for `FighterView.update`, `fa_*` for each numbered stage of `solve`; then `fine`: `fa2_*`, one timer on each call inside `solve`). Native, headless, `--fixed-fps 60`, an AI match, seed 4, planet 7, 2,400 frames. **Per-frame minimum of 3 runs in parallel** (the match is deterministic, so load only adds time). Timers are inclusive and add over the two fighters, so every figure is the pair's. **Load on the machine was 82 to 99% from other sessions during these runs**, so the absolute times read high: `r_fighters` here is 1.15 to 1.19 ms mean against 0.74 in the quiet run, which also has about 70 more timers in it. **Read the shares, not the milliseconds.** One planet, one seed, the AI's fights.

## The cut (ms, pair, mean / p95)

| Piece | Mean | p95 | Share of `r_fighters` |
|---|---|---|---|
| `AnimFighter.solve` (`fv_solve`) | 1.00 to 1.04 | 1.70 to 1.75 | 87% |
| everything else in `FighterView.update` | about 0.15 | | 13% |
| of that: pose and turn 0.025, anchor and uniforms 0.027 (`under_level` 0.008, `set_anchor` 0.002, `set_under` 0.002), the cue 0.010, the facing 0.010, aura and streaks 0.011, badge and guard 0.009, the skeleton write (`AnimBody.apply`) 0.008, damage 0.007, sockets 0.007, look 0.002, materials 0.001 | | | |

**Inside the solve, the pieces that matter** (`fa2_*`):

| Call | Mean | p50 | p95 | What it is |
|---|---|---|---|---|
| `_exchange_layers` | **0.243** | 0.242 | 0.603 | the approach and strike parts of an exchange, on in nearly every frame of the AI's fights |
| `_contact_ik` | 0.092 | **0.042** | **0.719** | the striking limb reaches the defender: a spike in blow frames |
| `_rd.apply` (the ragdoll) | 0.082 | 0.086 | 0.104 | steady, in every frame |
| `_reaction_layer` | 0.068 | 0.060 | 0.166 | reactions to blows |
| `_inertialise` | 0.067 | 0.034 | 0.193 | a join in the pose decays instead of popping |
| `_free_arm_slew` | 0.050 | 0.049 | 0.078 | steady |
| `_loco_layer` | 0.039 | 0.038 | 0.046 | steady |
| `_ground_layer` | 0.038 | 0.037 | 0.049 | steady |
| `AnimPose.limit_limbs` | 0.033 | 0.034 | 0.044 | the limb pass, every frame |
| `_ground_feet`, `_lead_layer` | 0.022 each | | 0.080 / 0.026 | |
| `_target_base`, `AnimZip.layers` | 0.017, 0.014 | | | |

The other 25 calls timed are 0.010 or less each. **The five biggest (exchange, contact IK, ragdoll, reaction, inertialise) are 55% of the solve.**

**What sets the p95.** The pair's `r_fighters` is 1.15 mean and 1.85 p95; the 0.7 between them is the blow frames: `_contact_ik` goes from a median of 0.04 to 0.72 at p95 (+0.68), `_exchange_layers` from 0.24 to 0.60 (+0.36), `_inertialise` +0.13, `_reaction_layer` +0.10. The steady layers (ragdoll, free arm, loco, ground, limbs) are the same in every frame and set the median, not the p95.

## What this says about cut 2

1. **Nothing to take from Rendering's side of the fighter** (skin, damage, materials, the aura, the uniforms): 0.15 ms in all, and the shipped `damage_reduced` and `minimal` switches already reach the damage part. A lower "rig detail" in the view would change nothing measurable.
2. **The p95 is the contact solve and the exchange layers**, in blow frames. The one thing in the code that stands out on a read: `_contact_one` does dictionary and string work every frame it runs (`AnimData.sockets.get("limbs", {}).get(kind, {})`, `get_slice`, `substr`, `contains`, `ends_with` on the limb name, `_region_point`, per limb, and a second limb when there is one). Whether that is the 0.7 ms I have not profiled; the next cut down is inside `_contact_one`. Yield if the blow-frame cost came down to the steady one: **about -0.4 to -0.6 ms at p95** (in these loaded units; scale by 0.65 for the quiet ones).
3. **The steady layers are the median.** The ragdoll's `apply` runs whenever `out_w > 0.001`, which in this match is almost every frame (0.082 of the 1.0). A threshold or a skip when the ragdoll's amplitude is below what shows would take most of it. The same for `_free_arm_slew` (0.050 for a slew), `_loco_layer` and `_ground_layer`. Yield: **-0.1 to -0.2 ms mean.**
4. **The existing quality switch reaches little of this**: `anim-quality=minimal` switches off the ragdoll and 8 layers and took `r_fighters` from 0.75 to 0.62 in the quiet run (quality-range.md 2.2). So the cost is in the base solve (pose build, exchange, reactions, inertialisation, limits), not in the optional layers.
5. **Skipping the solve every second frame does not help the Performance level**: `solve_hz` 30 ("on twos", the snappy profile) is only taken when the fighter is idle, and at the 30 fps target each drawn frame solves once anyway.

## Owners

All of it is `render/anim/anim_fighter.gd`: **Animation's.** `fighter_view.gd` (Rendering's) has nothing to take. The first task for Animation is to profile inside `_contact_one` and `_exchange_layers` (the hook's `fine` mode shows the way: `wrap` on the calls inside, one run of 40 seconds per cut), then cut the per-frame dictionary and string work.

## Files

`docs/perf/tools/scratch-hooks/hook-fighters.mjs` (`node hook-fighters.mjs <stage tree>` then `... <stage tree> fine`; apply to a scratch tree made by `make-stage-tree.mjs` with `hook-stages.mjs`). Run: `node docs/perf/tools/stage-run.mjs --tree <tree> --out <csv> --seed 4 --frames 2400 --planet 7`, three at once, then the per-frame minimum of each column (a short script; it is in my scratch folder, not the repo).

## Limits

Loaded machine (82 to 99%), so milliseconds are about 1.5 times the quiet ones; the shares and the ranking are the result. Native, not web: the web build reads `r_fighters` at about 1.7 times native (2.1 against 1.2 in the 2026-10-30 report). One planet, one seed.
