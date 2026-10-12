# The re-laid city in depth: what the camera gives Rendering so the fight is never hidden (Camera, 2026-10-12)

Owner: Camera and Cinematography. Paper only: nothing here is built in `render/camera`, and nothing in Rendering's files changes. It answers EP item 4 from `docs/rendering/lanes-camera-flash.md` section 1, as ruled by Orb on the night of 2026-10-11 ("try option 1, the larger see-through patch first, as the patch needs to become bigger to accommodate more missing action, allow a hybrid approach where the building also shrinks"). First draft (2026-10-11) said "always stubs"; that is withdrawn.

## 1. The geometry the rules rest on

Two cameras, both Rendering's measures at 1280 by 720 (`docs/rendering/fighters-in-depth.md`); the first draft of this paper took only the far one. The rules are written with the camera's distance `D_p` and height `cam_y` as parameters.

| | Close brawl (zoom 1.15) | Wide (zoom 0.6) |
| :--- | :--- | :--- |
| Camera's distance from the fighter plane, `D_p` | 1,168 units | 2,240 units |
| Camera's height over the street, `cam_y` | about 175 | about 320 |
| What the frame shows | 626 units tall (8.3 bh), 1,113 wide (14.8 bh) | 1,200 tall |
| A 75-unit fighter on the plane | 86 px | 45 px |
| Row 0 (562 to 938 units in front of the plane) is how far from the lens | 606 to 230 units | 1,678 to 1,302 |
| ... and so how large it is against the plane's scale | 1.9 to 5.1 times | 1.3 to 1.7 times |

- A depth `z` is in bh (75 units), positive toward the camera: the plane is 0; the foreground row 0 stands at +5 to +10; the front street +2.5 to -2.5; block row 1 -2.5 to -11; the middle street -11 to -16; block row 2 -16 to -24.5; the back street -24.5 to -29.5; scenery row 3 beyond (World, `depth-streets.md`). The band is z_front +2.5 to z_back -29.5 for fighters.
- A thing `u` units in front of the plane is `D_b = D_p - u` from the camera and appears `D_p / D_b` times as large as the same thing on the plane.
- A building top at height `h` is on the same sight line as a plane point at `y_ray = cam_y + (h - cam_y) * D_p / D_b`. It hides the fighter's feet when `y_ray > 0`, that is when `h > cam_y * u / D_p`, and the whole fighter when `y_ray > 75`.

**What this gives for row 0.** The height at which a house hides his feet is about 0.15 of its distance in front of the plane in both cameras (84, 112, 140 units at 562, 750, 938 in front at the close brawl; 80, 107, 134 at the wide), so the stub height is nearly the same. What differs is how much of the frame a foreground house takes: at the close brawl a house 938 units in front is 230 units from the lens, 5.1 times its plane size, and a 450-unit-wide house is wider than the screen. It is not an object to be opened by a patch: it is *in the lens*. **Near-clip rule:** a building closer to the camera than 300 units is not drawn for a fight at all (at the close brawl that is anything more than 868 units in front of the plane, the back half of row 0); one between 300 and 600 units from the lens is shrunk to its stub by the `sigma` of section 2 whatever the action's size.

## 2. Row 0: a see-through patch that follows the action, and a building that shrinks when it must

### 2.1 What "the action" is, in screen terms

The camera publishes, per pane and per frame, **one rectangle of the pane in pane pixels, `clear[i].rect`**, with the data below it. Rendering cuts the foreground (every row whose buildings are nearer the camera than the fight) where the rectangle falls. The rectangle is the union of the following, each padded by half a body height (0.5 bh on screen), taken in the pane's own picture:

| Shot | What the rectangle is the union of |
| :--- | :--- |
| **The one view** (merged) | each fighter's body box (his apparent height by 0.6 of it wide); the strip between the two chests (a capsule one body height thick), so the gap is clear, not just the two ends; every beam in flight (its current polyline); a launched body's next 0.5 s (position plus velocity times 0.5 s, with gravity); the zip's frame box while a zip runs |
| **A split pane** | the same, but only his own fighter's box; the strip toward the rival, from his chest to the pane's edge on the rival's side (the approach is read here), capped at 0.5 of the pane's width; any beam in this pane's view; his launch path or zip box as above |
| **A launch follow** (a solo shot on the victim, or a chase pane) | the victim's body box and his next 0.5 s of path, and, while the human attacker is held on, the attacker's box. Not the whole arc: the follow keeps him inside the pane |
| **A beam** | the beam from its source to the end it has reached this tick (plus the 0.3 s ahead of a beam being fired: the fire beat is 20 ticks before it arrives), 0.5 bh thick; a clash's two beams and the meeting point |
| **A cut-in or a transformation's break** | the strip (Camera's own panel) is drawn over the picture, so it needs nothing; the break keeps today's `CUTAWAY_BREAK_R` disc around the body, now the rectangle's lower bound |

