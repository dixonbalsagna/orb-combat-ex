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
