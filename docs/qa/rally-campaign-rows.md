# QA's rows for the rally and the campaign (2026-10-26)

The EP's brief of 2026-10-26: the rally's rows (`rulings-2026-10-23d.md` §7 with `rulings-2026-10-26.md` items 9 and 11) and the campaign's (`campaign.md` §7, item 5). **Rows and tools only: nothing was run on a build that has either.** The rally is Encounter's park (`docs/director/pending/rally`, switch `rally.enabled`), not on main; the campaign does not run. Every row below is PENDING until its cues or its record exist, and reads on its own the first time they do. Selftest 29 of 29.

## The rally (`qa/godot/records.gd`, `bands.js`)

`records.gd` reads Encounter's cues (`daze`, `sell`, `rally_link`, `rally_turn`, `rally_tech`, `rally_end`, field names from the park's README) into `rec.rally`: dazes and their sources, sells and their kinds, rallies opened, the rally's links as a list of base kinds, each rally's end (links, turns, live ticks, why, whether a tech by itself came). A build or a run without `rally.enabled` sends none of them, so `rec.rally.has` stays false and every row below is PENDING.

| Row | Band | How it is read |
| :--- | :--- | :--- |
| Dazes a match | 2 to 8 | `daze` cues with text `start`, over the matches; the sources are listed beside it |
| Rallies a match | 3 to 10 | `rally_end` cues |
| Links a rally | **median 2 to 4** | each `rally_end`'s `n` (links so far). A rally's links are their own row (item 11) |
| Two links of one kind in a row | at most 25% of links | the kinds of a rally's links, in order: the cue's `source` when set (an own link is its own kind, GD 23d item 17: a Palm Turn after an overtake is no repeat), else the base kind (`text`) |
| Rallies ended by repetition | at most 20% | a rally that ended `teched` after a tech by itself (`rally_tech` with `k` 1) |
| Rallies that turn at least once | **15 to 40%** | `rally_end`'s `k` (turns) of 1 or more. **The band stays 15 to 40**; the widening to 10 to 40% for AI v AI is applied only on GD's word that links and turns still conflict (item 9) |
| Rally time | at most 25% of match time | the rallies' live ticks over the matches' fight time |
| Sells a daze | reported | `sell` cues over `daze` starts |
| **Full launches (L16)** | 6 to 12, **a rally counts once, by its opening send** (item 11) | `launch_power` cues with `k` 1, **less those within 3 ticks of a link's landing** (`rally_link` with a base kind): a link's send is not a launch for this row. The links are the row above. Before the rally exists the row counts every full launch, as before |
| Match length, the lit-B newcomer (L17), the masher | unchanged | the existing rows |

To read them: a scratch export of main with the park applied (`rl.cjs`, after `launch-spike` and `water-surface`; `--check` first, never at the repo root) and `rally.enabled` true in the scratch data, then `node qa/godot/run-arm.js --count=200`.

## The campaign (`bands.js`, `rec.campaign`)

