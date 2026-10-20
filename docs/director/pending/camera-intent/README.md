# The camera-intent feed, v2 (parked, 2026-10-19)

Owner: Encounter Systems Director. The stream of `../../camera-intent.md` §2, for Camera's directed camera (Orb, 2026-10-19), with Research's recommendations 1, 3, 13 and 16: one plan at each exchange's start.
- **It sits behind `cameraIntent.enabled` (false)** in `data/director/interrupts.json`.
- **It writes cues only.** No draw, no state, so play doesn't move. Off, the golden is byte-identical; on, every checkpoint stays equal and only the fx digest differs (below).
- **Built and read in scratch. Not applied.**

## To build it

`node ci.cjs <root>` from this folder, on main with the grapple G1.
- It copies `files/sim/director/camintent.gd` (`DirCamIntent`) and its `.uid`.
- `--check` reads every anchor and writes nothing; any other option is refused.
- No new golden.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/camintent.gd` | Encounter | New: `DirCamIntent` |
| `sim/director/exchange.gd` | Encounter | A planned exchange's plan, once the alchemist has dressed it |
| `sim/director/brawl.gd` | Encounter | Each blow's plan at its throw; the AI's string as it starts it; the double hit |
| `sim/director/melee.gd` | Encounter | The send's plan, before `doLaunch` |
| `sim/director/launch.gd` | Encounter | `predictFlight` also returns `land` (the touchdown's x) and `slide` (what a knock-back's slide adds); the planner reads neither |
| `sim/director/interrupt.gd` | Encounter | A perfect block marked at the guard press |
| `sim/director/grapple.gd` | Encounter | The clinch's tie-up |
| `data/director/interrupts.json` | Encounter | `cameraIntent.enabled` |
| `tools/schemas/director-interrupts.schema.json` | **Tools** | The same key |

## The cues

All `cue` events of kind `cam_intent`; the fields are the paper's §2.

| `text` | When it goes out | Says |
| :--- | :--- | :--- |
| `plan` | a planned exchange's start; a brawl blow at its throw; the AI's string at its start; the double hit; the clinch's tie-up | the template (`source`), the last beat's tick, the span, the story weight; the plan (beats, contacts, pauses, spans not to cut, launch, set, story) as metadata |
| `launch` | the send | the candidate, its kind, its vector, the predicted touchdown (`x`, `n`), the travel, the flight's ticks; metadata adds the rest point |
| `read` | a perfect block marked at the guard press | the contact it turns, the blocker |

## What it read (main 257a766c, in scratch)

- **Anchors:** `--check` passes on 257a766c.
- **On:** imports clean.
  - The launch trace: the touchdown's tick and x are predicted exactly, hit-stop included (the rest point is an estimate).
  - The lead probe, 10 AI matches of 3 min: 11,094 landed hits, 86.8% told before contact, 30.2% told 8 ticks or more ahead. The AI's strings reach 68% at 8 ticks; a planned exchange's strikes are told for half (102 hits), all 8 or more ahead; the rest are scheduled after its start. A brawl light is told 2 ticks ahead (its press), by design (paper §2).
  - The golden with the feed on: 11 of 11 cases have every checkpoint equal; only the light (fx) digest differs.
- **Off:** the golden is main's, byte for byte. The full gate list on 257a766c is 34 of 35 at 0. Its one red is anim_check's "a blow within reach ends 5.00 units short" (seeds 12345 mix and snappy), the same two failures as clean main. The anchors still check on 09d465c0.

## Probes (`probes/`, run from a copy's root)

- `cit.gd -- <seed> [--launches=6]`: the first launches' plans against the flights that flew.
- `cip2.gd -- <matches> <seed0>`: the lead test; `cip3.gd` splits the hits by damage kind.
