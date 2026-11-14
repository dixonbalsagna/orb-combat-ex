# The stick push in a beam struggle, and the beam's six rungs (Controls, 2026-11-07; for Encounter, Rendering and UI)

Two changes for the morning build, from the EP's brief: Encounter's push mode (`docs/director/pending/push-mode/`, Game Design's `playable-build.md` section 3) makes the right stick's flick toward the foe the default push in a beam struggle, and the charge rumble's rungs meet Encounter's six stages. The park is `docs/controls/pending/push-stick/`.

## 1. The stick, read in a struggle (when the player's push mode is the stick)

Before: in a struggle the layout made the strike stick inert (`layout.gd` `in_struggle`): a started strike was cancelled, the stick was ignored, the faces were free. Now the host says a second word, `push`, and with it the stick is read **as in any strike**.

| | |
| :--- | :--- |
| **The word** | `hub.set_struggle(slot, on, push)`; `push` is `DirBeam.pushModeOf(S, fighter) == "stick"` (the host's one line, `host-push.patch`). That function is `"face"` with Encounter's `pushMode.enabled` off, so nothing changes until it is on. A call with two arguments (the old one) is face mode |
| **What reaches the director** | A flick is a request edge: `rsStart` with `rsDir` (the quadrant, 45° each side of the axis) on the tick the settle ends, 2 ticks after the stick crosses the request line (1 with quickRead). Encounter's `_stickPush` turns `rsDir` toward the rival into a surge and away into the let-go; up and down are nothing. Test A checks the edge lands 0 to 3 ticks after the crossing, inside the surge window of 4 (and the sharp window of 2 when the flick is on the beat) |
| **One edge a flick** | The reader's own rule: the stick has to come back under the release line (0.35) before the next request counts. Held out, scrubbed between the lines (0.55 here) or mashed without resting, it is one edge (test B) |
| **A charge in hand** | The struggle's **first** tick lets go of a strike the stick had started (a `rsCancel` edge, no throw) and the stick must rest before a flick counts (test C). So the thumb still out from the fire-back that began the clash does nothing until it comes home |
| **The struggle's last tick** | Likewise: a flick still going is let go of (`rsCancel`), so no strike crosses from the struggle into the fight (test C) |
| **The faces** | Still free at once, no queue, as in face mode. **A face press just before a flick does not delay it** (no reverse lockout in a stick-push struggle, test D). The director gives the faces no meaning in stick mode (Encounter's `push_mode_check`), so a press is neither a surge nor a stray |
| **The layer and B** | A stick-push struggle reads the stick whatever stance layer is on and with B held (nothing else counts there), where outside it a held B or an inert layer silences the stick |
| **Stall-keep** | A flick that came and went between two builds is still kept as an edge (the peak's rule), so a push is not lost to a frame stall |
| **Mirrors** | The D-pad mirror and the keyboard's strike arrows are the same stick (the reader takes their vector), so toward on the D-pad on the beat pushes too |
| **No "no answer"** | A flick in a stick-push struggle is the push, never a request the director could leave unanswered, so the hub neither times it out into a `no_answer` refusal nor knocks the pad (test F). A flick outside a struggle is as before |
| **Face mode, unchanged** | With no `push` word the stick is inert in a struggle exactly as before (test E), and outside a struggle the word is nothing |

### Proof
- `push_stick_test.gd` (34 checks, new): A direction (right, left, up, each with its direction), B one edge per flick and a second after a rest, C the first and last tick, D the faces, E face mode and the word's scope, F the hub's refusal and knock, G the ladder.
- `sim/input/tools/push_stick_probe.gd` (in `host-push.patch`, needs Encounter's stack): a **scripted pad through the hub, the layout and the director's real `clashTick`**. The rival's signature opens the pad's window, the pad fires back with RB + stick, the clash begins, and each pulse the pad flicks toward: 3 surges, 0 strays, 0 `stick_start`, 0 refusals and 0 knocks, the cue `push_mode` stick. The same pad on face mode: its X on a beat is a surge. **Negative control:** with the host's push word off the same run gets 0 surges, so the probe does catch the old inert stick.

## 2. The beam's six rungs

`strike.beamLevels` is **[12, 28, 46, 66, 90, 120]** (Encounter's stages, `beam-move`: stage s at those live ticks). Before it was [12, 30, 54].
- The reader takes 3 to 6 rungs (a list outside that is refused and the default stands, test G); the martial ladder (`levels`, 12/30/50) is as it was.
- **The intent's `rsLevel` is still 0 to 3** (two bits on the wire; `SimStrikeRead.LEVEL_MAX`): a beam held for 130 ticks is held and thrown at level 3. The reader's `level_at(held, true)` runs to 6, which the director reads where it wants the count (`stick.gd` 606's plain right-stick charge, which only tests it for zero).
- **What the pad now does:** the three pulses (a tick, a knock, a thud) fall at **12, 28 and 46 ticks**, stages 1 to 3, instead of 12, 30, 54 (test G, through the hub). A base fighter (two stages, the second at 28) gets its knock exactly at its top stage; its thud at 46 promises a third stage it does not have.
- **Stages 4 to 6 are the next park, `stage-pulses` (`docs/controls/stage-pulses.md`): the pad is told every stage from Encounter's `stick_stage` cue. What follows is push-stick alone:** stages 4 to 6 (66, 90, 120) still have no pulse. The pad's ladder is the intent's three rungs. `SimHaptics.stage_requests(slot, n, of)` is written for it (the stage `n` of `of`, a climbing knock and the thud on the last) and wants the host to call it on Encounter's `stick_stage` cue; Audio's last commit ("charge stages climbing") may already be doing the sound side. Say if you want Controls to take the pad side (it is a host call plus a hub switch to skip the three rungs on a beam hold).
- Tests that fixed 12/30/54 now say 12/28/46 (`strike_read_test`, `stick_feel_test`).

## What the host and the others do
- **Rendering (a grant, `render/core/sim_host.gd`, one line):** `hub.set_struggle(k, SimDir.inStruggle(S, S.fighters[k]), DirBeam.pushModeOf(S, S.fighters[k]) == "stick")`. It needs Encounter's push-mode applied (it names `DirBeam.pushModeOf`), so it is a separate patch that goes in with it.
- **Encounter:** nothing; `_stickPush` already reads `rsStart` and `rsDir`. Their `_start` guard drops a stick start in a stick-push clash, as their check expects.
- **Tools:** the page's `pushMode` switch (theirs) does the rest. No new switch of Controls': the push is on when the director's `pushMode.enabled` is and the player's mode is the stick.
- **UI:** the option and the teaching; nothing of Controls' to change. The cue `push_mode` carries the mode.

## Open
- A thumb test of the push on a real pad (the 2-tick settle is the latency; `settleQuick` 1 under `quickRead`, on in the switches-on patch). If the push feels late, a struggle could read at settle 0 (the direction taken on the crossing tick); I have not built it.
- Stages 4 to 6 on the pad (above).
- Whether the left stick's D-pad mirror should push in a stick-push struggle with the D-pad also moving the fighter: it does today (the same vector), and the fighter is pinned in a struggle, so I have left it.
