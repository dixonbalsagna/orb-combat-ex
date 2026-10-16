// Buildings and their roofs, every depth row (docs/world/buildings-in-depth.md; "Occlusion" and B3 in
// docs/rendering/README.md): flat like every prop, with three things of its own.
// 1. The hole. A fighter behind a building is kept in view: whatever of a building lies nearer the camera than he
//    does is cut away inside a dithered circle around him on this pane's screen (hole: his chest in world space and
//    the radius in pixels; hole_near: the view distance to cut up to, which stops short of the building he is aimed
//    at, so that one stays whole). When two fighters fight behind a block the hole stretches toward the other one
//    (hole_to: its other end and the radius there; hole_near's second number: the view distance to cut up to there),
//    so one opening covers both and the gap between them. pane_world.gd sets these each frame.
// 2. The stub. The other occlusion method: a building in front of a fighter is cut down to a low stub. Every vertex
//    above the height in stub_tex (a float texel a building, this pane's, read by the instance's index) is lowered to
//    it, so the box sinks to a solid stub with its own top, and a roof (instance colour alpha 0) folds flat under it.
// 3. The floor cut. World's skyscrapers lose floors to a brunt (Building.fmask): a cleared floor under a standing one
//    is a tunnel. Its front and side walls open (discard) and the back wall shows its dark inside, so the fighter is
//    seen flying through the building at his own depth. What holds the floors above is drawn (Orb, 2026-10-12: a gap
//    with no real-looking supports breaks belief): on the building's outermost walls the frame's columns stand in the
//    gap (the lobby's own, item 9, so they line up) and the plate of the floor over it and under it shows its edge;
//    behind them, against the dark, stands the core, whole, cracked or broken by the building's hit points. The mask comes from cut_tex, a float texel a building read by
//    the instance's index (planet_view.gd; a MultiMesh's own custom data is half floats here, too coarse for it): r and
//    g hold floors 0 to 47 (24 bits each), b floors 48 to 61 plus 16,384 times the top standing floor, a the height
//    of a floor (0: nothing to cut). The box's top is that floor's ceiling, which gives the base.
// 4. Windows. Every wall carries a row of windows a floor and a column every win_pitch along it, each lit or dark by
//    a hash of the building and its cell. They come from win_tex, two float texels a building: a bit per floor whose
//    windows are out (packed as the floor cut's mask), the height of a floor (0: none), the wall's base and the floors
//    standing. A floor's windows go out with VFX's blow-outs (planet_view.gd blow_windows) and show as dark holes, so
//    the facade matches the glass VFX throws. Thin windows fade into the wall before they alias.
// 5. Damage stages. World's stage of a building (WorldStructures.stage, read from state every time it changes) comes
//    in win_tex's second texel, and each has its own look, so a still tells them apart:
//    1 windows out: every pane is a dark hole with soot above it, and from far off the wall is darker by their share.
//    2 a part gone: the walls are sooted and cracked, and one top corner is sheared off in steps, the roof's end
//      over it too; the far wall is sheared less, so its dark inside shows through the gap.
//    3 a shell: the cladding is stripped to the frame (a post a column, a slab a floor, a panel left here and there)
//      with the dark inside between, there is no lid, and the walls end in a broken line. planet_view.gd hides the
//      roof. From far off it is a low dark block.
//    4 fallen: not drawn (planet_view.gd sinks it and hides it, as before).
// 6. Shapes (render/core/shapes.gd). A building is a few PARTS, each an instance of the one box: its tiers, its cap,
//    its roof. win_tex's third texel shapes the box: the top's width and depth as a share of the base's (a taper: 1 a
//    box, less a frustum, near 0 a pyramid or, on one axis only, a gable's ridge) and a lean that slopes the top down to
//    nothing toward one side (a shed's facet, a saw tooth). Walls and tops take the true normal of the deformed face,
//    for their shade and for the culling below. A roof is a part whose instance colour has alpha 0, as before.
// 7. District looks. The same texel's fourth number is the look (settlements.json looks): a column of windows every
//    (or one of shapes.gd's extra looks, a stone tower's slits): a column of windows every look_a.x along the wall, the pane's span in its cell and the share of cells that have one; look_b the pane's span
//    up the row, the strips a row and flags (a clerestory under the roof only, a door, shutters, door panels); the
//    glass, the bright glass and the trim. A floor taller than a row of windows carries several (win_tex's second
//    texel, a). Too far to draw panes, a wall is the average of its wall and its glass, so it does not change value
//    as the camera pulls back.
// 7b. The contrast budget. A look whose windows cover most of its wall (flag 16: downtown's bands, mid-rise's strips)
//    is stripes at fight framing. Stripes of pale wall and dark glass flip a quarter of the screen brighter and
//    darker on every tick the camera shakes (measured: 14% each way a tick in a hit-stop, where the old dark walls
//    flipped 1%). So on such a look a pane takes its glass's colour only as far as pattern_budget of relative
//    luminance from its wall, and a row whose panes are out has its wall as dark as they are: a burnt-out floor is a
//    dark band, a burnt-out tower is dark, and neither is stripes. Lit panes are few and keep their light.
// 8. Row haze. A part takes the air's colour by how far behind the fighter plane its front face stands (row_haze), so
//    the back block and the scenery row read as depth. The front block takes none.
// 9. The lobby (RenderLook.OPEN_*; Orb, 2026-10-12: real-looking supports). The camera's, not damage: in a match with depth
//    on, a tower in front of a fight at street level opens its lobby in this pane (stub_tex's g, b and a: the share
//    of it that is open, its top as a world y, and the tower's share of the patch). Under the top the walls are gone,
//    front, sides and back, so the street behind shows under the tower. What stands says it is built so: on every
//    side a regular row of columns, each open_col.x of its face wide; a beam open_beam deep on them; and, seen from
//    under it, a warm lit ceiling (the eye's ray is met with the ceiling's plane, so it lies flat over the lobby with
//    its lamps in rows). It fades in by stipple: a share of the lobby's pixels is through, the rest still the wall.
//    Only the tower's shell at the street carries the colonnade (win_tex's fourth texel: the shell's footprint from
//    this part); a part inside the shell, or stuck onto it, is simply gone under the lobby's top (g is negative on it).
//    Inside the patch (the hole's capsule) a column or the beam is thinned to a ghost, not removed.
//    In the middle of the lobby stands the core, the lift and stair shafts that hold a tower up: a box of the
//    columns' stone a step darker, with lift doors. There is no geometry for it: the eye's ray through an opened
//    pixel of the shell's wall is met with the box, and the pixel is drawn as the core where it hits.
//    A damaged tower's lobby opens too, and shows its stage: from "windows out" the lamps are out; from "a part
//    gone" the stone is sooted with the walls and one front column is cracked; a shell has the bare frame's tone, no
//    ceiling, and that column broken off above a stump.
//    The patch on a tower: a building that never has a lobby (b under -1.5e9) is holed as ever. A tower is holed only
//    by its share of the patch (a: the hole's radius is scaled by it), which planet_view.gd raises when the fight is
//    above the lobby's ceiling or the tower is damaged.
// An instance with nothing to cut and no part gone keeps back-face culling (its back faces are thrown away in the
// vertex stage), so only the cut towers and the buildings at stage 2 and 3 pay for their insides. tools/cull_check.gd
// compares that with the rasterizer's own culling.
shader_type spatial;
render_mode unshaded, cull_disabled;

