# GW1a: the check-scripts table for the final stack (Tools, parked 2026-11-14)

The EP's first GW1a gate failed `check-scripts`: "57 scripts are neither in CI, nor in the gate, nor given a reason; the ratchet allows 55". This is the read of the final stack and the fix.

**The read.** `node tools/check-scripts-table.mjs --check` on a clone of the EP's final stack `s422` at b09d705 (read only; I cloned it, did not run in it): **267 scripts, 191 in CI once this park is on, 20 in the gate only, 1 not run on purpose, 55 unreviewed (ratchet 55)**. Against main today (262 scripts, 55 unreviewed) the stack adds five scripts:

| Script | Where it stands on the stack |
| :--- | :--- |
| `audio/tools/sets_check.gd` | in CI on the stack: the stack applies `ci-sets-step.patch` (main's `ci.yml` has only the comment) |
| `render/camera/tests/own_pane_check.gd` | already in CI: the stack's `ci.yml` has the step (Camera's park) |
| `sim/world/tools/cache_warm_check.gd` | already in CI: `tools/world-checks.json` lists it |
| `render/tools/match_recorder_check.gd` | **unreviewed** (mine: the report hook's check, A-UI-02) |
| `sim/director/tools/match_end_check.gd` | **unreviewed** (A-MODES-07, the match-ending park) |

The two unreviewed ones are the whole of the 57. Both are run here, so both go **into CI**, not into the reasons list.

| File | What |
| :--- | :--- |
| `ci-gw1a-checks.patch` (sha1 `ca24378e1780fe6f56e968369eec3e935b2cdb4b`) | `.github/workflows/ci.yml`: two steps in the `godot-sim` job, after the cross end negative control: the match recorder check and the match end check, each through `tools/gate.mjs` (the plain form: both scripts `quit(1)` on a failure). Applies to HEAD and to the stack. |
| `check-scripts.md` (sha1 `8f988d2f953dbb6672e21885cb2fc11eb07a5009`, re-generated 2026-11-21 with World's memory-under-model on the stack: 268 scripts, 192 in CI, 55 unreviewed) | `docs/tools/check-scripts.md` as `--write` makes it on the stack with the patch: 267 scripts, 191 in CI, 55 unreviewed; the five new rows. It replaces the table file once the stack has landed (on main today it would list 262). |

**Kept:** `../gw1a-retire/ci-sets-step.patch` stays. (My first note here said it was redundant: wrong. The stack's `ci.yml` has the audio sets step only because the EP's stack applies that patch; main's `ci.yml` has just the comment.) Land it with Audio's park as before. `ci-gw1a-checks.patch` applies on top of it or without it: its two steps sit in the `godot-sim` job, a different job, and I checked it applies to both HEAD and the stack.

## Proof (on a scratch clone of the stack, with the patch applied)

- `check-scripts-table --check`: **191 in CI, 55 unreviewed (ratchet 55)**, exit 0 (without the patch: 57, exit 1).
- `check-workflows` ok (13 files), `check-workflow-shell` ok (262 run steps parse), `check-workflow-paths` ok (every file the workflows name is in git: both scripts are tracked on the stack).
- Both checks run headless, below-normal, on the imported stack clone: `match_recorder_check` **20 checks, 0 failed, 10 s**; `match_end_check` **0 checks failed, 55 s**; no SCRIPT ERROR line in either.
- Time: the two steps add about 65 s to `godot-sim`, which measured 15.4 min against a budget of 30 (`tools/ci-budgets.json`). I did not put them in `godot-roll-render`, which measured 25.9 of 30.

## Not proven

- Neither step has run on a runner. The timings are from this PC, a clean import and one Godot at a time; a shared runner is slower. `match_end_check` plays whole matches to their end, so a long seed on a slow runner is the one to watch; read the first run.
- The ratchet stays at 55: the 55 unreviewed are other owners' questions (the EP routes them), not part of this.
- Not run: the rest of the gate on the stack (the EP's gate does that).

## GW1a retirement, on this stack

I re-read `gw1a-retire` against b09d705: the **same 82 rows** are at their `to` value (the id list equals the one the patch was cut from, so `gw1a-retire.patch` is unchanged, sha1 `8bf4586ce97a19996a5fcb26cbd80639988b2890`), `switch-diff --tree` on it reads **1 of 87** on the old table (`power`, where main is ahead of the 9 November build), and the three look words are still on by default in the code (`notiles`, `nocraterlook`, `VfxLook.METEOR_DEFAULT` all there). The patch still applies to HEAD. Nothing moved.
