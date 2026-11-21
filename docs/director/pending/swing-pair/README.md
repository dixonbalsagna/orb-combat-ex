# Parked: no jolt on a launch swing's tick, and brawl swings capped at 40% of the big ones

Encounter, 2026-11-02, from QA's swing rows on the kept build (`docs/qa/cloud-reports/2026-11-02-kept-build.md` row 4): 52 of 2,395 gaps between swing starts were a jolt and a launch swing on the same tick, and brawl swings were 44% of the big ones against Game Design's 40% cap for any cause but a launch. **Two switches, both off,** in `data/director/swing.json`: `jolt.yieldToLaunch` and `brawl.shareCap.enabled`.

**Apply on the stack after `../stick-pend/`:** `git -c core.autocrlf=false -c core.eol=lf apply swing-pair.diff`. It's cut with one line of context, so it applies with or without `../swing-warm/`, and on Tools' tree `018b4edf`; all three checked.

## What it does

| | Off (today) | On |
| :--- | :--- | :--- |
| **A heavy landing that also launches** | Its jolt starts, then the launch's swing replaces it on the same tick: two starts in one tick | **The jolt waits for the tick's end** (the swing director's tick) and **goes only if no big swing started this tick.** It also yields while a launch's swing waits out its hit-stop |
| **Brawl swings** | Offered every 60 ticks of a brawl, with no limit on their share | **Not offered while they'd be over `max` 0.4 of the match's big swings,** once there have been `after` 3 |

The match's big swings, and how many were the brawl's, are counted in the high bits of a swing slot (`W_CAUSE`) that nothing reads, and only with the cap on. So with both switches off, no slot changes and the hash is the same.

## Read

8 AI-against-AI matches on the page's planet (gen 3, planet 7, the kept build's page switches), the same seeds off and on (`zz_swingpair.gd`, scratch):

| | Off | On |
| :--- | ---: | ---: |
| A jolt and a launch swing starting on the same tick | **9 of 300 gaps** | **0 of 254** |
| Brawl swings' share of the big ones | **46.9%** (67 of 143) | **32.2%** (39 of 121) |
| Jolts | 165 | 141 |
| Big swings by cause: brawl, chase, launch, form | 67, 33, 24, 19 | 39, 40, 29, 13 |

The cap lands under 40% because the share is counted with the next swing in it. 8 matches are few: QA's 60 is the read that counts.

## Not done

- **QA's whole-ring row with both on.** Swing time was already short of Game Design's 10 to 15% (8.1%), and fewer brawl swings take more from it. Game Design may want another cause to fill it.
- **Under 6 s between starts** (26% of gaps in QA's read) isn't touched: only the same tick.

## Grants

| Whose | What |
| :--- | :--- |
| Tools' | two switches: `{ id: 'joltYield', file: 'data/director/swing.json', path: ['jolt', 'yieldToLaunch'], from: false, to: true, needs: [], optional: true }` and `{ id: 'brawlShareCap', file: 'data/director/swing.json', path: ['brawl', 'shareCap', 'enabled'], from: false, to: true, needs: [], optional: true }` |
