# The LT zip: the body side (2026-10-05)

Owner: Animation. Source: Orb's approved prototype `docs/ep/prototypes/lt-zip-v4.html`, `docs/design/melee-press-feel.md` section 2c, Orb's answers in `docs/ep/vision.md` (the last two sections): "the character should zip back and forth in a stylistic blur, matching our visual cues we established for speed, tech and heavy", the exit anywhere on a circle around the rival, further out with the stick away. Status: **built behind the press-styles flag** (`RenderAnim.press_styles`, `--press-styles`, Shift+F7), with a lab and review GIFs for both fighters. The sim sends nothing yet: the lab plays the sim's part by hand, and section 6 lists what Encounter's beat must carry.

## 1. What the body does, phase by phase

The sim moves the fighter along the zip; the body poses. A zip has four phases, the prototype's ticks (60 Hz, in `data/anim/zip.json`, overridden by what the beat says):

| Reading | Tell | In | In reach (blows of `hd` ticks) | Out |
| :--- | ---: | ---: | :--- | ---: |
| Speed (mashed) | 6 | 6 | 3 blows of 8 | 6 |
| Tech (timed) | 6 | 4 | 1 blow of 16 | 4 |
| Heavy (held) | 26 | 8 | 1 blow of 22 | 10 |
| A pressed: the tackle | 8 | 7 | the carry, 22 | 8 |
| A held: the lift and throw | 22 | 7 | the lift 18, then the throw 30 | 10 |

