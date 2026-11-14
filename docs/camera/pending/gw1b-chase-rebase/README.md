# Parked: chase_rush's top-power step limit re-based to the plain chase's (gw1b-chase-rebase)

Camera, 2026-11-15, the EP's decision (option 1): the camera keeps following the chaser exactly. That's Orb's taste, and it keeps him at his anchor. chase_rush's limit for an ordinary send at top power goes from 0.25 to 0.30 of the width a tick, the plain chase's own limit, with the reason in the check: 0.25 was set when that rush read 0.20, and at Orb's dash speed (the 9 November data) it reads 0.29. **Checks only.**

**Apply after gw1b-chase-measure** (cut on main 5cef4af7 + gw1a-pins + gw1b-chase-measure): `git -c core.autocrlf=false apply gw1b-chase-rebase.patch` (sha1 3fa186f1). One file, mine: `render/camera/tests/chase_rush_check.gd`.

- The three arc-off ceilings go: they read 0.288, 0.288 and 0.262, all under 0.30.
- **The four meteor rows keep their ceilings** (step 0.065, jolt 0.036, against 0.06 and 0.03). Their limit is the peak shot's, which owns the frame there, and the plain chase has no peak shot to take a limit from.
- Proof (`docs/camera/runs/5cef4af7/gw1b/runs.txt`): chase_rush passes 130 on the stack with every camera park, 4 rows on a ceiling.

Status at quiet time: done and parked. Main's data wasn't re-run for this one; the change only loosens a limit main's rows already pass.
