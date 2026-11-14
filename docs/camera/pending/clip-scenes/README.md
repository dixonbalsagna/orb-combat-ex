# Parked: Camera's beam duel and film camera for Orb's clip kit

Camera, 2026-11-06, for the EP's brief (`docs/tools/clip-capture-audit.md`, step 1: "keep the scenes"). This is the staging and the camera behind the three beam-clash GIFs of 2026-11-02, as words of the capture hook. Tools folds it into the kit.

**Apply on main** (cut on 72a4d1e4): `git -c core.autocrlf=false apply clip-scenes.patch` (sha1 1c04c19b). It applies on that commit (`git apply --check --cached`).

**It does not apply on the working copy's `render/tools/flash_capture.gd`.** That file carries uncommitted clip-kit edits, Tools' by the look: `chase` in `SCENARIOS`, `events`, `_film_setup()`, `nohud`. Two hunks collide:
- the `SCENARIOS` / `AI_SLOTS` context;
- the `start_match` line.

**Folding it in by hand:**
- Keep Tools' `su = _film_setup()`. For `beamduel` start from `main._match_setup(seed)` and merge `su` into it, so the page's world words take.
- Tools' `nohud` makes this scene's own HUD line redundant: keep either.
- `FILM_SCENES` and the two lookups go in as they are, unless Tools would rather list `beamduel` with its other film scenes.
- The `_duel` / `_film` / `_place` block and the two Rendering files are unaffected.

## What it does

- **A film scene, `beamduel`**:
  - Both fighters are human slots and hold the charge from tick 0.
  - On tick 70 P1 presses the signature.
  - As his beam leaves (about tick 118), P2's answering signature goes straight into P2's queue, 4 ticks later. This writes into the sim, as the other scenes' ki and set-downs do.
  - The real beam struggle runs from about tick 122 to 426 and ends where the beams meet.
  - Both start with full ki. The HUD is hidden for the scene.
- **A film camera**, chosen by the page word `bdshot`. It rewrites the rig's frame each draw, and every move is eased: no cut after the first frame, no shake, one view, no strip.
  - **1, low and side on:** held on the charge, a push in and a small drift as he fires. It settles as the beams lock, and the struggle is held still.
  - **2, high and wide:** looking down on the town under the pair, craning down and easing in as he fires.
  - **3, tight then pull back:** tight on P1 charging, an eased move across to P2 charging (ticks 36 to 66), then a pull back to both as the beams meet (100 to 150).
  - Absent or 0: the game's own camera on the same scene.
- **The other words:**
  - `bdgap`: the pair's distance in units, 1000 by default.
  - `bdalt`: their height over the ground, 0 by default.
  - `bdx`: P1's x; the seed's start by default.
  - `bdcity=1`: set the pair down beside the tallest tower first.

## Normal play is untouched

- The hook exists only with `?flashcap=1` (main.gd).
- `SimHost.film_in` stays `[null, null]` and `main.film_cam` stays an invalid Callable unless the scene sets them, so the three new lines in play are a null check and an `is_valid()`.
- `beamduel` is kept out of `SCENARIOS` and `AI_SLOTS`, in a list of its own (`FILM_SCENES`). Tools' drift checks in `tools/flash/selftest.js` (the lists against `sources.json` and `flash_worst.gd`, and the scripted presses) therefore still compare the same lines. `drive()` gains one line, `_duel(t, S)`, which the presses filter does not read.
- The scene starts its match with the page's own world words (`main._match_setup`), so `planet`, `tiles` and `meteor` take. The flash scenes keep `{}`.

## Files and grants

| File | Owner | What |
| :--- | :--- | :--- |
| `render/tools/flash_capture.gd` | Rendering's hook, Tools' staging | `FILM_SCENES`, the lookups, `_duel`, `_film`, `_place` |
| `render/core/sim_host.gd` | Rendering | `film_in`, three lines in `tick()` |
| `render/core/main.gd` | Rendering | `film_cam`, the frame call and the zero shake |

**NEEDS:** Rendering's grant for main.gd and sim_host.gd, and Tools' for the hook.

## The three GIFs' recipes

All three:
- Seed 12345.
- Page `/index.html?flashcap=1&planet=7&meteor=loud&tiles=1` plus the words below.
- Started with `window.__flashcap.start("beamduel", {seed: 12345})` and stepped one tick a frame through `tools/machine/capture.mjs frames`.
- Captured as 960x540 PNG frames, `--every 5`.
- Built from ticks 12 to 252 (49 frames, 80 ms each, about 12.5 fps, 3.9 s, looping).
- Scaled to 480x270, with no crop.

| GIF | Words | KB | Flash check (`analyse-gif.mjs`) |
| :--- | :--- | :--- | :--- |
| 1-low-side-on | `bdshot=1&bdgap=750&bdalt=220` | 516 | PASS, count 1 |
| 2-high-wide-over-town | `bdshot=2&bdgap=900&bdalt=450` | 448 | PASS, count 0.5 |
| 3-tight-then-pull-back | `bdshot=3&bdgap=750&bdalt=200` | 557 | PASS, count 1 |

`gif_small.py` is the GIF builder: `python gif_small.py <frames> 12 252 <out.gif> 5 127 580 8`.
- One palette for the clip, with a quarter of it spread over the saturated colours so a costume's red survives.
- No dither.
- Each frame after the first draws only the pixels that changed by more than the tolerance, with lone specks left out.
- A moving camera changes every pixel, which is why the moves are kept short: the file size is in the moves.

## How far to trust this

- **Parse-checked, and run only on the 2026-11-02 kept build (68ee).** The GIFs were made there with these lines, the words then unprefixed (`shot`, `gap`, `alt`). On main the patch applies and its edits parse, but it has not been run there yet. Main's sim may have moved the beam's timing, so the ticks above are the 68ee ones.
- On that build:
  - The sky reads dusk to night.
  - The charge shows as a thin ring.
  - Buildings the beams cut through show black insides.
  - World traced a building that falls by P1 in GIF 3, from tick 122 to 137.