| | Speed | Tech | Heavy |
| :--- | :--- | :--- | :--- |
| **Tell** (a crouch along the line) | the entry's dash start: crouched, forward, eased in | the same, 6 ticks | the heavy's wind-up: the entry's plant-coil crouch plus the press styles' **squash** (legs, pelvis and spine toward a crouch pose, a lean back) |
| **Travel** | the entry's dash travel pose: a **low run**, blurred by VFX's after-images (3) | the entry's **skid run**, a **fast, upright, clean dash** (a long stride, the arms close, no crouch), drawn on every tick for at least 4 ticks, so it reads differently from the speed zip's low run (Legal RL-076: a zip that crosses in 2 ticks is the vanish-and-reappear staging) | the entry's coil-spring travel pose, a **stretched lunge**, plus the press styles' **stretch** (the spine extends, the body leads by 3 units) and a **smear frame** on the last tick before arrival (`zip.smear`) |
| **Strike** | the fighter's own key sets (X: jab, cross, jab; Y: kicks; B: both hands), speed reading: contact on the trigger frame, alternating limbs | the same key sets, tech reading: the contact pose on the contact tick with no in-between, a held beat, a quick return | the same, heavy reading: release with stretch and smear, a held follow-through |
| **Out** | a **back-step** (the entry's hop back) when the sim moves him away from the rival; a **run** (the dash travel pose, turned along its path) through, up, down or around | the same clean dash, or a back-step; at least 4 ticks | as the speed zip's way out (the prototype does the same) |

**The tell is the strike's wind-up.** A strike beat of a zip carries `zip: true` and its reading as `style`: the strike block then cuts its own wind-up to 2 ticks (3 for a heavy) and drops its squash, so the blow lands on the arrival, and the body is not squashed twice.

**The way out reads the sim's motion.** The body does not need to be told which way he leaves: on the first ticks of the way out it reads his velocity (as the flight lead does). Away from the rival, along the facing, is a back-step; anything else is a run. The facing turns by itself when he passes the rival (the pass-through turn is the existing turn layer, no new pose), and **up, down and around** tilt the body along its path (below). A beat can say `via: back` or `run` to force it.

**Turned along the path.** During a run, the whole body tilts toward its direction of travel, up to 1.2 rad and smoothed, after the flight lead (so the lead does not stand it back up), with the same pivot shift the lead uses. Under 700 units a second it does not. A zip that exits up or down shows the body leading up or down; one that exits around the rival is a run with a facing change.

**Caught and countered.** The zipper's hit reactions are the existing ones, played by the sim's damage events: a light hit in reach is a flinch and recoil, a heavy hit on arrival the crumple (`on_hit`'s heavy path). `RenderAnim.zip_end(S, f, reason)` stops the zip's layers so the reaction owns the body. Nothing new is posed.

**The tackle and the lift and throw.** A pressed A: the tell, the run, then the **tackle** pose held through the carry (the shoulder first, both open hands forward and apart); the rival he carries is held in the **carried** pose (leaning back, the heels dragging) for the carry, by `zip_held(S, f, "carried", dur)`. A held A: the **lift** pose for the 18 ticks of the lift, the rival in the **lifted** pose and raised by a cosmetic 26 units (`carry` in the data; the sim can move him instead), then the **throw** pose for the release.

## 2. Poses: which are new

**No new strike poses.** Every strike is the fighter's own key set. The tell, the travel and the back-step are existing entry poses (the Protagonist's `pe.*`, the rival's `w2.*`: `dash.start`, `dash.travel`, `plant_coil.start`, `coil_spring.travel`, `hop_back.start` and `.travel`), with the shared `approach.launch`, `move.dash`, `brace`, `move.burst` and `move.brake` as the fallback for a fighter without them. **Five shared hold poses are new** (wave `pair2`, prefix `zp`, 8 poses with the 3 sequences, baked with both fighters' `more` list, about 3 ms): `zp.hold.tackle`, `carried`, `lift`, `lifted`, `throw`. Legal's lines: open hands only, a two-hand hold keeps the hands apart, no clasp, nothing overhead (the lift is at shoulder height), no hand at a hip; `pose_lint` passes all five.

## 3. Squash, stretch and smear inside the joint limits

The same rules as the press styles (`docs/animation/press-styles.md` section 5): the squash is a blend of two valid poses on the legs, pelvis and lower spine; the stretch and the lean are a few hundredths of a radian on a spine and a neck that have no limit of their own; the tilt along the path is a rotation of the root, which no joint sees; the final limb pass runs after. **Checked by `anim_check` and the lab: on every scene, for both fighters, no joint past its limit reaches the screen** (0 of the solved frames after the last pass; the stage audits before it show the same few arm-back marks the plain stance has).

## 4. What I expose for VFX

On `RenderAnim.fighter(S, f)` (an `AnimFighter`), after a solve, beside the press hand-off:

- `zip` (empty when no zip plays): `reading`, `style` (speed, tech or heavy: the **look** to use, the same cues set for the press styles: smear for speed, crisp snap for tech, squash for heavy), `btn`, `phase` (`tell`, `in`, `reach`, `out`, `settle`), `tick`, `via` (`back` or `run`, once read), `ghosts` (how many after-images the reading asks for), `smear` (the smear frame), `travelling` (a run, so the blur is on), `ticks_to_arrival`, `reach_ticks`, `hits`, `tilt`, `bone`.
- `press_pose(k)`: the pose k solves back, now with its **world position** (`pos`, a Vector2) and `vface`: the after-images belong where the body was, not where it is. Up to 12 solves, kept 0.4 s.
- `zip_path`: where the body was over the last 24 solves, `{T, x, y, phase}`: the path of the body for the streak lines and the blur.
- The press hand-off (`press`, `press_path`) is filled while a zip's blows play, as for any blow.

The lab draws the previous poses as flat translucent bodies at their world positions (`--ghosts`): that is the hand-off in use, not VFX's look.

## 5. The lab, the GIFs, the checks

`render/anim/tools/zip_lab.gd` plays a zip through the real solver with the sim's part by hand (the prototype's positions, the strike beats, the damage events, the defender's answer). Scenes: `speed`, `tech`, `heavy` (with `--btn=x|y|b`), the exits `through`, `up`, `down`, `away`, the answers `caught` and `countered`, and `tackle` and `throw`. `--measure` runs headless and prints the phases, the contact error and the joint violations; `--ghosts` draws the hand-off; `--off` plays the same beats without the press styles (nothing zips).

```
godot --no-window --path . -s res://render/anim/tools/zip_lab.gd -- --scene=heavy --fighter=antihero --ghosts --out=a.rgb
godot --headless  --path . -s res://render/anim/tools/zip_lab.gd -- --scene=speed --fighter=protagonist --measure
```

Review GIFs for both fighters in `art/animation/review/zip/`: `speed`, `tech`, `heavy` (X), `speed-kick`, `tech-kick`, `heavy-both` (Y and B), the exits `exit-through`, `exit-up`, `exit-down`, `exit-away`, `caught`, `countered`, `tackle`, `throw`; 14 a fighter, 28 in all.

Checks (a fresh HEAD export plus my files, headless): `anim_check` (a new zip test: every reading on both fighters plays its phases in order, no joint past its limit on screen, contact on the contact tick, every reading is drawn travelling for at least 4 ticks each way (the floor), the heavy one smears, the hand-off has a path and previous poses with a position, and nothing plays with the flag off), `joint_scan --strict --waves` (760 poses and 100 sequences, none past a limit, the new poses included), `lead_scan --strict --max=40`, `coverage_live --strict`, determinism, `validate.js` (with `docs/animation/handoff/zip-schema-no-snap.patch` on Tools' schema: 150 files, 0 errors).

## 6. What I need from Encounter (the zip's beat)

The body reads only what the sim already decides; nothing here moves a position. Three things go to the body, each as a beat or a cue the render reads (`RenderAnim.zip_start`, `zip_end`, `zip_held` are the entry points; routing a cue to them is a three-line change in `render_anim.gd` once the cue has a name):

1. **The start of the zip** (to the zipper), once, at the tick the tell begins:

| Field | Meaning |
| :--- | :--- |
| `reading` | `speed`, `tech`, `heavy`, `press` (A pressed: the tackle) or `hold` (A held: the lift and throw) |
| `btn` | `x`, `y`, `b` or `a`: for the look only; the strike is the beat's `piece` |
| `tell`, `in`, `hits`, `hd`, `out`, `lift` | the phase ticks, **the sim's own** (the body's defaults are the prototype's; they must equal the sim's or the pose and the position part ways): the tell, the way in, the number of blows in reach and the ticks of each, the way out, the lift's ticks for a held A |
| `t0` | the sim time the tell begins (else the time the cue arrives) |
| `via` | optional: `back` or `run`. Absent, the body reads the way out from the sim's motion |

2. **The strike beats of the zip:** the same `strike` beat as any blow, with `zip: true` and `style` set to the reading (the beat fields the press styles already ask Encounter for: `style`, `grade`, `k`, `n`, `closing`, `charge`, `hand`, `ender`), contact on the arrival tick for the first blow. The tell is the wind-up, so the strike block needs **no** wind-up notice: a zip blow may be announced only 2 ticks ahead.
3. **The end and the hold:** `zip_end` with a reason (`caught`, `countered`, `cancelled`, `outrun`) when the zip stops early, at the tick it does (the sim's damage events then play the reaction); and `zip_held` to the **rival** (`carried` or `lifted`, the ticks) for the tackle and the lift. If the sim moves the lifted rival (a hold's rise in his `y`), say so and I drop the cosmetic 26 units.

**The floor on travel (Legal RL-076, `docs/legal/zip-screen.md`, `docs/design/melee-press-feel.md` section 2c).** Every zip, every reading, each way, takes at least max(4, ceil(the distance in bh / 3)) ticks with the body drawn on every tick. The body's defaults are 4 for tech, 6 and 6 for speed, 8 and 10 for heavy; **the sim sets the real `in` and `out` by the formula** and the body takes them from the spec, so a long zip's travel is longer than the default. `anim_check` fails if a reading's default is under 4 either way or has no travel pose, or if a lab zip is drawn travelling for fewer than 4 ticks. Nothing hides, fades or replaces the body: the lab's translucent bodies are the hand-off drawn, not the body.

## 7. Risks and what is not done

- The position is the sim's. In the lab it is the prototype's easing; a real zip depends on the sim's path matching the phase ticks.
- Up and down exits tilt the body by the measured velocity, which the sim must move him with (a rise in `y`), not teleport.
- The strike's `zip: true` cut of the wind-up is only in the press-styles path: with the flag off a zip's blow plays as any blow.
- The tackle and throw are first looks over five new hold poses; Legal's eye is needed on them (they are holds, not blows).
- The looks (the streak, the echoes, the ring) are VFX's: they read `zip.style` and `zip.ghosts`; the lab's flat ghosts are not a look.
- `a` buttons from the air (a dive grab) are Combat's wave 4 grabs: not posed, not part of this.

## 8. The zip slice (2026-10-06): entries at zip speed, the far-side pass, the check's guard, the push style

- **Entries at zip speed.** A zip's spec may name an entry of the fighter's own for the way in (`entry_in`) or the way out (`entry_out`), a name such as `spiral` or `pivot` as Combat's rows give (`pe.spiral` in, `pe.pivot` out); a reading's data row can too. The entry layer plays the whole sequence squeezed into the zip's ticks (`fit`: every phase shrinks together), so the entry is drawn whole in 4 to 10 ticks. A name he has no entry for plays the run or back-step poses as before. **Checked for all 17 and 15 entries** (`zip_entries_lab.gd`: a sheet a fighter, `art/animation/review/zip-entries-protagonist.png` and `-antihero.png`, a row of seven ticks an entry at a 6-tick zip): every entry is drawn on every tick and reads whole. The fastest turns of a bone between two ticks are the full flips and flights (`air_roll` 2.2 rad a tick on the pelvis, the rival's `coil_spring` 2.3 on the arm, `dash` 1.7, `spiral` and `arc_dive` about 1.4); they read as a blur at 60 Hz, the way a flip does, and no in-between pose was needed. The step entries (`lane_step`, `pivot`, `fade`, `step_in`, `plant_coil`, `backstep_counter`) change little by design: their travel is the sim's. **No new pose.**
- **The far-side pass.** A spec's `pass: over` plays an arc dive over the rival and `pass: round` a pivot round him (`pass` in `zip.json` names the entries), over the way out, with the rival in view and the facing turning by itself: `art/animation/review/zip/pass-over-<fighter>.gif` and `pass-round-<fighter>.gif`. Combat's `entry_out` wins over a `pass`.
- **The guard layer a check is thrown over.** A strike beat with `check: true` keeps the arm that is not striking in the defensive guard (`press_styles.json` `guard`: the pose, the arm bones, a weight 0.9), closing over the wind-up and opening over the return; a foot, knee or head check guards both arms. The strike and its contact solve are unchanged: `art/animation/review/press-styles/check-<fighter>.gif` (off on the left, on on the right).
- **The push style.** `styles.push` in `press_styles.json`, a beat's `style: "push"`: no impact snap (the blow drives into its contact over 5 ticks from a 10-tick wind-up), no overshoot, a 10-tick follow-through and a 12-tick return, a squash of 0.35 and a body drive of 4 units. Contact lands on the contact tick, within 0.02 rad of the key (`press-styles/push-<fighter>.gif`).
- **Tests:** `anim_check` `_test_zip_slice`: an entry, a pass over and a pass round play on both fighters with no joint past its limit, a missing name falls back, a check holds the guard arm (0.15 rad closer to the guard than without), a push drives for 4 ticks or more where a tech blow has none.
- **Schema keys** (sent to the EP as a one-liner first; the delta patch is `docs/animation/handoff/zip-gestures-schemas.patch`): `readings.<r>.entry_in`, `entry_out` and the top-level `pass` in `zip.json`; `styles.push` and the top-level `guard` in `press_styles.json`.

