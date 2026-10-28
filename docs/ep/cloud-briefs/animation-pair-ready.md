# Cloud brief: Animation, pair_ready from a fighter's own waves

**Who you are.** You are the Animation Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/animation.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/animation/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says.

**Branch:** `cloud/animation/pair-ready` from origin/main. Your pose-drain fix landed as 5d8d4978. Read its report `docs/animation/cloud-reports/2026-10-28-pose-drain.md` (NEXT 1) and `docs/animation/tick-cost.md`.

**Goal.** Do the same for `pair_ready`: build one fighter's lists from his own waves only, instead of running the queue up to them. The poses and lists must stay identical. Measure natively, before and after:
- the worst single frame in the first seconds of a seeded match;
- the count of on-demand bakes.

**Acceptance criteria:**
- anim_check, and the scans with `--strict`;
- determinism, plain and `--intro`;
- `bake_check` prints hash **720091122**, eager and lazy, unchanged;
- tick_bench;
- the standard gate set in cloud-workflow.md, each with its last line in the report;
- no look change.

**Report** as `docs/animation/cloud-reports/2026-10-28-pair-ready.md`. As last time, list under CHANGES any lines outside `art/animation/`. Push and end your turn.
