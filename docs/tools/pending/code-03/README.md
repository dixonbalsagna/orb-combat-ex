# A-CODE-03: the planet entry, the state probe and the report and replay hook move onto main (Tools, parked 2026-11-14)

Register rows A-CODE-03 (Orb's solo build carries code that is not on main), A-UI-02 (the report and "Save this match" save nothing on a plain desktop build) and the code half of A-ENERGY-04. Brief: `docs/ep/alpha/audit-2026-11-13/05-directives/A1/tools-pipeline.md`, criteria 1 to 3. Nothing here is applied to the repository; the two patches are cut on HEAD 20b0860b and apply to it, and to each other in either order (checked in a scratch git: planet-entry first, then report-hook).

## The two patches (both are Rendering's files: `render/core/main.gd`, `render/core/sim_host.gd`, the new `render/core/match_recorder.gd` and `render/tools/match_recorder_check.gd`)

| Patch | What | Files |
| :--- | :--- | :--- |
| `planet-entry-and-probe.patch` | `_planet_setup()`: the menu's planet part, else the option `planet=N` (touch 3) of the page address or command line. `planet`, `touch` and `preview` join `URL_ARGS` AND `LOCAL_ONLY_ARGS` (RL-196: a word that changes how a match starts, or a debug probe, is dropped on a public page; re-cut 2026-11-14 at the EP's word, sha1 cd8237cb). `_publish_probe()`: with `preview=1` on the web, `window.__preview` (the tick, the planet's generation, what the world's switches read, the hit points), twice a second, read only. | `render/core/main.gd` |
| `report-hook.patch` | `MatchRecorder`: the black box's host half as ordinary code. It READS the tick's intents, the seed, the setup and the AI toggles into SimReplay's own format, through three insert-only hooks in `SimHost` (arm after the setup is kept, `before_step` before `SimCore.step`, `toggle` before `toggleAI`). `SimHost.record_file(reason, tag, note)` writes `user://reports/solo-<commit8>-main-<time>-<reason>.json` ({kind "orb-solo-match", pc, slot, mode solo or couch, build, reason, savedAt, tick, marks, replay}, the shape of a LAN save). `main.gd` sets `ui_hud.lan_report_fn` to it on a desktop build, so the one-press report, "Save this match" and the panel's Save report row work with no UI change; a LAN build's host and the web page's download come first as before. The newest 20 files are kept. | `render/core/match_recorder.gd` (+ .uid), `render/core/sim_host.gd`, `render/core/main.gd`, `render/tools/match_recorder_check.gd` (+ .uid) |

## Proof

