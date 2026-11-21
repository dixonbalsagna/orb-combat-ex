# Parked: a catch holds him up, and a tap at his landing lands as he gets up

Encounter, 2026-11-02, on Game Design's latest `docs/design/power-scale.md` section 4 ("the chain" rows: at base, and a tap that reaches a landing). **Behind the chase tap's own switch:** `data/director/interrupts.json` `chase.tap.enabled`, off. It changes what that park does; nothing else.

**Apply on the stack after `../chase-tap/` and `../chase-ease/`,** before or after the six press-decides parks: it applies either way. `git -c core.autocrlf=false -c core.eol=lf apply chase-air.diff`.

## What it does

| | The chase tap before | Now |
| :--- | :--- | :--- |
| **After a catch** | He flies however long the planner's send takes: a low catch could land him in 12 ticks | **At least `minAirTicks` 40 live ticks in the air, unless B drove him down.** His flight is paced along the path the planner gave it, so where he goes, what he hits and where he lands don't change. A hit's hang, not more energy |
| **A tap that reaches his landing** (he came down first) | The blow lands as he lands, through any guard | **It waits for him to get up, and lands then as an ordinary blow he can guard.** Up to `riseTicks` 60 after his get-up starts |
| **The same on the meteor's curve** | Flies to the landing, and nothing, "for the first move" | **The same blow as he gets up.** It replaces "for the first move" and stands in for the apex spike, as ruled. The meteor's fallback stays: every tap on the curve goes to his landing |
| **He got up out of reach** (a crater's bounce carried him off) | | The chaser rushes to him, in `riseRushTicks` 20 at most, and the blow lands as he arrives, so the follow-up always hits something |

The hang is the player's chase only, like the rest of the tap. The AI keeps its own chase.

## Read

`chase_tap_check`, on an idle dummy:

| | Read |
| :--- | :--- |
| A short send down, with and without the hang | 12 ticks in the air plain, **42 with it**, landing 5.6 units from where it would have |
| The hang asked for B's drive | None: 12 ticks, as plain |
| After a real catch | 129 ticks: a long send needs no hang |
| A heavy tap that reaches his landing | Waits through his down time, lands as he's up: 140 taken |
| The same with him guarding as he gets up | 48 taken |
| The meteor's curve | He bounced off about 3,000 units; the chaser rushed to him and the blow landed as he was up |

## Grants

None: every line is mine (`chase_tap.gd`, `chase.gd`, the arc director's step, my data and schema). The hang uses the arc director's step, the core's hook for a launched body, and steps his physics at a slower pace from there.

## Not done

- **The look gate.** A body paced to 30% speed for 40 ticks reads as a hang, but nobody has seen it, and it changes what the player sees: it needs the side-by-side before it goes on the page.
- **Camera's chase jolt.** The hang changes the catch's arrival. Camera's jolt read (0.11 near the catch with the energy model on) should be taken again with this on.
- **The landing isn't exact.** A smaller physics step lands him a few units off the planner's forecast (5.6 in the check). Nothing checks building contacts at the edge.
- **With the flight curve on** (`data/fight/flight.json`, off on main and on the page), the curve paces by ticks, not time, so the hang's timing is approximate there.
- **QA's arm.** Game Design's aim is 2 or 3 catches at base and 3 or 4 at the top, as ki allows; that needs a player script that chases.