#include "res://render/shaders/color.gdshaderinc"
#include "res://render/shaders/bend.gdshaderinc"
#include "res://render/shaders/skycol.gdshaderinc"

uniform sampler2D stub_tex : filter_nearest, repeat_disable;
uniform sampler2D cut_tex : filter_nearest, repeat_disable;
uniform sampler2D win_tex : filter_nearest, repeat_disable;
uniform float windows = 1.0;         // 0: blank walls
uniform float win_pitch = 62.0;      // RenderLook.WINDOW_PITCH
uniform float win_lit_share = 0.3;   // RenderLook.WINDOW_LIT_SHARE
uniform vec4 win_lit : source_color = vec4(0.95, 0.81, 0.53, 1.0);
uniform vec4 win_glass : source_color = vec4(0.17, 0.21, 0.31, 1.0);
uniform vec4 hole[2];          // xyz: a hidden fighter's chest (world, as drawn); w: the hole's radius in pixels (0: none)
uniform vec4 hole_to[2];       // xyz: the hole's other end (the chest again for a round hole); w: the radius there
uniform vec2 hole_edge = vec2(0.8, 0.25);   // a hole's dithered edge: solid inside this share of its radius, thinning out over the next (the foreground row's patch has a softer one: RenderLook.PATCH_EDGE)
uniform vec2 hole_near[2];     // cut what is nearer the camera than this (view distance): at the chest, at the other end
uniform vec4 inside : source_color = vec4(0.07, 0.07, 0.09, 1.0);   // RenderLook.BUILDING_INSIDE
uniform vec2 dmg_bite = vec2(0.36, 0.3);       // RenderLook.DMG_BITE and the rest: see look.gd
uniform vec3 dmg_crack = vec3(1.8, 16.0, 26.0);
uniform float dmg_soot = 0.84;
uniform float dmg_rag = 0.34;
uniform float dmg_panels = 0.2;
uniform vec4 dmg_frame : source_color = vec4(0.29, 0.29, 0.31, 1.0);
uniform float roof_over = 1.2;
uniform float pan_haze = 0.0;        // 0 to 1: this pane's camera is travelling fast (PaneWorld.pan_haze); the wall loses its panes and marks and melts toward the sky behind it
uniform float pan_mix = 0.7;         // RenderLook.PAN_HAZE_MIX: how far it melts at full haze
uniform vec3 wl_mul = vec3(1.0);     // the world's light (SkyDrive.world_at's buildings layer); lit panes are never dimmed
uniform vec3 wl_add = vec3(0.0);
uniform float wl_lit = 1.0;          // the share of windows lit against the sunset's (SkyDrive.win_at / RenderLook.WINDOW_LIT_SHARE)
uniform float pan_whip = 0.0;        // 0 to 1: this pane's camera whips along the ground (PaneWorld.pan_whip), in every match
uniform float pan_whip_mix = 1.0;    // RenderLook.PAN_WHIP_MIX: how far a wall melts at a full whip
uniform vec4 pan_ground : source_color = vec4(0.37, 0.57, 0.25, 1.0);   // the ground's colour under this pane's camera: what is behind a wall below the horizon line
uniform float ref_cull = 0.0;        // 1: leave the back faces to the rasterizer (tools/cull_check.gd's reference picture)
uniform vec4 look_a[10];             // a look's windows: the pitch of a column, the pane's span across its cell (from, to), the share of cells with one
uniform vec4 look_b[10];             // ... the pane's span up the row (from, to), strips a row, flags (1 top row only, 2 a door, 4 shutters, 8 door panels)
uniform vec4 look_glass[10] : source_color;   // dark glass; a: the share of panes lit warm
uniform vec4 look_hi[10] : source_color;     // bright glass
uniform vec4 look_trim[10] : source_color;   // doors, shutters, panels
uniform float pattern_budget = 0.085;   // RenderLook.PATTERN_BUDGET: on a look with flag 16, the most a pane and its wall differ in relative luminance
uniform float dmg_holes = 0.18;      // RenderLook.DMG_HOLES: at stage 2, the share of a facade's bays broken open
uniform vec3 row_haze = vec3(0.5, 600.0, 2800.0);   // RenderLook.ROW_HAZE: the most of the air a far row takes, and the depths behind the fighter plane it starts and is full at
uniform float haze_focus = 0.0;      // the depth of the camera's focus plane (Camera's dolly): the rows' haze is measured from it. 0: the fighter plane
uniform vec2 open_col = vec2(0.0833, 4.0);   // RenderLook.OPEN_COL: a lobby's columns (a column's width as a share of its face, columns a face)
uniform float open_beam = 26.0;      // RenderLook.OPEN_BEAM: the beam on them, under the lobby's top
uniform vec4 open_frame_col : source_color = vec4(0.55, 0.58, 0.63, 1.0);   // RenderLook.OPEN_FRAME_COL: their stone, half the wall's own colour
uniform float open_far = 0.7;        // RenderLook.OPEN_FAR: the far side's columns and beam, in shade
uniform vec4 open_ceil : source_color = vec4(0.64, 0.59, 0.47, 1.0);    // RenderLook.OPEN_CEIL: the lit ceiling
uniform vec4 open_lamp : source_color = vec4(0.72, 0.65, 0.52, 1.0);    // RenderLook.OPEN_LAMP: its lamp panels (held to pattern_budget from the ceiling)
uniform float open_grid = 75.0;      // RenderLook.OPEN_GRID: a ceiling bay
uniform float open_ghost = 0.72;
uniform vec2 open_core = vec2(0.24, 0.4);   // RenderLook.OPEN_CORE: the lift and stair core in the middle of a lobby, as shares of the shell's width and depth
uniform float open_core_tone = 0.8;  // ... its stone against the columns'
uniform float open_door = 105.0;     // RenderLook.OPEN_DOOR: a lift door's height
uniform float open_core_ghost = 0.85; // RenderLook.OPEN_CORE_GHOST: the share of the core's pixels gone inside the patch (it is the widest thing in a lobby)
uniform float cut_plate = 9.0;       // RenderLook.CUT_PLATE: the edge of a floor's plate over and under a cleared floor
uniform float spread_now = 0.0;      // the sim's tick (PlanetView._send_spread): a new stage and a new mark spread from where the building was hit
uniform float spread_area = 8000.0;  // RenderLook.SPREAD_AREA_TICK: the pixels a tick the wave takes, on a screen of 1024 by 768
uniform float spread_lag = 0.35;     // RenderLook.SPREAD_LAG and SPREAD_BLOCK: the wave's edge is ragged in blocks, a block as much as this late
uniform float spread_block = 31.0;
uniform float spread_cell = 1200.0;  // RenderLook.SPREAD_CELL_PX: a window cell larger than this on the screen is taken in pieces
uniform vec2 mark_reach = vec2(90.0, 330.0);   // RenderLook.MARK_REACH: a held hit's dent, from the corner he came in by, at none and at all of the floor's strength taken
uniform vec2 mark_tall = vec2(0.5, 0.9);       // RenderLook.MARK_TALL: its height as a share of the floors hit
uniform vec2 mark_crack = vec2(3.0, 2.2);      // RenderLook.MARK_CRACK: cracks a mark, and how far they run as a multiple of the dent's reach
uniform vec2 open_near = vec2(300.0, 600.0);   // RenderLook.NEAR_CLIP: a column nearer the lens than the second is thinned toward a ghost, and is one at the first     // RenderLook.OPEN_GHOST: the share of a column's pixels gone inside the patch