## 9. Contract with the director (2026-10-07; Animation's answers to Encounter's four questions, no code yet)

**The rule: the read is the truth, the cues are edges.** The body polls `DirZip.read(S, f)` once per solve and poses from it; the cues only mark the moments (start, the exit becoming known, an early end) so VFX and I can start and stop a layer on the right tick. Nothing in a cue is needed twice.

**1. The read (yes).** `DirZip.read(S, f)` returns an empty dictionary when `f` is not zipping, else:

| Field | Meaning |
| :--- | :--- |
| `reading`, `btn` | `speed`, `tech`, `heavy`, `press`, `hold`; `x`, `y`, `b`, `a` (so the start cue carries neither) |
| `phase`, `n`, `len` | `tell`, `in`, `reach`, `out` or `settle`; the live ticks since the phase began (a hit-stop does not advance it), and the phase's length in ticks. This replaces my time-derived phase, which drifts through a hit-stop |
| `tell`, `in`, `hits`, `hd`, `out`, `lift` | the whole plan, as now (`out` is the default until `zip_out`, then the real one) |
| `blow` | the index of the blow in reach (0 first), for the look only: the strike beats still carry the blow |
| `via`, `pass`, `entry_in`, `entry_out` | the way out and the entries, empty until known (`via`: `back` or `run`; `pass`: `over`, `round` or empty); an empty `entry_*` means the body's default from `zip.json` |
| `dist_bh` | the distance at the start in body heights, so I can assert the floor on a live zip |

