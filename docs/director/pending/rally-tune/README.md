# The rally's final tune (parked, 2026-10-26)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-26.md` §2h items 29 to 31, on the rally as it lands (`../rally/`). Under `rally.enabled` (false on main), so the golden doesn't move.

## To build it

On main with `../launch-answer/`, `../water-surface/` and `../rally/` landed: `node rt.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/rally.gd` | Encounter | `counterLive` (new): f's blow on o is the counter-rush of o's rally. `turn` reads it, and spends his window (`DirRecoil.counter`, with its cue). The "teched" end waits while his counter-rush is on its way |
| `sim/director/brawl.gd` | Encounter | `contact`: a rally's chaser doesn't guard against its counter-rush (a perfect block, resolved before the contact, still answers it) |
| `data/director/ai.json` | Encounter | Each level's `rally.link`: easy 0.75, medium 0.9, hard 0.95 (item 29) |

## The rules as built

- **Item 29:** the attacking AI's link share in its own rally is 0.75, 0.9 or 0.95 by level. The tech shares are unchanged.
- **Item 30, a surer counter-rush.** The trace before it: after 9 air techs in 10 matches, the AI drew its counter-rush 8 times (at the recoil flip's 0.5, 0.7, 0.9, as item 30 asks). Yet no turn came. In 4 its next blow landed in reach as a plain blow, because `DirRecoil.counter` spends the window only on an approach from range. In the 2 that flew in and hit, the rally had already ended "teched", 20 ticks after the tech. Now:
  - the defender's next blow inside his counter window, or the counter-rush he flew in with (within `turnTicks` of its press), is the counter-rush;
  - it lands on the chaser through his guard, unless he perfect-blocks it;
  - the rally stays open while it is on its way;
  - landing it on the chaser in the air is the turn, as before.
- **Item 31 (length's 10th percentile):** the levers in GD's order, read below.

## What it reads

On main 7c48f552 (the three parks landed) + this, in scratch: 269 files, 0 errors, self-test 9,154 of 9,154; the import is clean. With the rally, launch anywhere, the answer and the water on. (The arms were read first on HEAD f8dddb8a with the three parks applied in scratch; main's read with 29 and 30 is the same to the digit.)

**QA's masher stage** (100 seeds, main + this): the banded masher 45% ✓, the newcomer against medium 11 of 100 ✓, against easy 86 of 100 ✓.

**The GIF** (`../../img/rally-ai-seed1.gif`, for Orb's rally homework): a rally of the AI's with this park on, filmed from the web build through Tools' capture hook (the `ai` scene, seed 1, ticks 6,376 to 7,167: four links; the default calm look). The web build plays a different match from the native one, so the rally was found with a scratch patch to the hook that logs the rally's cues while it fast-forwards. In the web `ai` scene rallies are rarer than in AI v AI (one with links in six 3-minute seeds), since that scene readies forms and raises a tier on its own schedule.

**QA's rows** (QA's runner, 40 matches, AI v AI):

| Row | The rally as landed | **With 29 and 30** | Lever 2: the chase rate outside rallies halved | Lever 3: link prices 35 / 50 ki (from 20 / 30) | Band |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Match length, p10 | 276.9 s | **279.0** | 279.0 | **315.7** ✓ | at least 300 |
| Median, p90 | 375.3, 538.6 | 382.5, 508.9 | 382.5, 516.2 | 376.6, 540.6 | 360 to 480; at most 600 |
| Links a rally, median | 1 | **1** | 1 | 1 | 2 to 4 |
| Rallies that turn | 4.2% | **12.3%** | 13.1% | **7.8%** | 15 to 40 (10 to 40 if links and turns conflict) |
| Dazes a match | 5.38 | 5.38 | 5.35 | 5.20 | 2 to 8 |
| Rallies a match | 5.30 | 5.50 | 5.53 | 6.08 | 3 to 10 |
| Rally time | 4.8% | 5.2% | 5.2% | 6.1% | at most 25% |
| Repeats; ended by repetition | 0%; 0% | 0.5%; 0% | 0.5%; 0% | 0%; 0% | at most 25%; 20% |
| Full launches, a rally once | 6.90 | 7.40 | 7.40 | 7.80 | 6 to 12 |

- **The links' median:** a probe of 10 matches (each `rally_end` as QA counts it) reads 0 links in 9, 1 in 14, 2 in 9, and 3 or more in 12. So 48% have two or more, a hair under the median. Most of the one-link rallies ended "landed": a link's own send can go down (item 22b keeps only the opening's off the ground).
- **Lever 2** (the AI's chase rate outside rallies) **moves nothing**: nearly every full send now opens a rally, where the rally's own link share rules.
- **Lever 3** (link prices: the zip's strike and heavy ki, which the chase pays) **brings p10 into band, but turns fall to 7.8%**, below even the widened band, and links stay at 1. The levers are GD's; neither is shipped. The park keeps today's prices.

**Golden and gates** (main 7c48f552 + this, switches off): the golden is HEAD's, byte for byte; 35 of 35 at 0.
