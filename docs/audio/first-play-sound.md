# What a player hears in the candidate build (Audio and Music, 2026-11-01)

Answers the EP's brief for the first press (`docs/ep/first-press-list.md` item 8a). **Read from a headless log, not by ear: nobody here can listen.** The log is a scratch script that steps seeded AI-versus-AI matches in the stack's tree (`meridian-stack-preview/stack/5a0e4013.../tree`, every preview switch on) and passes each sim event, one at a time, through the audio mapper. 6 normal matches of 90 s (seeds 300 to 305), 4 tier-4 starts on a generation 3 planet (seeds 400 to 403), and 4 matches each with a mashed heavy and a mashed signature (seeds 500 to 503). Counts below are from the 6 normal matches (540 s of fighting) unless stated.

## 1. Which sound is live

The chunky re-tune. The candidate tree's `audio/` is byte for byte main's after line endings (impacts, brawl_cues, beat_cues, cues, the mapper and the bank), and `tone_check` passes on it: the hits are heard at 417 Hz (light lite) to 754 Hz (heavy), 4% or less of their energy over 2 kHz. The old high, ringing set is gone.

**The bright ones that remain** are the first suspects if the hits still read as tinny: `energy.bolt` (heard 1297 Hz, 6% over 4 kHz; **258 of them in 540 s, the most frequent bright sound**), `energy.blast` (1240 Hz) and `impact.whiff` (1730 Hz, an air whoosh on purpose).

## 2. The table: what a real fight fires and what plays (the three sets off, as shipped)

| What happens | Per 540 s | What plays |
| :--- | ---: | :--- |
| Any blow lands (`damage`) | 3,329 | light 1,594 `impact.light`, 943 `impact.light.lite`; guarded 692 `impact.guard`; absorbed 31; medium and heavy `impact.medium`, `impact.medium.grind` (a mash), `impact.heavy`; a double hit `impact.double` |
| Pain and effort | about 500 | `voice.*.pain.limb` / `.head`, `voice.*.effort.heavy` (grunts, not words) |
| A blow misses | 9 | `impact.whiff` |
| Medium or heavy wind-up | 83 | `windup.medium` / `windup.heavy` (the gather), cut if a blow stops it; held B: `charge.hum`, then `charge.tick.heavy` |
| The launcher opens ("B now") | 25 | `ui.launcher`, cut when used |
| A bolt lands | 258 | `energy.bolt` (the bolt leaves in silence) |
| A blast reaches and lands | 1 | `energy.gather`, then `energy.blast` |
| A crater (energy over 0.45) | 8 of 15 | `impact.crater`, bigger is louder and lower (pitch floor 0.7, gain cap +3 dB) |
| A head flash starts | not in these logs | `flash.<id>.<family>`, when the host calls `AudioCues.flash` (`render/core/main.gd` does) |

### Silent as shipped, and what a set adds (sets off, then on)

| Event | Per 540 s | Off | With the set on |
| :--- | ---: | :--- | :--- |
| Perfect block | 18 | silent | `block.perfect` (carry) |
| Rush (a dash or a chase) | 112 | silent | `rush.whoosh` (carry) |
| Grip: clinch, squeeze, pummel | 19 / 22 / 24 | silent | `grip.clasp`, `grip.creak`, `grip.thud` (carry) |
| Ring turns, form ready, coil, brake | | silent | `arena.shift`, `form.ready`, `drone.coil`, `brake.skid` (carry; not reached by AI play) |
| Beam struggle starts | 5 | silent | `tug.lock` and `impact.heavy`, then the two-drone bed (tug) |
| Struggle pulse / surge | 75 / 99 | silent | `tug.tock`+`tug.pulse`, `tug.surge`+`tug.crack` (tug) |
| Struggle ends | 5 | silent | `impact.medium` (time), `tug.fall`, or `impact.double`+`energy.blast` (detonate); bed cut |
| Land, bounce, slide, skim, crater under a blow | 14 / 3 / 12 / 43 | silent | `surf.<ground>.hit` / `.slide`, on about 1 hit in 4 near the ground (world) |
| Biome ambience | always | silent | `amb.<biome>` crossfaded beds (world) |

### Silent in both states: flagged, no sound exists for them yet

