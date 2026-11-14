# Parked: a match ends each of the three ways, on the data's own switches (A-MODES-07, acceptance 2)

Encounter, 2026-11-14, sprint A1. **A check only: nothing in the sim changes.** It reads the ending from `interrupts.json` (`ending.enabled`, on with the 9 November rows in GW1a) and forces nothing. Each match is played to its end on planet 7, as the build plays it.

| Way | The match | What it asserts |
| :--- | :--- | :--- |
| **A finishing move** | two computers fight | one falls to a finisher (a `finisher_start` before the KO), before the cap, and never to the HP bar |
| **Wear on an idle player** | a player who touches nothing against a computer | he's opened on the brink and falls to the computer's finisher |
| **The last event after the time cap** | two players who keep moving but never fight, one with more wear | play goes on past the cap to `lastAt`: the one with less wear gets his finisher, with no contest, and the other falls |

## The reading (main def3445a + the 37 director rows, `../director-rows/rows-all.patch`)

`MATCH END: 0 check(s) failed`, 4 checks. Records are in `docs/director/runs/def3445a/match-end-check/`.
- The ending is on in the data.
- **Two computers, seed 21:** the match ends 11.5 minutes in (ticks, freezes included) by a finisher, before the match clock's cap.
- **An idle player against a computer:** opened on the brink and felled by its finisher, but **12.2 minutes in, after the cap.** The computer took that long to finish a fighter who never touched the pad. So on this data the idle rule doesn't end a put-down pad's match before the cap. That's a finding for Game Design: is `idleWearMul` and `pushSec` doing what was meant? The check passes it, since it asserts the route, not the time.
- **Two players who never fight:** the cap at 11.0 minutes, then the last event at 12.1, and the one with more wear fell.

The exit prints the planet setup's known "7 ObjectDB instances leaked" warning, as `power_check` and `two_states` do.

## Apply

On main: `git -c core.autocrlf=false -c core.eol=lf apply match-end-check.diff` (the new file `sim/director/tools/match_end_check.gd`). On main's data today its first row fails by design (the ending is off). It passes once the director rows land.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `match-end-check.diff` | Encounter | 8f782399a78923592ce7618e6747644fb8b9401d |

## NEEDS FROM EP

- **Game Design:** the idle player's match ends only after the cap (12.2 minutes against the computer).
- **Tools:** CI after GW1a. It takes about 3 to 6 minutes (three matches to their end), so the landing gate only might suit it better.
