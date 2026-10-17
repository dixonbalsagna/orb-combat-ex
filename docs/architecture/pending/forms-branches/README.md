# Forms' branches: Witness and Trial (parked build)

Owner: Simulation and Engine. 2026-10-17. The second forms window: Game Design's `docs/design/hero-forms.md` section 3 and section 4's pick, on main's forms (8f157894). The rules as built, my readings and the play read are in `../../forms-core.md` section 7. **Built and proved in scratch; nothing is in the tree.** Behind the forms switch (`data/fight/forms.json`, off): with it off, every match, replay and checkpoint is the same to the bit.

## To apply

From the repo root, in this order (no new class, no import needed):

1. `python docs/architecture/pending/forms-branches/branches.py .` (Simulation's files).
2. `python docs/architecture/pending/forms-branches/grant_world.py .`: two lines in World's `sim/world/collateral.gd`, for World to apply or grant. They apply before or after World's collateral window.
3. `python docs/architecture/pending/forms-branches/grant_tools.py .`: Tools' forms schema (`tools/schemas/fighters-forms.schema.json`) learns a step's `branch` and the `branches` block. **It must land in the same commit:** the schema is closed, and without it the validator fails on three unknown properties (CI's data job).

| File | Change |
| :--- | :--- |
| `sim/core/forms.gd` | The fills (`casualty`, `events`, the deficit seconds, the coil's points), the pick (`_pick`), the extras on the gains, `anguishOther`, `level`, `blockWiden` and `followBonus`; the branches' data |
| `sim/core/state.gd` | `FormState.witness`, `trial`, `branch`, `crossed` (hashed only while forms are on) |
| `sim/core/sim.gd` | `SimForms.events` after the mood's tick, while forms are on |
| `sim/core/fx.gd`, `hash.gd` | `form_step` carries `text` (the branch) and `source` (cross) |
| `data/fighters/PROTAGONIST/forms.json` | II and IV marked `branch`; the `branches` block (Game Design's numbers) |
| `sim/core/tools/parity.gd` | The forms check's gains with the branch's extras; one new check, "forms: Witness and Trial" |
| `docs/architecture/fx-events.md` | `form_step`'s two fields |
| World's `sim/world/collateral.gd` (grant) | `kill` tells `SimForms.casualty` where the dead fell and who caused it; `_feed` reads `SimForms.anguishOther` for the opponent's share |
| Tools' `tools/schemas/fighters-forms.schema.json` (grant) | A step's `branch` (boolean); the `branches` object, closed |

## Proof (scratch, HEAD b0542bae, below-normal priority)

- **Both scripts:**
  - import clean;
  - parity on the committed golden, unregenerated, **62 of 62**, no script error, the new check and the forms check among them;
  - the golden regenerated **byte-identical**.
- **The check, "forms: Witness and Trial":**
  - Witness: the rival's kills near him fill it; a kill beyond the range, or with no killer, does not; his own kill takes 2 a person off it; his anguish no longer takes the opponent's kills, and the rival's still does.
  - Trial: the rival's form with his tier no higher, then with his own form held; a deficit tick with its coil; two landed blows of a medium or more and three commitments; a light, a guarded medium, the rival's own blow, a beam hit and his own finisher do nothing.
  - The fills are hashed.
  - The pick at II with Witness the higher, with its extras and care 0.5.
  - The cross at IV to Trial, with its extras: block window 2, follow-up 1, care back to 0.
  - The first tie to Trial, and a tie kept on the branch he is on.
  - One pick for a release from base to IV.
- **In play** (`probe/branches_probe.gd`): 12 AI matches of 14,400 ticks. **Trial was taken in 12 and Witness in none,** and every match played the same twice. That is a balance read for Game Design (`../../forms-core.md` section 7), not a fault.
- **The full gates on that export** (both scripts):
  - npm 5 of 5; parity 62 of 62; determinism plain and with `--intro --seeds=2 --ticks=900` passed; seam passed; flash_worst 76 runs and check-log passed;
  - self-test 7966 of 7966; QA's run-all 7 of 7; the director's loader check passed; flash self-test 95.
  - The validator gave **3 errors without Tools' grant** (the closed forms schema doesn't know `branch` and `branches`). With `grant_tools.py`: **0 errors, 0 warnings**, and the self-test 7966 of 7966.
- **Rendering's 15 checks: all passed.** `cue_check` prints the 650 script-error lines main has too.
- **Re-proved on HEAD fbfdf182** (after World's collateral window landed), with the three scripts and `../brake/` with its World function: parity **63 of 63**, the golden **byte-identical**, the validator 0 errors (one warning: `data/fight/brake.json` has no schema yet), self-test 8309 of 8309. Witness now divides by `WorldCollateral.normPeople`, the meters' norm, which is pop0 by data.

## For the others

| Who | What |
| :--- | :--- |
| World | `grant_world.py` (two lines) |
| Encounter | The perfect-block window reads `SimForms.blockWiden`, and a perfect follow-up's worth reads `SimForms.followBonus`. The AI's holds (hero-forms.md section 4b) remain theirs |
| Game Design | My readings in `../../forms-core.md` section 7. The 25% row: Witness's `perPerson`, or Trial's `commit` and `opponentForm` |
| Narrative | `form_step.text` and `source` (a cross) for the turn's lines; the form ids |
| UI | The fills (`FormState.witness`, `trial`) by his power bar; the branch |
