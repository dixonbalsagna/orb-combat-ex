// The blast cloud's body (docs/vfx/catastrophe-plan.md section 2): stem, rolling cap and ground dust wall as one MultiMesh of billboards whose positions are closed-form curves of the cloud's age
// (cloud_curves.gdshaderinc), so it has no state and one draw call. Alpha-blended smoke with a billowy noise-broken edge, never a hard outline and never a clean arc (c06: no dome of light, no ring).
// The instance transforms are all identity and never change; INSTANCE_CUSTOM is (group, u, seed, jitter). Fire colours fade to smoke by heat; the fireball's light is cloud_core.gdshader's.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

#include "res://render/vfx/shaders/cloud_curves.gdshaderinc"

uniform float body_a = 0.0;            // the body's opacity now (blast_cloud.gd's body_alpha): in, held, out

varying vec4 v_col;
varying float v_sd;

void vertex() {
	vec2 c;
	vec2 sz;
	float heat;
	float shade;
	float z;
	place(INSTANCE_CUSTOM.x, INSTANCE_CUSTOM.y, INSTANCE_CUSTOM.z, INSTANCE_CUSTOM.w, c, sz, heat, shade, z);
	VERTEX = vec3(c + VERTEX.xy * max(sz, vec2(1.0)), z);
	float g = INSTANCE_CUSTOM.x;
	float per = g < 0.5 ? 0.9 : (g < 1.5 ? 1.0 : 0.6);
	float a = body_a * per * (0.55 + 0.45 * INSTANCE_CUSTOM.w);
	v_col = vec4(ramp(heat) * shade, a);
	v_sd = INSTANCE_CUSTOM.z;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float n = 0.55 * vnoise(p * 2.0 + vec2(v_sd * 7.1, v_sd * 3.7)) + 0.45 * vnoise(p * 5.5 + vec2(v_sd * 2.3, v_sd * 9.9));
	float r = length(p) + (n - 0.5) * 0.75;
	float a = 1.0 - smoothstep(0.15, 1.0, r);
	ALBEDO = v_col.rgb;
	ALPHA = v_col.a * a;
}
