# Review: rival4

Machine pass over 39 poses (rm.): **0 errors, 0 for review, 38 notes.** Errors are fixed by the director before Orb sees anything; the rows under "For review" are what Orb sees (with the sheet); notes are logged and need nobody.

Match checks: not run (--no-match). Strike lab: 13 strikes measured at their own distances: 13 reach, 12 clear of the defender (clip 3.5 u or less).

## Notes (logged, no action needed)

| Source | Subject | Finding | Suggested action |
| :--- | :--- | :--- | :--- |
| pose_lint | rm.elbow_drop.chamber | hand_r target [6, 76, 8] is 2.0 units out of reach (the limb is clamped to [8.0, 76.0, 8.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.elbow_drop.follow | right elbow at 156 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.forearm_drop.chamber | hand_r target [16, 80, 10] is 1.5 units out of reach (the limb is clamped to [17.4, 79.6, 10.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.forearm_drop.contact | left elbow at 152 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.forearm_drop.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.fist_drop.contact | hand_l target [16, 56, -8] is 1.1 units out of reach (the limb is clamped to [15.9, 57.1, -8.1]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.fist_drop.follow | hand_r target [31, 66, 9] is 2.0 units out of reach (the limb is clamped to [32.5, 65.5, 9.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.fist_drop.follow | hand_l target [20, 56, -7] is 1.2 units out of reach (the limb is clamped to [20.0, 55.0, -5.5]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.fist_drop.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.gut_rise.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.collar_chop.contact | hand_l target [14, 56, -8] is 1.6 units out of reach (the limb is clamped to [12.4, 55.8, -8.4]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.collar_chop.contact | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.collar_chop.follow | left elbow at 156 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.elbow_thrust.contact | hand_l target [16, 56, -8] is 2.2 units out of reach (the limb is clamped to [15.6, 54.0, -7.3]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.elbow_thrust.contact | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.elbow_thrust.contact | right elbow at 156 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.elbow_thrust.follow | left elbow at 153 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.elbow_thrust.follow | right elbow at 156 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.plate_rise.contact | hand_r target [40, 80, 6] is 1.3 units out of reach (the limb is clamped to [41.1, 79.4, 6.1]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_rise.contact | foot_r target [-6, 3, 9] is 1.5 units out of reach (the limb is clamped to [-5.3, 3.8, 8.8]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_sweep.contact | hand_r target [48, 62, 14] is 4.0 units out of reach (the limb is clamped to [52.0, 62.0, 14.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_sweep.contact | foot_r target [-6, 3, 9] is 2.4 units out of reach (the limb is clamped to [-4.5, 4.3, 8.7]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_sweep.contact | left elbow at 153 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.plate_sweep.follow | hand_l target [18, 58, -6] is 4.7 units out of reach (the limb is clamped to [22.7, 57.8, -5.5]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_sweep.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.heel_stamp.chamber | right knee at 153 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.heel_stamp.contact | right elbow at 155 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.heel_stamp.follow | hand_r target [12, 58, 14] is 1.3 units out of reach (the limb is clamped to [12.3, 56.9, 14.6]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.heel_stamp.follow | right elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.rib_scythe.contact | hand_l target [16, 54, -6] is 1.0 units out of reach (the limb is clamped to [15.7, 55.0, -6.1]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.rib_scythe.follow | hand_l target [18, 58, -6] is 4.7 units out of reach (the limb is clamped to [22.7, 57.8, -5.5]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.rib_scythe.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.spear_rise.contact | hand_r target [50, 82, 8] is 2.6 units out of reach (the limb is clamped to [47.9, 80.5, 8.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.spear_rise.contact | foot_r target [-6, 3, 9] is 1.7 units out of reach (the limb is clamped to [-5.1, 3.9, 8.8]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.spear_rise.contact | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| stacking_lint | brace | mark 1: a crouch with fists at the sides | fine alone; never in a moment that also has a scream, a flame aura, rising rubble, lightning, hair or a gold flash |
| stacking_lint | cue.brace | mark 1: a crouch with fists at the sides | fine alone; never in a moment that also has a scream, a flame aura, rising rubble, lightning, hair or a gold flash |
| strike_lab | hook_knee | a part that is not the striking limb touches the defender by 3.9 u (hand_r into forearm_r) at 28 u | none needed unless it reads as a clip in the reel |
