# The friends'-build sound set (Audio and Music, 2026-11-25; parked)

Built against main `935056c0`; re-cut and checked on `c3dabf8e` (the first cut raised the two-fighter ratchet by 2: `audio_scene.gd` now takes the fight's bodies from the list, bit-identical on 14,416 compared positions; baseline untouched). Audio only; nothing writes the sim (state hash identical with and without the mapper on seeds 301, 302, 305). **Nobody has heard it.**

## What it adds

- **One quiet wind bed** (`amb.wind`), on its own switch. Louder high up, quieter while blows land, faded in over 2.4 s from -40 dB. It stands down if the biome beds are ever switched on.
- **Building sounds** from the sim's `building_hit`, `floor_hit`, `building_stage`, `floors_fall` and `building_fall`: a hit, windows breaking, a wall breaking, floors falling, a collapse (after its ripple delay). At most one cue of a kind a tick.
- **Menu sounds** (move, confirm, back): `AudioVoices.ui("move")`. **Silent until UI calls it.**
- **The overdrive fix:** the master limiter no longer squares loud peaks (`docs/audio/desktop-sound.md`). Levels under -6 dB are unchanged.
- **A small fix found on the way:** while a browser holds sound back, a looped voice is no longer "held" (a held loop never started).
- **The proof** that a build makes sound (`audio/audio_proof.gd`) and `audio/tools/scene_check.gd`.

Data and switches: `audio/data/scene_cues.json`. All sounds are our own synthesis, kept low (the brightness limits for the new ones are in `tone_check.gd`).

## Apply (in this order, from the repo root; strict, all four together)

1. `friends-sound.patch` (Audio's own: `audio/`)
2. `grant/tools-schema.patch` (Tools': `tools/schemas/`; also applies after the GW1c stack)
3. `grant/rendering-audio-proof-arg.patch` (Rendering's: `render/core/boot_entry.gd`)
4. `grant/tools-ci.patch` (Tools': two steps in `ci.yml`, one Linux and one Windows step in `desktop-builds.yml`)

None of the GW1c stack's pieces touches `audio/`, `boot_entry.gd` or `.github/`, so it can land before or after.

Also commit with it: `docs/audio/listening-sheet.md`, `docs/audio/desktop-sound.md`, `docs/audio/runs/friends-sound/`.

## Checked (clean export of main with all four applied)

With Tools' `docs/tools/pending/audio-scene-cases` park too (apply after patch 2): all 29 node lines of `ci.yml`'s data job pass (two-fighter ratchet 365/365, fighter-specific 0/0); import clean; the 14 audio checks and the host check pass; the proof passes. A Windows release export ran `--audio-proof` and passed. Not run: Linux, the web build, `hud_check`.

Six older checks (`brawl`, `carry`, `coop`, `moments`, `tug`, `world`) assert exact cue lists and saw the new wind loop; each now switches the wind off for its own mapper, with a comment. `scene_check` and `sets_check` run with the data as shipped.

## UI's call lines (`ui/hud/ui_hud.gd`; cut after the GW1c stack, which touches that file)

`AudioVoices.ui(name)` is static, safe before audio exists, and returns false when it plays nothing.

| Where | Line |
| :--- | :--- |
| `menu_action(act)`, after its guard | `AudioVoices.ui("confirm" if act == "accept" else ("back" if act == "back" else "move"))` |
| `_menu_press(h)` (a mouse or touch press) | `AudioVoices.ui("back" if str(h.get("row", "")) == "back" else "confirm")` |
| `pause_menu_action(act)`, after its guard | the same line as `menu_action` |
| `settings_action(act)`, after its guard | `AudioVoices.ui("back" if act == "close" else ("confirm" if act == "accept" else "move"))` |
| `howto_action(act)`, after its guard | `AudioVoices.ui("back" if act == "close" else "move")` |

## Known gaps

- Building events are rare in the computer's own matches (12 cues in 3 minutes), so the listening pass may not reach "a building coming down" without a set-up.
- The wind's level and every new recipe are guesses until Orb listens.
- The proof uses the dummy audio driver: it does not prove a device plays sound.