| Event | Per 540 s | Note |
| :--- | ---: | :--- |
| **Beam charge and beam fire** (`beam_charge`, `beam_fire`, `beam_arrive`) | 12 / 7 / 2 | **a beam leaves the fighter in silence**; only a struggle or the end of it makes a sound |
| **The meteor** (`arc_send meteor`) | 1 per 4 tier-4 fights | the send is the heavy hit; the flight is silent (an accidental hush); **the landing is the ordinary crater sound** (meteor energy is 9x, the cue clamps at +3 dB and pitch 0.7). No rise, no hush before it, no late far boom: `catastrophe.md` is paper only |
| **KO** (`ko`) and `decisive` | 89 decisive | no sound of its own; the last blow's hit is all that plays (no KO happened in these 90 s runs) |
| **Launch flight**, knockback, `kick` | 13 / 5 / 55 | the blow that launches sounds (`impact.heavy`); the flight does not |
| Bolt leaves (`shot_fire`), `shot_clash`, `shot_deflect` | 78 / 9 / 1 | silent; the landing sounds |
| Grapple tell, catch, throws, tech | 22 / 3 / 9 / 8 | silent even with carry on (it covers only clasp, creak, thud) |
| `guard_break`, `parry`, `reversal`, `riposte`, taunts | 5 / 56 / 40 / 13 / 6 | the blow's own hit sounds; the moment itself has none |
| `transform`, `transform_ready` | 1 / 5 | `transform_ready` is carry's; `transform` is silent |
| **Spoken lines (the babble)** | | **not called by the host**: `AudioBabble` is used by no scene in `render/` or `ui/`. Fighters grunt; they do not speak |
| Music, menu and card sounds | | none exist (no Suno file has come back; no UI sound was ever made) |

## 3. Which sets to turn on

Checked on a real data flip (a scratch copy with the two files' `enabled` set true, not the in-memory flip): `warm_check` passes (nothing renders on first use, 258 clips), `host_check` passes (sim hashes unchanged by audio, both seeds; cue logs reproduce), `tone_check` passes, and 6 matches give 4,746 cues (790 a match) against 3,990 with the sets off.

| Set | Switch | Verdict |
| :--- | :--- | :--- |
| Beam struggle (`tug`) | `audio/data/tug_cues.json` `enabled` | **On.** Without it the struggle, the one thing Orb will be told to look for, is mute. Needs the `struggle` switch, which the stack has |
| What the HUD no longer draws (`carry`) | `audio/data/carry_cues.json` `enabled` | **On, after tug** (its struggle groove needs tug). The rush, the grip and the perfect block are otherwise silent, and the minimal HUD draws no marker for them |
| Biome sound (`world`) | `audio/data/world_cues.json` `enabled` | **Not ready.** (1) Nothing in `render/` calls `bank.warm_ids_async(cues.world.warm_beds(S))`, so each ambience bed (about 160 ms natively, a second or more in a browser; up to 17 on a generation 3 planet) would render the first time a biome is entered, in the middle of a fight. (2) It lays a second sound under about 1 hit in 4, an ear question that would blur the first answer. Turn it on after Orb has judged the hits |

**The page word.** Both are data flips, so they belong in `tools/preview/switches.mjs`, not in the committed defaults: `carry_check` and `tug_check` assert "the switch is off in the data" (they fail by design on a flipped copy), and the shipped default stays off until Orb has heard it. Rows:

```
{ id: 'soundTug', file: 'audio/data/tug_cues.json', path: ['enabled'], from: false, to: true, needs: ['struggle'], optional: true,
  what: 'the beam struggle has sound (Audio): lock, a two-drone bed that follows the meeting point, the pulse, surge and crack' },
{ id: 'soundCarry', file: 'audio/data/carry_cues.json', path: ['enabled'], from: false, to: true, needs: ['soundTug'], optional: true,
  what: 'the sounds that stand in for the old markers (Audio): the grip, the perfect block, the rush, the ready sting, the ring turn' },
```

Read-back probes for the page's state line: `host.audio_cues.tug.enabled()` and `host.audio_cues.carry.enabled()`.

## 4. The first-play question for Orb

"When the fighters trade blows and the beams meet, do the hits sound heavy and satisfying rather than thin, and what is the one moment you expected a sound for and got none?"

## What changed in files

`audio/tools/host_check.gd`: the gain floor for a looped or ambient cue is -40 dB (a bed sits under the hits on purpose: `bed.hi` goes to -28), not -20. Found on the real flip; it only fails with the tug set on. Nothing else.
