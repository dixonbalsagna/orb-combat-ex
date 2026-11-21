# Parked: the chaser carries his speed through the catch

Encounter, 2026-11-02, on Camera's tick trace: at a top-power catch the chaser went from 10,175 units a second to 0 in one tick (tick 76), and that stop was the jolt near the catch. **Behind the chase tap's own switch:** `chase.tap.enabled`, with `chase.tap.carryTicks` 8 (0 turns the carry off).

**Apply after `../chase-air/`:** `git -c core.autocrlf=false -c core.eol=lf apply chase-carry.diff`. On my stack it follows `../swing-pair/`, but it touches none of its files.

## What it does

At a tap chase's catch, before the blow sends the body on, the chaser keeps the speed he caught him at, read from this tick's step of his rush. It eases down over `carryTicks` live ticks, falling as (1 - t)², and stops early if a rush or a state that isn't free takes him. It's capped at the tap's `maxSpeed`. The AI's chase doesn't use it.

## Read

`chase_tap_check`, a tap chase after a send, the chaser's speed on live ticks around the catch:

| | Units a second |
| :--- | :--- |
| Before | 8,671, 9,752, **11,892 at the catch,** then 0 |
| With the carry | 8,671, 9,752, **11,892, 9,105, 6,689, 4,645, 2,973, 1,672, 743, 186,** then 0 |

No live tick falls by more than 2,787. The blow's own hit-stop still holds everything for its ticks, as every hit does.

## The hang's pace, and a floor for it (2026-11-02, from Tools' film)

Tools' track shows both bodies drifting at 170 to 210 units a second for ticks 472 to 498 after a catch. **That's chase-air's hang as written, and my "about 30%" in its README was wrong.** The hang paces his flight so the planner's path takes `minAirTicks` + 3. So its pace is the send's own time over 43 ticks: 30% for the check's 12-tick send, but **about 2% after a low catch whose send would land in a tick**. Both bodies then sit almost still while the next catches land: Game Design's "small fight in the air", which can read as a stall.

**`chase.tap.hangMinPace`, 0 as ruled:** above 0, the hang's pace never falls below it, and a send too short for `minAirTicks` at that pace hangs for less (at 0.25, a 1-tick send hangs 5 ticks). It's for Tools to film both, and Game Design's to rule, since it gives up the 40 ticks for the shortest sends.

## Not done

- **Camera's re-read** with the energy model at top power: chase_rush_check's jolt near the catch.
- **The look.** In the check the chaser drifts about 430 units past the catch point, from 11,892 units a second. Nobody has seen it, and it changes what the player sees, so it needs the side-by-side before it goes on a page.
