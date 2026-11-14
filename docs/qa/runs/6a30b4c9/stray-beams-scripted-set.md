# Stray stick beams, scripted set (scripted human, RB + right stick then X, against easy; 60 matches, seeds 1 to 60, whole ring, power model on, travel 1.5)

Tree: build 6a30b4c9 packed data + the park code hunks; ownMove.dropOnPress set at run time (0 old wait, 1 dropped by a new press).

| | dropOnPress 0 | dropOnPress 1 |
| :--- | ---: | ---: |
| RB holds | 4532 | 4708 |
| Stick beams thrown by the scripted human | 235 | 221 |
| **Late: thrown after a new press (X) came after the release** | **30** (12.8% of beams thrown) | **1** (0.5%) |
| Median ticks from the release to a late beam | 53 | 40 |
| refused: close | 156 | 174 |
| refused: ki | 2 | 3 |
| refused: late | 13 | 0 |
| refused: replaced | 0 | 99 |
| refused: soon | 168 | 189 |
| refused: taken | 466 | 474 |
| Refusals in all | 805 | 939 |
| Median match length, s | 228 | 230 |
