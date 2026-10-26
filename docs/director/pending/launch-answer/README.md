# The AI answers a launcher it guessed (parked 2026-10-26, re-cut the same day for GD's items 19 to 21)

Owner: Encounter Systems Director. The EP's (a) after the trace of the lit-B newcomer's 95 of 100 against medium (launch-spike's read), and Game Design's `rulings-2026-10-26.md` §2d items 19 to 21. Behind `data/director/interrupts.json` `brawl.launcher.anywhere.answer.enabled` (false), so the golden doesn't move.

## Why

The AI answers a launcher that isn't sure only by a guess (launch anywhere, section 8: it never reacts to one it sees). The guess is drawn when the rival's blow lands clean on it, at its level's `brawl.anywhere.answer` share (medium 0.25), and holds for the link's 24 ticks. Its answer was a guard press its reaction time (`reactTicks`, 14) after the launcher was thrown. **The launcher winds 14 ticks**, so that press came at the contact or after it and never once landed inside the perfect window. In 3 matches of the newcomer against medium with the share at 1.0: 643 late, answerable launchers came while the guess held, and 0 answers were pressed. So the share did nothing: 0.25 and 0.6 read the same to the digit.

## To build it

On main (launch-spike is in): `node la.cjs <root>` from this folder. `--check` reads every anchor and writes nothing. Before `../water-surface/` and `../rally/` (its new launch-anywhere slot moves their slot bases with it).

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/brawl.gd` | Encounter | `_laAnswerTick`: with the switch on, the guessed press is due `answer.leadTicks` live ticks before the blow's contact, in place of `reactTicks` after the throw. `_laAnswerPlan`: no guess at a player's first launcher of a match on `answer.firstFree`'s levels. `LA_LAU1` (a new launch-anywhere slot, `LA_N` 42): his first launcher is thrown. `mashing` |
| `sim/director/interrupt.gd` | Encounter | `_aiBlocks`: against a mash, its perfect-block chance in a brawl is at least its level's `brawl.perfectVsMash` |
| `data/director/interrupts.json` | Encounter | `brawl.launcher.anywhere.answer` {`enabled` false, `leadTicks` 3, `firstFree` [easy, medium], `mashTicks` 9} |
| `data/director/ai.json` | Encounter | easy's `brawl.anywhere.answer` 0.1 to 0.2; each level's `brawl.perfectVsMash` (easy 0.01, medium 0.02, hard 0.04) |
| `tools/schemas/director-interrupts.schema.json`, `director-ai.schema.json` | **Tools** | `anywhere.answer`; `brawl.perfectVsMash` |

## The rules as built

- **The timing:** the guess and its share are unchanged; the AI still never answers a launcher it didn't guess, and never one that is sure. With the guess holding and a launcher winding on it (answerable, thrown after its stagger), its guard press comes 3 live ticks before the contact, inside the perfect window (a blow's 8 ticks and the early 4). A perfect block turns the launcher: the thrower staggers, and the AI has the riposte.
- **Item 19:** on easy and medium the AI never guesses at a player's first launcher of a match (it may still guard it by ordinary reaction, as any blow). From his second it guesses at its share. Hard has no leniency.
- **Item 20:** easy's answer share 0.2 (it acts from his second launcher, by item 19).
- **Item 21:** a mash is his last two light presses within `mashTicks` (9) of each other, the last of them as recent. Against one, the AI's perfect-block chance in a brawl is at least its level's `perfectVsMash`, the share tuned toward the masher's 45%. A perfect-blocked light stays the plain reversal (10-26 item 8).

## What it reads

**The tuning** (QA's masher stage, 100 seeds, on HEAD with the re-cut; easy's answer 0.2 throughout):

| Arm: `perfectVsMash` easy / medium / hard | The banded masher | The AI's perfect blocks of mash presses |
| :--- | :--- | :--- |
| 0 (the first park) | 53% | |
| 0.06 / 0.12 / 0.25 | 6% | 3.7% |
| 0.025 / 0.05 / 0.1 | 32% | 1.6% |
| 0.015 / 0.03 / 0.06 | 38% | 1.0% |
| 0.0125 / 0.025 / 0.05 | 48% | 0.9% |
| **0.01 / 0.02 / 0.04 (shipped)** | **45%** | 0.7% |

The read moves a few points from noise (the 0.025 arm read above the 0.02 one), so the shipped value sits at the band's target with room either way. The newcomer presses every 10 ticks, outside a mash, so his rows don't read the mash share.

**The first arm's newcomer rows** (0.06 / 0.12 / 0.25, the rest as shipped): against medium 21 of 100 (L17 10 to 50 ✓); against easy 90 of 100 (✓, item 20's 85 to 90); his first launcher at medium thrown inside 60 s in 100%, landed inside 120 s in 100%, any launch inside 60 s in 100% (✓, item 19).

**The final read** (on c9bd20d1, this park alone, as shipped): the banded masher 45% ✓; the newcomer against medium 21 of 100 ✓, against easy 90 of 100 ✓; his first launcher thrown inside 60 s, landed inside 120 s and any launch inside 60 s: 100% at both levels ✓. AI v AI (40): median 401.3 s, p10 326.3, p90 527.7, civilians 20.3%, flips 1.90, full launches 10.0, no faults. With the water and the rally on top (c3ca82e9): see `../rally/README.md`'s final read. Golden byte-identical and 35 of 35 gates on both.

## The first park's read (before items 19 to 21)

On 1f95f42e (2026-10-26; launch-spike on main), in scratch: `la.cjs` applied, 267 files, 0 errors, self-test 9,120 of 9,120; the import is clean. With `answer.enabled` and launch anywhere on.

| Row | Without (launch-spike's read) | **With the answer** | Band | |
| :--- | :--- | :--- | :--- | :--- |
| The lit-B newcomer's wins against medium (L17) | 95 of 100 | **23 of 100** (his launches 4.4 a match, 9.9 on him) | 10 to 50% | ✓ |
| ... against easy | 100 of 100 | 99 of 100 | 50 to 95% | ✗ |
| His first launch inside 60 s: medium; easy | 73%; 96% | **40%**; 94% | at least 75%; 90% | ✗ ✓ |
| The banded masher against medium | 53% | 53% | 35 to 50% | ✗ (unchanged) |

- **The newcomer split** (10 against medium): he wins 4 (9 before). The AI perfect-blocked 533 launchers in the 10 matches; the pops on it fell from 1,917 to 1,468, and his damage on the popped AI from 75k to 56k.
- **AI v AI** (QA's runner, 40 matches): median 392.9 s, p10 289.5 (✗, as without it), p90 543.0, civilians lost 16.4%, full launches 9.93, flips 2.00, no faults.
- **Golden and gates** (switches off): the golden is HEAD's, byte for byte; 35 of 35 at 0.
