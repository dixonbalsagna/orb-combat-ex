# Park: water v2 sounds (Audio and Music, 2026-10-26)

World's water v2 (4dc06456; `sim/world/fill.gd`, `data/biomes/water.json`, off by default) sends three fx events: `water_fill`, `water_wave`, `water_douse`. Each now has a sound, chunky and low, our own synthesis (Orb, 2026-10-16: not tinny, not metallic), checked by the heard spectrum. **Stacks on the fine-biome park** (`docs/audio/pending/biomes-fine/`, itself on the biome sound on main): the sounds live in the world mapper that park replaces. Parked **off** with the biome sound's switch (`world_cues.json` `enabled`), and the events only exist while World's water switch is on.

**Audio's own files, plus Tools' schema, cross-reference rule and fixtures** (`grant_tools.py`, because the schema is closed and every sound has to belong to a surface or to `water`).

## What it does

| Event | Sound |
| :--- | :--- |
| `water_fill` (cause sea or water; amount the deepest dig; dur seconds to settle) | `surf.water.fill`: a rushing swell of low noise with a rumble and low drips under it, at the front's start; louder and lower for a deeper dig; cut with a 350 ms fade when the fill settles (the hold is `dur` clamped to 0.6 to 2.4 s) |
| `water_fill`, cause table (a seep) | `surf.water.seep`: a quiet trickle, 4 dB under a sea fill of the same dig |
| `water_wave` (a slam into deep water; a ring of 600 units) | `surf.water.wave`: one heavy slosh at the slam (a deep thump, a swash of low noise, a rolling rumble); it also counts as an impact for the fight's intensity |
| `water_douse` (water reaching a scorched column; n columns newly wet) | `surf.water.hiss`: a short low hiss with a thump of steam, louder for more columns |

A fill is quick (`STEP_TICKS` is 2: a typical dig settles in a second or less), so the swell is a one-shot with a scheduled cut, not a bed that follows the front. The fills sounding take four groups in turn, so each is cut when its own settles.

Heard spectrum (centroid, A-weighted, below 180 Hz cut; limits in `world_check`): fill 491 Hz, seep 501, wave 547, hiss about 700 (the brightest sound in the set, as a hiss is; limit 800). Warming the four adds about 300 ms on a loaded machine (one variant for the two long ones).

## Apply (after the fine-biome park)

The whole stack, from a scratch export of HEAD (the repo root only for the EP's apply, and then commit):

```
python docs/audio/pending/biomes-fine/grant_tools.py <root>      # Tools' ground patch, rebased (schema, xref, 5 fixtures)
python docs/audio/pending/biomes-fine/apply.py <root>
python docs/audio/pending/water-v2/grant_tools.py <root>         # the water block: schema, rule world-cues-water, 4 fixtures
python docs/audio/pending/water-v2/apply.py <root>
```

`apply.py` replaces five files by path (`audio/audio_world.gd`, `audio/data/world_cues.json`, `audio/tools/world_check.gd`, `audio/tools/render_biome_demo.gd`, `docs/audio/biomes.md`), only where each is what the fine park leaves (`old_hashes.json`). `grant_tools.py` adds a top-level `water` to the closed schema (`fill`, `wave`, `douse`, with bounds like the neighbouring blocks), makes the cross-reference rule check the water sounds exist and count as used, and adds four fixture cases.

## Proof

The stacked proof on a scratch export of HEAD, with the apply order, the sha1s and every gate, is in the report to the EP. In short: `world_check` (new section 5b: staged fills, waves and douses with the fields the sim gives them, the swell's cut, the groups, then **the real events from World's own fill module on a flat world by the sea** and a real match with water v2 on), `tone_check`, `carry_check`, `tug_check`, `brawl_check`, `beat_check`, `babble_check`, `warm_check`, `host_check` (identical to HEAD's cue logs and sim hashes with the set off), validate and its self-test.

`audio/preview/` has the clips for Orb: `water-fill-dry.wav`, `water-wave-dry.wav`, `water-douse-dry.wav` and the ocean fight with and without the set in it (`fight-ocean-water-dry.wav`, `fight-ocean-water-without-dry.wav`), all in `audio/preview/biomes/`.

## Needs

1. Tools: the water grant (and the ground grant before it, which is Tools' own `docs/tools/pending/audio-ground.patch` rebased: its two `cases.json` hunks no longer applied, so the cases are inserted by text).
2. Rendering: the boot warm-up (the four sounds are in `extra_ids()` when the set is on).
3. Orb: the clips.

## Not done

A sound for the pebble skip on a flooded scar (it already uses the existing `skim` sound), and wading (World's wade has no event).
