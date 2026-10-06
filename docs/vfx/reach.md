# Energy arts in reach, and the launcher's marks (2026-10-06)

Owner: VFX Director. For Orb's fourth test, "do energy attacks look cool as part of close-range combos?", and the third, "can I reliably launch my opponent?" (docs/design/brawl-second-pass.md §5b and §3). Built ahead of the sim against staged cues; presentation only (no sim write, no random number, the gameplay hash unchanged). `render/vfx/reach.gd` (state, the flash limit), `render/vfx/shots_view.gd` `_reach` (drawing), wired in `vfx_hub.gd` as `inreach`, behind the press flag. Legal's rulings: docs/legal/launcher-and-reach-screen.md, movegen-banned.json (f01, k03, k04, k05, e06, e08).

## The cue names I assumed (Encounter: match these, or tell me yours)

| Cue / event | Fields | What VFX does with it |
| :-- | :-- | :-- |
| cue `energy_reach` | `actor` the firing slot, `target`, `text` `bolt` or `blast`, `amount` the wind-up ticks (2, 12), `n` the contact tick (absolute), `x` and `y` the stick's lean | The lit palm (bolt) or the gather (blast) |
| cue `energy_land` | `actor`, `target`, `text` `bolt` or `blast`, `source` the outcome `hit`, `guard`, `armour` or `miss`, `x` and `y` the lean | The landing, the rim, the spill, the scorch, and the carry for a clean blast |
| cue `stagger` (exists: Encounter's brawl) | `actor` the staggered fighter, `target` the attacker, `text` the cause, `n` the ticks | "B now" when `n` is 12 or more |
| event `launch` (exists) | `actor` the launched fighter, `target` the attacker, `ux`, `uy` | Ends "B now" and draws the send-off |
| beat args `strength`, `windup_ticks`, `charge`, `full`; cues `charge_full`, `double_hit`, `burst` n | as planned in brawl-three-strength-plan.md | not built yet |

The fist's own blow still comes from the `damage` event and its press look (the smear and the contact), so a bolt is a blow and a shot at once and a mixed string reads as two instruments.

## What is drawn, point by point against §5b's list

1. **The hand is lit before it lands.** A bolt: a small hollow ring with a darker edge and two short streaks forward on the lead hand, for its 2 ticks (4 quads). A blast: a thin ring closing onto the palm over the last 10 ticks of its 12, with its edge, and three short streaks converging on it (5 quads); never a filled disc, never body-wide, one hand, at shoulder height or lower (the palm's place is Animation's real lead hand while a blow plays, else 26 units in front of the chest at height 50; the shoulder is 54).
2. **A blow and a shot at once.** At the contact: a hard crack (two crossed lines, each a dark core with a light glow: 4 quads), a hollow widening ring, and, when the flash limit allows, one soft flash that shrinks as it fades over 3 ticks (38 units for a bolt, 56 for a blast), on the contact and not on the hand.
3. **Both bodies are lit.** For 3 ticks a thin edge line on the near side of each fighter, in the shot's colour (2 quads), never over the body.
4. **The spill.** Streaks flying on along the stick's lean: 2 spark streaks to 2.5 bh for a bolt, a cone of 5 to 6 bh for a blast, and a scorch (a flat dark soft ellipse, 150 ticks, at most 6 alive) where the line meets the ground; drawn only. On a guard nothing spills.
5. **The blast carries him.** The shot's colour trails off his chest along his real path for 10 ticks (5 segments), then smoke puffs from him for 24 ticks (the debris pool's smoke).
6. **A mixed string reads as mixed.** The fist keeps the press look; the bolt adds the crack and the flash.
7. **Each fighter's own.** The colour is the fighter's lane colour (cyan, violet). The Protagonist's palm heel and the rival's blade hand are Art's and Combat's; this draws from whichever lead hand Animation reports.
8. **A mashed bolt must not strobe.** See "The flash limit".

**The launcher.** "B now": a stagger of 12 ticks or more draws one chevron on each side of the staggered fighter, rising through the stagger half a beat apart, in the attacker's colour with a light edge (8 quads); no words, no flash, and a shove's 8 ticks draw nothing. The send-off: a trail along his real path for 12 ticks, a flat ring on the ground where he left it and three short streaks lifting off.

## The flash limit (Legal's k05 and §5b point 8)

**Update 2026-10-06:** the energy flash now asks the shared flash registry (`hub.flashes`, docs/vfx/flash-registry.md) as the low-priority source `energy`, on top of its own 1-in-20-ticks pace; the description below is the first version of that rule, kept for the recording it was made against.

