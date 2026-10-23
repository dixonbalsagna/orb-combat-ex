# Biome sound (2026-10-23)

Owner: Audio and Music. Orb's brief through the EP: "each biome sounds like a place, and fights in it sound like its material." **Built, tested and parked** (`audio/data/world_cues.json`, `"enabled": false`), in the family Orb asked for on 2026-10-16: lower, chunkier, soft-edged, nothing metallic and nothing that rings. Every sound is measured by its heard spectrum (`world_check`, the same measure as `tone_check`). Everything is our own synthesis, built from noise and tone in code: no sample, no recording, no third-party file (`audio/README.md`, AUD-GEN-010). **I cannot listen**: the clips in `audio/preview/biomes/` are for Orb's ear, and every number is a first value.

## The two parts

### 1. The bed: where you are

One looped ambience for the biome the pair is over. It plays at the listener (no distance, no pan; `Cue.ambient`) on a new **Ambience** bus (-4 dB), as a looped voice that `AudioWorld` moves.

| Biome id | Bed | What it is | Level (dB) | With height |
| :--- | :--- | :--- | :--- | :--- |
| `ocean` | `surf` | a swell of two periods (5 s and 3.3 s) with a low fizz on the crests and a deep body under it | -4 | -4 (the sea falls away) |
| `village` | `village` | soft wind, leaves, now and then a distant wooden knock | -5 | +3 |
| `plains` | `plains` | wind in long grass: a gust and a soft swish | -4 | +4 |
| `city` | `city` | a mains hum (60 Hz with its harmonics) with a slow beat, traffic as a low swell, a few distant thumps | -5 | -3 |
| `forest` | `forest` | rustle in the canopy, a low wind, a hollow thrum | -4 | +2 |
| `desert` | `desert` | long, low gusts with sand hissing in them | -3 | +4 |
| `mountains` | `mountains` | thin wind with a low howl and a deep body | -4 | +4 |

**Spare beds for the biomes World names next** (built, measured, not mapped to a name until it exists): `tundra` (very quiet, a far low wind), `marsh` (a low hum, wet rustle and glugs), `jungle` (dense rustle, a low hum, frog thrums). Rows already in `biomes` for the names I would guess (`ice`, `tundra`, `marsh`, `swamp`, `jungle`, `beach`); **a biome World adds is one row in `biomes` and one in `soil`**, and a name with no row takes `default_biome` (plains).

How it behaves:

- **Crossfade.** The pair's midpoint (shortest arc) decides the biome. A different biome must hold for 120 ticks (2 s) before the bed changes, and a short visit changes nothing. The change is a crossfade over 2.4 s: the new bed starts at -40 dB and rises, the old one is stopped with the same fade, in the other of two groups (`amb.a`, `amb.b`). Two biomes with the same bed (two villages) never refade.
- **Ducked by the fight.** An intensity (every blow adds its damage over 80, a crater adds 0.2; it falls with a time constant of 2.2 s) lowers the bed by up to 8 dB while a fight is hard, and lets it back in the lulls. The bed is therefore loudest when nothing is happening, which is when the place should be heard.
- **Height.** Up in the air the wind beds are louder and the sea and the city are quieter, by the biome's own number, at 900 units up and more.
- **Quiet on the wire.** An update goes to the voice only when the level has moved half a dB, so a quiet minute sends nothing.
- **Seamless.** Each bed is noise filtered round the loop twice (and the DC block too), and every movement is a whole number of cycles in the loop, so the last sample runs straight into the first (checked by `world_check`). 10 s at 6,000 Hz (about 120 KB each); the beds are all under about 1 kHz, so nothing is lost.

### 2. The surface: what the fight is made of

Eight grounds, each a **hit** (what a body does to it) and a **slide** (what dragging along it sounds like): `grass`, `sand`, `snow`, `mud`, `water`, `rock`, `rubble`, `paving`. One hit serves for a step (higher, quiet), a landing (lower, louder with speed), a bounce, a crater's layer and a scuff under a blow, so each ground costs two recipes.

**Which ground is the sim's own read at the contact**, not a guess: `WorldContact.surfaceAt` (paving in a city or village that is not dug, rock, sand, rubble where a building has fallen, and soil), then standing water from `WorldWater` if the contact is at its surface, and for soil the biome's own ground (`soil` in the data: plains and village grass, forest mud, ice snow). The sim's `land` and `bounce` events already name the surface; the rest ask `surface_at(x, y)`. Nothing here writes the sim and nothing draws from its RNG.