Without a read (the lab, a replay with the flag off) the body keeps its time-derived phase from `zip_start`. That is a fallback, not a second path to maintain: both end in the same `z` dictionary.

**2. The exit (yes, with no earlier warning, and late degrades without a pop).** The out phase is posed from `out` ticks and `via`, `pass`, `entry_out`: the entry is squeezed into `out`, so I need those on the **first tick of the out** and no sooner. `zip_out` therefore works if it is **on the last tick of reach or earlier; the least notice is zero ticks**: the cue is consumed before the solve of the same tick, so the first out tick is posed from it. If it arrives late (after the out has begun), the body has already played the default way out; it switches to the named entry or the pass over **3 ticks** (a blend, not a pop) and the entry plays in the ticks that are left. The arc dive and the pivot need the rival in view, which the render keeps on its own. The exit's geometry (dx, dy) stays the sim's: I need only `ticks`, `via` and `pass`. The last blow's contact tick must come before the first out tick (it does by construction: the follow-through is in reach).

**3. One list of end reasons.** Split what is one list into two: **exit kinds** (how a zip that finishes leaves: `home`, `far`, `point`) come in `zip_out` and in the read's `via` and `pass`; they are not ends. **End reasons** (the zip stopped early) are on `zip_end`, `text` = the reason:

