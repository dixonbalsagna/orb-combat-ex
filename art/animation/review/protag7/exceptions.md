# Review: protag7

Machine pass over 24 poses (pm.): **0 errors, 0 for review, 21 notes.** Errors are fixed by the director before Orb sees anything; the rows under "For review" are what Orb sees (with the sheet); notes are logged and need nobody.

Match checks: not run (--no-match). Strike lab: 8 strikes measured at their own distances: 8 reach, 7 clear of the defender (clip 3.5 u or less).

## Notes (logged, no action needed)

| Source | Subject | Finding | Suggested action |
| :--- | :--- | :--- | :--- |
| pose_lint | pm.elbow_drop.chamber | hand_r target [6, 78, 8] is 2.0 units out of reach (the limb is clamped to [8.0, 78.0, 8.0]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.elbow_drop.follow | right elbow at 156 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.palm_slap.contact | foot_r target [-6, 3, 9] is 2.4 units out of reach (the limb is clamped to [-4.5, 4.3, 8.7]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.palm_slap.follow | hand_l target [18, 58, -6] is 4.7 units out of reach (the limb is clamped to [22.7, 57.8, -5.5]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.palm_slap.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.palm_drop.contact | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.palm_drop.follow | left elbow at 159 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.blade_back.contact | foot_r target [-6, 3, 9] is 3.2 units out of reach (the limb is clamped to [-4.0, 5.0, 8.7]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.blade_back.follow | hand_l target [18, 58, -6] is 4.7 units out of reach (the limb is clamped to [22.7, 57.8, -5.5]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.blade_back.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.palm_rise.follow | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.edge_crescent.follow | foot_r target [14, 28, 9] is 2.1 units out of reach (the limb is clamped to [14.6, 26.8, 10.6]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.edge_crescent.follow | right elbow at 152 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.edge_crescent.follow | right knee at 155 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.elbow_back.contact | hand_l target [14, 58, -8] is 3.7 units out of reach (the limb is clamped to [16.1, 55.4, -6.4]) | accept the clamped end (`fix-reach`) |
| pose_lint | pm.elbow_back.contact | left elbow at 160 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.elbow_back.follow | left elbow at 157 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| pose_lint | pm.elbow_back.follow | right elbow at 156 degrees | the runtime limb pass trims the fold to 150 degrees, so the pose shows less than authored; relax it if the full fold is meant |
| stacking_lint | brace | mark 1: a crouch with fists at the sides | fine alone; never in a moment that also has a scream, a flame aura, rising rubble, lightning, hair or a gold flash |
| stacking_lint | cue.brace | mark 1: a crouch with fists at the sides | fine alone; never in a moment that also has a scream, a flame aura, rising rubble, lightning, hair or a gold flash |
| strike_lab | knee_hook | a part that is not the striking limb touches the defender by 3.9 u (shin_l into shin_l) at 28 u | none needed unless it reads as a clip in the reel |
