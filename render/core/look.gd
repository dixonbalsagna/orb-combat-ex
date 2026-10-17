class_name RenderLook
## Greybox look: every colour and dimension the renderer uses, in one place. Placeholder values until Art's palette
## and the procedural generator specs land; then these move to data files. The biome, prop and HUD colours are the
## prototype's (prototype/index.html BCOL and draw*), so the greybox reads like the prototype.

## Camera: vertical field of view in degrees. The reference camera's zoom z (pixels per world unit) is honoured
## exactly on the fighter plane (depth 0); anything in front of or behind it gets perspective parallax.
const FOV_DEG: float = 30.0
## The camera pitches the debug key steps through, in degrees (CameraRig): straight on (today's view, which already
## sees the ground from about 6 degrees through its raised lens), then Camera's raised side view and its three-quarter
## view (docs/camera/camera-v2.md section 8). Camera's own constants replace these when its mapping takes the pitch.
const PITCH_STEPS: Array = [0.0, 11.0, 49.0]

## World scale. Sizes that belong to the world (buildings, trees, craters, the ground's depth) are written at the
## original scale and multiplied by the sim's feature scale WS; mountain heights by MS; lengths along the planet by PS
## (sim/core/constants.gd, docs/world/scale.md). Fighter-scale sizes (the fighter plane's fine rows, particles, the
## fighters themselves) are not scaled.
const WS: float = SimConst.WS
const MS: float = SimConst.MS
const PS: float = SimConst.PS

