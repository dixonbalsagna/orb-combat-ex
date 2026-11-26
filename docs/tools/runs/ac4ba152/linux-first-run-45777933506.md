# Linux first run, re-taken with the fixed script (Tools, 2026-11-25)

Run 45777933506 on 0c87f354 (the same game as ac4ba152, build 0.1.1: only docs/ and tools/ differ), ubuntu-24.04, virtual display, software GL. A performance reading, never a flash reading. Text and numbers only, from the run's log.

**The keys now close the game** (pause, Quit, "Close the game"), which no earlier run did: the game had been on a new profile, where the How to play card held the match after the warning. The script now starts the game with its own settings, that card marked as seen. The first run on ac4ba152 with the old script (45773667206) had closed by the window manager only.

```
ok   first-picture: after 151.2 s
ok   window-focus: at 163 s: window 4194307 focused
ok   notice: at 176 s: Return pressed by the workflow on the virtual display
ok   mode-list: at 183 s
ok   fighter-pick: at 192 s: 1 key(s)
ok   match-start: at 254 s: 3 key(s)
ok   match-play: at 344 s
ok   pause: at 350 s: 1 key(s)
ok   quit-question: at 365 s: 13 key(s)
ok   close-the-game: at 368 s: 2 key(s)
ok   match-built: at 368 s
ok   quit-keys: closed -1.5 s after the last key
ok   program-closes: closed by the keys
Build: 0.1.1 (commit 0c87f35, 2026-11-25). Machine: Intel(R) Xeon(R) 6975P-C, virtual display, software GL (Mesa), 15 GB, Linux 7.0.0-1014-aws. Window 1280x720 (Xvfb).
**Every step went as planned.** A performance reading, never a flash reading.
| first-picture | the program draws (its first frame-rate line) | ok: after 151.2 s |  |
| match-built | a match was built after the keys (the program printed its pair-bake line, or its data folder holds a field cache or a report) | ok: at 368 s |  |
| quit-keys | the pause, Quit and "Close the game" keys close the program within 10 s (reported only, never a failure of this run) | ok: closed -1.5 s after the last key |  |
| program-closes | the program closes (here by the keys) | ok: closed by the keys |  |
- Engine start to the first picture: 151.2 s
- Frame rate settled (80% of steady) after: 0 s
- Frames a second over 342 steady seconds: mean 11.6, median 10, slowest second 1, 5th percentile 6, fastest 31; 1% of seconds at 30 or more, 0% at 58 or more
- The game's own load lines: pair bake 279 ms (1009 poses), incremental bake drained at tick 3224
- The program closed: yes, by itself; the run took 368 s
Frames a second by ten-second stretch (from the start): 0-10 s: 19.4, 10-20 s: 5.5, 20-30 s: 7.8, 30-40 s: 15.8, 40-50 s: 15.6, 50-60 s: 15.6, 60-70 s: 15.6, 70-80 s: 15.4, 80-90 s: 15.3, 90-100 s: 15.4, 100-110 s: 15.4, 110-120 s: 15.4, 120-130 s: 15.4, 130-140 s: 15.6, 140-150 s: 13.8, 150-160 s: 12.3, 160-170 s: 12, 170-180 s: 9.9, 180-190 s: 10.2, 190-200 s: 10.1, 200-210 s: 10.4, 210-220 s: 10.3, 220-230 s: 9.1, 230-240 s: 10.2, 240-250 s: 9.3, 250-260 s: 8.3, 260-270 s: 8.6, 270-280 s: 8.9, 280-290 s: 8.9, 290-300 s: 8.6, 300-310 s: 8.2, 310-320 s: 8.5, 320-330 s: 8.7, 330-340 s: 9.1, 340-345 s: 9.2
```
