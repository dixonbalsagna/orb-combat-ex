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
// (The body of terrain.gdshader and terrain_far.gdshader; FAR_MAP: the planet's own far map.)

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
uniform float facet_slope = 0.05;   // RenderLook.FACET_SUN, FACET_LIGHT, ROCK_SLOPE, ROCK_HIGH, DEPTH_STEP, STRATA_H, SCAR_BAND, TONE_K (biome rendering window 1)
uniform vec3 sun_dir = vec3(-0.5, 0.8, 0.33);
uniform vec2 rock_slope = vec2(0.45, 1.25);
uniform float rock_high = 0.3;
uniform vec2 depth_step = vec2(1.1, 0.94);
uniform float strata_h = 60.0;
uniform vec2 scar_band = vec2(1.5, 0.3);   // the scar's edge rim in pixels, and the burn where its band starts
uniform vec3 tone_k = vec3(1.06, 1.0, 0.86);

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
varying float v_s;            // the far land's weight (far_weight): the band's facets below it, the far land's own colour above
varying vec2 v_grad;          // the ground's slope (d height / dx, / dz), smooth across the mesh: a facet's tone follows it
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
	v_s = s;
	v_grad = g.yz;
#ifdef FAR_MAP
	if (s > 0.0 && far_map_on) {
		// the planet's own far land (World's map beside the ring; ground.gdshaderinc far4), turned by the slow drift:
		// its colour from the biomes' shares at the row's level
		int L = far_lod(z);
		ivec2 i0;
		vec2 fr;
		far_cell(far_dir((xw - z * drift_tan * s) / col_w, z), L, i0, fr);
		vec4 w0 = far_fetch(far_bio0, i0, fr, L);
		vec4 w1 = far_fetch(far_bio1, i0, fr, L);
		vec3 fc = biome_colors[0].rgb * w0.x + biome_colors[1].rgb * w0.y + biome_colors[2].rgb * w0.z + biome_colors[3].rgb * w0.w
			+ biome_colors[4].rgb * w1.x + biome_colors[5].rgb * w1.y + biome_colors[6].rgb * w1.z;
		v_col = mix(v_col, fc / max(dot(w0, vec4(1.0)) + w1.x + w1.y + w1.z, 0.001), s);
		v_desert = w1.y > 0.5 ? 1.0 : 0.0;
		v_base = mix(b, far_fetch(far_map, i0, fr, L).b, s);
	} else if (s > 0.0) {
#else
	if (s > 0.0) {
#endif
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
	// The ground's facet (Art's biome look, biome rendering window 1). Its light: the ground's normal against the sun
	// (upper left, a little toward the viewer), lit facing it, shade turned from it, mid on the flat (Art's rule along the
	// strip, and a slope in depth takes the light too). The normal is the ground's own, smooth across the mesh, so a tone's
	// edge follows the ground's shape as a clean contour, not the mesh's triangles. Its biome's colour steps across a
	// border's zone in five hard bands (10 to 90 percent).
	vec3 nrm = normalize(vec3(-v_grad.x, 1.0, -v_grad.y));
	float lt = dot(nrm, sun_dir) - sun_dir.y;
	int tone = lt > facet_slope ? 0 : (lt < -facet_slope ? 2 : 1);
	// The border zone (ground_field.gd zone_rows), read for this pixel's own column: the biomes either side (palette ids;
	// its own both sides outside one) and its place across the zone, stepped in five hard bands. Read here, not passed
	// from the vertices: a flat varying costs the old GPUs a rewrite of every draw's index buffer (ANGLE's D3D11), and a
	// vertex outside a zone carries none of it.
	float cx = v_px.x / col_w;
	int ci = int(cx - float(nc) * floor(cx / float(nc))) % nc;
	int v_ba = int(gf(ci, 21) + 0.5);
	int v_bb = int(gf(ci, 22) + 0.5);
	float jb = gf(ci, 23);
	float du = cx - jb;
	du -= float(nc) * floor(du / float(nc) + 0.5);
	float zt = (jb < -1.0e8 || v_ba == v_bb) ? 0.0 : clamp(0.5 + du * col_w / biome_zone, 0.0, 1.0);
	float zf = zt <= 0.0 ? 0.0 : (zt >= 1.0 ? 1.0 : (floor(zt * 5.0) + 0.5) / 5.0);
	vec3 rk = biome_tone(zf < 0.5 ? v_ba : v_bb, 11);   // r: the rock has strata; g: a rocky biome's height (/ 10,000) from which rock starts at gentler slopes
	// Rock by the ground's steepness, in Art's five hard bands from rock_slope.x to .y (so the green and the rock meet along
	// the slope's contour, stepped); in a rocky biome the rock starts at gentler slopes the higher it is, so the foot stays
	// green only where it is gentle.
	float above = rk.g * 10000.0;
	float g0 = rock_slope.x * (above > 0.0 ? mix(1.0, rock_high, clamp((v_h - above) / above, 0.0, 1.0)) : 1.0);
	float rr = clamp((length(v_grad) - g0) / max(rock_slope.y - g0, 0.01), 0.0, 1.0);
	float rs = rr <= 0.0 ? 0.0 : (rr >= 1.0 ? 1.0 : (floor(rr * 5.0) + 0.5) / 5.0);
	vec3 c = mix(mix(biome_tone(v_ba, tone), biome_tone(v_bb, tone), zf), mix(biome_tone(v_ba, 3 + tone), biome_tone(v_bb, 3 + tone), zf), rs);
	float tk = tone == 0 ? tone_k.x : (tone == 2 ? tone_k.z : tone_k.y);
	if (rs > 0.5 && rk.r > 0.5) {
		// strata lines on the rock: thin dark lines every strata_h of height (antialiased edges only)
		float sb = v_h / strata_h;
		float fw = fwidth(sb);
		float ln = (1.0 - smoothstep(0.0, fw * 1.2, abs(fract(sb + 0.5) - 0.5))) * (1.0 - smoothstep(0.12, 0.3, fw));   // none where the lines would crowd closer than a few pixels
		c = mix(c, c * 0.62, ln);
	}
	c *= mix(depth_step.x, depth_step.y, floor(clamp(v_back, 0.0, 0.999) * 3.0) * 0.5);   // the band's value by depth, in three hard steps
	c = mix(c, flat_shade(v_col, NORMAL, 0.55) * mix(1.2, 0.95, v_back), v_s);   // the far land: its own colour, shaded as before
	if (v_base < sea_base && v_h < sea_base) {
		c = mix(sea_floor.rgb * tk, c, v_s);
	} else if (v_street > 0.001) {
		vec4 st = street_paint(v_px, fwidth(v_px.x));
		if (st.a <= 0.0) {
			st = block_paint(v_px, fwidth(v_px.x));   // between the streets: an avenue, or the district's paved lot
		}
		c = mix(c, st.rgb * tk, st.a * v_street);
	}
	if (v_dent < -dent_min) {
		vec3 earth = mix(biome_tone(v_ba, 6 + tone), biome_tone(v_bb, 6 + tone), zf);   // a crater's inside: the subsoil (Art), not the surface
		c = v_new > 0.0 ? mix(earth, c, v_new) : earth;
	} else if (v_dent > 0.5 * dent_min) {
		c = mix(c, ejecta.rgb * tk, (v_dent > 2.5 * dent_min ? 0.5 : 0.25) * (1.0 - v_new));   // rubble on the rim, in two hard steps
	}
	if (v_h > snow_from) {
		c = snow.rgb * tk;   // snow on the peaks: a hard edge
	}
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
	// A beam's scar (Art's damage language): a flat band in the biome's scar colour, a thin edge in its edge colour.
	float sc = clamp(v_scorch * 1.1, 0.0, 0.92) * char_gain * (1.0 - fresh) * (1.0 - v_new);
	// The band is where the burn passes scar_band.y; its edge a rim of scar_band.x pixels just inside the band's border, so a
	// faded scar narrows and goes, and never turns into a wide pale band.
	if (sc > scar_band.y) {
		float rim = fwidth(sc) * scar_band.x;
		c = mix(biome_tone(v_ba, sc > scar_band.y + rim ? 9 : 10), biome_tone(v_bb, sc > scar_band.y + rim ? 9 : 10), zf);
	}
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
