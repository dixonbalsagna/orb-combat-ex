// The tremor's dust curtains (docs/vfx/catastrophe-plan.md section 5): one MultiMesh quad per soft sprite of warm grey, its edge broken by two octaves of value noise so no outline reads as a
// disc, and no hard edge anywhere (a soft falloff, never a cel step). Alpha-blended, never additive, drawn behind the fighters' plane. COLOR is the dust's colour with its alpha (the view caps
// it at 0.5); INSTANCE_CUSTOM.x is a seed for the noise. Nothing here changes with time but what the view writes, so the shader has no clock and no rhythm of its own.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

varying vec4 v_custom;

void vertex() {
	v_custom = INSTANCE_CUSTOM;
}

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float sd = v_custom.x;
	float n = 0.6 * vnoise(p * 2.2 + vec2(sd * 7.1, sd * 3.7)) + 0.4 * vnoise(p * 5.0 + vec2(sd * 2.3, sd * 9.9));
	float r = length(p * vec2(1.0, 1.35)) + (n - 0.5) * 0.55;
	float a = 1.0 - smoothstep(0.25, 1.0, r);
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * a;
}