## Depth layout, in world units along +z (toward the camera). Fighters, beams and particles live on z = 0.
const Z_TERRAIN_FRONT: float = 600.0     # the ground's shading reference in front (its top face brightens toward here)
## The ground runs toward the camera and past it, so there is no front face to see at any zoom: Z_FORE is past the
## camera at its widest pull-out (SimCamera.ZOOM_MIN) on viewports up to about 3,500 px tall. In front of the fighter
## plane the foreground rule (ground.gdshaderinc, fore_fall) keeps land and water below the sight line from the camera
## to the fighter plane, less FORE_DROP of their depth: nothing in front hides the fight, the camera is never inside
## the ground or under water, and a ridge or sea the camera is below shows as a soft face under its own profile.
const Z_FORE: float = 1.0e6
const FORE_DROP: float = 0.03
## ... and the fighter plane's profile it reads is the lowest within FORE_SPAN columns either side (at most 3) of where
## the sight line meets it. A narrow rise there (a slide's heap three columns long, ai seed 38) threw a ridge of the cap
## toward the camera that swept across the foreground, lit face and shaded face by turns, as the camera moved.
const FORE_SPAN: int = 2
## Near the lens the sight line meets the fighter plane far from the point it passes, and farther the nearer: a vertex
## of the ground there reads the plane's profile many columns from its neighbour's reading (the mesh's stride over 1 -
## t, t its depth over the camera's), and many columns from its own last tick's while the camera travels. In ai seed
## 106 (ticks 3343 to 3393, a camera 60 units up travelling 70 a tick over dunes) each tick read a different profile,
## and the near ground's edge jumped across the frame at 30 Hz. So where that step passes FORE_FAR.x columns the cap's
## profile gives way to the plane's lowest ground within FORE_LOW_REACH half widths of the camera, and has given way
## whole at FORE_FAR.y: a smooth surface that does not depend on where each sight line lands, and is never higher
## than the plane's ground in view. That lowest ground, and the camera's travel a tick, ease over FORE_LOW_S.
const FORE_FAR := Vector2(2.0, 6.0)
const FORE_LOW_REACH: float = 1.25
const FORE_LOW_S: float = 0.25
const WATER_FALL_BODY: float = 4.0   # water that fell this far under the foreground rule shows its body, not its surface
const Z_TERRAIN_BACK: float = -1125.0 * WS   # back of the crater rows: tier-4 rims reach about 2 x 4,300
## Ground rows are generated, not listed: spacing ROW_STEP0 at the fighter plane (fighter scale), growing by
## ROW_GROWTH of the distance, from Z_FORE in front to the horizon (FOG_FAR) behind. The row at exactly 0 reads the
## sim's profile (render/core/ground_field.gd). Columns coarsen with distance from the fighter plane, either side:
## STRIDES is [up to this |z|, column stride]. The finest run and the middle runs are split into chunks along the
## planet (CHUNK_COLS columns) so the frustum culls them; the coarsest is one mesh per copy.
const ROW_STEP0: float = 16.0
const ROW_GROWTH: float = 0.15
const STRIDES: Array = [[400.0, 1], [2000.0, 2], [-Z_TERRAIN_BACK, 4], [1.0e12, 8]]
const CHUNK_COLS: int = 320              # a multiple of the largest stride
const Z_BUILDING_FRONT: float = -140.0   # a building with no depth from the sim stands here (B1 gives z and d)
## Buildings in depth (World's B1, docs/world/buildings-in-depth.md): each stands at its sim z with footprint depth d,
## on the highest ground under its footprint, its footing extended down to the lowest. An implode sinks it straight
## down over IMPLODE_S from the ripple's delay (VFX draws the dust skirt). Row 0 stands in front of the fighter plane.
## Civilians stand on their building's street side, CROWD_GAP units out from its face and up to CROWD_DEEP more.
## A building between a pane's camera and a fighter is opened by one of two methods (docs/rendering/README.md,
## "Occlusion"): a round hole around him (HOLE_*), or the building cut down to a low stub (STUB_*).
const IMPLODE_S: float = 0.5
const HOLE_PX: float = 70.0              # the hole around a fighter: its least radius on screen,
const HOLE_BODY: float = 1.6             # ... or this many of his drawn heights if that is more (Camera's rule)
const HOLE_GAP: float = 30.0             # it cuts up to this far in front of him (and of the building he is aimed at)
const HOLE_JOIN: float = 0.6             # two fighters behind a block this near on screen (of its width) share one hole,
const HOLE_JOIN_S: float = 0.25          # ... the two holes growing into one over this long
const OCCL_MARGIN: float = 40.0          # a building counts as in front of a fighter when it is this near his sight line
const STUB_H: float = 40.0               # a cut-down building stands this tall
const STUB_MARGIN: float = 110.0         # buildings this near a fighter's sight line are cut down with the one hiding him
const STUB_IN_S: float = 0.2             # a building sinks to its stub over this long,
const STUB_OUT_S: float = 0.35           # ... and stands again over this long
## The foreground row's patch (Orb, 2026-10-11: "the larger see-through patch first ... allow a hybrid approach where the
## building also shrinks"). Row 0 stands between the camera and the fight, so it opens with ONE dithered window for
## the whole action: both fighters, the street between them, and what is travelling (where a fighter will be
## PATCH_LOOK_S ahead, a beam, a shot). Its radius round a fighter is PATCH_BODY of his heights, so the street under
## him and a height over his head show. It grows and shrinks by area: never more than PATCH_AREA_TICK pixels a tick in
## all (at 1024 by 768), under the frame analyser's area threshold of 21,824, and a reach or the radius shrinks only
## when nothing has asked it to grow for PATCH_HOLD_S, so it does not breathe.
## The hybrid: a patch larger than PATCH_BIG.x square fighter heights (about 9% of the screen at fight framing) lowers
## the buildings it covers (a building counts as under it by the share of its face covered, PATCH_UNDER), and at
## PATCH_BIG.y (about 15%) they are stubs: a small skirmish is a window, a big exchange a lowered building.
const PATCH_BODY: float = 2.2
const PATCH_PAD: float = 60.0            # round anything else it must show, world units
const PATCH_LOOK_S: float = 0.3
const PATCH_LOOK_MAX: float = 900.0      # ... at most this far ahead of a fighter, world units
const PATCH_EDGE := Vector2(0.55, 0.5)   # its edge: solid inside this share of its radius, thinning out over the next
const PATCH_AREA_TICK: float = 16000.0
const PATCH_HOLD_S: float = 0.75         # Camera's hold (docs/camera/city-in-depth.md A4)
const PATCH_RESEAT: float = 4.0          # the whole patch as last drawn more than this many half-widths of the view to one side of the camera, with a fighter in view: it is put on the fighters at once, as on a first frame (the pair was moved under a camera already there: a seek, a tool's pose). That far off, none of it is on the screen at any depth, so nothing seen is taken away; an end coming home across the screen still walks
const PATCH_R_MAX: float = 0.42          # its radius is never more than this share of the pane's height
const PATCH_BIG := Vector2(40.0, 70.0)
const PATCH_UNDER := Vector2(0.1, 0.35)
const PATCH_SINK_S: float = 0.45         # a building under a big patch sinks over this long,
const PATCH_RISE_S: float = 0.8          # ... and stands again over this, once the hold has passed with nothing sinking
const STUB_SPAN: float = 150.0           # the stretch between two fighters is kept clear in steps of this
## Fight lanes (ADR 0009): the streets painted on the ground from the lane table (render/core/lanes.gd), and the lane
## cue, a stripe on the ground at a fighter's depth in his colour, shown while it says something: the fighters are at
## different depths, or his depth is changing.
const STREET_WALK: String = "#84878f"
const STREET_ROAD: String = "#3f4249"
const STREET_KERB: String = "#5c5f67"
const STREET_LINE: String = "#c8c2a8"
const STREET_EDGE: float = 120.0         # the paint fades in over this at a district's ends
const STREET_DASH: float = 120.0         # a centre-line dash and its gap, each
const STREET_BAY: float = 190.0          # a kerb parking bay's length (a car is 2.5 bh)
const AVENUE_WALK: float = 60.0          # an avenue's sidewalk, each side of its carriageway (at most a fifth of its width)
## The rows' haze (building.gdshader row_haze): the most of the air's colour a far row takes, and the depths behind the
## fighter plane (to a building's front face) where it starts and is full. The front block (its faces at 300) takes
## none, the back block (1,350) about a sixth, the scenery row (2,550) about four tenths: the rows read as depth.
const ROW_HAZE := Vector3(0.5, 600.0, 2800.0)
## At stage 2 (a part gone) this share of a facade's bays is broken open, wall and all: the stage's other marks (the
## sheared top corner, the cracks) do not show from the street under a tower 60 floors tall with its windows out.
const DMG_HOLES: float = 0.18
## The contrast budget (building.gdshader 7b): on a look whose windows cover most of its wall, the most a pane and its
## wall may differ in relative luminance. The frame analyser counts a pixel that changes by a tenth; under that, a
## facade's own pattern cannot flip a pixel however the camera shakes, pans or cuts across it.
const PATTERN_BUDGET: float = 0.085
## City variety (Orb, homework 4: up close the towers were "a bunch of dark grid lines"; Art's palettes and facade types,
## docs/art/city-facades.md and data/art/city-looks.json; building.gdshader 7c), on the downtown and mid-rise towers.
## Two switches (2026-10-16). CITY_TINTS: A, the glass takes the sky, and B, Art's tints. CITY_FACADES: C, Art's facade
## types, the lobby storey and the set-back crown; it builds on the tints (it does nothing with them off). C waits for
## Art's re-cut of the fins under Legal's neighbour rule (RL-144: the budget holds between neighbouring elements as well
## as against the wall; render/tools/city_check.gd asserts it). A and B stay off after their own flash clips: in full
## effects they took signaturecity from 3 to 4 and rushcity's area reading from 3.5 to 4 (2026-10-17). With all of it on,
## the collapse clip in normal mode read 2.5 / 3.5 (docs/rendering/city-variety.md, "Measured"). Off, every tower draws
## as it did without them.
const CITY_TINTS: bool = false
const CITY_FACADES: bool = false
## GLASS_SKY: how far a tower's glass takes the sky's colour in its direction, at the glass's own luminance (no pane
## changes value), and the least height over the horizon it takes it from, in half screens (at noon the sky's blue, not
## the pale band at the horizon; a pane under the eye never takes the ground).
const GLASS_SKY: Vector2 = Vector2(0.4, 0.5)
## Each facade type's column of windows as a multiple of its look's (ribbon, punched, fins): a punched pane is 0.38 of
## its cell, a slit at downtown's 46 units.
const FACADE_PITCH: Vector3 = Vector3(1.0, 1.5, 1.0)
## A tower of at least CITY_BASE_FLOORS floors has Art's lobby storey, and a shaft, slab or block of at least
## CITY_CROWN_FLOORS Art's set-back crown: a mid-rise of four to six floors would be all base and crown.
const CITY_BASE_FLOORS: int = 5
const CITY_CROWN_FLOORS: int = 9
## The lobby storey's rows of panes and each pane up its row (from, to): two rows, so a pane, lit or not, is the size of
## a shaft's and the lit windows keep their area; the lintel over it in floors; the cornice line at the top of each of
## the crown's floors, as a share of the floor.
const CITY_BASE_ROWS: int = 2
const CITY_BASE_PANE: Vector2 = Vector2(0.12, 0.88)
const CITY_LINTEL: float = 0.1
const CITY_CORNICE: float = 0.08
const LANE_CUE_W: float = 14.0           # the stripe's half width in depth,
const LANE_CUE_LEN: float = 450.0        # ... its half length along the street,
const LANE_CUE_ALPHA: float = 0.5        # ... and its strength at full
const LANE_CUE_DZ: float = 40.0          # the fighters count as at different depths past this,
const LANE_CUE_VZ: float = 60.0          # ... and a depth as changing past this many units a second
const LANE_CUE_IN_S: float = 0.15        # it comes up over this long,
const LANE_CUE_OUT_S: float = 0.6        # ... and goes over this long
## The pair's mark (ground.gdshaderinc pair_mark_on; Game Design's docs/design/depth.md section 7; its look is VFX's,
## docs/vfx/depth.md section 6): in a match with depth on, a stroke on the ground from under one fighter to under the
## other while they brawl, so the line they stand on reads on any screen. The ground is seen at a low angle (a 20
## degree line is a 3 degree slope on screen), so the stroke is a wedge in width and in value: broader and brighter
## under the fighter nearer the camera. It is drawn against its own ground: a core a little lighter than the ground
## under it (a little darker on pale ground) in a rim a little darker, never more than a tenth of relative luminance
## from that ground, so no pan moves a bright line across the screen. No hue, and nothing moves along it.
const PAIR_MARK_W := Vector2(2.34, 3.08) # the stroke's width in pixels at its middle: the first, plus the second times the nearer fighter's size against his size on the plane (4 px at 54%, 6 at 119%),
const PAIR_MARK_TAPER: float = 0.6       # ... broader by this share at the nearer end and thinner at the farther, at 30 degrees
const PAIR_MARK_CORE: float = 0.09       # the core against its ground at the nearer end, in relative luminance,
const PAIR_MARK_GRAD: float = 0.07       # ... less this much at the farther end (the wedge in value),
const PAIR_MARK_RIM: float = 0.05        # ... the rim's darkening,
const PAIR_MARK_PALE: float = 0.55       # ... and ground lighter than this takes a darker core
const PAIR_MARK_STEADY: float = 0.45     # its strength while the line is steady,
const PAIR_MARK_TURN_DEG: float = 5.0    # ... full for PAIR_MARK_LOUD_S once the line has turned this much,
const PAIR_MARK_LOUD_S: float = 0.6
const PAIR_MARK_CUES: float = 0.3        # ... this while the lane cues' stripes are up as well (one mark, never three),
const PAIR_MARK_CALM: float = 0.6        # ... and steady at this, with no fade, under reduced motion or reduced flashing
const PAIR_MARK_LEVEL_S := Vector2(0.2, 0.5)   # its strength steps up over the first and down over the second
const PAIR_MARK_SEP: float = 300.0       # the two are a pair when this near along the street (4 fighter heights),
const PAIR_MARK_DZ: float = 6.0          # ... at depths this far apart or more,
const PAIR_MARK_H: float = 150.0         # ... and neither higher above his ground than this (2 fighter heights)
const PAIR_MARK_IN_S: float = 0.5        # it comes up over this long,
const PAIR_MARK_OUT_S: float = 0.5       # ... goes over this long,
const PAIR_MARK_HOLD_S: float = 1.0      # ... and once asked for stays this long, so a drift across PAIR_MARK_DZ and back does not blink it
## Camera's near-clip rule (docs/camera/city-in-depth.md section 1), in a match with depth on: a building of the
## patch's kind whose face is nearer the lens than NEAR_CLIP.x is not drawn, and one nearer than NEAR_CLIP.y stands as
## its stub, whatever the action's size: so near, it is in the lens, not something to open. A tall building is not
## touched by it (a tower opens its lobby or takes the patch); an open lobby's columns and beam thin out between the
## two distances and are gone nearer (OPEN_GHOST), so a travelling camera does not sweep solid columns across the lens.
const NEAR_CLIP := Vector2(300.0, 600.0)
const NEAR_SINK: float = 30.0            # a building not drawn is sunk this far under its footing
## VFX's clear query (docs/vfx/depth.md section 4): what the patch and the opened floors leave to be seen of a thing a
## building threw. Only a point nearer the camera than the fight there by more than CLEAR_GAP is ever hidden.
const CLEAR_GAP: float = 30.0
## The lobby (Orb, 2026-10-12: "'open floors' sounds like it would look the most natural, get that implemented", and
## "gaps between floors without realistic looking supports will make players lose their suspension of disbelief";
## docs/rendering/open-floors.md). In a match with depth
## on, a tower standing between a pane's camera and a fight at street level opens its lobby in that pane: one storey at
## the ground, two floors tall, open through the building, so the street behind shows under the tower. What stands says
## it is built so: a regular row of columns on every side, each a twelfth of its face wide; a deep beam on them; a warm
## lit ceiling. It fades in and out by stipple, inside the area budget and never faster than OPEN_FADE_S.
## The lobby is the building's and the patch is the fight's. What the lobby cannot show (a fighter above its ceiling),
## the see-through patch shows, as on a low building. A damaged tower's lobby opens too and shows its stage: the lamps
## out, then soot and a cracked column, then in a shell the bare frame with a column broken off. A tower whose lobby
## floors a brunt has cleared, or that is coming down, has no lobby: the patch alone. A tall building that is not a tower (a stack, a lighthouse, a hall, a chapel) has no
## lobby: the patch. No tall building is sunk to a stub in a match with depth on.
const OPEN_FLOORS_MIN: int = 5           # World's FLOORS_MIN: the buildings whose floors a brunt can clear (from about 7 fighter heights)
const OPEN_SHAPES: Array = ["shaft", "slab", "block", "stepped", "crown", "spire"]   # the towers with straight walls: these have a lobby
const OPEN_LOBBY_FLOORS: int = 2         # the lobby is one storey this many floors tall (one double-height storey, not two floors with a line between),
const OPEN_LOBBY_H: float = 280.0        # ... and on a tower of OPEN_TALL floors or more, as many floors as reach this height (at most OPEN_LOBBY_MAX)
const OPEN_TALL: int = 10
const OPEN_LOBBY_MAX: int = 4
const OPEN_COL := Vector2(0.0833, 4.0)   # the colonnade: a column's width as a share of its face (a twelfth: sturdy against the first build's thin posts), and columns a face (the two corners and those between, evenly)
const OPEN_BEAM: float = 26.0            # the beam the columns carry: this deep, under the lobby's top
const OPEN_CORE := Vector2(0.24, 0.4)    # the core in the middle of the lobby (the lift and stair shafts that hold a tower up: "a spine"): its width and depth as shares of the shell's,
const OPEN_CORE_TONE: float = 0.8        # ... its stone against the columns',
const OPEN_DOOR: float = 105.0           # ... and a lift door's height (three doors a face; a lit sign over each where the tower is whole)
const OPEN_CORE_GHOST: float = 1.0       # inside the patch the core is cleared like the columns (Orb, homework 4: see all the way through the inner lobby pieces)
const OPEN_CORE_VARY: float = 0.2        # ... and its width and depth vary this much either way from tower to tower (Orb: "some variety in size per building")
const OPEN_DAMAGED: bool = true          # a damaged tower opens its lobby and shows its stage in it (Orb, homework 4: "a damaged tower keeps its lobby"; off, as committed in 60f82149, it took the patch)
## What holds a brunt's cleared floor up (building.gdshader item 3; Orb, 2026-10-12): the frame's columns (OPEN_COL,
## the lobby's own) on the outermost walls, the plates' edges, and the core. The core's state is the building's hit
## points (World's reading, docs/world/destruction-state.md): cracked under CORE_HP.x of them, broken under CORE_HP.y.
const CUT_PLATE: float = 9.0             # the edge of a floor's plate over and under a cleared floor
const CORE_HP := Vector2(0.35, 0.15)
## A held hit's mark (docs/rendering/destruction-look.md 3.1). The floors a held blow covered (World's fdmg) keep a
## dent at the corner he came in by, where the cladding is gone and the frame shows, and cracks running from it.
## MARK_REACH: how far the dent reaches along the wall from that corner, on a floor that has taken none of its strength
## and on one that has taken all of it (units). MARK_TALL: the dent's height as a share of the floors hit, the same two
## ends. MARK_CRACK: cracks a mark (four at most), and how far they run as a multiple of the dent's reach. MARK_RUNS:
## the marks a building keeps drawn, its heaviest (the shader reads this many rows: four).
const MARK_REACH := Vector2(90.0, 330.0)
const MARK_TALL := Vector2(0.5, 0.9)
const MARK_CRACK := Vector2(3.0, 2.2)
const MARK_RUNS: int = 4
## A stage that spreads (3.7). A building's new damage stage, and a new mark, spread over its face from where it was
## hit instead of changing in one frame: SPREAD_AREA_TICK pixels a tick on a screen of 1024 by 768 (scaled with the
## screen's area; each building's wave has the whole of it), SPREAD_CALM of that with reduced flashing. What
## the wave has not reached after SPREAD_TICKS (as many more with reduced flashing) changes at once. Its edge is ragged
## in blocks of SPREAD_BLOCK units, a block as much as SPREAD_LAG late. SPREAD_ON false: every change is at once, as it
## was. A change with no event behind it (a replay seek, a late join, a tool) is always at once.
const SPREAD_ON: bool = true
const SPREAD_AREA_TICK: float = 8000.0
const SPREAD_CALM: float = 0.5
const SPREAD_TICKS: int = 150
const SPREAD_LAG: float = 0.35
const SPREAD_BLOCK: float = 31.0
const SPREAD_CELL_PX: float = 1200.0     # a window cell larger than this on a screen of 1024 by 768 (pixels; scaled with the screen's area) is taken in pieces no larger
## A building that a hit brings lower (it shrinks with its hit points, or loses its top floors) comes down to its new
## height at DROP_SPEED units a second, reached over its first DROP_RAMP ticks, instead of in one frame: at a close
## brawl a tower's top then uncovers about 6,000 pixels of sky a tick. SPREAD_CALM of that speed with reduced flashing.
## A change smaller than DROP_MIN units is at once. With no event behind the change (a seek) it is at once, and
## SPREAD_ON false puts back the change in one frame.
const NEAR_MID: float = 0.6               # Camera's rule for a near tower: the middle of the view, as a share of its width (a tower there, its near face inside NEAR_CLIP.y of the lens, opens its lobby)
const DROP_SPEED: float = 900.0
const DROP_RAMP: int = 8
const DROP_MIN: float = 8.0
const OPEN_FRAME_COL: String = "#8d95a1" # the columns' and the beam's stone, mixed half with the wall's own colour: a neutral pale, no fighter's hue
const OPEN_FAR: float = 0.7              # the far side's columns and beam, in the lobby's shade
const OPEN_CEIL: String = "#a39679"      # the lobby's ceiling, lit warm (a lit lobby, not the tower's dark inside),
const OPEN_LAMP: String = "#b7a785"      # ... and its lamp panels, a square a bay: 0.08 of relative luminance over the ceiling, inside the contrast budget (PATTERN_BUDGET), so a shaking camera does not flip rows of them. The shader holds them to the budget whatever is set here
const OPEN_GRID: float = 75.0            # a ceiling bay
const OPEN_GHOST: float = 1.0            # inside the patch a column or the beam is cleared (this share of its pixels gone): Orb, homework 4, "fighters are still obscured partly, would be better to see all the way thru the inner lobby pieces" (ghosts at 0.72 distracted; at 0.55 a fighter behind a column was veiled, the clip of 2026-10-12). Outside the patch the colonnade stands whole
const OPEN_FADE_S: float = 0.3           # the lobby and the patch on a tower fade in and out over at least this long,
const OPEN_CLOSE: float = 0.5            # ... a closing at this share of the area an opening may turn a tick,
const OPEN_HOLD_S: float = 0.75          # ... and only when nothing has asked for it this long (PATCH_HOLD_S)
const OPEN_SIDE: float = 75.0            # a tower answers when the capsule's own line (the fighters, the gap, what is travelling) comes this near being hidden by it: not for the room the patch leaves round them
const OPEN_HEAD: float = 30.0            # the patch takes over on a tower when the sight line to this far above a fighter's head passes over the lobby's ceiling
## Windows on the buildings' walls (building.gdshader): a row a floor, a column every WINDOW_PITCH along the wall, lit
## or dark by a hash. A floor's windows go out with VFX's blow-outs (PlanetView.blow_windows) and stay out.
const WINDOW_PITCH: float = 62.0
const WINDOW_LIT_SHARE: float = 0.3
const WINDOW_LIT: String = "#f3cf86"
const WINDOW_GLASS: String = "#2c3550"
const BUILDING_INSIDE := "#12131a"       # the inside of a tower seen through its cut floors (a tunnel)
## A building's look by World's damage stage (WorldStructures.stage; building.gdshader): 1 its windows are out, 2 it
## is cracked and a top corner is sheared off, 3 it is a shell (the bare frame, no lid, a broken top).
const DMG_BITE := Vector2(0.36, 0.3)     # stage 2: the sheared corner's share of the width, and of the standing height
const DMG_CRACK := Vector3(1.8, 16.0, 26.0)   # stage 2: a crack's width, the length of one of its jags and how far a jag swings (units)
const DMG_SOOT: float = 0.84             # stage 2 and 3: the walls keep this much of their colour
const DMG_RAG: float = 0.34              # stage 3: the broken top takes up to this share of the standing height
const DMG_PANELS: float = 0.2            # stage 3: the share of a shell's cells that keep their cladding
const DMG_FRAME := "#4b4a4f"             # stage 3: the bare frame, mixed into the wall's colour
const ROOF_OVER: float = 1.2             # a house's roof is this much wider than its walls
const CROWD_GAP: float = 20.0
const CROWD_DEEP: float = 120.0
## A building's figures (World's proposal, docs/world/crowd-cars-buildings.md section 1; Orb: "a little too clustered"):
## at most one per CROWD_FACE units of its face and at most CROWD_MAX, evenly spaced along it with a seeded jitter. The
## rest of its people are inside: the sim's counts (casualties, budgets, menace) are untouched, and a building shows as
## many of its figures as it has people alive.
const CROWD_FACE: float = 40.0
const CROWD_MAX: int = 12
## The crowd is drawn in chunks (render/core/crowd_chunks.gd; Performance's audit, 2026-10-16): runs of figures whose
## spots lie within CROWD_CHUNK of each other along the planet, each culled by the camera. CROWD_CHUNK_PAD: how far a
## drawn figure reaches from its spot, boosted, cowering or turned (59 units tall, at most twice that boosted).
const CROWD_CHUNK: float = 4000.0
const CROWD_CHUNK_PAD: float = 400.0
const Z_TREE_MIN: float = -120.0 * WS
const Z_TREE_MAX: float = -30.0 * WS
const TREE_W: float = 26.0 * WS
const ROOF_H: float = 16.0 * WS
const Z_PARTICLES: float = 10.0
const Z_BEAMS: float = 6.0
## The ground continues behind the crater rows to the horizon as one surface (no separate backdrop): the far terrain
## blends in from the band's own heights over FAR_BLEND and is the same planet (each column's base height and biome,
## with relief). Its last eighth before FOG_FAR fades into the sky, so its far edge never shows.
const FAR_BLEND: float = 900.0 * WS
const MEANDER: float = 600.0 * PS        # how far (in x) the far land's biomes wander with depth
const FOG_FAR: float = 15000.0 * WS       # far enough that the planet fills the lower screen from the ceiling
## Far relief per biome: [height multiplier on the base terrain, relief amplitude at the original scale]; the relief is
## multiplied by WS (MS for mountains) and smoothed across biome borders.
const FAR_RELIEF: Dictionary = {
	"ocean": [1.0, 40.0], "plains": [1.0, 45.0], "city": [1.0, 12.0], "village": [1.0, 30.0],
	"forest": [1.0, 70.0], "desert": [1.0, 55.0], "mountains": [1.25, 300.0],
}
const FAR_SMOOTH_COLS: int = 24 * 4      # half width of the smoothing, in columns
const SNOW_FROM: float = 560.0 * MS      # far peaks whiten above this height ...
const SNOW_FULL: float = 900.0 * MS      # ... fully by this
const SNOW := "#dfe3ec"
const PLANET_COPIES: int = 2             # ground and water copies each side of the camera (props use 1)

