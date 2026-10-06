# Rendering's flashes and the shared flash register

Owner: Rendering and Technical Art. 2026-10-06. Legal's condition for the public web build (`docs/legal/photosensitivity-note.md`): at most three full flashes in any second across the whole screen, one under reduced flashing, never red. VFX built the register (`render/vfx/flash_registry.gd`, `hub.flashes`; `docs/vfx/flash-registry.md`). This page is Rendering's half: every full flash drawn from `render/core` and `render/shaders` asks it first.

## How a flash of Rendering's asks

- **One call:** `SimHost.ask_flash(source, colour)`. It returns whether the flash may be drawn, and a granted flash takes one of the second's three slots. A red colour is never granted.
- **Once for the screen.** The host asks, not a view, so a flash seen in both panes of a split is one flash and one slot.
- **After VFX.** Each tick the host asks after VFX has consumed the tick's events, so the register's clock is that tick's and VFX's big events (an explosion, a transformation) have asked first. Rendering's order is: head flashes, a perfect block's guard flash, a cue's flare, a new beam, a beam clash, and last a new hit's white body.
- **Low priority.** `body_hit`, `head_flash`, `guard_flash` and `cue_flare` are sources a fight makes many of. They get at most two of the three slots and none under reduced flashing, as the register's own low sources do. The register's `LOW` list does not name them yet, so `ask_flash` applies the rule itself until it does (the host's own refusals are counted in `SimHost.flash_refused`, the register's in its log).
- **With VFX off** (`--novfx`) the hub does not run its register, so the host ticks it. Rendering's flashes keep to the limit either way.
- **Presentation only.** Nothing here reads a random number or writes the sim.

## Every flash source in Rendering's paths

| Source | Where | What it is | Under the register | When refused |
| :-- | :-- | :-- | :-- | :-- |
| **A hit's white body** | `fighter_view.gd` (through Animation's `anim_body.set_look`), 0.12 s | The whole body goes white. At a mash's 5 to 10 hits a second it was the largest strobe risk in the game | **Yes**, `body_hit` (low). The host asks once for each new hit (`SimHost._ask_hits`) | **The outline lights** pale for the same 0.12 s (`RenderLook.HIT_EDGE`). It is a line a pixel or two wide, not a flash. The hit still lands; its sparks, the flinch and the damage marks are as before |
| The same on the placeholder parts | `fighter_view.gd` (`solid`) | The box figure's parts go white with the body (the old look, `--noanim`) | **Yes**, the same grant | They keep their colour |
| **A perfect block's guard flash** | `fighter_view.gd`, `guard.gdshader`, 0.3 s | The guard arc's line thickens, a second line leaves it, and its fill deepens | **Yes**, `guard_flash` (low), once for each block | The two lines still flash; the fill does not deepen (`flash_fill` 0). Lines are not a flash |
| **Head flashes** | `flash_view.gd` | Small shapes at the head that swell two or three times in under a second | **Yes**, `head_flash` (low). Each swell asks as the flash starts, so a three-swell flash plays as many swells as were granted | With none granted the flash still shows once, calm: it fades in, holds and fades, with no swell, sweep or jitter (the reduced-motion form). The player still gets what it says |
| **A cue's flare** | `fighter_view.gd` (`flare`) | A soft glow at the chest, up to a body and a half across, on four of Combat's cue poses | **Yes**, `cue_flare` (low), once for each fighter the cue plays on | No flare. The pose, the hand spark and the ring still play |
| **A signature beam** | `beam_view.gd` | Three additive cylinders, the inner one white, held and then faded: one bright step up and one down | **Yes**, `beam` (not low: a big event), once for each beam | No white core, and the rest at 45% of its strength (`RenderLook.BEAM_SOFT`) |
| **A beam clash's flare** | `beam_view.gd` | A white glow where two beams meet, with the two clash beams | **Yes**, `beam_clash` (not low), once for each clash | No flare; the two beams are drawn as a refused beam is |
| A cue's hand spark and ring | `fighter_view.gd` | A small spark at the hand; a hollow ring | No: small or hollow, not a flash | |
| The placeholder aura, speed streaks and charge orb | `fighter_view.gd` | The old look in place of head flashes (F7 off) | No: a debug view, not in normal play | |
| Sparks, debris, dust, splashes, ripples, shock rings, after-images | `particle_view.gd`, `impact_fx.gd` | Points a few pixels across, hollow rings, thin outlines | No: not a flash | |
| A fresh groove's glow | `impact_fx.gd`, the ground shader | A line of glow that fades over about 1.6 s | No: one slow fade along a line | |
| Windows going out, a building's damage stage | `building.gdshader` | A step in a building's look, once | No: one change, never repeated | |
| The sky's reaction to tier 3 and 4 | `sky.gdshader` | Off by default | No: off | |
| The old HUD's banner and floating words | `hud.gd` | Text, in the F2 debug view | No: a debug view | |

Not Rendering's, though they are drawn near these: the glare on the rival's glasses (VFX's `glare.gd`), the divider's slam flash (Camera's and UI's), every ring and burst in `render/vfx`.

## What it does in play

`render/tools/flash_reg_check.gd` (headless, through the real scene), on HEAD 00c4c90e plus this change:

- **Three AI matches of 3,600 ticks** (seeds 12345, 4 and 7): never more than 3 flashes granted in any second, Rendering's and VFX's together.

| Seed | Body white: granted, refused | Head flash pulses | Guard flash | Beams |
| :-- | :-- | :-- | :-- | :-- |
| 12345 | 56, 213 | 2, 12 | 1, 4 | 4, 0 |
| 4 | 59, 225 | 1, 17 | 2, 5 | 2, 0 |
| 7 | 61, 213 | 4, 14 | 1, 5 | 1, 0 |

- So about four hits in five now light the outline and one whitens the body, where every hit whitened it before.
- **A mash:** one fighter hit every 6 ticks for 4 seconds, 40 hits. The body whitens 3 times, never more than once in a second, and the outline is lit for the rest. The screen's count never passes 3.
- **The same under reduced flashing:** the body never whitens.
- **The rule:** two low flashes granted, a third refused, a beam still gets the last slot, a fourth flash refused; a red flare refused.
- **Head flashes:** a three-swell flash asks for three; with none granted it shows once, calm; with two it swells twice.

A hit granted (left) and a hit refused (right), on the web build: ![hits](img/flash-hit-granted-refused.png)

## Cost

Nothing measurable. An ask is a few whole-number comparisons, a tick has a handful at most, and a refused flash draws less than a granted one. Web build, headless Chrome, 1366 by 768, 1,500 frames of the bench match, two runs each taken in turn: frame mean 7.29 and 7.20 ms on HEAD against 7.43 and 7.24 with this change; at a 4x CPU slowdown 33.0 and 27.4 against 29.8 and 29.6. Two runs of one build differ by more than the two builds do. The gameplay hash at the end is the same in all four runs.

## Limits, and what is not done

- **The register counts flashes; it does not measure them.** Legal's second condition, a check against the WCAG 2.3.1 algorithm on recorded frames, is Tools' script and is not built.
- **A granted head flash still swells up to twice in a quarter of a second.** Its shapes are small (about a head across), well under the standard's area, and each swell takes a slot.
- **Head flashes are thinned a great deal:** in the three matches 7 pulses of 50 were granted. The flash always shows, but mostly in its calm form. If Art wants the swells back they need a higher priority than the body's white, which is a ruling for the EP.
- **The glow materials are additive.** A refused beam is dimmer, not gone; nothing here measures its luminance.
