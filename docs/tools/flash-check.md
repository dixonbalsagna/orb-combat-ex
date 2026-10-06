# The photosensitivity check (2026-10-06)

Owner: Tools and Pipeline. Legal's condition for the public web build (docs/legal/photosensitivity-note.md): WCAG 2.2 success criterion 2.3.1, "three flashes or below threshold". Two halves: the count runs in CI, the pixels run by hand on a local web export. Zero budget, headless only, Node built-ins and the project's own Godot.

**What a pass means.** Half 1 passing means: *in the worst cases below, no 60-tick window grants more than 3 flashes (1 under reduced flashing) among the sources that ask the flash register.* Half 2 passing means only that the analyser, under the reading written out below, found no failure in the captured frames; the sentence to use then is exactly: "An automated flash check based on WCAG 2.3.1 (general flash, red flash and area), run on recorded gameplay, found no failure." Neither half is a clearance, and no other wording is used for either (not "safe", not "seizure-safe", not "tested for photosensitivity", not "WCAG compliant", not "certified"). The README's wording ("contains flashing effects, has not been analysed for photosensitivity") stays true until a recognised analyser has been run over recordings of the real build. **Half 2 under the corrected reading finds five of sixteen clips failing: see "What it found".**

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
| `collapse` | AI against AI, both set down beside the tallest tower on tick 0 (so the blasts are on screen), then a blast through the nearest tower row every 150 ticks (`WorldStructures.explode`, as a beam's impact makes them), 1,500 ticks | 3 `building_fall` events and 3 staged blasts |
| `ai` | hash_check's real matches: seeds 12345, 4 and 7, forms at 300 and 1500, tier 3 at 900, a worn core at 1200, 3,600 ticks | 20 damage events |

The only direct writes into the sim are the ones `hash_check.gd` already makes (`formReady`, `tier`), ki refills for the beam cases and the staged blasts. A run takes about 90 seconds for all 16 runs; two runs write byte-identical files.

**The negative control** (`--negative-control`) adds four flashes at ticks 100 to 130 that the register cannot refuse (its `note`); the recount must then fail with "4 in the 60 ticks from 100". CI runs it and fails if the check passes. `tools/flash/selftest.js` (47 checks, no build needed) covers the recount's edges (the 60-tick window, refused asks, reduced cap, unknown sources, a full log) and the analyser (below).

### Results of half 1 on HEAD 68a9663f, 16 runs, 0 script errors

| Scenario | Normal: asks, granted, worst in 60 ticks (cap 3) | Reduced: asks, granted, worst (cap 1) |
| :-- | :-- | :-- |
| mash | 60, 32, 2 | 60, 0, 0 |
| clash | 31, 12, 2 | 31, 4, 1 |
| signature | 209, 41, 3 | 209, 4, 1 |
| transform | 114, 33, 3 | 115, 6, 1 |
| collapse | 103, 30, 3 | 103, 5, 1 |
| ai (seeds 12345, 4, 7) | 291/80/3, 334/83/3, 242/74/3 | 293/13/1, 335/13/1, 245/11/1 |

By source over all normal runs, granted and refused: body_hit 239/744, head_flash 22/132, block 44/104, beam 11/0, transform 17/1, explosion 27/10, shot_hit 2/7, guard_flash 12/0, cue_flare 7/1, beam_clash 4/0. Reduced: body_hit 0/983, head_flash 0/154, block 0/148, beam 9/2, transform 14/4, explosion 18/19, shot_hit 0/16, guard_flash 11/1, cue_flare 0/8, beam_clash 4/0. **Everything passes**, and the register's own figure and the recount agree in all 16.

**The big events keep their slot.** Of 70 big asks (explosion, transformation, beam, beam clash) 11 were refused in normal mode, all "cap" and mostly by other big events; at those moments low-priority flashes held at most 2 of the 3 slots, and in no window did they take all 3. In reduced mode the register's cap of 1 refuses 25 of the 70, as it is meant to.

**Every flash source now asks the register** except the split divider's slam flash (Camera's and UI's), which nothing asks for. The body hit flash is also counted by proxy from `hurtT`: the worst is 4 flash starts on one body in 60 ticks (the AI matches); advisory, because one body is a small part of the frame and the area test decides.

## Half 2: the pixels (run for real, 2026-10-06)

```
godot --headless --path . --export-release "Web" <site>/index.html                # a HEAD export (about 20 s, one Godot process, templates already installed)
godot --headless --path . --script res://tools/flash/flash_worst.gd -- --out=<flash>   # the headless runs, for the cross-check
node tools/flash/run-pixels.mjs --dir <site> --path "/index.html?flashcap=1" --out <clips> --flash <flash> [--jobs 3] [--only mash,clash] [--keep]
node tools/flash/analyse-frames.js <clip or folder of clips> [--scale 1] [--dips]   # by hand (--json for the per-tick windows)
node tools/flash/hit-windows.js <analysis.json> <flash-run.json> [--source body_hit]  # how big a window changes after a source's flashes
node tools/flash/pixel-selftest.mjs                                           # the pipeline on a page that flashes on purpose (in CI)
```

**A local web export costs nothing**: the Godot 4.7.2 web templates are installed on the machine that exports (a `git archive HEAD` copy, `--import`, then `--export-release "Web"`; build_info.json from `tools/write-build-info.mjs` is optional). CI's `site` job builds the same thing and could hand its artifact to this runner; it does not today. `run-pixels.mjs` serves the folder itself, drives headless Chrome (a throwaway profile, 1024 by 768 at device scale 1), steps Rendering's hook (`render/tools/flash_capture.gd`, offered at `/play/?flashcap=1`) one tick per screenshot, analyses every clip at full size, deletes the frames of clips that show no failure (`--keep` keeps them), and writes `summary.json`. Sixteen clips (the six cases, normal and reduced, `ai` at three seeds) are 35,000 frames and took 35 minutes on three Chrome jobs. On Git Bash set `MSYS_NO_PATHCONV=1` or quote `--path`.

**What exists.** `tools/flash/wcag.js` (PNG decoder, the analyser), `analyse-frames.js`, `capture-web.mjs`, `run-pixels.mjs`, `mock-page/` and `pixel-selftest.mjs` (six scenes through headless Chrome with known answers: a still frame 0, the whole frame at 3 a second passes, at 4 fails, a 2.25% corner at 10 a second passes, a 4% corner fails, red against grey is a red flash and no general one).

### What it found, under the corrected reading (16 clips, HEAD 68a9663f plus the collapse staging below)

**Under the corrected reading five of the sixteen clips FAIL** (more than 3 flashes in a second): the collapse case in both modes, `ai` at seed 12345 in both modes, and `ai` at seed 4 in normal mode. Four more sit at exactly 3 with no margin. **Nothing is red.** (Yesterday's "no failure found" used an area test four times too lenient and a red formula that was not the standard's; it does not stand.)

| Clip | Ticks | Worst second, general flashes: normal / reduced | Starts at tick (normal) | Red flashes | Result |
| :-- | :-- | :-- | :-- | :-- | :-- |
| mash | 1,800 | 3 / 2 | 1455 | 0 | at the limit (normal) |
| clash | 1,500 | 3 / 3 | 182 | 0 | at the limit (both) |
| signature | 1,500 | 2.5 / 2.5 | 83 | 0 | under |
| transform | 1,500 | 2 / 2 | 449 | 0 | under |
| collapse | 1,500 | **4.5 / 4.5** | 1352 | 0 | **FAIL (both)** |
| ai, seed 12345 | 3,600 | **4.5 / 4.5** | 3290 | 0 | **FAIL (both)** |
| ai, seed 4 | 3,600 | **3.5** / 2 | 1812 | 0 | **FAIL (normal)** |
| ai, seed 7 | 3,600 | 3 / 1.5 | 1776 | 0 | at the limit (normal) |

The same table with the register: in every clip the register in the web build counted the same flashes as the headless run at every tick (cross-check below), and each clip's register worst is at or under the cap (3, or 1 in reduced mode). The pixels exceed what the register counts because most of what changes the screen is not a register source.

**Case by case.** Frames are in the run's scratch folders; ticks are the clip's tick numbers (the file `frame-NNNNNN.png` is tick NNNNNN).

1. **collapse, ticks 1352 to 1397 (both modes): 4.5 flashes.** Eleven qualifying changes in 45 ticks, each 110 to 283% of the window limit (21,824 px), alternating every 2 to 10 ticks. The camera flies close past building facades while the blasts go off, so large dark and bright façades and the blast's flash sweep through the same windows. Reduced flashing changes nothing (4.5 both ways). Yesterday's reading called this "exactly 3"; the sliding window and the pooling count it as 4.5.
2. **ai seed 12345, ticks 3290 to 3328: 4.5 (both modes).** A beam signature landing with an explosion: the white beam and the explosion's flash alternate with Camera's inset cut-in panel opening and closing and a broad grey band across the screen, nine changes in 38 ticks, each 102 to 151% of the limit. Reduced flashing does not calm the beam, the panel and the band together.
3. **ai seed 4, ticks 1812 to 1872: 3.5 (normal).** The same kind of beam and impact, nine changes in 60 ticks (109 to 260% of the limit). The reduced run of the same seed is 2.
4. **At exactly 3, no margin:** mash normal (tick 1455: the camera pans across a mountainside, sand to grey and back), clash in both modes (tick 182: the beams meeting), ai seed 7 normal (tick 1776). A slightly faster pan or a second beam would fail them.
5. **Reduced flashing does not reliably reduce the pixels.** Clash, collapse and ai 12345 read the same in both modes; transform and signature the same. The register's cap of 1 a second removes VFX's and Rendering's flashes, and what remains (the camera, the beam's body, the scenery) is not under the setting.