One full flash is the soft disc at a landing. The counter (`VfxReach.allow_full`) gives one only when:
- at least 20 ticks have passed since the last full flash, across both fighters; and
- the hub's flash log holds fewer than 3 flashes in the last 60 ticks. The log counts every energy full flash and every block flash (the press styles' block flash reports to it, `VfxPress.flash_sink`).

Reduced motion gives no full flash at all (the half the rule allows would be 1 and a half a second; none is under it) and the rim is dimmer; the crack and the ring stay. The rest of a mash gets sparks at the contact.

**What the counter guarantees.** In this hub, no 60-tick window holds more than 3 energy-or-block full flashes, whatever the press rate or the number of fighters mashing; each full flash is a disc of at most 56 units (38 for a bolt) in the shot's lane colour lightened by 0.3, 3 ticks, at most 0.42 alpha, never red; none in reduced motion. `effects_check.gd` `_reach()` asserts it on 30 mashed bolts and on the block case.

**What it does not guarantee.** It does not count flashes from other effects (explosions, a signature's flash, a transformation, a hit's contact ring). It does not measure what is on the screen: a photosensitivity analysis (area, luminance change, red) is an accessibility check VFX cannot run, and the recording's luminance figure below is a crude aid, not that analysis. It does not know the real cue rate: the sim's cues do not exist yet, so the recording is staged at the rate the design allows (an X flurry's 6 ticks), and QA must count again on the sim's own cues. The press styles' own flashes (the block flash aside) are not yet routed into the counter: the way to close that is one shared flash registry in the hub that every effect calls, which is a larger change than this slice.

## The recording Legal asked for

`img/er-mash-sheet.jpg` (every tick of a 3-second mashed run, ticks 300 to 479 left to right and top to bottom, a white frame on each tick that gave a full flash) and `img/er-mash-log.json` (the counter's log and the luminance of each frame). Both fighters fire a point-blank bolt every 6 ticks, the second 3 ticks behind the first: 30 bolts in 180 ticks. Frames captured one tick at a time from the web build (the page held between ticks and stepped once per capture), crop of 160 by 100 units round the two fighters, scratch stage hook.
- Counter log: 9 full flashes, at ticks 302, 323, 344, 365, 386, 407, 428, 449 and 470 (21 apart): never more than 3 in any 60 ticks, which is 3 a second.
- The other 21 landings got sparks.
- Crude luminance check on the same crop (mean relative luminance, linear sRGB, Rec. 709): the biggest change from one frame to the next is 0.052 (0.236 to 0.433 range over the run), and no frame pair changes by 0.10 or more; one pair changes by 0.05 or more. The crop is a small part of the screen, so the full-screen change is smaller. This is not the accessibility analysis.
- The flash in the recording was drawn 0.25 lighter than the current code (the lane colour lightened by 0.55; now 0.3), so the recording is the brighter of the two.

## Quads and cost against the cap of 380

A bolt: lit 4, landing 8 (crack 4, ring, flash, and the rim's 2), spill 2 growing in. A blast: gather 5, landing 8, the cone 5, a scorch 1 for 150 ticks, the carry 5. B now 8. The send-off about 11. The busiest tick in the mash test (both fighters, a fist's press look each) drew 22 quads. No debris except the blast's smoke (about 8 puffs). No draw call and no pool: the same one draw of the shots view. CPU: a handful of float writes per quad; the scorch's ray walk is at most 45 ground reads once per blast.

## Stills (web build, headless Chrome, scratch stage hooks)

`img/er-bolt-lit.jpg`, `er-bolt-land.jpg`, `er-blast-gather.jpg`, `er-blast-land.jpg`, `er-blast-carry.jpg`, `er-stagger.jpg`, `er-launch.jpg`.

## What Legal must see drawn

The hand: `er-bolt-lit.jpg` (one lead hand, hollow, at the fist) and `er-blast-gather.jpg` (a thin ring at the palm, no ball). The flash: `er-bolt-land.jpg` (small, on the contact, lane-coloured, not red) and the mash sheet and log. The spill and the carry: `er-blast-land.jpg`, `er-blast-carry.jpg`. The launcher's marks: `er-stagger.jpg`, `er-launch.jpg`.

## Known weak spots

- The marks are pale against sand. If Orb says they are lost, a dark outline or a second tone is the fix (already done once for the rings).
- The palm is Animation's real hand only while a blow's pose is playing; otherwise an estimate in front of the chest, which can sit beside the drawn fist.
- The scorch is on terrain only; water and walls are not handled (the spec's sea and wall case).
- Staged: the stills and the recording use synthetic cues; the victim's carry in the stills is scripted by the hook.
