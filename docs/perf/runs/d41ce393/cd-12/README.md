# CD-12: desktop workflows must not publish an unlocked build (Performance and Platform, 2026-11-07, commit d41ce393)

Audit F-12 / corrective directive CD-12. Routed to Tools and Performance & Platform; the files are `.github/workflows/`, Tools' paths, so this is a **patch to apply**, not an edit: `git apply -p2 docs/perf/runs/d41ce393/cd-12/cd-12-desktop-lock.patch` (checked with `git apply --check -p2` on d41ce393: OK; `node tools/check-workflows.mjs` on the changed file: ok).

**What the patch does**
1. **Folds `linux-export.yml` into `desktop-builds.yml`.** The desktop job already exports Linux, plays the binary's bench and compares the gameplay hash, behind the lock and the route scan; `linux-export.yml` is deleted, so no workflow uploads a game binary without them. (`linux-export.yml`'s manual Linux-only run goes; the Linux artifact is one of the three.)
2. **`shell: bash` as the workflow default.** GitHub's `bash` is `bash --noprofile --norc -eo pipefail {0}`; the Linux default (`bash -e {0}`) loses a pipe's exit code. Both `gate.mjs ... | tee` steps now fail when gate.mjs fails. Shown here: `false | tee /dev/null` under the default shell exits 0, under `bash -eo pipefail` exits 1 (run on this PC's bash, 2026-11-07).
3. **A recorded approval instead of a date typed into a form.** The run needs `docs/ep/approvals/desktop-test-builds.txt` committed in the commit being built, with `date: YYYY-MM-DD`, a `scope:` line naming desktop test builds and a `recorded-by:` line; the `orbs_yes` input must equal that date and the date must be 0 to 30 days old. The check runs after the checkout (it reads the checked-out file) and before anything is built.

**Needs from the EP (not mine to do):** apply the patch (Tools' files); create `docs/ep/approvals/desktop-test-builds.txt` when Orb says yes (no file means no run, which is today's safe state); Tools to update `docs/tools/steam-deck.md:8` and `docs/tools/README.md` (they name `linux-export.yml`) and the `workflow-lint` expectations if any name the file. The workflow has never run (`gh run list`, per the audit), so nothing here is tested on GitHub; one dispatch with a deliberately wrong date should be the first test (it must refuse).

**Not done:** a CI run on GitHub (no remote access from here); `desktop-package.mjs` itself is unchanged (its lock, routes and verify steps are what the audit asked to keep).
