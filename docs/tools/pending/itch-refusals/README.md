# Park: the page upload's refusals, with nothing that can send (Tools, 2026-11-25; A2 job 4)

`itch-refusals.patch`, cut against HEAD e8943864. All Tools' paths. `git apply docs/tools/pending/itch-refusals/itch-refusals.patch`. Apply after the testers' words (2d2153a8, landed): its package check uses them.

- `tools/store/itch-push.mjs`: checks only. It runs no upload tool, opens no connection and refuses `--push`.
- `tools/store/itch-push-selftest.mjs` (25 checks), a CI step in `ci.yml`, a paragraph in `docs/tools/store-page-checklist.md` section 5.

**It refuses** in CI; without either committed approval file (page and desktop builds, each with its own typed date, 0 to 30 days); with an archive that is missing, will not unpack, is not in a committed record by SHA-256, or fails `verify --locked --testers`; with two commits or versions, a version that is not the changelog's newest (`--rollback`: an earlier one), or no line for players; with no page name in the git-ignored `.private/store/itch-target.txt`.

**Run:** self-test 25; workflow, workflow-shell, workflow-paths, desktop-audience and CI-budget checks; content screen 0 failing. On this PC: made-up archives unpacked with the system tar and were refused; the record search found a real checksum and not a made-up one. **Not proven:** a clean pass on a real package (none can be made yet); the unpacking on Linux.

**For Legal:** RL-272 asks for a scope line containing "restricted itch.io page", but the scope line it gives reads "restricted, key-only itch.io page", which does not contain that. The script accepts both.
