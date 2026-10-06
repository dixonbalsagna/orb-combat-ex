# The photosensitivity check (2026-10-06)

Owner: Tools and Pipeline. Legal's condition for the public web build (docs/legal/photosensitivity-note.md): WCAG 2.2 success criterion 2.3.1, "three flashes or below threshold". Two halves, built to be run by CI and by hand. Zero budget, headless only, Node built-ins and the project's own Godot.

**What a pass means.** Half 1 passing means: *in the worst cases below, no 60-tick window grants more than 3 flashes (1 under reduced flashing) among the sources that ask the flash register.* Half 2 passing means: *under this reading of criterion 2.3.1, no failure was found in these captured frames.* Neither is "safe", "compliant" or "tested for photosensitivity", and neither is a clearance. The README's wording ("contains flashing effects, has not been analysed for photosensitivity") stays true until a recognised analyser has been run over recordings of the real build.

## Half 1: the count (in CI today)

```
godot --headless --path . --script res://tools/flash/flash_worst.gd [-- --out=build/flash --only=mash,clash --ticks=1800 --seeds=12345,4 --trace --negative-control]
node tools/flash/check-log.js build/flash
```

`tools/flash/flash_worst.gd` plays each worst case through the real game scene (`render/main.tscn`, `main.frame`) with the real input path (two pads on the hub: device 0 is slot 0, device 1 is slot 1; the arena layout's west, north and east buttons are light, heavy and signature), once in normal mode and once with `vfx.force_reduced`, and writes `flash-<scenario>-<mode>[-<seed>].json` with the register's whole log (`log_rows()`), its summary, a tally of every sim event, and a proxy count for Rendering's body hit flash. `tools/flash/check-log.js` then **recounts every window from the rows**, not from the register's own running figure, and also fails if the two disagree.

It **fails** when: any 60-tick window grants more than 3 flashes (more than 1 in a reduced run); a red flash was granted; a log is full (the register keeps the last 2,400 asks) so earlier asks are missing; a reduced run never ran reduced; a scenario of the required set is missing; a scenario did not show the events it exists to show (`tools/flash/sources.json` `minEvents`, so a run that plays nothing cannot pass); no flash was asked anywhere; a flash source appears in a log that `sources.json` does not know (add it there). The window is the register's: a grant counts against another if they are fewer than 60 ticks apart.

| Scenario | What is played | Must show |
| :-- | :-- | :-- |
| `mash` | both fighters human, walking into reach, light every 4 ticks each (staggered), a heavy now and then, 1,800 ticks | 20 damage events |
| `clash` | both human, ki kept full, both fire the signature together every 30 ticks, 1,500 ticks | a `beam_outcome` of kind CLASH |
| `signature` | P1 human fires the signature on a cycle against the AI, 1,500 ticks | a beam outcome |
| `transform` | AI against AI, the form made ready for both at ticks 60, 500 and 1000 (tier 1 to 4; the game never goes past 4), 1,500 ticks | 4 `transform` events |
| `collapse` | AI against AI, a blast through the nearest tower row every 150 ticks (`WorldStructures.explode`, as a beam's impact makes them), 1,500 ticks | 3 `building_fall` events |
| `ai` | hash_check's real matches: seeds 12345, 4 and 7, forms at 300 and 1500, tier 3 at 900, a worn core at 1200, 3,600 ticks | 20 damage events |

The only direct writes into the sim are the ones `hash_check.gd` already makes (`formReady`, `tier`), ki refills for the beam cases and the staged blasts. A run takes about 90 seconds for all 16 runs; two runs write byte-identical files.

**The negative control** (`--negative-control`) adds four flashes at ticks 100 to 130 that the register cannot refuse (its `note`); the recount must then fail with "4 in the 60 ticks from 100". CI runs it and fails if the check passes. `tools/flash/selftest.js` (33 checks, no build needed) covers the recount's edges (the 60-tick window, refused asks, reduced cap, unknown sources, a full log) and the analyser (below).

### Results on HEAD (00c4c90e plus this tooling), 16 runs, 0 script errors

| Scenario | Normal: asks, granted, worst in 60 ticks (cap 3) | Reduced: asks, granted, worst (cap 1) |
| :-- | :-- | :-- |
| mash | 0, 0, 0 | 0, 0, 0 |
| clash | 0, 0, 0 | 0, 0, 0 |
| signature | 30, 17, 2 | 30, 0, 0 |
| transform | 14, 13, 3 | 16, 6, 1 |
| collapse | 18, 11, 2 | 18, 0, 0 |
| ai (seeds 12345, 4, 7) | 52/33/3, 40/26/2, 49/35/3 | 56/7/1, 40/4/1, 53/8/1 |

By source over all runs, granted and refused: block 91/207, transformation 32/4, explosion 35/21, shot hit 2/24. **Everything passes.** The register's own figure and the recount agree in all 16.

**Which sources are not counted today** (no ask in any log, so the register cannot see them): Rendering's **body hit flash** (`body_hit`: the whole body white for 0.12 s a hit), the **head flashes** (`head_flash`), the **guard arc's flash** on a perfect block (`guard_flash`), a **cue's flare** (`cue_flare`), a **signature beam's white core** (`beam`) and the **beam clash flare** (`beam_clash`); and, asked by nothing, the **split divider's slam flash** (Camera's and UI's). Rendering has the first six under the register in its working tree (docs/rendering/flash-sources.md, `SimHost.ask_flash`; not committed when this was written): the next run after it lands counts them, with no change here. This is why the two worst cases for a mash and a clash show 0 asks: what flashes there is Rendering's. Two things are done about it:

- When Rendering asks the register (`SimHost.ask_flash(source, colour)` in Rendering's change), the asks appear in the log and are counted and capped with no change here; `sources.json` already names them (`body_hit`, `head_flash`, `guard_flash`, `cue_flare`, `beam`, `beam_clash`), and the report moves them from UNCOUNTED to counted. Their low-priority rule is theirs to apply in `ask_flash`; the recount only asks that no 60-tick window grants more than 3 in all.
- Meanwhile the body hit flash is **counted by proxy**, from the same sim field (`hurtT`) and the same constant (`RenderLook.HIT_FLASH_S`) Rendering uses: the check prints how many flash starts one body has in any 60 ticks. On HEAD the worst is 4 (AI matches, seeds 12345 and 7; the two-human mash peaks at 2, a clash at 3). That figure is advisory and does not gate: one body is a small part of the frame, and whether a flash of that size counts is the area test, which only half 2 can do. If the melee press feel lands (each press a blow), the `mash` case will play it with no change here and the proxy will show the rate.

## Half 2: the pixels (built and tested on a mock page; not yet run on the game)

```
node tools/flash/capture-web.mjs --dir <built site> --path /play/ --scenario mash --ticks 1800 --out clips/mash [--reduced] [--software]
node tools/flash/analyse-frames.js clips            # a folder of clips, or one clip
node tools/flash/pixel-selftest.mjs                 # the pipeline on a page that flashes on purpose
```

**What exists.** `tools/flash/wcag.js` (PNG decoder and the analyser), `analyse-frames.js` (CLI over a clip or a folder of clips, one PNG per tick), `capture-web.mjs` (headless Chrome or Edge over the DevTools protocol, a throwaway profile, one screenshot per sim tick), `mock-page/` (a page that strobes on purpose) and `pixel-selftest.mjs`, which plays five mock scenes through all three and checks the known answers: a still (0 flashes), the whole frame at 3 a second (3, passes), at 4 a second (4, fails), a 9% corner at 10 a second (under the area, passes) and a 16% corner at 10 a second (over it, fails). It runs in CI (Chrome is on the runner).

**What does not exist: the hook in the game.** `capture-web.mjs` needs the page to offer, in a scratch or a flagged build, the contract in its header: `window.__flashcap = { ready, start(scenario, { reduced }), step() -> Promise<tick>, tick }`, where `step()` runs exactly one sim tick, draws it and resolves once that frame is on screen, and `start()` sets up the scene as `flash_worst.gd` does and pauses the sim. VFX's recording of the energy-in-reach mash (docs/vfx/reach.md) used such a hold-and-step hook in a scratch copy; this is the same thing made explicit. It touches `render/core/main.gd` (Rendering's) and needs the scenes' staging (forms, ki, blasts), which `flash_worst.gd` shows how to do. **Nobody has built it; it is the one thing between this and a real run.** Until then half 2 has only ever seen synthetic frames.

**The reading of the standard** (each number is a parameter; `--area-frac`, `--fps` and the `wcag.js` options change it):

- *General flash*: a pair of opposing changes in relative luminance (WCAG's formula, sRGB to linear, Rec. 709 weights) of 0.10 or more where the darker state is below 0.80. Measured per pixel: a pixel's change is a swing of at least 0.10 from its last extreme (a slow fade is one change, a flicker under 0.10 is none).
- *Area*: a frame counts only if the pixels making the change cover at least 341 x 256 px at 1024 x 768, which is 11.1% of the frame, scaled to the frame's size. They are counted **anywhere in the frame, contiguous or not**, which over-counts against the standard.
- *Count*: opposing changes in any window of one second (60 frames), divided by 2; more than 3 fails. Seven opposing changes in a second (3.5 flashes) fails; six (3) passes.
- *Red flash*: a saturated red (R/(R+G+B) at or above 0.8, stored values 0 to 1) whose (R - G - B) x 320 changes by more than 20, counted the same way and capped at 3. **This is my reading of the red definition and I am not sure of it**; Legal should confirm the formula.
- Frames are box-averaged to 640 wide or under before analysis (the area test scales with the frame). A flash in a part of the frame smaller than a pixel after averaging is lost, which is fine for the area test (such a flash is under it) and wrong for nothing else.

**What it cannot claim, against a recognised analyser (Harding FPA, PEAT):**

1. It is not a recognised analyser and has not been validated against one; its numbers are mine, from the standard's text as Legal states it. A recognised analyser must be run over the recordings before anyone says the game has been analysed.
2. It sees only what is in the frames: 60 frames a second of one render size, one scene, one machine's rendering (headless Chrome's GPU or SwiftShader, not the player's). A different display, brightness, gamma or frame rate changes what the player sees.
3. No pattern analysis. The standard also bars certain regular patterns (stripes and spirals); this does not look for them.
4. The area is counted as total changed pixels, not as the standard's contiguous 10-degree field at a viewing distance; a screen the player sits closer to is a bigger field.
5. Relative luminance is computed from the PNG's sRGB values, not measured light from a screen. The red measure is as above.
6. Only the scenes played: five worst cases and three seeds. A fight we did not play can flash.
7. Where the game and the captured clip disagree (a hook that differs from the game's own tick loop), the clip is not the game.

## Needs (outside my paths)

1. **Rendering**: the `__flashcap` hook in a flagged or scratch build (above); the body hit flash, head flash, guard arc flash and beam clash flare asking `host.vfx.flashes` (docs/vfx/flash-registry.md, Needs 1).
2. **VFX**: none for the count; `drop_ticks` is now a schema key (`data/vfx/react.json` `flicker.drop_ticks`, integer 1 to 20, optional, 9 cases): set it and read it in place of `VfxReact.DROP_TICKS`.
3. **EP**: decide whether the `flash` job joins `deploy.needs` in `.github/workflows/ci.yml` (it is a Legal condition for the public build; today it runs on every push and blocks nothing), and whether to run a recognised analyser over recordings before a store release.
