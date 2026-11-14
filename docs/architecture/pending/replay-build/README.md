# Parked: a replay names the build that made it (A-NET-05, B1)

Simulation, 2026-11-14, sprint A1 (`docs/ep/alpha/audit-2026-11-13/05-directives/A1/simulation-engine.md`, criterion 1). **Re-cut for B1** after the stand-in's review (`docs/ep/reviews/B1-replay-build.md`). It **lands before golden window GW1**, so every replay made from then on is refused plainly by a later build. **No state changes: the golden is byte-identical.**

## What changes

- **`SimReplay.header(seed, setup, ai, ticks)`: one header for every replay writer,** so they can't drift (the review's point 2). It holds format, version, intent schema, the setup's data hash, the seed, copies of the setup and the AI flags, the ticks, empty lists, and the build that made it when this build has a stamp.
  - The recorder uses it (here).
  - So does Netcode's LAN save (`NetDesync.replayOf`, in the Netcode grant).
  - The page's black box and Tools' report hook call it in Tools' own patches.
- **`SimReplay.buildId()`** reads the stamp Tools' build tools write into an exported build, `res://build_info.json`. It's the stamp's `"id"` if it has one (the page's: the commit and the build's cache key), else `"<commit> <date>"`. A tree with no stamp (a dev tree, CI, a check) is `""`, and its replays carry no build field, so they're exactly as they were.
- **`SimReplay.play` refuses another build's replay before its first tick,** with reason `"build"`. The result carries `"build"` (the replay's id, `""` for a build with no stamp) and `"home"` (this build's), for the sentence a player reads.
  - A stamped build also refuses a replay with no stamp, because it can't tell that file's code from its own.
  - The build is asked before the format version, so a later build's file of another version is named as another build's.
  - A check that knows it's on the matching tree passes `home`.
- **`SimReplay.refusal(rp, home)`** gives the same answer from the header alone ("", "format", "build" or "data"), for a host that checks replays itself. The LAN save's `replayState` uses it, and the page's `bb_play_start` can, to say why a file is refused.

## Two builds of one commit share an id (corrected)

The first cut said a rebuild of the same commit refuses its twin. **It doesn't.** Every stamp's date is the commit's own date (`write-build-info.mjs`, `preview.mjs`, `stack-preview.mjs`), and the page's `id` is the commit plus the build's cache key. So two builds with the same inputs share an id and play each other's replays.
- Different data is still refused, by the data hash.
- **Different patched code at the same commit is not,** wherever the stamp has no `id` (the site build, the desktop builds, a `preview.mjs` build with overlay files: `buildId()` ignores `overlay`). The risk is low, but that's the true rule.

## The sentence a player reads is UI's

The sim returns a reason and two ids, never words. It's forward-facing text, so UI writes it and Orb sees it before use. A draft for UI: *"This replay was saved by a different version of the game (build 6a30b4c, 9 November), so it can't be played in this one."*

## Apply

`git -c core.autocrlf=false apply replay-build.patch grant-netcode-build.patch`, on HEAD f83c78e9 (checked again on f61eb8c2: it applies and reproduces the tested tree).

| Patch | Owner | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `replay-build.patch` (`sim/core/replay.gd`; `parity.gd`'s replay rows) | mine | 73b9862a14f367c140eba5bc0ba21b738493ad1d | 401331c98997 |
| `grant-netcode-build.patch` (`net/desync.gd`: the LAN save builds its header with `SimReplay.header`; `replayState` asks `SimReplay.refusal`) | Netcode | 3cd1b35578e355f5cd169bade065bb5121d18c1a | b88d7f346d3e |

**The first cut's `grant-tools-build.patch` is withdrawn.** Tools call `SimReplay.header` in the black box and the report hook in their own patches, and emit those lines only for a tree whose `replay.gd` has `static func header`, so a page build of an older commit still compiles (the review's point 3).

## The review's other points

- **A stray stamp in a dev tree** (point 4): parity's first replay-build row now says so in plain words, and how to clear it. The repo root's `/build_info.json` is git-ignored, so `git status` won't show it.
- **Parity's test stamp** (point 6): set for the recorder's one call and cleared on the next line. The plays name `home` instead of reading the static, so a script error can't leave later rows running as a stamped build.
- **For Tools and Netcode** (points 1 and 6):
  - a LAN kit cut from a kept build's tree carries that build's stamp;
  - `blackbox-verify` can pass the save's own build as `home`;
  - the four readers of `build_info.json` (`SimReplay.buildId`, `net/lan.gd`, UI's feedback form, the report hook) should agree on one rule. `SimReplay.buildId` is the sim's.

## Proof

On f83c78e9 (records in `docs/sim/runs/f83c78e9/replay-build-b1/`; the first cut's are in `docs/sim/runs/191e5e30/replay-build/`):
- **Golden byte-identical.** Parity through `gate.mjs`: exit 0, no SCRIPT ERROR lines, golden check passed.
- Parity's rows (`_replayBuild`, in "replay module"):
  - a stray stamp is named;
  - a dev tree's replay has no build field and its header is `SimReplay.header()`'s, key for key;
  - another build's replay is refused as `build` before its first tick, with both ids;
  - a replay with no stamp is refused by a stamped build;
  - a later build's file of another version is named as another build's;
  - a dev tree refuses a stamped build's replay;
  - a stamped build's own 120-tick replay and its header carry its id and play, also through JSON;
  - `refusal()` agrees with `play()` and names other data.
- **Negative control** (`rb_neg.gd`): with the check, a foreign replay is refused before tick 1; with `blindBuild`, it runs to its last tick (300).
- `lan_check` (the LAN save's header from `SimReplay.header`): 0 failed. `replay_xproc`, rollback (AI), desync, the word check (623), `cross_check`, `frame_check`: all pass.
- Rendering's 15: all pass. Validator and self-test, lint, ratchet 365, the preview self-test 169.
