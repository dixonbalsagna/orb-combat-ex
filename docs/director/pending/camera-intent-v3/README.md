# The camera-intent feed, v3: the touchdown on the launch curve, and the story cut (parked, 2026-10-22)

Owner: Encounter Systems Director. Two changes to the feed on main (`sim/director/camintent.gd`, b3a3aa74):
- the send's touchdown from Simulation's launch curve (its shared functions: `SimFlight.track`, `tick`, `predict`);
- the EP's story finding from Rendering's roll probe.

**It writes cues only,** behind `cameraIntent.enabled` (and, for the touchdown, the curve's own switch). Play and the golden don't move. **Built and read in scratch. Not applied.**

## To build it

`node cc.cjs <root>` from this folder, on main with Simulation's shared park (on main since c6980e25). `--check` reads every anchor and writes nothing. It composes with the hit-weights, 4c/4d, wall-kick, balance and calm-turn parks.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/camintent.gd` | Encounter | `launched` (the touchdown on the curve); `decisive` (the moment's own plan); `_story` weighted by what a plan holds, with "decisive" only when the outcome is known, else "big"; `exchange(S, ex, why)` told again at a beam's fire, a beam clash's start and a finisher's plan; `beamReach` counted |
| `sim/director/melee.gd` | Encounter | `DirCamIntent.launched` after the send |
| `sim/director/exchange.gd` | Encounter | `DirCamIntent.decisive` in `decisive` and `decisiveShot`; the finisher's plan in `startFinisher` |
| `sim/director/beam.gd`, `beamplay.gd` | Encounter | The beam clash's, the beam's and the travelling beam's plans |

**The weights:**
- a finisher 5;
- a beam or a clash 4;
- a launch, a guard break or a clash's resolve 3;
- a heavy or a knock-back 2;
- else 1.

Each of reversal, comeback, crippling and first blood adds one, to 5. A decisive moment's own plan adds one when the loser is on the brink.

## What it read (in scratch, the feed on)

| | On main (v2) | v3 |
| :--- | ---: | ---: |
| Climaxes held, 10 AI matches of 2 min (212: decisives by knock-back, launch, beam, beam clash, guard break, barrage) | 132 | **212** |
| ... tagged decisive | 45 | 169 |
| The best held story's weight | 0 to 2 | 2 to 4 |
| 6 AI matches to the KO or 10 min: climaxes held (444, with 8 finishers and 4 KOs) | | **442**; the 2 not held are KOs after the finisher plan's span |
| ... finisher plans | 0 | **8 of 8, weight 5, told a median 20 ticks ahead** |
| The touchdown on the curve, 41 sends | | exact in 37 of 39 met, counted in live ticks. In ticks, 30 of 39: a freeze or a pause in the flight is in no prediction |

- **Told ahead:** a held plan's median lead is 18 ticks: a beam's 20, a launch's 36, a knock-back's 14. A brawl light can't be told earlier than its 2 ticks.
- **Off:** with main's shared park and the hit-weights park (30fcaf28), the golden is main's, byte for byte, and the gate list is 34 of 35. Its one red is main's own anim_check.

## Probes (`probes/`, from a copy's root)

- `ccp.gd -- <matches> <seed0>`: the touchdown against the first contact, in ticks and in live ticks.
- `stp.gd -- <matches> <seed0> [--ticks=7200]`: the stories at the climaxes, after Rendering's roll probe.
