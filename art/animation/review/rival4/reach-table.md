# rival4: the reach table

Measured by `strike_lab.gd --measure --sweep`: each strike played against a dummy defender at every distance from 20 to 98 u. **Hips alone** is the farthest distance the blow lands at with the pose's own lunge and no step-in; **with step-in** adds the contact solve's whole-body slide (the limb's `step_max` or the key set's). **Clear from** is the nearest distance at which no other part of the body passes more than 6 u into the defender. Combat's rule (docs/combat/pending/wave1-strikes.md section 3) is that a strike's contact distance is its reach minus the step, so the blow lands with the hip lunge alone: the verdict column checks it.

| Strike | Combat contact | Combat reach | Hips alone | With step-in | Clear from | Verdict |
| :--- | ---: | ---: | ---: | ---: | ---: | :--- |
| elbow_drop | 38 | 72 | 52 | 72 | 30 | lands on the hips alone |
| forearm_drop | 56 | 86 | 74 | 96 | 36 | lands on the hips alone |
| fist_drop | 56 | 86 | 66 | 86 | 40 | lands on the hips alone |
| gut_rise | 54 | 98 | 76 | 98 | 36 | lands on the hips alone |
| collar_chop | 58 | 98 | 76 | 96 | 34 | lands on the hips alone |
| elbow_thrust | 38 | 64 | 56 | 78 | 34 | lands on the hips alone |
| hook_knee | 28 | 48 | 34 | 54 | 20 | lands on the hips alone |
| plate_rise | 38 | 64 | 68 | 88 | 28 | lands on the hips alone |
| plate_sweep | 58 | 98 | 86 | 98 | 40 | lands on the hips alone |
| heel_stamp | 50 | 76 | 50 | 70 | 30 | lands on the hips alone |
| rib_scythe | 58 | 98 | 84 | 98 | 40 | lands on the hips alone |
| spear_rise | 58 | 98 | 72 | 92 | 34 | lands on the hips alone |
| fist_rise | 58 | 98 | 70 | 98 | 42 | lands on the hips alone |