The rectangle is **never smaller than today's hole** (a disc of 70 px or 1.6 bh), which stays as the floor.

### 2.2 Patch first, then the building shrinks (the hybrid)

Let `p` be the rectangle's area as a share of the pane's area. Two things happen, in order, as the action takes more of the pane:

- **`p` up to 0.18: the patch only.** A hole in the foreground the size of the rectangle; every building keeps its height.
- **`p` from 0.18 to 0.40: the patch and the shrink.** Buildings whose on-screen extent meets the rectangle's columns shrink toward their stub by `sigma = smoothstep(0.18, 0.40, p)`: height `= h_s + (1 - sigma) (h - h_s)`. The hole stays, so the patch can stop growing and the buildings carry the rest.
- **`p` over 0.40: stubs** (`sigma = 1`) across the rectangle's columns. At a full-width action (a beam across the whole pane) every row-0 building meeting that band is a stub.

The stub height is `h_s = (cam_y - g_p) * (1 - D_b / D_p) - 8`, where `g_p` is the ground height at the fighter on his plane (a crater under him lowers it): at the close brawl 76 units for a building 562 in front, 104 at 750, 132 at 938 (72, 99 and 126 at the wide camera); never below 12. The stub's top then never rises above the fighter's ground line.

Rendering owns *how* (the hole's edge, the shrink's look, debris, whether a shrunk building loses floors from the top or squashes). The camera owns *what and when*: the rectangle, `p`, `sigma`, the rates and the hold.

### 2.3 How fast the patch and the shrink may change

These are the numbers that keep a patch from reading as a flash or a bob. The analyser counts a change when a pixel moves by 0.10 of relative luminance within a second and 21,824 pixels (at 1024 by 768) do so in a window; a house is tens of thousands of pixels. Each opening or shrink is therefore **a change of its own**, and the rule is: slow enough that it is one change at a time, and never two opposite changes inside a second.

