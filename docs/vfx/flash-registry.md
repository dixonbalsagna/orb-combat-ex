# The shared flash registry (2026-10-06)

Owner: VFX Director. Legal's condition before the first public release of the web build (docs/legal/photosensitivity-note.md, RL-115; WCAG 2.2 criterion 2.3.1, "three flashes or below threshold"). `render/vfx/flash_registry.gd` (`VfxFlashRegistry`), held by the hub as `hub.flashes`. Presentation only: it reads nothing from the sim, draws no random number, and the gameplay hash is untouched.

## The rule (weighted by size, 2026-10-06)

The first version counted requests (three a second). Tools' frame analyser showed the standard counts something else: a flash counts only when the pixels that changed by 0.10 of relative luminance cover 25% of a 341 by 256 window, **21,824 px at 1024 by 768, 2.8% of the frame**. So a flash is now asked for with its **area** and its **step**, and the budget is a sum of weights.

`ask(source, colour, tick, area_px = -1, step = -1) -> bool`

- **Weight** `w = min(1, area_px / 21,824)`. With no area, the source's default weight stands (`VfxFlashRegistry.DEFAULT_WEIGHT`: 1 for a big event and for any unknown source; below for a small one). So Rendering's and UI's existing calls keep working.
- **Step.** A luminance step under 0.10 costs nothing and is not a flash: it is logged as `below_step` with weight 0 and not counted.
- **Budget**, in any 60 ticks across the whole screen: the sum of granted weights at most **2.5** (Legal's gate; **1.0** under reduced flashing or reduced motion).
- **Low-priority class** (energy, block, shot hits, mines, a guard break's ring, Rendering's body hit, head flash and cue flare, UI's divider slam): at most **1.5** of it, none when reduced, so a weight-1 explosion always fits. (The EP's brief said 2 of the 2.5; that leaves 0.5, and a big event of weight 1 could then never be granted, so it is 1.5 here.)
- **Count ceilings stay:** at most 3 granted flashes of weight 0.5 or more in a second (1 when reduced), and at most 6 flashes of any weight (3 when reduced). `guard_flash` is not low (a skill moment: the EP's ruling).
- **Nothing red** is ever granted. A refused flash is not drawn in its flash form; the table says what is left.
- **The clock** is the hub's own tick count (frozen ticks included).

**What the weights are, at the close framing (about 1.3 px a world unit)**

| Source | Area (px²) | Weight |
| :-- | ---: | ---: |
| Energy landing disc (38 to 56 units) | 1,900 to 4,000 | 0.09 to 0.18 |
| Block flash rings (hollow) | about 700 | 0.03 |
| Shot-hit flash disc (45 to 130 units across) | 2,700 to 22,000 | 0.12 to 1 |
| Body hit white (one body about 40 by 90 px) | 3,600 | 0.17 |
| Head flash | under 1,500 | 0.07 |
| Guard flash | | 0.2 |
| Guard break ring | about 900 | 0.04 |
| Double hit's disc, a charge's thin ring | 2,500 and 600 | 0.12 and 0.03 |
| Explosion flame burst (a blast radius of 40 to 200 units) | 3,000 to 80,000 | 0.14 to 1 |
| Transformation break flash (1.7 bh across) | about 80,000 | 1 |
| Beam white core, beam clash flare | Rendering's | 1 (default) |
| Camera's dip, a panel | the whole frame | 1 each (they must ask) |

**The host call.** Sizes need the camera's scale. The hub has `px_per_unit` (pixels per world unit at 1024 by 768 on the fighters' plane; default 1.3, the close framing). The host should set it every frame from the camera: `host.vfx.px_per_unit = 768.0 / (the visible world height at the fighters' plane)`. Until it does, every area uses 1.3, which over-weights a flash in a wide shot and under-weights it in a close-up.

**The honest limit.** This makes the register limit something closer to what the analyser measures, but it cannot see scenery sweeping past a moving camera, a panel wiping open, or a whole-screen dip unless the system that makes it asks for it. Camera's dip and panel and Rendering's beam have to ask with an area and a step. The analyser on the required clips stays the test.

**What it did to play** (hash_check, seeds 12345, 4 and 7, six VFX runs each: the by-source line, granted/refused, before the weights and after):

| Source | Before | After |
| :-- | ---: | ---: |
| body_hit | 730 / 2,966 | 1,780 / 1,916 |
| block | 145 / 455 | 310 / 290 |
| head_flash | 50 / 466 | 280 / 236 |
| guard_flash | 47 / 1 | 32 / 16 |
| explosion | 118 / 56 | 138 / 36 |
| shot_hit | 5 / 37 | 5 / 22 |
| beam, transform, cue_flare, beam_clash | 35/1, 70/2, 10/2, 12/0 | 35/1, 70/2, 10/2, 12/0 |

The body's white on a hit is granted 48% of the time (it was 20%), blocks 52% (24%) and head flashes 54% (10%); explosions are granted a little more often, and the worst second in the real matches reads a weight of 2.48 (budget 2.5) and at most 6 flashes. A mash's body white is still refused about half the time: the ceiling of six flashes a second, the 1.5 low-priority share and the hit rate of the AI are what bind.

## The log, for Tools and for UI

`hub.flashes.log` has a row for every ask: `{now, tick, source, granted, why, in_window, weight, sum}` (weight the flash's weight, sum the running sum of weights in the window after it), newest last, the last 2,400 asks. `log_rows()` returns them as arrays `[now, tick, source, granted, why, in_window, weight, sum]` for a script. `why` is `ok`, `budget`, `cap`, `low_priority`, `reduced`, `red`, `below_step` or `unregulated`. `summary()` gives `granted`, `refused`, `worst_second` (counted from the log), `worst_running` (the running figure over the whole run), the counts by source and the cap in force. The log is per match and is cleared by `hub.reset`. Tools can run the WCAG 2.3.1 check over recordings and read this log beside it: the log says what the effects asked for, the check says what the pixels did.

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

## What the pixel analyser found in VFX's drawing (2026-10-06)

Tools' frame analyser (docs/tools/flash-check.md) plays the real web build in headless Chrome at 1024 by 768 and counts opposing luminance changes of 0.10 or more over a quarter of a 341 by 256 window. Rendering switched layers off to attribute: two of the failures were VFX's, and neither was a flash the register could count.

1. **The broad grey band (AI seeds 4 and 12345).** A crater's shock ring (`blast.gd` `_ring`, a flat ring on the ground) scales with the crater: at tier 3 or 4 it is over a thousand units across, and the ground-ring shape drew a band 32% of its radius thick at 0.9 alpha in light dust colour, a pale band across a quarter of the screen that rose and fell in half a second. With VFX off the band is gone (Rendering). Fix, in `shard_view.gd` and `shard.gdshader` (nothing on the held files): a flat ring's band is at most about 70 units thick (`ring_w = 35 / radius`, 0.02 to 0.16) and it is fainter the wider it is (`alpha *= 500 / width`, not below 0.12), so a big ring's step stays under 0.10. Cost to the look: a small ring (under 500 units across) is as it was; a big crater's ring is a thin pale line, not a band.
2. **The transformation's whole-screen dim (AI seed 12345 around ticks 582 to 612).** `transform_view.gd` draws "the light around him dims" as a soft dark disc of 6 bh radius (about 1,170 px across) at `dim_alpha` 0.32 through the gather and takes it away within 4 ticks of the break: a whole-screen pair of opposing changes. The change is in the data VfxTransform reads, not in the held view: `dim_alpha` 0.32 to 0.16 (`data/vfx/transform.json` and the default in `transform.gd`), which puts its step under 0.10 against a mid-tone background. Cost to the look: the gather's dimming is half as dark. (Reduced motion already halves it again.)

**Results**, Tools' `check-clip.mjs` on a web export of HEAD 8d4e6ee3 plus VFX's change, normal and reduced, gate 2.5:

| Clip | Before | After |
| :-- | :-- | :-- |
| ai-12345 normal | 4.5 (tick 3290: a shot-hit flash, an explosion and the band) | **2.5** |
| ai-12345 reduced | 4.5 (Tools' table) | **2.0** |
| ai-4 normal | 3.5 (Tools' table; Rendering reproduced it) | **2.5** |
| ai-4 reduced | 2 (Tools' table) | **1.5**, one whole-screen dip at tick 620 (45% of the frame, mean luminance 0.256 to 0.156), not traced |

The largest single window in these clips still reads 400% of the limit (a camera or scenery change the count does not weigh), so a pass is at the gate, with no margin.

## A beam on a cliff face: the column of needles and the dust (ai seed 1 normal, ticks 2147 to 2181, 2026-10-11)

Tools' recount read 4 / 4 / 3 there (primary / area-15% / two-second memory). I reproduced it from a HEAD export (`capture-web` ai seed 1, 2,200 ticks) and took the layers apart by switching them off in scratch exports:

| Variant | Primary reading, whole clip to tick 2200 |
| :-- | ---: |
| as built (HEAD d70dc706) | 4 (at tick 2147) |
| VFX off altogether | 2.5 |
| earth flames off (`VfxEarth.on_fire`) | 4 (the needles are not those) |
| scorch embers off (`VfxDebris.embers`) | 3 |

So the "ground-flame needle column" is the **scorch's embers**: a beam's landing makes 2 + 1.5 power of them every tick, each a 42 to 112 unit needle of the ember ramp, up to 100 alive (`EMBER_CAP`), bright orange on a dark cliff. A fast camera pan (Camera's governor lets scenery cross 0.045 of the width a tick) moves every needle edge at once, so the column's own pixel area becomes the change. The beam's dust (a ring of tan puffs, up to 240 alive) does the same on the sand beside it. At tick 2182 with VFX on, 45,000 pixels changed by 0.10 or more in one tick against 16,000 with VFX off (the terrain's own edges).

What I did (render/vfx only, data in `vfx_look.gd`): the register's area threshold is the unit.
- **Embers:** `VfxLook.EMBER_AREA_SHARE` 0.4: the needles alive may cover at most 0.4 of 21,824 px (at the hub's `px_per_unit`; half of that under reduced motion or reduced flashing). A scorch past it makes fewer needles that tick, so the column keeps its shape and thins.
- **Puffs:** `VfxLook.PUFF_AREA_SHARE` 1.5: the puffs in the pool, at their widest, may cover at most 1.5 of the threshold; a new puff past it is not made (`VfxDebris._add`), the old ones fade as before.
- Both caps are in screen pixels, so a wide framing is not thinned and a close one is. The effect tests that count puffs and needles run at a mid-wide framing (`px_per_unit` 0.3 to 0.6) for that reason.

Result (`check-clip`, my tree, normal): see the table in the report; reduced was already thinner and reads 2.5.

## Collapse's first blast (collapse scene, seed 12345, ticks 84 to 144; 2026-10-13)

Camera isolated it at 2.0 / 3.0 on a held camera and asked for the debris and dust under the line on a still camera. Same commit (91b3722f), `capture-web` through the guarded launcher (tag vfx, one capture at a time, 8 to 11 frames a second), 200 ticks, and the layers switched off one at a time in a scratch export:

| Variant | Normal: primary / area-15% | Reduced: primary / area-15% |
| :-- | :-- | :-- |
| as built (before) | 2.5 / 3.5 | 2 / 2.5 |
| all of VFX off | 2.5 / 3.5 | 1.5 / 2.5 |
| stage layer off | 2.5 / 3.5 (109+ at 3.9x gone) | |
| **after** | **2.5 / 3.5, with 109+ at 2.0x (was 3.9x) and 158+ at 1.6x (was 2.9x)** | **1.5 / 2.5** |

(200 ticks a clip, so the two-second memory reading is not meaningful and is left out; both sets are the primary reading of the analyser's current combined rule.)

- **The events at 84+, 91- and 94+ (2.5 to 2.6 times the threshold) are not VFX's.** They are the same with every VFX layer off: at tick 91 a quarter of the frame goes dark (257,000 pixels, 11 times the threshold) and at 94 a seventh comes back (103,000): the camera's cut at the blast. The 84+ is the start of the analysed window. They set the primary and the area-15% reading; nothing on my side moves them.
- **What was VFX's** was the stage layer's: five towers change stage in the same tick, and each threw up to 24 cladding slabs of 45 to 112 units (grey boulders of 30 to 80 px) and up to 20 glass slivers, and the window blow-outs of the crater (10 buildings, 6 rows, 8 slivers) followed for 40 ticks. Changed pixels a tick above the no-VFX baseline: tick 109 +24,600 before, +11,200 after; tick 120 +23,300, +12,200; tick 158 +40,800, +14,200.
- **What changed** (data and layer, nothing in the held files): the stage events are drawn nearest first and the rest follow two ticks apart up to 12 (`stagger_ticks`); two towers at full strength (was six), up to six at 0.4 (was twenty); slabs at `0.75 + 0.12 x width` scale (28 to 70 units; were up to 112), cladding counts halved (`shed_big` 12 to 6, `shed_small` 6 to 3), glass 5 to 10 (was 8 to 20), the spend budget 300 to 160; stage glass and slabs live 0.7 to 1.3 and 0.9 to 1.5 seconds (were 1.0 to 1.9 and 1.2 to 2.2); glass at 0.75 alpha; a puff fades in over `0.06 + size / 2500` seconds (fix c of docs/vfx/windows-bc.md); the crater's window blow-outs are 4 rows (was 6) of 6 buildings (was 10) at 0.6 scale (was 0.8) and 0.7 to 1.3 seconds.
- **Not mine, for Rendering:** the concentric orange and pale rings (up to 5 at once, 270 px) and the brown squares at ticks 100 to 125 are Rendering's own (they are drawn with VFX off), and the cut at 91 and 94 is Camera's.

## The reserve for the big flashes (2026-10-13)

In the nine-cells chain (Encounter's parked chain on main 996bf933) the headless flash count failed on one run: AI normal, seed 7, 2.50006 of weight from tick 2939: a beam (1.0), its cut-in panel (1.0), a beam clash (0.4751) and a head flash (0.0249) granted at 2.5001, because the register's tolerance on a sum was 0.0001 and the check's is 1e-6. The four are VFX's register's to order, and the order was wrong: a gameplay flare (the clash) and a head's icon pulse took the last of the budget in whatever order they came.

- **Rule** (`flash_registry.gd`, `RESERVE_BIG` 0.5): in a normal second the low-priority sources (energy, block, shot hit, mine, guard break's ring, body, head and cue flashes, the divider's slam) and Camera's cut-in panel are not granted past 2.5 - 0.5 = 2.0. The big gameplay flashes (a beam's core, a clash, an explosion, a transformation, a perfect block's guard flash) fill to 2.5. The tolerance on a sum is 1e-6 (the check's). Reduced mode is unchanged (one weight-1 flash fits; its low class is none).
- **Who gives way:** the head's pulses first, then the cut-in panel if a clash or a beam has come first (Camera draws no panel when refused), never the clash. Seed 7: beam 1.0, panel 1.0, clash 0.4751 granted (2.4751) and the four head pulses refused.
- **What it costs:** a mash of body hits alone never passes 2.0 of weight in a second (it used to reach 2.49); on main's four seeds body hits are granted 53% of the time as before.
- **The margin:** the small sources end 0.5 under the gate by construction. Three big ones can still sit near it (a beam, a panel and a clash is 2.4751, margin 0.025): the clash's weight is Rendering's `clash_px` and the panel's is Camera's, so a margin beyond that is theirs to give.
- **Readings** (headless flash count, 56 runs each): main with this change passes, worst 2.34 (ai seed 43); the chain with this change passes, worst 2.48 (ai seed 7, the three big events), from 2.50006 and a FAIL.

## ai seed 38, ticks 3484 to 3494: a landing's world burst (2026-10-13)

Tools' three-arm table had the clip at 4 / 5 / 3 normal and 4 / 5 / 2 reduced from tick 3484. Pinned commit 7b0d03cf, then 38eaaf8d (the clip reads the same on both); `capture-web` ai seed 38, `--skip 3380 --ticks 190`, session vfx, one capture at a time, about 5 frames a second:

| Arm | Primary / area-15% (normal) | The four events (clip frames 106-, 107+, 112-, 114+) |
| :-- | :-- | :-- |
| as built | 4 / 5 | 1.7, 1.8, 1.3, 1.4 times the threshold |
| each VFX layer off by switch (one at a time) | 3.5 / 4 | 1.7, 1.8, 1.2, 1.4 |
| the whole VFX hub off | 3.5 / 4 | 1.7, 1.8, 1.2, 1.4 |

- **The four are not VFX's**: they are the same, to a tenth, with VFX off. The sim sends one `slide`, `tumble_end` and `journey_end` at 3482 and VFX makes 10 bits from it. What is on screen is the terrain's own deformation: a dark triangular shadow (the dune's wall lit and shaded as it is pushed) sweeping 300 px across the ground, tick by tick; that is Rendering's ground shader reading the sim's deformed heightfield.
- **VFX's share is a half point**: 4 against 3.5. It is the leftover of the crater made at 3384 (98 chunks and 15 puffs in the air, 80 to 120 chunks alive from 3384 to 3510), which adds 130-, 139- and 143+ in the window.
- **What I changed** (counts and lives, nothing removed): a crater's ejecta at most 16 chunks (was 30) living 0.9 to 1.5 s (was 1.0 to 2.0); the blast's rim chunks 3 (was 4), at most 12 (was 18), living 1.0 to 1.6 s and 1.6 to 2.4 s lobbed (were 1.2 to 2.0 and 2.0 to 3.0); the second fall 4 pebbles (was 6), at most 12 (was 20); a `debris` event at most 10 chunks (was 14). Result on the same commit: 139- gone, 143+ from 1.8 to 1.4 (reduced 1.4 to 1.1), reduced area-higher 4 to 3.5; the primary stays 4 and the area-15% 5. A further round (dust counts and lives, the dome and the bowl's settling) changed nothing counted and was dropped.
- **NEEDS (Rendering):** the deformation shadow at 3482 to 3494 is a 1.3 to 1.8 times threshold change four times in 12 ticks with no VFX in it; to bring the clip under, that sweep has to ease or stop alternating (a shadow that grows over 0.5 s and is not redrawn each tick).

## The chain's last three failing seconds: whose they are (2026-10-14)

Pinned to 3198301f; Tools' path (`capture-web`, session vfx, one capture at a time, camera switches off, 1024 by 768, `--skip` then 120 to 160 ticks, tick = skip + frame). Each clip taken as built, with the whole hub off, and with layers off in groups by a scratch URL switch (`?off=`; not in the tree). A layer off also puts Rendering's own stand-ins back (`ejecta_marks`, `water_marks`), so "hub off" is not zero.

| Clip (ticks) | As built (primary / events, times threshold) | Hub off | What is VFX's |
| :-- | :-- | :-- | :-- |
| ai 4 normal (2505-, 2506+, 2521-, 2522+) | 4.5: 64+ 1.0, 65- 1.6, 66+ 1.8, 71- 1.0, 72+ 1.5, 81- 1.2, 82+ 1.2, 88- 2.2, 95- 2.1, 113+ 1.5, 151+ 2.0 | 3: the same four at 1.6, 1.7, 1.2, 1.1 | **None of the four.** 64+ and 71- (each 1.0, borderline) are the earth layer's chunks (earth off removes both, 4.5 to 3); 151+ is the ground cracks (cracks off: 154+ 1.6) |
| ai 4 reduced | 4: 65-, 66+, 71- 1.0, 72+, 81-, 82+, 85- 3.0, 95- 2.1, 106- 1.6, 120+ 1.2, 151+ 1.8 | 2.5: the same four, 85- 4.0, 106- 1.5, 154+ 1.3 | 71-, 120+ (earth off removes both, 4 to 3); 151+ (cracks off: 152+ 1.4). Primary of the clip with the hub off is 2.5 with the area-15% run at 3.5: it fails without VFX |
| collapse reduced (1137: ticks 57 to 117 of the clip from 1080) | 3: 64+ 1.4, 76+ 2.8, 89- 1.1, 90+ 1.2, 93- 1.1, 100- 1.5, 104+ 1.1, 108+ 1.3, 116+ 1.1, 118- 1.3 | 3: the same set, 113- 2.4 where VFX has 116+ and 118- | **None.** The second's changes are the world around the grounded fighter; VFX adds nothing counted |
| ai 39 reduced (2741) | 3: 62+ 1.7, 66- 2.7, 70+ 1.4, 72+ 2.3, 75- 2.3, 111+ 1.1, 116- 2.4 | 3: 62+ 1.4, 65- 2.9, 70+ 3.1, 75- 2.4, 110+ 1.4, 120- 1.1 | **None.** VFX splits the world's 3.1 at tick 70 into 70+ 1.4 and 72+ 2.3 (cracks, aura and rocks off put the 3.2 back); the primary is 3 either way |

- **Why the four are the world's.** With the hub off the frame changes by 41,800 pixels at 2505 (down), 44,900 at 2506 (up), 38,200 at 2521 and 42,200 at 2522: about two window thresholds each, across the whole frame, every one of them terrain and camera. At 2504 the hub-off frame changes by 15,400 pixels (0.7 of the threshold, counted over the whole frame) and the as-built one by 21,200; the earth layer's 4,600 are what carry 64+ to 1.0.
- **Where VFX is a real share:** 64+, 71-, 120+ and 151+ above: four events, none above 2.0, all within 0.2 of the line or on a world event already there. Each flips with any one change (a layer off, a chunk less), so there is no margin to be had by spreading: a cut that removes one lets another cross.
- **Tried, measured, not kept.** A pool cap on the earth chunks' drawn area (a share of the register's area threshold: ambient chunks stop at 0.7 of it, a crater's own at all of it) took 64+ out of ai 4 normal (4.5 to 4) and 116+ out of collapse reduced and moved nothing in ai 4 reduced and ai 39; exempting the crater's own chunks (so tier 3 and 4 craters stay different at the close framing, which `effects_check` asserts) puts 64+ back. Parked as `docs/vfx/pending/chunk-area-cap.patch` (the exempt version, a diff against 3198301f with its test, inert on these four clips); not applied.
- **NEEDS (Rendering and World):** the whole-frame changes at ticks 2505 and 2506 (38,000 pixels) and at 2521 and 2522 are the ground's deformation shading and the camera's travel over it; VFX's layers do not move them (identical with the hub off). The reduced clip also fails with the hub off.

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
