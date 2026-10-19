# The grapple, slice G3: a throw worth a heavy (parked, 2026-10-18)

Owner: Encounter Systems Director. Game Design's ruling of 2026-10-18 (`docs/design/rulings-2026-10-18.md` §1c), on main with G1 and G2.
- **It sits behind the grapple's switch, `grapple.enabled`, which is false.** With it off, play is the same to the bit.
- **Built and read in scratch. Not applied.**

## To build it

`node g3.cjs <root>` from this folder.
- `--check` reads every anchor and writes nothing; any other option is refused.
- No new golden.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/grapple.gd` | Encounter | `_throwHit`, before what each throw hands the brawl |
| `data/director/interrupts.json` | Encounter | `grapple.throw.worth` 6 |
| `tools/schemas/director-interrupts.schema.json` | **Tools** | The same key |

## As built

- **A throw lands worth a heavy: 6 brawl lights.**
  - It is a strike of the heavy class, which ignores his stance and can't be perfect-blocked.
  - It comes before what the throw hands the brawl: the down throw's bury, the up throw's opening in the air, or the send across, whose landing does its own damage on top.
  - That covers the down, up and across throws, and the reversal's.
- The bury and a wall slam keep their openings.
- If the blow ends the exchange (a KO, or a broken region's set piece), the throw ends there.

## What it read

In scratch on main 4cf5802e + this + `../launch-anywhere-2/` + `../forms-2/`. The probe is `probes/gp.gd`, with the grapple on in memory and launch anywhere on in the data. Ten full matches an arm, against medium.

**Gates, every switch off:** 33 of 35, and the golden is main's, byte for byte. The two that fail, `anim_check` and the world probe, fail the same way on a clean export of main (7d93624e), so they are main's own:
- `anim_check`: "a blow within reach ends 5.00 units short of the defender", seed 12345, mix and snappy (Animation's);
- the world probe: "no casualty is counted outside collateral.gd", which flags casualty code in Simulation's `core/forms.gd`.

| Row (Game Design's §7) | Bound | Read |
| :--- | :--- | ---: |
| A throw's worth | a heavy, 6 brawl lights | **54 HP a throw** (94 throws measured): 6 lights, as ruled ✓ |
| A player who uses only A, as it is meant | wins 10 to 35% | **0 of 10** ✗ |
| Throws a match, AI v AI | 1 to 4 | **3.9** ✓ (across 14, down 15, up 10) |
| A throw's opening followed by a launch | 15 to 40% | **32%** ✓ |
| Catch tells a minute, AI v AI | 1 to 3 | **1.25** ✓ |
| The clinch's length, AI v AI | median 40 to 70, at most 90 | median **85** ✗, max 90 |
| The hard rows: a stray moving the grip, a regrab inside 120, an AI tech inside its reaction time | never | **0, 0, 0** ✓ |

- **The A-only player** throws about 18 times a match, some 1,000 HP against a maxhp of 1,600, and wins the grip (229 steps to 138). He never strikes, so the AI KOs him first in every match. With the throw worth a heavy, the row still fails.
- **The clinch's median sits on a knife edge.** 59 of 129 clinches run to the time (42 with a leader, 17 even). With almost half at 90, the median falls among the late throws. G2's read on an earlier main gave 65.
