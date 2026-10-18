// The blast cloud's curves (docs/vfx/catastrophe-plan.md section 2; render/vfx/blast_cloud.gd mirrors them on the CPU): a sprite's place, size, heat and shade as a closed-form function of the
// cloud's age and the sprite's four constants, so the cloud has no state on either side and the CPU writes only the uniforms below. INSTANCE_CUSTOM = (group, u, seed, jitter): group 0 stem, 1 cap
// (a rolling torus seen from the side), 2 ground dust wall, 3 fireball core piece, 4 crater-floor glow; u runs 0 to 1 along the group.

uniform float age = 0.0;               // seconds since landing, from the sim's tick (never wall time); negative before it lands
uniform vec2 origin = vec2(0.0);       // the blast's x (view-relative) and the ground's y there at landing
uniform float scale = 1.0;             // the blast's size over 3,000
uniform float size_k = 1.0;            // the impostor's sprite scale (the far ladder step draws fewer, larger sprites)
uniform float height_max = 14000.0;
uniform float height_tau = 6.5;
uniform float cap_major = 2600.0;
uniform float cap_major_tau = 8.0;
uniform float cap_minor = 1500.0;
uniform float cap_minor_rise = 5.0;
uniform float cap_omega = -0.35;
uniform float stem_w_top = 260.0;
uniform float stem_w_base = 760.0;
uniform float skirt_reach = 4500.0;
uniform float skirt_tau = 3.2;
uniform float skirt_h_lo = 300.0;
uniform float skirt_h_hi = 600.0;
uniform float heat_tau_core = 4.0;
uniform float heat_tau_stem = 2.2;

// c: the sprite's centre, sz: its size in units, heat: 0 to 1, shade: a brightness factor for the roll's near and far sides, z: its depth (all behind the fighters' plane).
void place(float g, float u, float sd, float jt, out vec2 c, out vec2 sz, out float heat, out float shade, out float z) {
	float t = max(age, 0.0);
	float H = height_max * scale * (1.0 - exp(-t / height_tau));
	heat = 0.0;
	shade = 1.0;
	z = -12.0;
	if (g < 0.5) {
		float h = u * 0.8 * H;
		float wv = mix(stem_w_top, stem_w_base, pow(1.0 - u, 2.0)) * scale * clamp(0.35 + t / 2.0, 0.0, 1.0);
		float sway = 0.06 * wv * sin(h * 0.0007 + sd * 6.2831853 + t * 0.4);
		c = vec2(origin.x + sway, origin.y + h);
		sz = vec2(wv * 2.4, wv * 2.0) * (0.85 + 0.3 * jt) * size_k;
		heat = exp(-t / heat_tau_stem) * (1.0 - 0.7 * u);
	} else if (g < 1.5) {
		float R = cap_major * scale * (1.0 - exp(-t / cap_major_tau));
		float r = cap_minor * scale * min(1.0, t / cap_minor_rise);
		float phi = 6.2831853 * u + cap_omega * t;
		float mu = 6.2831853 * fract(7.0 * u + sd) - 0.5 * cap_omega * t;
		float ring = R + r * cos(mu);
		c = vec2(origin.x + ring * cos(phi), origin.y + H * 0.9 + r * sin(mu) * 0.8);
		float rad = r * (0.85 + 0.3 * jt);
		sz = vec2(rad * 2.0, rad * 1.7) * size_k;
		shade = 0.85 + 0.15 * sin(phi);
		heat = exp(-t / heat_tau_core) * (0.3 + 0.7 * (0.5 - 0.5 * sin(mu)));
	} else {
		float s = skirt_reach * scale * (1.0 - exp(-t / skirt_tau));
		float hh = mix(skirt_h_lo, skirt_h_hi, jt) * scale * min(1.0, t / 1.5);
		c = vec2(origin.x + (2.0 * u - 1.0) * s, origin.y + hh * 0.5);
		sz = vec2((s * 0.14 + 220.0 * scale) * (0.8 + 0.4 * sd), hh * 1.2 + 40.0) * size_k;
		z = -8.0;
	}
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

// Fire into smoke by heat (blast_cloud.gd's ramp): hot, amber, ember brown, smoke. `lit` 0 holds it under the white-amber end.
uniform vec4 colour_hot : source_color = vec4(1.0, 0.94, 0.78, 1.0);
uniform vec4 colour_amber : source_color = vec4(0.94, 0.66, 0.31, 1.0);
uniform vec4 colour_ember : source_color = vec4(0.60, 0.42, 0.24, 1.0);
uniform vec4 colour_smoke : source_color = vec4(0.37, 0.35, 0.33, 1.0);
uniform float lit = 1.0;

vec3 ramp(float h) {
	float hh = clamp(h, 0.0, 1.0);
	if (lit < 0.5) {
		hh = min(hh, 0.7);
	}
	if (hh >= 0.7) {
		return mix(colour_amber.rgb, colour_hot.rgb, (hh - 0.7) / 0.3);
	}
	if (hh >= 0.4) {
		return mix(colour_ember.rgb, colour_amber.rgb, (hh - 0.4) / 0.3);
	}
	return mix(colour_smoke.rgb, colour_ember.rgb, hh / 0.4);
}
