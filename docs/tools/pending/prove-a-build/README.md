# Park: the "prove a build" kit (Tools, 2026-11-23; path to Alpha 1, job 7)

The kit, built and tried on main 66d4e460. **The records are not taken here: they are taken on the GW1c commit** (the EP's order).

**The change is already in the working tree** (uncommitted, my owned paths). Commit those paths directly; the two patches are the same change against 66d4e460 for a gate in a scratch tree (`prove-a-build.patch` applies alone, and together with `first-run.patch`; do not apply it on top of the working tree).

## Uncommitted paths (this park)

- Changed: `tools/desktop-local-build.mjs`, `tools/desktop-local-build-selftest.mjs`, `.github/workflows/ci.yml` (one step, "Record paths, tar.gz writer and run-record self-tests..."), `docs/tools/desktop-builds.md` (a last section)
- New: `tools/lib/targz.mjs`, `tools/record-paths.mjs`, `tools/record-paths-selftest.mjs`, `tools/desktop-run-record.mjs`, `tools/desktop-run-record-selftest.mjs`
- New records (cleaned of this PC's paths, filed): `docs/tools/runs/cb8d7934/owner-private-build-record.txt`, `docs/tools/runs/b624340a/owner-private-build-record.txt`
- Not in the patch, for the GW1c commit: `version-build-1.patch` (below)

## What each of the four asks became

1. **The pad-quit grant: YES, as it stands** (UI's `docs/ui/pending/pad-quit-smoke/grant/mode-smoke-pad-quit.patch`, sha1 8fd14ebc4d04). Applied to a scratch copy of main 66d4e460: it applies clean (`git apply --check`), and the mode smoke through its patched runner passes **solo and two people, 24 steps each, 0 failed, the program closed by itself both times** (so no run "stopped at the limit"), with `--commit 66d4e460` stamping the results. I read the three files against the old ones: the "told to close" step is required by `readResult`, a result with no such step fails (new self-test row), a run stopped at the limit fails, and `--commit` only fills in when git cannot answer. Nothing I would change. The EP applies it (it changes my paths; I did not).
2. **The build is numbered and its changelog entry is written.** `node tools/version.mjs --next` raises `tools/version.json` (0.1.0 to 0.1.1; the counter is 0 now) and puts the entry at the top of `docs/tools/changelog.md`, in the commit that is built. `version-build-1.patch` holds that for main 66d4e460 with a **draft** "For players" text (Orb reads it first; four lines: the list of modes and the fighter pick, the pause menu and its Quit question, the computer answering a held charge, and that the planet sizes are not in it). Applied to a scratch tree, `node tools/version.mjs --check --ready` passes. **On the GW1c commit: do not apply this patch; run `node tools/version.mjs --next` there** (the "For the team" list is the commits since the last entry) and paste the players' text, edited for what is then true. I did not put the bump in the working tree, because the number belongs to the commit that is built.
3. **Linux in the one command.** `node tools/desktop-local-build.mjs --platform windows|linux|both` (default both). Tried on 66d4e460, both: every step ok. Windows zip 44,471,403 bytes, its program played the bench and printed the project's hash (9d323c7f64c75955). Linux `.tar.gz` 35,420,148 bytes, program exported (85,398,176 bytes), packed by our own writer (`tools/lib/targz.mjs`: mode 0755 for the program, since Windows' tar has no executable bit), unpacked with the system tar, `verify --platform linux` ok (ELF magic, pck, notices, lock, private line), executable bit read back from the archive (755). **Not done on this PC: the Linux program was not started** (no WSL; an ELF); the record says so and gives the project's hash to compare with; the CI run plays it. Windows' side of the same command is unchanged apart from names.
4. **Saved runs and clean records.** `node tools/desktop-run-record.mjs <run id>` saves a `desktop-builds.yml` run as a page (jobs and times, failed steps with log tails, each job's hash and whether they agree, packages' sizes and SHA-256, artifact count). Tried: run 45265314781 (dispatched on main 66d4e460, owner-private, uploads nothing) is the first run the tool reads; its page is filed as `docs/tools/runs/66d4e460/desktop-run-45265314781.md` (success, 4 jobs; the Linux program played on the runner and printed 9d323c7f64c75955, the same hash this PC's Windows program and project bench printed for 66d4e460; no artifacts). The two existing build records (cb8d7934 and b624340a, which were in `homework/Files/desktop`) are cleaned with `tools/record-paths.mjs` (the scratch folder is `<scratch>`, a user folder `<user>`) and filed under `docs/tools/runs/`. A CI step now checks that no user folder path is in anything under `docs/tools` (158 files read, 0 hits) and the new local-build record is written clean by itself.

## Checks run in a scratch checkout of HEAD with the park applied

Self-tests: local build 10, record paths and tar.gz 19, run record 6, all pass; `check-workflows`, `check-workflow-shell`, `ci-budgets-check`, `check-scripts-table --check` (277 scripts, 200 in CI, 55 unreviewed = the ratchet), `version.mjs --check`, `content-screen` (0 failing hits).

## Not proven

- The Linux program running (above). The CI run of the new CI step (it is a plain node call).
- `desktop-run-record.mjs` against a run that FAILED (it is self-tested with a fake one: the failed-step tail is a real code path, not yet seen on a real log).
- That the draft players' text says what Orb sees: it is from the commit list and the mode smoke, not from playing.
