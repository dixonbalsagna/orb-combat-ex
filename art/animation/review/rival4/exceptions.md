# Review: rival4

Machine pass over 45 poses (rm.): **0 errors, 0 for review, 37 notes.** Errors are fixed by the director before Orb sees anything; the rows under "For review" are what Orb sees (with the sheet); notes are logged and need nobody.

Match checks: not run (--no-match). Strike lab: 15 strikes measured at their own distances: 15 reach, 15 clear of the defender (clip 3.5 u or less).

## Notes (logged, no action needed)

| Source | Subject | Finding | Suggested action |
| :--- | :--- | :--- | :--- |
| pose_lint | rm.elbow_drop.chamber | hand_r target [6, 76, 8] is 2.0 units out of reach (the limb is clamped to [8.0, 76.0, 8.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.elbow_drop.follow | right elbow at 156 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.forearm_drop.chamber | hand_r target [16, 80, 10] is 1.5 units out of reach (the limb is clamped to [17.4, 79.6, 10.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.forearm_drop.contact | left elbow at 152 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.forearm_drop.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.fist_drop.contact | hand_l target [16, 56, -8] is 1.1 units out of reach (the limb is clamped to [15.9, 57.1, -8.1]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.fist_drop.follow | hand_r target [30, 63, 9] is 2.0 units out of reach (the limb is clamped to [31.5, 63.0, 9.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.fist_drop.follow | hand_l target [20, 56, -7] is 1.2 units out of reach (the limb is clamped to [20.0, 55.0, -5.5]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.fist_drop.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.short_uppercut.contact | hand_r target [50, 80, 8] is 1.8 units out of reach (the limb is clamped to [48.5, 79.0, 8.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.short_uppercut.contact | foot_r target [-6, 3, 9] is 1.7 units out of reach (the limb is clamped to [-5.0, 3.9, 8.8]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.short_uppercut.contact | left elbow at 159 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.arm_chop.contact | hand_l target [14, 56, -8] is 1.6 units out of reach (the limb is clamped to [13.0, 54.7, -8.1]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.arm_chop.contact | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.arm_chop.follow | left elbow at 155 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.fist_sweep.contact | foot_r target [-6, 3, 9] is 3.2 units out of reach (the limb is clamped to [-4.0, 5.0, 8.7]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.fist_sweep.follow | hand_l target [18, 58, -6] is 4.7 units out of reach (the limb is clamped to [22.7, 57.8, -5.5]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.fist_sweep.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.plate_drop.chamber | hand_r target [18, 80, 10] is 1.3 units out of reach (the limb is clamped to [19.1, 79.3, 10.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_drop.contact | hand_l target [18, 50, -8] is 3.8 units out of reach (the limb is clamped to [18.2, 53.6, -9.2]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_drop.follow | hand_l target [21, 53, -7] is 4.4 units out of reach (the limb is clamped to [24.9, 52.3, -6.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_drop.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.plate_drop.follow | right elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.low_thrust.contact | right elbow at 157 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.low_thrust.follow | right elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.gut_rise.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.plate_hammer.chamber | hand_r target [14, 83, 9] is 1.5 units out of reach (the limb is clamped to [15.3, 82.4, 9.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_hammer.contact | foot_r target [-6, 3, 9] is 2.4 units out of reach (the limb is clamped to [-4.4, 4.3, 8.7]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_hammer.follow | hand_r target [32, 67, 12] is 4.0 units out of reach (the limb is clamped to [35.5, 66.5, 11.5]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_hammer.follow | hand_l target [15, 58, -9] is 2.5 units out of reach (the limb is clamped to [12.6, 57.9, -8.2]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.plate_hammer.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | rm.heel_backhand.contact | hand_l target [12, 58, -8] is 3.2 units out of reach (the limb is clamped to [12.7, 60.9, -7.1]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.heel_backhand.contact | foot_r target [-6, 3, 9] is 3.7 units out of reach (the limb is clamped to [-3.5, 5.2, 8.6]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.heel_backhand.follow | hand_l target [18, 58, -6] is 4.7 units out of reach (the limb is clamped to [22.7, 57.8, -5.5]) | accept the clamped end (`fix-reach`) |
| pose_lint | rm.heel_backhand.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| stacking_lint | brace | mark 1: a crouch with fists at the sides | fine alone; never in a moment that also has a scream, a flame aura, rising rubble, lightning, hair or a gold flash |
| stacking_lint | cue.brace | mark 1: a crouch with fists at the sides | fine alone; never in a moment that also has a scream, a flame aura, rising rubble, lightning, hair or a gold flash |
