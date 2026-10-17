# The catastrophe tier's sound (paper, 2026-10-16)

Owner: Audio and Music. Answers the EP's brief on the run mode's tier 5 (`docs/design/run-mode.md` §3.1 and §3.2 as amended, Legal's RL-145 in `docs/legal/catastrophe-and-city-screen.md`). **Paper only; nothing in `audio/` is changed.** Every number is a first value. The family is the one Orb asked for on 2026-10-16: lower, chunkier, soft-edged, nothing metallic, nothing that rings (`brawl-rework.md`).

**To hear a sketch:** `docs/audio/proposed/catastrophe-sketch.wav` (39.5 s, over the 180 BPM stand-in loop, with the music ducked and darkened where the design says). Recipes: `docs/audio/proposed/catastrophe-recipes.json`. It is a staged timeline, mixed offline:

| Time | What it shows |
| ---: | :--- |
| 0.5 s | The tremor |
| 5.5 s | The crust breach: the boring, then magma plops and steam, then rock ticking as it cools (to 14.3 s) |
| 15.0 s | The blast cloud, near: 8 ticks of hush before it, then the whump, the roar, the falling ash |
| 22.2 s | The same blast, far: it arrives 1.2 s late, duller and softer |
| 24.2 s | The exosphere: the music and the fists go dull, a hum, six small pops far below, a roar of the falling meteor, then its boom at 33.4 s |
| 33 s | The ash-dark: the music stays but darker, and the hush stays |

## 1. Rules for the whole tier

- **Legal c07, always "a blast cloud".** No siren, no countdown, no alarm. In sound that means: **nothing rhythmic or pulsing leads into the blast** (the charge before it is one continuous swell with no regular ticks); **no pitch that sweeps up and down like a wail**; **no descending whistle** (a falling whistle is a bomb-drop trope, so the meteor's approach is a growing low roar and nothing else); the only thing before the blast is **8 ticks of hush**, which is the existing "silence before a huge hit" rule (`rule-of-cool.md` rule 4) and is not a warning. Captions say "[blast cloud]", never anything else.
- **No voices.** No screams and no crowd noise at a death: the people lost show in the world getting quieter (the ash-dark, below), not in a sound of dying. The casualty presentation is UI's and Legal's.
- **One catastrophe sound at a time.** The registry's rule for light (c01: at most one catastrophe light event every 2 s) holds for sound too: the tremor, the breach's start, the blast and the meteor's boom are class `cat.big`, cap 1, and a second one is held back until 2 s after the first.
- **A calm form with the light's.** When *Reduce flashing* is on, every catastrophe sound is 6 dB lower in its peak and its onset is at least 80 ms (not a hit but a swell). The sound never carries information alone (UI and VFX show the same).
- **The loudest moment is chunky, not loud.** The blast peaks at the same -3 dBFS as any other sound; it feels biggest by being low (the audible 70 to 200 Hz, not the sub that small speakers drop), by everything else getting out of its way (below), and by the length of its tail.
- **Deterministic.** Every choice is a function of the cue stream and the seeded audio stream; the plops of the magma are drawn from it, so a replay sounds the same.

## 2. The five things

### 2.1 The tremor

`cat.tremor`: a swell of low rumble that heaves (a 2.5 Hz wobble) over 3.6 s, a sub tone whose harmonics sit in the audible 90 to 200 Hz, **two timber groans** (a narrow noise sliding down 210 to 125 Hz and 170 to 110 Hz, the towers swaying), and a patter of low rubble (150 to 480 Hz). No hiss, no crack, no glow-like tone. It starts on the tremor cue and its end hands over to the tier-5 form's ready tick (UI's, the one the form already has). It never repeats faster than the 2 s rule.

### 2.2 The crust breach and the magma

- **The boring:** `cat.breach.bore`, a grinding of rock (a 320 Hz low-passed rumble with a 23 Hz judder, a low-passed noise, a 72 Hz tone with harmonics), 3.6 s, sounding at the head of the cut and **following it** (the head moves, so the sound moves with its position).
- **The magma:** slow low **plops** (110 down to 55 Hz, 100 ms), irregular, **at most 2 a second and never on a pattern** (Legal c03 asks the same of the picture: a low-contrast change at 2 Hz or slower, irregular), plus a soft **steam** (a low band-passed breath, -22 dB) while it flows.
- **Cooling:** as the magma cools into rock, sparse dull **ticks** (260 Hz, 14 ms) as the rock contracts, a few a second and then fewer.
- **A fighter in it** (legs 4, core 2, arms 1 a second): a looped low sizzle on his body while he stands in it (the looped voice of the beam struggle, `launch-and-tug.md` §2.5), 6 dB under the bed; it stops when he leaves.
- **A tower in the sweep:** the existing building-crack sounds, with the warning (`buildings.md` §6.2) as a low groan before it falls, the same groan as the tremor's.

### 2.3 The blast cloud, near and far

- **Near:** `cat.blast.core`: a **soft-edged whump** (a 4 ms attack, not a crack): a band of noise falling 650 to 250 Hz, a 70 Hz tone down to 28 with strong harmonics, a 200 Hz thock, a low rumble tail, and low rubble. Then **`cat.blast.roar`**, 8 s of low roar falling slowly in pitch (the cloud rising, then the stem and cap), which starts 150 ms after the whump. Then **ash falling**: a soft low hush.
- **Out of the way:** 8 ticks before the blast lands everything except the Alert bus drops 14 dB for 133 ms (rule 4's silence), then the music returns to 6 dB down for the roar and comes up over the next seconds. The pad takes a long, low rumble for 1.5 s, never a pulse.
- **Far:** the sound is late, dull and soft by distance. First values, with `d` the distance in world units from the camera and "far" meaning more than 30 body heights (rule 6 of `rule-of-cool.md`): the **delay** is `min(1.5 s, d / 2400 per second)`; the **low-pass** is `max(180 Hz, 2400 / (1 + d / 800))`; the **level** is `-3 - 6 * log2(1 + d / 600)` dB, floored at -24. A far blast is the whump low-passed to about 200 Hz, with the roar at -12 dB behind it: the sketch's second blast.
- **The planet's sky answers:** nothing in sound. The darkening is the ash (2.5), over minutes.

### 2.4 The exosphere

- **Thin air.** Above the band's lower edge, sounds lose their top: all Sfx and Music pass through a low-pass whose cutoff falls from 8 kHz at the lower edge to about 650 Hz at the top (`a` the position in the band from 0 to 1: `cutoff = 8000 * (650 / 8000)^a`), and levels fall up to 6 dB. The fists still land, but dull; a flight **hum** (a low tone, 85 Hz) is the body's own sound; the pad carries more of the weight here (Controls' rumble is the "felt" part).
- **The impacts far below** (Legal c04): each missed shot lands about 90 ticks later as a tier-5 impact in the world below, small on the screen. Its sound is **`cat.exo.pop`**, a small low pop (140 down to 70 Hz) low-passed to about 800 Hz at -8 dB, with its pitch drawn from the seeded stream within ±12% so a run of them never forms a regular pattern ("never in step with each other"). Class `cat.far`, cap 3, low priority. Impacts are already spaced by the sim (at most 2 a second in any screen window), so the sound adds no density of its own. If the picture-in-picture shows a city hit, its pop is 3 dB louder than the others (the player is looking at it).
- **The meteor:** the sent fighter lands as the largest impact in the game. Its sound is a low roar that grows over the fall (no whistle) and then `cat.blast.core` at 0.8 pitch, longer, low-passed to 500 Hz as it is far below. It is the one big exosphere sound, class `cat.big`.
- **Coming down:** the low-pass opens over 0.5 s as the fight lands (the music in the sketch brightens at 33.5 s).

### 2.5 The ash-dark soundscape

The world's `ash` (0 to 1, going up by 0.6 over at least 120 s after a blast) sets the sound of the sky: a low-pass on the Sfx and Music buses that slides from open to about 5 kHz at 1, a **hush bed** (`cat.ash.hush`: a very low breath, -24 dB, coming up with the ash to -10 dB), and nothing else. It must obey the sky's slew limit (c05): no change faster than the ash itself changes, so it is minutes long. Ash has no rule effect, and so it has none in sound: it never hides a cue (the Alert bus is not filtered, and a cue that carries information is never made quieter than its class). The sketch's last section shows it.

## 3. Mix and voices

| | Class | Cap | Notes |
| :--- | :--- | ---: | :--- |
| Tremor, breach start, blast, meteor boom | `cat.big` | 1 | 2 s apart at least; highest priority below the Alert bus |
| The bore and the roar | `cat.bed` | 2 | Looped or long; they follow the head or the cloud |
| Magma plops, rock ticks | `cat.magma` | 3 | Low priority; drawn from the seeded stream |
| Far impacts | `cat.far` | 3 | Lowest priority |
| The hush bed and the hum | `cat.amb` | 2 | Looped, level set by `ash` and altitude |

Measured with `tone_check`'s heard spectrum over a sound's first 64 ms (slow swells are quiet then, so the table shows their attack, not their body): tremor 596 Hz, bore 648, plop 337, tick 681, blast core 679, roar 743, ash hush 708, far pop 289, hum 159; only the steam is brighter (1617 Hz, -22 dB, a breath). Every one is below the old hits' 1168 to 2108 Hz.

## 4. Cues I need, and what I read

| What | Fields | Why |
| :--- | :--- | :--- |
| `tremor` | `n` the tick it ends | The tremor's swell, and the 2 s rule |
| `breach` start, `breach` head, `breach` end | `x` the head's place, `n` | The bore follows the head (a looped voice, updated) |
| `magma` | `x`, `amount` its size | The plops and the steam's level; `cooling` text when it begins to set |
| `blast_cloud` | `x`, `y`, `amount` the size (3000), `n` the tick it lands | The hush 8 ticks before, the whump, the roar, the distance |
| `exo` text `enter` or `leave`, or the fighters' altitude | `y` | The thin air. I would rather read the fighters' `y` against the band's edges, which Simulation gives as data |
| `exo_impact` | `x`, `amount` its size | The pops. Or the shot's landing event, if it is already a `crater` event with `cause` `impact` far below |
| `meteor` | `x`, `n` the landing tick | The growing roar and the boom |
| the world's `ash` | 0 to 1 | The sky's low-pass and the hush. Read-only, like Clash.mid |

None of these exist yet; this is the list I would ask for.

## 5. Build order

1. The recipes into `impacts.json`, and the ash's slow low-pass (a bus effect whose cutoff is set at run time): data and a few lines, no new cue.
2. The altitude filter and the far-blast delay and distance rules (they use cues that already carry x and y).
3. The mapper for the new cues, as `audio_tug.gd` is for the beam: parked behind a switch, staged cues, tests.
4. The looped voice (built, `audio_voices.gd`) serves the bore, the hum, the hush and the sizzle.

## 6. What I could not judge

I cannot listen. The sketch is a proposal made audible, mixed offline, so its levels, the length of the roar and whether the exosphere's dullness reads as "thin" and not "broken" are for a playtest and Orb's ear. The ash's filter, the far-blast distances and the altitude band are first values to tune with the real distances and heights.

## 7. Sources and licence

Every sound is synthesised by our own code from the recipes in `proposed/catastrophe-recipes.json` (and, in the sketch, the existing `impact.heavy` and `impact.medium`): no sample, no recording, no third-party file or code, no audio model, and no sound taken from a real alert, event or film. Nothing evokes a real siren or countdown (c07). Licence: the repo's, as it settles (`audio/README.md`, rows AUD-GEN-001 and AUD-GEN-007).
