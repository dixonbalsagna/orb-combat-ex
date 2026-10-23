# Sound that carries what the HUD no longer draws (2026-10-18)

Owner: Audio and Music. Answers the EP's brief on Orb's ruling for a minimalist UI ("nothing on, over or between the fighters", `docs/ep/taste.md`): Game Design's `docs/design/minimal-hud.md` (§2 and §4) and Research's `docs/research/readable-speed.md` say which cues sound has to carry now. **Built, tested and parked** (`audio/data/carry_cues.json`, `"enabled": false`; the struggle also needs `tug_cues.json`'s switch), in the family Orb asked for on 2026-10-16: lower, chunkier, soft-edged, nothing metallic and nothing that rings. Every sound is checked by its heard spectrum (`tone_check`, limits in the file). Every number is a first value, and I cannot listen: the dry clips are for Orb's ear.

**To hear it** (`audio/preview/carry/`, no music underneath, mono, made by the real mappers from staged events, 1.4 MB in all):

| Clip | What it plays |
| :--- | :--- |
| `struggle-beat-dry.wav` (7.2 s) | A struggle: the clash thud, then ten pulses with the groove locked to them, plain and sharp surges cracking, a stray's droop, the beams cracking as the point nears an end, the rising bed, and the overwhelming end |
| `grip-dry.wav` (6.9 s) | A clinch: the clasp, the creak on each pulse climbing with the grip, pummels (a step, a sharp one with the tok, a void one that is silent), a stray that is silent, two refusals in the lockout |
| `forms-brake-rush-dry.wav` (17 s) | The ready form's sting; the coil's hum rising in three steps and released; two brakes, fast and slow; two rushes, a long and a short; a perfect block |
| `arena-turn-dry.wav` (9 s) | The ring's turn: a full turn, a small one (2.5 degrees), and a full one again. Quiet under a fight, as it would sit |

## What each ask became

| Ask (minimal-hud §4) | Sound | Cue it reads | State |
| :--- | :--- | :--- | :--- |
| **The struggle's pulse as a beat in the music** | **A groove locked to the pulse.** The kick is the pulse thud (it steps up to four semitones as the point nears an end); a ghost knock (`tug.tock`) 10 ticks later; and when the point is far from the middle two quieter taps (`tug.tick`) at 5 and 15 ticks. At 20 ticks a pulse that is 180 beats a minute, a kick, an off-beat knock and, near an end, sixteenths. It never depends on the music's tempo: the pulses are in ticks, and the music is only ducked 5 dB while it runs | `beam_pulse` | Built, parked |
| **Cracks as a surge lands** | `tug.crack` (low-passed noise and a thock, a few low crumbs): a surge at -5 dB, a sharp one 4 dB louder and a minor third higher | `beam_surge` | Built, parked |
| **Cracks and a rising tone as the point nears a fighter** | The bed (two looped drones: pitch up five semitones, louder, detune from a slow shimmer to a throb), and the beams **crack once each time the point crosses 0.6, 0.8 and 0.9 of the way to an end** (a rising set of pitches), again after it has gone back | `Clash.mid`, or the point in a cue's `x` | Bed built (earlier); cracks built, parked |
| **The clinch's creak** | `grip.creak`: a narrow low groan on each pulse of the grip, **a semitone higher for each point of the catcher's grip**, to five. Who is ahead can be heard, and so can the throw coming | `grapple_pulse` (`amount` the grip) | Built, parked |
| **The clinch starts** | `grip.clasp`: a low thud, hands closing, at the one caught | `grapple_clinch` `start` | Built, parked |
| **The pummel's thud** | `grip.thud`; a sharp one 3 dB louder with the perfect follow-up's tok on top. A void one is silent; a stray is silent | `grapple_pummel` (`step`, `sharp`, `void`), `grapple_stray` | Built, parked |
| **A dull refusal for a lockout press** | `grip.refuse`: a 50 ms dull knock at -20 dB, at the presser. Only for `lockout`; a busy or thrown refusal is silent | `grapple_refused` | Built, parked |
| **The launcher-opening ping** | **Already live** (`ui.launcher`, committed 9ee9d021): a G5 wooden pluck and a thump, the same for both players, with the pad's pulse (Controls). It sounds on `launcher_open`, which is sent when a B would launch, so it is also the lit B's sound | `launcher_open` | **Done** |
| **The perfect's own sound; a chain pitch that climbs** | **Already built, dormant** (`beat_cues.json`): a low wooden tok at the tap, a semitone higher for each count, the follow-up's hit leaning up half a semitone a count, the close 2 dB louder, a droop for a broken chain. Dormant because the perfect cues (`window_open`, `perfect`, `chain_broken`) are **not yet sent** by the sim | `perfect` (`k` the count) | Waits for Encounter's cues |
| **A perfect block's own sound** | `block.perfect`: the guard's thud with a round wooden tone over it, a major third above the tok (Research: "a perfect block rings", and ours rings short and low) | `perfect_block` (sent today; `actor` is the blocker) | Built, parked |
| **The charge's rising tone** | **Already live** for the B (the hum from tick 32, a tremolo that speeds up) and built for the Y (a higher hum); each ends with a low click at full (`charge_full`) | `windup` `charge`, `charge_full` | **Done**; the pad's pulse at full is Controls' |
| **The ready-form sting** | `form.ready`: two low wooden notes a fifth apart (G3 then D4, 0.4 s), a rising "hm-hm", on the unducked bus | `transform_ready` (an event of its own type) | Built, parked |
| **The coil's low hum, rising** | `drone.coil`: a looped low drone (82 Hz with harmonics so small speakers get it), started by the first `form_hold`, moved by each later one (louder and up to four semitones at a coil of 100), stopped by `form_release`. It sits under the music | `form_hold` (`amount` the coil, 0 to 100), `form_release` | Built, parked |
| **The brake's skid** | `brake.skid`: a low scrape that swells and falls, louder and higher for a faster send (5000 a second is "full"), cut when the brake ends | `air_brake` `start` / `end` (`amount` the speed) | Built, parked |
| **Panned rush sounds in place of the incoming chip** | `rush.whoosh`: air parted close by, falling in pitch as it passes, **at the rusher's place** so the stereo position says where he is coming from (the voice pool pans it by his x from the camera); sized to the ticks to his arrival (a short rush is higher) | `rush` (an event of its own type; `n` the arrival) | Built, parked |
| **The ring's turn** (2026-10-23, the shifting arena) | `arena.shift`: the ground shifting under the fight and settling, at Camera's hard cut. A low thump (95 down to 55 Hz), a rumble that dies in about 0.8 s, a few low crumbs, and one smaller thud as it settles at 0.38 s. No whoosh, no sweep, no bright layer. Placed at the pair (not at the pivot, which can be thousands of units off), on Sfx so it sits under the fight; a full 10-degree turn is 2 dB louder and a little deeper (x0.90) than a small one (x1.05 at none). A turn happens at most `maxTurns` a fight, so it can be a presence | `arena_turn` (an event of its own type: `amount` the bearing in degrees, `x` the pivot, `n` the turn, `k` the drift) | Built, parked (the turn itself is off by default) |

Not made, because the pad or the picture does it: the rumble patterns (Controls), and deaf and hard-of-hearing players get the same cues through rumble, poses and the edge caption option (UI's).

## Cue fields the mappers read

- **The beam cues** follow Encounter's agreed list (`docs/director/pending/return/cues.md`): **`x` is the point** (0 at the actor's hands to 1 at the target's) on `beam_struggle`, `beam_pulse`, `beam_surge`, `beam_stray` and `beam_end`. The mapper reads `S.game.clash.mid` first and the cue's `x` only when there is none; `beam_end overwhelmed` names the loser as the target. (The earlier `amount` fallback is kept as a third choice.)
- **The grip cues** follow the grapple window's table (`docs/director/pending/grapple-g1/README.md`): `grapple_clinch` (`start`), `grapple_pulse` (`amount` the grip), `grapple_pummel`, `grapple_stray`, `grapple_refused` (`lockout`, `thrown`, `busy`). `grapple_catch` and `grapple_end` make no sound of their own; the throws' openings are the ordinary `stagger` and `launcher_open`.
- **The forms, brake and rush** are the sim's own events today (`transform_ready`, `form_hold`, `form_release`, `air_brake`, `rush`), so nothing new is needed from the sim for them; they are only sent when the forms and the brake are switched on.

## How it fits

- **The switch:** `audio/data/carry_cues.json` `"enabled": true`. The struggle's groove and cracks also need `tug_cues.json` `"enabled": true`. With both off, audio is byte-for-byte what it was (`host_check`: cue logs identical).
- **Voices:** every class has a cap (the groove and cracks 2 each, the creak 1, the coil 2, the skid 1, the rush 3); information cues have priority 55 to 85 against the hits' 40 to 60, so they are not the ones dropped.
- **No new capability:** the coil uses the looped voice built for the struggle's bed.
- **Checks:** `carry_check` (parked, the groove's timing and pitch steps, the crack thresholds and their re-arming, the grip, the forms, the brake, the rush, the perfect block, determinism, the coil's hum through the real voice pool), `tone_check` (the heard spectra: crack 579 Hz, skid 559, rush 656, creak 600, thud 494, clasp 463, ready sting 239, perfect block 326, coil 208), `tug_check`, `host_check`.

**The slow drift** of the ring's axis between turns (at most 40 degrees in all, spread over whole turns) gets no bed: it is not motion anyone could hear, and a drone for it would only be noise under the fight. The turn's cut is the only sound.

## For Orb and the EP to decide

1. **Whether the groove is right.** A drum figure inside a struggle can be too much (Orb's "too much" about the perfect's note). The first thing to try if it is: only the off-beat knock, no sixteenths (`dense_from` above 1 in the data).
2. **Deaf and hard-of-hearing players** are served by Controls' rumble and the poses; if the struggle's beat should also have a visual option, that is UI's edge strip, off by default (`readable-speed.md` row 11).
3. **Switching it on** is one word in two data files; I would switch the struggle's set on together with Encounter's struggle window.

## Sources and licence

Every sound is synthesised by our own code from the recipes in `audio/data/impacts.json` (and `carry_cues.json` for the coil's drone): no sample, no recording, no third-party file or code, no audio model. Licence: the repo's, as it settles (`audio/README.md`, rows AUD-GEN-001, AUD-GEN-007, AUD-GEN-008 and AUD-PREV-008).
