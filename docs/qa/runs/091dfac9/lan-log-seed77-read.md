# LAN log of Orb seed-77 match (build 091dfac9), read by QA 2026-11-08

Source: homework/Files/builds/orb-lan-091dfac9/lan-log-main.txt (main PC; 126 lines, 17:57:34 to 18:12:52). Times are tick / 60. Lines are 10 s samples; frames columns cover the sample since the last line.

Match: 42924 ticks to the end (about 11.9 min); at the last line: checks matched 718, rollbacks 191, deepest 9 ticks. No desync reported.

Pauses (Orb typing notes): ticks 26425, 35095, 43103 = 7:20, 9:45, 11:58 of match time.

## Samples with over 50 ms frames >= 5, a worst frame >= 100 ms or dropped ticks >= 2

| Time | Tick | Match time | Rollbacks since last | Deepest | Ping ms | Worst ms | Over 50 | Over 100 | Dropped | Most re-run in a frame |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 18:00:16 | 9598 | 2:39 | 1 | 8 | 18.3 | 136 | 1 | 1 | 2 | 1 |
| 18:02:36 | 17987 | 4:59 | 10 | 9 | 25.1 | 101 | 8 | 1 | 0 | 9 |
| 18:06:06 | 26515 | 7:21 | 2 | 9 | 18.2 | 126 | 2 | 1 | 2 | 4 |
| 18:06:14 | 27000 | 7:30 | 9 | 9 | 15.9 | 104 | 9 | 1 | 0 | 8 |
| 18:06:24 | 27587 | 7:39 | 7 | 9 | 17.7 | 69 | 9 | 0 | 0 | 5 |
| 18:07:15 | 30587 | 8:29 | 2 | 9 | 16.7 | 106 | 3 | 1 | 0 | 8 |
| 18:07:55 | 32950 | 9:09 | 3 | 9 | 17.5 | 205 | 5 | 2 | 6 | 6 |
| 18:08:06 | 33596 | 9:19 | 7 | 9 | 17.4 | 101 | 6 | 1 | 0 | 6 |
| 18:08:31 | 35095 | 9:44 | 18 | 9 | 16.7 | 129 | 19 | 4 | 6 | 8 |
| 18:09:40 | 35400 | 9:50 | 10 | 9 | 30.9 | 69 | 11 | 0 | 0 | 7 |
| 18:10:00 | 36577 | 10:09 | 15 | 9 | 16.7 | 111 | 17 | 1 | 1 | 8 |
| 18:10:51 | 39589 | 10:59 | 15 | 9 | 31.2 | 91 | 22 | 0 | 0 | 8 |
| 18:11:01 | 40161 | 11:09 | 26 | 9 | 16.7 | 175 | 15 | 2 | 5 | 9 |
| 18:11:22 | 41390 | 11:29 | 9 | 9 | 15.9 | 82 | 5 | 0 | 0 | 9 |
| 18:11:32 | 41998 | 11:39 | 1 | 9 | 17.7 | 123 | 1 | 1 | 1 | 1 |
| 18:11:48 | 42924 | 11:55 | 3 | 9 | 18.7 | 145 | 5 | 3 | 5 | 4 |

## What the log can and cannot say

- **It holds no inputs**, only 10-second counters, so it cannot rebuild the match. The desktop LAN build wrote nothing else during or after the match: the only files changed in `%APPDATA%/Godot/app_userdata/Orb Combat EX` between 17:50 and 18:14 are four `logs/godot*.log` files and `ui_prefs.json`. The end-of-match "save a replay" prompt is the web page's black box; a search of `net/`, `render/` and `ui/` finds no black-box save in the desktop or LAN build.
- **The data was there while the match ran:** `net/session.gd` `confirmedLog` rebuilds every confirmed input from tick 0, and `net/desync.gd` already turns that into a SimReplay file (used for desync reports). Closing the windows ended it. The seed-77 match cannot be replayed.
- **Orb's notes fall at the three pauses** (ticks 26425, 35095, 43103).
- **Frame spikes and rollbacks go together.** Every sample with 5 or more frames over 50 ms also shows 2 or more rollbacks since the last line (most 7 to 26), and "most re-run in a frame" is 8 to 9 ticks: a rollback re-simulates up to 9 ticks in one frame. Worst frame 205 ms at 9:09 (tick 32,950). Orb's 9:49 note sits in two samples with 19 and 11 frames over 50 ms and 18 and 10 rollbacks (9:44 and 9:50).
- **A hypothesis, not tested:** "background buildings disappear and reappear" while rollbacks run may be the picture showing a corrected world after a re-run (a building the first run had standing or fallen, the re-run the other way). The log cannot show it; a rollback check with building state drawn would. Netcode and Rendering.
- Orb's 7:22 note ("a patch of air that forced me upwards") is a pause at tick 26,425; the log has no sign of it. The next sample (7:21 to 7:30, 9 rollbacks) is after the pause.
