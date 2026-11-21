# Parked, for QA: the 2v2 read (two_fights_read.gd)

Encounter, 2026-11-02. Game Design's QA rows for 2v2 (`docs/design/two-v-two.md`, "What brings the fights together"), as a headless read of four computer fighters in two fights. It's read-only: it changes no data and forces `outside.enabled` on for its own run. **Apply after `../two-fights-end/`:** `git -c core.autocrlf=false -c core.eol=lf apply two-fights-read.diff`.

```
godot --headless --path . --script res://sim/director/tools/two_fights_read.gd -- <matches> <baseSeed> [--cap=72000] [--spread=15000]
```

Gen 3, planet 7, baked as the page bakes it; setup `{"fights": 2, "cross": true}`; all four computer fighters. It prints one `ROW` a match and a `TOTAL`:

| Row | How it's counted |
| :--- | :--- |
| All four within `--spread` | Ticks with the four's spread on the ring (round their middle) at most 15,000 units |
| Rescue flights | A computer fighter's partner, in the other fight, on the brink: once a brink, however the rescue flickers |
| Winner flights | Once per finished fight's standing body |
| Brink calls, blows from outside, beams stopped | The cues `brink_call`, `outside hit`, `beam_stopped` |
| Rejoins | `S.stage.rejoined` |
| How it ended | `SimCore.ended`, the team out and when; or the cap |

## First read (2 matches, seeds 1 and 2, the kept build's page switches, cap 20 minutes)

| | Match 1 | Match 2 | Average | Game Design |
| :--- | ---: | ---: | ---: | :--- |
| Length | 821 s | 699 s | | 5 minutes or more |
| All four within 15,000 | 59.5% | 8.9% | **36.2%** | 25 to 50% |
| Rescue flights | 6 | 2 | **4.0** | 2 to 4 |
| Winner flights | 2 | 2 | 2.0 | |
| Brink calls | 6 | 3 | 4.5 | |
| Blows from outside | 31 | 127 | 79 | |
| Beams stopped on someone else | 1 | 2 | 1.5 | |
| Rejoins | 0 | 0 | 0 | |
| Ended | team 0 out | team 0 out | | |

**Two matches are a smoke test, not a read:** the closeness goes from 9% to 60%. Things for QA to read on more:
- **Team 0 lost both.** That could be slot order or the seeds.
- **No rejoin happened:** each match ended with the second team-0 fighter down before a rejoin could. Whether the 2-on-1 after a finished fight (127 blows from outside in match 2) is too strong is the row to watch.
- **The 10-minute version** of the same seeds read 27.2% within 15,000 and 13 rescues a match, but that count let one brink count many times. This is the corrected count.
