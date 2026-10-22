// The ground: one surface from well in front of the camera to the horizon. A grid of terrain columns by rows in depth,
// heights from the ground field (ground.gdshaderinc). The crater rows carry the round bowls, furrows, grooves and
// slide trenches; the row on the fighter plane reads the sim's deform directly (exact). Beyond them, behind and in
// front, the far terrain blends in: the same columns' base heights and biomes with relief, fading into the sky's own
// colour toward the far edge. In front of the fighter plane the foreground rule (fore_fall) keeps the land below the
// sight line to the fighter plane. Columns coarsen away from the fighter plane in runs (planet_view.gd); a run's
// boundary row snaps to the coarser stride.
// UV.x: terrain column (NC wraps to 0). UV2.y: 1 on the fighter-plane row, 2 or more a snapping boundary.
// The biome colour is each column's biome in the ground field's biome row (ground_field.gd), as the far land reads it,
// so a new world (World's turn) is a texture upload, never new meshes. Scorch chars the ground, heat glows, cracked pavement darkens (S.crack),
// rubble heaps (S.rubble, in depth as ground.gdshaderinc lays them) take the rubble colour, broken up in blocks.
// In a district the streets of the lane table are painted under all of that (sidewalks, kerb parking, carriageways),
// and the lane cue lies over it: a stripe at a fighter's depth, in his colour (ground.gdshaderinc).
shader_type spatial;
render_mode unshaded, cull_disabled;

#include "res://render/shaders/color.gdshaderinc"
#include "res://render/shaders/bend.gdshaderinc"
#include "res://render/shaders/ground.gdshaderinc"
#include "res://render/shaders/skycol.gdshaderinc"

uniform vec3 wl_mul = vec3(1.0);   // the world's light (SkyDrive.world_at), this layer's multiply in linear light
uniform vec3 wl_add = vec3(0.0);   // ... and its night lift
uniform vec4 sea_floor : source_color;
uniform vec4 crater : source_color;
uniform vec4 crater_desert : source_color;
uniform vec4 ejecta : source_color;
uniform vec4 char_col : source_color;
uniform vec4 heat_lo : source_color;
uniform vec4 heat_hi : source_color;
uniform vec4 snow : source_color;
uniform vec4 cracked : source_color;
uniform vec4 rubble : source_color;
uniform float rubble_tint_h = 20.0;
uniform float snow_from = 560.0;
uniform float snow_full = 900.0;
uniform float z_front = 140.0;   // RenderLook.Z_TERRAIN_FRONT: the top brightens from the back of the band to here
uniform vec2 char_fresh = vec2(0.04, 0.2);   // RenderLook.CHAR_FRESH: a groove warmer than y is not charred yet; the char comes in as its heat falls to x
uniform float char_gain = 1.0;               // 1; under reduced flashing RenderLook.CHAR_CALM
uniform float heat_gain = 1.0;               // 1; under reduced flashing RenderLook.HEAT_CALM
uniform float fog_far = 12000.0;

varying float v_base;
varying vec3 v_col;
varying float v_desert;
varying float v_dent;
varying float v_h;
varying float v_scorch;
varying float v_heat;
varying float v_back;
varying vec3 v_view;
varying float v_crack;
varying float v_rubble;
varying vec2 v_px;
varying float v_wz;
varying float v_street;
varying float v_new;          // how much of its own colour the ground keeps under a crater dug moments ago (ground.gdshaderinc crater_new; over CRATER_OPEN_S, over CRATER_CALM_S with reduced flashing)