| Quantity | Bound | Reason |
| :--- | :--- | :--- |
| Rectangle's edge, growing | at most **0.045 of the pane's width a tick** (`SCROLL_CAP`, the re-frame limiter's number), and the whole growth of area at most 0.25 of the pane over 0.35 s | it opens with the action, never ahead of it by more than the lead below, never as a step |
| Rectangle's edge, shrinking | at most **0.02 of the width a tick**, and only after the hold | closing is the slower, calmer move |
| `sigma`, shrinking buildings | 0 to 1 over **0.5 s** at the fastest (smootherstep), 1 to 0 (standing again) over **0.75 s** | a building changes by about a thirtieth of its area a tick |
| Rectangle's centre | follows the action's centre with the focus filter's own time constant (0.15 s) | it moves as the picture's fighters do; the camera's scroll governor (0.045 of the width a tick) already bounds what sweeps across it |
| Lead | the rectangle is widened on the side the action moves to by its speed times 0.5 s, capped at 0.2 of the pane's width | the foreground is open before the fighter arrives |
| **Hold** | the rectangle narrows, and buildings stand again, only after **0.75 s** with no demand for the space, and only when a building has been clear of the rectangle by 0.05 of the width for that time (so the edge does not flap) | a fighter pacing a street makes the houses neither bob nor strobe |
| **No opposite changes within the hold** | while any building is shrinking or the patch is growing, none stands and the patch does not narrow; the hold clock restarts at the last grow | a growth darkens or brightens a region and a stand does the reverse: two within a second are a flash. Same-direction ones pool, so a row of houses sinking together is one change |
| On a cut (cut-in, break, safety cut, a pane hand-over) | states jump to their target under the cut | nothing eases across a cut |

The camera publishes the rectangle already holding (widening at once, narrowing after the hold) and `sigma` already rate-limited, so Rendering applies what it is given and adds only its own look.

### 2.4 A split where one pane has a foreground and the other does not

Each pane is its own picture: its camera, its `clear[i]` and its own row-0 buildings (or none). Nothing couples them except the divider.

- **Different foregrounds.** Pane 0 is in a suburb (houses in row 0) and pane 1 in open country (none): pane 1's rectangle exists and cuts nothing; pane 0's cuts its houses. When pane 1's camera pans into a suburb the same rules run on it from that tick: the rectangle is already there (it is the action's, not the foreground's), so there is no step.
- **The divider.** The rectangle is clipped to its pane by the compositor's mask, as the picture is; a patch never reaches across the divider, and a building cut in pane 0 is not cut in pane 1's picture of the same place.
- **Layout changes** (a split opening, a merge, a slam's door, about 0.45 to 0.55 s): during the morph the published rectangle for each pane is the cross-fade between that pane's own and the shared one's, with the pane blend's smootherstep of `sep`; `sigma` likewise. The union of the two fighters' actions arrives as the shared rectangle, so the patch grows to the union at the rate bound above and does not jump when the merge completes. A merge that is refused (the dwell) leaves the panes' own rectangles as they were.
- **A pane that holds the screen** (an expanded pane, `e` near 1, a solo shot): the rectangle is that pane's alone and full width.

## 3. Tall buildings in front of the fight: open floors (Orb, 2026-10-12)

Orb, shown the options: "open floors sounds like it would look the most natural, get that implemented". So a low building (a house of the foreground row) opens by the patch and shrinks as section 2 says; a **tall building** in front of the fight (a tower of block row 1 or 2, 18 to 40 bh after the re-lay) opens by **open floors**: only its lowest floors are cut away, across its whole width, in the pane that needs it; the tower above and the skyline stand. The joined patch (a window through the whole building) is kept only as the fallback for a building with no floors to cut.

**What "the action" is for open floors** is the same rectangle as section 2.1 (the fighters' boxes, the strip between them, a beam's polyline, a launch's next half second, a zip's frame box), in the pane's picture. Per building the rig publishes nothing more than the rectangle and `y_top`; Rendering finds the buildings:
- **Which buildings:** those nearer the camera than the action (`D_b < D_f`, `D_f = D_p - u_f` for a fighter `u_f` units in front of his plane, negative behind it) whose on-screen extent meets the rectangle's columns. With the camera dollied to the pair's depth (section 6) this is at most one block row.
- **How many floors:** from the base up to `H = ceil_to_floor(y_ray_inv + 1 floor)`, `y_ray_inv = cam_y + (y_top - cam_y) * D_b / D_f`, the height at which the sight line to the top of the action passes the building (`y_top` the top of the rectangle in world units: his feet plus 1.2 bh for a fighter on his ground, higher for a launch's path or a beam). At the close brawl a fighter on his ground behind a building at half his distance needs 175 + (90 - 175) * 0.5 = 132 units: two floors; in the air at 1,500 units, a building at half the distance: 837 units, eleven floors. Never above what the pane's top edge shows at that depth.
- **Whole width.** No partial widths: a building is opened or not, so a fighter walking along a block opens the buildings one at a time, each once.

**Rates** are section 2.3's, per floor: a floor opens every 3 ticks while he rises (a flight of 20 bh opens in a second), closes every 6 ticks after the 0.75 s hold, and a building that opens and one that closes are never in progress together (no opposite change inside the hold).

**Cut flag a pane.** Every frame carries `clear[i].cut`: true on a tick that is a cut for pane i (a cut-in, a transformation's break, a pane hand-over, a safety or travel-budget cut, a layout's hidden flip). On that tick Rendering sets the state to its target at once, patch, floors and shrink alike; nothing eases across a cut.

**A split when one pane needs it.** Section 2.4 holds: each pane has its own `clear[i]` and its own buildings; nothing couples them but the divider and the morph's cross-fade. A building opened in pane 0 is whole in pane 1's picture of the same place.

## 4. What the camera builds when this is approved

1. `SplitFrame.clear[i]`: `{rect, p, sigma, y_top, x0, x1, holding, cut}`, computed in the rig from the fighters' projected boxes, the beams, the launch and zip frames, with the rate limits and the hold clocks (the rig is tick-stepped and deterministic, so the hold lives here). The compositor passes it through `pane.cutaway` next to the existing hole radius (which stays as the floor).
2. Tests in `split_sweep`: the rectangle contains each fighter's box at every pane size and shot type; its edges never move faster than the bounds; it narrows only after the hold; no two opposite changes within 0.75 s over the real matches; a cut jumps the state; a split's two panes are independent and their blend is continuous.
3. Tools' clips (the list in `lanes-camera-flash.md` section 2): a fighter pacing a street in a suburb, a beam down the front row, a launch along the downtown front street, a flight over a block in the back street.

## 5. Numbers to settle with Rendering before building

| Number | Mine | Why |
| :--- | :--- | :--- |
| Padding | 0.5 bh | a sleeve of street round the body |
| Patch only up to `p` | 0.18 | about a quarter of the pane's width by its height |
| Shrink to stubs by `p` | 0.40 | a full-width beam's band |
| Growth bound | 0.045 of the width a tick, 0.25 of the pane's area over 0.35 s | the re-frame limiter's number |
| Shrink bound | 0.02 of the width a tick | calmer closing |
| `sigma` ease | 0.5 s sink, 0.75 s stand | below the area threshold tick by tick |
| Hold | 0.75 s, margin 0.05 of the width | no opposite change inside a second |
| Lead | speed times 0.5 s, cap 0.2 of the width | open before he arrives |
| Stub top | `(cam_y - g_p)(1 - D_b / D_p) - 8`, 12 to 100 | never above the fighter's ground line |
| Floors (candidate F) | open 1 per 3 ticks, close 1 per 6 after the hold | each step small |

## 6. Fighters in depth: the camera follows the pair's depth (Camera's answer to `depth.md` section 3)

**The need** (Rendering's measures, `fighters-in-depth.md`; Game Design, `depth.md`): at the close brawl a fighter in the middle street is 54% of his plane size (46 px at 720p), in the back street 37% (32 px); a fight must be drawn at fight size (never under 85% of the plane's), the follow eased so a drift still reads (size changing by no more than about 5% a second), and a pair in a crossing or an avenue kept near the middle of the frame so it is seen down the avenue with nothing opened.

**Decision: both, in this order. The camera dollies to the pair's depth; the zoom is what is left.**

*D1. The focus plane follows the pair's depth.* The depth at which the frame's scale (`zoom`, pixels per unit) is defined, the pivot of the camera's orbit, is the brawl's centre depth (the pair's mean `z` in a brawl; the victim's in a launch's chase; the shot's subject in a solo shot), not 0. The camera then stands `D_p` from the *pair*, whatever street he fights in: his size is the plane size (100%, the 85% floor holds with a margin), the street slides under the pair as he drifts, and a fight in the middle street is not a smaller picture of the front street's. In `SplitFrame.project` and `CameraRig` the point `wz` becomes `wz - focus_z`; `frame.focus_z` is the new field (the rig computes it; Rendering applies it). It is a dolly, not a zoom: the buildings between the camera and the pair come nearer the lens (that is where Orb's open floors come in) and row 0 goes behind the camera when the pair is in the middle street or beyond (at the close brawl the camera stands 1,168 units from the pair: for a pair in the middle street, about 156 units in front of the plane, in the front street; for the back street, about 860 units behind the plane, in the middle street). So at most **one block row ever stands between the lens and the fight**, and the foreground row never does.

*D2. How fast.* `focus_z` is eased with a time constant of 0.5 s, capped at 3 bh a second in a brawl (the sim's own drift is at most 1.2) and 12 bh a second in a flight. His size then changes by at most 3.8% a second in a drift (the lag is the drift times the time constant, over the distance): inside the 5%. The scale of the scenery changes by `|d focus_z| / D_b` a tick: 0.3% a tick at the cap on the plane's scenery, 1.6% a tick on a building 230 units from the lens; both are far inside the travel budget (`TRAVEL_MAX` 0.045; the zoom term counts half) and the nearest row is cut or opened anyway (the near-clip rule of section 1).

*D3. What the zoom is for.* The existing size compensation (the zoom that gives the apparent height the plane zoom would have, up to the zoom cap) stays as the fallback: while `focus_z` has not caught up (a flight's 12 bh a second, a pair knocked across a street), the fighter's size is held by the zoom, then given back as the dolly arrives. No tick under 85%.

*D4. A crossing.* A pair whose centre is in an avenue (World's `avenueAt` over the band, and its `intersections()` list) is seen down it when the camera's x is inside the avenue's interval inset by 0.5 bh and the pair's midpoint is within 0.12 of the frame's width of the centre: the sight line from a camera inside the avenue to a pair inside it stays in the avenue (a convex interval). So at a crossing: (1) the one view, not a split (a split's pane cameras stand 0.25 of the width, 3.7 bh at the close brawl, off the fighter and would leave the avenue); (2) the lead room and the anchor's side offsets are off (the chase lead 0, the anchor at the centre) and the focus's x filter at 0.15 s so he is centred; (3) `focus_z` is the pair's, as D1. The camera's x then equals the pair's x, which World's rule already keeps inside the avenue. The camera needs from World one read, no state: whether an x is in an avenue, `WorldLanes.avenueAt(x)` (it exists).

*D5. Band limits (confirmed).* `z_front` +2.5 bh and `z_back` -29.5 bh. At `z_back` the camera at the close brawl stands at -13.9 bh, in the middle street (-11 to -16), clear of every footprint; at `z_front` at +18 bh, beyond the foreground row. `focus_z` is clamped to the band.

*D6. Built (2026-10-12), behind a switch, off.* `SplitRig.depth_dolly` (default false), `SplitView.set_depth_dolly(on)`. The rig computes `frame.focus_z[i]` per pane; `SplitFrame.screen_pos`, `depth_scale` and `apparent_height` take it; `CameraRig.frame(..., focus_z)` places the 3D camera at it. The focus is eased (0.5 s), takes half of the target's own depth step outright each tick (so the onset and the stop are each half of the drift: a drift of 1.2 bh a second is drawn 3.5% a second bigger or smaller at the onset, against 7.7% with a fixed focus), is capped at 3 bh a second in a brawl and 12 in a flight, is clamped to the band, and is never more than 4 bh (300 units) from the depth it follows (a fighter that far off is 0.8 to 1.35 of his size and never behind the lens). Measured in `split_sweep`, close brawl at 720p:

| Row | Result |
| :--- | :--- |
| A pair drifts 1.2 bh a second to the middle street, then to the back street | drawn at 0.98 of plane size at the least; size changes 3.5% a second at most (fixed focus: 7.7%); never off the screen |
| A sidestep of 1 bh over 15 ticks (4 bh a second, past the cap) | 0.967 of plane size at the least; the size change is the sidestep's own (25% a second over a quarter second): the dolly follows it at 3 bh a second and the rest is the zoom's |
| A pair astride an avenue (midpoint in the avenue, middle street) | the pair's midpoint 0.000 of the width from the middle of the frame; the camera's x inside the avenue on every tick |
| B launched across a street at 12 bh a second | the focus within 138 units of him; never behind the lens; 0.87 of plane size at the least |
| The dolly off, with fighters at depth | `focus_z` 0.0 on every frame, and every frame field equal to a clean HEAD's: the digest of 1,500 ticks (a pair drifting through three streets, a flight, a sidestep) over `mode, sep, e, cam_x, cam_y, cam_z, anchor, active, scroll, cutaway, cut, shake` is equal to the bit |

**What Rendering must change to take it** (two lines and a convention):
1. `render/core/pane_world.gd:134`, `cam_rig.frame(cam.y, cam.z, jitter, vp.y, pitch)`: pass `frame.focus_z[pane]` as the sixth argument, and the same for the inset's camera if it has one (it keeps 0: the inset is its own viewport, whose subject it frames at the plane). `CameraRig.focus_z` is then the depth of the plane the zoom is defined at; `CameraRig.dist` is the distance to it, unchanged.
2. Anything that treats depth 0 as "the camera's plane" takes `z - focus_z` instead: `CameraRig.half_width(vw, zd)` is called with the depth relative to the focus; `host.vfx.cam_dist` is `CameraRig.dist` (the distance from the lens to the focus plane), and an object at depth `z` is `cam_dist - (z - focus_z)` from the lens, so the pair, at the focus plane, is always `cam_dist` from it and its flash weights by size are those of the plane (that is the point of D1); the foreground's near-clip (section 1) reads the lens at `focus_z + cam_dist * cos(pitch)`.
3. Convention: while the dolly is on, a building whose depth is greater than the lens's is behind the camera and is not drawn (row 0, for a pair in the middle street). The frame says nothing more about it.

The frame carries `focus_z` per pane and it is interpolated between ticks with the cameras'. A cut-in's camera (`_ov_kind`) stands at its subject's depth (`focus_z` = the subject's), so a close-up on a deep fighter is a close-up at plane size, not a deep one.

## 7. What is open

- **City scale.** With downtown at 20 to 40 fighter heights (Orb, 2026-10-11) a tower is 1,500 to 3,000 units, so the camera's 1,200 units of height can see its top only when pulled back; the foreground rules above do not depend on that, but the "top of a tower out of frame" note in `lanes-camera-flash.md` changes. A taller view for stage changes is a separate decision.
- **The thinner, muted crowd** on the fight's sidewalk (Orb): a 75-unit figure in row 0 hides nothing (`y_ray` is below the ground), so a crowd needs no patch; it is Art's and World's.
- **Motion.** Orb asked to see it moving: Rendering is making the clip. The numbers in section 5 are mine to be moved by what it shows.