**Red: none.** The red test finds 0 flashes in all 16 clips; the largest window it ever sees is the collapse blast's orange flames, 19% of the limit.

**Dips.** Whole-screen dips (a general down change over 40% of the frame or more) in the 16 clips: collapse tick 1262 (54% of the frame, mean luminance 0.211 to 0.124, one frame down, back in four), transform reduced tick 120 (41%, 0.288 to 0.166), ai seed 7 reduced tick 368 (43%, 0.276 to 0.164). Each is one down change, and none has another within a second, so the shortest interval between two dips is not defined in these clips. Each dip counts as a flash over the whole screen area under the standard (one dark pulse: a down change and its return), and the 3-a-second rule and the 10% step apply to it; nothing here limits how often cuts can come. (The dip at collapse tick 1262 looks like Camera's safety-cut brightness dip, `split_frame.gd` `CUT_DIM`; I did not trace its trigger.)

**The body's white on a hit, re-read against the smaller threshold.** A body is about 40 by 90 px at 1024 by 768, about 3,600 px; both bodies fully white in one window would be about 7,200 px, a third of the 21,824-px threshold. So the body's white on its own cannot reach the area test. The measured windows near a body_hit grant (the largest window within 8 ticks after a grant, from `tools/flash/hit-windows.js`) are 101 to 115% of the threshold in mash, transform and signature, but the camera, a beam or an explosion is happening in the same ticks, and the analysis cannot separate them. **Not attributable**: I report the geometry bound and no more.

**The register in the web build counts the same flashes as the headless run, every tick**, in all 16 clips (the register's count per tick read from the page equals the count rebuilt from the headless log in 100% of ticks). That is the drift check between the two copies of the staging, and evidence that the clips are the scenarios the count half plays.

**Wording.** Only when a run is true to it: "An automated flash check based on WCAG 2.3.1 (general flash, red flash and area), run on recorded gameplay, found no failure." This run does not meet it, because five clips fail. The tools print that sentence only on a pass of every clip they were given. The words "safe", "seizure-safe", "tested for photosensitivity", "WCAG compliant" and "certified" are not used about this check anywhere.

### The staging exists twice; the decision

`tools/flash/flash_worst.gd` (here) and `render/tools/flash_capture.gd` (Rendering's, because `tools/` is not in an export) stage the same six cases. Options: mine calls Rendering's (it cannot: it needs the scene and is not in an export), a shared data file both read (the staging is rules and calls, not data; a file would carry only numbers), or a check that fails when they drift. **I chose the check, in two parts**, because it costs the two files' owners nothing and catches what matters:

- `tools/flash/selftest.js` (in CI) compares the scenario list and the human and AI slots of the two files, and `sources.json`'s ticks and seeds against `flash_worst.gd`'s.
- `run-pixels.mjs` compares, for every clip, the web build's register count at every tick with the headless run of the same scenario and seed; a difference in staging (a different tick for a blast, a different input) changes the count and the clip is reported DIFFERENT. Its limit: a staging difference that changes no flash is not seen.

### The collapse staging changed, in both copies

At the start of a match the nearest building is 18,000 units from the fighters, so the headless blasts were never on screen. `flash_worst.gd` now sets both fighters down beside the tallest tower on tick 0, then blasts as before. **Rendering's copy needs the same in `render/tools/flash_capture.gd`:**

```
func _to_the_city(S: SimState) -> void:
	var tall = null
	for b in S.buildings:
		if b.alive and (tall == null or b.h > tall.h):
			tall = b
	if tall == null:
		return
	for i in range(2):
		var f = S.fighters[i]
		f.x = SimWrap.wrap(tall.x - 900.0 + 60.0 * float(i))
		f.y = WorldTerrain.groundY(S, f.x) + 10.0
		f.vx = 0.0
		f.vy = 0.0
```

and at the top of `_stage_collapse`: `if t == 0: _to_the_city(S); return`. The clips above were captured with exactly this patch in a scratch export. Until Rendering lands it, `run-pixels.mjs` on a clean export shows the collapse clip in the desert and the register cross-check reports it DIFFERENT, which is the check working.

### The reading of the standard, as implemented (corrected after Legal's RL-116 addendum)

Each number is a parameter (`wcag.js` `DEFAULTS`; `analyse-frames.js --area-share --fps`).

- **Luminance: gamma-decoded.** Each of R, G, B (8-bit sRGB) is divided by 255 and linearised (`c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4`), then `L = 0.2126 R + 0.7152 G + 0.0722 B`, 0 to 1. It was gamma-decoded in the first version too; the header and this doc now say so.
- **General flash.** A pair of opposing changes in relative luminance of 0.10 or more (of a maximum of 1.0) where the darker state is below 0.80. Measured per pixel: a pixel's change is a swing of at least 0.10 from its last extreme, so a slow fade is one change and a flicker under 0.10 is none.
- **Area: a sliding window.** The window is 341 x 256 px at 1024 x 768, which is a third of the frame in each direction (scaled to the frame's size), and the threshold is **25% of the window's pixels: 21,824 px at 1024 x 768** (87,296 x 0.25). The window is slid to every position over the mask of pixels that turned a change on, using an integral image (one pass to build the cumulative sums, one to read every window in constant time); a change counts when some window holds at least the threshold. The changed pixels are not summed over the whole frame. Pixels that turn the same way on consecutive frames are pooled before the window is tried, so a fade over several frames is one change; a run ends when the other direction dominates a frame, so a fast alternation is many changes.
- **Count.** Opposing changes in any window of one second (60 frames), divided by 2; more than 3 fails. Six changes in a second (3 flashes) pass; seven (3.5) fail.
- **Red flash: the defined test.** A pair of opposing transitions where one state has R/(R+G+B) of 0.8 or more and the two states differ by more than 0.2 in CIE 1976 u'v' chromaticity, per pixel (u' = 4X / (X + 15Y + 3Z), v' = 9Y / (X + 15Y + 3Z), X Y Z from the linearised sRGB values with the Rec. 709 matrix; a pixel with no light is given the D65 white point). "Saturated red" is taken on the stored or on the linearised values, whichever is red (the more conservative of two readings of the text; `redSpace` = `stored` or `linear` narrows it). A transition into or out of red is counted like a general change: same window, same pooling, same count (more than 3 a second fails). There is no luminance floor, so a near-black dark red against black would count if it covered a window; no clip shows one. The first version's formula, (R-G-B) x 320 with a threshold of 20, is not used.
- **Dips.** A general down change over 40% of the whole frame is listed with its tick, its area and the mean luminance before and lowest within 8 frames; each also counts in the flash count.
- **Frames.** One PNG per sim tick, 60 a second, at 1024 x 768, device scale 1, analysed at full size (`--scale 1`; `analyse-frames.js` by itself shrinks to 640 wide or under and scales the window with it).

### What it cannot see, against a recognised analyser (Harding FPA, PEAT) and against play

1. **It is not a recognised analyser** and has not been validated against one; it is my reading of the text as Legal states it. A recognised analyser must be run over recordings of the real build before anyone says the game has been analysed. That is Orb's decision (cost); the free option is dated.
2. **Its frames are not play**: a tick is a frame, where real play draws between ticks at the display's rate; the crowd's cycles use the shader's clock; the scenes are staged (ki, forms, blasts, a teleport to the city), so they are worst cases and not matches the determinism tools know; the camera and HUD are the game's own. One machine's rendering (headless Chrome's GPU path), one canvas size.
3. **No pattern analysis** (the standard also bars regular stripes and spirals), and **no viewing-distance field**: the window is the standard's estimate of a 10-degree field at 1024 x 768 at a typical distance, scaled to the frame, not the player's actual field.
4. **Luminance is computed from the PNG's sRGB values**, not measured from a screen; brightness, gamma and a player's display change what they see.
5. **Only the six cases at the seeds played.** A fight we did not play can flash, and nine of the sixteen clips are at or over the limit already.
6. **Pooling and the run rule are my reading** of how a fade and an alternation are counted; a recognised analyser may count the same frames differently in either direction.
7. **The window is aligned to the pixel grid and tested on the changed-pixel mask only**; it does not model the standard's note on combined areas of flashes that are not adjacent.

## Needs (outside my paths)

1. **Rendering, VFX, Camera, Combat (via the EP)**: five clips fail and four sit at the limit. The causes in this run are the camera's flight past facades (collapse), the beam and explosion with the inset cut-in panel and the grey band (ai 12345 and 4), and the camera pans (mash, clash, ai 7). Which of those the register or a rate cap should own is for them; the case list above is the brief. Reduced flashing does not calm any of them.
2. **Rendering**: the collapse staging lines in "The collapse staging changed" in `render/tools/flash_capture.gd`, so the web clip and the headless run agree (`run-pixels.mjs` says DIFFERENT until they do).
3. **Legal**: confirm that the reading above matches RL-116 (the area window and the 25%, the u'v' red test with the stored-or-linear share).
4. **EP**: the `flash` job joining `deploy.needs` once green on a real runner twice (a one-line commit from me on your word; the job's count half and the Chrome self-test follow the corrected analyser, and the pixel half is manual); CI building the clips would need `site`'s export and about 35 minutes, so a manual run before a release is the use; a recognised analyser before a store release (Orb).
5. **VFX**: `drop_ticks` is a schema key (`flicker.drop_ticks`, integer 1 to 20, optional): read it in place of `VfxReact.DROP_TICKS` when ready.
