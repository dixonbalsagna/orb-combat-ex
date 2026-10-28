# Cloud brief: Tools & Pipeline, CI gates and a Linux / Steam Deck export

**Who you are.** You are the Tools and Pipeline Director for Orb Combat EX, working as a cloud session. Read in this order: CLAUDE.md, your charter `docs/directors/tools-pipeline.md`, and **`docs/ep/cloud-workflow.md`**. The cloud workflow overrides your charter where they differ: you commit and push, but only to `cloud/tools-pipeline/*` branches, never to main, and you report in the branch. Then read `.github/workflows/ci.yml`, `.github/actions/setup-godot/`, `export_presets.cfg`, `docs/perf/desktop-boot-2026-10-27.md` (its "platform notes for Steam" section), and `docs/net/cloud-reports/2026-10-28-rollback-core.md` (NEEDS item 6).

**Branch:** `cloud/tools-pipeline/ci-linux`, from origin/main.

**1. Two CI gates.** Each is a step in `ci.yml` with a clear name, kept short:
- the rollback check: `net/tools/rollback_check.gd -- --seeds=1 --ticks=300 --profiles=lan,p80j,p200`, plus `--negative-control` at 240 ticks;
- the sim's load split: `sim/core/tools/load_split.gd`. Only add it if that file is on main when you start; if not, write the step commented out and note it.

**2. A Linux export for Steam Deck.**
- Add a Linux/X11 preset to `export_presets.cfg`: release, Compatibility renderer, `x86_64`, the same pack filters as the Windows preset.
- Add a manual GitHub workflow, `linux-export.yml` (workflow_dispatch only). It installs Godot and the export templates through setup-godot's pinned hashes, exports the Linux build headless, sets the executable bit, runs it headless with `--bench` (or the closest headless smoke the project has) to prove it boots and plays to a gameplay hash, and uploads the build as an artifact.
- You can test the export here: download the pinned templates, export, run the binary headless, and confirm its gameplay hash at a fixed tick matches the web and Windows hash in desktop-boot-2026-10-27.md.

**3. Steam-readiness notes.** A short `docs/tools/steam-deck.md`: what the Deck needs (Proton against native Linux, controller glyphs, resolution, suspend), and what can't be checked without a Deck.

**Rules:** don't change the existing jobs' behaviour. Don't commit binaries. Don't touch the deploy job.

**Acceptance criteria:**
- the new CI steps run locally in your container with the commands CI uses;
- validate and the self-test pass;
- the Linux binary boots headless and its hash matches.

**Report** as `docs/tools/cloud-reports/2026-10-28-ci-linux.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn.
