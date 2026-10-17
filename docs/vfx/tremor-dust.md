# The tremor's dust (catastrophe tier, step 2)

Owner: VFX Director. 2026-10-17. Step 2 of `docs/vfx/catastrophe-plan.md` (§5), built in scratch and parked (`docs/vfx/pending/tremor-dust/`), on top of the parked `warm-and-cat` patch (the `cat` class). Legal c01 to c06 and run-mode §3.1 bind it. **Nothing draws until the `tremor` cue exists** (Simulation's: Audio's list gives it as `tremor` with `n` the tick it ends); a scratch scene injects it for the measurements below. Not a clearance.

## What it is

A live quake with no pause, shown as **low curtains of dust** across the whole visible slice and **a patter of small rubble**. A quake, never glowing fissures, never a ring, never a rhythm: the audio's 2.5 Hz wobble is not mirrored.

| Piece | File | What |
| :--- | :--- | :--- |
| State and rules | `render/vfx/tremor.gd` (`VfxTremor`) | the cue's runs (a start and an end tick, at most 2 at once), the envelope `level()`, the calm form's slower onset, the rubble spawner; hashes, never `S.rng` |
| Drawing | `render/vfx/dust_view.gd` (`VfxDustView`) + `render/vfx/shaders/dust.gdshader` | one MultiMesh, one draw call, at most 160 soft sprites of warm grey, a child of the trail view (like the shots view); the shader is a soft noise-broken puff, alpha-blended, never additive |
| Numbers | `data/vfx/catastrophe.json` (+ `tools/schemas/vfx-catastrophe.schema.json`, `map.json`) | every number below; the built-in defaults agree (checked) |
| Wiring | `vfx_hub.gd` (`tremor`, `catastrophe_enabled`), `trail_view.gd` (`dust_view`) | one cue handler, one clock tick, one draw call |
| Checks | `effects_check.gd` `_tremor` | see below |

## The numbers (the plan's, and where they are held)

- **At most 160 sprites** (60, 110, 160 by quality), **alpha at most 0.5**: no sprite is over 0.13, and *the sum* of the overlaps never passes 0.5. `VfxDustView.worst_column` measures it with the shader's own soft profile over three zooms, three qualities and ten seeds: **0.480**.
- **Onset 1 s** (calm: 1.5 s), **settling 4 s** (calm: 5 s), each a smootherstep; the steepest tick is 1.875 over the onset of the peak: **0.0094 of a brightness step at most** (0.0062 calm), against the 0.1 that counts. Dust is dark and slow, so it asks nothing of the flash register and is not a catastrophe light event (checked: the register's log and `cat_events` stay empty).
- **No rhythm.** A slow wander (two sines at 0.31 and 0.17 rad/s per sprite, phases from a hash) and a small shiver (at most 6% of a sprite's alpha, two sines at 0.83 and 1.37 rad/s, not harmonics of one another, phases per sprite); **both off in the calm form and Reduced motion**, where the curtains rise and settle only. Nothing repeats at a fixed period.
- **Colour:** a warm grey (`#8a8277`, red share 0.36): nowhere near red. **Position:** behind the fighters' plane (z -20 to -6), standing on the ground (`groundY` under each sprite), 0.16 to 0.46 of the half view tall (about 65 to 185 units at fight framing, up to three fighters high), spread across 1.15 of the half view.
- **Rubble:** up to 40 small chunks a second (20 in the calm form, which is the game's default Reduce flashing), through the existing debris pool and its caps, from the ground round the fighters, at hashed places and times, only while the tremor runs.
- **Between runs:** a second cue adds a run (at most 2); a seek or a pause is right by construction (the curtains are a function of the clock and the run).

## Measured (main fba75d21 + the parked patches, native checks and web clips, one capture at a time)

- `effects_check` `_tremor` passes: the data file against the defaults, the plan's counts and caps, the envelope in both modes (0 outside, 1 on the plateau, monotone, steepest tick), the layout's overlap sums (0.480), a sprite as a pure function, the colour, the no-harmonics rule, no cue = nothing thrown, one run per cue, rising from nothing to full over the onset, dropped once settled, **nothing asked of the flash register**, the same cue giving the same rubble, and the calm form throwing less (44 bits against 99 in 3 s).
- **Flash clips** (a scratch scene: the city mash beside the tallest tower with a tremor cue at ticks 90 and 700, 241 ticks each, 1,000 ticks, 1024 by 768, the official analyser): **both modes PASS: primary 1, area-15% 1, higher threshold 1, the stricter cross-check 0, red 0.** The same scene without the cue is Tools' `mashcity` (primary 1, area-15% 1 on HEAD, `docs/rendering/city-variety.md`), so the dust adds no reading to those two.
- **Look:** a faint grey haze at the foot of the street and the crowd, rising over a second and settling over four, with chips on the ground; the base of a tower reads about 6 to 15 steps of 255 brighter at full strength. It is deliberately light: the sum of its overlaps is capped at 0.5 and its typical value is a third of that. **It is a first version for Art and Orb to judge**: a denser, taller curtain is possible up to the same cap by lengthening the sprites (`height_k`), and a stronger colour would raise the contrast, which the brightness check above would then re-read.
- Cost: counts only. One draw call, at most 160 instances; the layout (160 hashes and 160 `groundY` reads) runs only while a tremor does, per pane. No timing was taken (the machine is shared); the first-use hitch is the shader's, which Rendering's boot warm-up covers when the line below is in.

## For Rendering: the warm-up list

`render/core/warmup.gd` is in Rendering's parked batch (`docs/rendering/pending/2026-10-17/`), not in HEAD, so its two lines are a patch to apply after that batch: `docs/vfx/pending/tremor-dust/warmup-entries.patch` adds `hole.gdshader` (missing from the first list) and `dust.gdshader` (`"multimesh"`).

## What it does not do (and who does)

- **The towers' sway, the ground's heave and the windows going dark** are World's, Animation's and Rendering's. **The camera's shake** is Camera's.
- **No light event, no cue sound:** the tremor's sound is Audio's (`cat.tremor`), and a `tremor` cue must come from Simulation with `n` the end tick; until then only the scratch scene exercises this.
- Not built yet in the catastrophe plan: the blast cloud, the magma's flare and bubbles, the orbital impact include (§8's order: cloud next).