## Planet-scale cues. Horizon curvature: how far the world behind the fighter plane sags at the screen edge, as a
## fraction of screen height (for the depth-weighted bend in render/shaders/bend.gdshaderinc). It grows from
## CURVE_NEAR at close zoom to CURVE_WIDE at wide zoom (log scale between ZOOM_CLOSE and ZOOM_WIDE), plus CURVE_HIGH as
## the camera climbs from HIGH_FROM to HIGH_TO (fractions of the flight ceiling).
const CURVE_NEAR: float = 0.035
const CURVE_WIDE: float = 0.10
const CURVE_HIGH: float = 0.10
const ZOOM_CLOSE: float = 0.3
const ZOOM_WIDE: float = 0.015
const HIGH_FROM: float = 0.2 * SimConst.CEILING   # camera y where the sky starts turning to space
const HIGH_TO: float = 0.85 * SimConst.CEILING

const BIOME: Dictionary = {
	"ocean": "#2a6b98", "plains": "#5f9140", "city": "#6c7079", "village": "#7c8e4b",
	"forest": "#2e6a35", "desert": "#cfa85c", "mountains": "#7e766a",
}
const SEA_FLOOR := "#5a5346"
const CRATER := "#4a4237"
const CRATER_DESERT := "#a98544"
const EJECTA := "#9a8a70"                # rims and aprons, dusty
const CRACKED := "#2b2a2c"               # cracked pavement (S.crack), its crack lines
const CHAR := "#1d1715"                  # scorched ground at full burn
const HEAT_LO := "#c2381c"               # a cooling groove
## A groove chars as it cools (terrain.gdshader): while its heat (ImpactFx.heat, 1/e in 1.6 s) is above CHAR_FRESH.y
## the ground under the glow keeps its own colour, and the char comes in as the heat falls to CHAR_FRESH.x: from
## about 1.4 to 4 s after a weak beam, 3.3 to 6 s after the strongest. The burn used to turn a broad strip of ground
## dark in one tick. Under reduced flashing (or reduced motion) the groove has no glow (HEAT_CALM 0, the EP's ruling of
## 2026-10-17: it is a safety mode) and its char is drawn at CHAR_CALM, so a camera moving over a groove changes little.
const CHAR_FRESH := Vector2(0.04, 0.2)
const HEAT_CALM: float = 0.0
## Under reduced flashing (or reduced motion) a new crater also keeps the ground's own colour at first. Its earth, its
## ejecta and its char spread from its centre to the edge of its apron over CRATER_CALM_S of match time, so a blast
## does not turn a third of the screen dark in one tick. (Measured on the collapse clip: with the ground's darkening
## held, reduced mode read 2.5 where it read 3.5; docs/rendering/flash-sources.md.) Ground an older crater already
## coloured stays as it is. Normal mode is not changed: there a fresh crater's glow covers it while it cools.
const CRATER_CALM_S: float = 1.5
const CHAR_CALM: float = 0.35
const HEAT_HI := "#ffd27a"               # a fresh groove from a strong beam
## Ground field widths across the band's depth (render/core/ground_field.gd). Bowls and grooves take their sizes from
## the sim (each crater record's r, depth and rim; the scorch constants in WorldCrater); only these are the renderer's.
const FURROW_W_R: float = 0.3            # a furrow's half width across the band, per unit of its crater's r ...
const FURROW_W_MIN: float = 20.0 * WS    # ... and at least this
const GROUND_SPREAD: float = 60.0 * WS   # half width across the band of dents with no record (dropped craters, clips)
## A new crater opens from its centre to the edge of its apron over CRATER_OPEN_S of match time: its bowl, its colours
## and its glow together, in every match, where they came in one tick. The fighter plane's row opens with it, so the
## band has no step there; for those ticks the ground drawn under a fighter standing in it is above the sim's.
const CRATER_OPEN_S: float = 0.4
const RUBBLE_EDGE: float = 30.0 * WS     # a rubble heap eases off over this depth past the range it spans
const RUBBLE_TINT_H: float = 20.0        # heap height at which the rubble tint is full
const RUBBLE := "#6f675d"                # rubble: broken concrete and brick dust
const SHORE_COLS: int = 16               # a land vertex this many columns from water (twice the band mesh's widest stride) keeps its level
## A water chunk is drawn only while a column holding water lies within this many columns of its own (PlanetView
## _water_show; Performance's audit, 2026-10-16): the shore's reach or the far meander's, whichever is wider, and a
## few columns of slack, as water spreads a column a step at most and a second pane may see a change a frame late.
const WATER_REACH_SLACK: int = 4
const OUTLINE_MIN_PX: float = 0.75       # ... and the thinnest it gets on a fighter deep in the rows
const SHADOW_W: float = 56.0             # a fighter's ground shadow: across, and
const SHADOW_D: float = 26.0             # ... in depth, in world units at his feet
const SHADOW_ALPHA: float = 0.38         # its strength under a fighter on the ground,
const SHADOW_FADE_H: float = 900.0       # ... easing to a quarter of that (and half again as wide) this high above it
const SHADOW_LIFT: float = 2.0           # it lies this far above the ground, clear of it
const OUTLINE_PX: float = 1.5            # fighter outline width on screen, in pixels (placeholder until Art sets it)
## The sky's clouds, and its reaction to a fighter at tier 3 or more (docs/design/rule-of-cool.md feature 12;
## render/shaders/sky.gdshader): the clouds part in a tall opening above him and the sky there takes his colour.
const CLOUD_PERIOD: float = 32.0         # cloud cells round the planet (the pattern wraps with it)
const CLOUD_COVER: float = 0.52          # the share of the cloud band that is cloud
const CLOUD_WIND: float = 0.004          # cells a second the clouds drift
## The clouds part for a fighter at tier 3 or more (sky.gdshader): the gap's half width and half height in half
## screen heights; how far above him its middle sits and the lowest and highest that middle goes, in the cloud band's
## heights above the horizon (the band is solid from 0.3 to 1.3); and how far off this pane's screen he may be before
## nothing parts for him (as a share of the screen's width, fading out over it).
const SKY_REACT_R := Vector2(0.7, 0.24)
const SKY_REACT_AT := Vector3(0.45, 0.46, 1.0)
const SKY_REACT_OFF: float = 0.15
const SKY_REACT_S: float = 1.5           # the reaction eases in and out over this long
## Battle damage on the mannequin (docs/design/rule-of-cool.md feature 1; fighter_body.gdshader): marks by wound
## region that stay and build with the wounds' stages. Colours are plain palette numbers, like the mesh's.
const DAMAGE_GRIME: String = "#2a2220"   # scuffs on clothing and gear, and a tear's frayed edge
const DAMAGE_BRUISE: String = "#6b3a62"  # bruises on skin
const DAMAGE_GROW_S: float = 0.6         # a stage's marks grow in over this long
## Which of Art's outfits (data/art/damage.json) each fighter wears, by roster id, until the roster names one.
const DAMAGE_OUTFIT: Dictionary = {"PROTAGONIST": "protagonist", "RIVAL": "empress"}
const DAMAGE_OUTFIT_DEFAULT: String = "protagonist"
## The seed of each outfit's marks, in 97ths (where the scuffs, bruises and tears fall on the body). They are the
## numbers the two fighters' first names gave before the seed moved to the outfit, so the roster's rename moved no
## mark, and a later one will not either.
const DAMAGE_SEED_97: Dictionary = {"protagonist": 16, "empress": 48}
const OUTLINE_F_MAX: float = 2.5         # the most a corner's outline reaches past the width (outline_bake.gd)
const OUTLINE := "#0a0d14"               # fighter outline colour
const SHORE_FLOOD: float = 24.0          # dry land at most this far below the water beside it is drawn under that water (World's shore step is at most 0.25 bh)
const WATER := Color(30.0 / 255.0, 110.0 / 255.0, 175.0 / 255.0)
const WATER_SURFACE := Color(0.42, 0.68, 0.9, 0.55)
const SKY: Array = ["#111a3e", "#4b4483", "#d9776b", "#f4b87a"]   # top to horizon
## The sky's gradient is anchored to the horizon (the far edge of the ground), in half-screen heights above it: the
## horizon colour at the line, the lower colour SKY_LOWER_AT above it, the upper at SKY_UPPER_AT, the top by
## SKY_TOP_AT. As the camera climbs the band thins by up to SKY_THIN times (a thin atmosphere rim seen from high up).
const SKY_LOWER_AT: float = 0.12
const SKY_UPPER_AT: float = 0.55
const SKY_TOP_AT: float = 1.45
const SKY_THIN: float = 5.0
## The haze by depth (Art: docs/art/sky-and-distance.md layer 5; Orb: "the sky and stars would appear as a close fog that
## obstructed view of the mountains"). The ground and the water mix toward the horizon band's colour by their depth
## behind the fighter plane, not by their height on the screen: none inside HAZE_AT[0] (the fight's own ground); HAZE_MIX[0] by HAZE_AT[1]; HAZE_MIX[1] by
## HAZE_AT[2]; HAZE_MIX[2] by HAZE_AT[3]; eased between. The distances stretch as the camera climbs (the air thins as the
## sky's rim does). Right at the horizon line, beyond HAZE_AT[1], a thin glow: HAZE_LINE.x half-screen heights deep, as
## much as HAZE_LINE.y of the horizon's colour.
const HAZE_AT := Vector4(1500.0, 2500.0, 6000.0, 40000.0)
const HAZE_MIX := Vector3(0.2, 0.45, 0.8)
const HAZE_LINE := Vector2(0.04, 0.5)
## The sea takes the sky (Art's layer 8): the water hazes toward the horizon band at HAZE_SEA of its value, and at its far
## edge it ends there instead of dissolving into the sky, so the sea meets the sky in one clear step at the horizon.
const HAZE_SEA: float = 0.9
## The far mountains' value ladder (Art's layer 6): the ground hazes toward the horizon band's colour at HAZE_VALUE of
## its value and HAZE_SAT of its saturation (Art: at noon the farthest ridge no more than about 60% as bright as the
## horizon band; at sunset a silhouette against the glow; at night darker than the band), so further is lighter and
## greyer and a ridge never reaches the colour of the sky behind it. The water hazes toward the band itself.
const HAZE_VALUE: float = 0.6
const HAZE_SAT: float = 0.7
## The world takes the sky's key (Art: docs/art/dynamic-sky.md section 6; data/art/sky.json _world_light): each
## layer's colour times a multiply in linear light, plus a small lift at night so the dark ground is cool, blended with
## the sky's own phase, hold and smoothstep (SkyDrive.world_at), the mood's multiplies on top. Lit windows, the lane
## colours, auras, the keylines, flashes, particles and the HUD are never dimmed. WORLD_LIGHT scales every tint toward
## none, and the windows' lit share toward WINDOW_LIT_SHARE (1: Art's; 0: the world as it was before the sky moved).
## It lands at 0 (EP, 2026-10-16): at 1 it tipped the near-lens and divider movement of AI clips over the flash line
## (docs/rendering/sky-and-distance.md); it follows as its own batch.
const WORLD_LIGHT: float = 0.0
const WORLD_LAYERS: Array = ["ground", "buildings", "trees", "water", "civilians", "bodies"]
## The stars (Art's layer 1): on the sky's sphere, turning STAR_TURN sky-widths (tan units) a lap; none below STAR_FLOOR
## (from x to y half-screen heights above the horizon line); and only where the sky behind is dark: full below
## STAR_DARK.x relative luminance, none above STAR_DARK.y. Their strength is the key's (the data's), whatever the height.
const STAR_TURN: float = 6.0
const STAR_FLOOR := Vector2(0.4, 0.8)
const STAR_DARK := Vector2(0.02, 0.08)
## The dynamic sky (render/core/sky_drive.gd; Art's docs/art/dynamic-sky.md and data/art/sky.json, which hold the
## keys, the blend paths, the drift, the rate limits and the mood's colours and least durations). SKY above is the
## sunset key and the fallback when the data is missing. These are the numbers the data gives only in words (from
## Art's reference code, keys.mjs) and Rendering's own. Bands in Art's order: horizon, lower, upper, top.
const SKY_FRENZY: Array = [0.10, 0.10, 0.25, 0.18]   # frenzy: the horizon toward ember, the lower toward deep, the upper toward the top, the top toward deep
const SKY_RUIN: Array = [0.60, 0.60, 0.40, 0.25]     # ruin: the horizon, lower and upper toward smoke, the top toward ash
const SKY_RUIN_STARS: float = 0.7                    # ... and the stars thin by this share (to 30%)
const SKY_FRENZY_BY_BAND: Array = [0.0, 0.4, 1.0]    # the frenzy asked for by the sim's mood band: calm, tense, frenzied
const SKY_STEP_PHASE: float = 5.0e-5     # a pane's sky is not worked out again while its place has moved less than this of a lap and nothing else has
const SKY_TOWN_GAP: float = 2400.0 * WS  # buildings further apart than this along the ground are two towns
const SKY_TOWN_SCAN_S: float = 0.5       # how often the towns' damage is read
const SKY_GLOW_FULL: float = 0.5         # a town with this share of its buildings cracked or worse glows fully
const SKY_GLOW_IN_S: float = 1.0         # a town's glow comes into a pane's view over at least this long, however fast the camera brings the town in (Legal's RL-122)
const SKY_GLOW_MIX: float = 0.35         # how far a full glow takes the horizon toward ember (Art)
const SKY_GLOW_SHAPE := Vector3(0.39, 0.015, 0.04)   # the glow: half its width in half screen heights (0.22 of a 16 by 9 screen across); it rises over y above the horizon line, is full to z, and is gone at the top of the horizon band

