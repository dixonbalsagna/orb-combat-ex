# director-22: the damage inset (parked, off)

Camera, 2026-10-30, from the EP's briefs: Orb's homework 5 ask, "dodging a beam that hits a skyscraper behind you should give a live picture-in-picture view of the damage, depending on how significant it is", then GD's rulings of the same day (`docs/design/rulings-2026-10-30b.md`). The design is `docs/camera/damage-inset.md`, the plan `docs/camera/damage-inset-build.md`.

To land it:
**State at the pause, 2026-10-30, with GD's 10-30d built: not ready for Orb's look. It misses GD's band, and a fall's picture shows the place after the tower has gone.**

| At `fallMinBh` 20 (kept; no value from 15 to 30 lands it) | Gen 1 | Gen 2 | Hand-made |
| :--- | ---: | ---: | ---: |
| Openings a match, scaled (beam + fall) | 1.51 (0.37 + 1.14) | 1.09 (0.25 + 0.83) | 0.86 (0.29 + 0.57) |
| Matches with none (target under 25%) | 45% | 47% | 50% |
| Open during an exchange | 70% | 71% | 62% |
| Empty matches with no tall fall out of the picture | 13 of 13 | 10 of 14 | 13 of 15 |
| Lived under 84 ticks (minS), of all openings | 10 of 50 | 12 of 38 | 4 of 32 |

