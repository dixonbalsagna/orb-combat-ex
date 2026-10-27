# The rally's second tune (parked 2026-10-26)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-26.md` §2j items 35 and 37, on the rally tune as landed (22b76cb4). Under `rally.enabled` (false on main), so the golden doesn't move. Item 36's levers are out: QA's 200 matches on fa6f727a read links at a median of 2.00, in band (the EP, by item 36 step 1).

## To build it

On main with `../rally-tune/` landed (22b76cb4 or later): `node rt2.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/rally.gd` | Encounter | Item 37: `counterLive` takes the wall kick's rush blow too, and `turn` spends that window. `answering` (new): the landed end waits while the defender's flip, his kick's push or his counter-rush is under way. `_landing` (new): his landing in a rally's flight opens his recoil flip (23d item 9). `counterShare` (new): the AI's counter share in a rally |
| `sim/director/recoil.gd` | Encounter | `landed` (new): the flip's window out of a rally's landing (the skid's kind, once a journey, no flourish). `_land`'s AI counter draw takes `counterShare` |
| `sim/director/wallkick.gd` | Encounter | Its rush blow marks the counter-rush (`DirRally.markCounter`), and its AI counter draw takes `counterShare` |
| `data/director/interrupts.json` | Encounter | `rally.linkWorth` 1.0 (item 35) |
| `data/director/ai.json` | Encounter | Each level's `rally.counter`: 0.7, 0.85, 0.95 (item 37 step 3) |
| `tools/schemas/director-ai.schema.json` | **Tools** | `rally.counter` in the three levels (optional) |

`probes/landt.gd` is the trace of item 36 step 2 (a scratch copy's root, `-- <matches> <seed0>`).

## The rules as built

- **Item 35:** `rally.linkWorth` is 1.0. The key stays.
- **Item 37 step 2: the counter-rush is as sure after all three answers.**
  - **Found:** 23d item 9's recoil flip "when he lands" was never built. The flip's window opened only out of a knock-back, a pop and the air tech, so a rally's landing had no flip, and item 37's flip had nothing to hang on.
  - **Built now:** when a rally's body lands (World's land contact: a skid, a tumble or a slam), his window opens as a knock-back skid's does. A dodge tap in its first `windowTicks` (10) flips him out of the journey, and he lands set with his counter-rush. The AI flips on its level's `brawl.recoil.flip` (0.3, 0.6, 0.85), as out of a knock-back.
  - **The wall kick:** its rush blow is the counter-rush too. It marks the turn, and it lands on a committed chaser through his guard (a perfect block still answers it), as item 30 made the tech's.
  - **The rally stays open** while his answer is under way: his flip in the air, his kick's push, his counter-rush.
- **Item 37 step 3:** the defending AI's counter-rush share after any of the three answers in a rally is its level's `rally.counter` (0.7, 0.85, 0.95), in place of the recoil flip's (0.5, 0.7, 0.9).
- **Item 36: nothing ships.** QA's runner counts every link across both hands, the turn's send as one (fa6f727a), and its 200 matches read a median of 2. Before the EP's word that the row passes, the trace and two levers were read on 40 matches; they stay in Encounter's scratch, for the record and in case links fall again:
  - **The trace** (`probes/landt.gd`, 10 matches, with 35 and 37 in): of 25 "landed" ends, 22 had no link drawn and 3 had the chase arrive after the landing. None popped.
    - Of the 22, 11 were the AI's share (its keyed draw over 0.9).
    - Most of the other 11 were ki. The AI drew its link with under 20 ki, and a draw made short of the price is dropped for good, though the journey ran on (median 157 ticks, at 5 ki a second).
    - The short journeys (5 of 25, 30 ticks or less) ended at a face, in his flip or in water. One was an opening; the rest were Plate Chase's line. None was the planner's pick for a link.
  - **GD's first pick** (a neutral-stick link's send whose predicted journey, the flight and its skid, is shorter than the chase is left out; Plate Chase's neutral line lifted alike) **changed nothing**: links 2.23 a rally with it and without. A flight's prediction doesn't see faces or flips, and the planner's link sends weren't the short ones.
  - **The ki lever** (in its own rally, the AI's drawn link waits for the zip's price while the body flies; the share and the price stay) moved links from 2.23 to 2.46 a rally, with 51 of 191 rallies having none, from 56 of 197. On 40 matches the median stayed at 1.

## What it reads

On fa6f727a with the park applied, read as QA read HEAD (`docs/qa/rally-read-fa6f727a.md`): a scratch export with `rally`, `brawl.launcher.anywhere`, its `answer` and `water` on, QA's runner, 200 matches, `--jobs=3`, below-normal priority.

| Row | HEAD (QA, 200) | With the park (200) | Band |
| :--- | :--- | :--- | :--- |
| Links a rally, median (item 36's count) | 2.00 | **2.00** (2,290 links in 924 rallies, 2.48 a rally; 266 with none) | 2 to 4 |
| Links a rally, last hands only | 1 (1.90 a rally) | 1 (1.82 a rally) | reported |
| Rallies that turn | 11.3% | **18.6%** | 15 to 40% |
| Rallies a match | 4.86 | 4.62 | 3 to 10 |
| Dazes a match | 5.67 | 5.75 | 2 to 8 |
| Repeat links; ended by repetition | 0.1%; 0.0% | 0.3%; 0.0% | at most 25%; 20% |
| Rally time of match time | 6.0% | 5.9% | at most 25% |
| Sells a daze | 1.54 | 1.53 | reported |
| Full launches a match | 7.26 | 7.55 | 6 to 12 |
| Match length median; p10; p90 | 392.7; 290.8; 519.1 s | 389.8; 288.6; 509.8 s | p10 at least 300 (item 34: not the rally's gate) |

- **On 40 matches** (seeds 1 to 40) turns read 16.2% and links a median of 1 (2.23 a rally). The median of a whole count flips at 40, so read it on 200.
- **The masher stage** (100 matches a job): `masher.medium` 47.0% (35 to 50%, pass); `newcomer.wins.medium` 9.0% (10 to 50%, fails, as HEAD's 7.0% does); `newcomer.wins.easy` 77.0% (HEAD 79.0%, pass); the first-launch rows 100% at both levels.
- **Switches off:** the golden is HEAD's, byte for byte. validate 269 files 0 errors, self-test 9154 of 9154, import clean. All 35 of Encounter's gate runs exit 0: npm, parity, determinism (and `--intro`), seam, anim_check, the lead, joint and held scans, cue, reads, hud, brawl cases, World's five tools, QA's run-all, flash worst and count, mash, the nine input tests and the loader. So do Rendering's 16 headless checks (`docs/rendering/README.md`'s table, cue with `--profile=spaced`; outline and cull need a window), split_sweep and campaign_episode.
