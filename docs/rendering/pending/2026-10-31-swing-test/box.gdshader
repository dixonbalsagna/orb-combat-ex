// SCRATCH: a building of the swing test. Instance matrix: [0] its anchor, [1] the way its width runs, [2] (width, depth, height), [3] (foot, seed, damaged).
shader_type spatial;
render_mode unshaded, cull_disabled;
#include "res://swing/place.gdshaderinc"

uniform vec3 sun_view = vec3(-0.5, 0.7, 0.3);
uniform vec3 haze_col : source_color = vec3(0.96, 0.72, 0.48);
varying vec3 v_loc;      // its own metres: a face's windows and a damage mark don't know the world
varying vec3 v_size;
varying vec3 v_nrm;
varying vec3 v_seed;
varying float v_z;
varying float v_dist;
varying vec3 v_ln;
varying float v_kept;
uniform vec3 keep_anchor = vec3(0.0);    // a wall that stops a fighter is drawn where it stops him (Game Design): no near rule for it

void vertex() {
	vec3 a = MODEL_MATRIX[0].xyz;
	vec3 e = MODEL_MATRIX[1].xyz;
	vec3 size = MODEL_MATRIX[2].xyz;
	vec3 info = MODEL_MATRIX[3].xyz;
	vec2 c; vec2 ex; vec2 ez;
	anchored(a, e, c, ex, ez);
	vec2 p = c + ex * VERTEX.x * size.x + ez * VERTEX.z * size.y;
	float tall = size.z;
	bool kept = dot(keep_anchor, keep_anchor) > 0.5 && distance(a, keep_anchor) < 1.0e-4;
	v_kept = kept ? 1.0 : 0.0;
	if (near_mode == 1 && !kept) {
		// Sink: the whole building eases into the ground over the 300 units before the line.
		float s = smoothstep(near_line - 300.0, near_line, c.y);
		tall *= 1.0 - s;
	}
	float y = info.x - 30.0 + VERTEX.y * (tall + 30.0);
	if (near_mode == 1 && !kept && c.y >= near_line) {
		y = info.x - 200.0;   // wholly sunk: under the ground, and it stays there until it comes round again
	}
	if (near_mode == 3 && !kept) {
		// The rule and sink together: the whole building goes down, its near side leading by half.
		float sa = smoothstep(near_line - 300.0, near_line, c.y);
		float sv = smoothstep(near_line - 500.0, near_line, p.y);
		y = info.x - 30.0 + VERTEX.y * (size.z + 30.0) * (1.0 - mix(sa, sv, 0.5));
		if (c.y >= near_line && p.y >= near_line - 200.0) {
			y = info.x - 200.0;
		}
	}
	if (near_mode == 4 && !kept) {
		// Sink and clip: it sinks to a third as its near side comes to the line, and what's left is cut there, dark inside and low.
		float front = c.y + 0.7 * max(size.x, size.y);
		y = info.x - 30.0 + VERTEX.y * (size.z + 30.0) * (1.0 - 0.67 * smoothstep(near_line - 400.0, near_line, front));
	}
	if (near_mode == 0 && !kept && p.y > near_line - 500.0) {
		// The rule: every vertex above the sight line to the plane's ground comes down to it, easing in over the 500 units before the line.
		float cap = sight_cap(p.x, max(p.y, 0.0), 0.0);
		float over = y - cap;
		float s = smoothstep(near_line - 500.0, near_line, p.y);
		if (over > 0.0) {
			y -= over * s;
		}
		if (p.y > near_line) {
			y -= 60.0;   // past the line what's left is under the ground's own cap, so no roof lies on it
		}
	}
	v_loc = vec3(VERTEX.x * size.x, (y - info.x), VERTEX.z * size.y);
	v_size = size;
	v_ln = NORMAL;
	v_nrm = normalize(vec3(ex.x, 0.0, ex.y) * NORMAL.x + vec3(0.0, 1.0, 0.0) * NORMAL.y + vec3(ez.x, 0.0, ez.y) * NORMAL.z);
	v_seed = info;
	v_z = p.y;
	v_dist = length(p - vec2(0.0, cam.z));
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(globe(p.x, y, p.y), 1.0));
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	if ((near_mode == 2 || near_mode == 4) && v_kept < 0.5 && v_z > near_line) {
		discard;
	}
	vec3 wall = mix(vec3(0.20, 0.25, 0.33), vec3(0.42, 0.33, 0.29), fract(v_seed.y * 7.0));
	vec3 c = wall * (0.8 + 0.3 * max(dot(v_nrm, sun_view), 0.0));
	// Windows, by its own face and floor: 44 units a floor.
	if (abs(v_ln.y) < 0.5) {
		float along = abs(v_ln.x) > 0.5 ? v_loc.z : v_loc.x;
		vec2 cell = vec2((along + 4000.0) / 46.0, v_loc.y / 44.0);
		vec2 fr = fract(cell);
		if (fr.x > 0.18 && fr.x < 0.82 && fr.y > 0.25 && fr.y < 0.8) {
			float on = hash(floor(cell) + floor(v_seed.y * 97.0 + 0.5));
			c = on > 0.62 ? vec3(0.98, 0.83, 0.50) : vec3(0.10, 0.16, 0.24);
		}
	}
	// The damaged tower: a dark breach and a band of floors out, in its own coordinates, so it can only turn with it.
	if (v_seed.z > 0.5) {
		float hh = v_size.z;
		if (v_loc.y > hh * 0.55 && v_loc.y < hh * 0.72) {
			c = vec3(0.03, 0.03, 0.04);
		}
		if (v_loc.y > hh * 0.72 && v_loc.y < hh * 0.74) {
			c = vec3(0.75, 0.32, 0.12);
		}
	}
	if (!FRONT_FACING) {
		c = vec3(0.02, 0.02, 0.03);   // a hard clip shows the inside as dark as it can
	}
	ALBEDO = mix(c, haze_col, smoothstep(14000.0, 62000.0, v_dist));
}
