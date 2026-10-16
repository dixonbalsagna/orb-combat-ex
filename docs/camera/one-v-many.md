# One versus many: framing three to five bodies (Camera, 2026-10-14)

Owner: Camera and Cinematography. **Paper.** Nothing here is built. Asked by the EP for Orb (2026-10-14, `docs/ep/vision.md`, last section): the Empress with up to two elite guards, so 3v1 in her base form; a 2v1 is allowed; at most 4v1; **a 2v2 always splits into two 1v1s**; versus only, co-op held; a guard knocked out is resummoned on a cooldown. Asked: how the split view and the panes handle three to five bodies (who gets a pane, what the merged view frames, the 5% floor, depth with more bodies) and the limit the camera can keep readable on a phone screen. Every number is a first value and is marked when it wants a measurement.

## 0. The short version

1. **A pane belongs to a player, not to a body.** There are never more than two panes, however many bodies there are: the principals (the human, and the Empress or the second human) get one each. A guard is framed *with* a principal, never gets a pane of his own, and a third pane is not offered: on a phone it would be a postage stamp.
2. **The one view frames the group, by priority.** Principals first, with the margin they have today; then as many of the others as fit above the size floor; the rest are off the frame and are *pointed to*, not zoomed out to. The frame never zooms out for a guard who has wandered off.
3. **The floor is in pixels, not in a share of the height.** Today's floors are shares: the launch's 5% (36 px at 720p), the shared view's `R_FLOOR` of 3.2% (**23 px at 720p, 12 px on a phone in landscape**: not a body), the pane's `R_PANE` of 8.5% (61 px; 32 px on that phone). The floor becomes **24 px for any body drawn** (equal to `R_FLOOR` at 720p, so nothing changes there) **and 32 px for a principal** (`R_PANE` on the phone), so on a phone in landscape the widest view is **25 body heights across, 11.7 high** at the principal's size and 34 by 15.6 at the floor.
4. **What a phone can hold:** in landscape, **3v1 (four bodies) readably; 4v1 (five) only while they are clustered inside about 14 body heights**, otherwise the farthest guard is an edge marker; in portrait only a 1v1 (and a 2v1 clustered: three bodies in 11.7 across is the edge of legible). So a multi-brawl is a landscape mode on a phone, and portrait gets the pair with markers.
5. **A 2v2 is two 1v1s, so it is two cells**, and the camera frames *cells*: both in one view when they are near each other, one cell to a pane when they are not.
6. **Depth does not multiply.** The dolly follows the principals' depth; a body more than 600 units off the focus plane is drawn under 0.66 of his size, which is under the floor, so he is *out of the frame* for sizing (marker), not a reason to move the camera.
7. **What it costs the code:** the rig is built for two fighters (`_fx[2]`, `frame.active[2]`, `clear[2]`, `focus_z[2]`). Panes stay two; what is new is a *framing set* per pane (a list of bodies instead of one fighter), and Simulation's `S.fighters` is two long. See section 8.

## 1. What the rig does today, and where it is two

| Piece | Today | With many |
| :--- | :--- | :--- |
| Pane index | = fighter slot (0 or 1); the divider's normal, the anchors and the cut-ins all say slot | = principal's slot; unchanged |
| Merged view | the pair's midpoint, zoom from the separation, the vertical spread and the tier; `ahead` = their distance (`_merged_target`) | the bounding box of the framing set; same filters, the same rate caps |
| A pane's zoom | the fighter's own apparent size (`R_PANE`), compensated for depth | his size, **and** what it takes to fit the bodies assigned to him (never under the floor) |
| Fighter off the screen | 0.6 s of waiting, then the travel rule's cut | a principal: as today; a guard: never a cut, a marker |
| The foreground opening (`clear[i]`) | his box, the strip to the rival, the launch path, the beams | all the bodies in his framing set (still one rectangle per pane, capped by its region) |
| Edge pointer | UI's marker points at the other fighter when he is off the pane | a marker per body that is off the frame, up to four |

The measures that constrain it (`camera_params.gd`): no fighter is shown under `R_FLOOR` = 3.2% of the height anywhere (23 px at 720p); a launch's pane under `LAUNCH_FLOOR` = 5%; a pane's fighter is `R_PANE` = 8.5% of the height (61 px) and the fight size `R_FIGHT` 11% (79 px); the split line is at least `MIN_PX` = 18 px under 600 px of height; the dolly's lag bound is 300 units, 600 with the approach cap; the travel bound is 0.045 of the width a tick (0.03 reduced).

