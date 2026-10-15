# Animation's parked patches (the tree is untouched; they apply to main as it stands, in this order)

| Patch | What | Needs |
| :--- | :--- | :--- |
| `nine-cells-asserts.patch` (2026-10-13, **already applied** in 3198301f) | The two asserts for the recipes' picture, the lead layer's use of the motion he has, `pu.su_drive` as one arm | the chain |
| `many-bodies.patch` (2026-10-15) | **N bodies** and the **lead scan's five frames** (below). 6 files: `render/anim/anim_fighter.gd`, `render/anim/anim_many.gd` (new), `render/anim/tools/anim_check.gd`, `lead_scan.gd`, `joint_scan.gd`, `data/anim/flight.json` | nothing; apply first. A new class: run the editor's `--import` once |
| `runs-look.patch` (2026-10-15) | **The runs' look**: the mash presses, the medium's windmill and held breath, the mashed heavy's march. 4 files: `anim_fighter.gd`, `anim_check.gd`, `render_anim.gd`, `data/anim/press_styles.json` | `many-bodies.patch` first (same two files) |
| `tenth-round.patch` (2026-10-15) | **The tenth round, the moveset distinction, the interjection's tell.** 10 files: `anim_fighter.gd`, `render_anim.gd`, `anim_check.gd`, `flurry_study.gd`, `wave_gen.mjs`, `fighters.json` (`ease`), `pair_live.json`, and the new wave `round10` (`round10.mjs`, `round10.poses.json`, `round10.sequences.json`) | both patches above, in order |

All three are render side only. None moves a sim hash. Accounts: `docs/animation/many-bodies-and-runs.md` and `docs/animation/tenth-round.md`.
