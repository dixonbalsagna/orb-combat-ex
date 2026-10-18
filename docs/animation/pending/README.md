# Animation's parked patches

Nothing is parked here that has not been applied. The eighteen patches of 2026-10-13 to 2026-10-17 (N bodies and the runs' look, the tenth round, Combat's pieces, homework 4 and 4b, the pulled joints and bend scans, the guard pass, the hammer's join, the ragdoll's variety, weight and out-of-plane joints, the air brake, the chain's poses, the clinch's C0 and C1, the study's scenarios) were applied by the EP in README order in b328017b; the patch files are in git history (`git show 754afbeb:docs/animation/pending/<name>.patch`, `f53ee87c` for the last four).

Accounts: `docs/animation/many-bodies-and-runs.md`, `tenth-round.md`, `combat-pieces.md`, `homework4.md`, `pulled-frames.md` and `homework4b.md`, `guard-pass.md`, `ragdoll-slices.md`, `clinch-sizing.md`.

## Parked: `fixes-18oct.patch` (2026-10-18), 3 files, render side only

- `render/anim/anim_fighter.gd`: a dodge beat with no args (the spaced profile) plays the plain dodge (`cue_check --profile=spaced` printed "Nonexistent function 'get' in base 'Nil'" 430 times on seed 4); the charge's held flight pose (`ag.hold.charge_heavy`, `charge_light`) is let go the moment he is carried off faster than `cut_speed` (a rush, lunge, drift or bounce), after `lead_scan --strict` found him laid out feet first at 718 u/s on the launcher build; the flight lead's doc comment moved back above its function.
- `data/anim/agency.json`: `charge.cut_speed` 300 (new key: the agency schema, if closed, needs it).
- `render/anim/tools/anim_check.gd`: `_test_charge_cut`.
- The lead frame could not be reproduced from the park's README (no seed or tick in it): 8 and 12 seeds and 4 bodies read 0 on a scratch export with launch anywhere, G2, forms-holds and the grants applied and the switch on.
