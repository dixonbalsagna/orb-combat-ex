# Parked: the five data/fight rows GW1a was missing (a data grant)

Simulation, 2026-11-14, sprint A1. The EP's manifest check found that, with every GW1a park stacked, five rows of `data/fight` still differed from the kept 9 November tree and no park carried them. My GW1a preview had matched the target only because it copied the whole target data. **This grant carries the five, so the GW1a stack reproduces GW1a's target golden byte for byte.** It's a data grant: no code.

## What changes

Each row takes the kept tree's value, with a note beside it saying what it was:

| File | Row | Was | Now (the 9 November build's) |
| :--- | :--- | :--- | :--- |
| `data/fight/brake.json` | `enabled` (the air brake) | false | true |
| `data/fight/hitstop.json` | `budgetAny.enabled` (the freeze budget on any table) | false | true |
| `data/fight/kick.json` | `enabled` (the kick and the coin turn) | false | true |
| `data/fight/ladder.json` | `chargePerSec` | 0.5 | 2 |
| `data/fight/power.json` | `dash.slip.enabled` (the slip; data-power-on left it off) | false | true |

The data hash skips comment keys and reads 2 and 2.0 alike, so the notes don't move anything.

## Apply

After the rest of the GW1a stack: `data-power-on.patch` and `never-cut.patch` edit the same lines of `power.json` and `hitstop.json`, so it doesn't apply to main alone. `git -c core.autocrlf=false apply data-fight-gw1a.patch`.

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `data-fight-gw1a.patch` | `data/fight/{brake,hitstop,kick,ladder,power}.json` | 0b9fcbc658229c0447bc84791e488e3ff2227aae | f23ab2e54e6e |

## What else GW1a needs (found by the bisect)

With the EP's stack overlay (`list.txt`'s 36 patches on main) plus this grant, the golden still differed. Four goldens on that tree, each against the target:

| With | Golden |
| :--- | :--- |
| all of the target's data | **reproduces the target** (so no code in the stack moves it) |
| World's `biomes/water.json` alone | differs |
| Combat's `combat/mixed.json` and `phrases.json` alone | differs |
| **water and combat together** | **reproduces the target** |

So **GW1a = the stack + this grant + World's re-cut water hunk (`docs/world/pending/a-world-01/data-switches-gw1a.diff`, 31f6a8bd) + Combat's `docs/combat/pending/gw1a-rows/` (fd5c1895).** After those, the data differs from the target only in `art/biomes.json` (colours) and `camera/swing.json` (the view's pieces), and neither reaches the golden.

## Proof

Records in `docs/sim/runs/26fd27b0/data-fight-gw1a/`. Tree: HEAD 26fd27b0 + the EP's GW1a overlay + World's water hunk + Combat's gw1a-rows, committed as the base, then this grant:
- **Negative control:** without the grant, the golden differs from the target (187,200 ticks against 184,833).
- **With it, the golden reproduces GW1a's target byte for byte** (184,833 ticks).
- **Parity against the target through `gate.mjs`: exit 0**, no SCRIPT ERROR lines.
- `power_check` through `gate.mjs`, and its negative control: 0 failed. `kick_check` 0 failed. `two_states` (default, power, dash, slip, fights) passes.
- Import, validator, determinism lint, the two-fighter ratchet (365).
- The other owners' checks that read these five switches:
  - pass: Encounter's `floorlift_check`, `strike_stages_check` and `arrive_check`; Netcode's `lan_check`;
  - fail, being attributed (the same checks on the same tree without the grant): Encounter's `beam_front_check` (4 rows: a signature pressed into the charge, a fire-back's struggle); Animation's `anim_check` (13 rows: the grip, the throws, the zip view, the slope test, standing on the water, plus a SCRIPT ERROR in `render/core/match_recorder.gd:82`, a file of the stack's). Encounter's own S2 notes list `beam_front_check` as failing on GW1a's data with today's code.
- Rendering's 15 on the stack: 13 pass. `flash_reg_check` (2 rows: the camera's scale reaches the register at 0.48 pixels a unit against the reference's 0.51) and `flight_check` (20 rows: building 239 shows 5 people standing where the sim has 4) are being attributed the same way.

**Not this grant's:** the validator's self-test fails on the stack: "coverage: `ui-modes.schema.json`: at least three invalid cases, has 0". That's UI's new schema from a1-start-flow's grant (the EP routed it to Tools).
