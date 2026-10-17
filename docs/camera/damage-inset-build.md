# The damage inset: the build plan (Camera, 2026-10-17)

Owner: Camera and Cinematography. The plan for building `damage-inset.md` (the design, Orb's picture-in-picture of a dodged beam's damage), ready to start. The data and its schema are in `docs/camera/pending/build-ready/` (`damage_inset.json`, `damage_inset.schema.json`); both pass the repository's validator in a scratch copy (with the two map entries below) and the schema rejects a bad value (a negative threshold) as it should.

## 1. What is built on, and what is not there yet

| Piece | State |
| :--- | :--- |
| The inset pane and the panel strip's compositor (`SplitView`, `panel_mask.gdshader`, `SplitFrame.panel`, Rendering's `make_inset` / `inset_view`) | built; the panel record is `{kind, slot, open, still, band, rect, slant, size, cam_x, cam_y, cam_z}`, and its `double` kind already frames a world point (`cx`, `pw`), which is what a site is |
| Panel modes (full, still, off) and the ration (one per 12 s) | built (`camera_panels`, `set_panel_mode`) |
| The events: `beam_outcome {actor, target, kind}`, `building_stage {b, from, to, x, y, z, w, h, kind, cx, owner, n}`, `floors_fall {b, from, to, n, x, z, w}`, `building_fall {b, x, y, w, depth, mode, delay, cx, rubble, n, landmark}`, `S.beams` | exist; **no event names which beam caused a stage step or a fall** (the stand-in below) |
| A floors count on the damage events | not there (`floors_fall` has `from` and `to`, not the building's floors) |
| A calm flag for the inset's view | not there (VFX) |

## 2. The pieces, in the order to build them

All behind `SplitView.set_damage_inset(on)` / `SplitRig.damage_inset` (default off, build-time), the numbers from `data/camera/damage_inset.json`, loaded once by a small reader (`render/camera/camera_data.gd`, a class that reads a data file and falls back to the constants in `camera_params.gd` when a file or a key is missing, so the rig never depends on the file being there). The rig stays deterministic: it reads events and state, writes nothing to the sim.

**Step 1: the record of dodges and damage** (`SplitRig._dmg_events`, new). On each tick's events:
- `beam_outcome` with `kind == "dodge"`: push `{beam_owner: actor, dodger: target, t: time, line: <the beam's polyline from S.beams at that tick>}` to `_dmg_dodges` (at most 4, each lives `windowS`).
- `building_stage` (`to > from`), `floors_fall`, `building_fall`: look for a dodge in the window whose beam owner is the other fighter and, **with the stand-in cause**, whose line passes within the building's half width + the beam's width of `x` (the structure's centre); with the real cause (`by_beam`) match the id. Add points to that structure's `_dmg_score[b]` by `score` in the data (stages, floors share, a fall, a landmark multiplier, the tower bonus). The floors share needs the building's floors: with the event field absent, estimate from `h` over the storey height (World's `buildings.md`), flagged in the plan as an estimate.

**Step 2: the gate** (`_dmg_open(S)`). A site opens when its score reaches `thresholds.open`, it is **not already in the dodger's picture** (its centre projects inside the pane and is `visibleMinPx` or more wide: use `SplitFrame.screen_pos` and `apparent_height` of the building), the moment is not blocked (`blocked`: `intro_active`, `solo_kind` in the list, a lunge), the ration allows it (`ration`: the gap and the per-minute count from the rig's own times), and no fighter strip is up (the strip has priority; wait `waitForStripS`, else drop). The kind is `thumb` below `thresholds.big`, `strip` at or over it.

