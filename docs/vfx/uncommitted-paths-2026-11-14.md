# VFX's uncommitted paths (2026-11-14, from `git status` on render/vfx, data/vfx, art/vfx, docs/vfx)

**No code, data or art of mine is uncommitted**: `render/vfx/`, `data/vfx/`, `art/vfx/` and `tools/schemas/vfx-*` are clean. Everything below is documentation, pictures and parked patches under `docs/vfx/`.

## Pictures and pages (untracked or modified; safe to commit as they are)
- Modified: `docs/vfx/clash-shockwave.md` (the built-from-World's-cues note, the `shape` line), `docs/vfx/power-up-ideas.md`, `docs/vfx/img/power-up-ideas/three-ways-to-power-up.png`.
- New pages: `docs/vfx/catch-the-ground.md` (a held proposal, waits for Game Design), `docs/vfx/flash-readings-tile-ground-plan.md` (this round's plan, A-LEGAL-01), `docs/vfx/marks-on-fighters.md` (this round's A-RENDER-13 re-price), this list.
- Pictures (all under `docs/vfx/img/`): `beam-front/`, `beam-shove/`, `burn-gate/`, `catch-the-ground/`, `clash-press/`, `clash-shockwave/built-release-ticks-146-336-342-348-356-400.png`, `energy-language/`, `flight-lines/`, `meteor-trail/`, `peak-floor/`, `rings/`, `shared-register/`, `struggle-ring/`.
- Gate outputs (CD-22): `docs/vfx/runs/94774fc6/` (the shared-register and shape gates; the clip readings in it are labelled unverified).

## Parked patches under `docs/vfx/pending/`
Tested against main on 2026-11-14 two ways: does its patch reverse-apply (landed) and do the new files it adds exist on main.

| Park | State on main | What to do |
|---|---|---|
| `shared-register` | **landed** (patch reverses clean) | folder can go once the EP confirms |
| `struggle-ring-shape` | **landed** | same |
| `beam-shove` | **landed** | same |
| `ratchet-meteor` | **landed** | same |
| `struggle-ring` | landed in the re-cut form (`struggle_ring` in `clash_wave.gd`); the old patch no longer applies | stale, can go |
| `clash-wave` | superseded by `struggle-ring` | stale, can go |
| `clash-look` | its 15 new files are on main (landed in an earlier batch; the patch no longer applies) | stale, can go |
| `meteor-trail` | its 8 new files are on main | stale, can go |
| `peak-floor` | its marker (`wfloor_from`) is on main | stale, can go |
| `energy-language` | its 5 new files are on main | stale, can go |
| `flight-lines` | its new file is on main | stale, can go |
| `beam-front` | its 3 new files are on main | stale, can go |
| `other-fights` | its 3 new files are on main (`stage_feed.gd`) | stale, can go |
| `perf-level` | its 7 new files are on main | stale, can go |
| `clash-press` | adds no new files; marker not found by this test | **to check**: I will read it against main before saying landed |
| `beam-buckle` | patch empty in this test; two grant patches for Rendering and UI | **to check** |
| `power-burn` | **not landed** (applies forward) | needs the power-core and field-place beneath; waits |
| `aura3d` | **not landed** (none of its 9 new files on main) | parked, no brief |
| `warm-first-use` | **not landed** (applies forward) | A2 item 4: land or retire in writing after Rendering's first-draw probe has read the A2 commit |
| `biome-fx` | grant patches only (`grant-beam-clips.patch`) | Rendering's grant, waits |

"Landed" here is a test, not a record: the EP's landing commits are the record. Where I wrote "stale, can go" the folder is a copy of work already on main, and deleting it loses nothing the patch history does not hold.
