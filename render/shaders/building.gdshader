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
//    seen flying through the building at his own depth. The mask comes from cut_tex, a float texel a building read by
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
// An instance with nothing to cut and no part gone keeps back-face culling (its back faces are thrown away in the
// vertex stage), so only the cut towers and the buildings at stage 2 and 3 pay for their insides. tools/cull_check.gd
// compares that with the rasterizer's own culling.
shader_type spatial;
render_mode unshaded, cull_disabled;

#include "res://render/shaders/color.gdshaderinc"
#include "res://render/shaders/bend.gdshaderinc"

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
uniform vec2 hole_near[2];     // cut what is nearer the camera than this (view distance): at the chest, at the other end
uniform vec4 inside : source_color = vec4(0.07, 0.07, 0.09, 1.0);   // RenderLook.BUILDING_INSIDE
uniform vec2 dmg_bite = vec2(0.36, 0.3);       // RenderLook.DMG_BITE and the rest: see look.gd
uniform vec3 dmg_crack = vec3(1.8, 16.0, 26.0);
uniform float dmg_soot = 0.84;
uniform float dmg_rag = 0.34;
uniform float dmg_panels = 0.2;
uniform vec4 dmg_frame : source_color = vec4(0.29, 0.29, 0.31, 1.0);
uniform float roof_over = 1.2;
uniform float ref_cull = 0.0;        // 1: leave the back faces to the rasterizer (tools/cull_check.gd's reference picture)

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

// A world point on this pane's screen, in FRAGCOORD's pixels.
vec2 screen_px(mat4 view, mat4 proj, vec3 p, vec2 size) {
	vec4 c = proj * (view * vec4(p, 1.0));
	return (c.xy / c.w * 0.5 + 0.5) * size;
}