**Step 3: the record** (`SplitRig._dmg_frame(S)` beside `_panel_frame`). Same fields as the panel's record, kind `site`: `slot` the dodger, `open` (the wipe in `time.wipeIn`, out `time.wipeOut`), `still`, `rect`, `size`, `cam_x/cam_y/cam_z`:
- the camera stands at the site's centre; `cam_y` puts `frame.centerY` of the building's height at the plane's height; `cam_z` fits the building (`w`, `h`, or the whole building for a fall; `frame.margin`, `landmarkMargin`), never under `frame.minPx` drawn;
- the rect: for `thumb`, `thumb.w x thumb.h` of the screen (the phone's if the viewport is under 600 px high) at the top corner on the building's side inside the dodger's pane, `margin` from the edge, under UI's `panel_floor_y`; moved to the other corner or closed if a fighter's box would be under it. For `strip`, the panel strip's band (the existing `_panel_rect`);
- the life: from the first event, at least `time.minS`, on while events continue, closing `time.tailS` after the last, at most `time.maxS` (`maxFallS` with a fall);
- `still` when reduced motion, the setting `still`, or `flash.stillWhenReduced` and Reduce flashing: the frame at `flash.stillAtS` after the first fall event, held.

**Step 4: the compositor** (`SplitView`): generalize `_panel_*` drawing to take the `site` record next to `panel`: the same mask shader with a plain rectangle (no slant) for a thumbnail, the strip's slant for `strip`; the inset camera from `cam_x/y/z`; one inset at a time (the damage inset and a panel strip share the slot). Rendering's `inset_view` already takes a world point and a zoom, so no new Rendering API for the camera; **VFX's `inset_calm`** is the only grant (the flag `flash.calmFlag` names), asked of VFX.

**Step 5: UI.** Nothing new; the corner uses `panel_floor_y()`. The option `camera_panels` covers it (off: none; still: stills).

## 3. The sweep rows (`split_sweep.gd`, synthetic events through `rig.step(S, vw, vh, events)`)

| Row | Checks |
| :--- | :--- |
| `damage below the threshold` | a dodge and a one-stage step (0.5): nothing opens |
| `damage thumb` | a dodge and two stages: a thumbnail opens in the dodger's pane, in the corner on the building's side, under the HUD floor, the fighters not under it, lives 1.4 to 4 s |
| `damage strip` | a dodge and a fall: the strip's band, 6 s at most |
| `damage in the picture` | the building already 60 px wide in the pane: nothing opens |
| `damage not a dodge` | the same events after a `guard` outcome: nothing |
| `damage ration` | three sites in 10 s: one opens; a fourth in a minute is refused |
| `damage priority` | a fighter strip running: the inset waits 1 s and is dropped; a strip after the inset has started does not replace it |
| `damage blocked` | during the intro, a transformation, a launch's solo shot: nothing |
| `damage still` | Reduce flashing or still: a held frame at 0.5 s, no live render; opening and closing at once |
| `damage split` | in a split view the rect is clipped to the dodger's pane; the divider and both panes' cameras are those of a run without the inset (tick by tick) |
| `damage off` | with the switch off, the frames equal a run without it to the bit |

## 4. Acceptance

1. The rows above pass; with the switch off every digest equals a clean HEAD's (`depth_inert`).
2. `split_sweep`, seam, pane, determinism (plain and `--intro`) pass with the switch on and off.
3. A flash clip with the inset in it: a dodged beam into a tower in the city, normal and reduced (Tools' scenario, asked for): PASS, and collapse in both modes unchanged.
4. The cost: the inset's render at its size is measured by Performance on the web at 4x (the panel's 0.45 ms strip is the reference), and one inset at a time is enforced.
5. Legal's view: the inset frames the building, never people; Reduce flashing gives a still.

## 5. What to ask, in one list

| Who | Ask |
| :--- | :--- |
| **Simulation / Encounter** | `by_beam` (the beam's id) on `building_stage`, `floors_fall`, `building_fall`; the id on `beam_outcome`; the building's `floors` on the damage events. Until then the stand-in cause (the line test) and the estimate of floors |
| **VFX** | the inset view's `inset_calm` (flash layers off, the explosion's peak capped, embers at their reduced counts) |
| **Tools** | a scenario for the flash set (a dodged beam into a tower in the city, normal and reduced); the two map entries below; the cross-reference of the data (thresholds open <= big) |
| **Rendering** | nothing new for the camera; the inset at a distant structure may want a level of detail for a building 5,000 units off |

**Tools' two lines** for `tools/schemas/map.json`: `{"match": "data/camera/damage_inset.json", "schema": "camera-damage-inset.schema.json"}` and `{"match": "data/camera/intro_shots.json", "schema": "camera-intro-shots.schema.json"}`, with the two schema files copied from `docs/camera/pending/build-ready/` to `tools/schemas/` under those names, and the data files to `data/camera/`.
