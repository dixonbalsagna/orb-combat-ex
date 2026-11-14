# How many matches a cell needs (QA, sprint A1, A-AI-11; written 2026-11-14)

**Rule from today: every win rate QA reports carries its 95% interval and the tree or build it was read on, in the same row.** A table without both is not a reading.

## Method

- **A win rate** (matches won of matches played, draws and timeouts counted as not won and named): the **Wilson score interval**, 95% (z = 1.96). It is correct for small samples and for rates near 0% or 100%, where the plain "plus or minus" is not.
- **Two cells against each other** (a level against another, slot 0 against slot 1): **Newcombe's hybrid interval** for the difference of two rates, built from the two Wilson intervals. Two cells are told apart only if the interval of the difference excludes 0.
- **A median, a p10 or a p90** (match length, collateral): a **bootstrap**, 2,000 resamples of the matches, 95% percentile interval (as `qa/godot/city-read.js` already does).
- A rate's interval is for the seeded set read, a sample of the game's matches; it says nothing about a different scripted player.

## The numbers (Wilson, 95%)

Half-width of the interval in points, by matches in a cell and the true rate (the bands X-06 proposes are Easy 60 to 80%, Medium 35 to 55%, Hard 10 to 30%, centres 70, 45 and 20):

| Matches in a cell | at 20% (Hard's centre) | at 45% (Medium's centre) | at 70% (Easy's centre) |
| ---: | ---: | ---: | ---: |
| 40 (today's cell) | 10.5 to 34.8 (±12.1) | 30.7 to 60.2 (±14.7) | 54.6 to 81.9 (±13.7) |
| 100 | 13.3 to 28.9 (±7.8) | 35.6 to 54.8 (±9.6) | 60.4 to 78.1 (±8.8) |
| 200 | 15.0 to 26.1 (±5.5) | 38.3 to 51.9 (±6.8) | 63.3 to 75.9 (±6.3) |
| 300 | 15.9 to 24.9 (±4.5) | 39.5 to 50.7 (±5.6) | 64.6 to 74.9 (±5.2) |
| 400 | 16.4 to 24.2 (±3.9) | 40.2 to 49.9 (±4.9) | 65.3 to 74.3 (±4.5) |

## What the three questions need

1. **Telling the three levels apart** (the band centres are 25 points apart): Easy against Medium separate from **61 matches** a cell, Medium against Hard from **54**. So 100 a cell tells the levels apart; 40 does not (the intervals at 70% and 45% overlap).
2. **Calling a reading inside its band** (the whole interval inside a 20-point band): a reading at the band's centre needs **about 95 matches**; a reading 5 points from the edge needs about **400**; a reading within 3 points of an edge cannot be called at any sample size we will run, and is reported as "on the edge".
3. **Two fighters in two slots** (each fighter in each slot, a balance reading): 100 matches a side gives ±9.6 at 50%, enough to see 50% against 70%, not 50% against 58%. A claim of "within 5 points of even" needs about 400 a side.

## What QA runs from now on

- **First reading of a cell: 200 matches** (±5.5 to ±6.8 at the centres): it tells the levels apart with margin and calls a centred reading in band.
- **Extend to 400** where the reading is within 7 points of a band edge, using fresh seeds (the next 200), and say so.
- A cell of 40 is a smoke, not a reading, and is labelled so.
- Seeds are recorded with the run (base seed and count) so the batch can be repeated; the matches are independent seeded runs, so cells add up.
- **Tree or build** in every row: the build's commit and packed-data folder, and the data hash the run read (`qa/godot/data_hash.gd`; equal to the saved play file's `data` for the same build).
