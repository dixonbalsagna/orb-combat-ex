# The beam struggle's framing, and the opening (Camera, 2026-10-16)

Owner: Camera and Cinematography. Item 5 of the EP's message of 2026-10-16: "the eleventh round's struggle framing on `Clash.mid` and Encounter's five beam cues, and the opening's framing". Built in scratch on Encounter's park (`docs/director/pending/beam-struggle/`, `bs.cjs` and the two grants) over HEAD ee822c5e; the camera side is in the tree behind a switch and does nothing without the park (`S.game.clash.get("mid")` is null on a tree without Simulation's field).

## 1. The beam struggle

**What the picture needs.** The struggle is a tug of war on the pulse (Game Design: the point starts in the middle, 15 pulses 20 ticks apart, a surge moves it 10% toward the rival, 15% on the beat, a stray 5% back, the end at a fighter, on time or a detonation). The viewer has to see both fighters, the beams, and where the point is; the camera has to give the decision weight without moving the picture much (the scene is already two beams, a glare and a crater forming).

**Switch:** `SplitView.set_struggle_framing(on)` (`SplitRig.struggle_framing`, build-time, default off). Reduced motion: none of it. Reduce flashing: half the tightening and no punches.

| Cue or field | What the camera does |
| :--- | :--- |
| `S.game.clash.mid` (0 at the attacker's hands, 1 at the defender's) | the shared view's focus leans toward the meeting point by STRUGGLE_FOCUS (0.5) of its offset from the pair's middle, the point eased with a 0.3 s time constant (a surge jumps it 10 to 15% of the line); the lean is capped so both fighters stay inside 0.42 of the width (a fighter lost off the edge of the one view opens the split: my first build did that) |
| the same, as a distance from the middle | the view tightens by up to 10% as the point nears a fighter (the decision is near), by up to 4% more over the last 40% of the struggle's time; capped so both fighters stay inside 0.44 of the width |
| `beam_struggle` (start, `n` the tick it ends by at the latest) | starts the clock of the time tightening |
| `beam_surge` (`surge` or `sharp`) | a 6-tick punch of the zoom, 2% or 3.5%: the beat, seen (not under Reduce flashing) |
| `beam_end` (`detonate`) | the shared view pulls out for 0.7 s (the crater is the picture) |
| `beam_end` (`overwhelmed`) | nothing of its own: the loser is launched along the beam's line and the launch follow takes him |
| `beam_pulse`, `beam_stray` | nothing: the beat and the stray are UI's and Audio's to show; a pulse every 20 ticks is not a camera move |
| the end of the struggle | all of it fades out over 0.4 s (no step: the first build stepped the focus 55 units the tick the clash ended) |

**Measured.**
- `split_sweep` rows "beam struggle framing off / on" (a stand-in clash with the point driven from the middle to 0.9 and back over 240 ticks, then no clash): with it on the focus leans 125 units for a pair 800 apart, the worst camera travel is 0.0047 of the width a tick (0.0041 with it off), both fighters on the screen at every tick; off, nothing moves.
- `clip_probe.gd --scenario=clash --sweepmid --struggle`: the same through the real scene: worst travel 0.0103, no tick over 0.03.
- **Flash** (scratch export of the park over HEAD, Tools' path, 1,024 x 768, primary / area -15% / 2 s memory), the `clash` scenario (both human, the signature every 30 ticks): ordinary, switch off 1 / 1 / 1, on 1 / 1 / 1; reduced, off 1 / 1 / 1, on 1 / 1 / 1, all PASS. The `collapse` clip on the same export with the switch on: 1.5 / 2 / 0.5 and, reduced, 2 / 2.5 / 1, PASS.

**What I could not show.** In the probe's two-human clash the scripted presses (a sharp surge a tick after each pulse, the other side three ticks late) produced surge and stray cues but the sim's `mid` stayed at 0.58 for the whole struggle, so the real point never moved there; the framing's response to a moving point is measured with the point driven. Whether the park's `mid` moves under real presses is Encounter's read (their bs1 probe says it does).

**Honest size of the effect.** The shared view is already fitted to the pair, so the lean is limited to what the margins allow (125 units on an 800 gap) and the tightening is small at the fit. It reads as a gentle lean toward the winner's side, a beat on each surge and a pull-out on a detonation, not a different shot. A larger move (a crop onto the point and the loser) means letting the winner leave the frame, which opens the split; I have not built that.

## 2. The opening's framing

`render/camera/tests/intro_probe.gd` plays the opening through the real scene (the host's intro record; eight seeds; AI against AI and one human with the split off):
- Two lengths came up, 299 and 419 ticks. Seven hard cuts, as the plan. One fighter at a time by design: each grounded fighter is off the picture for one 60-tick shot and one 24-tick shot, 108 ticks in all; never under 71 px tall.
- **The descent is a fast pan**: the camera falls with the faller, so over the last 25 ticks of a fall the picture changes 0.06 to 0.29 of the width a tick (the fight's bound is 0.045). It is the designed shot (rule-of-cool-shots.md row 7, sky that becomes ground). Smooth until the ground comes up in the last ten ticks. If the opening becomes the default, Tools' pixel gate should read it.
- **The known gap with the split off** (the camera loses the fighter on the ground in the longest opening) does not reproduce at this build: with one human and the split off the numbers equal the AI's.
- `varied-intros.md` is the proposal for varying the opening.

## 3. Files

`render/camera/split_rig.gd`, `camera_params.gd`, `split_view.gd`; `render/camera/tests/split_sweep.gd` (the rows), `clip_probe.gd` (the `clash` scenario with `--surges`, `--sweepmid`, `--struggle`), `intro_probe.gd` (new).
