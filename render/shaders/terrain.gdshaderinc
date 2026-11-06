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
#ifdef TILE_GROUND
uniform float ice_cap = 0.68;   // RenderLook.TILE_ICE_CAP: the brightest channel ice's ground reaches, after the world's light
#endif
uniform vec4 cracked : source_color;
uniform vec4 rubble : source_color;
uniform float rubble_tint_h = 20.0;
uniform vec2 rubble_cell = vec2(16.0, 0.12);   // the tile ground's rubble: a stone's size in units, and its spread of value
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
// Biome rendering window 3: the far land's ridges (RenderLook.FAR_LADDER_*; RenderBiomeLook rows ladder_row to + 2).
uniform bool ladder_on = true;
uniform int ladder_row = 28;
uniform float ladder_from = 0.5;
uniform vec2 ladder_z = vec2(22000.0, 36000.0);
uniform vec3 ladder_haze = vec3(0.0, 0.12, 0.25);
uniform vec3 ladder_tone = vec3(1.04, 1.0, 0.92);
uniform vec4 ladder_n[7] : source_color;   // the nearest and farthest ridge of each of GroundField.BIOME_ORDER (the far map's shares)
uniform vec4 ladder_f[7] : source_color;

varying float v_base;
varying vec3 v_col;
varying vec3 v_lad_n;         // the far land's nearest and farthest ridge colour (window 3); the middle is halfway
varying vec3 v_lad_f;
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

