// SCRATCH: a tile of the swing test's ground. The instance's matrix carries its cube face and place, its custom its layer and morph.
shader_type spatial;
render_mode unshaded, cull_disabled;
#include "res://swing/place.gdshaderinc"

uniform sampler2DArray hts : filter_nearest, repeat_disable;
uniform sampler2DArray cols : filter_nearest, repeat_disable;
uniform vec3 sun_view = vec3(-0.5, 0.7, 0.3);
uniform vec3 haze_col : source_color = vec3(0.96, 0.72, 0.48);
uniform vec3 clear_haze = vec3(1.0);      // 0 in the seam test, so the ground is what it is
uniform float surface_detail = 0.0;       // visual only: a fragment's light, never a height, so no foot moves
varying vec3 v_dir;
varying vec3 v_col;
varying vec3 v_pos;

void vertex() {
	vec3 n = MODEL_MATRIX[0].xyz;
	vec3 u = MODEL_MATRIX[1].xyz;
	vec3 w = MODEL_MATRIX[2].xyz;
	vec3 place = MODEL_MATRIX[3].xyz;
	vec2 g = UV * 32.0;
	// How far this vertex has gone to the coarser level's lattice: by distance, or the tile's own sharpening.
	vec2 st0 = place.xy + UV * place.z;
	vec3 d0 = normalize(n + u * tan(st0.x * 0.7853982) + w * tan(st0.y * 0.7853982));
	float dist = atan(length(cross(d0, pv)), dot(d0, pv)) * planet_r;
	float mk = max(smoothstep(INSTANCE_CUSTOM.g * 1000.0, INSTANCE_CUSTOM.b * 1000.0, dist), 1.0 - INSTANCE_CUSTOM.a);
	vec2 gm = g - mod(g, 2.0) * mk;
	vec2 st = place.xy + gm / 32.0 * place.z;
	vec3 dir = normalize(n + u * tan(st.x * 0.7853982) + w * tan(st.y * 0.7853982));
	int layer = int(INSTANCE_CUSTOM.r + 0.5);
	ivec2 i0 = ivec2(floor(gm));
	ivec2 i1 = min(i0 + ivec2(1), ivec2(32));
	vec2 f = gm - vec2(i0);
	float h = mix(mix(texelFetch(hts, ivec3(i0.x, i0.y, layer), 0).r, texelFetch(hts, ivec3(i1.x, i0.y, layer), 0).r, f.x),
		mix(texelFetch(hts, ivec3(i0.x, i1.y, layer), 0).r, texelFetch(hts, ivec3(i1.x, i1.y, layer), 0).r, f.x), f.y);
	v_col = texelFetch(cols, ivec3(i0.x, i0.y, layer), 0).rgb;
	v_dir = dir;
	vec2 p = ae(dir);
	float y = max(h, 0.0);
	if (p.y > 0.0) {
		y = min(y, sight_cap(p.y, 0.0));
	}
	y = bent(p.x, y, p.y);
	v_pos = vec3(p.x, y, p.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(p.x, y, p.y, 1.0));
}

float vh(vec3 c) {
	return fract(sin(dot(c, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float vn(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(vh(i), vh(i + vec3(1, 0, 0)), f.x), mix(vh(i + vec3(0, 1, 0)), vh(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(vh(i + vec3(0, 0, 1)), vh(i + vec3(1, 0, 1)), f.x), mix(vh(i + vec3(0, 1, 1)), vh(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z) - 0.5;
}

void fragment() {
	vec3 nrm = normalize(cross(dFdx(v_pos), dFdy(v_pos)));
	if (nrm.y < 0.0) {
		nrm = -nrm;
	}
	float lit = 0.72 + 0.34 * max(dot(nrm, sun_view), 0.0);
	float far_k = smoothstep(14000.0, 62000.0, length(v_pos.xz - vec2(0.0, cam.z))) * clear_haze.x;
	if (surface_detail > 0.0) {
		vec3 q = normalize(v_dir) * planet_r;
		float fade = 1.0 - smoothstep(2500.0, 12000.0, length(v_pos.xz - vec2(0.0, cam.z)));
		lit *= 1.0 + surface_detail * fade * (vn(q / 170.0) * 0.55 + vn(q / 61.0) * 0.3 + vn(q / 23.0) * 0.15);
	}
	ALBEDO = mix(v_col * lit, haze_col, far_k);
}
