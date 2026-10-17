# Forms: the Protagonist's five steps and the slingshot (parked build)

Owner: Simulation and Engine. 2026-10-17. The build of `../../forms-core.md` (Game Design's `docs/design/hero-forms.md` sections 4 and 4b, and Narrative's hold and release signals). **Built and proved in scratch; nothing is in the tree.** Behind `data/fight/forms.json` `enabled` (false): with it off, every match, replay and checkpoint is the same to the bit.

## To apply

From the repo root, in this order, then an import (`SimForms` is a new class):

1. `python docs/architecture/pending/forms/forms.py .` (Simulation's files: the module, the two data files, the core's hooks, the check, the three events in `fx-events.md`).
2. `python docs/architecture/pending/forms/grant_encounter.py .` (four lines in Encounter's `sim/director/`, for Encounter to apply or grant). With forms off they read today's numbers; without them, a forms match plays the right steps but the director's speed estimate, its launch force and the transform event's tier read the shared ladder's.

| File | Change |
| :--- | :--- |
| NEW `sim/core/forms.gd` | `SimForms`: the data, the steps and the coil, the release, the hold's signal, the gains |
| NEW `data/fight/forms.json` | The switch (off) and the hold's signal (60 ticks) |
| NEW `data/fighters/PROTAGONIST/forms.json` | His five steps, gains, coil, patience and release: Game Design's first values |
| `sim/core/state.gd` | `S.formsOn`, `FormState`, `Fighter.form` and `Fighter.fd` |
| `sim/core/sim.gd` | The switch and each fighter's form state in `newMatch` |
| `sim/core/hash.gd` | `FormState` hashed only while forms are on; the three events' fields |
| `sim/core/fighter.gd` | Readiness from his steps, the hold's tick, the transform and the break, his speed, regen and recovery |
| `sim/core/damage.gd` | The damage factor; patience, his guard's gain and the coil in `hurt` |
| `sim/core/pause.gd` | A release of live steps is live |
| `sim/core/replay.gd` | The forms data in a replay's data hash, only with forms on |
| `sim/core/fx.gd`, `view/fx.gd` | `form_hold`, `form_release`, `form_step` |
| `sim/core/tools/parity.gd` | "forms: five steps and the slingshot" |
| `docs/architecture/fx-events.md` | The three events' rows |
| Grant: `sim/director/exchange.gd`, `data.gd`, `launch.gd` (Encounter's) | The transform event's tier; the speed estimate; the launch planner's and doLaunch's tier factor |

## Proof (scratch, below-normal priority, one Godot job at a time)

| Run | Base | Result |
| :--- | :--- | :--- |
| `forms.py` alone | HEAD 1e06319b with the depth window (as main became at 46734840) | Import clean. Parity on the committed golden, unregenerated, **60 of 60**, no script error, the new check among them. The golden regenerated **byte-identical** |
| `forms.py`, the grant and `../anim-events/` together | HEAD 70cf2fe6 | Parity **61 of 61**, the golden **byte-identical**, and the full gates (below) |
| The full gates, on that export | | npm 5 of 5; parity 61 of 61; determinism plain and with `--intro --seeds=2 --ticks=900` passed; seam 1280x720 passed; flash_worst 76 runs and check-log passed; validate 195 files, 0 errors and 2 warnings (the two new forms files have no schema yet: Tools'); self-test 7545 of 7545; QA's run-all 7 of 7; the director's loader check passed; flash self-test 88 |

**Forms on, in live play** (`probe/forms_probe.gd`, a scratch probe, not a gate):
- **AI against AI**, four matches of 7,200 ticks, each played twice: the same hashes both times. The Protagonist took step I at 75 to 96 s in each.
  - The AI takes a ready step when it can, but the director takes a transform only between exchanges, so in a brawl the step waits. Its coil was 14 to 67 at the take, from damage traded while it waited.
  - So the AI throws slingshots without meaning to, until Encounter's holds and a rule on when a transform is taken land.
- **The slingshot by hand**, four seeds. He closes and trades lights, holds every ready step until his power reaches 65, then holds Transform:
  - one release took steps I to IV at once (tier 1 to 3), every time, with the rival at tier 2;
  - the coil was at its cap (100) every time, so the release added the surge (600 ticks), 3 armoured blows and the ×1.5 lasting gain;
  - the hold took about 3 minutes.

**For Game Design, from the probe:** at 1 coil point for every 20 damage traded, doubled a tier behind, a brawl fills the coil to its cap long before the third or fourth step comes. So every real slingshot is a full one. If the size of a release should mean something, `coil.perDamage` (0.05) may want to be nearer 0.005, or the cap reached only over minutes of fight time.

## Not in this build

Witness and Trial, the pick at II and IV and the branch extras; the AI's holds; spending the armour; World's and the planner's recovery reads; the schemas. All are in `../../forms-core.md` section 6.
