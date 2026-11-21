# Parked: a Medium candidate for X-06 and A-AI-10 (data only; off main until QA measures it)

Encounter, 2026-11-21, sprint A1. QA found Medium a cliff for a single pad on Orb's scheme (6 of 100) and wide open to charged heavies (60 of 60). Easy is 100 of 100 for the beam pad. This is one Medium candidate in `data/director/ai.json`. **QA measures it with the strike, beam and charge pads.**

**The one line:** Medium matches the player's pace as Easy does (`levels.medium.brawl.paceMatch`, Easy's own floor 12 and ceiling 30), which is what makes a single pad's blows trade evenly; and Medium perfect-blocks a full charge as often as Hard does (`levels.medium.brawl.perfectVsHeavy` 0.15 to 0.3), which closes the charged-heavy hole. Pace matching never touches a charge, and the charge answer never touches the strike-and-beam pad: their runs are tick for tick the same with and without it.

## The readings

On the kept 9 November build's tree (its data is main's since GW1a), QA's `qa/godot/orbs_player.gd --solo` with QA's planet settings. Records are in `docs/director/runs/b0e20f9a/x06-medium/x06-candidates.txt`. My baseline reproduces QA's: Medium as shipped, 4 of 50 for the beam pad.

| Medium | Beam pad (strikes, guard, a beam every 420) | Charge pad | Strike-only pad |
| :--- | ---: | ---: | ---: |
| As shipped | 4 of 50 (8%; QA 6 of 100) | QA: 60 of 60 | QA: 0 of 200 |
| **This candidate** | **9 of 30 (30%)**; hits even (15,064 to 15,800, from 1 to 2.6) | **14 of 30 (47%)**, inside 35 to 55% | 0 of 30 |

**What else I tried, which didn't move the beam pad beyond the noise of 30 matches (about ±17 points):**
- Every numeric Medium knob moved toward Easy's (t 0.4: 0 of 30; t 0.6: 1 of 30; with pace matching, t 0.5: 5 of 30).
- The beam struggle's `aiHit` at Easy's 0.4 (`interrupts.json`): 1 of 30.
- `beamAnswer` 0.25: 16 of 60.
- `perfectBlockMul` 0.35 with `riposte` 0.75: 13 of 60.

## What the candidate doesn't close

- **The beam pad sits at about 30%,** under the 35 to 55% band. Pace matching is the only Medium lever I found that moves it (from 8%).
- **The strike-only pad still wins 0 of 30.** QA's note holds: stick-only pads have lost to Medium in every reading.
- **Easy stays above its band.** The beam pad won 29 of 30 with Easy's `beamAnswer` 0.25 and `beamDodge` 0.55 (not parked). The beam is what wins Easy (61% without it), and Easy's beam knobs barely move it. No Easy candidate is parked.

## Apply

On main (`data/director/ai.json` is the kept build's, byte for byte): `git -c core.autocrlf=false -c core.eol=lf apply x06-medium.diff`. Two keys on Medium's line only. Validate: 0 errors, self-test 10,121 of 10,121.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `x06-medium.diff` (`data/director/ai.json`, `levels.medium.brawl`: `paceMatch` added, `perfectVsHeavy` 0.3) | Encounter | 6fe839aef79fc847cd1b75061d20a295ab66db11 |

## NEEDS FROM EP

- **QA:** the measurement with the strike, beam and charge pads, at QA's sample sizes.
- **Game Design:** with ai.json alone, a scripted strike-only pad can't win at Medium, and the beam pad reaches about 30%. Either the bands are read for a player that also uses face buttons and beams (QA's open question), or the next lever is outside the computer's level knobs (damage, the guard, the hit-stun), which is Combat's and Simulation's.
