# The destruction look: what the picture reads from a building's state (2026-10-12)

Owner: Rendering and Technical Art. **Paper,** except where a line says **built**. Asked by the EP for Orb: "realistic building destruction is absolutely a priority, gaps between floors without realistic looking supports will make players lose their suspension of disbelief, so lets get some kind of compromise in there so smashing opponents through multiple buildings is climactic, catastrophic, visually appealing, and part of the gameplay hook."

It is written against World's `docs/world/destruction-state.md` (the state: breach, failing, fallen) so that World's windows B and C have agreed states, and beside `docs/world/destruction-hook.md`, Game Design's `docs/design/buildings.md` (the ladder, the lodge, the wall slam, the falling stack), Camera's `docs/camera/buildings-in-frame.md` and VFX's `docs/vfx/building-stages-plan.md` and `floors-plan.md`. Sizes are estimates, in windows of mine (a window is one gated batch).

## 0. The short version

1. **One frame, drawn in every state.** A tower has a frame: four columns a face, a plate a floor, a core in its middle. The lobby, a breach, a cleared floor, a shell and a ruin all show that same frame, so what is left standing always looks like it is carrying load. The lobby, the cleared floor and a held hit's mark are **built**.
2. **The fight sees four floors.** At a close brawl the frame is 626 units tall, about four floors of a downtown tower. A tower's top is far out of the picture. So every state has to read between the street and the fourth floor, or send something down into the picture: glass, dust, a shadow, the floors themselves.
3. **World's three questions** (its section 5) are answered in section 8: one interval a floor is enough, with one rule about what the interval is; the sim should hold the fall's time; and what the warning shows.
4. **The flash check shapes it from the start.** Every change of mine is spread by area as the patch and the lobby are: a breach opens outward from the body, a stage spreads from the hit (**built**, section 3.7), a floor comes down over a quarter of a second, and nothing large changes brightness in one tick.
5. **A known fault:** a crater made in the middle street shows in the front street. Section 7 has why and the fix.

## 1. What is drawn today, and what does not read

