# Are the flash numbers real? (Tools, 2026-11-01; unfinished, gaps marked)

**The short answer, for Orb: the numbers are real, not luck, but they measure one picture size, and they are not an independent check.**

- **Not margin of error.** The same clip, built and run the same way, gives the same reading every time: five runs of the collapse at 960 x 540 gave 3.5, 3.5, 3.5, 3.5, 3.5, and five at 1024 x 768 gave 2.0 every time, with the machine anywhere from 55% to 99% busy. The count follows the frames, not the clock, so load does not move it.
- **It counts what is there.** Clips drawn with a known answer read back exactly (table below).
- **But the answer depends on the picture's size.** The same collapse reads **3.5** at 960 x 540, **2.5** at 1280 x 720 and **2.0** at 1024 x 768. Our gate is 2.5 and the standard's limit is 3, so whether the collapse "fails" depends on the size it was recorded at. That is the real uncertainty: about one flash either way across sizes. Nothing here says which size a player's screen is closest to.
- **Plain motion can read as a flash** on a very busy picture: a smooth pan over a deliberately noisy, high-contrast ground read 1.5 (slow) and 2.5 (fast), and a camera shaking back and forth over it read 9. My test ground is harsher than the game's, so this shows the method can false-alarm, not that the game does.
- **It is our own analyser, not a recognised one.** Nothing outside has checked it (see the last section).

## Known answers (960 x 540, 600 ticks, drawn on purpose)

| Drawn | Reads |
| :--- | :--- |
| nothing flashing | 0 |
| a full-screen black and white flash, 2 / 3 / 4 / 10 a second | 2 / 3 / 4 / 10 |
| 10 a second in a corner, 1.5% and 2.25% of the screen (under the standard's quarter of a window, 2.78%) | 0 and 0 |
| 10 a second in a corner, 4% and 25% of the screen | 10 and 10 |
| 4 a second, a brightness step of 5% and 9% (the standard needs 10%) | 0 and 0 |
| 4 a second, a step of 12% and 20% | 4 and 4 |
| red against grey, 10 a second | red reading 10 (general 0) |
| the detailed ground, still | 0 |
| the ground panning 120 px/s / 600 px/s | **1.5 / 2.5** |
| the ground shaking 40 px at 3 a second | **9** |

## The collapse, repeated (plain export of HEAD a1b8bfd8, one capture at a time, below-normal)

| Size | Runs | Reading (all at the same tick) |
| :--- | :--- | :--- |
| 960 x 540 | 5 | 3.5, 3.5, 3.5, 3.5, 3.5 (tick 69) |
| 1280 x 720 | 1 | 2.5 (tick 69) |
| 1024 x 768 | 5 | 2.0 x 5 (tick 82) |

## Not done (the pause came first)

- **The AI match (seed 4) and a launch swing, five runs each:** not run.
- **A light-load against a heavy-load repeat on purpose:** not run; the runs above happened at 55% to 99% machine load by themselves and did not differ.
- **Whether it is the shape (16:9 against 4:3) or the pixel count that moves the reading:** 960 x 720 was queued, not run.
- **A clip beside a slowed one with the counted frames marked, and the launch swing with the fore tone off against on:** the viewer is written (scratch `fp/make-view.mjs`: a real-speed and a slowed GIF with counted ticks boxed in red, and a before / after / what-changed sheet) and its GIF encoder is checked against the project's decoder, but the capture it needs was stopped. **So I cannot yet say whether a person would call the 3.5 a flash.**

## An outside check (searched, nothing downloaded)

- **PEAT** (the Trace Center's Photosensitive Epilepsy Analysis Tool, made with Dr Harding): free, Windows only. I could not confirm its download link, size or licence, and one university page says it was retired. Its method is the same standard we use (more than three flashes a second over a quarter of a 341 x 256 area at 1024 x 768). **I have no file and size to give you yet.**
- **Harding FPA** (the commercial one video sites use): licensed, no free download found.
- **FlashDetect** (a small free Python package, MIT licence): does not say which standard it follows. Not a real answer.