varying flat vec4 v_cut;      // x, y, z: the mask's three parts; w: floor height
varying flat vec2 v_base;     // x: the base's world y; y: the top standing floor
varying flat float v_back;    // 1 on the back wall (model normal toward -z)
varying flat vec4 v_win;      // x, y, z: the mask of floors whose windows are out; w: floor height (0: no windows)
varying flat vec3 v_winb;     // x: the wall's base (world y); y: floors standing; z: the building, for the windows' hash
varying vec4 v_face;          // x: along the wall, from its middle; y: the wall's length; z: 1 on a wall, 0 on a box's top, -1 on a roof; w: along the building's width, from its middle
varying flat vec3 v_dmg;      // x: World's damage stage, 0 to 3; y: the top as drawn (world y); z: the instance's width
varying flat vec4 v_hole0;    // each hole's two ends on this pane's screen, in pixels (xy: the chest, zw: the other end)
varying flat vec4 v_hole1;
varying float v_wy;
varying vec3 v_view;          // from the camera, in world axes, for the sky's colour behind (the pan haze)
varying flat vec3 v_look;     // x: the look; y: rows of windows a floor; z: the row's haze, 0 to 1
varying flat vec3 v_open;     // this pane's lobby: x the share of it open (0: shut; negative on a part inside the shell or stuck onto it), y its top (world y; under -1.5e9: a building with no lobby), z the tower's share of the patch
varying flat vec4 v_shell;    // the footprint of the tower's shell at the street: xy its middle (x across from the camera, z in depth), zw half its width and depth (0: none)
varying flat vec2 v_frame;    // x: the height over the building's base from which this part is its outermost wall (it carries the frame's columns there; huge: never); y: four times what rows 5 to 9 of win_tex hold (1 marks, 2 a stage spreading) plus the core's state (0 whole, 1 cracked, 2 broken)

// A world point on this pane's screen, in FRAGCOORD's pixels.
vec2 screen_px(mat4 view, mat4 proj, vec3 p, vec2 size) {
	vec4 c = proj * (view * vec4(p, 1.0));
	return (c.xy / c.w * 0.5 + 0.5) * size;
}

void vertex() {
	vec4 so = texelFetch(stub_tex, ivec2(min(INSTANCE_ID, textureSize(stub_tex, 0).x - 1), 0), 0);
	float stub = so.r;
	v_open = so.gba;
	vec4 c = texelFetch(cut_tex, ivec2(min(INSTANCE_ID, textureSize(cut_tex, 0).x - 1), 0), 0);
	float top_floor = floor(c.z / 16384.0);
	v_cut = vec4(c.x, c.y, c.z - top_floor * 16384.0, c.w);
	int id = min(INSTANCE_ID, textureSize(win_tex, 0).x - 1);
	// The part's shape: the box's top is narrowed (a taper) or sloped down to one side (a lean). A plain box (1, 1, 0)
	// is left as it is, to the bit.
	vec4 sh = texelFetch(win_tex, ivec2(id, 2), 0);
	vec3 n0 = NORMAL;
	vec3 v0 = VERTEX;
	vec3 mv = VERTEX;
	float up = mv.y + 0.5;
	mv.x *= mix(1.0, sh.x, up);
	mv.z *= mix(1.0, sh.y, up);
	float ls = sh.z > 0.0 ? 1.0 : (sh.z < 0.0 ? -1.0 : 0.0);
	if (up > 0.5 && ls != 0.0) {
		mv.y -= abs(sh.z) * (ls * v0.x + 0.5);
	}
	// The deformed face's normal, in the model's space (a covector: the engine's normal matrix takes the uneven scale).
	vec3 nm = n0;
	if (abs(n0.x) > 0.5) {
		nm = vec3(n0.x, 0.5 * (1.0 - sh.x), 0.0);
	} else if (abs(n0.z) > 0.5) {
		nm = vec3(0.0, 0.5 * (1.0 - sh.y), n0.z);
	} else if (n0.y > 0.5) {
		nm = vec3(ls * abs(sh.z), 1.0, 0.0);
	}
	VERTEX = mv;
	NORMAL = nm;
	vec4 w = MODEL_MATRIX * vec4(mv, 1.0);
	float top = MODEL_MATRIX[3].y + 0.5 * length(MODEL_MATRIX[1].xyz);
	v_base = vec2(top - (top_floor + 1.0) * c.w, top_floor);
	v_back = n0.z < -0.5 ? 1.0 : 0.0;
	float stubbed = COLOR.a < 0.5 ? stub - 1.0 : stub;
	w.y = min(w.y, stubbed);
	v_wy = w.y;
	v_win = texelFetch(win_tex, ivec2(id, 0), 0);
	vec4 wb = texelFetch(win_tex, ivec2(id, 1), 0);
	bool zface = abs(n0.z) > 0.5;
	float sx = length(MODEL_MATRIX[0].xyz);
	float sz = length(MODEL_MATRIX[2].xyz);
	v_winb = vec3(wb.x, wb.y, float(INSTANCE_ID) + (zface ? 0.0 : 0.5));
	v_face = vec4(zface ? v0.x * sx : v0.z * sz, zface ? sx : sz, COLOR.a < 0.5 ? -1.0 : (abs(n0.y) < 0.5 ? 1.0 : 0.0), v0.x * sx);
	v_dmg = vec3(wb.z, min(top, stubbed), sx);
	v_look = vec3(sh.w, max(1.0, wb.w), row_haze.x * clamp((-(MODEL_MATRIX[3].z + 0.5 * sz - haze_focus) - row_haze.y) / max(row_haze.z - row_haze.y, 1.0), 0.0, 1.0));
	vec4 fr4 = texelFetch(win_tex, ivec2(id, 4), 0);
	v_frame = vec2(fr4.x, fr4.y + 4.0 * fr4.z);   // the core's state, and four times what rows 5 to 12 hold (1 marks, 2 a stage spreading, 4 a second wave inside it, 8 a blow-out's wave)
	vec4 shl = texelFetch(win_tex, ivec2(id, 3), 0);
	v_shell = vec4(MODEL_MATRIX[3].x + shl.x, MODEL_MATRIX[3].z + shl.y, shl.z, shl.w);
	vec4 bw = bent_world(mat4(1.0), w.xyz);
	v_view = bw.xyz - INV_VIEW_MATRIX[3].xyz;
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * bw);
	if (c.w <= 0.0 && wb.z < 1.5 && ref_cull < 0.5 && so.g == 0.0) {
		// Nothing to cut: cull this face if it looks away from the camera, as cull_back would. Every corner of a face
		// must decide the same, or a face thrown away at some corners only is drawn stretched to the screen's corner
		// (a dark stripe from a roof). So the test uses the face's plane and nothing of the corner itself: the true
		// normal (an instance is scaled unevenly, so the normal takes the inverse scale; a roof's slopes need it) and
		// one point of the plane, the same from every corner (the foot of the model's origin on it, rounded so the
		// corners agree to the bit; lowered with the stub).
		vec3 s2 = max(vec3(dot(MODEL_MATRIX[0].xyz, MODEL_MATRIX[0].xyz), dot(MODEL_MATRIX[1].xyz, MODEL_MATRIX[1].xyz), dot(MODEL_MATRIX[2].xyz, MODEL_MATRIX[2].xyz)), vec3(1e-12));
		// For a deformed box that is the deformed face's normal and a point the deforming leaves on the face: a wall's
		// bottom edge, a top's middle (its high edge when it leans).
		vec3 n = (VIEW_MATRIX * (MODEL_MATRIX * vec4(nm / s2, 0.0))).xyz;
		vec3 fpm = abs(n0.y) < 0.5 ? n0 * 0.5 + vec3(0.0, -0.5, 0.0) : (n0.y > 0.5 ? vec3(-0.5 * ls, 0.5, 0.0) : vec3(0.0, -0.5, 0.0));
		vec4 fp = MODEL_MATRIX * vec4(fpm, 1.0);
		fp.y = min(fp.y, stubbed);
		if (dot(n, (VIEW_MATRIX * fp).xyz) > 0.0) {
			POSITION = vec4(2.0, 2.0, 2.0, 1.0);
		}
	}
	v_hole0 = vec4(0.0);
	v_hole1 = vec4(0.0);
	if (hole[0].w > 0.0) {
		v_hole0 = vec4(screen_px(VIEW_MATRIX, PROJECTION_MATRIX, hole[0].xyz, VIEWPORT_SIZE), screen_px(VIEW_MATRIX, PROJECTION_MATRIX, hole_to[0].xyz, VIEWPORT_SIZE));
	}
	if (hole[1].w > 0.0) {
		v_hole1 = vec4(screen_px(VIEW_MATRIX, PROJECTION_MATRIX, hole[1].xyz, VIEWPORT_SIZE), screen_px(VIEW_MATRIX, PROJECTION_MATRIX, hole_to[1].xyz, VIEWPORT_SIZE));
	}
}