| The event | What plays | Sized by |
| :--- | :--- | :--- |
| `damage` near the ground (under 150 units) and not tiny | the ground's hit, quiet, under the blow's own sound | the damage (louder and lower for a big blow) |
| `land` | the ground's hit | the speed into it (a touch under 250 a second is silent) |
| `bounce` | the same, 3 dB softer | the speed |
| `slide_dust` (every third sample) | the ground's slide | the slide's speed |
| `skim` | water's hit | the speed |
| `splash` | water's hit | the splash's size |
| `crater` | the ground's hit, low | the crater's energy |
| a fighter on the ground and moving | a step, alternating feet, quiet and high | faster steps when he runs |

In the three seeded matches (3,600 ticks) the layers come to 13, 112 and 59 a minute: a fight is mostly in the air, so most of the time the bed is the biome and the surface speaks at the landings.

## What it sounds like, by the heard spectrum

(`world_check`; centroid in Hz of what a small speaker plays, A-weighted, below 180 Hz cut. Limits are in the file.)

Beds: surf 411, village 339, plains 369, city 238, forest 386, desert 438, mountains 280 (spares: tundra 260, marsh 305, jungle 417); nothing over 2 kHz to speak of.
Hits: grass 587, sand 561, snow 374, mud 371, water 600, rock 315, rubble 252, paving 588. Slides: 356 to 769.
For comparison the brawl's own hits are limited at 560 to 850 (`tone_check`).

The two "chunkiest" are rubble (252) and rock (315), the ones heavy fights make. If a ground should be more *recognisable* than it is low (rubble reads as a thump with a grumble rather than a clatter), I would raise its crumbs, not its highs: the grains have no click on purpose (the 3-sample click each grain had was where the tin came from).

## For Orb to hear

`audio/preview/biomes/` (the README.txt beside the clips says which is which): a bed per biome at the level it has relative to the others, a clip per ground, and three staged fights (desert, ocean, city), each as a pair: `fight-<biome>-dry.wav` with the set on and `fight-<biome>-without-dry.wav` with it off, same fight, same levels. Staged fights are a few blows, a landing and a crater, a slide, a flurry up in the air and two heavies, with the bed under them ducking.

## Tuning knobs (all data, `world_cues.json`)

- A bed too quiet or loud: `biomes.<id>.gain_db`. Ducking too deep: `intensity.duck_db`; how fast the fight lets go: `intensity.decay_s`.
- Surface layers too present: `hit.gain_db` (blows), `land`, `bounce`, `step`, `slide`, `crater` each have `gain_db`; `step.interval_*` for the walking pace.
- A ground too loud or quiet next to the others: `surfaces.<ground>.gain_db`.
- Switching: `"enabled": true` for the whole set. A bed or a surface can be silenced alone by making its level very low; I would not.

## What the host has to do

1. **Play the cues as it already does.** Beds are ordinary cues (`ambient` true, `loop` true, `group` `amb.a` or `amb.b`, bus `Ambience`) with `update` cues and stop requests, the same shapes the struggle's bed and the coil use. `AudioVoices` needs only the one-line change in the park (`ambient` ignores the camera).
2. **Warm the beds at the start of a match**: `AudioBank.warm_begin`/`extra_ids` already include the surface sounds when the set is on (16 sounds, about 150 ms in all); the beds are not in `extra_ids` (they depend on the world) and `cues.world.warm_beds(S)` names them for the ring (the seven today). They render in about 1.1 s in all on a loaded machine (about 160 ms each), so they must not be first-played in a fight: Rendering's boot warm-up adds those ids.
3. **The Ambience bus** is in `mix.json` (the park adds it).

## What is not here, and why

- **Hiding and underwater**: a submerged or hidden fighter does not change the bed. Ambience under water would want the muffled bus; I held it back because the pair is rarely under and it is the host's routing.
- **Beam scorch, dust and debris events** (the ground scorched along a beam; particles) make no sound of their own here: the beam's sound is the beam's.
- **Buildings falling** are the destruction sound's (`impact.crater`); a layer of paving or rubble under them is possible if Orb wants more of the city's material.
- **Wind rush at speed** is a different brief (flight), not the biome's.
- **Music** is untouched; the bed sits under it on its own bus.
- **Deaf and hard-of-hearing players**: the bed carries no information (the place is on screen), so it needs no caption, and the surface layers sit under sounds that already have captions.

## Sources and licence

Every sound is synthesised by our own code from the recipes in `world_cues.json` (`AmbienceSynth` for the beds, `ImpactSynth` for the grounds): no sample, no recording, no third-party file or code, no audio model. No CC0 source was used or needed, so there is nothing to attribute beyond the rows AUD-GEN-010 and AUD-PREV-009 in `audio/README.md`. Licence: the repo's, as it settles.
