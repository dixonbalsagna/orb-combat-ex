# Parked: a replay names the build that made it (A-NET-05)

Simulation, 2026-11-13, sprint A1 (`docs/ep/alpha/audit-2026-11-13/05-directives/A1/simulation-engine.md`, criterion 1). It **lands before golden window GW1**, so every replay made from then on is refused plainly by a later build. **No state changes: the golden is byte-identical.**

## What changes

- **`SimReplay.buildId()`** reads the stamp Tools' build tools write into an exported build, `res://build_info.json`. It's the stamp's `"id"` if it has one, else `"<commit> <date>"`. So every build is its own, a rebuild of the same commit included. A tree with no stamp (a dev tree, CI, a check) is `""`.
- **The recorder writes `"build"`** into a stamped build's replays. A tree with no stamp writes nothing, so its replays are exactly as they were.
- **`SimReplay.play` refuses another build's replay before its first tick,** with reason `"build"`. The result carries `"build"` (the replay's id, `""` for a build with no stamp) and `"home"` (this build's), for the sentence a player reads.
  - A stamped build also refuses a replay with no stamp, because it can't tell that file's code from its own.
  - The build is asked before the format version, so a later build's file of another version is named as another build's, not as a broken file.
  - A dev tree refuses a stamped build's replay. A check that knows it's on the matching tree passes `home` to `play`.
- **`SimReplay.refusal(rp, home)`** gives the same answer from the header alone ("", "format", "build" or "data"), for hosts that build or check replays themselves.

## The sentence a player reads is UI's

The sim returns a reason and two ids, never words. It's forward-facing text, so UI writes it and Orb sees it before use. A draft for UI, in plain words: *"This replay was saved by a different version of the game (build 6a30b4c, 9 November), so it can't be played in this one."*

## Apply

`git -c core.autocrlf=false apply replay-build.patch grant-netcode-build.patch grant-tools-build.patch`, on HEAD 191e5e30 (checked again on ef67696f: it applies and reproduces the tested tree).

| Patch | Owner | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `replay-build.patch` (`sim/core/replay.gd`; `parity.gd`'s replay rows) | mine | 9c96cd73d27bd73e639ed0e4b3c3303bc9186867 | 3ddcf0d81e1a |
| `grant-netcode-build.patch` (`net/desync.gd`: the LAN replay names its build; `replayState` asks `SimReplay.refusal`) | Netcode | 1eb5913be95a3450835c86305af0f42778cee116 | 57d2124fa7f6 |
| `grant-tools-build.patch` (`tools/preview/blackbox.mjs`: the page's black box names its build, and refuses another build's file at play) | Tools | a95ad4c35879b88d6cbce3c24053a22afaf34d6a | 8c6066ff003d |

## Asked of Tools (not in a patch)

- **`blackbox-verify.mjs` plays a saved match against a build's source tree,** which has no stamp. From this landing on, a stamped save is refused there as another build's.
  - Either the handover writes the build's `build_info.json` into its `tree/` (the tree is the build's own sources), or the verifier copies it from the build's `web/` before playing.
  - A save from before this landing has no `build` field and plays on its own tree as before.
- **The stamp must name the build uniquely.** `{commit, date}` does, because the date is the build's own moment. If Tools adds an `"id"` (say the cache key, `6627cb9d...`), the sim uses it as it stands.

## Proof

On 191e5e30 (records in `docs/sim/runs/191e5e30/replay-build/`):
- **Golden byte-identical.** Parity through `gate.mjs`: exit 0, no SCRIPT ERROR lines, golden check passed.
- Parity's new rows (`_replayBuild`, inside "replay module"):
  - a dev tree's replay carries no build field;
  - another build's replay is refused as `build` before its first tick, with both ids;
  - a replay with no stamp is refused by a stamped build;
  - a later build's file of another version is named as another build's;
  - a dev tree refuses a stamped build's replay;
  - a stamped build's own 120-tick replay carries its id and plays, also through JSON;
  - `refusal()` agrees with `play()`, and names other data.
- **Negative control** (`rb_neg.gd`): with the check, a foreign replay is refused before tick 1; with `blindBuild`, the same file runs to its last tick (300).
- `replay_xproc`, rollback (AI), desync, the word check (623), `cross_check`, `frame_check`: all pass.
- Rendering's 15: all pass.
- Validator and self-test, lint, ratchet 365, the preview self-test 161.
