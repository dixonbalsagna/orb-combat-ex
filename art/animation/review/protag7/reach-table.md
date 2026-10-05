# protag7: the reach table

Measured by `strike_lab.gd --measure --sweep`: each strike played against a dummy defender at every distance from 20 to 98 u. **Hips alone** is the farthest distance the blow lands at with the pose's own lunge and no step-in; **with step-in** adds the contact solve's whole-body slide (the limb's `step_max` or the key set's). **Clear from** is the nearest distance at which no other part of the body passes more than 6 u into the defender. Combat's rule (docs/combat/pending/wave1-strikes.md section 3) is that a strike's contact distance is its reach minus the step, so the blow lands with the hip lunge alone: the verdict column checks it.

| Strike | Combat contact | Combat reach | Hips alone | With step-in | Clear from | Verdict |
| :--- | ---: | ---: | ---: | ---: | ---: | :--- |
| knee_hook | 28 | 48 | 36 | 54 | 26 | lands on the hips alone |
| back_chop | 58 | 88 | 72 | 88 | 40 | lands on the hips alone |
| palm_rise | 54 | 98 | 74 | 98 | 34 | lands on the hips alone |
| palm_lift | 58 | 98 | 72 | 92 | 34 | lands on the hips alone |
| lift_kick | 54 | 82 | 60 | 78 | 24 | lands on the hips alone |
| edge_crescent | 50 | 72 | 64 | 78 | 34 | lands on the hips alone |
| fist_chop | 56 | 86 | 72 | 92 | 34 | lands on the hips alone |
| palm_heave | 58 | 98 | 74 | 96 | 34 | lands on the hips alone |