The campaign is not built, so these rows read a record that a campaign run will have to write. **What I need from the build** (a `campaign` object in each episode's record):

```
{ episodeSec,                       // the episode's length in seconds
  arc,                              // the arc's id
  columns: [{ n: 1..5, ring: "Half", turned: bool,
              places: [{ fromPair: signed columns }] }],   // the places of the column, from the pair
  rescues: { n, won }, rematches: { n, won }, partner: { stages, won },
  templates: [ids, in play order],  // the stage templates of the episode
  arcTemplates: { id: count over the arc so far } }
```

| Row | Band |
| :--- | :--- |
| An episode's length, median | 40 to 50 minutes |
| A column's places from the pair, each way, on a Half ring (columns 1 to 4; the climax may lie farther) | every place 322 to 806 columns |
| Columns 1 to 4 that turn the ring (item 5: raise `minGain` first, then lower `turn.bonus`) | 40 to 60% |
| Stages won with a partner who joined mid-stage | read only (to tune x1.6) |
| Rescues won | 30 to 60% |
| Rematches won after "Previously on" | 50 to 75% |
| Templates repeated | none inside an episode (hard); at most 3 across an arc |

## Files (uncommitted)

`qa/godot/records.gd`, `bands.js`, `selftest.js`, and this document.

## Addendum (2026-10-26): the split first-launch rows and the masher's answer (rulings-2026-10-26 items 19 and 21)

Rows only; no run. They read on the next newcomer and masher jobs (`node qa/godot/masher-only.js`, easy and medium).

| Row | Band | How it is read |
| :--- | :--- | :--- |
| `newcomer.thrown60.<level>` | at least 75% of matches | the first launcher the lit-B newcomer throws inside 60 s of the first brawl: an opening he used (`launcher_close` used), or the first that landed if none was announced. `players.gd` writes `firstThrowSec` |
| `newcomer.landed120.<level>` | at least 75% of matches | the first launcher that lands inside 120 s of the first brawl: **a send (the `launch` event) or a pop** (the `pop` cue, target the launcher). `firstLaunchSec` now counts pops too, so `newcomer.first60` reads a landed pop or send as item 19 asks |
| `newcomer.first60`, `newcomer.wins` (L17) | unchanged | reported beside the two. **L17 holds if they pull apart; the two rows then stand in the first-60 row's place** (item 19) |
| `masher.answer.<level>` | reported | the AI's perfect blocks per press of the banded masher (the `perfect_block` cue by the AI, or the brawl's `stagger` cue with text `perfect_block` on the masher), beside `masher.<level>` (35 to 50%). Item 21's lever: raise the share in small steps until the masher reads about 45% |

Selftest 30 of 30. A one-job smoke in my scratch (4 matches) shows the new fields written (`firstThrowSec` 5.3 to 8.1 s, `presses` and `perfectBlocksByAI` from masher.gd). Saved jobs from before today read the thrown and answer rows as PENDING.

## Addendum 2 (2026-10-26): a turned hand is not a rally (the links' median 1 against 2)

`records.gd` kept an end for every `rally_end`, "turned" ones included, so a rally that changed hands made two entries, the first usually short. Encounter's probe skips the "turned" end and reads the last hands' links as the rally's. Now: a `turned` end adds its links and live ticks to a carry and writes no entry; the rally's final end writes `[last hands' links, turns, live ticks of all hands, why, auto-tech, links of all hands]`. So rallies a match, the turn share, rally time and the auto-tech share count one rally per opening send, and the repeat row is unchanged (each hand's links are still its own sequence, as in the probe).

- `rally.links` (band 2 to 4): the **last hands'** links, the probe's reading, until Game Design says which reading the band means.
- `rally.links.all` (reported): the links of every hand of the rally together.

## Addendum 3 (2026-10-26): the band counts every link across both hands (GD rulings 10-26 item 36 step 1)

`rally.links` (2 to 4) is now, per rally, the links of every hand plus one for each turn's own send (the new attacker's "send" after a turn); the opening send never counts, and a rally with none counts 0. A record entry is `[last hands' links, turns, live ticks of all hands, why, auto-tech, links of all hands without the turns' sends]`, so the count is entry[5] + entry[1]. `rally.links.last` (INFO) is the last hands' links alone, the probe's reading; `rally.links.all` is retired in its favour. Selftest has a turned rally whose median is 2 only when the turn's send is counted.

### The full read on the tune's commit (GD 10-26 item 34), planned
1. **Main read:** a scratch export of the tune's commit, `rally.enabled` true, `node qa/godot/run-arm.js --count=200` (3 jobs, below-normal priority, valid-run gate). The rows that matter: `2.len.p10` (whole-match, at least 300 s; the error at 200 matches is about 8 s), median 360 to 480, p90 at most 600, the rally rows, L16, L17.
2. **If p10 reads under 300 on the 200:** the same 200 seeds three more times, each with one park off, in separate scratch copies of the data: the launch answer (`brawl.launcher.anywhere.answer.enabled` false), the water's surface (`data/director/interrupts.json` `water.enabled` false), the rally (`rally.enabled` false). The parks since 23c; it read 319 s at 23c. The park whose removal brings p10 back is the one whose own sends are first in GD's lever order. Same seeds, so the three are paired against the main read.