const TOWER := "#565e70"
const TOWER_DEAD := "#3f424a"
const HOUSE := "#a67c52"
const HOUSE_DEAD := "#5d4a37"
const ROOF := "#7a3b2e"
const TREE := "#1f4a26"
const TREE_TOP := "#2f6b35"
## Civilians, thinned and muted (Orb, 2026-10-11: "Thin and mute it", so the fighters stand out; World thins their
## number in data). They were bright shirts with a black outline, 85 units tall against a fighter's 75. Now:
## - smaller than a fighter: CROWD_SCALE times the 17-unit figure is 59 units, about four fifths of his height;
## - grey: each shirt is one of CROWD's quiet tones leaned CROWD_DISTRICT of the way to its district's wall tone
##   (RenderShapes), so a crowd sits in its street's own colours. No tone is a fighter's hue (teal, orchid, moss,
##   coral): lane colours stay the fighters' alone;
## - a softer outline than a fighter's keyline.
## They still grow as the camera zooms out so they stay about CROWD_MIN_PX tall, but only up to CROWD_BOOST_MAX, which
## stops at a fighter's own height.
const CROWD: Array = ["#8b8f97", "#a09a8c", "#777d89", "#b3ada0", "#6c7078", "#978b7a", "#9498a0", "#7d7468"]
const CROWD_DISTRICT: float = 0.35
const CROWD_SKIN: Array = ["#f1c9a5", "#8d5a3b"]
const CROWD_LEGS := "#2b2f3f"
const CROWD_OUTLINE := "#343842"
const CROWD_SCALE: float = 3.45         # 59 units: about four fifths of a fighter's height (75)
const CROWD_SPREAD: float = 50.0 * WS    # how far past a building's width its people stand
const CROWD_MIN_PX: float = 12.0
const CROWD_BOOST_MAX: float = 1.25
const CROWD_OUTLINE_PX: float = 1.1
## Evacuation (render/core/crowd_flight.gd, World's `evacuate` event): people who flee a blow run away from it, faster
## the closer they were, drifting back behind the building row; a share look back once; each fades out at the end of
## its run. The run cycle plays in the figure's plane, as a runner seen side-on. Speeds and the stride are a person's
## (fighter scale); the blow's reach is the world's.
const RUN_SPEED: float = 420.0          # units a second: a sprint for a life-size person
const RUN_NEAR: float = 0.6             # up to this much faster for people right at the blow ...
const RUN_NEAR_R: float = 200.0 * WS    # ... falling to none this far from it
const RUN_TIME: float = 3.2             # seconds of running before a runner is gone (each 75% to 125% of this)
const RUN_FADE: float = 0.45            # the last seconds of a run, fading out
const RUN_BEHIND: float = 60.0          # they drift this far back past their own row's face (into the row)
const RUN_DEST_MAX: float = 6.0         # the longest run to shelter in another building (they speed up past it)
const RUN_YAW: float = 20.0             # degrees they turn from face-on (back-on, running left) toward where they run
const RUN_LOOK_SHARE: float = 0.15      # the share that look back once ...
const RUN_LOOK_S: float = 0.35          # ... for this long, slowing
const RUN_STRIDE_HZ: float = 2.8        # the run cycle (render/shaders/crowd.gdshader): strides a second,
const RUN_LEG_SWING: float = 0.75       # leg and arm swing (radians), forward lean and bob (figure units)
const RUN_ARM_SWING: float = 0.9
const RUN_LEAN: float = 0.2
const RUN_BOB: float = 1.1
## Survivors near a blow (a crater, a beam's scorch or a building hit) are startled for STARTLE_S: no idle hop, arms
## over the head, a small crouch and a tremble (figure units), until the flight takes them or they calm down.
const STARTLE_R: float = 150.0 * WS
const STARTLE_S: float = 4.0
const STARTLE_ARMS: float = 2.4          # radians the arms swing up, over the head
const STARTLE_CROUCH: float = 0.1        # share of the height they drop
const STARTLE_TREMBLE: float = 0.3
## Combat's cue events (data/combat/finishers.json `cues`) as placeholder poses on the fighter rig
## (render/core/fighter_view.gd): each blends in over CUE_IN, holds, and blends out over CUE_OUT by `dur` seconds of
## sim time (hit-stop holds it). front and back: the hands' targets in the body plane (x forward, y up from the pivot,
## fighter units; the shoulders are at (12, 14) and (-12, 14)); lean: radians, negative leans forward (the stance lean's
## sign); crouch and step: units down and forward; head and yaw: radians the head, and the whole body, turn toward the
## camera; tremble: units of shake; flare, spark and guard: a brief chest flare, a spark at the front hand, the guard
## glow; badge: the stance badge's size (a tell); ring_other: a ring around the other fighter (circle). The body
## signals (lean, crouch, yaw, flare) carry the pose at gameplay zoom, where the arms are a few pixels. Cues not listed draw nothing here (camera, banner and HUD cues).
const CUE_IN: float = 0.08
const CUE_OUT: float = 0.14
const CUE_RING_S: float = 0.45
const CUE_POSES: Dictionary = {
	"brace": {"dur": 0.45, "front": [8, 8], "back": [-8, 6], "lean": 0.2, "crouch": 9.0, "flare": 0.45},
	"glance": {"dur": 0.3, "front": [28, 18], "lean": -0.1, "spark": 1.0},
	"tell": {"dur": 0.4, "back": [2, 26], "lean": 0.32, "crouch": 6.0, "step": -8.0, "badge": 1.8},
	"turn_read": {"dur": 0.45, "front": [2, 24], "lean": -0.14, "head": 0.5, "yaw": 0.7},
	"overextend": {"dur": 0.5, "front": [34, -6], "back": [-24, 2], "lean": -0.4, "crouch": 3.0, "step": 12.0},
	"circle": {"dur": 0.45, "front": [20, 6], "lean": -0.28, "ring_other": 0.6},
	"guard_set": {"dur": 0.45, "front": [32, 14], "back": [10, 18], "lean": -0.2, "step": 8.0, "guard": 1.0},
	"struggle": {"dur": 1.2, "front": [14, 26], "back": [-8, 24], "crouch": 8.0, "tremble": 2.4},
	"last_look": {"dur": 0.9, "front": [-2, 22], "lean": 0.08, "head": 0.6, "flare": 0.25},
	"breaks_hold": {"dur": 0.55, "front": [26, 30], "back": [-26, 28], "lean": 0.24, "flare": 0.9},
	"holds_on": {"dur": 0.7, "front": [18, 22], "back": [-4, 22], "crouch": -3.0, "flare": 0.3},
	"catch": {"dur": 0.45, "front": [30, 20], "lean": -0.18, "step": 8.0, "spark": 0.8},
	"glance_back": {"dur": 0.5, "lean": -0.12, "head": 2.0, "yaw": 0.4},
	"pursue": {"dur": 0.5, "front": [6, 2], "back": [-26, 8], "lean": -0.42},
	"reset": {"dur": 0.4, "front": [22, 0], "back": [-20, -4], "crouch": 5.0},
}
## Head flashes (render/core/flash_view.gd; Art's spec docs/art/flash-prototype-spec.md, data data/art/flashes.json).
## The layouts, timings, priorities, colours of the info flashes and Legal's rules are Art's data; these are the
## drawing's own numbers from the spec. Sizes are in layout units: a twelfth of the fighter's head size, the data's
## own unit. For Art's figures that is also the spec's hundredth of a body height; the placeholder's head is larger
## (a 20-unit head on a 90-unit body), so the head rule keeps every flash as Art drew it around the head.
const FLASH_UP: float = 2.0             # the flash's origin above the head centre
## The spec puts the flash just behind the head. The placeholder's hair crest is deep and would swallow it, so the
## flash draws in front (FLASH_Z) with the head's own disc cut out (never over the face). Glyphs rise by any excess
## of the head's radius over Art's (FLASH_ART_HEAD_R; none with the head unit).
const FLASH_Z: float = 24.0             # world units in front of the fighter plane, past the head and hair
const FLASH_ART_HEAD_R: float = 6.0     # Art's head radius in layout units (head size 12)
const FLASH_GLYPH_AT: Array = [[2.0, 5.0]]                 # a glyph's place from the origin; hazard's two bangs:
const FLASH_GLYPH2_AT: Array = [[-5.5, 5.0], [9.0, 5.0]]
const FLASH_OUT: float = 0.1            # seconds a preempted flash takes to fade (spec section 7)
const FLASH_JITTER: Dictionary = {"hurt": 0.04}     # irregular jitter per shape, as a share of the body height
const FLASH_JITTER_HZ: float = 18.0     # how often the jitter moves
const FLASH_SWEEP: Dictionary = {}     # degrees a layout sweeps over its first pulse's swell (rage no longer does)
const FLASH_BLADE_W: float = 2.3        # half widths of blades and wedges, layout units (thin, after the playtest)
const FLASH_WEDGE_W: float = 5.2
const FLASH_GLYPH_SCALE: float = 1.1    # glyph units to layout units at full size
## The placeholders' shape families: P1 draws as the Protagonist, P2 as the Anti-hero; Alt+F (Alt+Shift+F for P2)
## cycles a fighter through all four. The colours are Art's (flashes.json `accents`, `emotion_colours`).
const FLASH_FAMILY: Array = ["P", "A"]

