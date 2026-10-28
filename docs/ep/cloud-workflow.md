# Working as a cloud session (EP, 2026-10-28)

Orb has $250 of cloud-session credit that expires on 4 November 2026. Some directors continue their sessions in the cloud until then. Everything in CLAUDE.md still applies. This page covers what is different in the cloud.

## What is different
- **You can't message anyone, and the EP can't see your screen.** The EP (local, session "Meridian - Executive Producer") can still send *you* messages. You report by pushing to git.
- **Your machine is a Linux container, not Orb's PC.** The machine rules about Godot process counts and below-normal priority protect Orb's PC, so they don't apply here; use the cores you have. The browser-capture rules still apply: there is no Tools launcher here, so **run no browser captures at all**. Side-by-sides, flash clips and web profiling stay local.
- **Godot.** Install it the way CI does. Read `.github/actions/setup-godot/action.yml` for the pinned Linux URL and SHA-512, download that one zip to /tmp, check the SHA-512 (stop if it doesn't match), unzip it, and import once with `$G --headless --path . --import`. Download nothing else unless your brief names it.

## How work comes back
1. Work on a branch named `cloud/<your-slug>/<topic>` (for example `cloud/world-environment/biomes-w4`). **Never push to main.** The EP merges.
2. Change only your owned paths. A grant the EP has already approved in your brief may touch other paths; list every such line in your report.
3. Before you push, run the gates that cover your change, and paste each one's last line and exit code into your report. The standard set: `node tools/validate.js` and `--self-test`, `node tools/lint-determinism.mjs`, `npm test --prefix sim` (the golden must stay byte-identical unless your brief says otherwise), `render/anim/tools/anim_check.gd`, every `sim/world/tools/*_check.gd`, `render/camera/tests/split_sweep.gd`, `sim/core/tools/campaign_episode.gd` and `sim/core/tools/parity.gd`, plus your own area's checks.
4. Write the report into the branch as `docs/<your-area>/cloud-reports/<date>-<topic>.md`, in the standard format: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Keep it short.
5. Commit with a message that names the outcome, push the branch, and end your turn. The EP watches `cloud/*` branches, reads the report, gates it again if needed, and merges or replies by message.
6. A change to what the player sees must sit behind a switch that is off by default, and its report must say "look evidence pending (local)". The EP arranges the side-by-side and flash clips on Orb's PC.

## Spending the credit well
- One brief at a time, each worth hours of work. Don't idle-poll, and don't rerun gates you have already run on the same tree.
- Stop and report if you're blocked. Don't spin.
- When a brief is done and your report is pushed, end your turn. The EP sends the next brief.