## 2. Who gets a pane

**Principals.** The human, and whoever is the other side's principal: the Empress (AI or a second human). That is two, always. Guards are *not* principals: they are AI companions of the Empress and are framed with her.

**Cells.** The choreographer pairs bodies off (`2v2 -> two 1v1`). The camera takes its cue from the pairing: a **cell** is the set of bodies in one fight (one principal pair plus whoever is committed to it). Three cases:

| Situation | Cells | What is framed |
| :--- | :--- | :--- |
| Hero vs Empress and two guards, all close | one | one view: the bounding box of the five, by priority (section 3) |
| The same, the hero having drawn the guards away from the Empress | two (hero + guards; Empress alone) | the split view: two panes, each framing its principal and the bodies *assigned* to him |
| 2v2 (two cells of 1v1) | two | both in one view when they are within the widest view; else one cell to a pane |

**Assignment of a guard to a pane** (for framing only; the panes are windows on the same world, so a guard standing in a pane's picture is drawn there whoever he is assigned to): each non-principal goes to the principal he is **nearest**, with a bias of 4 body heights toward his own principal (a guard belongs to the Empress unless he is that much nearer the hero). A guard assigned to a pane is framed by it; a guard in the other pane's picture but not framed there is simply seen.

**A third pane is never shown.** Two panes of a 1,280-wide screen are 640 each; three are 427, and on a phone in landscape 270: a principal at 32 px in a 270-px-wide pane has no room to move. When three cells exist (the hero, the Empress, and a guard cut off by 20 body heights), the guard is a marker.

## 3. What the merged view frames

**The framing set** is, in priority order:
1. The principals, with today's margins (0.168 of the width at the opening, 10% of the height tall at the brawl zoom).
2. The bodies *committed* to a principal in the last 2 s (attacking, being attacked, or within 6 body heights of him).
3. Everyone else, nearest first.

**The zoom** is the smallest that holds items 1 and 2 with margin, never under the floor (section 4). Item 3 is included while it does not push the zoom under the floor. Whoever does not fit is out of the frame and gets a marker.

**Hysteresis.** A body joins the framing set when he is within 0.9 of the frame's half width and leaves when he is beyond 1.1: a guard who steps in and out of the edge would otherwise step the zoom target. The zoom target changes through the filters and the rate caps that exist (the comfort rate, the travel bound), so a join is a slow zoom-out and a leave a slow zoom-in, and the merge zoom limit of `buildings-in-frame.md` section 13 is the closing's.

**The vertical.** Bodies in the air: the bounding box includes them up to 8 body heights above the principals (a launched guard is not followed up); above that they are markers. That is the same rule as the pair's vertical spread today.

**The weighting.** The principals' midpoint is the focus, with the group's bounding centre pulling it by up to 0.15 of the width: the principals stay where the player looks, and a guard behind them is seen.

## 4. The floor, and what a phone can hold

The camera's floors are shares of the height (the 3.2% of `R_FLOOR`, the 5% of a launch, the 8.5% of a pane). At 720p they are 23, 36 and 61 px; they scale down with the screen, and on a phone in landscape (375 px tall) they are **12, 19 and 32 px**: the shared view's floor is not a body there. The floor has to be a size in pixels: **24 px for any body drawn, 32 px for a principal**, whichever is larger than the share.

| Screen | Height | R_FLOOR (3.2%) | R_PANE (8.5%) | Widest view at 24 px (body heights) | At 32 px (a principal) | At 40 px (comfort) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Desktop 1,280 x 720 | 720 | 23 px | 61 px | 53 x 30 | 40 x 22.5 | 32 x 18 |
| Steam Deck 1,280 x 800 | 800 | 26 px | 68 px | 53 x 33 | 40 x 25 | 32 x 20 |
| Phone, landscape 812 x 375 | 375 | **12 px** | **32 px** | **34 x 15.6** | **25 x 11.7** | **20 x 9.4** |
| Phone, portrait 375 x 812 | 812 | 26 px | 69 px | 15.6 x 34 | 11.7 x 25 | 9.4 x 20 |

The widest view is where the number of bodies stops. A brawl takes room: a standing body is 0.6 to 0.8 of a body height wide, but a body in a melee takes about **4 body heights of width** (reach, the strike's travel, the shake), and a cluster of four overlaps in depth, 10 to 12 across; five, 12 to 14.

**What follows** (first values; they want Tools' still frames and Orb's phone):

| | Landscape phone (25 across at 32 px; 20 at 40) | Portrait phone (11.7 across) | Desktop (40 across) |
| :--- | :--- | :--- | :--- |
| 1v1 | yes, at 32 to 40 px (R_PANE gives 32) | yes (a 1v1 is 6 to 8 across) | yes |
| 2v1 (3 bodies) | yes, clustered 8 to 10 | **edge**: legible only clustered inside 10; guards as markers beyond | yes |
| 3v1 (4 bodies, the Empress's base) | **yes** when clustered inside 12 (the usual); a guard past 14 is a marker | no: pair framing, guards as markers | yes |
| 4v1 (5 bodies) | **only while clustered inside 14**; the farthest is a marker | no | yes, 14 to 16 across |
| 2v2 as two 1v1s | one view when the cells are within 18; else a pane each | no: one cell at a time (the nearer to the human), the other a marker | yes |

So the limit the camera can keep readable on a phone is **four bodies in landscape, five while clustered, two in portrait**; and a multi-brawl mode on a phone should ask for landscape.

## 5. Depth with more bodies

The dolly's focus depth follows the principals' mean depth (D1), not the group's mean: a guard who is a street behind should not pull the picture. With more bodies:
- A body within 300 units (4 body heights) of the focus plane is drawn at 0.8 to 1.35 of his size: in the frame.
- 300 to 600 units: 0.66 to 0.8 of his size: in the frame while he is still 24 px or more (the floor for a body that is not a principal), else a marker.
- Beyond 600: out of the frame for sizing. He is drawn if he is on the screen; he does not move the zoom or the dolly.
- The approach cap (the lens does not run at a facade) reads the focus plane and the central view, unchanged.
- The open floors: `clear[i]` takes the union of the framing set's boxes, capped by the pane's region: with five bodies the rectangle's area share is likely over 0.4 (the patch saturates: the foreground is fully opened and the row's buildings fully shrunk). That is acceptable and is what a five-body brawl in a street needs; it does cost the foreground's depth for the length of the fight.

## 6. What changes in the cuts and shots

- **The summon** (the Empress calling two guards): a beat the camera should *stage*, not a cut: a panel strip (the existing cut-in strip, `rule-of-cool-shots.md`) on the Empress with the guards arriving in the main view, which keeps framing the pair until the guards are in. No camera move for the arrival itself (a guard appearing is a join under the hysteresis).
- **A guard knocked out**: no shot; the framing set drops him when he is down for 1 s (a body that is down stays in the frame while he is a hazard).
- **The resummon on a cooldown**: the same as a summon, but only the strip's light version (a cooldown that keeps cycling must not make a cut a second).
- **Launches**: the launch shot is for the launched fighter; with a guard launched the rule is "a principal is followed, a guard is not": a launched guard leaves the frame as a marker, and the camera stays on the principals.
- **The divider's slam, the rush**: a rush is a principal's. A guard rushing is a marker move, not a slam.

## 7. The flash rules and the many

More bodies means more simultaneous change in the same area, which is VFX's and the choreographer's, not the camera's, and the camera must not add to it. Three rules: (1) the framing set never *steps* the zoom (hysteresis and the rate caps); (2) adding a body is never a cut; (3) the travel bound is the same: a group's centre moves no faster than a pair's did. The foreground's patch saturating is a *less* changing picture (it is already open).

## 8. What it needs, and the order I would build in

| Who | What |
| :--- | :--- |
| **Simulation** | a body list the camera can read: today's `S.fighters` is two; the guards need entries (`team`, `principal`, `owner`, x, y, z, state, tier) and events for summon, guard down, resummon. Without it the camera cannot frame them |
| **Encounter / Game Design** | the cell: which bodies are in which fight (the choreographer's pairing), as a read |
| **UI** | a marker per off-frame body (up to four), and a phone-landscape layout |
| **Rendering** | many bodies per pane at 24 to 32 px: the sprite budget and the outline at that size |
| **Tools** | a still-frame check at 812 x 375: five bodies clustered inside 14 body heights at 32 px |

Build order (all behind switches, default off, each with a `split_sweep` row):
1. **The framing set in the merged view**: N bodies from a test list, the priority, the floor in pixels, hysteresis; rows: 3, 4, 5 bodies, a guard walking in and out of the edge (no zoom step over the comfort rate), a launched guard (a marker, no camera move), the phone's pixel floor.
2. **Assignment and the panes' framing** (a pane frames its principal and his assigned bodies), the cell read; rows: 3v1 split with the guards drawn away; 2v2 as two cells.
3. **`clear[i]`'s union** and the markers' data (which bodies are off the frame, and on which side).
4. **The summon strip** (with Encounter's event).

**Open for Orb:** whether a phone gets multi-brawls in landscape only (my recommendation), and whether a guard beyond the frame should be a marker or may simply be lost (a guard the player never sees is a guard the Empress's player cannot command by sight).

## 9. Built (2026-10-15): the shared view's framing set, behind a switch (scratch on stages 1 to 3, not applied)

**Switch:** `SplitView.set_many_framing(on)` (build-time, default off; `SplitRig.many_framing`). With two bodies, or with it off, nothing changes: `depth_inert` digests equal a clean HEAD's with it on at two bodies, and `split_sweep`, `seam_sweep`, `pane_check` and `determinism` (plain and `--intro`) pass.

**What it does** (`SplitRig._many_set`, in `_merged_target`; `SplitFrame.many_off`):
- The principals are the one (slot 0), the second principal (slot 1) and the one's *partner now*: the nearest of the others, held unless another is a body height nearer (a tag hands the fight to a guard, who steps in to striking distance). The pair's own focus, brawl centre and zip box stay the base.
- Every other body counts by a **weight** between 0 and 1, from the zoom that fits him together with the set: 0 at 0.9 of the limit (the principals' pixel floor, 32 px, or three quarters of the principals' own zoom, whichever is higher) and 1 at 1.1 of it. The weight *moves* at 0.025 a tick, so a body that joins or leaves never steps the frame (the first build used a hysteresis on a boolean and stepped the focus 270 units in one tick when a guard flew off; the weights fixed it: worst travel 0.2016 to 0.0391 on the same seed).
- The focus is the principals' midpoint pulled toward the set's bounding centre by at most 0.15 of the width; the span is the weighted farthest member.
- A body more than 8 body heights above the principals, or 600 units deeper than their plane, has no weight (the first is a marker). A body with a weight under 0.5 is listed in `SplitFrame.many_off` as `[slot, side]` (-1 left, +1 right, 0 above): UI's markers.
- The zoom floor in the merged view is 24 px for any body when there are more than two (it is the share `R_FLOOR` otherwise).

**Measured** (`render/camera/tests/many_probe.gd`, the real scene, the AI on every body, 3,000 ticks, seeds 2 to 4, 3 / 4 / 5 bodies, 1,280 x 720 and 812 x 375; Encounter's stage 3 on Simulation's stage 1, scratch on HEAD 4a3ecb74):

| Row | Off | On |
| :--- | :--- | :--- |
| The one off the picture, ticks (all 18 desktop matches and 8 phone) | 0 | 0 |
| The Empress off the picture | 0 | 0 |
| Interjections landed off the picture | 0 of 1 to 6 a match | 0 |
| The partner (a guard after a tag) off the picture, ticks of 3,000: seed 3 with 4 and 5 bodies; seed 4 with 4 and 5 | 89, 89; 86, 84 | **0, 0; 38, 42** |
| ... the same in a split view (seeds 2 and 3 with three bodies, seed 2 with 4 and 5) | 48, 439, 70, 133 | **unchanged** (the panes are slot-bound, section 2) |
| The guards' share of ticks off the picture | 0.155 0.179 0.114 0.056 0.203 0.104 0.098 | 0.131 0.152 0.096 0.030 0.141 0.043 0.094 |
| Worst travel a tick in the merged view (bound 0.045) | 0.0407, 0.0538 | 0.0391, 0.0534 |
| Ticks over 0.045, merged-view matches (seed 4: 4 and 5 bodies; seed 3: 4 and 5 bodies) | 0, 1; 10, 10 | 0, 1; **12, 12** (the two are a launch's solo shot, whose blend with the shared camera sweeps a little more) |
| Cuts | as the match makes them | the same |
| Smallest principal drawn, seed 4 (merged all match) with 4 and 5 bodies | 55.6, 55.6 | **49.5, 43.0** (a guard pulls the zoom out by up to a quarter; the other seeds are split views and unchanged, 23 to 37) |
| Ticks a body on screen is under 24 px (desktop) | 11 (3 bodies seed 2, both arms) | 11 |
| Phone landscape (4 and 5 bodies, seeds 2 and 3): partner off the picture | 47, 79, 69, 79 | 47, **2**, 69, **2** |
| ... markers the frame lists, most at once | 0 | 1 to 3 |

The `worst_travel` of 7 to 8 in the table's raw output is the probe's pane flip at a launch shot (a measurement artifact in both arms; the notes of `buildings-in-frame.md` section 15).

**What it does not do yet** (the build order's 2 and 3): in the split view each pane frames its own principal, slot 0 and slot 1, whatever the director has made of the fight; after a tag the partner is a guard who can be outside both panes (439 ticks of 3,000 at three bodies on seed 3). That is the assignment of section 2: a pane frames its principal *and the partner or bodies assigned to him*. It needs the pane's framing set (`_own_zoom_target` and the focus take a list), a `clear[i]` union, and is the next window. A flash clip of a 3v1 is Tools' to stage (`flash_capture.gd` takes two `slots`); the camera's own read is the table above.

## 10. Built (2026-10-16): the pane's framing set, the pixel floor in a pane, the sweep rows (behind `many_framing`, off)

The next window of section 8's build order. In a split view each pane frames its principal (slot 0, slot 1) as before, **and the bodies assigned to him** (`SplitRig._many_pane_tick`): the one's partner (the nearest of the others, section 9) and the guards nearer the one by more than 4 body heights go with pane 0; the others with the second principal's pane. Each assigned body counts by a weight that moves at 0.025 a tick (no step when one joins or leaves), 1 while the zoom that fits him with the pane's other bodies stays above three quarters of the pane's own size and the principal's 32 px floor (the partner is held down to the floor alone). The pane's zoom takes the weighted fit (`_many_pzf`, never under the floor) and its focus is pulled toward the set's centre by at most 0.15 of the pane's width (`_many_pull`, into the focus target, so the filters take it). A body out of both panes is listed in `SplitFrame.many_off` ([slot, side], 0 above) for UI's markers. In a many-body match the pane's governor floor is 24 px (`MANY_PIX_FLOOR`), not the 3.2% share (12 px on a phone).

**Measured** (`many_probe.gd`, scratch with Simulation's stage 1 and Encounter's stages 2 and 3, seeds 2 to 4, 3,000 ticks; "off" is the switch off on the same tree):

| The partner (a guard after a tag) off the picture, ticks | Off | On |
| :--- | :--- | :--- |
| 4 bodies, seed 2 (a split view of 1,045 ticks) / seed 3 | 70 / 89 | **12 / 0** |
| 5 bodies, seed 2 / seed 3 | 133 / 89 | **0 / 0** |
| 3 bodies, seed 2 / seed 3 (a guard that stands 600 to 1,100 units from the one) | 48 / 439 | 48 / 333 |
| Phone (812 x 375), 4 and 5 bodies, seed 2 | 47 / 69 | **14 / 0** |
| Phone, 4 and 5 bodies, seed 3 | 79 / 79 | **2 / 2** |
| Guards' share of ticks off the picture, 4 bodies, seeds 2 to 4 | 0.114 0.056 0.203 | 0.048 0.000 0.141 |
| The one, the Empress off the picture | 0 | 0 |

**The limit:** a partner that stands more than about 1,000 units from the one cannot be held in a half-width pane at the principal's 32 px floor; he is then a marker (3 bodies, seed 3: 333 ticks). Encounter's stage 3 steps a tag's partner in to striking distance; the guard in that match did not.

**Sweep rows** (`split_sweep.gd`, a synthetic guard appended to the two-body state): "many bodies walk" (a guard out to 3,000 units and back over twenty seconds: worst zoom step 0.0108 against the comfort 0.04, worst travel 0.0109, the one and the Empress always on screen), "tag" (the nearest guard changes at once: worst travel 0.0450 at the bound, zoom 0.04 at the rate cap), "launched" (a guard 20 body heights up is marked above and the frame does not zoom), "split" (a guard with the one is in the one's pane, the one at 32 px or more, no marker).

**Not done:** `clear[i]`'s union over the assigned bodies (the foreground's opening is still the principal's and the strip to his rival); a 2v2 as two cells; the summon strip.
