# The shared flash registry (2026-10-06)

Owner: VFX Director. Legal's condition before the first public release of the web build (docs/legal/photosensitivity-note.md, RL-115; WCAG 2.2 criterion 2.3.1, "three flashes or below threshold"). `render/vfx/flash_registry.gd` (`VfxFlashRegistry`), held by the hub as `hub.flashes`. Presentation only: it reads nothing from the sim, draws no random number, and the gameplay hash is untouched.

## The rule

- **At most 3 granted flashes in any 60 ticks** (a second) across the whole screen: both fighters and every effect that asks.
- **Priority.** Low-priority sources (`energy`, `block`, `shot_hit`, `mine`, `zip_break`, and Rendering's `body_hit`, `head_flash` and `cue_flare`: the things a fight makes many of) get at most 2 of the 3, so one slot is always left for the big events (`explosion`, `transform`, `beam`, `beam_clash`) and for a perfect block's `guard_flash`, which is not low (a skill moment the player earned, about 2.4 a minute at medium: the EP's ruling).
- **Reduced flashing** (`hub.reduced_flashing`, or reduced motion): the cap is **1 a second** and the low-priority sources get none. This is "halves it or better".
- **Nothing red.** A flash whose colour is saturated red (`r > 0.55`, `g` and `b` under 0.45 `r`) is refused whatever the count; the lane colours (cyan, violet) and the flame's orange are not red.
- **The clock** is the hub's own tick count (one per `consume()`, frozen ticks included), so a hit-stop does not stop the second.
- A refused flash is **not drawn in its flash form**; the source draws what is left (the table says what).

`ask(source, colour, tick) -> bool` is the one call a source makes before it draws. `note(source, tick)` counts a flash another system draws and cannot be refused yet. Both write the log.

## The log, for Tools and for UI

`hub.flashes.log` has a row for every ask: `{now, tick, source, granted, why, in_window}`, newest last, the last 2,400 asks. `log_rows()` returns them as arrays `[now, tick, source, granted, why, in_window]` for a script. `why` is `ok`, `cap`, `low_priority`, `reduced`, `red` or `unregulated`. `summary()` gives `granted`, `refused`, `worst_second` (counted from the log), `worst_running` (the running figure over the whole run), the counts by source and the cap in force. The log is per match and is cleared by `hub.reset`. Tools can run the WCAG 2.3.1 check over recordings and read this log beside it: the log says what the effects asked for, the check says what the pixels did.

**What a "reduced flashing" setting would switch** (UI: `host.vfx.reduced_flashing = true`): the register's cap from 3 to 1 a second and the low-priority flashes (energy landings, block, shot-hit and mine rings, guard-break rings) off, with the explosion's flame burst and the transformation's break flash down to one a second between them. It does **not** touch anything Rendering draws (below) until Rendering asks the register. If UI offers it, it should also switch Rendering's hit flash and head flashes when those ask.

## What Reduced motion removes today, and what it does not

UI is writing a notice: it must not say "no flashing". Reduced motion (`hub.reduced_motion`, set from the player's option) **removes or calms**:
- VFX: the transformation's break flash disc (the ring stays); the blast power-up's shock ring; the energy landing's full flash (the crack, ring and rim stay, dimmer); the wear flicker (a steady dimming instead); the standing aura's breathing; the mines' bob and fuse blink (steady); the beam head's pulse (steady); wind marks and trail marks (half the count or none); rocks and debris counts halved; the register's cap drops to 1 a second and the low-priority flashes stop.
- Others: Animation's ragdoll joint ranges halved; Camera's shake quartered, cuts as dissolves, the panel cut-in still; the sky stands still; the head flashes play one pulse instead of 2 or 3.

It does **not** remove: Rendering's white **body hit flash** (the whole body goes white for 0.12 s on every hit), the head flash's single pulse, the guard arc's flash on a perfect block, the additive beams and the clash flare, the press styles' contact rings, diamonds and crescents (they are hollow or thin marks, not flashes), hit sparks, an explosion's flame burst once a second, and the glare's on and off. So the honest sentence is: "Reduced motion calms movement and removes most of the large bright flashes; it does not stop every flash."

## Every flash source and whether it is under the register

| Source | Owner | What it is | Under the register? | If refused |
| :-- | :-- | :-- | :-- | :-- |
| Energy landing's soft disc | VFX `reach.gd` | filled disc, 38 to 56 units, 3 ticks | **Yes**, `energy` (low), and its own 1 in 20 ticks | sparks at the contact; crack, ring and rim stay |
| Block's flash rings | VFX `press.gd` | two hollow rings, 7 ticks | **Yes**, `block` (low) | the shield line only |
| Shot hit's flash ring, a deflect's, a stop's | VFX `shots.gd` | one hollow ring per hit | **Yes**, `shot_hit` (low); rides free on a flame burst granted the same tick | the ring that goes with it still draws |
| Mine trip's flash | VFX `shots.gd` | one hollow ring | **Yes**, `mine` (low) | none; the fuse blink and the blast remain |
| Explosion's flame burst | VFX `explode.gd` via `shots.gd` | flames with a pale core, sparks, smoke | **Yes**, `explosion` | sparks and smoke only (the explosion's own "spark" mode) |
| Transformation's break flash | VFX `transform_view.gd` (on hold) | soft disc 1.7 bh, 5 ticks | **Yes**, `transform`, **without editing transform_view.gd**: the hub asks once as the break begins and `VfxTransform.flash_scale` (read by `VfxTransform.p`) turns the disc's alpha to 0 | the break's ring still leaves the body |
| Guard break's ring | VFX `zip.gd` | one hollow ring | **Yes**, `zip_break` (low) | the fragments only |
| Wear flicker (aura dropouts) | VFX `react.gd` | alpha dropouts of a worn fighter's aura | **Re-timed, not asked.** It was up to 20 dropouts a second; it is now at most one 4-tick dropout in each 40 ticks per fighter (1.5 a second each, 3 across both; asserted by `effects_check`) | n/a |
| Mine fuse blink | VFX `shots_view.gd` | the plate dims to 0.45 and back | **Re-timed**: 10-tick halves, 3 a second (it was 7.5) | n/a |
| Beam head pulse | VFX `shots_view.gd` | head alpha ±20% | **Re-timed**: 3 Hz (it was 10) | n/a |
| Press contact rings, diamond, crescent, speed blur | VFX `press.gd` | hollow, thin or low-alpha marks | **No: not a flash** (small and hollow; no luminance step of the standard's size) | n/a |
| Energy crack, ring, rim, spill, carry; B now chevrons; send-off | VFX `reach.gd` | thin lines and hollow rings | **No: not a flash** | n/a |
| Pressure rings, power-up shock ring, crack sets, dust, shards, glass, a building collapse | VFX | rings, lines, matter | **No: not a flash.** A collapse in VFX is dust, shards and glass; no bright pop | n/a |
| Glare on the rival's glasses | VFX `glare.gd` | a lens wedge of 10 by 4.8 units in pale violet, a 3-tick attack and a hold of at most 24 ticks | **No, and deliberately not asked.** The cooldown is the guarantee: a wearer's glares are at least 200 ticks (3.3 seconds) apart, so at most 0.3 on-off cycles a second a wearer, on an area far under the standard's; only a seal-break cue ignores the cooldown. Reduced motion makes the ramp a hard on/off, still once per cooldown at most (the EP agreed, 2026-10-06) | n/a |
| **Body hit flash** | **Rendering** `fighter_view.gd`, `anim_body.gd` (`HIT_FLASH_S` 0.12 s) | the **whole body white** on every hit | **No.** Needs Rendering. At a mash's 5 to 10 hits a second this is the largest strobe risk in the game | see "Needs" |
| Head flashes | **Rendering** `flash_view.gd` | 2 or 3 icon pulses at the head | **No.** Needs Rendering | one pulse in reduced motion (Rendering's) |
| Guard arc flash on a perfect block | **Rendering** `fighter_view.gd` | the guard arc flares | **No.** Needs Rendering | |
| Signature beams, beam clash flare | **Rendering** `beam_view.gd` | additive cylinders with a white core; a flare at a clash | **No.** Needs Rendering | |
| Impact sparks and scorch | **Rendering** (`impact`) | sparks | **No**, not surveyed beyond the name | |

## What I could and could not do about the held files

`transform_view.gd` and `vfx_layer.gd` stay untouched. The transformation's flash is brought under the register through `transform.gd` alone (a static scale the view's own `VfxTransform.p("break", "flash_alpha")` call already passes through), so **nothing is needed from those two files for the transformation**. The pressure rings are thin rings (not a flash) and need nothing.

## Needs (outside my paths)

1. **Rendering**: before it starts the body hit flash, a head flash, the guard arc flash or a beam clash flare, call `host.vfx.flashes.ask("body_hit" | "head_flash" | "guard_flash" | "beam_clash", colour, S.tick)` and skip the flash if it returns false (the hit still lands; the body just does not go white), or, if it cannot skip, `host.vfx.flashes.note(source, S.tick)` so the count is honest. Priority: add the names to `VfxFlashRegistry.LOW` if Rendering wants them to leave a slot (the hit flash should be low). The body hit flash is the one that matters most.
2. **Tools**: an optional `drop_ticks` key in `tools/schemas/vfx-react.schema.json` (the dropout length is a constant, `VfxReact.DROP_TICKS`, until then); the WCAG 2.3.1 script over recorded frames, reading `hub.flashes.log_rows()`.
3. **UI**: bind a "reduced flashing" setting to `host.vfx.reduced_flashing`.

## Numbers

- `effects_check.gd` `_flashes()`: the rule (3 in 60, low priority 2, red refused, the window slides, reduced flashing 1), one case for each family with a flash (energy, block, shot hit, explosion, transformation twice, guard break), every family at once for 2 seconds (never more than 3 granted in a second, the rest refused), the log (a row per ask) and reduced flashing through the hub (at most 1 a second, no energy or hit-ring flash).
- Real AI matches (`hash_check.gd`, seeds 12345, 4 and 7, six VFX runs each, 3,600 ticks, 64,800 ticks of play in all): 854 asks, **489 granted and 365 refused**, never more than 3 in any second. By source (granted, refused): block 300 and 282, transformation 70 and 2, explosion 109 and 35, shot hit 10 and 46. Blocks are the busiest source in the AI's play (a block's flash ring is refused about half the time; the shield line always draws), then explosions (a refused burst is sparks and smoke). No energy blow exists in the sim yet, so energy is not in these numbers; the 30-bolt mash test covers it.
- Cost: `ask` is a loop over at most 3 integers and one log row; a dozen asks a second at most. Nothing is drawn by the register itself; refusing a flash removes quads, it adds none.
