# The varied intros' shot grammar as data (Camera, 2026-10-17)

Owner: Camera and Cinematography. The shot grammar of `varied-intros.md` as a data file, with its schema, its cross-reference check and the first build's acceptance, ready to build. The files are in `docs/camera/pending/build-ready/`: `intro_shots.json` (25 families, 19 weights, 12 rules), `intro_shots.schema.json`, `check_intro_shots.mjs`. The data and the schema pass the repository's validator in a scratch copy (with the map entries of `damage-inset-build.md` section 5) and the schema rejects a misspelt anchor; the check script finds no broken reference.

## 1. The file

`data/camera/intro_shots.json`, schema `camera.intro_shots/1`, closed except underscore keys (the repository's convention).

| Block | What it holds |
| :--- | :--- |
| `hash` | the algorithm (`fnv1a32`) and the fields it hashes, joined with `\|`: `seed, phase, actor, biome, tod, tone, arrival, template` |
| `constraints` | at most 3 hard cuts in any second and 8 in the intro (today's count), `noRepeatPerPhase` 2 (the host's intro record), `scrollBound` 0.045 (the fight's bound on the picture's change in a tick), `faceMinStareTicks` 120 |
| `defaults` | the family played per phase when nothing else decides; they are today's shots (F1, D1, L1, W1, S1, C1) |
| `sets.reducedMotion` | the fixed families for reduced motion (R1 to R6: the spot, the landing, the two-shot, level and still), no faces, 0.3 s dissolves |
| `sets.reduceFlashing` | `replace`: F1 (the ride-along fall) becomes F2 (from the ground), and no faces |
| `families` | each: `phase` (fall, descend, land, wait, stare, closing), `arrival` (which arrival kinds it fits), `title`, `cuts`, `scroll` (worst share of the width a tick), `legacy` (today's shot: exempt from the scroll bound), optional `needs` (a pitch or a field of view Rendering must give), `requires` (a settlement in view, or a closing), and `keys` |
| `weights` | the base weight of each family in the ordinary mode |
| `rules` | `when` (biome, time-of-day band, tone, arrival, template, closing, settlement, rematch) multiplies the weights named in `mul`; a 0 forbids |

**A keyframe** is `{t, cut?, anchor, dx, dy, r, ay, pitch, fov?}`:
- `t` is the position in the shot, 0 to 1 of the phase's span (the event gives the span: the fall's `dur`, the staredown's `dur`, the landing's 48 ticks before the next beat);
- `cut: true` makes the camera cut to this key (every shot but a closing opens on one); otherwise it eases from the key before (smoothstep);
- `anchor` is what the key is placed against: `faller`, `lander`, `spot` (the landing spot), `crater` (its centre), `pair` (the two fighters' middle), `other` (the other fighter or his spot), `sky` (straight up from the spot);
- `dx`, `dy` are body heights from the anchor (`dy` up); `r` the subject's height as a share of the screen's; `ay` where the anchor sits on the screen (0 top, 1 bottom, 0.62 is the fight's); `pitch` in degrees (negative limited to -6 by the ground rule; the checker refuses lower); `fov` a multiplier of the field of view (1 is the game's; a family that uses it is marked `needs.fov` and waits for Rendering's lens).

The numbers are first values; the legacy families reproduce today's shots (F1 the ride-along with its `INTRO_FALL_ANCHOR_Y` 0.38, L1 the low wide at pitch -6 and the crater filling 55% of the width: the first build matches today's cut ticks and cameras tick by tick before anything new is on).

## 2. The picker (what the rig does with it)

For each phase of a fighter's arrival (from `intro_start`, `entrance_fall`, `entrance_land`, `staredown_start`, `clock_start`):
1. `ctx` = the event's fields and the intro's setup (seed, the actor's slot, the biome at the spot, the time-of-day band, the tone, the arrival kind, the template id, the closing, the settlement flag, the rematch flag); a field the events do not yet carry takes a neutral value (`plains`, `day`, `neutral`, `drop`, `double-drop`, no settlement), so the build can start before Encounter's fields.
2. Candidates: families of the phase whose `arrival` list has the fighter's arrival kind and whose `requires` hold; the set for the mode first (reduced motion plays its fixed family; Reduce flashing applies `replace`).
3. Weight: `weights[f]`, times every matching `rule`'s `mul[f]`; a family the last `noRepeatPerPhase` picks used is multiplied by 0 unless it is the only one left.
4. Pick: `h = fnv1a32(join("|", fields))`, `u = h / 2^32 x sum(weights)`, the first family whose cumulative weight passes `u`. The same context always gives the same family.
5. Check the constraints: the intro's cut count and the second's cut count with the family added; if it breaks either, the next family by weight is tried; at the end the phase's default.
6. Play the keys: from the phase's span, per tick, the interpolated key gives the focus, the zoom (from `r`), the pitch and the field of view; a `cut` key starts the cut machinery (the dip, the fade when needed).

**A worked example** (these two come from `check` with the data as it stands). Context `1|land|0|desert|dusk|grave|drop|double-drop`: hash 4012358230, weights L1 8, L2 4, L3 0.5, L4 0.5, L5 0 (no settlement), total 13, `u` = 12.14 against the cumulative 8, 12, 12.5: **L3 (overhead)**. Context `2|land|0|mountains|day|light|drop|double-drop`: hash 2920907440, weights L1 4, L2 6, L3 0 (mountains forbid it), L4 2, total 12, `u` = 8.16: **L2 (crater lip)**.

## 3. What the rig replaces

The hand-written timeline (`_intro_fall`, `_intro_land`, `_intro_stare`, `_intro_faces`, `_intro_clock` and the `INTRO_*` constants in `camera_params.gd`) becomes: the picker, a keyframe player, and the data. The event handlers stay (they carry the timing), the cut machinery stays, the forced single view at the two-shot stays (the fault Rendering found: a solo pane keeping the screen). The legacy constants are the data's legacy families, so the switch off leaves the code path as it is.

## 4. The checks

- **Schema** (`tools/validate.js` with the two map entries): the shapes above, the closed policy, the ranges (a `pitch` in -90 to 90, an `r` over 0 and at most 0.3, `ay` 0 to 1).
- **Cross-references** (`check_intro_shots.mjs`, to fold into Tools' `xref`): `defaults` and both sets name families of the right phase; every non-reduced family has a weight, a reduced-set family has none; `weights` and `rules` name families that exist; `t` starts at 0, ends at 1 and does not go back; the first key cuts (a closing continues the staredown and does not); `cuts` equals the number of cut keys; a family over `scrollBound` is `legacy`; no pitch under -6; a family that `needs` a pitch has a key that reaches it.
- **Rows** (`split_sweep.gd`): each family played on the injected timeline: the subject on the screen at every tick of his own shot, the cuts equal the data's, the worst travel under its `scroll` (the legacy ones to their measured), the same context gives the same family over 1,000 seeds, every non-zero-weight family comes up over 1,000 seeds in a context that allows it, none of weight 0, a reduced-motion run has only the R families and dissolves, a skip at any tick is one cut with the fade, two humans get the same cameras as the AI.
- **Clips** (Tools): one per family, normal and reduced; F1 is the one over the bound (the reduced-flashing set already drops it), and if the opening becomes the default the pixel gate reads it first.

## 5. Acceptance for the first build (behind `varied_intros`, default off)

1. With the switch on and only the legacy families allowed (the default set), the cut ticks and the cameras of the intro are today's, tick by tick (the existing rows "intro full / humans / reduced / skip" pass unchanged).
2. With all families allowed: the rows above pass; the picker is a pure function of the context; a replay of a recorded match plays the same shots.
3. The golden does not move (the camera writes nothing) and `determinism --intro` passes.

## 6. What the first build still needs from others

Encounter and Narrative: the template id, each fighter's arrival kind and role, the closing and its tick, the tone and stakes, the history flags (rematch, last winner), the voice lines' ticks (`varied-intros.md` section 6). Simulation or World: the biome, slope and settlement at each spot. Rendering: the time-of-day band, a pitch up to 60 degrees (L3) and a narrower field of view (S3). Until they are in, the picker uses the neutral values above, and the families that need a field (L5, C2, S3, L3) stay at weight 0 or are marked `needs`.