const SKIN := "#efc7a2"
const ARM := "#e6b995"
const LEGS := "#1b1f2a"
const CAPE := "#7a1414"
const EYE := "#111111"
## Afterimages (the sim's `after` events: a dodge, an escape, each tick of a rush; ParticleView): the thin outline of
## a figure where the fighter was, in his lane colour. How long one shows at most (the event's own life may be
## longer), its quad, its opacity at the start, how far behind the fighter's depth it is drawn, and how far the
## fighter must have moved off it before it shows (nothing at the first distance, all of it at the second).
## An after-image is shown for five ticks, so a rush (one a tick) has five at once and no more (Legal's m12: at most
## five whole-figure ghosts round one fighter from all sources; at 0.1 s a rush had six). The half tick is margin: a
## particle's age is a sum of ticks, and VFX's tally (render/vfx/ghost_tally.gd after_ticks) rounds this down to the
## same five. AFTER_MAX holds the five whatever sends them: past it the oldest are not drawn (ParticleView).
const AFTER_LIFE: float = 5.5 / 60.0
const AFTER_MAX: int = 5
const AFTER_SIZE := Vector2(48.0, 88.0)
const AFTER_ALPHA: float = 0.5
const AFTER_BEHIND: float = 14.0
const AFTER_CLEAR: Vector2 = Vector2(24.0, 60.0)
## The guard arc (guard.gdshader; FighterView): a held guard, drawn in front of the fighter on the side he faces, in
## his lane colour. The quad's size and the arc's radius; how far the quad's near edge is from the pivot (behind it,
## so the arc wraps the front of the body); its opacity; how fast it comes up and goes; a perfect block's flash.
const GUARD_SIZE := Vector2(52.0, 88.0)
const GUARD_RADIUS: float = 46.0
const GUARD_NEAR: float = -8.0
const GUARD_ALPHA: float = 0.9
const GUARD_UP_S: float = 0.08
const GUARD_DOWN_S: float = 0.15
const GUARD_FLASH_S: float = 0.3
## Stance colours for the badge above each fighter: aggressive, defensive, evasive, escape.
const STANCE_COL: Array = ["#ff5a4a", "#4aa8ff", "#5ed17a", "#b58cff"]
const STANCE_SHORT: Array = ["ATK", "DEF", "EVA", "ESC"]
const STANCE_LONG: Array = ["AGGRESSIVE", "DEFENSIVE", "EVASIVE", "ESCAPE"]

