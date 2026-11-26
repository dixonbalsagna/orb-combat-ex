# The friends'-build sound set (Audio and Music, 2026-11-25)

Landed as `7bfbfe6a`. Audio only; nothing writes the sim. **Nobody has heard it.**

## What it adds

- **One quiet wind bed** (`amb.wind`), on its own switch. Louder high up, quieter while blows land, faded in over 2.4 s from -40 dB. It stands down if the biome beds are ever switched on.
- **Building sounds** from the sim's `building_hit`, `floor_hit`, `building_stage`, `floors_fall` and `building_fall`: a hit, windows breaking, a wall breaking, floors falling, a collapse (after its ripple delay). At most one cue of a kind a tick.
- **Menu sounds** (move, confirm, back): `AudioVoices.ui("move")`. **Silent until UI calls it.**
- **The overdrive fix:** the master limiter no longer squares loud peaks (`desktop-sound.md`). Levels under -6 dB are unchanged.
- **A small fix:** while a browser holds sound back, a looped voice is no longer "held" (a held loop never started).
- **The proof** that a build makes sound (`audio/audio_proof.gd`) and `audio/tools/scene_check.gd`.

Data and switches: `audio/data/scene_cues.json`. Code: `audio/audio_scene.gd` (wind and buildings), `AudioVoices.ui` (menu). All sounds are our own synthesis, kept low (the brightness limits for the new ones are in `tone_check.gd`).

Listening: `listening-sheet.md`. Desktop settings and the proof: `desktop-sound.md`. Run records: `runs/friends-sound/`.

## The menu call

`AudioVoices.ui(name)` is static, safe before audio exists, and returns false when it plays nothing. UI's calls (UI's park `docs/ui/pending/menu-sounds/` adds them):

| Where (`ui/hud/ui_hud.gd`) | Line |
| :--- | :--- |
| `menu_action(act)`, after its guard | `AudioVoices.ui("confirm" if act == "accept" else ("back" if act == "back" else "move"))` |
| `_menu_press(h)` (a mouse or touch press) | `AudioVoices.ui("back" if str(h.get("row", "")) == "back" else "confirm")` |
| `pause_menu_action(act)`, after its guard | the same line as `menu_action` |
| `settings_action(act)`, after its guard | `AudioVoices.ui("back" if act == "close" else ("confirm" if act == "accept" else "move"))` |
| `howto_action(act)`, after its guard | `AudioVoices.ui("back" if act == "close" else "move")` |

## Rules for anyone adding sounds to the bank

- `AudioBank.WARM_FIRST` must begin `impact.light`, `impact.light.lite` (`warm_async_check`, which is not in CI: run it by hand).
- The six older checks that assert exact cue lists switch the wind off for their own mapper; `scene_check` and `sets_check` run the data as shipped.

## Known gaps

- Building events are rare in the computer's own matches (12 cues in 3 minutes), so a listening pass may not reach "a building coming down" without a set-up.
- The wind's level and every new recipe are guesses until Orb listens.
- The proof uses the engine's dummy audio driver: it does not prove that a device plays sound. It passed on the exported Linux and Windows programs in CI (`runs/7bfbfe6a/`).
- Not run: the web build.
