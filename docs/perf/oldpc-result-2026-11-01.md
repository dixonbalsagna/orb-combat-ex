# The old-PC test, Orb's result (Performance and Platform, 2026-11-01)

For the EP. Orb ran `oldpc-kit-dafc348f` on the old PC (Intel Core i5-6600K 3.5 GHz, 4 cores, 15.9 GB, GeForce GTX 1080, Windows 10 Pro, Firefox 159, window 925 x 846 on a 2048 x 1152 screen at 125%) and brought back `homework/Files/oldpc-result-20261101-1813.json`. **Orb's ruling: it counts as a success. It is one, for this machine.** The kit ran from a double-click to one result file with no prompt, no network and nothing to install; the two-processor check and the sim speed run finished; the browser part finished.

**Plainly: a GTX 1080 is not the ADR 0011 budget machine.** The budget machine is the old laptop with integrated graphics. That number is still unmeasured. This result says what a 2015 desktop CPU with a strong graphics card does; it says nothing about integrated graphics. (The kit's step 5, the board's own HD 530 on this same PC, would be the nearest cheap read; it was not done.)

## Two processors, one match

Compared with this PC's quiet file (`homework/Files/mainpc-result-quiet-20261101-1137.json`, Ryzen 7 9800X3D, 16 threads) by `compare-results.mjs`, with the kit's own imported project for Netcode's compare:

- **My hash trace: SAME on both processors, 366 gameplay hashes compared (three planets, a first match and a rematch each, 7,200 ticks), none differ.**
- **Netcode's two-PC check: THE SAME, exit 0: the Ryzen and the i5 agree on all 90 lines of its report** (build dafc348f, protocol 5, data hash 7303efb405a2f585, 5,400 ticks, 17 swings, every state hash).

So the sim is bit-identical across a 2026 and a 2015 processor, which is the thing the rollback netcode and the replays rely on. A first, real answer to "two different processors": yes. (One pair of processors; both x86-64 Windows; not ARM, not another OS.)

## How fast the sim runs there

| | Ryzen 7 9800X3D (this PC, quiet) | i5-6600K (old PC) | old / this |
| :--- | ---: | ---: | ---: |
| Mean sim tick | 0.31 ms | 0.67 ms | 2.2 x |
| Fixed float64 job | 147 ms | 329 ms | 2.2 x |
| 99th percentile tick (the six matches) | 0.78 to 1.02 ms | 1.54 to 1.92 ms | |
| Worst tick, six matches | 6.2 to 13.3 ms | 14.2 to 23.6 ms | |
| Ticks over 16 ms (of 43,200) | 0 | 11 | |
| Match build, first match | 0.8 to 1.1 s | 1.8 to 4.4 s | |
| Netcode's check: tick mean / worst | 0.66 / 13.3 ms | 1.32 / 27.4 ms | |
| Netcode's snapshot take / restore | 0.28 / 0.27 ms | 0.65 / 0.60 ms | |

The sim alone is cheap on the old machine: a mean tick of 0.67 ms is 4% of a 16.7 ms frame, and a rollback snapshot costs well under a millisecond. The worst ticks (up to 27 ms) are most likely the launch and swing ticks of `docs/perf/orb-first-play-spikes-2026-11-01.md`, about twice as long here (not traced: the file keeps only the ten worst per match).

## The game in the browser (Firefox 159, 120 s)

46.8 frames a second; frame time p50 20.8 ms, p95 34.7, p99 62.5, worst 187.5 ms (188 ms at 11 s, 160 ms at 81 s, 153 ms at 49 s). Over 34 ms: 471 of 5,644 frames; over 50 ms: 86; over 100 ms: 14. The sim fell behind: **28 of 118 seconds ran under 50 ticks a second** (mean 59.7, the slowest second 0), so in those seconds the game was running slow, not only drawing slow. The game's state appeared 44 s after the page opened and the 120 s measure began at 100 s. The kit's own verdict: WARN ("plays but does not hold 60", "a stall of 187.5 ms"). Orb saw the same impact drops (the frame drops at impacts) as on the main PC.

What this does and does not say:

- The browser result is a WARN on a machine with a strong graphics card, so the game does not hold 60 on an old CPU through Firefox. With a mean sim tick of 0.67 ms, the cost is in the draw and the page (Firefox, one main thread at 3.5 GHz), not in the sim.
- It is **one run, in Firefox, in a 925 x 846 window at 125% scaling**: the kit's steps said Chrome or Edge, Firefox was the default browser there. Firefox reports its renderer as "GTX 980 or similar" (it hides the real card); Windows lists a GTX 1080 (driver 32.0.15.8228).
- The game in the kit is **not the build Orb played on the main PC** (below).

## What the kit's game was, against `orb-first-play-018b4edf`

| | The kit's game (`oldpc-kit-dafc348f`) | Orb's first play (`orb-first-play-018b4edf-fddd34b4`) |
| :--- | :--- | :--- |
| Commit | dafc348f | 018b4edf (11 commits later) |
| Parks on top of the commit | none (a HEAD-only build: `stack-preview.mjs --only none-head`) | 58 (stack key dc01cd6e4c43): rendering-tile-ground, near-towers, far-tiles, water-sheet, building-band, crater look and scar, foot-walls and more; vfx-meteor-trail, beam-front, clash look; camera-swing 1 to 11 and the split vision; load pace |
| Switches on | 17: gen2, biome, water, surface, interrupts, floor, calmTurn, turn, rightStick, gen3, go, swing, everywhere, arc, beamFront, kick, struggle | 42: those 17 and quickRead, hapticLadder, hapticIncoming, hapticRefused, webRumble, specialsOff, signatureRtOnly, blackbox, meteor, tiles, craterlook, ending, follow, lightStops, grapple, driver, driverOnRb, stances, phrases, vsHuman, firstMeteor, mixed, soundTug, soundMoments, soundCarry |
| Page address | `/game/index.html?planet=7&preview=1&tiles=1&meteor=loud` | `index.html?planet=7&meteor=loud&tiles=1&go=1&blackbox=1` |
| Effect of the words `tiles=1`, `meteor=loud` | **none: the tree has no `render/core/tile_ground.gd` and no `data/vfx/meteor.json`** (the preview build said "WAITING, not in this build: tiles, meteor, quickRead, hapticLadder, hapticIncoming, mixed"); the result's own probe reads `meteor trail undefined` | on |
| Black box, `go=1` | no black box; no `go` (the start card is the page's) | on |

So **the old PC showed the plain commit: the old ground, no tile ground, no meteor trail, none of the 58 parks' looks, no black box.** Whatever looked odd to Orb on that PC cannot be a render park's doing; it is either the older render path of dafc348f or Firefox on that machine. The kit builds its game from the commit it is given: for a look-faithful test, build it from the same stack as the first play (`stack-preview.mjs` with the parks, then `build-kit.mjs --site` that folder).

## Limits

One run; one pair of processors; Firefox, not Chrome or Edge; a different build from Orb's first play; the budget machine (integrated graphics) not measured.
