# Forms: the Protagonist's five steps and the slingshot (parked build, ready to apply)

Owner: Simulation and Engine. 2026-10-17. The build of `../../forms-core.md` (Game Design's `docs/design/hero-forms.md` sections 4 and 4b, with the coil as re-ruled in edd7dcd8, and Narrative's hold and release signals). **Built and proved in scratch; nothing is in the tree.** Behind `data/fight/forms.json` `enabled` (false): with it off, every match, replay and checkpoint is the same to the bit.

## To apply

From the repo root, in this order, then an import (`SimForms` is a new class):

1. `python docs/architecture/pending/forms/forms.py .` (Simulation's files: the module, the two data files, the core's hooks, the check, the three events in `fx-events.md`).
2. `python docs/architecture/pending/forms/grant_encounter.py .` (four lines in Encounter's `sim/director/`: **granted by Encounter**, 2026-10-17).

It applies before or after `../brake/brake.py`.

| File | Change |
| :--- | :--- |
| NEW `sim/core/forms.gd` | `SimForms`: the data, the steps and the coil (its start at the first break, `canTake`), the release, the hold's signal, the gains |
| NEW `data/fight/forms.json` | The switch (off) and the hold's signal (60 ticks) |
| NEW `data/fighters/PROTAGONIST/forms.json` | His five steps, gains, coil (0.5 a second, 0.005 a point traded, ×2 behind), patience and release |
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
| Granted: `sim/director/exchange.gd`, `data.gd`, `launch.gd` | The transform event's tier; the speed estimate; the launch planner's and doLaunch's tier factor |

## Proof (scratch, below-normal priority, one Godot job at a time but for the probes)

| Run | Base | Result |
| :--- | :--- | :--- |
| `forms.py` and the grant | HEAD ff68e994 | Import clean. Parity on the committed golden, unregenerated, **61 of 61**, no script error, the new check among them. The golden regenerated **byte-identical** |
| With `../brake/` and World's brake function, all four together | HEAD ff68e994 | Parity **62 of 62**, the golden byte-identical, the full gates and **all 15 of Rendering's checks** passed (`../brake/README.md` has the list) |

**The check** adds the coil's start: a step that comes ready inside an exchange coils nothing, and its coil starts at the break.

**Forms on, in live play** (`probe/forms_probe.gd`, a scratch probe, not a gate):
- **AI against AI:** four matches of 7,200 ticks, each played twice, gave the same hashes both times. **Every release was at a coil of 0 to 0.01.** The AI takes its step at the first break, so it no longer throws slingshots by accident. Before the ruling, its coils were 14 to 67.
- **The slingshot by hand:** four seeds. He closes and trades lights, holds every ready step until power 65, then holds Transform.
  - One release took steps I to IV every time, tier 1 to 3, with the rival at tier 2.
  - **From the coil's start to 100: 85, 94, 98 and 101 s** (the rival above him for 56 to 71% of it). Game Design's row is a median of 60 to 100 s while the opponent is above; the median here is 96 s.
  - The release had the full extras: the surge, 3 armoured blows and the ×1.5 lasting gain.

## Not in this build

Witness and Trial, the pick at II and IV and the branch extras; the AI's holds; spending the armour; World's and the planner's recovery reads; the schemas (Tools). See `../../forms-core.md` section 6.
