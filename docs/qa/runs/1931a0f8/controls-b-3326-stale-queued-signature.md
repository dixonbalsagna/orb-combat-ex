# Tick 3326 (B alone) with bNoBeam on: a signature B queued at tick 3297, before the flip (Controls, 2026-11-08)

Question (EP): the replay of Orb's 1714 file with the b-no-beam park flipped on at tick 3300 still starts a full signature exchange at 3326 (B alone, mode 0, act.mode 0, 2.83 bh apart). Does the intent carry anything besides B?

**Answer: no, and the beam is not that press.** It is a stale signature in slot 0's attack queue, put there at tick 3297, three ticks before the flip, while the switch was still off. The new B at 3326 is queued as a heavy, as the park says.

## The intent at 3326 (every non-zero field, from the file, replayed on a scratch copy of the 1931a0f8 tree with the park's isB clause)

`sig`, `sigHeld`, and the left stick's x and y. Nothing else: no `upgrade`, `special`, `context`, `transform`, `rs*`, `charge`, `lightHeld` or `heavyHeld`; stance mask 0, intent mode 0, fighter act.mode 0, `f.ai` null, `DirStick.firing` false. (Heavy was held until tick 3319.) The only intent routes to a signature request are `i.sig` (`control.gd`) and `i.upgrade == 2` (nothing in sim/input sets it), plus the stick's own beam; none is in play here.

## What the director did (instrumented `_request`, `_drain`, `_start`; `controls-dump-3326.gd.txt`)

- `isB` was true for the press (bNoBeam on, mask 0, not firing), so the press was converted: `PUSH kind=heavy idx=1`.
- But the queue already held an older request: `queue-before=[2, 0, 1, 3297]` (weight 2 = signature, mode 0, entry 1, queued at tick 3297).
- `_drain` starts the oldest queued request, so it started that one: `START kind=sig ownBeam=false` from `_drain` (called from `_request`), exchange `signature`. The fighters were in a dodge exchange until tick 3320 (`exchange_end`), so the stale signature could not start earlier; the cooldown and the exchange ended and it went at the next request.

## Proof

Flipping the switch before tick 3297 (`--flip=3290` and `--flip=3200`) gives `queue-before=[1, 0, 1, 3297]` (a heavy) and `START kind=heavy`: no beam at 3326. A run with the switch on from tick 0 (`bt_park` in `park-replay-b-no-beam-1714.txt`) has no beam at 3326 or at 8096.

## What it means

- The replay's 3326 is an artifact of flipping mid-match: the queue holds signatures pushed while the switch was off. In play the switch is on for the whole match, so the 3297 press is queued as a heavy and nothing fires at 3326. No change to the park is needed.
- To use `--flip` for the rest of the replay, flip it before the first B press the window cares about (here before 3297), or start with it on. Flipping shortly before a window leaves stale queue entries from the old rule.
- Optional hardening (Encounter's, not needed for play): the drain could turn a player's queued non-stick signature into a heavy when bNoBeam is on, so a switch flipped mid-match leaves nothing behind.
