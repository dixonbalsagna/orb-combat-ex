// Water: the sea and crater lakes, one surface from well in front of the camera to the horizon. In the crater rows it
// comes from S.water (the sim's per-column depth): a surface at each wet column's standing level, depth-tested against
// the ground, so a lake shows only inside its bowl; off the sea (base below -30) the ground there must also be dug, so
// low coastal land beside a lake stays dry. Beyond the crater rows the far terrain decides, in the sea's columns (base
// below -30, the sim's sea rule): sea level wherever the far ground is below it, so the sea runs on to the horizon
// with one shoreline, and islands rise where the far sea floor does. In front of the fighter plane the foreground rule
// (fore_fall) lowers the surface and the ground under it together, below the sight line to the fighter plane's water.
// Where it had to fall (the camera near or below the waterline) or is seen from under its own level, the water shows
// its body, so what is under the water reads as under it, as the old front face did.
// The shore (in the crater rows): a vertex whose ground stands at or above the level of the water at or beside it (row
// 20, ground_field.gd) keeps that level, so a triangle from the water to the land stays flat and is cut where the land
// rises through it (v_depth crosses zero): the shoreline and a lake's outline in depth follow the ground's own contour.
// Without it the land vertex took the ground's height, the sheet sloped up the bank and was cut halfway between the
// vertices, a jagged wedge climbing the land at the mesh's stride. Dry land a little below the water beside it (at
// most shore_flood, as World's sea edge leaves a strip of up to 0.25 bh) is drawn flooded at that level, so the
// waterline is where the land rises through it and the drop at the sea's last column stays under water; deeper low
// land beside water stays dry, as the sim has it.
// The waterline (Art's flat facets, the water window): in the near water a foam line water_line.x pixels wide where the
// land rises through the surface, and a shallow band to water_shallow.x deep, so a new pool and the coast read as water
// with an edge. The fill's drama (render/core/water_fill.gd, from World's water_fill and water_wave cues): a crest that
// runs with the front over the water filling behind it, piles up at the hole's far wall (or where two fronts meet) and
// falls back as a slosh that settles; a wave's ring runs out over the surface and narrows to nothing. Both lift only
// wet near water (the sim's S.water stays the truth); the foam is a hard band on the crest and the ring.
// It fogs into the sky like the ground. UV.x: terrain column. UV2.y: 1 on the fighter-plane row. Same data as the
// terrain (ground.gdshaderinc).
// (The body of water.gdshader and water_far.gdshader; FAR_MAP: the planet's own far map.)

#include "res://render/shaders/bend.gdshaderinc"
#include "res://render/shaders/ground.gdshaderinc"
#include "res://render/shaders/skycol.gdshaderinc"

uniform vec3 wl_mul = vec3(1.0);   // the world's light (SkyDrive.world_at), this layer's multiply in linear light
uniform vec3 wl_add = vec3(0.0);   // ... and its night lift
uniform vec4 water : source_color;
uniform vec4 surface : source_color;
uniform float fall_body = 4.0;   // RenderLook.WATER_FALL_BODY: a sheet that fell this far shows its body
uniform float fog_far = 12000.0;
uniform vec4 foam : source_color = vec4(0.894, 0.925, 0.933, 0.92);   // RenderLook.WATER_FOAM (Art's sea accent)
uniform vec2 water_line = vec2(1.5, 0.92);     // RenderLook.WATER_LINE: the waterline's width in pixels, its alpha
uniform vec2 water_shallow = vec2(28.0, 0.28); // RenderLook.WATER_SHALLOW: the shallow band's depth, its share of the foam
// The fill's drama (render/core/water_fill.gd; the clock is crater_now, the sim's time). The loops run to wf_n and
// ww_n, uniforms, so the driver's compiler keeps one copy of each body.
uniform int wf_n = 0;      // the live fills, at most 4
uniform vec4 wf_a[4];      // x (the front's source), y (the surface it heads for), its speed (units a second), t0 (its start)
uniform vec4 wf_b[4];      // its run behind x (from .x to .y units from x) and ahead (.z to .w)
uniform vec4 wf_c[4];      // the crest's height, the slosh's
uniform int ww_n = 0;      // the live rings, at most 2
uniform vec4 ww_a[2];      // x, y (the surface), t0, the radius it runs out to
uniform vec4 ww_b[2];      // its lift, the time it runs
uniform vec4 fill_t = vec4(0.22, 0.55, 0.3, 1.6);   // RenderLook.WATER_FILL_T, WATER_PILE: the crest's length behind the front (s), the slosh's period and settle time (s), the pile at a wall
uniform vec2 foam_band = vec2(14.0, 50.0);   // RenderLook.WATER_FOAM_BAND: the foam line's width on a front, a pile or a ring (units); the ring's width