## Staging (Orb: fighters "cheat out" like stage actors, docs/ep/vision.md). A fighter is turned toward the camera by
## a pose angle in degrees from a pure profile: TURN by state ("sliding" while a knockback slide runs), plus
## TURN_STANCE by stance when free or locked; the head leads by TURN_HEAD. A facing flip turns through facing the
## camera in TURN_TIME seconds; pose changes ease at TURN_RATE_DEG per second. Art tunes these (and a fighter's
## turn_scale) for its turnarounds.
const TURN: Dictionary = {"free": 30.0, "locked": 24.0, "charging": 36.0, "launched": 34.0, "down": 38.0, "sliding": 28.0}
const TURN_DEFAULT: float = 30.0
const TURN_STANCE: Array = [-5.0, 6.0, 0.0, 4.0]   # aggressive squares to the opponent; defensive opens to the camera
const TURN_HEAD: float = 12.0
const TURN_TIME: float = 0.16
const TURN_RATE_DEG: float = 240.0
const SLIDE_LEAN: float = 0.35           # radians: a sliding fighter stays upright, leaning back against the slide
const SLIDE_CROUCH: float = 6.0          # and crouches this much
const HIDDEN_ALPHA: float = 0.22
const HIT_FLASH_S: float = 0.12
## A hit the shared flash register refuses the white body for: the outline lights in this colour for HIT_FLASH_S (a
## thin line, not a flash). (A beam it refuses, and every beam under reduced flashing, is drawn calm by VFX's beam look: the
## same beam at a share of its strength, with a slower rise.)
const HIT_EDGE := "#e8ecf2"
## A granted hit (Legal's RL-122): the body takes a strong light tint of its own colours, HIT_TINT of the way to white,
## with the outline lit, where it went pure white. One body is tinted at most HIT_TINT_BODY times in a second and
## the two together at most HIT_TINT_ALL, beside the register's own budget; the hits past that light the outline.
const HIT_TINT: float = 0.6
const HIT_TINT_BODY: int = 3
const HIT_TINT_ALL: int = 4
## What Rendering's flashes cover, for the flash register's weights (VfxFlashRegistry weighs a flash by its area against
## a quarter of the standard's 341 by 256 window, and counts none whose luminance step is under a tenth). Sizes are in
## world units on the fighters' plane (SimHost.flash_px turns them into pixels at the camera's scale). Each is an
## estimate of the part that changes by a tenth of full luminance, and FLASH_STEP of that change against what is behind.
const FLASH_BODY_AREA: float = 0.27     # a body's silhouette, as a share of FighterView.HEIGHT squared
const FLASH_HEAD_R: float = 17.0        # a head flash's shapes, as a disc of this radius
const FLASH_GUARD_FILL: float = 0.55    # the guard arc's fill, as a share of GUARD_SIZE's rectangle
const FLASH_GLOW_R: float = 0.7         # the share of a soft glow's radius bright enough to count
const FLASH_CUE_R: float = 70.0         # a cue flare's largest radius (fighter_view.gd)
const FLASH_CLASH_R: float = 70.0       # a clash flare's radius, before the 20 pixels it adds (beam_view.gd)
const FLASH_WINDOW_DIAG: float = 426.0  # px: the longest strip one 341 by 256 window holds, so a beam's length counts up to this
const FLASH_STEP: Dictionary = {"body_hit": 0.7, "head_flash": 0.5, "guard_flash": 0.25, "cue_flare": 0.5, "beam": 0.6, "beam_clash": 0.7}
## A beam comes and goes once (docs/rendering/flash-sources.md): its strength rises over BEAM_RISE_S, holds, and falls
## to nothing at its end.
const BEAM_RISE_S: float = 0.1
## The most pixels of beam (at the flash register's scale, 1024 by 768) a bright beam's tail may uncover in a tick as
## it draws back from the firer (BeamView.tail_at). A beam that reaches a defender across the planet is tens of
## thousands of units long, and a tail that kept pace with its length left the firer's screen in one tick at nine
## tenths of its strength: the whole thick core going out at once, a counted change for the frame analyser (ai seed 1,
## tick 2153: 121% of the area threshold on that one tick). The analyser's own floor for a frame to count toward a
## change is 0.2% of the picture (1,573 pixels); this is under it.
const BEAM_TAIL_PX: float = 1000.0
## A clash's flare and its two beams rise over CLASH_RISE_S and fall over the clash's last CLASH_FALL_S.
const CLASH_RISE_S: float = 0.15
const CLASH_FALL_S: float = 0.25
## The pan haze: while a pane's camera travels along the ground faster than PAN_HAZE_FROM screen widths a second, the
## buildings lose their windows and marks and melt toward the sky behind them, complete at PAN_HAZE_FULL, as far as
## PAN_HAZE_MIX. It comes in over PAN_HAZE_IN_S and clears over PAN_HAZE_OUT_S. A facade's window grid and its edge
## against the sky flip a great many pixels a tick when they sweep past; a jump of more than PAN_HAZE_CUT widths a
## second is a cut, not travel. It ships off (PAN_HAZE_DEFAULT): it is a large change to how a town looks in a rush,
## and Orb's to decide. --panhaze turns it on and --nopanhaze off, whichever the default is.
const PAN_HAZE_DEFAULT: bool = false
const PAN_HAZE_FROM: float = 0.35
const PAN_HAZE_FULL: float = 0.9
const PAN_HAZE_MIX: float = 0.7
const PAN_HAZE_IN_S: float = 0.1
const PAN_HAZE_OUT_S: float = 0.6
const PAN_HAZE_CUT: float = 20.0
## ... but a whip pan hazes every building in every match (PAN_WHIP_ON), whatever the switch: from PAN_WHIP.x screen
## widths a second to whole at PAN_WHIP.y, melting as far as PAN_WHIP_MIX into the sky and ground behind, in over
## PAN_HAZE_IN_S and out over PAN_HAZE_OUT_S. In the signature clip in the city (seed 12345) a pane's camera went from
## standing to 3.5 widths a second in four ticks past a row of houses (736 to 740), and a launch threw another at 10 to
## 20 widths a second through the towers (428 on): a facade swept that fast flipped 40,000 pixels each way a tick, and
## which way won turned every tick. Hazed at PAN_HAZE_MIX the pale towers still did; melted fully they do not.
const PAN_WHIP_ON: bool = true
const PAN_WHIP := Vector2(1.5, 2.5)
const PAN_WHIP_MIX: float = 1.0

