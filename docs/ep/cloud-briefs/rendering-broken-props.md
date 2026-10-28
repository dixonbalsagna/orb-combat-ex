# Cloud brief: Rendering & Technical Art, broken props leave the view

**Who you are.** You are the Rendering and Technical Art Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/rendering-techart.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/rendering-techart/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read:
- World's W6 report `docs/world/cloud-reports/2026-10-28-biomes-w6.md`, NEEDS 4 and 5;
- `WorldGround.matchProps` (`sim/world/ground.gd:313`) and `DirLaunch.brokenProps` (`sim/director/launch.gd:741`).

**Branch:** `cloud/rendering-techart/broken-props` from origin/main. If `cloud/rendering-techart/pane-sweep` is on origin, branch from it instead and say so. Both touch the view, and the EP lands them in that order.

**Goal.** The view draws the props from `WorldGround.matchProps(S, x0, x1, DirLaunch.brokenProps(S))`. A prop that PROP SMASH breaks then disappears from the picture as it does from the sim, and is re-drawn only when the world is rebuilt. The view reads the sim and never writes it.

**Constraints:**
- With `biome.enabled` off, or before any prop breaks, the picture is unchanged at every frame.
- The break itself is a cut: the prop is there on one frame and gone the next, with the existing debris and dust doing the work. No fade or dissolve (ADR 0010).
- On an old laptop with integrated graphics (ADR 0011), the per-frame cost of the prop pass doesn't grow. Re-query only when `brokenProps` changes, or say why that isn't possible.

**Acceptance criteria:**
- the 19 render gates, `split_sweep` and `seam_sweep` pass;
- a headless pixel comparison shows the frames before the first break are identical, and that the broken prop is gone after it. Say exactly which frames you compared;
- World's `flighthooks_probe` with the switch on: every PROP SMASH that broke a prop has it missing from the view on the next frame;
- the golden is byte-identical, and determinism passes plain and with `--intro`. Report each gate's last line.

**Look evidence:** list the scenes to capture (an embed, snapped trunks, a broken prop), so the EP can run the side-by-side and both flash modes locally before landing.

**Report** as `docs/rendering/cloud-reports/2026-10-28-broken-props.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.