varying float v_wet;
varying float v_depth;
varying float v_ok;
varying float v_under;
varying vec3 v_view;
varying float v_wz;
varying vec2 v_px;
varying float v_near;

// The fill's drama at band x and depth z: x the surface's lift, y the foam (0 to 1 on a crest or a ring).
vec2 water_drama(float x, float z) {
	vec2 o = vec2(0.0);
	for (int j = 0; j < wf_n; j++) {
		vec4 a = wf_a[j];
		float ds = x - a.x;
		ds -= world_w * round(ds / world_w);
		float u = abs(ds);
		vec2 r = ds < 0.0 ? wf_b[j].xy : wf_b[j].zw;   // this side's run
		if (r.y <= r.x || u < r.x - col_w || u > r.y + col_w) {
			continue;
		}
		float tau = crater_now - a.w;
		float f = a.z * tau;                            // the front, from the source
		float lc = max(a.z * fill_t.x, 3.0 * col_w);    // the crest's length behind it
		float h = wf_c[j].x;
		float c = 0.0;
		if (f < r.y) {
			// Running: a wedge from the front back, taller as it nears the wall; the foam a thin line on the front.
			float pile = 1.0 + (fill_t.w - 1.0) * clamp(1.0 - (r.y - f) / lc, 0.0, 1.0);
			c = u <= f ? h * pile * max(0.0, 1.0 - (f - u) / lc) : 0.0;
			o.x += c;
			o.y = max(o.y, (u <= f && u > f - foam_band.x) ? 1.0 : 0.0);
		} else {
			// At the wall: the pile falls back, and the pool sloshes end to end and settles; the foam a line on the pile
			// while it stands.
			float t_wall = tau - r.y / a.z;
			float e = exp(-t_wall / fill_t.z);
			c = h * fill_t.w * e * max(0.0, 1.0 - (r.y - u) / lc);
			float m = cos(3.14159265 * clamp((u - r.x) / max(r.y - r.x, col_w), 0.0, 1.0));
			o.x += c - wf_c[j].y * e * sin(6.2831853 * t_wall / fill_t.y) * m;
			o.y = max(o.y, (e > 0.5 && u > r.y - foam_band.x) ? 1.0 : 0.0);
		}
	}
	for (int j = 0; j < ww_n; j++) {
		vec4 a = ww_a[j];
		float ds = x - a.x;
		ds -= world_w * round(ds / world_w);
		float q = clamp((crater_now - a.z) / ww_b[j].y, 0.0, 1.0);
		float rr = a.w * (1.0 - (1.0 - q) * (1.0 - q));   // runs out fast and slows
		float off = abs(length(vec2(ds, z)) - rr);
		o.x += ww_b[j].x * max(0.0, 1.0 - off / foam_band.y) * (1.0 - q);
		o.y = max(o.y, (q < 0.6 && off < 0.5 * foam_band.x) ? 1.0 : 0.0);   // the foam a thin line on the ring's crest, while it runs
	}
	return o;
}

