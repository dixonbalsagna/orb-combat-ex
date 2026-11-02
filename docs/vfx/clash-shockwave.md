# The beam clash's shockwave at the meeting point, growing through the struggle (a sketch, VFX, 2026-11-02)

The ask (through the EP), from Orb on Camera's tight-then-pull-back GIF: "in my mind, the center where the beams collide would have the biggest shockwave, possibly causing a crater underneath." Sketch the shockwave at the meeting point growing through the struggle, inside the flash and stacking limits, with no screen-wide wash. Nothing is built. The picture is `docs/vfx/img/clash-shockwave/shockwave-contact-grow-release-crater.png` (shapes only). Game Design rules the numbers; World's crater goes through the EP.

**A note on the rows:** the EP named RL-232 and RL-233. RL-233, as I read the log, screens the megastructure landmarks, which this is not. The limits used here are RL-232's catastrophe-class light and dust rule (one event, a rise of at least 0.3 s, a fall of at least 1 s, a calm form, day and night, dust a local cloud and never a wash that darkens the sky, no ceremony at the collapse), the flash registry, and the stacking rule (at most two of the seven marks; the ground bundle is one). If another row was meant, tell me and I will re-read against it.

## What the clash already does (so the sketch only adds the ground)
The meeting point is a disc of rippling air, 165 units across at an even low-tier clash up to 360 at the most power, with pressure rings, each side's colours and front, and the pair's mix colour where they meet (`docs/vfx/clash-look.md`; the park `docs/vfx/pending/clash-look/`). The struggle model's **knot** swells it slowly over the first 1.8 s and each **surge** adds a ring and rays for 0.55 s, at most one every 30 ticks. All of it is air and rays: nothing touches the ground, and the disc is never white. The **duel's wave** (`docs/vfx/multi-fight-plan.md`) already does what a ground wave needs: a thin flat ring running out along the ground to 4 body heights over 12 ticks, the glass of every tower inside it blowing out nearest first (`react.on_wave`), and a crack web on the ground. So the pieces exist; they are not tied to the clash's point.

## The sketch: four beats (the picture)
1. **Contact.** The beams meet: today's air disc, small. Nothing on the ground.
2. **The struggle grows it.** As the knot swells and each surge lands, the point sends a thin ring out through the air, and a **flat ring on the ground beneath it** (the arrive ring's shape, in the pair's mix colour) widens with the knot, with a **low dust skirt** along the ground that builds a little each surge. The ground ring's radius follows the knot (a smoothstep from the first beat's size to the cap); each surge adds one ring at most.
3. **The release: the biggest.** When the struggle ends (a win, a draw, a break), the energy goes in one wave, once: a wide ground ring (the whole struggle's growth in one run out), the glass of the towers inside it blown out and a few tiles shed (the duel wave's pieces, scaled), and a local dust dome that rises and settles. **One rise, one fall.** The beams' ends and the disc do what the clash already does at its resolve.
4. **Beneath the point.** If the energy spent and the point's height say so, a **crater** opens under the meeting point, its rim thrown out and the dust settling. That is World's crater record; VFX draws only its ejecta and cracks, as for any crater. The sky is untouched.

## Inside the limits
- **Flash and light.** The growth beats (2) are rings and dust: no brightness change beyond the disc the clash already has, steady in rate (a ring at most once in 2 s, thin and in the pair's mix colour, rising over at least 6 ticks, as RL-240 set for the power-up ring). The release (3) is **one catastrophe-class event** in the registry: its light, if any, rises over at least 0.3 s and falls over at least 1 s, with a calm form under Reduce flashing (the ring's strength 0.82, the dust fewer, no second ring), read in day and night. No white or gold or red anywhere (the mix colour is a hue average and is never white); no screen-wide wash: the dust is a local cloud (a few body heights) and the sky never darkens; the screen-reading air stays the clash's own disc (its cap, 360 units) and is not enlarged for the release.
- **Stacking (RL-232, k01).** The ground bundle (the ring, the dust, the cracks, the crater's ejecta) is one mark. The air disc and the beams are not marks. So the moment holds one mark plus the clash's own look, under two.
- **No ceremony.** No slow motion, zoom, held shot, sting, score popup or line at the release or the crater (RL-232's rule for the fall; I keep to it for this). Camera's own framing is Camera's.
- **People.** Nothing in or beneath it is a person drawn dying; the toll is the existing scalar. If the crater takes buildings, it is the fall rule: no AI, picker or landing score reads the point's surroundings, and QA re-reads the civilian band at the top tier with it on.

## What I need, and from whom (for the EP to route)
| Need | From | What |
|---|---|---|
| **The crater under the meeting point** | World, Game Design | A crater record at the ground below the point when the struggle ends: its radius and depth from the energy the two beams spent, and a rule for when the point is too high above the ground to dig one (a height limit). Whatever stands in the bowl falls, by the fall rule, with RL-232's limits |
| **The end of the struggle as an event** | Encounter | `Clash.mid` (the point) is parked, so none of this shows until it lands. At the end an event with the point (x, y, z), the total energy spent and the outcome (win, draw, break), so the release has one tick to be drawn on; while it runs, the knot and surges (already read) |
| **The numbers** | Game Design | See below |

## Numbers for Game Design to rule (my proposal, all data)
| What | Proposal | Why |
|---|---|---|
| Ground ring's radius through the struggle | from 1 body height at contact to **3 at the cap**, following the knot | Reads as growing, not as a flash; the duel wave runs to 4 |
| The release's wave radius | **4 body heights at the lowest tier up to 12 at the top**, one run over about 0.4 s | The biggest wave in the game, still a local ring |
| Towers' glass and tiles | inside the release's radius only | The duel wave's rule, scaled |
| Dust dome | local: **at most 6 body heights** across at the top; rises over 0.5 s, falls over 2 s | RL-232's local cloud |
| Rings during the struggle | **at most one in 2 s**, thin, 6 ticks to rise | The power-up ring's limits, the strictest in the log |
| Crater radius | the power scale's `160 x sqrt(E)` with E the energy the two beams spent, times a clash factor **k (Game Design: 0.5 to 1)** | One path with every other crater; "nothing counted twice" |
| Crater only if | the point is within **a few body heights** of the ground, or the struggle was held near it for the last second | A point high in the air digs nothing; a shockwave in the air is the ring across the beams |

## Cost and what is not built
Reuses the pool's rings, puffs and chunks, `react.on_wave` and the crack sets; a new cue-driven piece of about 80 lines in `beam_struggle.gd` and `earth.gd`, a few data numbers and one check, once the struggle's end event exists. Cheap. **Not built**, and nothing shows in the game until Encounter's struggle lands (`Clash.mid` is -1 today).

## For Orb
Pick or change the picture's idea: a ground ring that grows with the struggle and one big wave at the release, with the crater only when World's rule allows. The alternative (nothing until the release) is the picture without beat 2.
