# rival4: the reach table

Measured by `strike_lab.gd --measure --sweep`: each strike played against a dummy defender at every distance from 20 to 98 u. **Hips alone** is the farthest distance the blow lands at with the pose's own lunge and no step-in; **with step-in** adds the contact solve's whole-body slide (the limb's `step_max` or the key set's). **Clear from** is the nearest distance at which no other part of the body passes more than 6 u into the defender. Combat's rule (docs/combat/pending/wave1-strikes.md section 3) is that a strike's contact distance is its reach minus the step, so the blow lands with the hip lunge alone: the verdict column checks it.

| Strike | Combat contact | Combat reach | Hips alone | With step-in | Clear from | Verdict |
| :--- | ---: | ---: | ---: | ---: | ---: | :--- |
| elbow_drop | 38 | 72 | 52 | 72 | 30 | lands on the hips alone |
| forearm_drop | 56 | 86 | 74 | 96 | 36 | lands on the hips alone |
| fist_drop | 56 | 86 | 66 | 86 | 40 | lands on the hips alone |
| short_uppercut | 58 | 98 | 72 | 92 | 34 | lands on the hips alone |
| knee_lift | 28 | 48 | 34 | 54 | 22 | lands on the hips alone |
| arm_chop | 58 | 98 | 72 | 92 | 34 | lands on the hips alone |
| lift_kick | 54 | 82 | 60 | 80 | 24 | lands on the hips alone |
| fist_sweep | 58 | 98 | 72 | 88 | 40 | lands on the hips alone |
| plate_drop | 56 | 86 | 82 | 98 | 46 | lands on the hips alone |
| low_thrust | 50 | 76 | 58 | 78 | 30 | lands on the hips alone |
| gut_rise | 54 | 98 | 76 | 98 | 38 | lands on the hips alone |
| plate_hammer | 56 | 86 | 68 | 94 | 40 | lands on the hips alone |
| knee_hook | 28 | 48 | 36 | 54 | 24 | lands on the hips alone |
| fist_rise | 58 | 98 | 70 | 98 | 44 | lands on the hips alone |
| heel_backhand | 58 | 88 | 64 | 92 | 42 | lands on the hips alone |