- At 15, the widest: 1.68, 1.19, 0.86, with none in 41 to 50% of matches. Most empty matches have no tall fall out of the picture to open on, so the height isn't what's missing. **This goes back to GD (row 4).**
- **The film:** `docs/camera/img/damage-inset/real-match-fall-normal.gif` and `-reduced.gif`, AI seed 1, tick 6942, inputs at the frame edge. The opening is real, but the thumbnail shows an empty lot with no tower falling and no dust. Building the pane before the fall, and giving the fall its height in `planet_view.consume`, each changed nothing in scratch. The cause isn't found; it needs Rendering, and perhaps VFX for the dust. The tall dark building at the thumbnail's right edge wasn't identified.
- **Legal's conditions:** it reads structure events only, never a casualty or a head count, awards nothing and captions nothing, and row "the same with or without deaths" proves it opens the same. **"No people" isn't met yet:** the inset's pane draws fighters and the crowd. The patch asks with `inset_view`'s `"people": false`; nothing reads it until Rendering does.
- **Fixed by the film:** in a split the thumbnail opened in the corner the divider was about to cross, and lived about 3 ticks. It now takes only the pane's outer corner.
- **Gates on 18b78ea0, final cut:** off byte-identical (48,600 lines); split_sweep with 23 new rows, seam sweep, sweep_check and determinism pass, off and on; collapse on 2 / 2.5 / 2 and 2 / 2.5 / 1, both PASS (normal's memory was 1 before this trigger); schema clean on 251 files. **Stopped by the pause:** the staged signaturecity on and off, whose table below is from the earlier cut. Those clips have no look report: the side-by-side against the reference hasn't been run.
- The tables below are the earlier beam-only reads.

1. Apply `director-22-damage-inset.patch` (written on 3c40fae7). It touches render/camera and adds `render/camera/camera_data.gd`, `render/camera/tests/inset_rate.gd` and `data/camera/damage_inset.json`.
2. Copy `camera-damage-inset.schema.json` to `tools/schemas/`.
3. Add to the `rules` of `tools/schemas/map.json`: `{"match": "data/camera/damage_inset.json", "schema": "camera-damage-inset.schema.json"}`.

The switch is the data file's `enabled` (false), or `SplitView.set_damage_inset(on)`.

## The rate, beam trigger only (GD's 10-30c; GD's 10-30d replaced this band with 1 to 3 for both triggers)

**Scaled to a third of beams avoided: gen 1 0.52, gen 2 0.28, hand-made 0.35. All in the band, gen 2 at its low edge.** The floor moved from 0.5 under GD's row 5, after the second read below. The rule stays as it was: each building scores alone.

`inset_rate.gd`: whole AI matches through the rig, the inset on. Slot 0 is a scripted defender who avoids every third beam aimed at him. Planets and touches are QA's list. About 30 matches each; one gen 1 seed fell back to the hand-made world and is not counted.

| World | Matches | Opens for slot 0 a match | Matches with none | Avoided share of beams | Slot 0's avoided beams | Reached the score | Opened |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Gen 1 | 29 | **0.62** | 15 | 40% | 69 | 18 | 18 |
| Gen 2 | 30 | **0.33** | 21 | 39% | 76 | 11 | 10 |
| Hand-made | 30 | 0.40 | 18 | 38% | 77 | 12 | 12 |

- The script avoids a little more than a third, because the AI's own swats count too. The scaled rates are arithmetic, not a run.
- **The gates are not what holds it down.** Of the avoided beams whose damage reached the score, 40 of 41 opened.
- Slot 1, the AI, opens 0.17 to 0.20 a match on its own avoids and swats. Those aren't counted in the rate.

### Why most beams open nothing (GD's 10-30c row 3)

The same matches, with each avoided beam read:

| World | Avoided beams | No building in reach | In reach, none damaged | Damaged a building | Of those, best building under 1.0 | Sum at 1.0 or more | Scaled |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Gen 1 | 69 | 46 (67%) | 5 | 18 | 0 | 18 | 0.52 |
| Gen 2 | 76 | 54 (71%) | 11 | 11 | 0 | 11 | 0.31 |
| Hand-made | 77 | 65 (84%) | 1 | 12 | 0 | 12 | 0.35 |

- **Most beams find no building at all. No beam scratched a building and fell short:** every beam that damaged anything had a single building at 1.0 or more.
- **Scoring the beam changes nothing.** Run side by side on the same matches, `scoreBy: "beam"` opened exactly as the building rule did. Gen 2 needed 0.5, so it isn't in the park.
- "No building in reach" is read along the line from the outcome on, so it can miss a building that fell before then: hand-made tier 3 shows 2 in reach and 3 damaged.
- Beams that damaged something averaged 5 to 52 in summed score by tier, far past the 1.0. The best building averaged 21 to 26 body heights.

| World | Openings by third of the match | Median minute | By the beam's tier (1 / 2 / 3 / 4) |
| :--- | :--- | ---: | :--- |
| Gen 1 | 1 / 7 / 10 | 6.2 | 0 / 4 / 5 / 9 |
| Gen 2 | 3 / 3 / 4 | 5.5 | 3 / 1 / 2 / 4 |
| Hand-made | 0 / 4 / 8 | 6.9 | 0 / 2 / 3 / 7 |

It mostly belongs to the later, bigger part of a fight, as GD's row 5 expected. Gen 2 is the least so: 3 of its 10 come from tier 1 beams.

### Falls no one sees (counted only, nothing opens)

| World | `building_fall` events a match | Off every pane | In a pane, drawn under seenShare |
| :--- | ---: | ---: | ---: |
| Gen 1 | 21.7 | 17.4 (80%) | 3.0 |
| Gen 2 | 37.9 | 28.7 (76%) | 7.5 |
| Hand-made | 32.0 | 25.8 (80%) | 4.7 |

Each event is one building, read where the camera is on the tick it's sent. They weren't grouped by blast, so one big blast can be many of them. GD's row 6 sends this back for a ruling.

## Whether reach 400 loses real hits (GD's row 3)

Every building stage credited to a fighter with a live beam, within the window of an avoided beam of that fighter (or a swat), read against the beam's line at several reaches:

| World | Stages | Credited at 400 | At 600 | At 1,200 and up |
| :--- | ---: | ---: | ---: | ---: |
| Gen 1 | 199 | 199 | 199 | 199 |
| Gen 2 | 313 | 313 | 313 | 313 |
| Hand-made | 461 | 456 | 459 | 461 |

400 stays: it loses 5 of 973. It needed the beam's whole length: a line cut where it meets the ground credited only 21 to 40%, because the beam goes on biting below ground.

## How the build differs from the plan, and why

| Plan (10-17) | Built | Why |
| :--- | :--- | :--- |
| Wipes 0.12 / 0.18 s | 0.08 / 0.12 s, the strip's | Orb, 10-18: slow wipes read as fading |
| Moves to the other corner if a fighter comes under it | The corner is chosen at opening. After that it closes (eight ticks' look ahead), and goes at once if a fighter gets there first | A jump is not an eased move, and nothing is drawn over a fighter on any frame |
| The beam's line passes the building | The live beam's whole length, or its line as recorded at the outcome if it has gone, within `reach` (400 units) of the building; a stage's own `owner` must match | On main a signature comes down steeply and damages along its full length, including below ground; buildings are hit by the blast |
| Dodges only; shut if the building is 60 px wide on screen | `avoided`: DODGE, ESCAPE and DEFLECT, a swat's beam credited on the live fork. `seenShare` 0.5: shut only if the centre is in the dodger's pane and it is drawn at half the pane's height or more | GD's rulings 10-30b, rows 1 and 2 |
| Damage comes after the dodge | Damage within the window before or after it | The beam carves on its way; the outcome is called when it reaches the dodger |
| Floors estimated from the height | `b.floors`, read from the state | It is there now |
| A phone's larger thumbnail | Not built | ADR 0011 |
| Its own viewport size | The strip's viewport, its middle shown | Remaking the inset's viewport for each size would hitch the match |
| A collapse in a split is the strip, cut at the divider | The thumbnail in a split | The strip's slant is not cut at the divider |
| A running inset follows a collapse's centre, or a stronger one replaces it | The camera stays on the building; no replacement | Fewer moves. The kind is decided at opening |
| The register asks once | It keeps asking while the inset is up, and wipes in from when it is let in | A beam's flashes come just before it: asked once, it was refused for its whole life in normal mode |

The inset takes the panel's slot in the frame (kind `site`), so it shares the strip's compositor, its register ask and its off and still options (`camera_panels`).

## Proof

Nothing under render/camera or data/camera has changed from b7a2cd86 to 521bc9c9, and the patch applies there. On the final patch, on 521bc9c9: clip_digest off, split_sweep off and on, determinism plain off and --intro on. The seam sweep, sweep_check, the --intro run off, the schema and the flash clips are from the cut before it on b7a2cd86. The final patch adds only a beam id and a score to the rig's records, which the rate tool reads; those weren't re-run.

| Check | Off | On |
| :--- | :--- | :--- |
| clip_digest, default set, both modes (48,600 lines) | byte-identical to main | |
| split_sweep, with the 16 new rows | PASS; every line equal to main's but the frame and check counts | PASS |
| seam sweep, sweep_check | PASS | PASS |
| determinism | plain and --intro PASS | --intro PASS |
| collapse, normal / reduced | not run: off's camera is byte-identical | 2 / 2.5 / 1 PASS, 2 / 2.5 / 1 PASS |
| schema, in a scratch copy with the map line | all 250 data files clean; a bad `seenShare` is refused | |

The staged dodge (below), Tools' signaturecity clip with the inset open:

| Build | normal | reduced |
| :--- | :--- | :--- |
| inset off | 3 / 4 / 3 FAIL | 2.5 / 3 / 2.5 PASS |
| inset on | 3 / 4 / 3 FAIL | 2.5 / 3 / 2.5 PASS |

The inset adds nothing to the count. That FAIL is the staged scene's own.

**Side-by-side:** `docs/camera/img/damage-inset/damage-inset-staged.gif`. It is a staged scene in a scratch tree (the dodge forced, the dodger pinned 1,200 units up), recorded on the first cut. The rulings changed when it opens, not what it draws.

## What to know before turning it on

1. **It opens about once in every two to four matches** on the script's third of beams, and most matches have none. GD's assumption of a third is a guess at a player, not a measurement. Unseen falls are back with GD (above).
2. **The picture is a first look.** At the framing that fits a tall tower, fighters who cross it read as dark blobs, and one stage of damage on a tower isn't obvious. The sky can differ from the main view's; that is the place's own sky.
3. **Under Reduce flashing, the default, this cut is a still**, taken 0.5 s after it opens, so most players see a held frame. GD's row 6 wants it live if VFX's `inset_calm`, the flash set, the look gate and Performance's reading pass. None of those has run.
4. **Not measured:** the cost on the web. It renders at the strip's viewport size, whose reference is about 3 ms at x4, for the inset's life. No Tools scenario exists, so the flash reading above is from a scratch stage.