| Reason | When | The body |
| :--- | :--- | :--- |
| `stopped` (my `cancelled`: one word, `stopped`) | the zipper let go or the sim cancelled it, nothing hit him | layers off, the stance takes over over 4 ticks (a blend from the pose he is in); no reaction |
| `outrun` | the rival got away and the zipper arrives at nothing | the whiff he already has (`_over_commit`: carried past, off balance), then the stance; if he has no momentum, as `stopped`. A small addition on my side when the cue exists |
| `countered` | a blow met him on arrival | layers off on that tick; the sim's damage event plays the crumple (the heavy hit path) |
| `caught` | a light hit him in reach | layers off on that tick; the damage event plays the flinch and recoil |

`zip_end` must arrive on the same tick as the damage event or earlier; later, one tick of the zip pose shows under the reaction. The normal ends (`home`, `far`, `point`) need no `zip_end`: the read goes to `settle` and then empty.

**4. Routing (three lines in `render_anim.gd`'s cue branch once the names are final).** `who` is the cue's actor, `t_cue` the event's own time, as the other cues use:

```
"zip_light", "zip_heavy":  zip_start(S, S.fighters[who], {"t0": t_cue})      # reading, btn and the plan come from DirZip.read
"zip_out":                 zip_out(S, S.fighters[who], t_cue)                # new: latches via, pass, entry_out and the real out ticks from the read
"zip_end":                 zip_end(S, S.fighters[who], String(e.text))       # the reason, as in the table
```

`zip_light` and `zip_heavy` both route to the same line (the reading says which look); VFX can still tell them apart by the cue name. `zip_out` is the one new function (`AnimZip.out`, about ten lines: it sets `via`, `entry_out`, `out` and `T4` and starts the 3-tick blend if the out has already begun); I write it with the routing, in my files.

**Legal's standing rules (RL-076, `docs/legal/zip-screen.md`) still hold for what is built, and I assert them on the live zip when it exists.** The body is drawn on every tick of the zip with a travel or entry pose, never hidden, faded or replaced; each way takes at least max(4, ceil(distance in body heights / 3)) ticks, which the sim sets and the read's `in`, `out` and `dist_bh` let me check (a live zip below the floor fails `anim_check`'s zip slice, as the lab's does now); the arc dive plays only over the way out, after the last blow's follow-through, so it is never under a strike tick and never behind the rival at that tick. The one thing that would break the last two is a way out that begins before the last contact tick: please keep the strike inside reach.

## 10. The dropped zipper (Simulation's `dropped` state; the plan, docs only)

**Reuse, nothing new to pose.** A zipper shot out of his way out falls for up to 24 ticks "as in a tumble": the body already has a tumble (`launched`: the ragdoll flail, the flight lead, the brace before the ground, `gc.hold.brace_tumble` on a tumble landing, `gc.tech_flip` on a recover). `dropped` is that, softer:

| Moment | The body |
| :--- | :--- |
| `drop_start {actor, dur, x, y, z}` | the zip's layers end (the drop is an implicit `zip_end`, reason `dropped`; the read goes empty). The state is treated as airborne like `launched`: the ragdoll's flail starts from the pose he is in (the run or the back-step), at a lower looseness than a launch (`free_t` 0.6 against 0.85: he was hit by a shot, not thrown); the flight lead keeps him feet-down on a steep fall (its steep gate) and head-first only if he is flung sideways at speed. |
| the fall | the existing brace for the ground (`brace_time` before the landing: arms up, chin down, in his own brace shape): it reads as a man who sees the floor coming, which is what Simulation's "hurts nothing" wants |
| `drop_land {actor, x, y, z}` | **no crumple** and no slam fold (`land` kinds `slam` and `skid` are never sent for it); `gc.hold.brace_tumble` as a soft catch at weight 0.35 (`dropped.land_w` in `ground.json`; the tumble's own weight is 0.5 to 0.85 by speed), released at `drop_end` |
| `drop_end {actor, kind, ...}` | `end`: the stance takes over by a 6-tick blend from the catch (no get-up: he is not down); a tech word: the entry named for it in a small table (`dropped.tech` in `ground.json`: `recover` plays `gc.tech_flip`; a word with no entry plays as `end`) |

**Checks and rows.** No new pose, so no new `held_scan` row (`gc.hold.brace_tumble` is already a held pose in the `gc.` family, class rest, and its weight here is lower, not higher) and no `joint_scan` row (its live sample and the all-poses pass already cover the tumble's poses); the check is an `anim_check` test with a hand-staged `dropped` state: 24 ticks of fall with no joint past its limit, no crumple on the landing, a tech word plays its entry, an unknown word falls back to the stance, the zip's layers are off from the first tick, and one tick a frame against two gives the same ragdoll state (the test the ragdoll already has).

**What I need from Simulation** (so the body is not guessing): `f.state == "dropped"` with `f.stateT` counting up from 0 at `drop_start` (the flail fades by it) and `f.dropT` the ticks left; `vx`, `vy`, `spin`, `rot` as a launched fighter has them (spin 0 is fine); the fighter stays `dropped` on the ground between `drop_land` and `drop_end` (what state follows `drop_end`: `free`?); and no `land` or `tumble_end` ground-contact event for a dropped fighter (or it sends them with kind `none`), since those would play a slam or a get-up. **On my side**, about eight places treat `launched` as the airborne state (`flying`, the pose weights, the flight lead, the crumple on a landing, the look and the entry guards): one helper for "launched or dropped", with the landing crumple skipped for `dropped`. Not started: that is the zip slice.

## 11. How the body reads a bowed rush (`Rush.arc`)

Today the zip's travel tilt (`AnimZip.orient`) and the flight lead read the fighter's measured velocity (his position change over the last tick, `_lead_measure`), which follows a bow by itself but lags it by a tick and cannot tell the bow's apex from a straight line at low speed. For a rush with `arc != 0` the body reads the **path's tangent** instead, from the rush's own fields (`arc`, `x0`, `y0`, `dur`, `end`, and `tgt` or `px`, `py` as now):

- `u = 1 - (end - S.T) / dur` is how far along the rush he is (0 to 1).
- The direction of travel is the derivative of the path at `u`: the straight leg from `(x0, y0)` to the aim point, plus the bow's derivative. I will not copy the formula into the render: **please expose it once in the sim** (`SimFighter.rushAt(S, f, u) -> Vector2`, the position along the rush at `u`, bow included), and I take the tangent from `rushAt(u + 0.05) - rushAt(u)`, so the render and the sim cannot disagree about the bow's shape or sign. (If Simulation would rather document the formula, I need: is the bow a vertical offset `arc * 4u(1-u)` as the shots' lob is, or perpendicular to the chord, and which sign is up.)
- The tilt is the same layer as the zip's: the whole body turns along the tangent (the angle from the facing direction when he backs out, as now), clamped to 1.2 rad, gain 0.85, smoothed at 18 a second, with the flight lead's pivot shift, and 0.6 of it with reduced motion. It applies to every bowed rush (a zip's travel or any other), is gated by the rush's own speed (its length over `dur`, not the measured one, so it starts on the first tick), and a rush with `arc == 0` or without the fields keeps today's behaviour exactly (the measured velocity, the zip's travel only).
- The result: a rush that bows up leans up on the way up, is level at the apex and leans down on the way down; a straight line would tilt one way throughout.
- **Check** (`anim_check`, staged rush with an arc): the tilt is positive on the rising half, near 0 at the apex, negative on the falling half; an `arc` of 0 gives the tilt it gives today; one tick a frame against two gives the same tilt.
