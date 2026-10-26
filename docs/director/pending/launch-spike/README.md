# The spike, the pay down, the teched landing a flip, free from the apex (parked, 2026-10-23)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-23c.md` items 9 to 12, on the pop (`../launch-pop/`). A second park on top of it, since the pop is in the EP's gates. Only with `anywhere.pop.enabled` (under launch anywhere's switch, false on main), so the golden doesn't move.

## To build it

On main with launch-pop (7170c4ac or later; re-cut on 9273cc0c): `node ps.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/brawl.gd` | Encounter | Two slots (`LA_POP_SPK`, `LA_POP_STUN`; `LA_N` 41). In `_bigLanded`, a launcher at a popped fighter is the spike (`_spike`). `_safety`: a juggle's stun is no opening. In `_popTick`, the spike's landing digs its crater, and a pop's tech is a recoil flip. Item 12: the pop's stun ends at `freeAt`, with no burst out; `_gapDist` (a blow's reach and closing by the horizontal gap while either is popped) |
| `sim/director/recoil.gd` | Encounter | `DirRecoil.popFlip`: the recoil flip out of a pop's landing (the backflip, the counter-rush), only with recoil flips on |
| `data/director/interrupts.json` | Encounter | `anywhere.worth` 4 (from 5), `landPay` 0.5 (from 1.0), `anywhere.pop.spike` {`fallTicks` 6, `recoverTicks` 21, `speed` 1800}; item 12: `pop.freeAt` 12, `pop.ticks` 24 (from 30: the apex at 12), `pop.landReel` 0 (from 8) |
| `tools/schemas/director-interrupts.schema.json` | **Tools** | `anywhere.pop.spike`, `anywhere.pop.freeAt` |

## The rules as built

- **The spike (9):** B at a popped fighter is never a send. He comes straight down into the ground under him in `fallTicks` (6), and his landing digs a crater there: an impact at `speed` (1800 u/s, energy 4 at tier 1). He recovers in `recoverTicks` (21, 0.35 s) unless he techs it, with a dodge tap in the landing's last `techTicks` (the AI at its recoil-flip share). The brawl goes on. The stick can't aim it. No journey, no freshness mark, no wary window, no 9a pay; the launching blow's worth is its damage. It replaces the pop's "a second pop in a row lands him".
- **Never sure in a juggle (9):** while he is popped or landing from it (`LA_POP_STUN`: the pop and its landing reel, or the spike and its recovery), a launcher at him is not sure: the stun is the juggle's, not an opening. The full send comes from the ground only.
- **The pay down (10):** `landPay` 0.5 and `worth` 4.
- **Free from the apex (12):** the pop is 24 ticks, so its apex is at 12. He is stunned on the way up (the rise is the reel the attacker's blows land in) and free from the apex: he guards, perfect-blocks and strikes in the air as on the ground, while the pop's own descent brings him down to the attacker. No landing reel and no burst out (he can strike instead). The spike stays: B at him in the air brings him down, and from the apex it can be guarded like any blow. The brawl's pull would meet them halfway up, so the descent is the pop's, not the pull's.
- **The gap while popped (12):** a blow either way while one of them is popped reaches and closes by the horizontal gap (`_gapDist`); the striker steps up to his height as it lands. Before, the closing read the full distance, height included, so a launcher at a popped fighter landed late, after his pop. That is the likely reason no spike landed in 1,492 pops (to be confirmed in the re-read).
- **The teched landing (11):** with recoil flips on, a teched pop landing is the recoil flip: the same backflip (flipBh 1, flipTicks 12, arcBh 0.8), landing set, and the counter-rush within counterTicks (20), the AI's counter press at its share. A spike's tech is the quick recovery only. With recoil flips off, a tech is the tech alone.

## Cues (for Animation)

The pop's cues (`../launch-pop/README.md`), plus:

| Kind, text | When | Fields |
| :--- | :--- | :--- |
| `pop`, `spike` | B at a popped fighter spikes him down | `target` the attacker, `n` the tick he lands, `dur` the fall's ticks, `x` where |
| `pop`, `land` | his landing (the pop's or the spike's) | `n` 1 set, 0 reeling; `amount` 1 for a spike's landing (its crater dug there) |
| `recoil`, `flip` (exit `backflip`) | a teched pop landing (recoil flips on) | as the recoil flip's own cue |

## What it read before item 12 (3be56843 with launch-pop, in scratch: its `sim/`, director data and schemas are those of 7170c4ac plus this; launch anywhere and recoilFlip on)

**AI v AI** (QA's runner, bands only, 40 matches, seeds 1 to 40):

| Arm | Median | p10 | p90 | Sends a match (L16) | Civilians lost | Flips a minute |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| The pop alone (launch-pop) | 373.8 s | 307.9 | 549.5 | 8.97 | 18.2% | 0.84 |
| **The pop with 9 to 11** | **385.8 s** | **319.0** | 496.5 | **8.30** | 17.6% | **1.88** |
| Bands | 360 to 480 | at least 300 | at most 600 | 8 to 16 | at most 30 | 1.2 to 6 |

- **Every AI v AI row is in its band.** Item 10's lower pay gives back 12 s. Item 11's flips add about one a minute, as Game Design said. Five probe matches (`popt.gd`): 8.2 sends and 14 pops a match, two juggle blows a pop, 43 of 71 landings teched, every match a KO.
- **No spike in AI v AI** (0 in 71 pops): the AI rarely presses B at a popped fighter.

**QA's masher stage** (100 seeds a job):

| Row | Read | Band | |
| :--- | :--- | :--- | :--- |
| The banded masher against medium | 51.0% | 35 to 50% | ✗ (one over) |
| The lit-B newcomer's wins: medium; easy | **100 of 100; 100 of 100** (his launches 10.7 and 12.3 a match; on him 6.1 and 3.8) | at most 50%; 50 to 95% | ✗ ✗ |
| His first launch inside 60 s: medium; easy | 90%; 99% | at least 75%; 90% | ✓ ✓ |

**Where the newcomer's edge is** (`probes/players_split.gd`, a scratch copy of QA's `players.gd` with counters; 10 matches against medium, all won):
- **He pops the medium AI about 149 times a match** (1,492 in 10); it techs 830 and bursts out 115. **55% of his damage lands on the AI while it is popped** (65,692 of 119,205), 42% in the brawl and 3% on journeys. He sends about 9.5 times a match.
- **No spikes** (0 in 1,492 pops): none of his launchers landed while the AI was up. Not traced why. With a pop about every 2.5 s, his launchers land as the AI comes down or after, when it is on the ground, often in its pop's landing reel, and pop it again. The arm below tests whether that re-pop is the loop.
- His mash also closes his flurry 5.7 times a minute, each close an opening, and he lands 158 heavies a match.

**Not ruled, the arm for the re-pop:** the spike also while he lands from a pop (`LA_POP_STUN` in the spike's test, scratch only). AI v AI reads the same as above to the digit, so no launcher lands in that window in AI play. **The newcomer still wins 100 of 100 against medium** (10.6 launches a match, first launch inside 60 s 91%). So the landing reel's re-pop is not the loop: his edge is the pops themselves, about 149 a match against a medium AI that is helpless for each, with more than half his damage landing in juggles.

**Golden and gates** before item 12 (switches off): the golden is main's, byte for byte; 35 of 35 at 0.

## What it reads with item 12

On db6c17ac (2026-10-25), in scratch with launch-pop already on main: `ps.cjs` applied, 262 files, 0 errors; the import is clean. Launch anywhere and recoilFlip on.

**AI v AI** (QA's runner, bands only, 40 matches, seeds 1 to 40):

| Arm | Median | p10 | p90 | Sends a match (L16) | Civilians lost | Flips a minute |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Before item 12 (above) | 385.8 s | 319.0 | 496.5 | 8.30 | 17.6% | 1.88 |
| **With item 12** | **392.9 s** | **289.5** ✗ | 538.9 | 10.2 (the probe; QA's full launches 9.70) | 16.9% | 2.00 |
| Bands | 360 to 480 | at least 300 | at most 600 | 8 to 16 | at most 30 | 1.2 to 6 |

- **The 10th percentile falls out of band** (289.5 s against at least 300). Every other row is in band. Five probe matches (`popt.gd`): 11.4 pops a match, 36 of 57 pop landings teched, 85 juggle blows on popped fighters, every match a KO.

**QA's masher stage** (100 seeds a job):

| Row | Read | Band | |
| :--- | :--- | :--- | :--- |
| The banded masher against medium | 53.0% | 35 to 50% | ✗ (three over) |
| The lit-B newcomer's wins: medium (L17); easy | **95 of 100; 100 of 100** (his launches 6.8 and 8.4 a match; on him 6.3 and 4.5) | 10 to 50%; 50 to 95% | ✗ ✗ |
| His first launch inside 60 s: medium; easy | 73%; 96% | at least 75%; 90% | ✗ (two under) ✓ |

**Where the newcomer's edge is** (`probes/players_split.gd`, 10 matches against medium, he wins 9):
- **He pops the medium AI about 192 times a match** (1,917 in 10; it techs 1,147). **Half his damage lands on the AI while it is popped** (75,031 of 151,496), 49% in the brawl and 1% on journeys. Item 12 brought the medium win share down from 100 to 95 and his launches from 10.7 to 6.8 a match. It didn't bring the share into L17's band.
- **Still no spikes** (0 in 1,917 pops), even with the horizontal gap while he is popped. **Inferred, not traced:** a launcher's 14-tick wind-up can't land before the pop's 12-tick apex, and from the apex he is free and may guard.

**Golden and gates** (switches off): the golden is HEAD's, byte for byte; 35 of 35 at 0.

## State

- **Built, read, frozen.** The four rows out of band (p10, the masher, the newcomer's medium wins and his first launch at medium) go to Game Design.
