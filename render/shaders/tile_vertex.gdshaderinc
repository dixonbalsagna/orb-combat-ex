// The tile ground's vertex stage (RenderTileGround; terrain_tile.gdshader). A tile is an instance: its face's axes and its place on
// the face (s, t, size), its layer and the data's level, its morph (tile_read.gdshaderinc). A mesh finer than the data keeps the ground the
// sim will stand on. What lies on the ground today (craters, scorch, streets, a groove's heat) still comes from the strip's own rows, read at
// this vertex's place in the strip's frame.
#include "res://render/shaders/tile_read.gdshaderinc"
varying vec2 v_uv;
varying float v_layer;
varying float v_rad;
varying float v_h0;
varying vec2 v_pv;
varying float v_wet;     // a lake's or a river's depth here (RenderTileField.WET_STEP)
varying vec2 v_dg;       // a crater's own slope here, without the land's: which way its wall faces
varying vec3 v_q;        // the planet's direction, in nodes: what a border's wander is keyed to, so it stays with the land

// A straight-sided wave, -1 to 1: a border wanders in straight runs, as the flat look draws an edge.
float tile_tri(float x) {
	return abs(fract(x * 0.37) * 2.0 - 1.0) * 2.0 - 1.0;
}

void vertex() {
	vec3 dir;
	float skirt;
	float h;
	float wet_n;
	ivec2 ic;
	int layer;
	float dist;
	vec2 st;
	float dsize;
	tile_node(MODEL_MATRIX, INSTANCE_CUSTOM, UV, dir, skirt, h, wet_n, ic, layer, dist, st, dsize);
	vec3 n = MODEL_MATRIX[0].xyz;
	vec3 u = MODEL_MATRIX[1].xyz;
	vec3 wv = MODEL_MATRIX[2].xyz;
	// The slope, by the strip frame's own axes, so its light stays with the land: a solid thing under a fixed sun.
	float cell = dsize / 25.0;
	vec2 c0 = tile_chart(dir, hdp, sdp, pvp);
	vec2 cs = tile_chart(tile_dir(n, u, wv, st + vec2(cell, 0.0)), hdp, sdp, pvp) - c0;
	vec2 ct = tile_chart(tile_dir(n, u, wv, st + vec2(0.0, cell)), hdp, sdp, pvp) - c0;
	// Over a canonical cell on the sub-node tiles: their nodes lie on its flat triangles, and a one-node slope would jump at each triangle's edge.
	int span = max(int(1.0 / (6.0 * dsize) + 0.5), 1);
	ivec2 sa = min(ivec2(span), ivec2(27) - ic);
	ivec2 sb = min(ivec2(span), ic);
	float hs = (tile_h(ic + ivec2(sa.x, 0), layer) - tile_h(ic - ivec2(sb.x, 0), layer)) / float(max(sa.x + sb.x, 1));
	float ht = (tile_h(ic + ivec2(0, sa.y), layer) - tile_h(ic - ivec2(0, sb.y), layer)) / float(max(sa.y + sb.y, 1));
	float det = cs.x * ct.y - cs.y * ct.x;
	v_grad = abs(det) > 1.0e-3 ? vec2(hs * ct.y - ht * cs.y, ht * cs.x - hs * ct.x) / det : vec2(0.0);
	// The bowls near the camera, and their slope by the same chart.
	float bw0 = 0.0;
	vec2 bg = vec2(0.0);
	if (cb_n > 0) {
		bw0 = tile_bowls(dir);
		float bs = tile_bowls(tile_dir(n, u, wv, st + vec2(cell, 0.0))) - bw0;
		float bt = tile_bowls(tile_dir(n, u, wv, st + vec2(0.0, cell))) - bw0;
		bg = abs(det) > 1.0e-3 ? vec2(bs * ct.y - bt * cs.y, bt * cs.x - bs * ct.x) / det : vec2(0.0);
		v_grad += bg;
	}
	float sl = far_weight(dist);
	int pid = int(texelFetch(ids, ivec3(ic.x, ic.y, layer), 0).r * 255.0 + 0.5);
	v_col = biome_tone(pid, 1);
	v_lad_n = biome_tone(pid, ladder_row);
	v_lad_f = biome_tone(pid, ladder_row + 2);
	v_desert = 0.0;
	v_base = h;
	v_s = sl;
	v_uv = vec2(ic);
	v_layer = float(layer);
	v_rad = dist;
	v_h0 = h;
	v_wet = wet_n;
	v_q = dir * globe_r / 128.0;
	// The strip's frame: this point's place along the line, and its depth, as the strip's rows have them.
	float z0 = asin(clamp(dot(dir, sd0), -1.0, 1.0)) * globe_r;
	float xr = atan(dot(dir, hd0), dot(dir, pv0)) * globe_r;
	float xw = strip_x + xr;
	xw -= world_w * floor(xw / world_w);
	int ci = int(xw / col_w) % nc;
	v_px = vec2(xw, z0);
	v_dent = 0.0;
	v_dg = bg;
	v_scorch = 0.0;
	v_heat = 0.0;
	v_crack = 0.0;
	v_rubble = 0.0;
	v_new = 0.0;
	float z_abs = abs(z0);
	if (z_abs <= -z_band_back + 0.5) {
		vec4 gr = ground4(ci, xw, z0, false, 0.0);
		h += gr.w;
		v_dent = gr.w;
		v_grad += vec2(gr.y - base_slope(ci), gr.z);
		v_dg += vec2(gr.y - base_slope(ci), gr.z);
		float gw = groove_half_at(ci);
		float gt = clamp(1.0 - z0 * z0 / (gw * gw), 0.0, 1.0);
		v_scorch = gh(ci, 0) * gt;
		v_heat = gh(ci, 1) * gt;
		v_crack = gf(ci, 15) * gt;
		v_rubble = rubble_at(ci, z0);
		v_new = crater_new(ci, xw, z0, calm_ease > 0.0 ? crater_calm_s : crater_open_s);
	}
	h += bw0;
	v_dent += bw0;
	v_street = street_n > 0 ? street_weight(xw) : 0.0;
	vec2 p = tile_chart(dir, hd, sd, pv);
	v_pv = vec2(strip_x + p.x, p.y);
	v_back = clamp((z_front - p.y) / (z_front - z_band_back), 0.0, 1.0);
	float y = tile_fore(h, p);   // the real bed under the sea and a lake: the water sheet lies over it (water_tile.gdshader)
	v_h = y;
	y -= skirt * mod(INSTANCE_CUSTOM.a, 16.0) * 1000.0 * 0.05;
	float rr = globe_r + y;
	vec4 bw = vec4(rr * dot(dir, hd), rr * dot(dir, pv) - globe_r, rr * dot(dir, sd), 1.0);
	v_view = bw.xyz - INV_VIEW_MATRIX[3].xyz;
	v_wz = bw.z;
	NORMAL = normalize(vec3(-v_grad.x, 1.0, -v_grad.y));
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * bw);
}
