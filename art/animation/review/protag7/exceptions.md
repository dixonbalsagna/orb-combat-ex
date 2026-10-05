# Review: protag7

Machine pass over 24 poses (pm.): **0 errors, 0 for review, 17 notes.** Errors are fixed by the director before Orb sees anything; the rows under "For review" are what Orb sees (with the sheet); notes are logged and need nobody.

Match checks: not run (--no-match). Strike lab: 8 strikes measured at their own distances: 8 reach, 7 clear of the defender (clip 3.5 u or less).

## Notes (logged, no action needed)

| Source | Subject | Finding | Suggested action |
| :--- | :--- | :--- | :--- |
| pose_lint | pm.back_chop.contact | foot_r target [-6, 3, 9] is 3.2 units out of reach (the limb is clamped to [-4.0, 5.0, 8.7]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.back_chop.follow | hand_l target [18, 58, -6] is 4.7 units out of reach (the limb is clamped to [22.7, 57.8, -5.5]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.back_chop.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.palm_rise.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.palm_lift.contact | hand_r target [50, 80, 8] is 2.3 units out of reach (the limb is clamped to [48.0, 78.8, 8.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.palm_lift.contact | foot_r target [-6, 3, 9] is 1.7 units out of reach (the limb is clamped to [-5.0, 3.9, 8.8]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.palm_lift.contact | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.edge_crescent.follow | foot_r target [14, 28, 9] is 2.1 units out of reach (the limb is clamped to [14.6, 26.8, 10.6]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.edge_crescent.follow | right elbow at 152 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.edge_crescent.follow | right knee at 155 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.fist_chop.contact | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.fist_chop.follow | left elbow at 159 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.palm_heave.contact | left elbow at 159 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.palm_heave.follow | left elbow at 157 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| stacking_lint | brace | mark 1: a crouch with fists at the sides | fine alone; never in a moment that also has a scream, a flame aura, rising rubble, lightning, hair or a gold flash |
| stacking_lint | cue.brace | mark 1: a crouch with fists at the sides | fine alone; never in a moment that also has a scream, a flame aura, rising rubble, lightning, hair or a gold flash |
| strike_lab | knee_hook | a part that is not the striking limb touches the defender by 3.9 u (shin_l into shin_l) at 28 u | none needed unless it reads as a clip in the reel |
