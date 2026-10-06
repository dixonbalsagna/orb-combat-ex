# Framing the zip (a plan against Encounter's final cue names; no code until its commit)

Owner: Camera & Cinematography. Date: 2026-10-05. **A note only.** It replaces the guesses in `lunge-framing.md` sections 8 and 9 (the out-and-back hold and the far-side exit) with the real cues. Sources: Encounter's zip slice as the EP described it, `docs/design/melee-press-feel.md` section 2c (the zip), `lunge-framing.md`, `camera-v2.md` section 3 (who the camera follows on a launch), `split-screen.md` sections 21d and 22b.

## 1. The cues, and what the rig reads from each

| Cue | When | Fields the rig uses | What it does |
| :--- | :--- | :--- | :--- |
| `zip_light`, `zip_heavy` | The tell starts | `actor`, `target`, `amount` (the tell's ticks), `n` (the way in), `dur` (the whole zip with the default exit) | Starts the hold (section 2). The hold's length until a `zip_end` is `dur` plus a margin, never over 2.2 s. The rival's incoming read is `aimed` from here, with `eta` to the blow (tell + way in) |
| `zip_out` | The tick the blow lands (6 or 10 ticks before the way out begins) | `text` (`home`, `far`, `point`), `x`, `y` (the exit point), `n` (the out's ticks) | Pre-frames the exit (section 3): the zoom and focus are put where the pair will be, in the 6 to 22 ticks the zipper spends in reach |
| `zip_end` | Every zip | `text`: `done`, `stopped`, `outrun`, `countered`, `caught`, `shot`, `down` | The return marker. The hold ends 0.4 s after a `done` (the zipper is home or at his exit) and at once for every other text (section 6) |
| `drop_start`, `drop_land`, `drop_end` | A zipper knocked out of his way out by a shot, 24 ticks | `actor` | The hold ends at `drop_start`; the dropped fighter is framed as any falling fighter (section 5) |
| `brawl_start` (texts `caught`, `countered`) | The tick a caught or countered zipper starts a brawl | | The hold ends; the brawl's own framing takes over (the pair is in the close band: the one view as now) |

The rig also reads the path itself, as a view-layer read of the sim state and never a write: `DirZip.read(S, f)` (`phase` tell, in, reach, out; `n`, `len`, `exit`, `x`, `y`, `dist_bh`) and, for the arc of a way out that bows over the rival, `SimFighter.rushAt` and `rushU`. At `zip_out` the rig samples the way out at eight points and takes the box of the path: the numbers section 3 needs.

## 2. The hold through a zip out and back (the `home` exit)

The one rule: **the viewer sees both fighters at the cue, at the blow, and the tick the zipper is home, and the camera does not move to chase the zipper.** The zip is a mid-band move (3 to 12.5 body heights, up to 937 units), so the pair is in the one view at the cue and the view that fits them at the cue fits them for the whole zip.

- **Layout:** frozen from the cue to 0.4 s after `zip_end`. A layout change already easing (a split opening or closing at the cue) finishes; no new decision starts. The order of the two fighters (sigma) is not allowed to flip during the hold; if it should have flipped by the end, the ordinary swing runs once, after the hold, and only if the layout is a split.
- **Zoom (one view):** held at the cue's separation; from `zip_out` held at the larger of that and the exit's (section 3).
- **Focus (one view):** held near the cue's midpoint, leaning toward the zipper by at most 0.1 of the width.
- **The zipper's pane (split):** held on his home point; the pane the rival watches is held too, with only the hit push. A zip cannot start in a split at the usual zoom (937 units is under the split line), but a pair at 49 degrees, in depth, or in a layout still closing can be in two panes: section 7.
- **Orb's note (playtests): "the camera often follows the launched fighter, so after knocking the opponent away I can't tell what my own character is doing."** Three rules, in order:
  1. A launch that ends inside the widest shared view is not followed at all (`camera-v2.md` section 3, as built): the one view shows both. A zip's blow is a short launch more often than not.
  2. For a launch that leaves the shared view, when the **zipper is the human's fighter**: the camera stays on him through his way out and for 0.4 s after `zip_end`, his own fighter is on the screen on every tick of it, and the victim is the edge pointer and the ring map (the hybrid's hold shot with the impact cut, which does not start until the zipper is home). The chase of the victim begins after that, not at the blow.
  3. When the **human is the one launched** by a zip, the chase is as before: he sees himself.

## 3. A far-side exit, and an exit away up to 12.5 body heights

Both are known at `zip_out`, 6 or 10 ticks before the zipper moves, which is the time to get the frame right and the reason the camera reads that cue rather than waiting for the way out.

- **The frame at `zip_out`.** The pair after the exit is the rival and the exit point `(x, y)`; with an arc, also the box of the sampled path. The rig takes the **larger** of the cue's frame and the exit's: the zoom is held at the zoom that fits it (no zoom-out later while the zipper is moving), and the focus eases toward the midpoint of {rival, exit point} over the ticks in reach, at the usual focus filter, so by the time he moves it is already there.
- **A far-side exit** (`far`): the zipper ends on the rival's other side, 2.5 to the exit's distance. The frame is as above. In one view nothing else is needed. In a split the zipper's pane holds to the blow and then follows him with the ordinary lag bound across (he moves at most 937 units in 12 ticks, about 0.1 of a pane width a tick: well inside the bound); no cut.
- **An exit away to 12.5 bh** (`point`): the same: the frame includes the exit point from `zip_out`, so a zipper who ends at the edge of the mid band is on the screen as he goes and when he stops. At the zoom floor and at 49 degrees the box of the path decides whether the one view holds both; if it does not, the hold falls back to the zipper's own pane in a split (the rig's ordinary decision, taken at `zip_out` rather than mid-flight).
- **The arc over the rival** (`Rush.arc`): its height is in the box, so the zipper at the top of his arc is not cropped; the vertical margin is the rig's usual one.