void vertex() {
	int i = int(UV.x + 0.5) % nc;
	float xw = UV.x * col_w;
	float b = gf(i, 0);
	float d0 = gf(i, 1);
	float wd = gf(i, 4);
	float z = VERTEX.z;
	float s = far_weight(z);
	float surf;
	float ground;
	bool shore = false;
	if (s <= 0.0) {
		v_wet = wd >= wet_min ? 1.0 : 0.0;
		surf = b + d0 + wd;
		float lv = gf(i, 20);
		float off = d0;
		if ((v_wet > 0.5 || lv > -1.0e8) && UV2.y < 0.5) {
			off = ground_offset(i, xw, z);
		}
		ground = b + off;
		// The sea is wherever the sim's water stands at sea level (World's edge follows S.water, not the base rule).
		v_ok = (b < sea_base || off < -wet_min || abs(surf) < wet_min) ? 1.0 : 0.0;
		if (lv > -1.0e8 && ground >= lv) {
			shore = true;
			surf = lv;
			v_wet = 1.0;
			v_ok = 1.0;
		} else if (lv > -1.0e8 && v_wet < 0.5 && lv - ground <= shore_flood) {
			surf = lv;
			v_wet = 1.0;
			v_ok = 1.0;
		}
		if (!shore && v_wet > 0.5 && wf_n + ww_n > 0) {
			surf += max(water_drama(xw, z).x, -0.6 * max(surf - ground, 0.0));   // the fill's crest, slosh and ring (never below the floor)
		}
		v_near = 1.0;
	} else {
		v_near = 0.0;
		bool wet;
		vec4 f = far4(xw, z, s, false, wet);
		ground = mix(b, f.x, s);
		surf = 0.0;
		v_wet = (ground < 0.0 && (mix(b, f.w, s) < sea_base || wet)) ? 1.0 : 0.0;
		v_ok = 1.0;
	}
	// The foreground rule on the surface and the ground under it, as the terrain shader applies it to that ground.
	float surf0 = surf;
	if (!shore && (v_wet < 0.5 || v_ok < 0.5 || surf <= ground)) {
		surf = ground;
	}
	vec2 gr = vec2(0.0);
	float ox = MODEL_MATRIX[3].x;
	if (shore) {
		// The land falls as dry land does; the sheet falls with the water beside it, to the sight line's cap for tops.
		float top = ground;
		fore_fall(ground, gr, top, xw + ox, z, ox);
		if (z > 0.0) {
			surf = min(surf, fore_cap3(xw + ox, z, ox, true).x);
		}
		surf = min(surf, ground);   // never over land the rule pushed below it
	} else {
		fore_fall(ground, gr, surf, xw + ox, z, ox);
	}
	v_under = max(clamp((surf0 - fore_cam.y) / fall_body, 0.0, 1.0), smoothstep(0.0, fall_body, surf0 - surf));
	VERTEX.y = surf;
	v_depth = surf - ground;
	v_px = vec2(xw, z);
	vec4 bw = bent_world(MODEL_MATRIX, VERTEX);
	v_view = bw.xyz - INV_VIEW_MATRIX[3].xyz;   // from the camera, in world axes (the camera may be pitched)
	v_wz = bw.z;
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * bw);
}

void fragment() {
	if (v_wet < 0.5 || v_depth <= 0.0 || v_ok < 0.5) {
		discard;
	}
	float depth_px = fwidth(v_depth);   // the depth's change a pixel, worked out outside any branch (the waterline's width)
	vec3 c;
	float a;
	c = mix(surface.rgb, water.rgb, v_under);
	a = mix(surface.a, 0.5 + 0.25 * clamp(v_depth / 340.0, 0.0, 1.0), v_under);
	if (v_under < 0.5) {
		// Art's waterline: a foam line where the land rises through the surface, a shallow band, hard edged.
		if (v_depth < depth_px * water_line.x) {
			c = foam.rgb;
			a = water_line.y;
		} else if (v_depth < water_shallow.x) {
			c = mix(c, foam.rgb, water_shallow.y);
			a = mix(a, foam.a, water_shallow.y);
		}
		if (v_near > 0.5 && wf_n + ww_n > 0 && water_drama(v_px.x, v_px.y).y > 0.5) {
			c = foam.rgb;   // the crest's and the ring's foam
			a = foam.a;
		}
	}
	c = c * wl_mul + wl_add;   // the world's light; the lane cue is never dimmed
	vec4 cue = lane_cue_at(v_px, fwidth(v_px.y));   // the lane cue lies on the surface
	c = mix(c, cue.rgb, cue.a);
	a = max(a, cue.a);
	c = pair_mark_on(c, v_px, fwidth(v_px.y));   // ... and so does the pair's mark
	// The sea takes the sky: by depth toward the horizon band at haze_sea of its value, and at the far edge it ends there
	// (not in the sky's own colour), one clear step below the sky at the horizon. It turns opaque as it hazes.
	vec2 hz = haze_parts(v_view, -v_wz, fog_far);
	float hs = max(hz.x, hz.y);
	ALBEDO = mix(c, sky_horizon.rgb * haze_sea, hs);
	ALPHA = mix(a, 1.0, hs);
}
