# The rally's third tune (parked 2026-10-26)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-26.md` §2j items 39 and 40, on the rally tune's second pass as landed (741c8483). Under `rally.enabled` (false on main), so the golden doesn't move. `rally.linkWorth` stays 0.8 (item 41): this park changes no data.

## To build it

On main with `../rally-tune2/` landed (741c8483 or later): `node rt3.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/rally.gd` | Encounter | Item 39: `_landing` opens the flip only at a land contact his flight doesn't carry on from in the same tick. Item 40: `waitsKi` (new); the landed end's reason is `ki` when the attacker is short of the next link's price |
| `sim/director/chase.gd` | Encounter | Item 40: in its own rally the AI's link is drawn at its share whatever its ki, and its start waits for the zip's price while the body flies |

## The rules as built

- **Item 39: the flip is at the landing that would end his flight.**
  - World tells each contact of a journey as an event. A skid, a tumble or a slam is a `land`. A bounce off the ground, a glance off a face (Simulation's ricochet) and a skip across water are a `bounce`. A contact the body leaves the ground from again is followed in the same tick by a `left_ground`.
  - The skip and the glance were never landings here: they are bounces, and the flip read only `land`.
  - The spike's bounce off hard ground was one. A steep landing at speed is a slam, and its hop is a `land` then a `left_ground` in the same tick. It opened his flip, and the AI flipped out of the bounce at its `brawl.recoil.flip` share (0.3, 0.6, 0.85). Now the tick's last contact decides: a `land` opens the window, a `left_ground` after it means the flight carried on, and the window waits for the landing that ends it.
  - The flip's window is as before: a dodge tap in its first 10 ticks cuts the tumble or skid short, once a journey.
  - The tech at a link's arrival (item 8) and the wall kick at a face are untouched.
- **Item 40: the AI waits for the next link's ki.**
  - In its own rally the AI draws its link at its level's `rally.link` share (0.75, 0.9, 0.95), with its ki or without. A drawn link starts at its reaction (from the send, item 7) if the zip's price (20 ki) is there, and otherwise the moment the ki comes, while the body is still in flight. Before, a draw made short of the price was dropped for good.
  - Outside a rally, and for a player, the chase is unchanged.
  - The end (23d item 11): he lands and no link follows within `endTicks` (20), and not while his answer is under way (item 37). If the attacker is then short of the next link's price, the rally ends `ki`, otherwise `landed`. The time of the end doesn't change.
  - QA's rows key on `turned` and `teched` only, and Camera reads no reason, so the new reason touches no reader.

## What it reads

On 741c8483 with the park applied, read as QA reads main: a scratch export with `rally`, `brawl.launcher.anywhere`, its `answer` and `water` on and `rally.linkWorth` 0.8, QA's runner, 200 matches, `--jobs=3`, below-normal priority. Main is read the same way beside it.

| Row | Main, 0.8 (200) | With the park (200) | Band |
| :--- | :--- | :--- | :--- |
| Links a rally, median (item 36's count) | 2.00 (2,117 links in 871 rallies, 2.43 a rally; 243 with none) | **2.00** (2,509 links in 913 rallies, 2.75 a rally; 246 with none) | 2 to 4 |
| Links a rally, last hands only | 1 (1.83 a rally) | 1 (2.01 a rally) | reported |
| Rallies that turn | 18.5% | **17.6%** | 15 to 40% |
| Rallies a match | 4.36 | **4.57** | 3 to 10 |
| Dazes a match | 5.63 | 5.80 | 2 to 8 |
| Repeat links; ended by repetition | 0.2%; 0.0% | 0.5%; 0.0% | at most 25%; 20% |
| Rally time of match time | 5.6% | 6.0% | at most 25% |
| Sells a daze | 1.50 | 1.50 | reported |
| Full launches a match | 6.94 | **7.38** | 6 to 12 |
| Match length median; p10; p90 | 366.5; 284.0; 489.7 s | 379.4; 286.1; 540.2 s | p10 at least 300 (held for QA's autopsy) |

- **The masher stage** (100 matches a job): `masher.medium` 42.0% (main 44.0%; 35 to 50%, pass). `newcomer.wins.medium` 11.0% (main 14.0%; 10 to 50%, pass by one match, so item 38's launcher share doesn't apply). `newcomer.wins.easy` 71.0% (main 74.0%; pass). The first-launch rows read 100% at both levels.
- **QA's whole table:** 26 rows fail with the park, against 27 on main. Both builds fail the same rows except five, each within a point or two of its band's edge. On main only: the beam variant share (40.2%), finisher survival (25.7%) and §8's comeback rallies (0.29). With the park only: zips caught (31.6%, its interval over 35%) and second breath (26.8%).
- **The probes** (scratch, 20 matches; `hopt.gd` counts a rally's land contacts by whether he left the ground again in the same tick, and the flips by the last contact before them):
  - On main, 10 of 92 land contacts in a rally's flight were a slam's hop, and 13 recoil flips (8 in a rally) came out of one. With the park the hop flips are 0, and a flip in a rally comes only after the landing that ends the flight. A rally's bounces (18 on the park, 23 on main, glances among them) aren't read by `_landing` on either build. There were no skips across water in these 20 matches.
  - Main ended 60 rallies "landed". The park ended 47 "landed" and 4 "ki". On 10 matches (`landt.gd`), main had 5 links drawn with under 20 ki and dropped. The park had none, and 2 rallies ended "ki".
- **Switches off:** the golden is main's, byte for byte. validate 269 files 0 errors, self-test, import clean. All 35 of Encounter's gate runs exit 0, as do Rendering's 16 headless checks (cue with `--profile=spaced`), split_sweep and campaign_episode.