## 4. What is held and what is released, by exit

| Exit | Zoom | Focus | Layout | Hold ends |
| :--- | :--- | :--- | :--- | :--- |
| `home` | the cue's | near the cue's midpoint | frozen | `zip_end` `done` + 0.4 s |
| `far` | the larger of the cue's and the exit's, from `zip_out` | eases to the final midpoint in the reach ticks | frozen | `zip_end` `done` + 0.4 s |
| `point` (to 12.5 bh) | as `far`, with the path's box | as `far` | frozen | `zip_end` `done` + 0.4 s |

## 5. A dropped fighter

A zipper knocked out of his way out by a shot ("dropped": 24 ticks, `drop_start`, `drop_land`, `drop_end`): `zip_end` comes with the text `shot` (or `down`). The camera does not know where he will fall, so it does not hold:
- At `drop_start` the hold ends at once and the ordinary follow takes over; he is a fighter falling out of the air in the one view, and the usual zoom rate and the lag bound keep him on the screen. In a split his pane follows him; the other pane is as it was.
- At `drop_land` the existing ground-contact push (a small impact push on the pane that has him) plays; the 24 ticks end at `drop_end`.
- If the shot that dropped him was fired by the human's fighter, the shot's own beam shot rules apply and the zip adds nothing.

## 6. When the zip ends early

`zip_end` text `stopped`, `outrun`, `countered`, `caught`, `shot` or `down` ends the hold on that tick, not 0.4 s later: the zipper is not coming home, so nothing is to be held for. Specifically:
- `outrun` (the rival boosted out of the mid band; the zip ends short with no blow): the camera follows the pair as any separation change (the lag bound and the zoom rate); no cut.
- `caught` and `countered`: a brawl starts on that tick; the pair is in the close band, the one view as now; the zip's hold must not outlast it (it would keep the zoom at the cue's separation while the brawl is closer).
- `stopped`, `shot`, `down`: as `outrun` and section 5.

## 7. Split view, and a zipper crossing from one pane to the other

A zip is a mid-band move and a split opens beyond about 2,000 units at 720p, so a zip normally starts in the one view. The cases that reach two panes: a pair at 49 degrees or far apart in depth (the same units look farther), a layout that is closing or opening at the cue, and two humans each in his pane. The rig's rules there:

- **A layout already easing** at the cue finishes its ease (the hold decides nothing new). No frozen half-open divider.
- **Each pane keeps his own fighter** (the anchors): the zipper's pane is held on his home point, the rival's pane on the rival, and the zipper crossing the divider is seen as moving across his pane from the home side to the exit side until the hold ends; he is on the screen by the exit's frame at `zip_out`, and the pane follows him across for a far-side exit (section 3).
- **The order flip (sigma).** When the zipper passes the rival's position the order of the two flips; in a split this is a divider swing (the divider turns by half a revolution). That swing is **deferred** until 0.4 s after `zip_end`; if the zip came home it is cancelled (the order did not change); after a far-side exit it runs once, after the zip, with the ordinary swing time. No swing starts inside a zip.
- **The divider** is not moved by the zipper's passing (the divider follows the pair's separation and the pane order, not a fighter's x in a hold).

## 8. The tests to add to `split_sweep.gd` (against injected cues of the final shape; the cue fields as in section 1)

Each in the one view, at 49 degrees, and (artificial 6,000-unit pair, the exit 750 units) in a split, with the cue withheld as the recorded baseline:

1. `zip home`: no cut; the layout does not change; the zoom moves at most 0.02 (split), 0.04 (one view); the camera moves at most 0.13 of the width; **both fighters are on the screen at the cue, at `zip_out`, at `zip_end` and 0.4 s after**; the zipper is within 5 px of his start at the end; the rival's incoming read is `aimed` from the cue with the right `eta`, inactive after `zip_out`.
2. `zip far side`: no cut; the frame at `zip_out` holds {rival, exit}: both on the screen on every tick from `zip_out` to 0.4 s after `zip_end`; the zoom moves at most 0.06 and never faster than the rate cap; the camera's jerk (change of velocity relative to the zipper) stays under 0.05 of the width; in a split the zipper's pane makes no cut and moves at most 0.12 of the width a tick.
3. `zip point 12.5 bh`: the same, with the exit at 937 units.
4. `zip arc`: the exit's path bows over the rival; the zipper is on the screen on every tick, uncropped at the top of the arc (a vertical margin of at least 0.04 of the height).
5. `zip dropped` (`zip_end shot`, then `drop_start`, `drop_land`, `drop_end`): the hold ends on `drop_start`; no cut; the dropped fighter is on the screen on every tick of the 24; no layout flip.
6. `zip outrun`, `zip caught`, `zip countered`: the hold ends on `zip_end`; for `caught` and `countered` the zoom is back to following the pair within the zoom rate, with no cut, on the tick after.
7. `zip then launch, human zipper` (Orb's note): the zip's blow launches the rival out of the shared view: the zipper is on the screen on every tick from the cue to 0.4 s after `zip_end`; the impact cut does not start before he is home; the victim is in the record's pointer; then the ordinary follow. And the mirror: the human is launched by a zip: the chase is on from the launch.
8. `zip in a split, crossing`: a layout closing at the cue completes; no divider swing during the zip; a far-side exit produces one swing after `zip_end` + 0.4 s and none for a `home` exit; each pane keeps its own fighter on the screen throughout.
9. Real matches, when the AI zips: the jolt scan gets a `zip` class (the cue's window); it must be zero over 0.05 of the width, and the count before and after the zip slice is reported next to the rush class.

## 9. What the code needs (when the commit lands)

In `split_rig.gd`: `_read_move_cue` takes `zip_light` and `zip_heavy` as now plus `dur`; new readers for `zip_out` (the exit frame: the box of the sampled path, the held zoom, the focus easing), `zip_end` (the hold's end, by text), and `drop_start`; the swing deferral in the layout step; the human-zipper rule in the launch follow (no chase and no impact cut until the zipper's hold ends). In `camera_params.gd`: the hold's margin and cap (`ZIP_HOLD_MARGIN` 0.6 s, `ZIP_HOLD_MAX` 2.2 s), the path samples (8), the vertical margin for the arc (0.04). No change to `sim/core/view/camera.gd`: nothing here reads or needs more than the intro block.

## 10. Settled (the EP, 2026-10-05)

- **The rig reads `DirZip.read`, `SimFighter.rushAt` and `rushU` directly**, as view-layer reads: read only, nothing written, and the sim hash must stay equal with and without the rig (the sweep and `pane_check` already check it). No path box on the cue.
- **The bow is 2 body heights (`zip.bowBh`, Game Design's ruling):** over the rival by default, under him when the stick points down and there are 2 body heights of clear room beneath. It is data and could move, so the vertical margin is stated from the box of the sampled path (section 3), never from the number: the test asserts the zipper is on the screen with the margin at the top **and bottom** of whichever bow the read gives (over, and under, the second needing the ground clear beneath).
- **Orb's rule is confirmed:** stay on the human zipper until 0.4 s after `zip_end`, the victim on the edge pointer, the impact cut after he is home.

## 11. From Encounter's built slice (2026-10-05)

- **The in-reach ticks run on the brawl's lines with no brawl announced.** For those ticks `DirBrawl.inBrawl` is true; `brawl_start` comes only if the zipper is caught or countered (text `caught` or `countered`); a zip that leaves sends no `brawl_start` and no `brawl_end`. **The rig keys nothing off `DirBrawl.inBrawl`** (a search of `render/camera/` finds no read of it, no `brawl_start` and no brawl framing), so a zip in reach cannot trip a close framing or push-in of mine. The rule for later: if Camera ever frames a brawl, it takes its start from the `brawl_start` event and never from `inBrawl`, and a zip hold in force owns its ticks; the sweep's `zip` scenarios will assert that no brawl framing starts inside a zip that leaves.
- **The read's pass has a third value, `under`** (the way out bows beneath the rival): the box of the sampled path may extend below the rival, and below the ground line of the pair at the cue. The arc test's vertical margin is applied to the box at the top and the bottom (section 10); the zoom floor and the one view's lower edge are checked against it (a path under a rival who stands on the ground is only offered by the sim when there are 2 body heights of clear room, so the box stays above the ground).


## 12. As built (Z1, 2026-10-06; read this section before the plan above where they differ)

**What failed on Z1, confirmed from the matches.** The three rows (real match 3 full, two humans, t=122.85; real match 10 at 49 degrees, t=21.57; and the anchor step in match 3) were the zip hold of section 2 meeting a **split that was still closing**: a knock-down had left the layout in two panes, the pair came together (58 units apart), the AI zipped in that moment, and the hold froze the layout and disabled the slam (`_slam_step` stood down while a hold was on), so the pair collapsed into two panes' worth of anchors at the divider and a fighter stood on the wrong side of it for 0.31 s. The sweep traces (`--jolts`) show both fighters 58 and 58 units apart, sep 1.00, `locked/locked`, with the hold running.

**What the rig does now.**
- **In a split, or while a pane still holds the screen at the cue: nothing is held.** The way in is a rush: the slam's door and the lag bound handle it as for any rush; the zip is not cut ahead for (`_nopin_until`); the rival's countdown still starts at the tell. This replaces section 7 above (the frozen pane, the deferred swing): a hold in a split was the fault.
- **In one view the zip is held through a frame box.** At `zip_light` / `zip_heavy` the box is the pair at the cue. Every tick it takes in where the two fighters are; at `zip_out` it is reset to the rival and the whole way out (the path sampled from where the zipper stands to the exit point; the bow is left out of the zoom, since two body heights is a fraction of the screen at these zooms, and the sweep checks the bowed way out keeps a vertical margin instead). The camera follows the box, eased (`ZIP_FRAME_TAU` 0.2 s: the merged camera's velocity lead follows a target step with no lag, so a box that widened 350 units in a tick was a 350 unit step of the camera), so the zoom and the focus are where the pair will be before the zipper moves, and he is neither chased nor cropped. The layout is frozen; the order flip (sigma) flags a cut in one view that nothing draws and the test does not count.
- **The end.** `zip_end` `done` ends the hold 0.4 s later; every other text ends it at once; so do `drop_start`, a launch, a knock-down and a shot's state `dropped`. A hold that ends does not step the frame: it eases back to the live pair for 0.6 s (`ZIP_RELEASE`); ended at once by a catch, the merged camera had stepped 0.22 of a screen.
- **The cues are read as built:** `zip_light`/`zip_heavy` (`amount` the tell, `n` the way in, `dur` the whole zip in ticks, `x`, `y` the ticks in reach, not a place); `zip_out` (`text` the exit, `x`, `y` the exit point, `n` the way out, `amount`, `dur` the reach ticks); `zip_end` (`text`). The hold lasts `dur` plus 0.6 s, at most 2.2 s from the cue.

**Orb's note (the camera follows the launched fighter).** Unchanged by the zip and already as the plan says: a launch that ends inside the shared view is not followed; a launched rival ends the hold, and the hybrid takes over (the human attacker's hold shot stays on the zipper and the impact cut waits for the victim's first ground contact, which is after the zipper is home); a human launched by a zip is chased as before.

**Legal's floor** (a way in and a way out each seen for at least 4 ticks, never a blink): the camera makes no cut in a zip (the sweep counts every cut flag but the unseen order flip), and the zipper is on the screen on every tick of the zip, in every scenario below (0 ticks off in 13).

**The tests** (`zip ...` in the sweep; `_zip_run`, against injected cues of the final shape). One view: home; far side; point over; point under (the zipper's bow under the rival, with the clear room the sim demands); home and far side across the world's seam; caught; shot down (`zip_end shot`, `drop_start`, a 24-tick fall); outrun. At 49 degrees: home and far side (cuts and the zipper's place only: the 700-unit test pose cycles split and merge by itself at 49 degrees, before any zip). Split closing (the pair brought together over 1.5 s from 6,000 apart, the zip started with the merge pending: the failure on Z1): no hold, no cut, the zipper on the screen. Asserted: no cut; the zipper on the screen every tick; for a held zip no layout change, the camera's velocity never changing by more than 0.05 of the width in a tick, the zoom moved at most 0.06 for `home`, 0.3 for `far` (the path from the near side of the rival to the far end is wider than the start) and 0.45 for `point`; for `home` he is back within 6 px of where he began; a bowed way out keeps 0.04 of the height top and bottom. Before the fix on HEAD: the zipper was off the screen for 17 ticks in the far-side exit, the layout changed on 17 ticks of a held zip, the zoom moved 0.55, and the three real-match rows failed; after: all pass. The jolt scan now has a `zip` class (the cue to 0.4 s after the end).

**What `dropped` needs from the rig.** Nothing beyond the above: the rig ends the hold at `drop_start` (and on the state), and a dropped fighter falls where the shot put him, so he is a falling fighter in the one view (the zoom rate and the lag bound keep him on the screen) or in his own pane. His state is not "launched", so the chase and the launch hold do not start; the ground-contact push comes from `land` and `bounce` events as for any body. If a drop should read like a launch (a chase), the sim would send `launch`; it does not and the camera does not need it. The 24 ticks without control are a sim fact for the controls and the HUD.

**Sizing the two things coming.**
- **The brawl's control slice (C1): a pair moving up to 0.3 body heights a tick (22.5 units, 1,350 a second), across the seam, with `DirBrawl.centre(S, ex)` for the frame.** The one view frames the pair's midpoint with the merged camera's velocity lead, which keeps pace with a steady speed (the same lead that follows a launch chase at 20,000 units a second); 1,350 a second is a quarter of a screen a second at the usual zoom and well inside it. Two things to do, about 40 lines in `_merged_target` and one sweep scenario: (1) take the focus from `DirBrawl.centre` while a brawl is on and not quiet (a zip in reach is not a brawl: `DirBrawl.quiet(ex)`), so two fighters that jitter against each other do not move the frame; the centre is already the sim's smoothed point; (2) a scenario that drifts a brawling pair across the seam (positions on both sides of the world's wrap) at 22.5 units a tick with reversals: both on the screen, the camera's velocity changing by under 0.05 of the width a tick, no cut, no layout flip. The brawl's near-reversal (0.3 bh a tick one way, then the other) is the jerk to measure; the velocity lead is the thing to tune (`MERGED_TAU`). A real-match jolt class `brawl drift` in the scan once C1 is in.
- **The `double_hit` cue 8 ticks ahead, for a picture-in-picture close-up.** The panel cut-in already exists (a strip over the live view from an inset pane, `PANEL_OPEN` 0.08 s = 5 ticks to wipe open), so an 8-tick lead is enough for it to be open when the second hit lands; ask the sim for **at least 8 ticks, and for the cue to carry both fighters' slots and which is hit**. The work: a `double` panel kind in `PANEL_KINDS` (the victim of the second hit, a short window, the existing cooldown and cap), the request read from the cue, a row in `rule-of-cool-shots.md`, and one sweep scenario (the strip opens before the hit tick and closes after; one inset render, no new cost). About 50 lines. The open question for Game Design is whether it replaces the impact push or adds to it; and in a split the strip sits over the divider's line, which the panel rules already handle.