- **The check** (`godot --headless --path . --script res://render/tools/match_recorder_check.gd`), run on a scratch export of HEAD with the patch (Windows, headless): **16 checks, 0 failed.** A solo match and a couch match are played through the real SimHost with scripted intents; the report writes `solo-...-report.json` and "Save this match" later writes a second file; each file holds the kind, mode, build, the report mark (tick, tag, note), and a replay that `SimReplay.play` reproduces to the last tick with the live state's final hash; an AI toggle is recorded and still verifies; a host with no match answers the empty name; the folder keeps the newest 20.
- **Negative controls:** a replay missing the second half of its presses does not reproduce, nor does one with every press swapped for another intent.
- **The sim is untouched:** the hook reads the same `inputs` the next line steps with; a replay of the saved file, run on a separate sim with no hook, ends on the hooked host's own final hash.
- **Not run:** Linux (the check is in CI's job after the A-TOOLS-08 split: step text below), the golden/parity (no sim file changes), a window (the game was not opened: no session opens a Godot window), `hud_check`.

## The scratch layer of the private page (tools/preview) after these land

- `switches.mjs`: the three planet edits carry `skipIf: 'func _planet_setup('` (skipped once main has the entry), and the probe adds to `window.__preview` with `Object.assign` instead of replacing it. The hooks of `blackbox.mjs`'s `patchHost` are on the same lines the new hooks sit beside (nothing replaced), so both stay in a page build until the page's copy is retired; checked on the patched files: `patchHost` and `patchMain` still apply. Self-test 164.
- The energy model is a data row now: `power` (data/fight/power.json `enabled`), ON in a page build; the page no longer forces `"power": true` into the setup, it only lets `?power=0` turn it off. When Simulation's data on main has it on, the row has nothing left to flip.

## Where the footprint stands today (the file compare, `tools/preview/build-compare.mjs`)

A page build's source tree against HEAD 59c6b195: **30 files differ**: 26 data and options files (the switch rows), `export_presets.cfg` (the engine template's path), `audio/audio_voices.gd` (the audio log), `render/core/main.gd` and `render/core/sim_host.gd` (the page's scratch code), and `build_info.json` is extra. (`docs/tools/runs/59c6b195/build-compare-preview-tree.txt`.) A desktop build exports the commit as it is: its tree must read "THE TREE IS THE COMMIT"; that run is part of A-TOOLS-01. `node tools/preview/switch-diff.mjs --list` says how many switch rows still differ between main and the 9 November build's packed data: **69 of 86 data rows** at 59c6b195 (`docs/tools/runs/59c6b195/switch-diff.txt`).

## For the CI job (after the split, A-TOOLS-08)

```
      - name: Match recorder check (a solo and a couch match saved as files and replayed; A-UI-02)
        run: |
          set -o pipefail
          node tools/gate.mjs --verdict "match_recorder_check:" -- "$GODOT" --headless --path . --script res://render/tools/match_recorder_check.gd
```
(Use the job's own way of running a Godot check; the line the script prints is `match_recorder_check: 16 checks, 0 failed`.)

## Scope of the recorder

`MatchRecorder` records the two bodies of the sim state (`S.fighters`, the first two slots of SimReplay's format): that is a solo match and a couch match. A 2v2 match (`S.stage` with four bodies) is NOT recorded whole: its replay would lack the other two slots' intents, so the recorder is not offered for it and a 2v2 save waits for the stage-aware version (the EP's note, 2026-11-14; Netcode's LAN save, which records every confirmed input, covers LAN 2v2).

## Needs

- Rendering lands `main.gd`, `sim_host.gd` and the two new files; Simulation reads the hook (it only reads; it sits beside `SimCore.step`). The words a player sees stay UI's ("Saved ...", "can't save"), which already exist.
- Whether matches are also kept automatically is Orb's answer (the manual save comes first, as the brief says).
- Tools, after landing: `lan-report.mjs` learns the `solo-` file name (its pattern is `lan-...`), and the report folder's README says where the files are (`%APPDATA%` of the game, `user://reports`).

## Re-cut 2026-11-14 on HEAD 148f4e16: the report hook names its build (A-NET-05, the B1 review's finding 3)

`report-hook.patch` is re-cut (sha1 210584948d8fdd2aa505409b48caee66e138ea1c, was 5fc43ef9). It applies to HEAD 148f4e16 alone, after `planet-entry-and-probe.patch`, and before it (checked both orders in a scratch git). The one change in the content: `MatchRecorder._begin` now writes `"build"` into the replay header the way `SimReplay.recorder` does, **by name**: `SimReplay.new().has_method("buildId")`, then `call("buildId")`, and the field only when the answer is not empty. So the file compiles and plays before AND after Simulation's replay-build park (`docs/architecture/pending/replay-build/`) lands, whichever lands first; before it, a replay carries no build field, exactly as it did.

- `render/tools/match_recorder_check.gd` has one more check (17 in all): the replay names the build exactly when the build is stamped, and has no `build` field otherwise.
- **Checked three ways** (Godot 4.7.2, headless, Windows, scratch git of HEAD 148f4e16): on HEAD with the hook (no `buildId` yet): 17 checks, 0 failed, no build field. With Simulation's `replay-build.patch` applied and no `build_info.json`: 17, 0 failed, no build field. With it applied and a stamp (`{"commit":"148f4e1","date":"2026-11-14"}`): `SimReplay.buildId()` reads `148f4e1 2026-11-14`, 17 checks, 0 failed, the replay carries that build.
- A saved file's top-level `build` (the build info object of the LAN-style save) is unchanged; this is the replay's own field, which `SimReplay.play` asks of a stamped build.
- Not done: the shared header builder (one `SimReplay` function for the recorder, the LAN save, the black box and this hook). The review preferred it; Simulation has not parked one. This hook asks `buildId` itself in the meantime, and the four writers can move to the shared one when it exists.
- A trap I met running the check: an `APPDATA` in Git Bash's `/c/Users/...` form makes Godot's `get_files_at("user://...")` fail on a folder it has just written to (the check's "keeps the newest 20" case then reads 0 files). Use a Windows-style path (`cygpath -w`) when pointing the game's data folder away.
