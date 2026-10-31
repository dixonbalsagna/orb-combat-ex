# SCRATCH: rendering.md section 11: the game's own tree, patched in a scratch copy only. Run from the copy's root. The bend gets the turn and the radial sag; buildings stub at the near line;
# the crowd takes the placement; a tile shader is made from the real terrain shader's own text, its fragment kept; PaneWorld calls SwingDrive; the capture hook and export take the bake.
import re, sys, os
def edit(p, pairs):
    s = open(p, encoding='utf-8', newline='').read().replace('\r', '')
    for a, b in pairs:
        assert s.count(a) >= 1, (p, a[:70])
        s = s.replace(a, b, 1)
    open(p, 'w', encoding='utf-8', newline='').write(s)

edit('render/shaders/bend.gdshaderinc', [
("""vec4 bent_world(mat4 model, vec3 v) {
	vec4 w = model * vec4(v, 1.0);
	float back = max(bend_focus - w.z, 0.0);
""", """uniform float sw_on = 0.0;               // the world turns about the pivot: this material's (SwingDrive)
uniform vec2 sw_cs = vec2(1.0, 0.0);
uniform float sw_px = 0.0;               // the pivot's x from the camera
uniform vec2 sw_band = vec2(0.0);        // what stands outside the place's band isn't drawn in this test (its ground is the planet's, not the strip's)
uniform float sw_front = 0.0;            // small things go at the near line
uniform float sw_line = -80.0;
uniform float r_eff = 0.0;               // above 0: the sag is the globe's, by radius, a share of the true curve (Camera's curve)

// A building's height at the near line: it sinks by the stub, the whole box, over 300 units.
float sw_stub(vec3 a, float top, float bot, float stub) {
	if (sw_on < 0.5) {
		return stub;
	}
	float z = (a.x - sw_px) * sw_cs.y + a.z * sw_cs.x;
	return min(stub, mix(top + 1.0, bot - 60.0, smoothstep(sw_line - 300.0, sw_line, z)));
}

vec4 bent_world(mat4 model, vec3 v) {
	vec4 w = model * vec4(v, 1.0);
	float qx = w.x - sw_px;
	float qz = w.z;
	if (sw_on > 0.5) {
		bool drop = sw_band.x > 0.0 && (abs(qx) > sw_band.x || abs(qz) > sw_band.y);
		w.x = sw_px + qx * sw_cs.x - qz * sw_cs.y;
		w.z = qx * sw_cs.y + qz * sw_cs.x;
		if (drop || (sw_front > 0.5 && w.z > sw_line)) {
			w.y -= 1.0e6;
		}
	}
	if (r_eff > 0.0) {
		// The globe: a point's radius from the pivot is its arc, its height is along the sphere's normal, so a wall leans as it would on a planet.
		float rx = w.x - sw_px;
		float rz = w.z;
		float r = sqrt(rx * rx + rz * rz);
		float ang = r / r_eff;
		if (ang > 1.5) {
			w.y -= 1.0e6;   // past the horizon of any height in the game
			return w;
		}
		float k = r > 0.01 ? (r_eff + w.y) * sin(ang) / r : 1.0;
		w.x = sw_px + rx * k;
		w.z = rz * k;
		w.y = (r_eff + w.y) * cos(ang) - r_eff;
		return w;
	}
	float back = max(bend_focus - w.z, 0.0);
"""),
])
edit('render/shaders/building.gdshader', [
("""	float stubbed = COLOR.a < 0.5 ? stub - 1.0 : stub;
""", """	stub = sw_stub(MODEL_MATRIX[3].xyz, top, top - length(MODEL_MATRIX[1].xyz), stub);
	float stubbed = COLOR.a < 0.5 ? stub - 1.0 : stub;
"""),
])
edit('render/shaders/crowd.gdshader', [
("""#include "res://render/shaders/color.gdshaderinc"
""", """#include "res://render/shaders/color.gdshaderinc"
#include "res://render/shaders/bend.gdshaderinc"
"""),
("""	VERTEX = v * boost * nearc;
	NORMAL = nrm;
""", """	VERTEX = v * boost * nearc;
	NORMAL = nrm;
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * bent_world(MODEL_MATRIX, VERTEX));
"""),
])
# The tile shader: the real terrain body with a new vertex stage. The fragment stays, but for the biome read (the node's, not the column's) and what lies in the view's frame.
s = open('render/shaders/terrain.gdshaderinc', encoding='utf-8', newline='').read().replace('\r', '')
i = s.index('void vertex() {')
j = s.index('void fragment() {')
vertex = """uniform sampler2DArray hts : filter_nearest, repeat_disable;
uniform sampler2DArray ids : filter_nearest, repeat_disable;
uniform vec3 pv = vec3(1.0, 0.0, 0.0);
uniform vec3 hd = vec3(0.0, 1.0, 0.0);
uniform vec3 sd = vec3(0.0, 0.0, 1.0);
uniform vec3 hd0 = vec3(0.0, 1.0, 0.0);
uniform vec3 sd0 = vec3(0.0, 0.0, 1.0);
uniform float strip_x = 0.0;
uniform sampler2D plane_tex : filter_nearest, repeat_disable;   // the line's own ground in view, 64 points: the foreground rule's sight lines end on it
uniform float plane_span = 3000.0;
uniform float sw_simple = 0.0;    // above 0.5: the biome's colour alone, to measure what the real fragment costs
varying vec2 v_uv;
varying float v_layer;
varying float v_rad;
varying float v_h0;
varying vec2 v_pv;

vec2 ae(vec3 d, vec3 h, vec3 s) {
	float x = dot(d, h);
	float z = dot(d, s);
	float q = sqrt(x * x + z * z);
	float k = q > 1.0e-5 ? atan(q, dot(d, pv)) / q : 1.0;
	return vec2(x, z) * k * planet_r;
}

float tile_h(ivec2 a, int layer) {
	return texelFetch(hts, ivec3(clamp(a.x, 0, 32), clamp(a.y, 0, 32), layer), 0).r;
}

vec3 tile_dir(vec3 n, vec3 u, vec3 w, vec2 st) {
	return normalize(n + u * tan(st.x * 0.7853982) + w * tan(st.y * 0.7853982));
}

void vertex() {
	vec3 n = MODEL_MATRIX[0].xyz;
	vec3 u = MODEL_MATRIX[1].xyz;
	vec3 wv = MODEL_MATRIX[2].xyz;
	vec3 place = MODEL_MATRIX[3].xyz;
	vec2 uvc = clamp(UV, vec2(0.0), vec2(1.0));
	float skirt = (UV.x != uvc.x || UV.y != uvc.y) ? 1.0 : 0.0;
	vec2 g = uvc * 32.0;
	vec2 st0 = place.xy + uvc * place.z;
	vec3 d0 = tile_dir(n, u, wv, st0);
	float dist = atan(length(cross(d0, pv)), dot(d0, pv)) * planet_r;
	float mk = smoothstep(INSTANCE_CUSTOM.g * 1000.0, INSTANCE_CUSTOM.b * 1000.0, dist);
	vec2 gm = g - mod(g, 2.0) * mk;
	vec2 st = place.xy + gm / 32.0 * place.z;
	vec3 dir = tile_dir(n, u, wv, st);
	int layer = int(INSTANCE_CUSTOM.r + 0.5);
	ivec2 i0 = ivec2(floor(gm));
	ivec2 i1 = min(i0 + ivec2(1), ivec2(32));
	vec2 f = gm - vec2(i0);
	float h = mix(mix(tile_h(i0, layer), tile_h(ivec2(i1.x, i0.y), layer), f.x), mix(tile_h(ivec2(i0.x, i1.y), layer), tile_h(i1, layer), f.x), f.y);
	// The slope, by the chart's own axes, so its light turns with the land: a solid thing under a fixed sun.
	ivec2 ic = ivec2(floor(gm + 0.5));
	float cell = 1.0 / 32.0 * place.z;
	vec2 c0 = ae(dir, hd0, sd0);
	vec2 cs = ae(tile_dir(n, u, wv, st + vec2(cell, 0.0)), hd0, sd0) - c0;
	vec2 ct = ae(tile_dir(n, u, wv, st + vec2(0.0, cell)), hd0, sd0) - c0;
	float hs = 0.5 * (tile_h(ic + ivec2(1, 0), layer) - tile_h(ic - ivec2(1, 0), layer));
	float ht = 0.5 * (tile_h(ic + ivec2(0, 1), layer) - tile_h(ic - ivec2(0, 1), layer));
	float det = cs.x * ct.y - cs.y * ct.x;
	v_grad = abs(det) > 1.0e-3 ? vec2(hs * ct.y - ht * cs.y, ht * cs.x - hs * ct.x) / det : vec2(0.0);
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
	v_dent = 0.0;
	v_scorch = 0.0;
	v_heat = 0.0;
	v_crack = 0.0;
	v_rubble = 0.0;
	v_new = 0.0;
	v_px = vec2(strip_x + c0.x, c0.y);
	v_street = street_n > 0 ? street_weight(v_px.x) : 0.0;
	vec2 p = ae(dir, hd, sd);
	v_pv = vec2(strip_x + p.x, p.y);
	v_back = clamp((z_front - p.y) / (z_front - z_band_back), 0.0, 1.0);
	float y = max(h, 0.0);
	if (p.y > 0.0) {
		float t = min(p.y / fore_cam.z, 0.95);
		float u = clamp((p.x / (1.0 - t) + plane_span) / (2.0 * plane_span), 0.0, 1.0) * 63.0;
		int ua = int(u);
		float pl = mix(texelFetch(plane_tex, ivec2(ua, 0), 0).r, texelFetch(plane_tex, ivec2(min(ua + 1, 63), 0), 0).r, u - float(ua));
		y = min(y, mix(pl, fore_cam.y, t) - fore_drop * p.y);
	}
	v_h = y;
	y -= skirt * INSTANCE_CUSTOM.a * 1000.0 * 0.05;
	float rr = length(p);
	float ang = rr / r_eff;
	float kk = rr > 0.01 ? (r_eff + y) * sin(ang) / rr : 1.0;
	vec4 bw = vec4(sw_px + p.x * kk, (r_eff + y) * cos(ang) - r_eff, p.y * kk, 1.0);
	v_view = bw.xyz - INV_VIEW_MATRIX[3].xyz;
	v_wz = bw.z;
	NORMAL = normalize(vec3(-v_grad.x, 1.0, -v_grad.y));
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * bw);
}

"""
body = s[:i] + vertex + s[j:]
zone_a = body.index('	float cx = v_px.x / col_w;')
zone_b = body.index('	vec3 rk = biome_tone(')
body = body.replace('void fragment() {\n', 'void fragment() {\n\tif (sw_simple > 0.5) {\n\t\tALBEDO = v_col * wl_mul + wl_add;\n\t} else {\n', 1)
k_end = body.rindex('}')
body = body[:k_end] + '\t}\n}\n'
zone_a = body.index('	float cx = v_px.x / col_w;')
zone_b = body.index('	vec3 rk = biome_tone(')
body = body[:zone_a] + """	int v_ba = int(texelFetch(ids, ivec3(int(v_uv.x + 0.5), int(v_uv.y + 0.5), int(v_layer + 0.5)), 0).r * 255.0 + 0.5);
	int v_bb = v_ba;
	float zf = 0.0;
""" + body[zone_b:]
for a, b in [
    ("float zb = -v_px.y;", "float zb = v_rad;"),
    ("vec4 cue = lane_cue_at(v_px, fwidth(v_px.y));", "vec4 cue = lane_cue_at(v_pv, fwidth(v_pv.y));"),
    ("c = pair_mark_on(c, v_px, fwidth(v_px.y));", "c = pair_mark_on(c, v_pv, fwidth(v_pv.y));"),
    ("	c = c * wl_mul + wl_add;   // the world's light;", """	if (v_h0 < 0.0) {
		c = (v_h0 > -37.5 ? vec3(0.27, 0.56, 0.72) : (v_h0 > -240.0 ? vec3(0.17, 0.42, 0.65) : vec3(0.12, 0.33, 0.56))) * tk;   // water, as a colour in this test
	}
	c = c * wl_mul + wl_add;   // the world's light;"""),
]:
    assert body.count(a) == 1, a
    body = body.replace(a, b)
