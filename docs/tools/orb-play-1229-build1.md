# Orb's 1229 play against Sunday's build 1 (Tools, 2026-11-08)

Kept build orb-first-play-1931a0f8-7a5a2d2c (main 1931a0f8). Rows: `runs/1931a0f8/b1-ledger-1229.txt` and `.json`. Earlier counts: `orb-play-1229-report.md` (first count), `orb-play-1229-counted.md` (e80b8e3d, counted once).

## The replay does not reproduce on this build (so read it as direction)

On e80b8e3d the saved match reproduced exactly. On this build it does **not**: the build's rules differ from the one Orb played (refusal knocks on, the press answers, the kept flick, the chord pick, the slam), so the same recorded presses make a different fight and the ledger's rows are a replay on this tree, not the moments Orb lived. The press count is the same (760: the presses are the file's); what happened to each press is not. Do not compare row by row.

## The counting rule, beside both figures

- **Counted once across a hit-stop**: a press of one kind on consecutive ticks is one press (399 repeats not counted). A guard held up and a dodge open read as honoured.
- **Answers (2026-11-08)**: `power_start`, `power_burst`, the transform event and `press_refused not_ready` count as answers to a power press or a transform. `not_ready` stays a refusal with its reason (verdict "refused": not silent, not honoured).
- **The 15% figure** (116 of 760) was read on e80b8e3d, which has none of these cues, so a power press or a transform with no form could only be silent. **This build's figure is 30% (225 of 760)** with the answers counted, and 226 (30%) with the one press answered only by them taken as not answered: the answers move one press here.

## The figures

| | Presses | Honoured | Silent | Refused | Partly | Not honoured |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| e80b8e3d (reproduced exactly) | 760 | 644 | 61 | 41 | 14 | 116 (15%) |
| Build 1 (does not reproduce) | 760 | 535 | 97 | 96 | 32 | 225 (30%) |

Where it moved (build 1): the game now says no with a reason far more often: refusals 41 to 96, mostly `press_refused locked` 47 (a press while locked in an exchange), `queue_expired` 16, `queue_full` 11, `press_chase_no_ki` 19; the stick's own `"8"`, `"0"`, `refused` and `replaced` reasons are gone from the list (the stick now says `late`, `chase`, `hit`, `not_yours`). Silent presses went 61 to 97 (locked 69, free 15, launched 10, down 3), by kind: heavy 40, sig 27, dodge 8, light 8, right stick 8, guard 2, power 4 of 8. A power press: 8, none honoured, 2 refused, 2 partly, 4 silent; a transform: 3, 2 honoured (one by the transform answer), 1 refused (`not_ready`). Right stick by direction: away 41 (6 silent), down 19 (1 silent, 1 partly, 2 refused), up 4, toward 5 (1 silent).

## Reading it

Refused rose 41 to 96 because the game now says no with its reason where it said nothing or something unreadable; silent rose 61 to 97. Those two moves are not the same thing and a diverged replay cannot separate them: a different fight puts different presses into locked exchanges, where most refusals and most silence sit. What can be said: the stick's unreadable reasons ("8", "0", "refused") are gone; a power press and a transform now get answers (4 of 8 power presses still silent); a press made in a freeze is told. What cannot be said from this file is whether the build answers a press more or less often than e80b8e3d did. The way to know is Orb's next play file on this build: its replay will reproduce on its own tree, and the same ledger reads it with the counting rule above.
