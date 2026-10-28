# Cloud brief: Rendering & Technical Art, the view update's bigger cut (sweep what each pane sees)

**Who you are.** You are the Rendering and Technical Art Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/rendering-techart.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/rendering-techart/*`, never to main; report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read:
- `docs/rendering/view-update.md`, especially "A bigger cut, not built";
- your 27l short cuts, now on main as f00de397: `render/core/planet_view.gd`, `tree_view.gd`, and `PlanetView.view_fast`;
- ADR 0011: PC first, so the budget is an old laptop with integrated graphics.

**Branch:** `cloud/rendering-techart/pane-sweep` from origin/main.

**Goal.** The building sweep visits only the buildings within each pane's view every frame, and the rest a slice a frame, so its cost stops scaling with the whole planet. This applies to split screen too, with two panes.

**Constraints:**
- The picture must be unchanged at every frame. A building out of view may wait up to a few frames for its people, but nothing a player can see may lag.
- Behind its own switch, on by default only if every gate passes. A `--no` command-line switch keeps the A/B.

**Acceptance criteria:**
- **Frame proof:** the 19 render gates, `split_sweep` and `seam_sweep` pass. Show the picture is unchanged by a headless pixel comparison, if your tools have one, or by the gates' own image checks. Say exactly which frames were compared.
- **Cost:** report the building sweep's and the planet update's cost before and after (`--noviewfast` and your new switch), on the same machine in the same run: the gen 2 coast, planet 7, at x1 and x4. Mark any run taken on a loaded machine as invalid.
- **Standard gates:** the golden is byte-identical, and determinism passes plain and with `--intro`. Report each gate's last line.

**Look evidence:** list the scenes to capture, so the EP can run the side-by-side and both flash modes locally before landing (ADR 0010).

**Report** as `docs/rendering/cloud-reports/2026-10-28-pane-sweep.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.