os.makedirs('swing', exist_ok=True)
open('swing/tile.gdshader', 'w', encoding='utf-8', newline='').write('// SCRATCH: made from render/shaders/terrain.gdshaderinc by sg_patch.py.\nshader_type spatial;\nrender_mode unshaded, cull_disabled;\n\n' + body)
edit('render/core/pane_world.gd', [
("""	planet.update(S, cam_x, host.impact.heat, host.impact.heat_changed)
""", """	planet.update(S, cam_x, host.impact.heat, host.impact.heat_changed)
	if _swing == null:
		_swing = SwingDrive.new(self)
	_swing.apply(host, cam_x, vp)
"""),
("""	planet.cull_to(cam_rig, vis_plane) """, """	if SwingDrive.word("sw") == "":
		planet.cull_to(cam_rig, vis_plane) """),
("""var pan_haze: float = 0.0 ""","""var _swing: SwingDrive = null
var pan_haze: float = 0.0 """),
])
# The CPU's twin of the bend, for what's placed rather than bent.
p = 'export_presets.cfg'
s = open(p, encoding='utf-8', newline='').read()
s = s.replace('include_filter="build_info.json"', 'include_filter="build_info.json,swing/*/*.bin,swing/*/*.json"')
open(p, 'w', encoding='utf-8', newline='').write(s)
print('sg patch')
