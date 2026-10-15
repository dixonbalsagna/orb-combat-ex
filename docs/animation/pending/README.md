# Animation's parked patches (the tree is untouched; both apply to main as it stands)

| Patch | What | Needs |
| :--- | :--- | :--- |
| `nine-cells-asserts.patch` (2026-10-13, **already applied** in 3198301f) | The two asserts for the recipes' picture, the lead layer's use of the motion he has, `pu.su_drive` as one arm | the chain |
| `many-bodies.patch` (2026-10-15) | **N bodies** and the **lead scan's five frames** (below). 6 files: `render/anim/anim_fighter.gd`, `render/anim/anim_many.gd` (new), `render/anim/tools/anim_check.gd`, `lead_scan.gd`, `joint_scan.gd`, `data/anim/flight.json` | nothing; apply first. A new class: run the editor's `--import` once |
| `runs-look.patch` (2026-10-15) | **The runs' look**: the mash presses, the medium's windmill and held breath, the mashed heavy's march. 4 files: `anim_fighter.gd`, `anim_check.gd`, `render_anim.gd`, `data/anim/press_styles.json` | `many-bodies.patch` first (same two files) |

Both are render side only. Neither moves a sim hash. Account: `docs/animation/many-bodies-and-runs.md`.
