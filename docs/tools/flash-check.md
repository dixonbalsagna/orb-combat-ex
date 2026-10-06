# The photosensitivity check (2026-10-06)

Owner: Tools and Pipeline. Legal's condition for the public web build (docs/legal/photosensitivity-note.md): WCAG 2.2 success criterion 2.3.1, "three flashes or below threshold". Two halves: the count runs in CI, the pixels run by hand on a local web export. Zero budget, headless only, Node built-ins and the project's own Godot.

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
| `collapse` | AI against AI, both set down beside the tallest tower on tick 0 (so the blasts are on screen), then a blast through the nearest tower row every 150 ticks (`WorldStructures.explode`, as a beam's impact makes them), 1,500 ticks | 3 `building_fall` events and 3 staged blasts |
| `ai` | hash_check's real matches: seeds 12345, 4 and 7, forms at 300 and 1500, tier 3 at 900, a worn core at 1200, 3,600 ticks | 20 damage events |

The only direct writes into the sim are the ones `hash_check.gd` already makes (`formReady`, `tier`), ki refills for the beam cases and the staged blasts. A run takes about 90 seconds for all 16 runs; two runs write byte-identical files.

**The negative control** (`--negative-control`) adds four flashes at ticks 100 to 130 that the register cannot refuse (its `note`); the recount must then fail with "4 in the 60 ticks from 100". CI runs it and fails if the check passes. `tools/flash/selftest.js` (37 checks, no build needed) covers the recount's edges (the 60-tick window, refused asks, reduced cap, unknown sources, a full log) and the analyser (below).

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
node tools/flash/analyse-frames.js <clip or folder of clips> [--scale 1]      # by hand
node tools/flash/pixel-selftest.mjs                                           # the pipeline on a page that flashes on purpose (in CI)
```

**A local web export costs nothing**: the Godot 4.7.2 web templates are installed on the machine that exports (a `git archive HEAD` copy, `--import`, then `--export-release "Web"`; build_info.json from `tools/write-build-info.mjs` is optional). CI's `site` job builds the same thing and could hand its artifact to this runner; it does not today. `run-pixels.mjs` serves the folder itself, drives headless Chrome (a throwaway profile, 1024 by 768 at device scale 1), steps Rendering's hook (`render/tools/flash_capture.gd`, offered at `/play/?flashcap=1`) one tick per screenshot, analyses every clip at full size, deletes the frames of clips that show no failure (`--keep` keeps them), and writes `summary.json`. Sixteen clips (the six cases, normal and reduced, `ai` at three seeds) are 35,000 frames and took 35 minutes on three Chrome jobs. On Git Bash set `MSYS_NO_PATHCONV=1` or quote `--path`.

**What exists.** `tools/flash/wcag.js` (PNG decoder, the analyser), `analyse-frames.js`, `capture-web.mjs`, `run-pixels.mjs`, `mock-page/` and `pixel-selftest.mjs` (five scenes through headless Chrome with known answers: 0, 3 passes, 4 fails, a 9% corner passes, a 16% corner fails).

### What it found, under this reading (16 clips, HEAD 68a9663f plus the collapse staging below)

| Clip | Ticks | Worst second, general flashes (normal / reduced) | Red | Largest single change (normal / reduced) | Register in the web build vs headless |
| :-- | :-- | :-- | :-- | :-- | :-- |
| mash | 1,800 | 0.5 / 0.5 | 0 | 13.6% / 15.0% of the frame | same (max 2 / 0) |
| clash | 1,500 | 0 / 0 | 0 | 10.3% / 10.4% | same (2 / 1) |
| signature | 1,500 | 0 / 0 | 0 | 7.5% / 7.5% | same (3 / 1) |
| transform | 1,500 | 1 / 1 | 0 | 39.0% / 41.0% | same (3 / 1) |
| collapse | 1,500 | **3 / 3** | 0 | 54.4% / 54.1% | same (3 / 1) |
| ai, seed 12345 | 3,600 | 0.5 / 0.5 | 0 | 41.4% / 43.0% | same (3 / 1) |
| ai, seed 4 | 3,600 | 1 / 1 | 0 | 43.0% / 45.8% | same (3 / 1) |
| ai, seed 7 | 3,600 | 1 / 1 | 0 | 40.9% / 43.2% | same (3 / 1) |

**No clip fails under this reading.** Nothing is red. What the reading shows that the register cannot:

1. **The collapse case sits exactly at the limit: 3 flashes in its worst second, in normal and in reduced mode alike.** The second is frames 1363 to 1387: the camera flies close past the fronts of buildings, so large dark and bright façades sweep across 12 to 16% of the frame six times in under half a second (changes at frames 1363 to 1367, 1372 to 1375 and 1383 to 1387). That is motion across high-contrast surfaces, not an effect the register can see or limit, and **the reduced-flashing setting does nothing to it** (3 flashes both ways). It passes by one change. A recognised analyser might read the same sweep differently, and a slightly faster pass would fail.
2. **The biggest single change is a whole-screen dip, not a flash**: at frame 1261 the mean luminance falls from 0.211 to 0.124 in one frame (54% of pixels change by 0.10 or more) and is back to 0.213 four frames later (the +40% at 1265). It looks like Camera's safety-cut brightness dip (`split_frame.gd`, `CUT_DIM`; I did not trace it to its trigger). It is a deliberate softening and one dark pulse a cut, so it counts as one flash per cut; how often cuts can come in a second is Camera's to cap, and nothing here limits it.
3. **The body's white on a hit never reaches the area test**: no clip has a change of hit-flash size counted. The largest change in the mash clip, 13.6% at one frame, is a single event.
4. **The first frame of every clip is the capture's start-up** (the camera settling at tick 1, up to +30%); it is not play.

**The register in the web build counts the same flashes as the headless run, every tick**, in all 16 clips (the register's in-window count per tick, read from the page, equals the count rebuilt from the headless log in 100% of ticks). That is the drift check between the two copies of the staging (below), and evidence that the clips are the scenarios the count half plays.

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

### The reading of the standard, written out for Legal to confirm

Each number is a parameter (`wcag.js` options, `analyse-frames.js --area-frac --fps`).

- **General flash.** A pair of opposing changes in relative luminance of 0.10 or more (of a maximum of 1.0) where the darker state is below 0.80. Relative luminance is WCAG's: each of R, G, B (8-bit sRGB) is divided by 255, linearised (`c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4`), then `L = 0.2126 R + 0.7152 G + 0.0722 B`. Measured per pixel: a pixel's change is a swing of at least 0.10 from its last extreme, so a slow fade is one change and a flicker under 0.10 is none.
- **Area.** A change counts only if the pixels making it cover at least 341 x 256 px at 1024 x 768, which is 11.1% of the frame (87,296 of 786,432 px), scaled to the frame. They are counted anywhere in the frame, contiguous or not, which over-counts against the standard. **To confirm: is 341 x 256 the threshold area itself (as read here), or the 10-degree field of which 25% is the threshold?** If the latter the threshold is a quarter of this and the clips will count more.
- **Count.** Opposing changes in any window of one second (60 frames), divided by 2; more than 3 fails. Six changes in a second (3 flashes) pass; seven (3.5) fail.
- **Red flash.** Per pixel, from the stored (gamma-encoded) values R, G, B in 0 to 1: a pixel is a *saturated red* when `R / (R + G + B) >= 0.8`; its red value is then `(R - G - B) * 320`, and a pixel that is not a saturated red has value 0. A swing of that value of more than 20 (that is, `R - G - B` changing by more than 0.0625) is a transition, counted like a general flash: same area, same count, capped at 3 a second. The standard's wording is "a pair of opposing transitions involving a saturated red ... change in (R - G - B) x 320 > 20 (negative values set to zero) for both colours". **To confirm**: (a) the scale is 0 to 1 and gamma-encoded, not linear; (b) in the standard the other colour of the pair keeps its own (R - G - B) x 320 with negatives set to zero, where this analyser sets any unsaturated pixel to 0, which makes every change that involves a saturated red at least as large here as there (it over-counts, never under-counts); (c) the 0.8 share applies to the stored values.
- **Frames.** One PNG per sim tick, 60 a second, at 1024 x 768, device scale 1, analysed at full size (`--scale 1`; `analyse-frames.js` by itself shrinks to 640 wide or under).

### What it cannot see, against a recognised analyser (Harding FPA, PEAT) and against play

1. **It is not a recognised analyser** and has not been validated against one; it is my reading of the text as Legal states it. A recognised analyser must be run over recordings of the real build before anyone says the game has been analysed. That is Orb's decision (cost); the free option is dated.
2. **Its frames are not play**: a tick is a frame, where real play draws between ticks at the display's rate; the crowd's cycles use the shader's clock; the scenes are staged (ki, forms, blasts, a teleport to the city), so they are worst cases and not matches the determinism tools know; the camera and HUD are the game's own. One machine's rendering (headless Chrome's GPU path), one canvas size.
3. **No pattern analysis** (the standard also bars regular stripes and spirals), and **no viewing-distance field**: the area is total changed pixels, not a contiguous 10-degree field, so a player sitting closer sees a bigger field than 341 x 256.
4. **Luminance is computed from the PNG's sRGB values**, not measured from a screen; brightness, gamma and a player's display change what they see.
5. **Only the six cases at the seeds played.** A fight we did not play can flash, and collapse already sits at the limit.
6. **Combined area is a plain count of changed pixels in the frame**, so many small separate flashes that together exceed the area count as one change here; the standard's own rule on combined area is not modelled beyond that.

## Needs (outside my paths)

1. **Rendering**: the collapse staging lines above in `render/tools/flash_capture.gd`, so the web clip and the headless run agree again once HEAD has them (`run-pixels.mjs` says DIFFERENT until they do).
2. **Camera**: the camera's flight past building fronts (collapse clip, frames 1363 to 1387: three flashes in a second, at the limit, untouched by reduced flashing) and the safety cut's brightness dip (54% of the frame, once per cut): whether either needs a rate cap or a calmer pass under reduced flashing. That is Camera's call; I report it.
3. **Legal**: confirm the area threshold and the red formula in "The reading of the standard".
4. **EP**: the `flash` job joining `deploy.needs` once green on a real runner twice (a one-line commit from me on your word); CI building the clips would need `site`'s export and about 35 minutes, not worth it per push, so a manual run before a release is the use; a recognised analyser before a store release (Orb).
5. **VFX**: `drop_ticks` is a schema key (`flicker.drop_ticks`, integer 1 to 20, optional): read it in place of `VfxReact.DROP_TICKS` when ready.
