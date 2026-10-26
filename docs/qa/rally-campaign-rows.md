# QA's rows for the rally and the campaign (2026-10-26)

The EP's brief of 2026-10-26: the rally's rows (`rulings-2026-10-23d.md` §7 with `rulings-2026-10-26.md` items 9 and 11) and the campaign's (`campaign.md` §7, item 5). **Rows and tools only: nothing was run on a build that has either.** The rally is Encounter's park (`docs/director/pending/rally`, switch `rally.enabled`), not on main; the campaign does not run. Every row below is PENDING until its cues or its record exist, and reads on its own the first time they do. Selftest 29 of 29.

## The rally (`qa/godot/records.gd`, `bands.js`)

`records.gd` reads Encounter's cues (`daze`, `sell`, `rally_link`, `rally_turn`, `rally_tech`, `rally_end`, field names from the park's README) into `rec.rally`: dazes and their sources, sells and their kinds, rallies opened, the rally's links as a list of base kinds, each rally's end (links, turns, live ticks, why, whether a tech by itself came). A build or a run without `rally.enabled` sends none of them, so `rec.rally.has` stays false and every row below is PENDING.

| Row | Band | How it is read |
| :--- | :--- | :--- |
| Dazes a match | 2 to 8 | `daze` cues with text `start`, over the matches; the sources are listed beside it |
| Rallies a match | 3 to 10 | `rally_end` cues |
| Links a rally | **median 2 to 4** | each `rally_end`'s `n` (links so far). A rally's links are their own row (item 11) |
| Two links of one kind in a row | at most 25% of links | the base kinds of a rally's links, in order |
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