// Whether floor k's bit is set in a mask packed as 24, 24 and 14 bits.
bool bit_on(float k, vec3 m) {
	float part = k < 24.0 ? m.x : (k < 48.0 ? m.y : m.z);
	float bit = k < 24.0 ? k : (k < 48.0 ? k - 24.0 : k - 48.0);
	return mod(floor(part / exp2(bit)), 2.0) > 0.5;
}

// Whether floor k is cleared (its bit is 0).
bool cleared(float k, vec3 m) {
	return !bit_on(k, m);
}

// Relative luminance (the shader works in linear light).
float lum(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// The colour `to`, but no farther from `from` in relative luminance than `budget`.
vec3 toward(vec3 from, vec3 to, float budget) {
	return mix(from, to, min(1.0, budget / max(abs(lum(to) - lum(from)), 0.0001)));
}

float win_hash(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

// The frame's columns along a wall: open_col.y of them, the two corners and those between, evenly, each open_col.x of
// the wall wide (never thinner than `edge`, a pixel and a bit). at: along the wall from its middle; len: its length.
// which: the nearest column's number from the wall's start; across: how far `at` is from that column's middle; wide:
// a column's width. Returns whether `at` is on a column.
bool on_column(float at, float len, float edge, out float which, out float across, out float wide) {
	float n = max(2.0, open_col.y);
	wide = max(open_col.x * len, 1.3 * edge);
	float pitch = (len - wide) / (n - 1.0);
	float u = at + 0.5 * len - 0.5 * wide;
	which = clamp(floor(u / pitch + 0.5), 0.0, n - 1.0);
	across = u - which * pitch;
	return abs(across) < 0.5 * wide;
}

// The core (the lift and stair shafts that hold a tower up): a box in the middle of the shell's footprint (shell: xy
// its middle across and in depth, zw half its width and depth). Where the ray eye + view * t enters it: t (this pixel
// is at 1), or -1 when it misses. xface: it enters by a face that looks along x.
float core_in(vec4 shell, vec3 eye, vec3 view, out bool xface) {
	vec2 h = open_core * shell.zw;
	vec2 dir = vec2(abs(view.x) < 0.0001 ? 0.0001 : view.x, abs(view.z) < 0.0001 ? 0.0001 : view.z);
	vec2 ta = (-h - (eye.xz - shell.xy)) / dir;
	vec2 tb = (h - (eye.xz - shell.xy)) / dir;
	vec2 lo = min(ta, tb);
	vec2 hi = max(ta, tb);
	xface = lo.x > lo.y;
	float t = max(lo.x, lo.y);
	return (shell.z > 0.0 && t < min(hi.x, hi.y)) ? t : -1.0;
}

// The core's face where that ray meets it, shaded. stone: the frame's stone here; floor_y and room: the storey's
// floor and its height; state: 0 whole, 1 cracked, 2 broken (the building's hit points); lit: the lift signs are on.
vec3 core_look(vec4 shell, vec3 eye, vec3 view, float t, bool xface, vec3 stone, float floor_y, float room, float state, bool lit, float bid, mat4 to_view) {
	vec2 h = max(open_core * shell.zw, vec2(0.001));
	vec3 nrm = xface ? vec3(-sign(view.x), 0.0, 0.0) : vec3(0.0, 0.0, -sign(view.z));
	float along = xface ? (eye.z + view.z * t - shell.y) / h.y : (eye.x + view.x * t - shell.x) / h.x;   // -1 to 1 across the face
	float up = eye.y + view.y * t - floor_y;
	float door_h = min(open_door, 0.72 * room);
	bool door = abs(fract((along * 0.5 + 0.5) * 3.0) - 0.5) < 0.3;   // three lift doors a face
	vec3 c = stone * open_core_tone;
	if (door && up < door_h) {
		c = mix(inside.rgb, stone, 0.3);
	} else if (door && lit && up > door_h + 6.0 && up < door_h + 13.0) {
		c = toward(stone, open_lamp.rgb, 2.0 * pattern_budget);
	}
	if (state > 0.5) {
		// Cracked: a line up it in straight jags.
		float jag = (win_hash(vec3(bid, floor(up / 14.0), 29.0)) - 0.5) * 0.22;
		c = mix(c, inside.rgb, 0.8 * (1.0 - smoothstep(0.025, 0.05, abs(along - 0.24 - jag))));
	}
	if (state > 1.5 && up > 0.2 * room && up < 0.74 * room && abs(along + 0.12) < 0.3 + 0.22 * win_hash(vec3(bid, floor(up / 16.0), 31.0))) {
		c = inside.rgb;   // broken: a bite out of its middle, the dark inside showing
	}
	return flat_shade(c, (to_view * vec4(nrm, 0.0)).xyz, 0.35);
}

void fragment() {
	float lit_w = 0.0;   // the share of this pixel that is a lit pane (the world's light leaves it)
	if (ref_cull > 0.5 && v_cut.w <= 0.0 && !FRONT_FACING) {
		discard;
	}
	float dith = fract(dot(FRAGCOORD.xy, vec2(0.7548777, 0.5698403)));
	bool lobby = v_open.y > -1.5e9;         // a tower with a lobby
	float share = lobby ? v_open.z : 1.0;   // how much of the hole is this building's: all of it, or a tower's share of the patch
	bool holed = false;      // inside a hole (or its share of the patch), nearer the camera than it cuts to
	bool in_patch = false;   // inside the patch itself, whatever this tower's share of it
	for (int i = 0; i < 2; i++) {
		if (hole[i].w > 0.0) {
			// The distance to the hole's axis (a point for a round hole), and how far along it this pixel is.
			vec4 ends = i == 0 ? v_hole0 : v_hole1;
			vec2 ab = ends.zw - ends.xy;
			vec2 ap = FRAGCOORD.xy - ends.xy;
			float t = clamp(dot(ap, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
			float lim = mix(hole[i].w, hole_to[i].w, t) * (hole_edge.x + hole_edge.y * dith);
			float off = length(ap - ab * t);
			if (-VERTEX.z < mix(hole_near[i].x, hole_near[i].y, t)) {
				in_patch = in_patch || off < lim;
				holed = holed || off < lim * share;
			}
		}
	}
	if (holed) {
		discard;
	}
	float st = v_dmg.x;
	bool wall = v_face.z > 0.5;
	bool roof = v_face.z < -0.5;
	float hgt = max(v_dmg.y - v_winb.x, 1.0);
	float bid = floor(v_winb.z);
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	// What rows 5 to 9 of win_tex hold for this building, read here and only for a building that has any: a stage
	// spreading from where it was hit, and the marks its held hits left. Both grow as a disc on the screen from their
	// point, the same area a tick, so the picture never changes by more than that in a frame. A wall with windows is
	// taken a window cell at a time (the cell's middle is where the disc is measured, so its panes go out together),
	// anything else in blocks; each cell or block is a little late (lag), never early. A cell that is large on the
	// screen is cut into pieces of spread_cell pixels at most, or a near tower's lit cells would each change more of
	// the picture in one tick than the wave is allowed.
	float fxf = floor(v_frame.y * 0.25 + 0.01);
	float core_state = v_frame.y - 4.0 * fxf;
	bool f_wave = mod(floor(fxf * 0.5), 2.0) > 0.5;
	bool f_wave2 = mod(floor(fxf * 0.25), 2.0) > 0.5;
	bool f_blow = fxf > 7.5;
	int iid = min(int(bid), textureSize(win_tex, 0).x - 1);
	float toward_z = v_shell.y + (v_shell.y < 0.0 ? v_shell.w : -v_shell.w);   // the shell's face toward the fighter plane
	float px_area = spread_area * VIEWPORT_SIZE.x * VIEWPORT_SIZE.y / 786432.0 / PI;
	float lag = 1.0;
	vec2 at_px = FRAGCOORD.xy;
	float per_px_u = fwidth(v_face.x);   // world units a pixel along the wall and up it: worked out for every pixel
	float per_px_y = fwidth(v_wy);
	if (fxf > 0.5) {
		vec2 blk = vec2(floor(v_face.x / spread_block), floor(v_wy / spread_block));
		if (v_face.z > 0.5 && v_win.w > 0.0) {
			float nc = max(1.0, floor(v_face.y / look_a[clamp(int(v_look.x + 0.5), 0, 9)].x));
			float side = sqrt(spread_cell * VIEWPORT_SIZE.x * VIEWPORT_SIZE.y / 786432.0);   // a piece's side, in pixels
			float cut_u = nc * clamp(ceil(v_face.y / nc / max(per_px_u, 0.0001) / side), 1.0, 16.0);   // pieces along the wall
			float cut_y = v_look.y * clamp(ceil(v_win.w / v_look.y / max(per_px_y, 0.0001) / side), 1.0, 16.0);   // ... and up a floor
			blk = vec2(floor((v_face.x / v_face.y + 0.5) * cut_u), floor((v_wy - v_winb.x) / v_win.w * cut_y));
			vec3 mid = eye + v_view;
			float du = ((blk.x + 0.5) / cut_u - 0.5) * v_face.y - v_face.x;
			if (fract(v_winb.z) < 0.25) {
				mid.x += du;
			} else {
				mid.z += du;
			}
			mid.y += v_winb.x + (blk.y + 0.5) / cut_y * v_win.w - v_wy;
			at_px = screen_px(VIEW_MATRIX, PROJECTION_MATRIX, mid, VIEWPORT_SIZE);
		}
		lag += spread_lag * win_hash(vec3(bid, blk.x + 40.0 * fract(v_winb.z), blk.y));
	}
	if (f_wave) {
		vec4 sp = texelFetch(win_tex, ivec2(iid, 5), 0);
		float sn = floor(sp.a * 0.25 + 0.01);
		vec2 dp = at_px - screen_px(VIEW_MATRIX, PROJECTION_MATRIX, bent_world(mat4(1.0), vec3(v_shell.x + sp.x, v_winb.x + sp.y, toward_z)).xyz, VIEWPORT_SIZE);
		if (dot(dp, dp) * lag * lag > px_area * max(spread_now - sp.z, 0.0) / max(sn, 1.0)) {
			st = sp.a - 4.0 * sn;   // the wave has not reached this pixel: the stage before
		} else if (f_wave2) {
			// A later change spreads inside the first wave as a second one (row 10): outside it, the stage between.
			vec4 s2 = texelFetch(win_tex, ivec2(iid, 10), 0);
			float n2 = floor(s2.a * 0.25 + 0.01);
			vec2 d2 = at_px - screen_px(VIEW_MATRIX, PROJECTION_MATRIX, bent_world(mat4(1.0), vec3(v_shell.x + s2.x, v_winb.x + s2.y, toward_z)).xyz, VIEWPORT_SIZE);
			if (dot(d2, d2) * lag * lag > px_area * max(spread_now - s2.z, 0.0) / max(n2, 1.0)) {
				st = s2.a - 4.0 * n2;
			}
		}
	}
	if (st > 2.5) {
		// A shell: no lid, and the walls end in a broken line, a step every half column. The far walls break
		// elsewhere, so their dark inside shows over the near ones.
		if (!wall) {
			discard;
		}
		float seg = floor((v_face.x / v_face.y + 0.5) * max(2.0, floor(2.0 * v_face.y / win_pitch)));
		if (v_wy > v_dmg.y - dmg_rag * hgt * win_hash(vec3(v_winb.z + (FRONT_FACING ? 0.0 : 0.25), seg, 5.0))) {
			discard;
		}
	} else if (st > 1.5) {
		// A part gone: one top corner (which one is the building's own) is sheared off in four steps. u is how far
		// this pixel is from that edge of the building.
		float wbox = roof ? v_dmg.z / roof_over : v_dmg.z;
		float bw = clamp(dmg_bite.x * wbox, 14.0, 110.0) + 0.5 * (v_dmg.z - wbox);
		float u = 0.5 * v_dmg.z - (win_hash(vec3(bid, 3.0, 7.0)) < 0.5 ? -1.0 : 1.0) * v_face.w;
		if (roof) {
			if (u < bw * (0.85 + 0.3 * win_hash(vec3(bid, floor(v_wy / 18.0), 1.0)))) {
				discard;
			}
		} else {
			float s = floor(4.0 * u / bw);
			float left = clamp(1.0 - (s + 0.5) / 4.0 + 0.3 * (win_hash(vec3(bid, s, 2.0)) - 0.5), 0.0, 1.0);
			if (s < 4.0 && v_wy > v_dmg.y - dmg_bite.y * hgt * left * (FRONT_FACING ? 1.0 : 0.45) + 0.01) {
				discard;
			}
		}
	}
	vec3 wallc = (st > 1.5 && !roof) ? COLOR.rgb * dmg_soot : COLOR.rgb;
	vec3 col = FRONT_FACING ? flat_shade(wallc, NORMAL, 0.35) : inside.rgb;
	if (FRONT_FACING && wall && v_win.w > 0.0) {
		int lk = clamp(int(v_look.x + 0.5), 0, 9);
		vec4 la = look_a[lk];
		vec4 lb = look_b[lk];
		float fy = (v_wy - v_winb.x) / v_win.w;
		float fr = fy * v_look.y;                 // rows of windows: a tall floor carries several
		float ncol = max(1.0, floor(v_face.y / la.x));
		float cx = (v_face.x / v_face.y + 0.5) * ncol;
		vec2 r = vec2(fract(cx), fract(fr));
		float kf = floor(fy);
		float fine = 1.0 - smoothstep(0.3, 0.75, max(fwidth(cx), fwidth(fr)));
		bool soft = mod(floor(lb.w / 16.0), 2.0) > 0.5;
		// A held hit's marks on this floor (rows 6 to 9): the dent at the corner he came in by, by window cells where
		// they can be drawn, and the cracks that run from it.
		bool mk_pane = false;   // a floor a held blow covered, or the one over or under it: its panes are out
		float mk_cell = 0.0;    // this cell's cladding is gone
		float mk_far = 0.0;     // ... and the dent itself, on a wall too far to draw cells
		float mk_line = 0.0;    // on a crack
		float edge_y = fwidth(v_wy);
		float edge_u = fwidth(v_face.x);
		if (mod(fxf, 2.0) > 0.5 && st < 2.5 && kf >= 0.0 && kf < v_winb.y) {
			vec3 pw = eye + v_view;
			bool zf = fract(v_winb.z) < 0.25;
			float cell_u = ((floor(cx) + 0.5) / ncol - 0.5) * v_face.y - v_face.x;   // from this pixel to its cell's middle, along the wall
			float cell_y = v_winb.x + (floor(fr) + 0.5) / v_look.y * v_win.w;
			vec3 pc = pw + (zf ? vec3(cell_u, 0.0, 0.0) : vec3(0.0, 0.0, cell_u));
			for (int i = 0; i < 4; i++) {
				vec4 run = texelFetch(win_tex, ivec2(iid, 6 + i), 0);
				if (run.x < 0.5) {
					break;
				}
				float rn = floor(run.x / 4096.0);
				float cnt = floor((run.x - rn * 4096.0) / 64.0);
				float f0 = run.x - rn * 4096.0 - cnt * 64.0;
				if (kf < f0 - 1.0 || kf > f0 + cnt) {
					continue;
				}
				float side = run.z < 0.0 ? -1.0 : 1.0;
				vec3 corner = vec3(v_shell.x + side * v_shell.z, v_winb.x + (f0 + 0.5 * cnt) * v_win.w, toward_z);
				// Grown this far: the mark as it is now inside the disc, as it was before this hit outside it. A mark that
				// is whole (its tick far in the past) has no disc to measure.
				float q = run.y;
				if (run.w > -1.0e5) {
					vec2 dp = at_px - screen_px(VIEW_MATRIX, PROJECTION_MATRIX, bent_world(mat4(1.0), corner).xyz, VIEWPORT_SIZE);
					if (dot(dp, dp) * lag * lag > px_area * max(spread_now - run.w, 0.0) / max(rn, 1.0)) {
						q = abs(run.z) - 1.0;
					}
				}
				if (q <= 0.0) {
					continue;
				}
				mk_pane = true;
				float reach = mix(mark_reach.x, mark_reach.y, q);
				float half_h = 0.5 * cnt * v_win.w * mix(mark_tall.x, mark_tall.y, q);
				float d = abs(pw.x - corner.x) + abs(pw.z - corner.z);   // along the walls from the corner
				float dc = abs(pc.x - corner.x) + abs(pc.z - corner.z);
				if (length(vec2(dc / reach, (cell_y - corner.y) / half_h)) + 0.35 * (win_hash(vec3(v_winb.z, floor(cx), floor(fr) + 17.0)) - 0.5) < 1.0) {
					mk_cell = 1.0;
				}
				mk_far = max(mk_far, 1.0 - smoothstep(0.8, 1.0, length(vec2(d / reach, (v_wy - corner.y) / half_h))));
				float wdt = max(dmg_crack.x, 1.3 * edge_y);
				for (int j = 0; j < 4; j++) {
					float fj = float(j);
					if (fj >= mark_crack.x) {
						break;
					}
					float h3 = win_hash(vec3(bid, f0 + 3.0 * fj, 23.0 + side));
					float t = d / dmg_crack.y + fj * 5.7;
					float sway = mix(win_hash(vec3(bid, floor(t), 29.0 + fj + f0)), win_hash(vec3(bid, floor(t) + 1.0, 29.0 + fj + f0)), fract(t)) - 0.5;
					float yl = corner.y + (fj - 0.5 * (mark_crack.x - 1.0)) * (0.3 * half_h + 0.45 * d * (0.5 + h3)) + sway * dmg_crack.z;
					mk_line = max(mk_line, (1.0 - smoothstep(0.5 * wdt, wdt, abs(v_wy - yl))) * step(d, mark_crack.y * reach * (0.6 + 0.4 * h3)));
				}
			}
		}
		// Floors VFX's blow-out has just put out (rows 11 and 12): their panes go as a wave from where the building
		// was hit, like a stage.
		if (f_blow && kf >= 0.0 && kf < v_winb.y) {
			vec4 bm = texelFetch(win_tex, ivec2(iid, 11), 0);
			if (bit_on(kf, bm.xyz)) {
				vec4 bw = texelFetch(win_tex, ivec2(iid, 12), 0);
				vec2 db = at_px - screen_px(VIEW_MATRIX, PROJECTION_MATRIX, bent_world(mat4(1.0), vec3(v_shell.x + bw.x, v_winb.x + bw.y, toward_z)).xyz, VIEWPORT_SIZE);
				mk_pane = mk_pane || dot(db, db) * lag * lag <= px_area * max(spread_now - bw.z, 0.0) / max(bw.a, 1.0);
			}
		}
		if (soft && (st > 0.5 || mk_pane || (kf >= 0.0 && kf < v_winb.y && bit_on(kf, v_win.xyz)))) {
			// A row whose panes are out, on a look with the contrast budget: its wall is as dark as they are.
			wallc = toward(inside.rgb, wallc, pattern_budget);
			col = flat_shade(wallc, NORMAL, 0.35);
		}
		if (st > 2.5) {
			// The frame of a shell, and the few panels of cladding it keeps. Too far to draw the cells, it is their
			// average: mostly the dark inside.
			vec3 bare = flat_shade(mix(wallc, dmg_frame.rgb, 0.6), NORMAL, 0.35);
			bool post = r.x < 0.11 || r.x > 0.89 || r.y < 0.16;
			vec3 cell = post ? bare : (win_hash(vec3(v_winb.z, floor(cx), kf + 31.0)) < dmg_panels ? col : inside.rgb);
			col = mix(mix(inside.rgb, bare, 0.4), cell, fine);
		} else if (windows > 0.5 && kf >= 0.0 && kf < v_winb.y) {
			bool gone = st > 0.5 || mk_pane || bit_on(kf, v_win.xyz);
			float row = floor(fr);
			float flags = lb.w;
			bool top_only = mod(flags, 2.0) > 0.5;
			bool door = mod(floor(flags / 2.0), 2.0) > 0.5;
			bool shutters = mod(floor(flags / 4.0), 2.0) > 0.5;
			bool panels = mod(floor(flags / 8.0), 2.0) > 0.5;
			float ry = lb.z > 1.5 ? fract(r.y * 2.0) : r.y;   // two strips a row
			bool has = win_hash(vec3(v_winb.z, floor(cx), row + 57.0)) < la.w && (!top_only || row >= v_winb.y * v_look.y - 1.5);
			bool across = r.x > la.y && r.x < la.z;
			bool tall = ry > lb.x && ry < lb.y;
			vec3 glass = look_glass[lk].rgb;
			vec3 bright = look_hi[lk].rgb;
			if (soft) {
				glass = toward(wallc, glass, pattern_budget);
				bright = toward(wallc, bright, pattern_budget);
			}
			// Too far to draw panes, the wall is the average of wall and glass (the dark inside where they are out).
			float cover = top_only ? 0.0 : (la.z - la.y) * (lb.y - lb.x) * la.w;
			float lit_sh = min(look_glass[lk].a * wl_lit, 1.0);   // the panes lit warm: more with the dark
			vec3 avg = flat_shade(mix(mix(glass, bright, 0.1), win_lit.rgb, lit_sh), NORMAL, 0.35);
			vec3 far = mix(col, gone ? inside.rgb : avg, cover);
			// A pane's own colour (lit, bright or dark) shows from near only: from the middle distance every pane is the
			// glass's average, so a far tower is bands, not a sparkle that shimmers as the camera moves.
			float vary = 1.0 - smoothstep(0.06, 0.2, max(fwidth(cx), fwidth(fr)));
			vec3 near = col;
			float near_lit = 0.0;   // the share of this pixel that is a lit pane (never dimmed)
			bool ground = row < 0.5;
			if (ground && panels) {
				// Wide door panels along the ground row, every other cell.
				if (mod(floor(cx), 2.0) < 0.5 && r.x > 0.1 && r.x < 0.9 && r.y < 0.82) {
					near = flat_shade(look_trim[lk].rgb, NORMAL, 0.35);
				}
			} else if (ground && door && floor(cx) == floor(ncol * 0.5)) {
				if (r.x > 0.3 && r.x < 0.7 && r.y < 0.74) {
					near = flat_shade(look_trim[lk].rgb, NORMAL, 0.35);
				}
			} else if (has && across && tall) {
				vec3 wc = inside.rgb;
				if (!gone) {
					float hsh = win_hash(vec3(v_winb.z, floor(cx), row));
					bool on = hsh < lit_sh;
					wc = mix(avg, on ? win_lit.rgb : flat_shade(hsh > 0.9 ? bright : glass, NORMAL, 0.35), vary);
					near_lit = (on ? vary : 0.0) + (1.0 - vary) * lit_sh;
				}
				near = wc;
			} else if (has && shutters && tall && r.x > la.y - 0.11 && r.x < la.z + 0.11) {
				near = flat_shade(look_trim[lk].rgb, NORMAL, 0.35);   // shutters beside the pane
			} else if (gone && has && across && ry >= lb.y) {
				near = mix(col, inside.rgb, 0.45 * (1.0 - (ry - lb.y) / max(1.0 - lb.y, 0.001)));   // soot above an empty pane
			}
			if (st > 1.5) {
				// A part gone: here and there a bay of the facade is broken open, wall and all, so the stage reads at street
				// level under a tower whose sheared top is far out of sight.
				far = mix(far, inside.rgb, 0.85 * dmg_holes);
				if (win_hash(vec3(v_winb.z, floor(cx) + 0.5, row + 91.0)) < dmg_holes) {
					near = mix(near, inside.rgb, 0.85);
				}
			}
			col = mix(far, near, fine);
			lit_w = mix(gone ? 0.0 : cover * lit_sh, near_lit, fine);
		}
		if (mk_cell + mk_far + mk_line > 0.0) {
			// The dent: the cladding is gone to the dark inside, and the frame shows in it, the edge of each floor's
			// plate and the frame's columns, in the stone a lobby's are. They are large and few, so they keep their
			// tone on a wall whose own pattern is held to the contrast budget. The cracks are dark on a wall and the
			// stone's tone on a wall as dark as its empty panes: whichever shows.
			vec3 stone = flat_shade(mix(open_frame_col.rgb, COLOR.rgb, 0.5), NORMAL, 0.35);
			float in_fl = fract(fy) * v_win.w;
			float plate_h = max(cut_plate, 1.3 * edge_y);
			float ci = 0.0;
			float cu = 0.0;
			float cw = 1.0;
			bool frame_on = in_fl < plate_h || in_fl > v_win.w - plate_h || on_column(v_face.x, v_face.y, edge_u, ci, cu, cw);
			col = mix(col, frame_on ? stone : inside.rgb, mix(mk_far, mk_cell, fine));
			col = mix(col, abs(lum(stone) - lum(wallc)) > abs(lum(inside.rgb) - lum(wallc)) ? stone : inside.rgb, 0.8 * mk_line);
		}
		if (st > 1.5 && st < 2.5) {
			// Two cracks: one from the top down, one from the ground up. Each wanders in straight jags and never thins
			// below a pixel and a bit, so it holds from far off.
			float y = v_wy - v_winb.x;
			for (int i = 0; i < 2; i++) {
				float fi = float(i);
				float t = y / dmg_crack.y + fi * 7.3;
				float sway = mix(win_hash(vec3(v_winb.z, floor(t), 13.0 + fi)), win_hash(vec3(v_winb.z, floor(t) + 1.0, 13.0 + fi)), fract(t)) - 0.5;
				float d = abs(v_face.x - (win_hash(vec3(v_winb.z, fi, 11.0)) - 0.5) * 0.7 * v_face.y - sway * dmg_crack.z);
				float span = i == 0 ? step(0.3 * hgt, y) : step(y, 0.62 * hgt);
				float wdt = max(dmg_crack.x, 1.3 * fwidth(v_face.x));
				col = mix(col, inside.rgb, 0.8 * span * (1.0 - smoothstep(0.5 * wdt, wdt, d)));
			}
		}
	}
	float edge_x = fwidth(v_face.x);   // worked out for every pixel, so it is defined wherever a branch below uses it
	bool core_x = false;
	float core_t = -1.0;   // where the eye's ray enters the core (this pixel at 1); under 0: it misses. Worked out only in an opening
	float col_i = 0.0;
	float col_u = 0.0;
	float col_w = 1.0;
	if (v_cut.w > 0.0) {
		float fk = (v_wy - v_base.x) / v_cut.w;
		float k = floor(fk);
		if (k >= 0.0 && k < v_base.y && cleared(k, v_cut.xyz)) {
			// A cleared floor: a gap, and what holds it open. The bare frame's tone, as a shell's.
			vec3 bare = mix(wallc, dmg_frame.rgb, 0.6);
			if (FRONT_FACING || v_back < 0.5) {
				// The walls are gone. On the outermost walls that face the camera the columns stand, and the plates
				// of the standing floors over and under the gap show their edges.
				float in_floor = fract(fk) * v_cut.w;
				bool col_on = on_column(v_face.x, v_face.y, edge_x, col_i, col_u, col_w);
				bool plate = (in_floor > v_cut.w - cut_plate && (k + 1.0 >= v_base.y || !cleared(k + 1.0, v_cut.xyz))) || (in_floor < cut_plate && k > 0.5 && !cleared(k - 1.0, v_cut.xyz));
				if (!(wall && FRONT_FACING && v_wy - v_winb.x >= v_frame.x - 0.5 && (col_on || plate))) {
					discard;
				}
				col = flat_shade(plate ? mix(bare, open_frame_col.rgb, 0.35) : bare, NORMAL, 0.35);
			} else {
				// The far wall's dark inside, and in front of it the core where the ray passes through it on a
				// cleared floor.
				col = inside.rgb;
				core_t = core_in(v_shell, eye, v_view, core_x);
				if (core_t > 0.0 && core_t < 1.0) {
					float ck = floor((eye.y + v_view.y * core_t - v_base.x) / v_cut.w);
					if (ck >= 0.0 && ck < v_base.y && cleared(ck, v_cut.xyz)) {
						col = core_look(v_shell, eye, v_view, core_t, core_x, bare, v_base.x + ck * v_cut.w, v_cut.w, core_state, false, bid, VIEW_MATRIX);
					}
				}
			}
		}
	}
	float open_k = abs(v_open.x);
	if (lobby && open_k > 0.0) {
		float ltop = v_open.y;
		float ceil_y = ltop - open_beam;
		bool inner = v_open.x < 0.0;
		// Where the eye's ray to this pixel passes the ceiling's height (worked out for every pixel, so its rate of
		// change across the screen is defined wherever it is used).
		vec2 at = eye.xz + v_view.xz * ((ceil_y - eye.y) / max(v_view.y, 0.0001)) - v_shell.xy;
		float edge_c = max(fwidth(at.x), fwidth(at.y));
		// The lobby's stone, by the tower's stage: sooted with its walls from "a part gone" (wallc carries it), the bare
		// frame's tone in a shell.
		vec3 frame = st > 2.5 ? mix(wallc, dmg_frame.rgb, 0.6) : mix(wallc, open_frame_col.rgb, 0.5);
		core_t = core_in(v_shell, eye, v_view, core_x);
		float core_y = eye.y + v_view.y * core_t;
		bool core_hit = core_t > 1.0 && core_y < ceil_y && core_y >= v_winb.x;   // the core, beyond this wall, between the lobby's floor and its ceiling
		bool col_on = on_column(v_face.x, v_face.y, edge_x, col_i, col_u, col_w);
		bool ceiling = false;
		if (v_shell.z > 0.0 && eye.y < ceil_y && v_wy >= ceil_y && v_view.y > 0.0001) {
			// Seen from under it. Inside the shell's footprint that point is on the lobby's ceiling, whatever wall the
			// ray goes on to meet. Lit where the tower is whole; the lamps are out in a damaged one; a shell has no
			// ceiling, only its dark inside.
			if (abs(at.x) < v_shell.z - 1.0 && abs(at.y) < v_shell.w - 1.0) {
				vec2 bay = abs(fract(at / open_grid + 0.5) - 0.5);
				float near_c = 1.0 - smoothstep(0.3, 0.75, edge_c / open_grid);
				vec3 lit = mix(open_ceil.rgb, toward(open_ceil.rgb, open_lamp.rgb, pattern_budget), mix(0.31, step(max(bay.x, bay.y), 0.28), near_c));   // too far to draw the lamps, their share of a bay
				col = st > 2.5 ? mix(inside.rgb, open_ceil.rgb, 0.12) : (st > 0.5 ? mix(open_ceil.rgb, inside.rgb, 0.55) : lit);
				ceiling = true;
			}
		}
		if (!ceiling && v_wy < ltop + (inner ? 0.5 : 0.0) && dith < open_k) {
			// Under the lobby's top, on the share of its pixels that is through: nothing of a part inside the shell,
			// no lid; of the shell's walls the beam and the columns; and through them the core.
			if (inner || !wall) {
				discard;
			}
			float dg = fract(dot(FRAGCOORD.xy, vec2(0.5698403, 0.7548777)) + 0.37);
			float in_p = in_patch ? 1.0 : 0.0;
			float mid = 1.0 + floor(win_hash(vec3(bid, 4.0, 9.0)) * max(open_col.y - 2.0, 1.0));   // one of the columns between the corners: the building's own
			bool front = v_back < 0.5 && fract(v_winb.z) < 0.25 && FRONT_FACING;
			bool stands = v_wy >= ceil_y || col_on;   // the beam, or a column
			// A shell: on the front, that column has broken off above a stump with a ragged top. The beam spans two
			// bays there: it stands, and reads as about to go.
			if (stands && v_wy < ceil_y && st > 2.5 && front && col_i == mid && v_wy > v_winb.x + (0.3 + 0.12 * win_hash(vec3(bid, floor(col_u / 7.0), 17.0))) * (ceil_y - v_winb.x)) {
				stands = false;
			}
			// Inside the patch a column is a ghost, so the fight shows through it. So near the lens that it is in it
			// (Camera's near-clip distances), it thins to one too: a solid column a fifth of the screen wide, swept
			// past by a travelling camera, is a large change every time it crosses.
			float thin = max(in_p, 1.0 - smoothstep(open_near.x, open_near.y, -VERTEX.z));
			if (stands && dg >= open_ghost * thin) {
				col = FRONT_FACING ? flat_shade(frame, NORMAL, 0.35) : frame * open_far;
				if (FRONT_FACING && v_wy >= ceil_y && v_wy < ceil_y + 3.0) {
					col *= 0.8;   // the beam's foot, in its own shade
				}
				if (st > 1.5 && front && col_i == mid && v_wy < ceil_y) {
					// A part gone: a crack up that column, in straight jags.
					float jag = (win_hash(vec3(bid, floor((v_wy - v_winb.x) / 14.0), 23.0)) - 0.5) * 0.45 * col_w;
					col = mix(col, inside.rgb, 0.8 * (1.0 - smoothstep(0.5, 1.0, abs(col_u - jag) / max(1.6, 1.3 * edge_x))));
				}
			} else if (FRONT_FACING && core_hit && fract(dg + 0.5) >= open_core_ghost * max(in_p, 1.0 - smoothstep(open_near.x, open_near.y, -VERTEX.z * core_t))) {
				// The core, seen through the opening.
				col = core_look(v_shell, eye, v_view, core_t, core_x, frame, v_winb.x, ceil_y - v_winb.x, core_state, st < 0.5, bid, VIEW_MATRIX);
			} else {
				discard;   // no wall here
			}
		}
	}
	col = mix(col * wl_mul + wl_add, col, lit_w);   // the world's light, but not on a lit pane
	if (v_look.z > 0.001) {
		// The rows' haze: the air's colour toward the horizon in this direction, more of it the farther back the row.
		col = mix(col, sky_color(min(elevation(v_view), horizon + 0.3 * sky_tan)), v_look.z);
	}
	float ph = max(pan_haze, pan_whip);   // the whole town's haze behind its switch, or a whip's
	if (ph > 0.001) {
		// A fast pan: the plain wall in place of its panes, soot and cracks, then toward what is behind it: the sky's
		// colour in this direction above the horizon line, the ground's below it.
		vec3 plain = FRONT_FACING ? flat_shade(COLOR.rgb, NORMAL, 0.35) : inside.rgb;
		float q = elevation(v_view);
		vec3 behind = mix(pan_ground.rgb, sky_color(q), smoothstep(-0.03, 0.03, (q - horizon) / sky_tan));
		col = mix(mix(col, plain, ph), behind, max(pan_haze * pan_mix, pan_whip * pan_whip_mix));
	}
	ALBEDO = col;
}
