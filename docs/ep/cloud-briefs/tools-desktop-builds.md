# Cloud brief: Tools & Pipeline, desktop builds for Windows, macOS and Linux

**Who you are.** You are the Tools and Pipeline Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/tools-pipeline.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/tools-pipeline/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else install the pinned Linux build as cloud-workflow.md says. Then read:
- ADR 0011 (`docs/decisions/0011-pc-first-mobile-parked.md`): PC first;
- `.github/workflows/linux-export.yml`;
- `export_presets.cfg`;
- your CI-and-Linux report `docs/tools/cloud-reports/2026-10-28-ci-linux.md`.

**Branch:** `cloud/tools-pipeline/desktop-builds` from origin/main.

**Goal.** One manual workflow (workflow_dispatch) builds the game for all three PC platforms from a given commit and uploads each as an artifact a player can download and run:
- **Windows x86_64:** the existing "Windows Desktop" preset; a zip with the .exe and .pck.
- **Linux x86_64:** as linux-export.yml does today, folded in or kept, your call.
- **macOS:** a new preset, universal if Godot 4.7.2 allows it from Linux; an unsigned .zip holding the .app. Notarizing needs an Apple account, which zero budget rules out. Write in the docs what a player must do to open an unsigned app.

Every export template download is pinned by SHA-512, as setup-godot does. Each artifact carries `build_info.json` (commit, date), the licence notices the web build carries, and the AI disclosure line.

**Acceptance criteria:**
- In this container, export all three from HEAD with the pinned templates.
- Run the Linux build headless with its gameplay-hash bench, as linux-export.yml does. Its hash equals the editor's on the same frames.
- Inspect the Windows and macOS packages for structure (files present, pck readable, sizes). You can't run them here: say so plainly.
- Every step name containing ": " is quoted. `node tools/check-workflows.mjs` and its self-test pass.
- Write `docs/tools/desktop-builds.md`: how to start the workflow, where the artifacts land, what each holds, and the unsigned-macOS steps.
- Gates: validate and its self-test, and lint.

**Not in scope:** Steam upload, code signing, store pages.

**Report** as `docs/tools/cloud-reports/2026-10-28-desktop-builds.md` with sections SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.