void vertex() {
	int i = int(UV.x + 0.5) % nc;
	float xw = UV.x * col_w;
	float z = VERTEX.z;
	float b = gf(i, 0);
	vec4 g = ground_vertex(UV.x, UV2.y, z, MODEL_MATRIX[3].x);
	float h = g.x;
	float s = far_weight(z);
	float bio = gf(i, 14);   // the column's biome, BIOME_ORDER (desert 5)
	v_col = biome_colors[int(bio + 0.5)].rgb;
	v_desert = abs(bio - 5.0) < 0.5 ? 1.0 : 0.0;
	v_base = b;
	if (s > 0.0) {
		float xs = far_x(xw, z, s);
		v_col = mix(v_col, biome_rgb(xs), s);
		v_desert = abs(far_biome(xs) - 5.0) < 0.5 ? 1.0 : 0.0;
		v_base = mix(b, gfx(xs, 0), s);
	}
	VERTEX.y = h;
	NORMAL = normalize(vec3(-g.y, 1.0, -g.z));
	v_dent = g.w;
	v_h = h;
	float w = groove_half_at(i);
	float t = clamp(1.0 - z * z / (w * w), 0.0, 1.0);
	v_scorch = gh(i, 0) * t;
	v_heat = gh(i, 1) * t;
	v_crack = gf(i, 15) * t;
	v_rubble = abs(z) <= -z_band_back ? rubble_at(i, z) : 0.0;
	v_px = vec2(xw, z);
	v_street = street_n > 0 ? street_weight(xw) : 0.0;
	v_new = crater_new(i, xw, z, calm_ease > 0.0 ? crater_calm_s : crater_open_s);   // a new crater's colours come with its opening (more slowly with reduced flashing)
	v_back = clamp((z_front - z) / (z_front - z_band_back), 0.0, 1.0);
	vec4 bw = bent_world(MODEL_MATRIX, VERTEX);
	v_view = bw.xyz - INV_VIEW_MATRIX[3].xyz;   // from the camera, in world axes (the camera may be pitched)
	v_wz = bw.z;
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * bw);
}

void fragment() {
	vec3 c = v_col;
	if (v_base < sea_base && v_h < sea_base) {
		c = sea_floor.rgb;
	} else if (v_street > 0.001) {
		vec4 st = street_paint(v_px, fwidth(v_px.x));
		if (st.a <= 0.0) {
			st = block_paint(v_px, fwidth(v_px.x));   // between the streets: an avenue, or the district's paved lot
		}
		c = mix(c, st.rgb, st.a * v_street);
	}
	if (v_dent < -dent_min) {
		vec3 earth = v_desert > 0.5 ? crater_desert.rgb : crater.rgb;
		c = v_new > 0.0 ? mix(earth, c, v_new) : earth;
	} else if (v_dent > 0.5 * dent_min) {
		c = mix(c, ejecta.rgb, clamp(v_dent / (5.0 * dent_min), 0.0, 0.6) * (1.0 - v_new));
	}
	c = mix(c, snow.rgb, smoothstep(snow_from, snow_full, v_h));
	if (v_crack > 0.01) {
		vec2 q = v_px / 70.0;
		vec2 cell = floor(q);
		vec2 f = fract(q);
		float h1 = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
		float diag = abs(f.x - f.y * (0.4 + 0.6 * h1));
		float line = 1.0 - smoothstep(0.0, 0.05, min(edge, diag));
		c = mix(c, cracked.rgb, clamp(v_crack, 0.0, 1.0) * (0.3 + 0.7 * line));
	}
	if (v_rubble > 0.01) {
		vec2 q = v_px / 45.0;
		float n = fract(sin(dot(floor(q), vec2(41.3, 289.1))) * 43758.5453);
		c = mix(c, rubble.rgb * (0.8 + 0.4 * n), clamp(v_rubble / rubble_tint_h, 0.0, 1.0) * 0.9);
	}
	// A groove chars as it cools: under a fresh glow the ground keeps its own colour, so a beam's burn does not turn a
	// broad strip of ground dark in one tick.
	float fresh = smoothstep(char_fresh.x, char_fresh.y, v_heat);
	c = mix(c, char_col.rgb, clamp(v_scorch * 1.1, 0.0, 0.92) * char_gain * (1.0 - fresh) * (1.0 - v_new));
	c = flat_shade(c, NORMAL, 0.55) * mix(1.2, 0.95, v_back);
	c = c * wl_mul + wl_add;   // the world's light; the lane cue, the pair's mark and a groove's glow below are never dimmed
	vec4 cue = lane_cue_at(v_px, fwidth(v_px.y));
	c = mix(c, cue.rgb, cue.a);
	c = pair_mark_on(c, v_px, fwidth(v_px.y));
	float hh = clamp(v_heat, 0.0, 1.6);
	vec3 glow = mix(heat_lo.rgb, heat_hi.rgb, clamp(hh - 0.6, 0.0, 1.0));
	// The glow's tint comes in gently at low heat (a weak beam's groove is a faint red, not a dark one, at first).
	float opened = 1.0 - v_new;   // a new crater's glow comes with its opening too
	c = mix(c, glow, smoothstep(0.2, 1.0, hh) * 0.85 * heat_gain * opened) + glow * max(0.0, hh - 1.0) * 0.6 * heat_gain * heat_gain * opened;
	// Aerial perspective: hazing toward the horizon, the ground takes the sky's colour in its own direction.
	ALBEDO = haze_ground(c, v_view, -v_wz, fog_far);   // the haze by depth (skycol.gdshaderinc)
}
