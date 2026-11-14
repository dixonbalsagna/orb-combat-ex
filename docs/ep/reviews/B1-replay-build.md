# Landing review, batch B1: a replay names its build (A-NET-05) and the page's stamp

From Orb's stand-in, for the EP. 2026-11-14, on HEAD 9431211a. Read-only: nothing was run in Godot, and nothing in the batch was changed.

**What was reviewed**
- Simulation's park `docs/architecture/pending/replay-build/` (three patches and the README). `git apply --check` passes on 9431211a, and the three sha1 values match the README's table.
- Tools' stamp change, already committed in 047d4037 (`tools/preview/stack-preview.mjs` `pageStamp`, and its self-test rows).

**How:** I read the patches and the stamp code, one independent reviewer (Opus) traced every place a stamp is written or a saved match is played, and I checked each finding below against the files myself. Cost: about 0.3M tokens.

**Verdict: hold B1 for three small fixes.** The sim side is sound. The golden is safe and nothing reads the clock. The faults are in what the new check does to three tools around it.

## Your five questions

| Question | Answer |
| :--- | :--- |
| Does the golden stay byte-identical, and is nothing read from the clock in the sim? | **Yes to both.** The patch adds no state and no clock read: `buildId()` reads `res://build_info.json` once and caches it. The recorder writes `"build"` only when that file exists. The golden's two replays are built by `scriptedReplay` (`sim/core/tools/golden_recipes.gd:115`, `:576`), not by the recorder |
| Does any path make an unstamped dev tree or CI write or require a build field? | **No, with one trap (finding 4).** A tree with no stamp writes nothing and plays unstamped replays as before. In CI only the site job writes a stamp (`ci.yml:476-477`), and it then only exports. The check jobs never write one |
| LAN: do both PCs share one id? | **Yes, because both run the same kit folder.** The id is the kit's `--build` name (`net/tools/lan_kit.mjs:117`). The handshake does not compare builds, before or after. But see finding 1 |
| Do Orb's older saves still play on their own builds? | **Yes.** None of the kept builds' `tree/` folders has a stamp, and those trees run their own older code. An old save on any *new* stamped build is refused, by design |
| Is "a rebuild refuses its twin" harmful anywhere Orb would notice? | **It does not happen.** No stamp carries a build moment. Every date is the commit's own date, and the page's `id` is the commit plus the build's cache key, so a rebuild with the same inputs has the same id. The README's sentence is wrong (finding 5), in the harmless direction |

## Findings, all verified

**1. Major: the LAN report's clip and its replay check stop working for new LAN builds.**
- `tools/preview/lan-clip.mjs` plays a LAN save on "a kept web build of the SAME commit" (its own header, line 3), through the page's replay path.
- After B1 the LAN save carries `build` = the kit's `--build` name (`lan_kit.mjs:117`: `{commit: a.build, lan: true}`).
- The page compares that with its own id, `<commit8>-<key8>` (`grant-tools-build.patch`, `bb_play_start`). The two never match, so the page refuses the file. `blackbox-verify.mjs:33` (`SimReplay.play(rp)`, no `home`) refuses it on the kept tree for the same reason.
- Orb asked for the LAN reporting tools on 8 November, so Orb would notice this at the next LAN play.
- **Fix:** when a LAN kit is cut from a kept build's tree, write that build's `id` into the kit's stamp. Or let the clip tool and the verifier pass the save's own build as `home`.

**2. Major: the new report hook's saves would be refused by the build that made them.**
- The parked report hook (`docs/tools/pending/code-03/report-hook.patch:73`) builds its replay header by hand, with no `build` field. The sprint lands it before this batch (`A1-sprint.md`, steps 3 and 4).
- A stamped build refuses a replay with no build field. So a desktop or site build would refuse its own "report this" saves in the page's replay and in the verifier.
- That would also block "compared by stills on the same replay" for the first desktop build (step 7).
- **Fix:** the report hook writes `SimReplay.buildId()` as the recorder does. Better: one `SimReplay` function builds the header for the recorder, the LAN save, the black box and the report hook, so the four cannot drift again.

**3. Major: a page build of any commit from before this batch stops compiling.**
- `grant-tools-build.patch` adds `SimReplay.buildId()` to `HOST_FUNCS` in `tools/preview/blackbox.mjs`.
- `patchHost` (`blackbox.mjs:187-198`) appends `HOST_FUNCS` to the `sim_host.gd` of whatever commit is being built. `--rev <sha>` is a documented use (`docs/tools/preview.md:14`, `:160`).
- An older commit's `replay.gd` has no `buildId`, so its patched host fails to parse.
- **Fix:** emit the two new lines only when the tree's `sim/core/replay.gd` has `static func buildId`.

**4. Minor, but it would cost every session a gate: a stray stamp in the shared folder.**
- `tools/write-build-info.mjs` writes to the repo root by default, and `/build_info.json` is git-ignored, so nobody sees it in `git status`.
- With that file present, the dev tree is "stamped": parity's new first row fails ("a dev tree's replay carries a build field"), and every committed fixture replay is refused as another build's.
- The desktop build work this sprint is the likely moment someone runs the tool here. There is no such file now.
- **Fix:** parity says so in plain words when it finds a stamp in a dev tree. Or the build tools write the stamp only into scratch or export trees.

**5. Minor: the README's claim about ids is wrong, and one of its asks is already done.**
- "The date is the build's own moment" and "a rebuild of the same commit included" are false. `write-build-info.mjs` (lines 3-5), `preview.mjs:186` and `stack-preview.mjs` `commitDate` all use the commit's date.
- So two builds of one commit share an id wherever the stamp has no `id` (the site build, the desktop builds, `preview.mjs` builds, even with uncommitted overlay files: `buildId()` ignores `overlay`). The data hash still catches different data. Different patched code at the same commit would not be caught. Low risk, but the README should say what is true.
- The self-test row "a rebuild is its own build" (`stack-selftest.mjs:272`) only shows that two different keys give two ids.
- "Asked of Tools" (the stamp in `tree/`) is done at `stack-preview.mjs:82`.

**6. Minor.**
- The page's `bb_play_start` returns only true or false, so the page cannot tell Orb *why* a file was refused, and UI's sentence has nowhere to show. It also repeats the header test by hand and has no data check. `SimReplay.refusal` exists for exactly this.
- `blackbox-verify.mjs` cannot pass `home`, so a new stamped save cannot be checked on an unstamped scratch copy of its own commit.
- Four readers of `build_info.json` now follow different rules: `SimReplay.buildId`, `net/lan.gd:541-545`, UI's feedback form, and the report hook. A saved file carries a `build` dictionary at the top and a `build` string inside its replay.
- Parity's `_replayBuild` sets `SimReplay._bid` and resets it eight lines later. A script error between the two leaves the later replay rows running as a stamped build.

## Confirmed fine

- The order of the checks (format, build, version and intent, data), and `refusal()` agreeing with `play()`.
- `NetDesync.replayState` is only ever given the session's own replay (`net/desync.gd:363`), so the new check cannot blank a desync report in a match.
- `net/tools/two_pc_check.gd:23`'s `"build"` is its own report header, not the replay's field.
- `tools/feel/feel.gd`, the gauntlet and QA's trace tools step the sim themselves, so they still replay Orb's older saves on any tree.
- The golden-window steps compare records made on unstamped trees, so they are not affected.
