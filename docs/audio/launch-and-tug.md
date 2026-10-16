# The launch opening and the beam struggle, by ear (paper, 2026-10-16)

Owner: Audio and Music. Answers the EP's brief on the eleventh round (`docs/design/brawl-second-pass.md` §14 item 1 and 2; the beam struggle in `docs/design/rule-of-cool.md` §2 and Encounter's park `docs/director/pending/beam-struggle/README.md`). **Paper only.** Nothing in `audio/` is changed; the recipes are proposals, and every number is a first value. The family is the one Orb asked for on 2026-10-16: lower, chunkier, short rings, nothing metallic (`brawl-rework.md`).

**To hear a sketch:** `docs/audio/proposed/launch-and-tug-sketch.wav` (13.7 s, over the 180 BPM stand-in loop): the launcher's ping as it is now, then the proposed one; a beam struggle that ends overwhelmed; a struggle that ends on time and detonates. It is mixed offline in a scratch script, because the struggle's bed needs a runtime capability that does not exist yet (§2.5). Recipes: `docs/audio/proposed/launch-and-tug-recipes.json`.

## 1. The launch opens: the ping and the pad's pulse

**What is already there.** `launcher_open` (sent only when a launch is ready) makes `ui.launcher`: one fixed pitched ping at the staggered fighter, heard by both players, on the unducked Alert bus, ducking the impacts 3 dB and the music 4 dB; `launcher_close` text `used` cuts it; an opening that will not launch makes the dull knock (`launcher_rest`). Nothing about the cue changes for the wider window (10 ticks before the close until 24 after) or the 30 s rest: the ping still means "an opening, and B launches now".

**What the eleventh round asks for.** "The opening is unmistakable: head snaps back, arms fly open, a ring on his chest, the ping sounds, and the pad pulses." Animation and VFX show; Audio's two parts are the ping and, with Controls, the pulse.

### 1.1 The ping in the new family

The ping is the one sound that has to cut through a flurry and the music, so it keeps a fixed pitch and a clean shape. But it was a 1100 Hz sine ring with a 3 kHz hiss at its start, and Orb called the brawl "tinny" and "metallic". The proposal, `ui.launcher.v2`:

- a **wooden pluck at G5 (784 Hz)** over its octave below (392 Hz), with only a faint second harmonic;
- a **short thump** under it (150 down to 100 Hz, 100 ms), so the opening has a body: the head snap you can hear;
- a tiny click, no hiss, no ring above 1.3 kHz.

| | Old | v2 |
| :--- | ---: | ---: |
| Heard centroid (A-weighted, 180 Hz low cut) | 1303 Hz, 15.6% over 2 kHz | **738 Hz, 0% over 2 kHz** |
| Length | 0.26 s | 0.27 s |
| Over the stand-in music, its first 150 ms in 400-3000 Hz, at gain -2 dB | 5.9 dB (9.9 with the 4 dB duck) | 2.7 dB (6.7 with the duck) |

