# B1's Tools piece: the header, the refusal and the home (A-NET-05; Tools, parked 2026-11-14)

The stand-in's review (`docs/ep/reviews/B1-replay-build.md`, findings 1, 2, 3 and 6) and the EP's brief, after Simulation's `grant-tools-build.patch` was withdrawn. Simulation's side is `docs/architecture/pending/replay-build/` (`SimReplay.header`, `buildId`, `refusal`, `play(rp, home)`). Nothing here changes a file that is not Tools' except the report hook, which is a patch.

## What changed

| Item | Files | What |
| :--- | :--- | :--- |
| (a) the page's black box | `tools/preview/blackbox.mjs`, `preview.mjs`, `stack-preview.mjs`, `preview-selftest.mjs` (all Tools') | The header and refusal lines are emitted **only when the tree's `sim/core/replay.gd` has `static func header`** (`hasHeader(tree)`, `withHeader`, `patchHost(text, { header })`), so a page build of an older commit still compiles (finding 3). With it: the recording's header is `SimReplay.header(seed, setup, ai)` (no hand-written dict), and `bb_play_start` asks `SimReplay.refusal(rp, home)`; a refusal sets `window.__replay_refused` to `format`, `build` or `data` and `window.__replay_refused_ids` to the file's and the page's build, so the page or a tool can say why (finding 6). `window.__replay_home` still names a save's own stamp as `home`. The first cut's `hasBuildId` / `withBuildId` are gone (a tree with `buildId` and no `header` is the withdrawn cut: treated as an older tree). |
| (b) the report hook | `docs/tools/pending/code-03/report-hook.patch` (re-cut, sha1 `ebe79b6a0480e79b5fa421f529849d01f6157e77`; Rendering's `match_recorder.gd`, `sim_host.gd`, `main.gd` and the check) | `MatchRecorder._begin` builds its header with `SimReplay.header(...)` **when it exists**, asked by name (`has_method("header")`); without it the by-hand dict stays, with the by-name `buildId` fallback, so the file compiles and plays before AND after replay-build lands (finding 2's better fix, with the earlier tolerance kept). The check has one more case (18 checks): the replay's header keys are `SimReplay.header`'s, key for key. |
| (c) the verifier | `tools/preview/blackbox-verify.mjs` | `--home <build id>` or `--home save` (the id from the file's own `replay.build`): the save is replayed with that as `home`, so only the build test is waived (the data hash, the format and every checkpoint still hold). A tree from before `header` ignores it and says so. A refusal for build now prints both ids and the hint. Findings 1 and 6. |
| (d) `lan-clip.mjs` | none | Dropped, as the EP said (Netcode's lan-stamp writes the kept build's id into the kit's stamp). The `--home` pass-through from the earlier cut (`homeOf`, `blackbox-clip --home`) stays in the tree and does nothing when the stamps agree. |

## Proof (Godot 4.7.2 headless, Windows, scratch git copies of HEAD f1f91f45)

- **Main alone** (no `header`): the hook's check **17 of 17**; the patched sim host loads (`LOADHOST ok`), with no header or refusal lines in it.
- **Main + `replay-build.patch` + `grant-netcode-build.patch`**: the hook's check **18 of 18**, unstamped and stamped; the patched sim host loads with `SimReplay.header(` in it. A recording made in a stamped tree carries `build` `f1f91f4 2026-11-14`.
- **The verifier**, on a 90-tick replay recorded with `SimReplay.recorder` in a stamped tree: its own tree: `BLACKBOX OK`; an UNSTAMPED copy of the tree, no `--home`: `FAILED: reason=build` with both ids and the hint; the same with `--home save`: `OK`, final hash unchanged; `--home bogus`: `FAILED: reason=build`; an older tree (no `header`) with `--home save`: plays, says the option was ignored.
- `tools/preview/preview-selftest.mjs` **171 checks ok** (was 169; the `hasHeader` cases: yes, no, no file, and the first-cut `buildId`-only tree is no), `stack-selftest` ok, `lan-clip-selftest` 95 ok.
- The patch applies to HEAD alone, after `planet-entry-and-probe.patch`, and on main + replay-build + the Netcode grant.

## Not proven

- The page's black box was only **parsed** (the patched host loads), not run in a browser: recording through `SimReplay.header` and the refusal flags on a web build have not been exercised. The first page build after replay-build lands is that test; a refused file there should set `window.__replay_refused`.
- `blackbox-clip.mjs` does not yet read `window.__replay_refused` to name the reason when it films a refused file. Small; say if you want it.
- A save made before replay-build has no `build`; a stamped build refuses it by design (`--home save` has nothing to take: pass `--home <id>` or use the tree it was made on).

## Order

The Tools files can land before or after replay-build: with no `header` in the tree they emit exactly what they did. The report-hook patch is on GW1a's list and applies either way.
