// The blast cloud's fireball (docs/vfx/catastrophe-plan.md section 2.1): a lumpy additive core inside the stem's base and the cap's lower third, and a low glow on the crater floor. It is the
// ONE catastrophe light event: its brightness is `light`, the envelope the flash register granted (rise over at least 0.3 s, fall over at least 1 s, one a 2 s, a calm form), and 0 when it
// refused it. The core is a cluster of noise-broken blobs, never a hemisphere and never a ring (c06); its radius caps at 0.35 of the cap's major radius. Additive, behind the fighters' plane.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

#include "res://render/vfx/shaders/cloud_curves.gdshaderinc"

uniform float light = 0.0;             // the granted envelope times its peak, 0 to 1
uniform float core_radius = 910.0;     // the core's radius at full growth, in units
uniform float core_alpha = 0.55;

varying vec4 v_col;
varying float v_sd;

void vertex() {
	float g = INSTANCE_CUSTOM.x;
	float u = INSTANCE_CUSTOM.y;
	float sd = INSTANCE_CUSTOM.z;
	float jt = INSTANCE_CUSTOM.w;
	float t = max(age, 0.0);
	float H = height_max * scale * (1.0 - exp(-t / height_tau));
	float grow = 1.0 - exp(-t / 1.0);
	float Rc = core_radius * grow;
	vec2 c;
	vec2 sz;
	float heat;
	float z = -10.0;
	if (g < 3.5) {
		// a piece of the fireball: scattered inside a lumpy cluster that lifts with the stem's base
		float ang = 6.2831853 * fract(sd * 3.7 + u);
		float rr = Rc * 0.6 * fract(jt * 5.3 + u * 2.1);
		c = vec2(origin.x + cos(ang) * rr * 1.2, origin.y + min(H * 0.12, 900.0 * scale) + sin(ang) * rr * 0.7 + Rc * 0.25);
		sz = vec2(Rc * (0.55 + 0.5 * jt)) * 2.0;
		heat = exp(-t / heat_tau_core) * (0.75 + 0.25 * jt);
	} else {
		// the crater-floor glow: wide and flat along the ground
		c = vec2(origin.x + (u - 0.5) * Rc * 3.0, origin.y + 30.0 * scale);
		sz = vec2(Rc * (1.2 + 0.8 * jt), Rc * 0.28);
		heat = exp(-t / heat_tau_core) * 0.7;
		z = -9.0;
	}
	VERTEX = vec3(c + VERTEX.xy * max(sz, vec2(1.0)), z);
	float a = light * core_alpha * (g < 3.5 ? 1.0 : 0.6);
	v_col = vec4(ramp(0.7 + 0.3 * heat) * 1.0, a);
	v_sd = sd;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float n = 0.55 * vnoise(p * 2.0 + vec2(v_sd * 5.1, v_sd * 8.7)) + 0.45 * vnoise(p * 4.5 + vec2(v_sd * 1.9, v_sd * 6.3));
	float r = length(p) + (n - 0.5) * 0.8;
	float a = 1.0 - smoothstep(0.1, 1.0, r);
	ALBEDO = v_col.rgb;
	ALPHA = v_col.a * a * a;
}
