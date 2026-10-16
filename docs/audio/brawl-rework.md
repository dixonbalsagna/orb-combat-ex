# The brawl's sounds, lower and chunkier (rework of 2026-10-16)

Owner: Audio and Music. Answers the EP's brief on Orb's listen (`docs/ep/vision.md`, "Orb answers homework 4"). Orb on the hits: "a little too high pitched, hits sounded a little 'tinny'". On the perfect follow-up: the rising note is "too much", the opponent's chain "not needed", "needed to sound 'chunkier', kind of sounds metallic and high pitched".

**To hear it** (all in `audio/preview/`, the originals untouched beside them):

| New | Old | What it is |
| :--- | :--- | :--- |
| `brawl-demo-v2.wav` | `brawl-demo.wav` | The same 10 seconds of seed 12345 on the same sim (tick 2105 of 2e0f3b2c), over the same music loop |
| `perfect-chain-v2.wav` | `perfect-chain.wav` | The same staged events: a chain of three, a broken one, a link, the opponent's chain |
| `brawl-demo-v2-dry.wav`, `perfect-chain-v2-dry.wav` | | The same two with **no music underneath**. The loop under the demos is our synthetic stand-in riff (bright saws) and may itself add to "tinny"; the dry clips are the hits alone |

## Why the hits sounded tinny

Measured with `audio/tools/tone_check.gd`. A hit's raw spectrum is mostly low body, which a laptop or phone speaker does not play (it cuts below about 180 Hz). What is heard is the part above that, weighted by the ear, and there the old hits were bright:

- **Bright noise bursts** (a 2.4 kHz high-pass, a 3.6 kHz band) as the "crack", loud for the first 10 to 30 ms.
- **Grains layers** (short rings scattered between 900 and 5000 Hz) on the medium, heavy, double and blast: little tuned rings, which is what "metallic" is.
- **Hard saturation** (drive 1.3 to 2.6), which makes upper harmonics out of the body tone.
- **Bodies under 180 Hz** that small speakers drop, leaving only the bright parts.
- **Pitch**: hits were played 15% sharp for a small hit (size scaling clamped at 1.15), a flurry climbed up to 3 semitones, and a guard on a light was 25% sharp.

## What changed

- **Recipes** (`audio/data/impacts.json`): a **thock** of 150 to 400 Hz that small speakers do play, a slap of band-passed noise starting at 800 to 1400 Hz instead of a crack at 2.4 to 3.6 kHz, only a tiny click above it, the grains turned into low rubble (150 to 700 Hz), and half the drive. Light, lite, medium, grind, heavy, guard, double, whiff, bolt, blast, and the two full-charge ticks (less ring: 130 and 330 Hz instead of 520 and 1170).
- **Pitch** (`audio/data/brawl_cues.json`): hits at most at their written pitch (0.78 to 1.0 instead of 0.85 to 1.15); a flurry climbs 0.15 semitone a blow to 1.5 instead of 0.33 to 3; a guard on a light 1.1 instead of 1.25.
- **The perfect follow-up** (`audio/data/beat_cues.json`): **no note, no chord, no shimmer, no second voicing.** One low wooden *tok* at the tap (420 to 300 Hz, 70 ms, 8 dB under a light hit), a semitone higher for each count of the chain; the follow-up's own hit leans up half a semitone a count (to 1.5) and the close is 2 dB louder, with the launcher's ping marking the opening as before. One chain sound for both sides: the AI's perfect and a player's make the same cues (tested). The droop for a broken chain and the plain light's tick are lowered the same way (320 Hz and 900 Hz, no bright partials).

## Measured: how it sounds to a small speaker

`tone_check`: the centroid of the heard spectrum (A-weighted, 180 Hz low cut) over a hit's first 64 ms, before and after, and the share of the heard energy over 2 kHz after.

| Hit | Before | After | Over 2 kHz after |
| :--- | ---: | ---: | ---: |
| Light | 1168 Hz | **472** | 3.9% |
| Light, lite | 902 | **417** | 3.3% |
| Medium | 919 | **566** | 4.5% |
| Medium, grind | 903 | **565** | 3.9% |
| Heavy | 1578 | **754** | 7.5% |
| Guard | 1119 | **663** | 6.7% |
| Double | 2108 | **705** | 5.6% |
| Whiff | 2387 | 1730 | 25% |
| Bolt | 1890 | 1297 | 20% |
| Blast | 2289 | 1240 | 18% |

The limits are in `tone_check` and fail the check if a recipe drifts back toward tin. The whiff, bolt and blast are air and electricity, so they stay brighter than the fists.

## What I could not judge

- I cannot listen. These are measurements of a small speaker's view of each sound and checks that the events drive the same cues; **whether it now sounds chunky is Orb's ear**. If it is still thin, the next lever is the thock's weight (the 300 to 380 Hz layers) and a gentler slap; if it is now dull, the click's gain (0.1 to 0.2) comes back first.
- The music loop under the demos is not the music. Real music from Suno will change the mix; the notes of the old version sat where guitars do, which is one more reason there are none now.

## Sources and licence

Every sound is synthesised at run time by our own code (`audio/synth/`) from the recipes above: no sample, no recording, no third-party file or code, no audio model. The recipes are original numbers. Licence: as the repo's licences settle (`audio/README.md`, rows AUD-GEN-001, AUD-GEN-007 and AUD-PREV-006; Legal writes the log). Selection is deterministic: the cue chooser draws only from the audio stream seeded from the match seed, reads the sim and writes nothing to it (`host_check` confirms the sim hash is unchanged by audio).
