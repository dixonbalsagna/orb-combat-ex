# The camera director at high velocity: what's built (Camera, 2026-11-01)

Orb: "keep refining our camera director so any high stakes, high velocity situation is handled smoothly". Why each piece: `launch-cinematography.md`. Park: `pending/swing/swing-7-director.patch`, after swing 1 to 6. **`SplitRig.launch_director`, off byte-identical, on with `tiles`.** View only.

**How far to trust this.** The check is measured, on the real rig with a gen 3 planet. Most launches in it are staged, because no rule in the sim earns them yet; the fights are real AI fights. Limits are first values I set after seeing the numbers. **Nobody has watched these clips but me, as stills.** Flash isn't read: backburner, public check later.

## The test: `render/camera/tests/launch_shots_check.gd`

Every shot, every tick, through the real rig. It fails on:

| Fault | Measure | Limit |
| :--- | :--- | :--- |
| **A jolt** | The picture's step changing in a tick, of the width | 0.06. 0.16 past the eye's ceiling: flat sends of 10,800 u/s and up, and real fights. **Those two are looser because I couldn't soften them further** |
| A blow's release | The same, in the 10 ticks round a launch's start or end: the blow hides the start, as a cut on action does | 0.30 |
| **A zoom jolt** | The zoom's step changing in a tick, log units | 0.012; 0.03 on a release |
| **A lost subject** | The shot's subject off the frame in a run | 50 ticks: a launch's climb, on Research's reading |
| **An unjustified cut** | A cut with no key in `CamParams.CUT_REASONS` | None |

The slam and the catch-up whip are named moves, 12 eased frames (`director.md` section 11), and aren't scored as jolts.

## What it found, and what's built

| Shot | Before: jolt, zoom | After: jolt, zoom | Lost run |
| :--- | :--- | :--- | :--- |
| Tier 2 up | 0.028, 0.025 | 0.005, 0.006 | 0 |
| Tier 3 up | 0.028, 0.025 | 0.016, 0.003 | 0 |
| Tier 4 up | 0.050, 0.025 | 0.027, 0.002 | 0 |
| Meteor, Game Design's curve | 0.020, 0.025 | 0.026, 0.004 | 43, unchanged |
| Flat 5,000 | 0.026, 0.006 | 0.006, 0.002 | 0 |
| Flat 10,800 | 0.097, 0.006 | 0.098, 0.002 | 0 |
| Flat 26,700 | 0.259, 0.0003 | 0.155, 0.0004 | 0 |
| Through a tower | 0.078, 0.008 | 0.043, 0.007 | 0 |
| Flat-out chase | not comparable: the first measure was on a harsher stage | 0.007, 0.008 | 5 |
| AI fights, DirSwing on, 4 of them | | At most 0.137, 0.012 | At most 3 |

A jolt read in the last row is for all ticks but a release; a first measure of a tiles-only fight read up to 0.150 and 0.020 off.

1. **Every cut names its reason.** Every cut site goes through `_mark_cut(why)`, and `CUT_REASONS` says why in words. In real fights the cuts are `side_swap`, `insert` and `rush_pin`.
2. **The zoom's own ease (`_zoom_ease`, `ZOOM_ACC`).** The biggest finding: the zoom's rate caps were clamps, so a zoom started at full rate in one tick. Its step now changes by at most 0.004 a tick, and it brakes to rest.
3. **The softest catch that never loses him (`_soft_catch`, `SPEED_*`).** The camera's velocity heads for his, plus a pull on what it has fallen behind, changing by the least that keeps him inside 0.35 of the width. It runs until it has settled, so it doesn't hand back all at once when he stops. **It helps from 5,000 to about 7,000 u/s, and little past 10,000.** At 10,800 a camera can't catch him softly at fight size: that's the limit `director.md` section 5 predicted.
4. **Research's two descent changes,** with my amendment. The frame's centre passes from the pair to just short of where he's going as the width stops holding both, in place of a clamp that started dead. Width over height has a 1.25 margin, and also holds his sideways lead. **The focus pass is why the "before" and "after" differ on the descent in the clip.**

## Not built, and why

| Item | State |
| :--- | :--- |
| **Three-beat focus on ordinary low launches** | Tiers 2 and up going upward now have it, through the peak shot. Flat sends don't |
| **Hold a still frame and let him leave, as a chosen shot** | I tried `launch_hold` everywhere: jolts fell and it lost the subject for 56 to 396 ticks, and stalled then jumped. It needs a rule for when, and that rule needs Orb's eye. Not in the patch |
| **Film's foreground on a low flight** | Rendering's. Reveal and overshoot are built: below |
| **Which flat shot** | Built both ways, below. Default wide. Orb's eye picks |

## Parks 8 to 11: four more moves (2026-11-01)

Each is its own patch and switch, all on with `tiles`.

| Park | What you see | Numbers |
| :--- | :--- | :--- |
| **8, flat sends** (`flat_mode`; the page word `flat=wide` or `flat=hold`) | A flat send past 10,000 units a second can't be followed softly at fight size. **Wide:** the frame rides after him, lets go, and pulls wide. **Hold:** the frame stays still 0.4 s as he leaves, then the same pull. | Fighter out of frame 17 to 28 ticks wide, 47 to 55 hold. Frame's step at most 0.06 of the width a tick. `img/launch-director/flat-wide-vs-hold.gif` is for Orb's eye |
| **9, reveal** (`flight_reveal`) | A flight at 3,000 units a second or more, for a second, opens out in its middle: low, wide, low. At most one every 8 s. | Out over 1 s, held 0.5 s, back over 1 s. Up to 8,000 units wide with both at power 3 or more, else the size floor |
| **10, overshoot** (`follow_through`) | When a fast body stops dead, the frame's mass carries on a little and comes back. | At most 0.02 of the width, from 3,000 units a second |
| **11, close brawl** (`close_brawl`) | Two locked fighters within 300 units frame closer, as Orb asked for at base power. Eases in over 0.7 s, out over 0.35 s. | 0.17 of the screen's height, against the fight's 0.12 and the cap's 0.14 |

**A bug found by the real-fight gate, in the reveal.** It opened on a fighter whose pane wasn't on the screen, so the other pane took a jolt of 0.161 and lost its subject for 26 ticks. It now doesn't start or carry on while the other pane has the screen. The same fight now reads 0.028, and 3 ticks lost.

**Not done:** no one has looked at a close-brawl clip. The first was filmed where no locked brawl happens, and the next was stopped at the pause. Seed 12345 from tick 1500 has a real one.

## Checks

- Off: `clip_digest` (48,600 lines) and `split_sweep` identical to swing 1 to 6; `determinism`, `flight_check`, `seam_sweep`, `pane_check`, `sky_check`, `depth_check` pass.
- On: `launch_shots_check` 549 pass, and with DirSwing on, 4 AI fights, 564 pass. With all of 8 to 11 on and DirSwing on, 4 AI fights over 3,600 ticks: 553 pass. `swing_real_check`, `swing_shot_check`, `peak_shot_check`, `swing_places_check` pass.

## Clips, before on the left, after on the right

`img/launch-director/launch.gif` (staged launch with a real `SimSwing` turn), `meteor.gif` (Game Design's curve written by a scratch hook; it isn't in the sim yet), `fight.gif` (a real AI fight, DirSwing on). The presses and the swing are at the frame's edge; the small corner square is a search mark. **Trail, rig poses and crater slant aren't final, and today's HUD is on.**
