// The scar a beam leaves in the air (render/vfx/beam_scar.gd, scar_view.gd; docs/vfx/beam-scar.md): one MultiMesh quad along the beam's line. Crisp by construction: the shape is an analytic
// strip (a hard edge antialiased over one pixel), never a soft falloff. Where the beam's tail has passed the air is cut: a dark core with a bright lane-coloured rim, the rim hot at first and
// cooling to the lane colour's own dark shade. It heals by geometry, not by fading: its strip thins, and its cells drop out one by one with hard edges. Nothing here flickers or pulses:
// every change is a slow one-way change with the scar's age. INSTANCE_CUSTOM: x = the age (s) of the strip's firer end, y = how much younger a point is per world unit along the strip,
// z = a seed, w = the strip's length. COLOR: rgb the lane colour, a = the rim's share of the strip's half width (a pixel-wide rim at this pane's zoom).
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform float heal_s = 3.6;       // seconds a point takes to heal
uniform float cell = 110.0;       // the pieces it drops out in, in world units
uniform float cool_s = 1.2;       // seconds the rim takes to cool
uniform float grow_s = 0.14;      // seconds a fresh point takes to reach its full width: the scar's newest end is a pointed wedge
uniform float alpha_core = 0.62;
uniform float alpha_rim = 0.92;
uniform float dark = 0.1;         // the core's brightness against the lane colour

varying vec4 v_c;

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	v_c = INSTANCE_CUSTOM;
}

void fragment() {
	float L = v_c.w;
	float s = UV.x * L;
	float age = v_c.x - s * v_c.y;
	if (age < 0.0) {
		discard;
	}
	float h = age / heal_s;
	if (h >= 1.0) {
		discard;
	}
	float y = UV.y * 2.0 - 1.0;
	float d = abs(y);
	// the pieces drop out one by one, on a slant so the cuts are not square: hard edges, never a fade
	float cid = floor((s + y * 28.0) / cell);
	float thr = 0.35 + 0.6 * h21(vec2(cid, v_c.z * 17.0));
	if (h > thr) {
		discard;
	}
	float jag = (vn(vec2(s * 0.04, v_c.z * 13.0)) - 0.5) * 0.3 + (vn(vec2(s * 0.15, v_c.z * 5.0)) - 0.5) * 0.1;
	float grow = smoothstep(0.0, grow_s, age);
	float thin = 1.0 - 0.55 * smoothstep(0.15, 1.0, h);
	float hw = 0.86 * grow * thin * (1.0 + jag);
	float aa = max(fwidth(y) * 1.2, 0.002);
	float inside = 1.0 - smoothstep(hw - aa, hw + aa, d);
	if (inside < 0.02) {
		discard;
	}
	float rim_w = max(COLOR.a, aa * 2.5);
	float rim = smoothstep(hw - rim_w - aa, hw - rim_w + aa, d);
	float heat = 1.0 - smoothstep(0.0, cool_s, age);
	vec3 lane = COLOR.rgb;
	vec3 hot = lane + (vec3(1.0) - lane) * 0.3;
	vec3 core_col = lane * dark;
	vec3 rim_col = mix(lane * 0.5, hot, heat);
	ALBEDO = mix(core_col, rim_col, rim);
	ALPHA = inside * mix(alpha_core, alpha_rim, rim);
}