static var _colors: Dictionary = {}


## The colour-blind presets (UI's `colour_vision` option; Art's data/art/colour-vision.json): a preset gives each
## fighter another lane colour, and everything Rendering draws in a fighter's aura colour takes it (the aura, the
## body's accent, his beams, after-images, cue flare, guard arc and lane cue), because all of it asks col() for the
## sim's aura string. raw: the sim's aura strings, by slot; cols: UI's lane colours for them (UiHud.lane_colors).
## With the option off the two are the same colours, nothing is remapped, and col() is exactly as it was. Returns
## whether the mapping changed (the fighters' views are then built again: main._on_lane_colors).
static var _lanes: Dictionary = {}


static func set_lanes(raw: Array, cols: Array) -> bool:
	var next: Dictionary = {}
	for i in range(mini(raw.size(), cols.size())):
		var hex: String = str(raw[i])
		if hex != "" and not (cols[i] as Color).is_equal_approx(Color.html(hex)):
			next[hex] = cols[i]
	if next == _lanes:
		return false
	_lanes = next
	return true


## A CSS hex colour ("#fff", "#3d8fdc") as a Color, cached: the sim's colours are strings.
static func col(hex: String) -> Color:
	if not _lanes.is_empty():
		var lane = _lanes.get(hex)
		if lane != null:
			return lane
	var c = _colors.get(hex)
	if c == null:
		c = Color.html(hex)
		_colors[hex] = c
	return c
