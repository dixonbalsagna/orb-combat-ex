// The head of a blast, a charged shot or a beam's front in the beam's own language (render/vfx/energy_head.gd; docs/vfx/energy-language.md): one fighter's energy, drawn the way his beam and his clash are, from the same composition (VfxClashLook.side:
// his lane and the second tint at the same luminance, his front, his texture, his power). One quad along the flight, x along it (-1 the tail), y across; the quad runs HALO_L past the shape's head and HALO_W across it, so the shape sits in its own glow.
// INSTANCE_CUSTOM = (the second tint's hue turn from the first, in turns; the front + 8 x the texture; a seed; the power 0 to 1.4). COLOR = the lane colour, alpha the strength.
// Fronts, as a SHAPE and never a sphere (Legal RL-225: a bolt, slug, wedge, lance or ram; no ball, disc or spinning hoop; nothing rotates): 0 wall, a short thick wedge, flat at the head, its pattern bubble rings that drift back;
// 1 lances, a needle with a point and a crystal facet mosaic; 2 wire, a slim lens with a thin rim line; 3 sputter, a jagged slug with gaps fixed along it; 4 plain, a capsule. Hue moves, brightness does not (within 6%).
// Not an object: the shape is lit from its axis out to a bright rim line in the lane (the pressed face of the clash, not a darker outline), and a soft halo in the lane colour spreads past it, a share of the shape's own brightness and never over it.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform float time = 0.0;
uniform float glow_cap = 0.92;
uniform float halo_k = 0.5;          // the halo's peak alpha as a share of the head's

const float HALO_L = 1.25;           // the quad's length over the shape's (energy_head.gd's HALO_L)
const float HALO_W = 1.7;            // and its width

varying vec4 v_custom;
varying vec4 v_col;

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

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	v_col = COLOR;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;          // x along the flight, y across
	float front_tex = v_custom.y;
	float tex = floor(front_tex / 8.0 + 0.001);
	float front = front_tex - tex * 8.0;
	float seed = v_custom.z;
	float pw = clamp(v_custom.w / 1.4, 0.0, 1.0);
	float u = (p.x + 1.0) * 0.5 * HALO_L;       // 0 the tail, 1 the shape's head, beyond it the halo
	float uc = clamp(u, 0.0, 1.0);
	float xs = uc * 2.0 - 1.0;
	float ay = abs(p.y) * HALO_W;               // across, in the shape's own units
	float w;                             // the half width at this x, as a share of the shape's
	if (front < 0.5) {
		w = mix(0.34, 0.92, pow(uc, 0.7));      // a short thick wedge, widening to a flat head
		w *= 1.0 - smoothstep(0.93, 1.0, uc) * 0.12;
	} else if (front < 1.5) {
		w = 0.30 * smoothstep(-0.02, 0.18, uc) * (1.0 - smoothstep(0.35, 1.0, uc)) + 0.06;   // a needle: a point at the head
	} else if (front < 2.5) {
		w = 0.42 * sin(3.14159265 * uc);       // a slim lens
	} else if (front < 3.5) {
		float jag = vn(vec2(uc * 6.0 + seed, seed * 3.0));
		w = (0.30 + 0.55 * jag) * (1.0 - pow(abs(xs), 3.0));   // a jagged slug
	} else {
		w = 0.55 * (1.0 - pow(abs(xs), 4.0));                  // a capsule
	}
	float aa = max(fwidth(ay) * 1.5, 0.02);
	float inside = (1.0 - smoothstep(w - aa, w + aa, ay)) * (1.0 - step(1.0, u));
	if (front > 2.5 && front < 3.5) {
		// the slug's gaps are fixed along it
		inside *= mix(0.15, 1.0, smoothstep(0.30, 0.42, vn(vec2(uc * 5.0 + seed * 2.0, seed))));
	}
	float rel = ay / max(w, 0.02);        // 0 the axis, 1 the edge
	vec3 a_col = v_col.rgb;
	vec3 hsv = rgb2hsv(a_col);
	vec3 b_col = hsv2rgb(vec3(fract(hsv.x + v_custom.x), hsv.y, hsv.z));
	vec3 col = a_col;
	// the pattern, by hue
	if (tex > 0.5 && tex < 1.5) {
		// boil: bubble rings inside, drifting back along the shot
		vec2 g = vec2(uc * 3.2 * (1.0 + pw) + time * 0.5, rel * 1.6 + seed);
		vec2 f = fract(g) - 0.5;
		vec2 ig = floor(g);
		float ring = 1.0 - smoothstep(0.0, 0.12, abs(length(f) - 0.28 - 0.1 * h21(ig + seed)));
		col = mix(col, b_col, clamp(ring * 0.9, 0.0, 1.0));
	} else if (tex > 1.5) {
		// facets: a flat hue mosaic
		vec2 c = floor(vec2(uc * 5.0, (ay * 0.5 + 0.5) * 3.0 + seed));
		col = mix(a_col, b_col, step(0.5, h21(c + seed)) * 0.85 + 0.05);
	}
	// lit from the axis out: a lighter core (never white), the body, and a bright rim line where the shape meets the air
	vec3 core_c = min(col * 1.16 + 0.04, vec3(glow_cap));
	vec3 body = mix(core_c, col, smoothstep(0.0, 0.75, rel));
	vec3 rim_c = min(mix(col, b_col, 0.5) * 1.14 + 0.04, vec3(glow_cap));
	body = mix(body, rim_c, smoothstep(0.78, 0.96, rel) * 0.9);
	// the halo: the lane colour spreading past the shape, falling off with the distance from it (across, and ahead of the head), a share of the head's brightness
	float dy = max(ay - w, 0.0);
	float dx = max(u - 1.0, 0.0) * 2.2;
	float halo = exp(-(dy * dy * 6.0 + dx * dx * 6.0));
	halo *= (1.0 - smoothstep(0.7, 1.0, abs(p.y))) * (1.0 - smoothstep(0.8, 1.0, p.x));
	vec3 halo_c = min(mix(a_col, b_col, 0.3) * 1.06 + 0.02, vec3(glow_cap));
	float a_halo = halo_k * halo * (1.0 - inside);
	ALBEDO = min(mix(halo_c, body, inside), vec3(glow_cap));
	ALPHA = clamp(v_col.a * max(inside, a_halo), 0.0, 1.0);
}
