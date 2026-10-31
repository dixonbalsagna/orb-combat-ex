// SCRATCH: the real figure (CrowdMesh) on the shared placement. Instance matrix: [0] its anchor, [1] the way it faces, [3].x its foot; custom its shirt and skin.
shader_type spatial;
render_mode unshaded, cull_back;
#include "res://render/shaders/color.gdshaderinc"
#include "res://swing/place.gdshaderinc"

uniform float figure_scale = 3.45;
uniform float outline = 0.7;
uniform vec4 outline_col : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform vec4 legs : source_color = vec4(0.17, 0.18, 0.25, 1.0);
uniform vec4 skin_a : source_color = vec4(0.95, 0.79, 0.65, 1.0);
uniform vec4 skin_b : source_color = vec4(0.55, 0.35, 0.23, 1.0);
varying vec4 v_custom;
varying float v_kind;
varying float v_z;

void vertex() {
	v_kind = UV.x;
	v_custom = INSTANCE_CUSTOM;
	vec3 a = MODEL_MATRIX[0].xyz;
	vec3 e = MODEL_MATRIX[1].xyz;
	float foot = MODEL_MATRIX[3].x;
	vec2 c; vec2 ex; vec2 ez;
	anchored(a, e, c, ex, ez);
	vec3 v = VERTEX;
	if (UV.x < 0.25) {
		v += NORMAL * outline;
	}
	float k = figure_scale;
	if (near_mode == 1) {
		k *= 1.0 - smoothstep(near_line - 300.0, near_line, c.y);
	}
	if (near_mode == 0 && c.y > near_line) {
		k = 0.0;   // a figure is gone where its street came down
	}
	vec2 p = c + (ex * v.x + ez * v.z) * k;
	float y = foot + v.y * k;
	v_z = p.y;
	y = bent(p.x, y, p.y);
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(p.x, y, p.y, 1.0));
}

void fragment() {
	if (near_mode == 2 && v_z > near_line) {
		discard;
	}
	vec3 c = v_kind < 0.25 ? outline_col.rgb : (v_kind < 0.65 ? v_custom.rgb : (v_kind < 0.9 ? mix(skin_a.rgb, skin_b.rgb, v_custom.a) : legs.rgb));
	ALBEDO = c;
}