**The price is audibility:** v2 is 3.2 dB less above the music in the band the music lives in. Take it back with level, not pitch: **raise its gain from -2 dB to +1 dB** (it is on the Alert bus, so it is neither ducked nor clipped; it stays 3 dB under full scale in the recipe's peak). That gives v2 the old ping's 5.9 and 9.9 dB. These are against the synthetic stand-in loop, so they must be redone when Suno's music arrives; if the music is dense in 700 to 900 Hz, the duck on the music goes from -4 to -6 dB before the ping goes sharper.

**One sound, still.** The same pitch, level and shape every time, no random spread, for both fighters (the EP's ruling). The launcher of either side makes it at the staggered fighter's position.

### 1.2 The gauge and the readiness: silent, by design

The four-pip gauge, the full-gauge flash, the lit B, the LAUNCH or RESTING chip and the rest's ring are UI's, and the rest's ring "fills" without a flash or pulse (§14 twelfth round item 4). **Audio adds nothing to any of them:** a sound at "gauge full" would be the busy "too much" Orb has just named, and the rest becoming ready is meant to be quiet. The one sound for the whole thing is the ping when the opening exists, and the knock when it exists and will not launch.

(If a playtest shows newcomers still missing the gauge, the lever is one tiny low *tok* of the perfect family at the full-gauge moment, a quarter of the ping's level. It is not proposed.)

### 1.3 The pad's pulse

UI already raises `haptic_requested(slot, "launch_open")`; Controls plays it. Audio's part is to say what shape matches the ping so the two read as one event on the same tick.

| | Strong motor | Weak motor | Length |
| :--- | ---: | ---: | ---: |
| First strike (the pluck and the thump) | 0.7 | 0.3 | 80 ms |
| After a 10 ms gap, the ring | 0 | 0.2 | 60 ms |

That is two calls to `Input.start_joy_vibration(device, weak, strong, duration)`: `(0.3, 0.7, 0.08)` on the open's tick, `(0.2, 0.0, 0.06)` 90 ms later. On a phone: one 25 ms pulse, a 60 ms gap, one 10 ms pulse. Rules that stand from `docs/controls/platform-plan.md` and `input-scheme.md`: **only the fighter who may launch feels it** (the defender hears the ping and feels nothing, so the pad says whose move it is), and **it never carries information alone** (the ping and the ring say the same).

## 2. The beam struggle: a sound that rises as the point nears a fighter

**What Game Design asks.** "The pulse is a beat the music and the pad follow. The sound rises as the point nears either fighter" (`rule-of-cool.md` §2). The pulse comes every 20 ticks, which is 3 a second. A surge is a press within 4 ticks of a pulse; within 1 tick it is sharp. A stray moves nothing and voids that fighter's next surge. The struggle ends when the point reaches a fighter (overwhelmed), or on time (`time`, or `detonate` if the point is within 10% of the middle).

**The principle, as for the perfect follow-up and the pulse everywhere in the brawl: a transient is "now".** The pulse is a low *tok-thud* on the pulse's own tick, the same every time; the player's surge lands against it, not against the music. A press that is on the beat is confirmed by its own low *whump*. Nothing is voiced per side.

### 2.1 The five cues and what each makes

| Cue (Encounter's park) | The sound | Notes |
| :--- | :--- | :--- |
| `beam_struggle` text `start` (`n` the latest end) | **`tug.lock`**: a low clash thud (80 down to 45 Hz, 0.35 s, with a rumble under it), played with the existing `impact.heavy` at pitch 0.8; the bed fades in over 150 ms; the music ducks 5 dB for the struggle's length | Heard by both players, at the point |
| `beam_pulse` (`k` the pulse, `n` its tick) | **`tug.pulse`**: a low thud with a faint knock (95 down to 60 Hz, 90 ms). Fixed, except that its pitch steps **up a semitone per quarter of the way to either end** (0 to +4 semitones) so the beat itself tightens | The beat. 180 BPM exactly, but the music is not locked to the ticks, so the pulse has its own sound and is not meant to sit on the music's grid |
| `beam_surge` text `surge` | **`tug.surge`**: a rising low whump (140 up to 230 Hz, 140 ms, with a soft slap), at the presser | Both fighters' surges sound alike; where it comes from is where it is |
| `beam_surge` text `sharp` | the same, 1.5 dB louder, **plus the perfect follow-up's tok** a whole tone up | The reward for the exact press is the same small wooden confirmation the player already knows from the perfect |
| `beam_stray` | **the droop** (`perfect.break`, quiet, falling): "quiet, not a buzzer". Rate-limited to one a pulse per fighter, so a masher hears three droops a second at most, never a buzz | A stray costs only the next surge now, so its sound is a soft "not that" |
| `beam_end` text `overwhelmed` (`x` the point) | the bed **falls** an octave over 0.35 s and fades; `tug.fall` (220 down to 55 Hz) and the existing `energy.blast` at pitch 0.9 as the beam lands on him | The loser |
| `beam_end` text `detonate` | the bed cuts in 60 ms; the existing `impact.double` and `energy.blast` at the point | Both beams meet in a blast |
| `beam_end` text `time` | the bed fades over 0.3 s; one `impact.medium` at the side the point is on | Half a beam: no launch |

### 2.2 The bed: two drones that beat, and tighten

The continuous part is two low drones a hair apart, so they **beat**, as the sound direction already describes for a clash ("two tones that beat against each other"). All four things below follow `d`, how far the point is from the middle (0 even, 1 at a fighter's hands):

| | Even (d = 0) | At a fighter (d = 1) |
| :--- | ---: | ---: |
| Pitch | 98 Hz (G2) | 131 Hz (a fourth up, 5 semitones) |
| Detune between the two drones | 0.3% (a beat of 0.3 Hz: a slow shimmer) | 2.3% (a beat of 3 Hz: a throb) |
| Level | about -21 dB | about -10 dB |
| Harmonics (2nd, 3rd) | 0.15, 0.05 | 0.50, 0.30 |

It stays low and round at every point (a few harmonics, no noise, nothing over about 400 Hz fundamental), so it rises in **tension** and not in shrillness. The pitch change is gradual; a surge moves the point by 10 or 15%, so the bed takes a small step with it. It is placed at the meeting point, between the two fighters by `mid`, so the sound sits where the beams meet.

**Which way the point is going is not in the bed,** only how near the end it is; that is the brief ("rises as the point nears either fighter") and avoids a second voice per side. The player knows from the picture and from the surge sounds who is pushing.

### 2.3 What this does to the mix

- The music ducks 5 dB for the whole struggle (200 ms ramps) so the pulse and the bed read; it comes back after the end.
- Voice classes: the bed holds two voices, one class (priority 85); the pulse and surges are cap 2; the strays cap 1; nothing else of the brawl is dropped by them. A struggle has no melee hits in it (the fighters are locked), so the density is low.
- Measured with `tone_check`'s heard spectrum: pulse 214 Hz, surge 291 Hz, fall 262 Hz, lock 770 Hz (the ping is 738), every one inside the family's limits and under the old ping's 1303 Hz.

### 2.4 The pad

Rumble repeats what the picture and the sound already say and carries nothing alone (`platform-plan.md`): **8 ms on each pulse** for both players, **15 ms on a player's own surge**, and on the end one 40 ms pulse for the loser. So a player who cannot hear the beat can still feel it, and a player who can hear it feels it too.

### 2.5 What has to be built, and what it needs

1. **A live voice in `AudioVoices`:** a looped sound whose gain and pitch can be updated for a group, `update_group(group, gain_db, pitch, ramp_ms)`. Today's voices are one-shots. The bed is two such voices (the two drones) plus recipes of 2 s that loop without a click. This is the one new capability, about 40 lines, and it also serves the charge hums later.
2. **A mapper for the five cues** in `audio_brawl.gd`, as the perfect follow-up's: data in `beat_cues.json` (or a file of its own), tests with staged cues, and no randomness (the chooser is the seeded stream; the bed is a function of the cue stream).
3. **The point:** from the cues (below), not from the sim.

Tests: a staged struggle that checks the pulse's pitch steps, the bed's level and pitch at d of 0, 0.5 and 1, the end's fade for each of the three texts, the stray rate limit under a mash, voice caps, and the sketch's determinism (`host_check` gains a struggle once the park is on main).

## 3. What I need from Encounter, and what I read

| Cue | Fields I read | Why |
| :--- | :--- | :--- |
| `beam_struggle` start | `actor` the firer (the point is 0 at his hands), `target` the other, `n` the latest end | The sides and the meeting point's position |
| `beam_pulse` | `k`, `n`, and **`amount` the point (0 to 1) after the last move** | The pulse's pitch and the bed |
| `beam_surge` | `actor`, `text`, and **`amount` the point after it** | The step in the bed |
| `beam_stray` | `actor` | The droop |
| `beam_end` | `text`, `x` the point's position, and **`amount` the point** | The ending |

`amount` is a request: if the cue carries the point, Audio never reads `S.game.clash.mid` (which is -1 until the grants are applied) and the sound follows the event stream alone, like every other cue. If it is easier to leave it off, I can read `S.game.clash.mid` each tick as UI does; it is read-only.

## 4. Order, and what stays dormant

1. Nothing of this is in `audio/` yet, by the brief. When the EP says go: the recipes into `impacts.json`, the ping's `ui.launcher.v2` in place of `ui.launcher` (a data change, plus the gain), the live voice, the mapper, the tests.
2. The ping change needs nothing from the sim and could land first, alone.
3. The struggle's sounds are dormant until the beam-struggle park is applied (its five cues do not exist on main); the mapper does nothing without them.

## 5. What I could not judge

- I cannot listen. The sketch is the proposal made audible, and whether the bed's tension reads, whether the beat is easy to press with, and whether the new ping is as findable as the old over real music are Orb's and a playtest's to say.
- The bed is mixed offline in the sketch; the runtime version will be a pair of looped voices with ramped gain and pitch, and will be a little less smooth than a per-sample drone.
- The ping's audibility numbers are against the stand-in loop, not the music Suno will make.

## 6. Sources and licence

Every sound here is synthesised by our own code from the recipes in `proposed/launch-and-tug-recipes.json` (the pluck, thumps, whumps and the drones), and the sketch reuses the existing `impact.heavy`, `impact.double`, `energy.blast`, `perfect.tok` and `perfect.break`. No sample, no recording, no third-party file or code, no audio model. Licence: the repo's, as it settles (`audio/README.md`, rows AUD-GEN-001 and AUD-GEN-007). Nothing here uses randomness at run time beyond the seeded audio stream.
