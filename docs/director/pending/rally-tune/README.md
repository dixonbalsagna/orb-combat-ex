# The rally's final tune (parked 2026-10-26, re-cut the same day for §2i)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-26.md` §2h items 29 to 31 and §2i items 32 and 33, on the rally as landed (`../rally/`), with Camera's one-line grant. Under `rally.enabled` (false on main), so the golden doesn't move.

## To build it

On main with `../launch-answer/`, `../water-surface/` and `../rally/` landed: `node rt.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/rally.gd` | Encounter | `counterLive` (new): f's blow on o is the counter-rush of o's rally. `turn` reads it, and spends his window (`DirRecoil.counter`, with its cue). The "teched" end waits while his counter-rush is on its way |
| `sim/director/brawl.gd` | Encounter | `contact`: a rally's chaser doesn't guard against its counter-rush (a perfect block, resolved before the contact, still answers it) |
| `data/director/ai.json` | Encounter | Each level's `rally.link`: easy 0.75, medium 0.9, hard 0.95 (item 29) |
| `sim/director/rally.gd`, `sim/director/chase.gd` (more) | Encounter | Item 32: `linkNoDown` around the planner's pick for a link's send, and Plate Chase's neutral line laid flat when his flight goes down. Item 33: `linkWorth`, the link's blow damage times `rally.linkWorth` |
| `data/director/interrupts.json` | Encounter | `rally.linkWorth` 0.8 (item 33) |
| `tools/schemas/director-interrupts.schema.json` | **Tools** | `rally.linkWorth` |
| `render/camera/split_rig.gd` | **Camera** (a grant) | Camera's one line (`docs/camera/pending/rally/director-19-rally-grab-kind.patch`): a grab in flight arrives as `energy_grab`, so the rally's held shot size takes that kind too. No conflict: nothing in the rally sends `energy_grab` yet |

## The rules as built

- **Item 29:** the attacking AI's link share in its own rally is 0.75, 0.9 or 0.95 by level. The tech shares are unchanged.
- **Item 30, a surer counter-rush.** The trace before it: after 9 air techs in 10 matches, the AI drew its counter-rush 8 times (at the recoil flip's 0.5, 0.7, 0.9, as item 30 asks). Yet no turn came. In 4 its next blow landed in reach as a plain blow, because `DirRecoil.counter` spends the window only on an approach from range. In the 2 that flew in and hit, the rally had already ended "teched", 20 ticks after the tech. Now:
  - the defender's next blow inside his counter window, or the counter-rush he flew in with (within `turnTicks` of its press), is the counter-rush;
  - it lands on the chaser through his guard, unless he perfect-blocks it;
  - the rally stays open while it is on its way;
  - landing it on the chaser in the air is the turn, as before.
- **Item 31 (length's 10th percentile):** the levers in GD's order, read below.
- **Item 32 (§2i):** on a neutral stick every link's send goes across or up, as the opening's does (22b): the planner leaves its down candidates out for a link, and Plate Chase's line with no stick, along his flight, is laid flat when his flight goes down. A held-down stick still wins, and the spike (B from above) stays the deliberate down link.
- **Item 33 (§2i, the length's p10 still under 300 with 32 in: 288.0 s):** each link's blow deals ×0.8 of its damage (`rally.linkWorth`). The opening send and the sell are unchanged; link prices stay as they are.

## What it reads

On main b1de4c69 + this, in scratch: 269 files, 0 errors, self-test 9,154 of 9,154; the import is clean. With the rally, launch anywhere, the answer and the water on. (29 and 30 were read on 7c48f552, 32 alone and 32 with 33 on b1de4c69.)

**QA's masher stage** (100 seeds, b1de4c69 + this): the banded masher 38% ✓ (45% with 29 and 30 only), the newcomer against medium 16 of 100 ✓, against easy 83 of 100 ✓.

**The GIF** (`../../img/rally-ai-seed1.gif`, for Orb's rally homework): a rally of the AI's with this park's 29 and 30 on, filmed from the web build through Tools' capture hook (the `ai` scene, seed 1, ticks 6,376 to 7,167: four links; the default calm look). The web build plays a different match from the native one, so the rally was found with a scratch patch to the hook that logs the rally's cues while it fast-forwards. In the web `ai` scene rallies are rarer than in AI v AI (one with links in six 3-minute seeds), since that scene readies forms and raises a tier on its own schedule.

**QA's rows** (QA's runner, 40 matches, AI v AI):

| Row | The rally as landed | With 29 and 30 | And 32 | **And 33: this park** | This park, the rally off | Band |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Match length, p10 | 276.9 s | 279.0 | 288.0 | **283.6** ✗ | 278.6 ✗ | at least 300 |
| Median, p90 | 375.3, 538.6 | 382.5, 508.9 | 394.4, 475.4 | 382.3, 518.0 | 405.9, 538.1 | 360 to 480; at most 600 |
| Links a rally, median | 1 | 1 | 1 | **1** ✗ (410 links, 236 rallies) | | 2 to 4 |
| Rallies that turn | 4.2% | 12.3% | 11.3% | **9.7%** ✗ | | 15 to 40 (10 to 40 if links and turns conflict) |
| Dazes a match | 5.38 | 5.38 | 5.20 | 5.05 | | 2 to 8 |
| Rallies a match | 5.30 | 5.50 | 5.78 | 5.90 | | 3 to 10 |
| Rally time | 4.8% | 5.2% | 6.2% | 5.8% | | at most 25% |
| Repeats; ended by repetition | 0%; 0% | 0.5%; 0% | 0.2%; 0% | 0%; 0% | | at most 25%; 20% |
| Full launches, a rally once | 6.90 | 7.40 | 7.38 | 7.40 | 8.80 | 6 to 12 |

- **The short matches aren't the rally's.** With the rally off and everything else on, p10 reads 278.6 s, as short as with it on. The rally is about 6% of match time. No column moves p10 beyond the 40-seed noise (276.9 to 288.0), item 33 included.
- **The links' median:** the probe (10 matches) reads 102 links in 46 rallies, a median of 2, but QA's runner reads 1 (1.74 a rally). Most one-link rallies still end "landed" (28 of 46 in the probe), now with 32's sends across or up.
- **Lever 2** (read on 29 and 30: the AI's chase rate outside rallies halved) **moves nothing**: p10 279.0.
- **Lever 3** (read on 29 and 30: link prices 35 / 50 ki, from 20 / 30) **brings p10 into band (315.7), but turns fall to 7.8%**, below even the widened band, and links stay at 1. The prices are the zip's strike and heavy, which every chase pays, in a rally or not; so it works on the matches outside the rally too. The levers are GD's; neither is shipped. The park keeps today's prices.

**Golden and gates** (b1de4c69 + this, switches off): the golden is HEAD's, byte for byte; 35 of 35 at 0.
