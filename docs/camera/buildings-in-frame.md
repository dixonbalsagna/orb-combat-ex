# Buildings in frame: a chain, a lodge, a wall slam, a falling stack (Camera, 2026-10-12)

Owner: Camera and Cinematography. **Paper.** Nothing here is built; every number is a first value, and the ones marked *measure* wait for Tools' clips. Asked by the EP for Orb (2026-10-12): "smashing opponents through multiple buildings is climactic, catastrophic, visually appealing, and part of the gameplay hook." Reads: Game Design `docs/design/buildings.md` (the ladder, the lodge, the wall slam, the falling stack), World `docs/world/destruction-hook.md`, and my `depth-and-chains.md` (the chain shot as built on 2026-10-01), `city-in-depth.md` section 6 (the dolly), `split-screen.md` section 24h (the travel bound). Rendering's `destruction-look.md` is theirs; where my frames depend on it I say so.

## 0. The short version

1. **The camera holds, the world breaks.** Orb's spectacle is what the buildings do, and the flash rules say the picture may change by only so much per second. So while a building is being hit, held, slammed or is coming down, the camera does not travel: it holds a *stage*, and the only thing that changes in the picture is the destruction. It moves between stages, and it moves slowly, in the gaps.
2. **A chain is a relay of stages, not a chase.** Two links in frame at a time (the building he is in and the next), the body at the trailing third; the stage moves on each `chain_link`, eased, at no more than 0.03 of the width a tick. A chain of three fits one stage at the launch zoom; four or five take two.
3. **Down a street the camera stands on the plane and looks across the chain. Across a block it stands behind the line and the dolly follows him through the holes.** Both are the dolly's job (D1): his size stays the plane's, and one block row at most stands between the lens and him.
4. **The lodge is a push, not a cut.** The hold (0.5 to 0.9 s) is the only moment the sim gives the camera a still subject. Over it the zoom goes in by a quarter of its size, centred on the breach, and comes back after. That costs a tenth of the travel bound.
5. **A wall slam is a held stage with the breach in the middle**, the three or four floors of damage in frame; a falling stack is a *pull-out during the warning*, so the fall zone is in the picture before it falls, and a held wide while it comes down.
6. **No cut anywhere in these four shots.** A cut is a flash (the dip and a pair of changes of 25,000 to 50,000 pixels); a subject off the screen is none. A body that leaves the pane at speed is waited for (the travel rule), not chased with a cut.
7. **The clip that still fails collapse-normal is a different shot** (section 7): a body across the city at 6,600 units a second. The building shots are slow enough to pass; that one has to be a held wide with the body leaving the frame and a settle, and its numbers are below.

## 1. The two bounds these shots live under

| Bound | Number | Source |
| :--- | :--- | :--- |
| Displayed travel of a pane | `sqrt(dx^2 + dy^2) * z / vw + 0.5 |d ln z|` at most **0.045 of the width a tick** (0.03 reduced) | `split-screen.md` 24h |
| A cut | costs one flash; at most one in a second a pane | 24h, measured |
| A subject off the screen | costs none; waited for 0.6 s before any cut | 24h |
| Size | a fighter is never under 5% of the height for a launch (`LAUNCH_FLOOR`), 10% at the brawl | `camera-v2.md` |
| Zoom | no faster than the comfort rate (`ZOOM_RATE_TRANS`); a push of 25% in 0.6 s is inside it | `camera_params.gd` |

