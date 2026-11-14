# stray-beams-input (park, on HEAD 51b840f5 plus Encounter's stray-beams): A-CONTROLS-06 acceptance item 6

Controls, 2026-11-14. Input tests, through the real hub, for the two stray beams of Orb's 9 November play: RT + B at the last tick of its window and one tick after, and a stick beam let go of that cannot start. Records: `docs/controls/runs/51b840f5/stray-beams-input-test.txt` (CD-22).

## Apply

After Encounter's `docs/director/pending/stray-beams/` (`stray-beams.diff`, `grant-tools-schema.patch`): `git -c core.autocrlf=false -c core.eol=lf apply docs/controls/pending/stray-beams-input/stray-beams-input.patch`. Two new files in Controls' path: `sim/input/test/stray_beams_input_test.gd` (+ `.uid`). No existing file changes, no switch, no schema. It pins its own switches, so it does not depend on the pad group.

## What it checks (12)

- RT, then B 0, 1 and 11 ticks later: the signature (11 is the last tick of the window from a pad). B 12 and 13 ticks later: the heavy, no beam.
- Orb's 6617: RT, a blow (a brawl begins), B 26 ticks after RT with RT still held: the heavy, no beam.
- A stage 1 stick hold let go while its target is held waits; a Y pressed 8 ticks after the release drops it (`stick_refused beam replaced`), no beam comes; with nothing pressed it fires once the target is free; with `dropOnPress` off the Y drops nothing.

## Tested

12 of 12 pass with Encounter's patch; **control** (the same tree without it): the three rows marked (fix) fail (Orb's 6617 still a signature, a late beam after the Y). The whole input suite, 46 scripts including this one, passes on pad group + stray-beams (`b_no_beam_test` 103 and the layouts scan included, so Encounter's `isB` change does not move my switches' tests). Lint ok; the patches apply in sequence on a clean `git archive` of HEAD.

## A finding for Encounter (no action needed to land)

A pad cannot reach the window's last tick as Encounter's check counts it. The layout turns RT into a charge on its 12th tick (`tapHold.holdStart` 12: the intent's `charge` bit is on at tick 11 from the press), so **from a pad B pressed 12 ticks after RT is already the heavy, and 11 is the last signature tick**. Encounter's own rows feed intents with no `charge` bit and count to 12. Both read "within 12 ticks"; the pad's window is 0 to 11. The old rule behaves the same at 12 (the channel has begun). Worth one line in the stray-beams README so a reader does not expect 12.

## Feel note (Controls, for the report)

With `dropOnPress` on, a stick beam that was refused for the moment (its target not free) and is then followed by any other press (a face button, a guard, a dodge, RT, a new stick strike) is dropped with the word "Replaced" instead of firing up to 90 ticks later into whatever the player is doing. So beams are refused **more often by count** than in the 9 November build, and each refusal says so; a beam with nothing pressed after it fires as before. If Orb mashes after a release, he will see "Replaced" where he saw a late beam.