void vertex() {
	float stub = texelFetch(stub_tex, ivec2(min(INSTANCE_ID, textureSize(stub_tex, 0).x - 1), 0), 0).r;
	vec4 c = texelFetch(cut_tex, ivec2(min(INSTANCE_ID, textureSize(cut_tex, 0).x - 1), 0), 0);
	float top_floor = floor(c.z / 16384.0);
	v_cut = vec4(c.x, c.y, c.z - top_floor * 16384.0, c.w);
	vec4 w = MODEL_MATRIX * vec4(VERTEX, 1.0);
	float top = MODEL_MATRIX[3].y + 0.5 * length(MODEL_MATRIX[1].xyz);
	v_base = vec2(top - (top_floor + 1.0) * c.w, top_floor);
	v_back = NORMAL.z < -0.5 ? 1.0 : 0.0;
	w.y = min(w.y, COLOR.a < 0.5 ? stub - 1.0 : stub);
	v_wy = w.y;
	int id = min(INSTANCE_ID, textureSize(win_tex, 0).x - 1);
	v_win = texelFetch(win_tex, ivec2(id, 0), 0);
	vec4 wb = texelFetch(win_tex, ivec2(id, 1), 0);
	bool zface = abs(NORMAL.z) > 0.5;
	float sx = length(MODEL_MATRIX[0].xyz);
	float sz = length(MODEL_MATRIX[2].xyz);
	v_winb = vec3(wb.x, wb.y, float(INSTANCE_ID) + (zface ? 0.0 : 0.5));
	v_face = vec4(zface ? VERTEX.x * sx : VERTEX.z * sz, zface ? sx : sz, COLOR.a < 0.5 ? -1.0 : (abs(NORMAL.y) < 0.5 ? 1.0 : 0.0), VERTEX.x * sx);
	v_dmg = vec3(wb.z, min(top, COLOR.a < 0.5 ? stub - 1.0 : stub), sx);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * bent_world(mat4(1.0), w.xyz));
	if (c.w <= 0.0 && wb.z < 1.5 && ref_cull < 0.5) {
		// Nothing to cut: cull this face if it looks away from the camera, as cull_back would. Every corner of a face
		// must decide the same, or a face thrown away at some corners only is drawn stretched to the screen's corner
		// (a dark stripe from a roof). So the test uses the face's plane and nothing of the corner itself: the true
		// normal (an instance is scaled unevenly, so the normal takes the inverse scale; a roof's slopes need it) and
		// one point of the plane, the same from every corner (the foot of the model's origin on it, rounded so the
		// corners agree to the bit; lowered with the stub).
		vec3 s2 = max(vec3(dot(MODEL_MATRIX[0].xyz, MODEL_MATRIX[0].xyz), dot(MODEL_MATRIX[1].xyz, MODEL_MATRIX[1].xyz), dot(MODEL_MATRIX[2].xyz, MODEL_MATRIX[2].xyz)), vec3(1e-12));
		vec3 n = (VIEW_MATRIX * (MODEL_MATRIX * vec4(NORMAL / s2, 0.0))).xyz;
		float pd = floor(dot(NORMAL, VERTEX) * 4096.0 + 0.5) / 4096.0;
		vec4 fp = MODEL_MATRIX * vec4(NORMAL * pd, 1.0);
		fp.y = min(fp.y, COLOR.a < 0.5 ? stub - 1.0 : stub);
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

float win_hash(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

void fragment() {
	if (ref_cull > 0.5 && v_cut.w <= 0.0 && !FRONT_FACING) {
		discard;
	}
	float dith = fract(dot(FRAGCOORD.xy, vec2(0.7548777, 0.5698403)));
	for (int i = 0; i < 2; i++) {
		if (hole[i].w > 0.0) {
			// The distance to the hole's axis (a point for a round hole), and how far along it this pixel is.
			vec4 ends = i == 0 ? v_hole0 : v_hole1;
			vec2 ab = ends.zw - ends.xy;
			vec2 ap = FRAGCOORD.xy - ends.xy;
			float t = clamp(dot(ap, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
			if (-VERTEX.z < mix(hole_near[i].x, hole_near[i].y, t) && length(ap - ab * t) < mix(hole[i].w, hole_to[i].w, t) * (0.8 + 0.25 * dith)) {
				discard;
			}
		}
	}
	float st = v_dmg.x;
	bool wall = v_face.z > 0.5;
	bool roof = v_face.z < -0.5;
	float hgt = max(v_dmg.y - v_winb.x, 1.0);
	float bid = floor(v_winb.z);
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
		float fy = (v_wy - v_winb.x) / v_win.w;
		float cx = (v_face.x / v_face.y + 0.5) * max(1.0, floor(v_face.y / win_pitch));
		vec2 r = vec2(fract(cx), fract(fy));
		float kf = floor(fy);
		float fine = 1.0 - smoothstep(0.3, 0.75, max(fwidth(cx), fwidth(fy)));
		if (st > 2.5) {
			// The frame of a shell, and the few panels of cladding it keeps. Too far to draw the cells, it is their
			// average: mostly the dark inside.
			vec3 bare = flat_shade(mix(wallc, dmg_frame.rgb, 0.6), NORMAL, 0.35);
			bool post = r.x < 0.11 || r.x > 0.89 || r.y < 0.16;
			vec3 cell = post ? bare : (win_hash(vec3(v_winb.z, floor(cx), kf + 31.0)) < dmg_panels ? col : inside.rgb);
			col = mix(mix(inside.rgb, bare, 0.4), cell, fine);
		} else if (windows > 0.5 && kf >= 0.0 && kf < v_winb.y) {
			bool gone = st > 0.5 || bit_on(kf, v_win.xyz);
			bool across = r.x > 0.24 && r.x < 0.76;
			if (st > 0.5) {
				col = mix(mix(col, inside.rgb, 0.22), col, fine);   // too far to draw panes: the wall takes their share of dark
			}
			if (across && r.y > 0.3 && r.y < 0.78) {
				vec3 wc = inside.rgb;
				if (!gone) {
					wc = win_hash(vec3(v_winb.z, floor(cx), kf)) < win_lit_share ? win_lit.rgb : flat_shade(win_glass.rgb, NORMAL, 0.35);
				}
				col = mix(col, wc, fine);
			} else if (gone && across && r.y >= 0.78) {
				col = mix(col, inside.rgb, fine * 0.45 * (1.0 - (r.y - 0.78) / 0.22));   // soot above an empty pane
			}
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
	if (v_cut.w > 0.0) {
		float k = floor((v_wy - v_base.x) / v_cut.w);
		if (k >= 0.0 && k < v_base.y && cleared(k, v_cut.xyz)) {
			if (FRONT_FACING || v_back < 0.5) {
				discard;
			}
			col = inside.rgb;
		}
	}
	ALBEDO = col;
}