What a body does to the travel when it is *followed* (zoom 0.6, 1,280 px wide, 60 ticks a second): 1,000 units a second is 10 px a tick, 0.008 of the width; 2,000 (a building launch's speed, force 2,000) is 0.016; 3,000 is 0.023; **6,600 (the commonest launch, SMASH ACROSS, 13,200 units in two seconds) is 0.052**, over the bound. So a chain through buildings is inside the bound even when it is chased; what brings it below by a wide margin is not chasing it. The across-the-city launch is over the bound at any zoom the 5% floor allows: at zoom 0.48, the floor, it is 0.041.

## 2. The four shots

Sizes: a house is under five floors (a few bh), a downtown tower 14 to 20 floors, 1,500 to 2,250 units (a floor is about 110 units, 1.5 bh), a landmark 23 to 33 floors. A building's width is 6 to 9 bh (450 to 675 units) and the gap between two in a street about 2 to 3 bh, so a link is about 700 units: three links are 2,100 units, the width of the screen at zoom 0.6.

| Shot | The subject | Hold / time | One view | Split |
| :--- | :--- | :--- | :--- | :--- |
| **Launch through a chain** | the body and the buildings ahead of him | the flight, 0.35 s first hit, 0.12 s each further, 0.8 s at most together (the sim's) | the stage frames the body at 0.35 from the trailing edge and the first two links; the attacker is in frame while he fits, and is let go at the first hit | the launched fighter's pane takes the screen (as now), the attacker's pane returns after the lodge |
| **The lodge** | the breach he is in | 0.5 s (tiers 1 and 2), 0.7 s (3), 0.9 s (4, finisher) | the frame holds; the push of section 4 | the launched pane holds the screen through the lodge; the other pane returns at its end |
| **The wall slam** | the face of the tower | the stop is about 15 ticks, the stagger 24, the attacker's first move 45 | the stage is centred on the breach, three or four floors in frame, the body at the wall | his pane takes the screen for the stop, then the follow |
| **The falling stack** | the stack and the fall zone | warning at least 1.5 s, collapse at least 2 s | a pull-out in the warning; held wide in the collapse | each pane keeps its fighter; the pane whose fighter is inside the fall zone pulls out; no layout change for a stack |

## 3. Where the camera stands: down a street, across a block

The chain's line is World's: *down a street* is the x line through the row-1 buildings; *across a block* is a line through depth: the three streets stand at 0, -1,012 and -2,025 units (World's three-street table) with a row of buildings between each pair, row 1's near face 2.5 bh (190 units) behind the plane; World's L3 makes the line possible from the front street.

**Down a street** (the common one). The body's z eases from the plane to row 1's front face (-190 units) and runs along x. The camera stands on the plane with the dolly on: his size is the plane's whatever the row he is aimed at (the dolly follows his depth at up to 12 bh a second in a flight, 900 units, so the whole dive is inside it), the chain is seen side-on, each hole shows as the body goes into it, and the next building comes toward the lead edge. **The stage** is the camera's x and zoom for two links: centre at the midpoint of the building he is in and the next, zoom the smaller of the launch zoom and the one that puts both links (their near edges, with 0.15 of the width each side) on the screen, never under 0.5 (the body at 37 px, 5.2%). It holds while the body crosses it and moves to the next pair on `chain_link`, eased with a time constant of 0.25 s and a cap of 0.03 of the width a tick. At 700 units a link a stage holds two buildings (three would not leave the margin at the zoom floor), so the stage moves once a link: 700 units, 420 px at 0.6, a third of the width, over about 0.3 s at the cap. A body that keeps 0.7 of his speed a building is slower at each link, so the later links are held longer than the first. (As built, section 10.)

**Across a block** (the strongest picture, and the rarest). The body goes *away* from the camera through the rows: the line of holes is a tunnel seen end on, each lit by the sky behind the next. The camera stands behind the line on the plane and the dolly carries the focus into the rows after him, at the body's own rate, to at most the row he lodges in: his size stays the plane's, so the holes shrink in front of him as they should. Three rules: (1) the focus is clamped to the band (D5: -29.5 bh) and never more than 4 bh from his depth (the dolly's lag bound); (2) the near-clip rule is Rendering's: a building 300 units or less from the lens is not drawn and one 300 to 600 away is a stub, so a camera that comes into a row is never inside a wall, and the building he has just gone through is the nearest thing in frame and is already open; (3) the zoom is not asked to do the work of the dolly (D3's fallback only while the focus catches up). One view only: a split's pane cameras stand 0.25 of the width off the fighter and cannot look down the line; the chain is a solo shot of the launched fighter's pane, which is the whole screen, centred.

**Two dollies at once.** If the pair is in the middle street and the launch goes to the back, the focus is the victim's (a launch's chase follows the victim), and the attacker leaves the frame by design; his pane returns at the end of the shot.

## 4. What the lodge's hold lets the camera do

The lodge is the first time in the game that the sim gives the camera a held body and a held building together, for 0.5 to 0.9 s. Three things it can do, in order of what I would build:

1. **A push in on the breach** (decided). From the stage's zoom `z` to `min(1.15, 1.25 z)` over the hold, eased in and out, centred on the breach (the hit point `(x, y, z)` of `building_hit`, not the body), and returned over 0.5 s after the hold by the ordinary zoom filter. Travel per tick is `0.5 |d ln z|`: 0.22 of a log unit over 30 ticks is 0.0037, over 54 ticks 0.002: **a twelfth to a fifth of the bound.** The push is the existing impact push (+6%, 0.15 s) grown to the hold: the same event, the same code.
2. **A held wide** (the alternative, and the right one when the lodge is deep in a chain of five whose last two links are in the stage): no push, no travel at all; the picture is the breach, the dust, the debris. It is the choice when the chain ended in a *tower*, whose damage is three or four floors: the push would crop the floors above and below the body, which the ladder in `buildings.md` section 1 says must be readable. So: push for a house or a breach one floor high, hold for a tower.
3. **Not a cut-in.** A close-up cut on the lodged body (the cut-in shot, 16% of the height) is a flash and a change of subject at the moment the picture is busiest. Not in the lodge. It remains available after it, at the settle, as today's cut-in rules allow.

The hold also lets the **HUD's pointer** and Audio's cue come to the frame without the picture moving; I do nothing for them.

## 5. The wall slam and the falling stack

**The wall slam** (a tier-1 body, a tower that holds). The body stops in the face for about 15 ticks; the face breaks over the floors he covers, glass goes from the floor above and the floor below. The stage is centred on the *breach*, not the body, with room for the floor above and below the body's own at the launch zoom (four floors are 430 units, 5.8 bh: 260 px at 0.6, a third of the height; they fit with room), and the existing impact push on the hit (+6% over 0.15 s, shake). Then **nothing**: the stagger is 24 ticks of a body coming off the wall and the attacker has the first move after 45; the follow takes the body back at the ordinary lag bound. The one new thing is the attacker: his 45 ticks of waiting are a free beat for the pair to be in one view again, which the layout rules already do after a solo shot ends.

**The falling stack.** Game Design: warning at least 1.5 s (always 0.6 s longer than any hold a fighter there is in), then collapse of at least 2 s, 6 damage a floor to what is under it. This is a shot the *player* must read, so the camera's job is to make the fall zone visible before it falls:
- **The fall zone** is the footprint (its width) plus 1 bh each side, from the ground to as high as the frame shows. It must be inside the pane of any fighter within 12 bh of it, or the pane says so with the HUD's pointer (the edge marker, UI's).
- **The warning:** a slow pull-out of up to 25% over 1.0 s (an e-fold of 0.29 over 60 ticks: 0.0024 a tick), to no lower than the 5% floor (zoom 0.48), the stack's base and as many floors as fit. The top of a 14 to 20 floor tower does not fit at 0.48 (it shows 1,500 units): that is deliberate: the stack leaves the top of the frame, and what the player reads is dust and glass coming down out of it, the groan, and the shadow.
- **The collapse:** held. No travel, no zoom. The shake of the sim's impacts is Controls', and for the collapse it is inside the travel bound (at most 0.01 of the width a tick, 13 px at 1,280), at most 6 px in amplitude, below 12 Hz for the first 0.5 s, decaying: that is a requirement to Controls, not mine to set.
- **A fighter caught** (6 damage a floor, buried 0.5 to 1 s): the pane holds on him buried; the follow resumes at the end.
- **Split:** each pane keeps its fighter; no layout change for a stack. If both fighters are inside one fall zone they are in one view anyway.

## 6. Staying inside the rules, and what each choice costs

| Choice | Travel a tick | Flash cost |
| :--- | :--- | :--- |
| A stage held through a hit | 0 | the destruction's own (Rendering's and VFX's) |
| A relay between stages (700 units to 1,400 in 0.6 s) | 0.011 to 0.018 | scenery sweeps at that rate, as a follow at 1,000 to 2,000 units a second does today |
| The lodge's push (1.25x over 30 to 54 ticks) | 0.002 to 0.004 | a scaling of the frame by a quarter over half a second |
| The warning pull-out (25% over 60 ticks) | 0.0024 | as above, once |
| A cut | n/a | one flash, once a second at most; **none in these four shots** |
| The dolly through rows | 0.003 a tick on the plane's scenery at its cap, 0.016 on a building 230 units from the lens | the near row is cut or opened by the near-clip rule |

Tests I would add (section 8): over a scripted chain of 2, 3 and 5 links down a street and across a block, one view and split, reduced and not: the body is on screen inside his pane at every tick from the launch to the lodge's end; no tick over the bound; no cut; the number of stage moves is at most the number of links; the push ends at the hold's end and the zoom is back within 0.5 s; a stack's fall zone is in the pane of a fighter within 12 bh at every tick of the warning and the collapse.

## 7. The clip that fails: a launch across downtown (collapse-normal, ticks 717 to 755 on main)

**What it is.** The rival launched across downtown by a SMASH ACROSS: about 6,600 units a second over 13,200 units, 20 to 35% of the frame changing every tick for 25 ticks. It is not a building shot (he does not meet one); it is the commonest launch in the game, over the tallest, highest-contrast scenery, and it asks the follow for 0.041 to 0.052 of the width a tick.

**Why the bound does not save it.** The 0.045 bound passed in the clips I measured on the old city. Downtown is taller and higher in contrast (20 to 40 fighter heights, dark facades against lit windows), so I expect it turns more of the frame at the same travel; that is a reading, not a measurement, and Tools' table with the budget off and on is what settles it. If it holds, *the follow itself* is what is wrong at this speed, not a number in it.

**What I propose (the shot, measured next):** a launch whose speed times the pane's zoom would exceed 0.03 of the width a tick **is not followed by the camera at all**.
1. At the launch the pane holds its frame (the stage) and the body leaves it (a subject off the screen costs nothing). The travel is zero.
2. The pane *cuts nothing and moves nothing* for 0.6 s after he is gone (the existing wait), then **moves to the landing** at no more than 0.03 a tick, as an eased pan along the flight's line at the cap, with the zoom out to the 5% floor for the pan; the distance is then covered in `13,200 * 0.48 / (0.03 * 1280 * 60)` = 2.7 s. Or, when the landing is farther than that is worth (more than 20,000 units), one cut at the end of the wait (a flash, once).
3. Where a launch through the flight crosses a building (a BUILDING SMASH from a SMASH ACROSS's line), the stage rules of section 3 take over from that building.
4. The HUD's edge arrow points at him while he is out of the frame (UI's).

This is the travel budget's behaviour with a lower speed threshold (0.03, not 0.045) and a pan instead of the catch-up, so it is a small change to a rule that exists. **Built (section 10, `launch_hold`, off).** I will not claim it passes collapse-normal until Tools has run it both ways; I would report the table before and after. It costs the picture of the body in flight across the city, which is the thing a player would like to see, and that is the reason the 5% floor and the bound disagree: **a decision for Orb if the clip cannot be brought under with the body still in frame** (the cheaper picture is the body at 30 px, 4%, streaking along a held frame).

## 8. What I would build, in order, and what I need

1. **The stage and the relay** (`SplitRig`: the chain's lead already exists; the stage is two links and a cap), and the tests of section 6. About 120 lines, behind the same switch as the dolly.
2. **The lodge push** (the impact push grown to the hold, centred on the breach). Needs the `lodge` event or the hold's length from the sim: **from Simulation/World, an event `lodge {x, y, z, hold}`** (the breach's point and the hold in seconds); today `building_hit` carries the point and the sim's `dirS.stop` the hold.
3. **The wall slam stage** (the breach, not the body). Needs `building_hit.outcome` to say *wall* (a tier-1 body, a tower that holds): from World, one value.
4. **The stack's fall zone and the warning pull-out.** Needs `building_failing {b, x, y, w, h, t_warn, t_fall}` from World's failing state (`failT`): the footprint, the height and the two times.
5. **The slow-launch rule** of section 7 behind a switch, measured on collapse-normal both ways.

| Who | What |
| :--- | :--- |
| World | `lodge`, the wall outcome on `building_hit`, `building_failing` (items 2 to 4) |
| Controls | the shake's amplitude and rate during a collapse (section 5) |
| Rendering | the near-clip rule for a camera that comes into a row; the breach and a cleared floor drawn so a held wide reads |
| Tools | collapse-normal both ways for section 7; a chain clip, a lodge clip and a stack clip |
| UI | the edge pointer to a body out of frame and to a fall zone out of pane |

## 9. The travel budget as the default

I have no reason to say yes yet. The budget's cut-and-wait is what section 7 wants for fast launches, so the rule belongs in the product; but it has a cost the flash numbers hide, and **the case that failed in this batch is its cost**: with the budget on, a fighter at 12,000 units a second was out of his pane for 1.2 s at a stretch (seed 17), because each cut came back to a camera aimed for a zoom the comfort limit had not yet reached. That is fixed (the camera is now aimed for the zoom that is drawn), and the budget's real number can be read once Tools' table with it off and on is in. My position until then: **on, with the section 7 rule, after the table shows the budget costs no more than it saves on the clips that fail**; off otherwise.

## 10. As built (2026-10-12): the rule of section 7 and the stage of section 3, each behind its own switch, both off

**Switches** (build-time, not player options; `SplitView`): `set_launch_hold(on)` for section 7, `set_depth_dolly(on)` for the dolly and with it the stage. Both default off, and with both off the frame fields are equal to a clean HEAD export's to the bit (`depth_inert.gd`, 1,500 ticks, a scripted drift and a real-sim run). The sweep takes `--launch-hold` to run every row with the rule on (the shipped default is off, as for `--budget=off`).

**The rule (`SplitRig.launch_hold`), second version (2026-10-12, after Tools' first measurement).** A launched body whose speed, at the zoom of the 5% floor (0.48 at 720p), would move the picture by more than `LH_SPEED` = 0.03 of the width a tick (4,800 units a second at 1,280 wide) is not followed:
1. *Hold:* the launched pane's focus **and zoom** are frozen (the same `freeze` as a rush's pin), **and the shared (merged) camera is frozen with them**. He leaves the frame (a subject off the screen costs nothing); the attacker, who stands where the launch was, is in it. The frame is held for the whole flight.
2. *Back:* when he has landed, one cut brings the pane to him if the held frame is more than `LH_NEAR` = 0.9 of the width from him (a flash, once a launch); nearer than that the pane pans to him at no more than `LH_STEP` = 0.026 of the width a tick, the zoom at most 0.008 of a log unit a tick (0.03 of travel in all). In a flight so long that he would be over `LH_CUT_UNITS` = 20,000 units from the held frame, the same cut is made in the air and the frame is held again.
3. *Exempt:* a launch through buildings (a `launch_depth`, `chain_link` or `building_hit` for him in the last 2.5 s): that is a spectacle, the ordinary follow's with the dolly off (its aim lead and the governor) and a stage's with it on. A hold or a pan under way ends when a building event arrives.

**Why the first version did not move collapse-normal** (found by reproducing the clip's sim staging through the rig, `render/camera/tests/collapse_probe.gd` (`-- --hold` for the rule on), ticks 700 to 900, seed 12345): the shot is not a merged view, it is the *launch solo shot* (`mode solo`, `sep` 0 because a solo shot has no divider). The displayed camera in a solo shot is the *blend of the shared camera and the launched pane's own* (`_outputs`: `shared = blend(shared, own, smoothstep(solo_w))`) over the 19 ticks the pane takes to expand. The first version held only the pane's focus: the shared camera went on zooming out 4% a tick and travelling 200 units a tick under the blend, and the pane's own zoom went on to the floor. The victim of the staged blast leaves at 32,000 units a second. Measured on that staging, worst displayed travel in 700 to 900: **0.3234 of the width a tick off (166 ticks over 0.03), 0.0307 on (3 ticks over 0.03)**; the only cuts are the two in-air ones for the 60,000-unit flight.

**Measured** (`split_sweep` rows `launch hold on / off`, B flung along the street, 1,280 x 720, 60 ticks a second):

| Flight | Rule | Picture's travel while it holds | Cut frames | Off his pane at most | Back on his pane after landing |
| :--- | :--- | ---: | ---: | ---: | ---: |
| 6,600 u/s, 13,200 u (the commonest launch) | on | 0 (held) | 2: the first frame and the cut on landing | 118 ticks (2.0 s: the flight) | 0 |
| 6,600 u/s | off | n/a | 3 | 38 ticks | 0 |
| 9,000 u/s, 18,000 u | on | 0 | 2 | 119 ticks (2.0 s) | 0 |
| 3,000 u/s, 6,000 u | on | does not engage (0 holds) | 2 | 0 | 0 |

What the table is: with the rule on the picture does not move while the body is in the air, and he is back on his pane the tick he lands, by one cut. **What it costs is the picture of the body in flight** (he is off his pane for the flight, two seconds for a 13,000-unit launch) and one flash a launch (the cut and its dip). A viewer sees the attacker, the held frame and a streak leave it, then the landing. That is the decision for Orb flagged in section 7. The onset of the flight (the first ten ticks: the pane expanding, the re-frame limiter easing the step) reaches 0.045 in both arms in the rows and is not the rule's; on the clip's staging it is inside the rule's hold.

**The stage (`SplitRig` with `depth_dolly` on).** `launch_depth` and `chain_link` set a stage for the launched fighter: the frame of the building he is at and the next, centred on their midpoint, zoom the smaller of the shot's own and the one that puts both near edges (a building's half width 300 units) inside `STAGE_MARGIN` = 0.15 of the width each side, never under 0.5 at 720p. The focus eases to it with `STAGE_TAU` 0.25 s at no more than `STAGE_STEP` 0.03 of the width a tick (the vector, x and y together); the lag bound's whip moves out to 0.40 of the width, so the body may cross the stage while the frame holds. It holds when the next pair is already inside the stage there is, ends when he has landed and 54 ticks have passed (the lodge's hold), when he is farther than 0.46 of the width from the focus, or after 5 s, and hands back to the ordinary follow over 20 ticks (the lag bound closes from 0.41 to 0.20 of the width, the step still capped: no yank). The smash cut-in is not played with the stage on. Reduced motion: no stage (as before: the aim and the cuts of `depth-and-chains.md` section 4).

| Row (`stage chain of N`, dolly on) | Off his pane | Max travel in the chain (after the flight's onset) | Cut frames | Stage moves |
| :--- | ---: | ---: | ---: | ---: |
| 2 buildings | 0 ticks | (over before the window) | 0 | 2 |
| 3 buildings | 0 ticks | 0.0207 | 0 | 3 |
| 5 buildings | 0 ticks | 0.0327 | 0 | 5 |

The body leaves 4,500 units a second and keeps 0.7 of his speed a building (the sim's `keep`), so the first links go by faster than the relay's cap and the whip takes the focus along at his speed, and the later links are held. The moves are one a link (two buildings in frame), not one per two links as the first paper said: three buildings do not fit the margin at the zoom floor.

**Not built, in this batch:** the lodge push and the wall slam's and stack's stages (they need `lodge`, the wall outcome and `building_failing` from World), the `clear[i].cut` hand-off (Rendering), and any change to the travel budget's default.
