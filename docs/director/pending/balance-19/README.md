# Balance, from Game Design's rulings of 2026-10-19 (parked)

Owner: Encounter Systems Director. Game Design's §5 (`docs/design/rulings-2026-10-19.md`) for Encounter's parks. Each change sits behind the switch it already has: launch anywhere's (`brawl.launcher.anywhere.enabled`) and the grapple's (`grapple.enabled`), both false on main. So the golden doesn't move.
- **Built and read in scratch. Not applied.**

| # | The ruling | What changes |
| :--- | :--- | :--- |
| 5a | The second light must land within 6 ticks of the first | `anywhere.armourLightTicks` 6. An answerable launcher's armour takes a light; a second light stops it only if it lands within 6 live ticks of the last one taken, and a later one is the new first. So only a real flurry stops it. One new launch-anywhere slot (`LA_LHIT_AT`) |
| 5c | The grab-and-follow row, 25 to 50% against medium | No change of mine. `probes/gp.gd --mode=follow` is the row: the catches and pummels of the A-only row (each pummel within 3 ticks of its pulse), with the stick down at each claim so his throw is down, and B 2 ticks after it |
| 5d | The clinch is 60 ticks at most: three pulses | `grapple.clinch.max` 60, where it was 90 |
| 5e | Route rows: by him 20 to 50, on him 10 to 40; AI v AI full launches 6 to 12 | QA's rows. `probes/lap.gd --mode=route` and `--mode=ai` read them |

## To build it

`node bal.cjs <root>` from this folder, on main with launch anywhere. `--check` reads every anchor and writes nothing. It composes with the camera-intent and recoil-flip parks in any order.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/brawl.gd` | Encounter | 5a: `_flurried`, the slot, the stop's condition |
| `data/director/interrupts.json` | Encounter | `anywhere.armourLightTicks` 6 and its note; `grapple.clinch.max` 60 |
| `tools/schemas/director-interrupts.schema.json` | **Tools** | `armourLightTicks` |

## What it read (main 5385a86d, in scratch; launch anywhere and the grapple on)

| # | Row | Read | Band |
| :--- | :--- | :--- | :--- |
| 5a | The spammer's answerable launchers answered (`lap.gd --mode=spam`, 10 matches, 1,035 of them) | **68.9%**, from 89.8% before 5a (same probe, 50 matches). AI v AI: 50%, from 79% | 20 to 50 ✗ |
| 5d | The clinch, AI v AI (`gp.gd --mode=ai`, 127 clinches) | median **60** (the cap), time-outs **57%** (24 at the time, 49 at it with a leader) | 30 to 55, under 30% ✗ |
| 5d, grip 1 (in memory) | the same | median **25**, time-outs **24%**, 6.4 throws a match (1.9 at grip 2) | ✗ (close) |
| 5c | Grab-and-follow against medium (`gp.gd --mode=follow`) | **0 of 10.** Each of his 156 down-throws is followed by a launch. The AI ends on 38 to 751 HP | 25 to 50% ✗ |
| 5c, throw worth 9 (in memory) | the same | 0 of 10 | ✗ |
| 5e | My route arm (`lap.gd --mode=route`, 10 matches capped at 5 min) | by him 8.3 a match, on him 12.5; AI v AI full launches 5.6 | 20 to 50, 10 to 40, 6 to 12 (QA's player decides) |

- **5a** is built as ruled, and it moves the spammer's row by 21 points. The rest of "answered" is the AI's guard and its perfect blocks against launchers it guessed (101 guards, 98 perfects).
- **5d's cap alone** cuts the clinch to 60 without resolving it: two steps of grip in three pulses rarely happen between two even pummellers. Grip 1 is near Game Design's band.
- **5c's script never guards**, so it takes every blow the AI lands. Throws and launches alone don't win at any worth tried. The row needs a defence in the script (QA's) or a different target (Game Design's).
- **The probe's own fix:** its B after a throw was falling in the throw's hit-stop, where a scripted press is lost. It is now held to the first live tick, as a player's press waits through a freeze.
- **Off:** in the gate list over all five parks together (5385a86d), the golden is main's, byte for byte, and 34 of 35 pass. The one red is main's own anim_check.