| State (World's) | Drawn today | At fight framing |
|---|---|---|
| Stage 1, windows out | Every pane dark, soot above it | Reads on the floors in view |
| Stage 2, a part gone | Soot, two cracks, one top corner sheared | **Barely reads:** the sheared corner is a thousand units over the frame. Only the soot and a crack are seen |
| Stage 3, a shell | The frame with the dark inside between, a broken top line | Reads: the street floors are a dark grid |
| A cleared floor (`fmask`) | Front and sides gone, the dark back wall. **Built in this batch:** the frame's columns, the plates' edges and the core stand in the gap | Reads when the cleared floor is one of the lowest four |
| A tower's loss of height (`curH`) | The box is cut off at its height | **Does not read at all:** the top is out of the picture |
| Falling (`building_fall`) | The building sinks into the ground over 0.5 s, VFX's dust skirt | Reads as a building going down a hole, not as a collapse |
| Fallen | Not drawn; the rubble heap is ground | A gap in the street |

- **A real match hardly ever puts a body in a building:** 1.4 to 2.5 building hits a match (World's count). Nearly all the destruction a viewer sees is a blast's or a beam's, from far off, in one tick. That is Encounter's and Game Design's to change; the picture has to be worth it when it happens.

## 2. The frame: columns, plates, a core

- **Columns:** four a face, the two corners and two between, each a twelfth of the face wide (`OPEN_COL`). They run up the whole building on the same lines, so a lobby's columns stand under a cleared floor's.
- **Plates:** a floor's slab shows as an edge 9 units deep (`CUT_PLATE`) wherever the wall is gone over or under a standing floor.
- **The core:** a box in the middle of the footprint, 0.24 of the width and 0.4 of the depth (`OPEN_CORE`), with three lift doors a face. It is what really holds a tower up, and it gives an opening a spine.
- **The core's state is the building's hit points** (World's reading): whole, cracked under 35%, broken under 15% (`CORE_HP`). No new sim state.
- **How it is drawn:** there is no geometry for any of it. Columns and plates are the pixels of the box's own walls that are kept where the rest is thrown away. The core is found by meeting the eye's ray with its box, a pixel at a time.
- **Only the outermost wall carries columns.** A stepped tower is boxes one inside the other; each part knows from what height it is the outermost (`RenderShapes.outer_from`).

**Built** (this batch and 60f82149): the lobby (whole towers; a damaged tower's lobby is behind `RenderLook.OPEN_DAMAGED`, off, Orb has the question) and the cleared floor. Not built: everything below.

## 3. The states, and what each would look like

### 3.1 A held hit: the wall slam's mark (World's window A): **built** (2026-10-13)

- **Reads:** `fdmg`, the damage a floor has taken, as a share of that floor's strength (`WorldBrunt.floorStr`). For the side only, the `floor_hit` and `building_hit` events.
- **One mark for each run of floors** a held blow covered (a body covers two). It is at the corner he came in by, on the face toward the fight and round onto the side wall.
- **The dent:** the cladding is gone to the dark inside, a window cell at a time, and the frame shows in it: the edge of each floor's plate and the frame's columns, in the stone a lobby's are. They are the same columns on the same lines as the lobby's and a cleared floor's.
- **The cracks:** three jagged lines from the corner, fanning out. Dark on a pale wall, the stone's tone on a wall as dark as its empty panes, so they show on both.
- **Panes** are out on those floors and on the floor over and the floor under.
- **Its size is the damage.** The dent reaches 90 units along the wall on a floor barely touched and 330 on one about to break (`MARK_REACH`), and is half to nine tenths as tall as the floors hit (`MARK_TALL`). The cracks run 2.2 times as far (`MARK_CRACK`). A second blow on the same floors grows the mark from what it was.
- **It stays,** because it is read from the state: a replay seek or a late join draws the same mark. A floor that breaks stops being a mark and is a cleared floor.
- **It grows from the corner** at the pace of section 3.7, when an event of that frame says a blow landed. With no event (a seek) it is whole at once.
- **The side is not in the state.** `fdmg` says which floors, not from where. The side comes from the event's direction; after a seek or a late join the building chooses one for itself, the same every time. World's `fhole` could carry it: section 8.
- **A building keeps four marks drawn,** its heaviest (`MARK_RUNS`). At stage 3 none is drawn: a shell's face is bare frame already.
- **A wall slam sends no `lodge` event** (World sends one only when the body ends inside the building). The mark needs none: `building_hit` and `floor_hit` carry the height and the direction.
- **VFX:** the glass and the dust at the point, falling to the street for a second or more. **Camera:** its held stage centred on the mark. **Audio:** the building is heard to take it. (Theirs; not in this change.)

### 3.2 A breach: a hole on a floor that keeps its plate (window B)

- **Reads:** `fhole`, three numbers a floor since World's re-cut (75c9894f): the slot's two ends as fractions of the half width, and how much of the story is gone. Section 8, answer 4: the look can be built from it.
- **Drawn:** on that floor the wall is gone inside the interval and stands outside it, with a ragged edge in steps. In the hole: the columns that fall inside it, bare; the plates over and under; the core if the interval crosses it, in its state; the dark inside behind. Where the interval reaches the building's edge the side wall is open on that floor too, so the way in or out shows from the side.
- **It opens outward from the body,** by area, over six ticks or more: the patch's rule. A hole that appears whole in one tick is a counted change at fight framing.
- **Tier reads as size:** a body-wide hole and cracks on its neighbours at a low tier; most of the plate gone and the columns left at tier 4. That is World's width rule and needs nothing more from me.
- **The body in the breach** (the lodge) is drawn at his own depth, inside the building, seen through the hole.
- **Size:** one window, with window B. The rows of the window texture that carry the marks (3.1) carry the slots too: a run of floors with one slot is two texels.

### 3.3 A cleared floor (`fmask`): **built**

The gap shows its columns on the outermost walls, the plates of the standing floors over and under it, and the core against the dark inside. The fighter flying through is drawn in front of the core.

### 3.4 A lean (derived; nothing stored)

- **Reads:** the breaches and `hp / maxhp` (World: toward the side with the larger breach, once the core is under half).
- **Drawn:** everything above the lowest breach is sheared sideways by its height above it: a tilt of a few degrees about that floor. Three degrees over the three floors in view is 24 units, a third of a fighter: it reads against the upright towers beside it.
- **It moves slowly** (a degree a second at most), so it costs nothing in flashes.
- **Size:** small, after 3.2. Two numbers a part in the window texture's fifth row, which has room.

### 3.5 Failing: the warning, then the stack comes down (window C)

- **Reads:** `failT` (negative is the warning), `failDir`, `failK`. A pure function of hashed state, so a seek and a late join show the same fall. That is how everything else of mine works, and I want it this way (World's question 2).
- **The warning** (1.5 s or more). The lean grows by a degree or two. The building's lit panes go dark a floor at a time upward from the breach, 0.15 s a floor: a signal that only darkens, a little at a time. VFX's dust trickles from the broken floors and glass falls. I do not shake the building or the camera: a tower's window grid jittering is the worst thing I could put on the screen.
- **A pancake.** The stack above the front comes down a floor each 0.25 s. Drawn: the block above moves down a floor's height over the step, eased; the floor it lands on is crushed to a dark band a fifth of its height with the columns buckled out of it; the plates stack. At fight framing the block's travel is about 7,000 pixels a tick for a tower as wide as the screen's half, inside the 16,000 budget.
- **A tip.** The part above the breach turns about its hinge to 25 degrees over a second, then falls. Drawn as a rotation of every part's corners above the hinge, in the box's own shader. Under reduced motion it pancakes instead.
- **VFX:** dust at each landing floor, growing over half a second or more, never a white burst (see section 5). **Camera:** a pull-out during the warning and a held wide while it comes down. **Audio:** the groan and each landing.
- **Size:** two windows, with window C: the moving block and the crushed floors, then the tip.

### 3.6 Fallen: the aftermath that stays

- **Reads:** `alive` false and the building's own numbers. Nothing new.
- **Drawn:** today nothing stands. It should leave a ruin: the core's stump a floor or two high with a ragged top, a few columns broken at different heights, the lowest plate hanging. World's rubble heap is the ground under it.
- **Size:** one small window.

### 3.7 A stage that spreads: **built** (2026-10-13). A face that peels: not yet

- **Before:** a blast or a wall slam changed a building's whole face in one frame.
- **Now the new stage spreads from where the building was hit.** It grows as a disc on the screen that takes 8,000 pixels a tick on a screen of 1024 by 768 (`SPREAD_AREA_TICK`, scaled with the screen's area). Inside the disc the building is at its new stage, outside at the stage before. So at any zoom the picture changes by no more than that area in a tick.
- **Where it starts:** where a lodged body lies; the edge a brunt or a shot came in by, at its height; for a blast, the building's side toward the blast at the height of the blast's crater (the foot when no crater came with it).
- **A wall goes a window cell at a time.** The disc is measured at each cell's middle, so a cell's panes go out together, and each cell is up to 35% late (`SPREAD_LAG`), so the edge is ragged. Roofs and blank walls go in blocks of 31 units.
- **Pace:** the disc is 226 pixels across its radius after a third of a second and 391 after a second. A face that fills the screen takes about 1.6 seconds. Each building's wave has the whole area. With reduced flashing the area a tick is halved (`SPREAD_CALM`).
- **A second change is a second wave** inside the first, which keeps what it has not reached at the stage before it. A window cell large on the screen is taken in pieces. The floors a blow-out puts out go as a wave too.
- **It ends after 150 ticks** (2.5 seconds; 300 with reduced flashing): what the wave has not reached by then changes at once. That is the far end of a tower that crosses the whole screen and was hit at the screen's edge.
- **Only with an event.** A stage that changes with no event in the same frame (a seek, a late join, a tool) changes at once: a seek shows the state and replays nothing.
- **The top comes down:** a building that a hit brings lower comes down to its new height at 900 units a second (`DROP_SPEED`), not in one frame.
- **Not built: the face that peels.** Going to a shell, the cladding should leave the frame a panel at a time behind the wave, with VFX throwing a panel for each. The cells the wave takes are the hook for that; the panels are VFX's.
- `RenderLook.SPREAD_ON` false puts back the change in one frame.

## 4. Through and through: one launch, tick by tick

| When | What happens | Whose |
|---|---|---|
| The launch | The camera sets its stage: the body at the trailing third, the first two links in frame, and holds | Camera |
| He meets the face | The hit-stop (the sim's). The breach starts at the body and opens outward over six ticks. Glass from that floor and its neighbours | World's `floor_hit` with `x0`, `x1`; the hole is mine; the glass is VFX's |
| Inside | He is drawn at his depth, crossing in front of the core, between columns. Dust hangs in the hole | Mine; VFX |
| The far face | The breach reaches the far edge: the side wall opens on that floor, and debris leaves with him | Mine; VFX |
| The street between | The stage moves on to the next link, slowly, in the gap | Camera |
| The last building | The lodge: he stops in the breach, the push in on it, the deepest hole, the core cracked or broken behind him if the dump took its hit points that low | The sim's hold; Camera; mine |
| After | The marks stay. A building whose core went under World's line starts its warning | World's state; mine |

## 5. What the flash check does to it

| Rule | Why |
|---|---|
| Any change of mine to a building spreads by area: at most 16,000 pixels a tick at 1024 by 768, together with the patch and the lobbies | The frame analyser counts a change of 21,824 pixels |
| No change of mine is a brightness step over a large area in one tick. A wall going to sky, a tower going to dust, a face going dark: each is spread or eased | A dark tower leaving a bright sky is the largest step there is |
| Nothing of a building jitters. A tower's grid of panes moved a pixel flips a quarter of the screen | Measured on the camera's shake before the contrast budget |
| Dust is the colour of what it comes from and near its value, and it grows; it is never a pale burst over a dark tower | VFX's; said here because it is the largest thing in the picture when a stack comes down |
| Dust takes the air's light at that place and hour (the sky's own colours): warm at dusk, nearly dark at night, and it dims what is behind it rather than lighting the frame | A cloud lit white at night is a flash, and the sky already gives every material its light |
| Under reduced flashing a step that moves becomes a step that fades, and takes longer | The crater's ease is the pattern |
| The camera does not travel while a building changes | Camera's own rule; it leaves the whole budget to the destruction |

**To measure with Tools:** a clip a state. A wall slam at tier 1; a launch through one tower and a lodge at tier 3; a chain of three; a tower failing by pancake and by tip; a blast taking a tower to a shell with the stage spreading. Each in both modes, at fight framing.

## 6. Whose is what

| | Rendering | VFX | World (state) | Camera | Audio |
|---|---|---|---|---|---|
| The frame in every opening | Draws it | | `hp / maxhp` for the core | | |
| A held hit's mark | The floors' look | Glass, dust | `fdmg` (in the tree) | The held stage | The hit |
| A breach | The hole, opening outward | Dust in it, debris out the far side | `fhole` (B) | The stage, the push at a lodge | |
| A lean | The shear | | Nothing stored | | |
| The warning | The lean, the lights going out | Dust, glass | `failT` under 0 (C) | The pull-out | The groan |
| The stack coming down | The moving block, the crushed floors, the tip | Dust at each landing | `failT`, `failDir`, `failK` (C) | The held wide | Each landing |
| The ruin | The stump and the broken columns | Smoke that stays | `alive`, the rubble heap | | |

## 7. A known fault: a crater in the middle street shows in the front street

- **What is seen:** with depth on, a crater made by a fight in the middle street is drawn on the fighter plane's ground, in the front street, and the middle street stays flat. It is in the stills of 2026-10-12 as a grey smear in the road in front of the tower.
- **Why:** with depth on the sim keeps a row of ground a street (`S.deformZ`), and a crater belongs to its row. The renderer's ground reads the plane's row for every depth, and the crater's paint (its char, its ease) has no depth: the crater event carries none yet.
- **The fix:** the ground at a depth reads that depth's row. The mesh's strips already stand at their own depths, so each strip takes its row's heights; between two rows the height is blended across the block. The crater's paint gains a depth and is drawn only within its own street. The crater event gains a `z` with Simulation's depth window, as planned.
- **Size:** one window, with the first crater in depth. Until then the fault shows only in a scratch build with depth on.

## 8. World's three questions

1. **One interval a floor, or two?** One is enough for the picture, with one rule: the interval is the span of the plate the body swept on that floor, clipped to the building, not a hole centred on a point. A lodge is then a slot from the face he entered to where he lies, with him in it. A pass-through is a slot from side to side, which is the true picture of a body going through a floor. A hole centred on the body's x at the hit would show the way in and no way out. Tier then reads in how tall the slot is (floors) and in how much is left standing in it, not in its length. If World would rather keep width as the tier's measure, two intervals are needed (one from each side) and I would draw both.
2. **Who times the fall?** The sim. I read `failT`, `failDir` and `failK` and draw them. A fall timed by the renderer could not hurt a fighter, and would differ after a seek.
3. **What the warning shows:** section 3.5. The lean, the lights going out upward from the breach, VFX's dust and glass. No shake.
4. **World's re-cut of window B (75c9894f, 2026-10-12): yes, the look can be built from it.** `Building.fhole` is three numbers a floor: the slot's two ends as fractions of the half width, and how much of the story is gone. That is the span swept and the share, which is what section 3.2 draws: on that floor the wall is gone between the two ends, as tall as the share says; the columns that fall inside the slot stand bare; the plates over and under show; the core shows where the slot crosses it. A slot that reaches the building's edge opens the side wall there. It reads `fhole` from the state, so a seek agrees, and it opens at the pace of 3.7 from the `floor_hit` event's `x0`, `x1`. **One thing I would ask of it:** a held hit writes its side there too (both ends at the edge he came in by, nothing gone). Then a mark's side is in the state and survives a seek; today only the event knows it. I draw the slot on the face toward the fighter plane, as World's events place it (`faceZ`).

## 9. Order and sizes

| Step | Size | Waits for |
|---|---|---|
| The frame in the lobby and in a cleared floor | **Built** | |
| 3.1 A held hit's mark, a floor at a time | **Built** (2026-10-13) | |
| 3.7 A stage that spreads | **Built** (2026-10-13); the face that peels is not | VFX's panels, for the peel |
| 3.2 A breach | One window | World's window B |
| 3.4 A lean | Small | 3.2 |
| 3.5 Failing: the pancake, then the tip | Two windows | World's window C |
| 3.6 The ruin | Small | Nothing |
| 7 The ground in depth | One window | Simulation's depth window (the crater's `z`) |

3.1 and 3.7 were taken first (2026-10-13): they needed nothing new from anyone, and they are what a viewer sees most, since blasts and held hits are nearly all of today's destruction. Next is 3.2, with World's window B.
