# Reading the charge stages without anything over the fighter (UI & UX, paper, 2026-11-01)

For the EP's ask: charge stages run from 2 at base up to about 6, and the player must read the stage they are at, and the foe's, with nothing drawn on or over a fighter (ADR 0010). **Paper only; nothing built.** Game Design's page is not ready, so the numbers below are placeholders and the open questions in section 6 go to them.

## 1. What the screen has to say

Three facts, in this order of urgency: **which stage I am at** (so I know when to let go), **how many there are** (2 to 6, so the last one is obvious), and **which stage the foe is at** (so I can decide to guard, dodge or hit him first). The first two are for the person charging; the third is for the one answering, and it is the one that matters most to the fight, because a charge that cannot be read cannot be answered.

## 2. Where it can live (the edge, never the body)

| Home | Reads as | Why it is safe |
| :-- | :-- | :-- |
| **A segmented ring round the pressed button's glyph in the legend** | N equal arcs, filled one at a time | It is the ring already specified for the Y and B wind-up (hud-spec, "The wind-up and charge cue"), now cut into N arcs instead of one smooth fill. In the legend, at the screen edge |
| **A stage ladder on the plate** (the charging fighter's own, so the foe's too) | N short bars in a row, the reached ones solid, the current one filling | The plate is the edge column for each slot, so the foe's stage is on his plate, in his corner. It shows only while he charges and goes in one cut when he lets go |
| **A word in the legend row's note**, "Stage 3 of 6" | text | For players who read words and for captions; it is also what a screen reader would be given |

What UI does **not** do: no ring, bar, number or marker near either body. The fighter-side read (the glow and bulk of the charge growing by stage) belongs to VFX and Animation, as a shape and size change the player watches without looking at the edge. UI's ladder is its readable twin, which is the same split as the Y and B ring.

## 3. How the ring and the ladder are drawn

- **Segments, not a smooth fill.** At 6 stages each arc is 60 degrees less a 6 degree gap. On a 24 px ring (1280x720) that is a 12 px arc, which reads; at 2 stages each is a half. The current stage fills inside its arc, so the player sees progress to the next click as well as the click.
- **Shape, not colour.** Reached stages are solid; the current one is striped as it fills (the plate bars' existing striped look); stages not reached are an outline. The last stage carries a notch on its arc so "the top one" is a shape.
- **A cut at each stage** (no fade, no pulse): the arc becomes solid on the tick the stage is reached. One short flash at the top stage, with the same single-frame rule as the full-charge flash (the flash analyser's count applies; nothing above 3 a second, never a large area).
- **Reduced motion:** the current stage fills in quarters; the top stage is a steady solid ring.
- **The ladder on the plate** reuses the plate's bar row (the one that shows charge today): it swaps the smooth ki bar's tick marks for N stage bars only while a charge is going, and puts the bar back on release. No new row, so the plate does not grow.
- **The foe's ladder** is drawn the same way on his plate, as soon as he starts to charge, so the answer is learnable from the first fight.

## 4. What it needs from the sim (a cue; UI reads, never writes)

`charge_stage {actor, cell, n, of}` once each time a held charge reaches a stage (`n` the stage reached, 1 to `of`), and once at the start with `n` 0 and the `of` for this fighter's tier. Today the stick has `stick_charge` (a charge starting, level 0) and a level rises with no cue of its own; the Y and B windup has its `full`. One cue for all charges, rather than three, is the cleanest: the hub keeps `m.charge_stage` and `m.charge_of`, the same fields serve the ring and the ladder, and the rival's plate reads them the same way. `of` changing with the tier (2 to 6) is just a new number in the next charge's first cue.

## 5. Companions that are not UI (asks, not work for me)

- **Audio:** a tick at each stage, higher each time, a different top-stage sound (a sound cue for the player who is not looking at the edge). Captions: "Charge stage 3 of 6", off by default as the other captions.
- **Controls:** a short pulse on the player's own pad at each stage (the haptic mapper has the kinds; this is one more).
- **VFX / Animation:** the fighter's body growing with the stage, so the foe's stage can be read in the picture. That is the main read for most players; the ladder is the exact count.

## 6. Questions for Game Design

1. What is a stage: a fixed time rung (like the stick's levels at 0.2 s, 0.5 s), or an energy cost spent as it climbs? If it costs energy, the ladder should show the stage the player can still afford, not only the one reached.
2. Is the number of stages set by the tier alone, or also by which charge it is (the stick, B, the beam, powering up)? If powering up has stages too, it needs its own name ("Power stage") so the two ladders are not confused.
3. Can a stage be skipped over or lost (a hit stopping a charge at stage 2: does it drop to 1, or end)? The ring would show a loss with the existing grey `lapsed` mark.
4. Is there a stage worth holding for (a sweet spot) other than the top? If so, it gets the notch, not the last arc.

## 7. Cost and checks

About a day and a half: the cue and hub fields (half a day with Encounter's cue), the ring and ladder planners (static, testable), reduced motion, the foe's ladder, the strings and tests. Checks for hud_check: the ring and ladder planners at N = 2 to 6 at the six screen sizes and both slots, every rect clear of the fighters' anchors (the chip-clearance check), the plate not growing, the flash count, and reduced motion steps. Off-switch: `charge_stages` in `features.json`, off until the cue exists.