#ifdef TILE_GROUND
#include "res://render/shaders/tile_vertex.gdshaderinc"
#else
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
	int pid = int(gf(i, 21) + 0.5);   // the column's palette id (zone A: its own biome outside a zone)
	v_lad_n = biome_tone(pid, ladder_row);
	v_lad_f = biome_tone(pid, ladder_row + 2);
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
		float wsum = max(dot(w0, vec4(1.0)) + w1.x + w1.y + w1.z, 0.001);
		v_col = mix(v_col, fc / wsum, s);
		vec3 ln = ladder_n[0].rgb * w0.x + ladder_n[1].rgb * w0.y + ladder_n[2].rgb * w0.z + ladder_n[3].rgb * w0.w
			+ ladder_n[4].rgb * w1.x + ladder_n[5].rgb * w1.y + ladder_n[6].rgb * w1.z;
		vec3 lf = ladder_f[0].rgb * w0.x + ladder_f[1].rgb * w0.y + ladder_f[2].rgb * w0.z + ladder_f[3].rgb * w0.w
			+ ladder_f[4].rgb * w1.x + ladder_f[5].rgb * w1.y + ladder_f[6].rgb * w1.z;
		v_lad_n = mix(v_lad_n, ln / wsum, s);
		v_lad_f = mix(v_lad_f, lf / wsum, s);
		v_desert = w1.y > 0.5 ? 1.0 : 0.0;
		v_base = mix(b, far_fetch(far_map, i0, fr, L).b, s);
	} else if (s > 0.0) {
#else
	if (s > 0.0) {
#endif
		float xs = far_x(xw, z, s);
		v_col = mix(v_col, biome_rgb(xs), s);
		float cf = xs / col_w;
		cf -= float(nc) * floor(cf / float(nc));
		int fid = int(gf(min(int(cf), nc - 1), 21) + 0.5);   // the far column's palette id
		v_lad_n = mix(v_lad_n, biome_tone(fid, ladder_row), s);
		v_lad_f = mix(v_lad_f, biome_tone(fid, ladder_row + 2), s);
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
#endif

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
#ifdef TILE_GROUND
	// The node's own biome. A border wanders up to a third of a node, keyed to the planet (Art's look check), with one flat band between
	// the two biomes where the next node over is the other one. Hard edges only: no blend, no dither.
	vec2 u_w = v_uv + vec2(tile_tri(v_q.y + 0.7 * v_q.z), tile_tri(v_q.x + 0.6 * v_q.z)) * 0.33;
	int v_la = int(v_layer + 0.5);
	ivec2 u_a = clamp(ivec2(floor(u_w + 0.5)), ivec2(0), ivec2(27));
	ivec2 u_b = clamp(ivec2(floor(u_w + 0.95)), ivec2(0), ivec2(27));
	int v_ba = int(texelFetch(ids, ivec3(u_a, v_la), 0).r * 255.0 + 0.5);
	int v_bb = int(texelFetch(ids, ivec3(u_b, v_la), 0).r * 255.0 + 0.5);
	float zf = v_ba == v_bb ? 0.0 : 0.5;
#else
	float cx = v_px.x / col_w;
	int ci = int(cx - float(nc) * floor(cx / float(nc))) % nc;
	int v_ba = int(gf(ci, 21) + 0.5);
	int v_bb = int(gf(ci, 22) + 0.5);
	float jb = gf(ci, 23);
	float du = cx - jb;
	du -= float(nc) * floor(du / float(nc) + 0.5);
	float zt = (jb < -1.0e8 || v_ba == v_bb) ? 0.0 : clamp(0.5 + du * col_w / biome_zone, 0.0, 1.0);
	float zf = zt <= 0.0 ? 0.0 : (zt >= 1.0 ? 1.0 : (floor(zt * 5.0) + 0.5) / 5.0);
#endif
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
	// The far land (window 3, Art's value ladder): past ladder_from of the far blend, its biome's three ridges by depth
	// behind the fighter plane in hard steps, nearest the darkest, lit, mid and shade by the same light; hazed below by
	// the ridge's own step. Without the ladder, its own colour shaded as before.
	int lk = -1;
	if (ladder_on && v_s >= ladder_from) {
#ifdef TILE_GROUND
		float zb = v_rad;
#else
		float zb = -v_px.y;
#endif
		lk = zb < ladder_z.x ? 0 : (zb < ladder_z.y ? 1 : 2);
		c = (lk == 0 ? v_lad_n : (lk == 1 ? mix(v_lad_n, v_lad_f, 0.5) : v_lad_f)) * (tone == 0 ? ladder_tone.x : (tone == 2 ? ladder_tone.z : ladder_tone.y));
	} else if (!ladder_on) {
		c = mix(c, flat_shade(v_col, NORMAL, 0.55) * mix(1.2, 0.95, v_back), v_s);   // the far land: its own colour, shaded as before
	}
	if (lk < 0 && v_base < sea_base && v_h < sea_base) {
		c = mix(sea_floor.rgb * tk, c, v_s);
#ifdef TILE_GROUND
	} else if (v_street > 0.001 && length(v_grad) < rock_slope.x) {   // no paint on a slope it would streak down
#else
	} else if (v_street > 0.001) {
#endif
		vec4 st = street_paint(v_px, fwidth(v_px.x));
		if (st.a <= 0.0) {
			st = block_paint(v_px, fwidth(v_px.x));   // between the streets: an avenue, or the district's paved lot
		}
		c = mix(c, st.rgb * tk, st.a * v_street);
	}
	if (v_dent < -dent_min) {
#ifdef TILE_GROUND
		vec3 earth;
		if (crater_look > 0.5) {
			// Art's crater: hard edges and flat colour. A wall's tone is which way it faces, in eight flat sides, against the biome's light.
			float cd = -v_dent;
			float cs = length(v_dg);
			float cf = floor(atan(v_dg.y, v_dg.x) / 0.7853982 + 0.5) * 0.7853982;
			float cl = dot(-vec2(cos(cf), sin(cf)), normalize(sun_dir.xz));
			int ct = cl > 0.35 ? 0 : (cl < -0.35 ? 2 : 1);
			earth = mix(biome_tone(v_ba, 6 + ct), biome_tone(v_bb, 6 + ct), zf);
			if (cs < crater_rings.w || cd >= crater_rings.z) {
				// The floor: warm, in flat stripes at slightly different slants.
				float cz = dot(v_q.xz, vec2(0.83, 0.55)) + 0.35 * tile_tri(v_q.x * 0.31 - v_q.z * 0.17);
				earth = mix(biome_tone(v_ba, 8), biome_tone(v_bb, 8), zf) * crater_steps.y * (1.0 + crater_steps.z * (mod(floor(cz / crater_steps.w), 3.0) - 1.0));
			} else if (cd >= crater_rings.y) {
				earth *= crater_steps.x;
			} else if (cd < crater_rings.x + dent_min && cl > 0.0) {
				earth = mix(biome_tone(v_ba, 6), biome_tone(v_bb, 6), zf);   // the lip: only on an edge facing the light
			}
		} else {
			earth = mix(biome_tone(v_ba, 6 + tone), biome_tone(v_bb, 6 + tone), zf);   // a crater's inside: the subsoil (Art), not the surface
		}
#else
		vec3 earth = mix(biome_tone(v_ba, 6 + tone), biome_tone(v_bb, 6 + tone), zf);   // a crater's inside: the subsoil (Art), not the surface
#endif
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
#ifdef TILE_GROUND
		// Stones keyed to the planet, small and close in value: the strip's 45-unit squares read as a checker on a hill face toward the camera.
		float n = floor(fract(sin(dot(floor(v_q * (128.0 / rubble_cell.x)), vec3(41.3, 289.1, 113.7))) * 43758.5453) * 3.0) * 0.5;   // three hard steps
		c = mix(c, rubble.rgb * (1.0 + rubble_cell.y * (n - 0.5)), clamp(v_rubble / rubble_tint_h, 0.0, 1.0) * 0.9);
#else
		vec2 q = v_px / 45.0;
		float n = fract(sin(dot(floor(q), vec2(41.3, 289.1))) * 43758.5453);
		c = mix(c, rubble.rgb * (0.8 + 0.4 * n), clamp(v_rubble / rubble_tint_h, 0.0, 1.0) * 0.9);
#endif
	}
	// A groove chars as it cools: under a fresh glow the ground keeps its own colour, so a beam's burn does not turn a
	// broad strip of ground dark in one tick.
	float fresh = smoothstep(char_fresh.x, char_fresh.y, v_heat);
	// A beam's scar (Art's damage language): a flat band in the biome's scar colour, a thin edge in its edge colour.
	float sc = clamp(v_scorch * 1.1, 0.0, 0.92) * char_gain * (1.0 - fresh) * (1.0 - v_new);
	// The band is where the burn passes scar_band.y; its edge a rim of scar_band.x pixels just inside the band's border, so a
	// faded scar narrows and goes, and never turns into a wide pale band.
#ifdef TILE_GROUND
	if (crater_look > 0.5) {
		if (v_scorch > 0.0) {
		// Art's scar: read by the pixel from the column, so it's as narrow as the look wants and not as wide as the mesh's corners say.
		float scx = v_px.x / col_w;
		int sci = int(scx - float(nc) * floor(scx / float(nc))) % nc;
		float sleft = mix(texelFetch(scar_tex, ivec2(sci, 0), 0).r, texelFetch(scar_tex, ivec2((sci + 1) % nc, 0), 0).r, fract(scx));
		if (sleft > 0.0 && clamp(gh(sci, 0) * 1.1, 0.0, 0.92) * char_gain * (1.0 - fresh) * (1.0 - v_new) > scar_band.y) {
			float sside = v_px.y > 0.0 ? 13.0 : 0.0;   // each side its own outline
			// The burn's own width, without a slide's trench, which jumps from column to column.
			float sg0 = groove_w0 + groove_wp * clamp((gh(sci, 0) - groove_i0) / groove_ip, groove_pmin, groove_pmax);
			float sg1 = groove_w0 + groove_wp * clamp((gh((sci + 1) % nc, 0) - groove_i0) / groove_ip, groove_pmin, groove_pmax);
			// Stronger beams burn wider: the look's width is the strongest beam's, a weak one's a little over half of it.
			float spn = clamp((clamp((gh(sci, 0) - groove_i0) / groove_ip, groove_pmin, groove_pmax) - groove_pmin) / max(groove_pmax - groove_pmin, 0.001), 0.0, 1.0);
			float swid = mix(sg0, sg1, fract(scx)) * scar_look.x * (0.55 + 0.45 * spn) * sleft * (1.0 + scar_look.y * tile_tri((scx + sside) * scar_look.z));
			float sz = abs(v_px.y) / max(swid, 1.0);
			if (sz < 1.0) {
				if (sz > 1.0 - fwidth(sz) * scar_band.x) {
					c = mix(biome_tone(v_ba, 10), biome_tone(v_bb, 10), zf);
				} else {
					float sst = dot(v_q.xz, vec2(0.83, 0.55)) + 0.35 * tile_tri(v_q.x * 0.31 - v_q.z * 0.17);
					c = mix(biome_tone(v_ba, 9), biome_tone(v_bb, 9), zf) * (1.0 + crater_steps.z * (mod(floor(sst / crater_steps.w), 3.0) - 1.0));
				}
			} else if (sz < 1.0 + scar_look.w) {
				c *= scar_fringe;
			}
		}
		}
	} else if (sc > scar_band.y) {
		float rim = fwidth(sc) * scar_band.x;
		c = mix(biome_tone(v_ba, sc > scar_band.y + rim ? 9 : 10), biome_tone(v_bb, sc > scar_band.y + rim ? 9 : 10), zf);
	}
#else
	if (sc > scar_band.y) {
		float rim = fwidth(sc) * scar_band.x;
		c = mix(biome_tone(v_ba, sc > scar_band.y + rim ? 9 : 10), biome_tone(v_bb, sc > scar_band.y + rim ? 9 : 10), zf);
	}
#endif
#ifdef TILE_GROUND
	// One tone in front of the plane: its big facets, close to the lens, are a swing's flash (docs/camera/swing-view.md). Marks keep their colours.
	if (fore_tone > 0.5 && v_pv.y > 0.0 && abs(v_dent) < dent_min && v_rubble <= 0.01 && v_crack <= 0.01) {
		c = mix(biome_tone(v_ba, 2), biome_tone(v_bb, 2), zf);   // the biome's shade colour (Art: docs/art/tile-ground-look.md)
	}
#endif
	c = c * wl_mul + wl_add;   // the world's light; the lane cue, the pair's mark and a groove's glow below are never dimmed
#ifdef TILE_GROUND
	// Ice above the water (World's fine ids 5 and 6): a low sun would clip Art's warm white to the brightest thing in the frame, above a beam. Its hue stays.
	if (v_h > sea_base && (v_ba == 5 || v_ba == 6 || v_bb == 5 || v_bb == 6)) {
		c *= min(1.0, ice_cap / max(max(c.r, c.g), max(c.b, 0.001)));
	}
#endif
#ifdef TILE_GROUND
	vec4 cue = lane_cue_at(v_pv, fwidth(v_pv.y));
#else
	vec4 cue = lane_cue_at(v_px, fwidth(v_px.y));
#endif
	c = mix(c, cue.rgb, cue.a);
#ifdef TILE_GROUND
	c = pair_mark_on(c, v_pv, fwidth(v_pv.y));
#else
	c = pair_mark_on(c, v_px, fwidth(v_px.y));
#endif
	float hh = clamp(v_heat, 0.0, 1.6);
	vec3 glow = mix(heat_lo.rgb, heat_hi.rgb, clamp(hh - 0.6, 0.0, 1.0));
	// The glow's tint comes in gently at low heat (a weak beam's groove is a faint red, not a dark one, at first).
	float opened = 1.0 - v_new;   // a new crater's glow comes with its opening too
	c = mix(c, glow, smoothstep(0.2, 1.0, hh) * 0.85 * heat_gain * opened) + glow * max(0.0, hh - 1.0) * 0.6 * heat_gain * heat_gain * opened;
	// Aerial perspective: hazing toward the horizon, the ground takes the sky's colour in its own direction.
	ALBEDO = lk >= 0 ? haze_step(c, v_view, -v_wz, fog_far, lk == 0 ? ladder_haze.x : (lk == 1 ? ladder_haze.y : ladder_haze.z)) : haze_ground(c, v_view, -v_wz, fog_far);   // the haze by depth (skycol.gdshaderinc); the far land's in its ridges' steps
}
