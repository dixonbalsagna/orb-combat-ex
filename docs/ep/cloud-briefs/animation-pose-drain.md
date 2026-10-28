# Cloud brief: Animation, the pose_exists full drain

**Who you are.** You are the Animation Director for Orb Combat EX, working as a cloud session. Read in order: CLAUDE.md, your charter `docs/directors/animation.md`, and **`docs/ep/cloud-workflow.md`**: it overrides your charter where they differ (commit and push only to `cloud/animation/*`, never main; report in the branch). Godot: use `$GODOT` if set, else install the pinned Linux build as cloud-workflow.md says.

**Branch:** `cloud/animation/pose-drain`. Read `docs/animation/incremental-bake.md` and `docs/animation/tick-cost.md` (the frame-aware bake slice is parked locally and lands separately; base on main).

**Goal.** `AnimData.pose_exists()` drains ALL queued wave work the first time anything asks for a pose that doesn't exist yet (for example `gc.hold.brace_tumble`), which is one long frame on a phone. Make a missing-pose lookup bake only what it needs (the one wave or pose), never the whole queue, with identical poses. Measure natively: the worst single frame before and after in a seeded match (headless), and the count of on-demand bakes.

**Acceptance:** anim_check and the scans --strict; determinism plain and --intro; `bake_check` hash 2051599411 (or whatever main's bake_check prints) eager and lazy, unchanged; the standard gate set.

**Report** as `docs/animation/cloud-reports/2026-10-28-pose-drain.md`. Push and end your turn.
