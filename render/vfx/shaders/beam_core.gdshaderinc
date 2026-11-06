// The beam's layer: uniforms, the noise and the fragment (render/vfx/beam_look.gd; docs/vfx/beam-look.md). Included by beam.gdshader (alpha-blended: the body and the core) and beam_glow.gdshader
// (additive: the sheath's soft glow, kept thin in alpha because three additive layers add up to white and this beam has no white core).
// A slow travelling ripple of HUE between two tints of the same luminance (so it flows while its brightness stays steady: Legal fx03, 2 Hz or slower, under a tenth of luminance), turbulence on the
// soft edge only (shape, never the middle), rounded ends and a swelling heel. The beam stays a plain straight line (e04, e07): nothing goes round the axis. UV.y runs along the prism.
#include "res://render/shaders/ortho.gdshaderinc"

uniform vec4 tint_a : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform vec4 tint_b : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform float strength = 1.0;       // the layer's alpha, with the beam's own rise and fall folded in
uniform float soft = 1.6;           // the edge's falloff, as the glow's
uniform float time = 0.0;           // the sim's clock in seconds (frozen with the sim)
uniform float len = 600.0;          // the beam's length in world units
uniform float flow = 90.0;          // units a second the turbulence slides toward the head (kept slow: a feature is about 80 units, so a point sees about 1 Hz)
uniform float wavelength = 120.0;   // units between two ripples
uniform float hz = 1.0;             // how often a point of the beam passes through its two tints (2 or slower: Legal fx03); the ripple travels at hz x wavelength
uniform float turb = 0.2;           // edge turbulence, 0 to 1
uniform float lum_amp = 0.06;       // the most the alpha moves with the shimmer
uniform float cap = 40.0;           // the rounded ends, in units
uniform float heel = 0.0;           // how much the firer's end swells (0 for a beam already detached)
uniform float seed = 0.0;
uniform float wob = 0.0;            // how much the width swells and thins along the beam (a share of the radius): the silhouette flows, the axis stays a straight line
uniform float fil = 0.5;            // the filaments: long thin streaks along the beam, in hue and saturation, within `lum_amp` in brightness
uniform float head_at_zero = 1.0;   // 1: UV.y is 0 at the head, as the cylinder is built
// The beam struggle's waves (render/vfx/beam_struggle.gd): up to two swells and the meeting point's knot, each (x its centre from the tail in world units, y its half length, z the width it adds as a
// share of the radius (negative pinches), w the alpha it adds as a share). All zero outside a struggle: a plain beam is as it was.
uniform vec4 wv0 = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 wv1 = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 wv2 = vec4(0.0, 1.0, 0.0, 0.0);
// The loser's buckling (render/vfx/beam_struggle.gd, Orb 2026-10-22: the losing beam bulges and quivers like it is buckling under pressure, instead of thinning). All GEOMETRY, no brightness:
// buck = (how much ground he has lost 0 to 1, the bow in world units, the quiver in world units, the bulge as a share of the radius), buck2 = (the bow's Hz, the quiver's Hz, the quiver's wavelength in
// world units, the side the bow leans: +1 up, -1 down). The beam stays anchored at the hand and at the meeting point; between them it bows, its width swells where the push lands, and two slow travelling waves
// shake its axis. A point of the beam moves at buck2.x or buck2.y Hz at most (data bounds: 2 Hz), so nothing flickers.
uniform vec4 buck = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 buck2 = vec4(0.7, 1.6, 160.0, 1.0);

float wbump(float s, vec4 w) {
	float u = (s - w.x) / max(w.y, 1.0);
	return exp(-2.0 * u * u);
}

uniform float pat = 0.0;            // the fighter's own beam pattern: 0 plain, 1 boil (rounded scallops along the edge, bubble rings inside), 2 facets (zigzag edge, crystal seams inside)
uniform float pat_k = 0.0;          // the pattern's brightness inside the beam, a share of the alpha (kept at 3% or under: Legal fx03's step under a tenth)
uniform float pat_a = 0.0;          // how deep the edge scallops or zigzags cut in, a share of the radius (shape, never a flicker)
uniform float pat_scale = 90.0;     // units between two scallops or cells
// The press (docs/vfx/clash-look.md, Orb 2026-11-01: the two beams "colliding and pressed against each other at the centre point ... flare out or erupt in eddies"). A clash beam's head, where it meets the other, flares and bells out into a
// flat sheet, and eddies shed off its rim and roll back along it. press = (the flare: the head's extra radius as a share, the eddies' depth as a share of the radius, their speed back along the beam in units a second, the sheet: how
// flat and wide the front lies, 0 to 1), press2 = (a seed, the eddies' wavelength in units, how far back from the head the press reaches in units, the eddies' hue share). Geometry and hue only: no brightness moves but `lum_amp`'s,
// and a point of the beam sees an eddy go by at press.z / press2.y Hz, held under 0.9 (data bound).
uniform vec4 press = vec4(0.0, 0.0, 110.0, 0.0);
uniform vec4 press2 = vec4(0.0, 170.0, 300.0, 0.5);

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

// A 2D cellular distance: x the nearest feature point, y the second nearest, z a hash of the nearest cell.
vec3 worley2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	float id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(h21(i + g + seed), h21(i + g + seed + 17.0));
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = h21(i + g + seed * 1.3);
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec3(sqrt(d1), sqrt(d2), id);
}

void vertex() {
	vec3 v = VERTEX;
	float s0 = (head_at_zero > 0.5 ? 1.0 - UV.y : UV.y) * len;
	float wsum = wv0.z * wbump(s0, wv0) + wv1.z * wbump(s0, wv1) + wv2.z * wbump(s0, wv2);
	float bu = clamp(s0 / max(len, 1.0), 0.0, 1.0);
	if (buck.x > 0.0) {
		float gb = (bu - 0.62) / 0.3;
		wsum += buck.w * buck.x * exp(-gb * gb);
	}
	if (press.x + press.y + press.w > 0.0) {
		// the prism has 24 rings along it, far too few where the beams meet: bunch them toward the head (the cylinder's top, y = +0.5) so the flare and the eddies are drawn with more than a handful of them
		float t0 = v.y + 0.5;
		float t2 = 1.0 - pow(1.0 - clamp(t0, 0.0, 1.0), 2.2);
		v.y = t2 - 0.5;
		float hd = max((1.0 - t2) * len, 0.0);                              // the distance back from the head, where the beams meet (by where this ring now sits)
		float tp = 1.0 - smoothstep(0.0, max(press2.z, 1.0), hd);           // 1 at the head, 0 at the press's reach
		float ew = max(press2.y, 20.0);
		float arg = (hd - press.z * time) / ew;                              // an eddy sits at a fixed arg, so it rolls away from the head at press.z units a second
		float lob = (vn(vec2(arg, press2.x)) - 0.5) + 0.5 * (vn(vec2(arg * 1.9 + 3.1, press2.x + 5.0)) - 0.5);
		wsum += press.x * pow(tp, 2.2) + press.w * smoothstep(0.86, 1.0, bu) * 0.9 + press.y * tp * lob * 2.0;
	}
	v.xz *= max(0.2, 1.0 + wsum);
	if (buck.x > 0.0) {
		float env = sin(3.14159265 * bu);
		float bow = buck.y * (0.72 + 0.28 * sin(6.2831853 * buck2.x * time + 1.3));
		float lam = max(buck2.z, 1.0);
		float q = buck.z * 0.625 * (sin(6.2831853 * (s0 / lam - buck2.y * time)) + 0.6 * sin(6.2831853 * (s0 / (0.57 * lam) + 0.7 * buck2.y * time) + 2.1));
		vec3 up_m = inverse(mat3(MODEL_MATRIX)) * vec3(0.0, 1.0, 0.0);
		v += up_m * (buck2.w * buck.x * env * (bow + q));
	}
	if (wob > 0.0) {
		float sw = (vn(vec2(s0 * 0.011 - time * flow * 0.012, seed + 3.0)) - 0.5) * 2.0;
		v.xz *= 1.0 + wob * sw;
	}
	if (ortho > 0.5) {
		POSITION = ortho_clip(MODEL_MATRIX, VIEW_MATRIX, PROJECTION_MATRIX, v);
	} else {
		POSITION = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(v, 1.0));
	}
}

void fragment() {
	float facing = abs(dot(normalize(NORMAL), ortho > 0.5 ? vec3(0.0, 0.0, 1.0) : normalize(VIEW)));
	float from_tail = (head_at_zero > 0.5 ? 1.0 - UV.y : UV.y) * len;
	float lat = (UV.x < 0.5 ? UV.x : 1.0 - UV.x) * 2.0;           // across the prism, mirrored so there is no seam
	float travel = from_tail - time * flow;
	float rip = sin((from_tail - time * hz * wavelength) * 6.2831853 / max(wavelength, 1.0) + seed);
	float n1 = vn(vec2(travel * 0.012, lat * 1.7 + seed));
	float f1 = vn(vec2(travel * 0.0035 + 11.0, lat * 6.0 + seed * 2.3));    // long thin streaks along the beam
	float m = clamp(0.5 + 0.38 * rip + 0.5 * (n1 - 0.5) + fil * (f1 - 0.5), 0.0, 1.0);
	vec3 col = mix(tint_a.rgb, tint_b.rgb, m);
	// the edge: shape turbulence, strongest where the edge is
	float nn = vn(vec2(travel * 0.02 + 7.0, lat * 2.3 + seed * 1.7));
	float edge = pow(facing, soft) * mix(1.0, 0.35 + 1.3 * nn, turb * (1.0 - facing));
	float shim = 1.0 + lum_amp * (0.6 * rip + (n1 - 0.5) + 0.8 * (f1 - 0.5));
	float cap_e = min(cap, len * 0.14);     // the rounded ends never take more than a seventh of the beam each: a short beam (a point-blank one) stays solid in the middle, not a soft smear
	// the fighter's own pattern: a silhouette cut into the edge (the boil's rounded scallops, the facets' straight zigzag) and a quiet texture inside (bubble rings, crystal seams); both travel slowly
	// toward the head at a quarter of the flow, a point seeing about one a second or slower. The axis stays a straight line; nothing goes round it.
	float pat_edge = 1.0;
	float pat_tex = 1.0;
	float pat_ring = 0.0;
	float pat_cell = -1.0;
	if (pat > 0.5) {
		float rad = sqrt(max(1.0 - facing * facing, 0.0));
		float ph = fract((from_tail - time * flow * 0.25) / max(pat_scale, 1.0) + seed * 0.17);
		float shape = pat < 1.5 ? sqrt(max(1.0 - pow(2.0 * ph - 1.0, 2.0), 0.0)) : 1.0 - abs(2.0 * ph - 1.0);
		float wmax = 1.0 - pat_a * (1.0 - shape);
		pat_edge = 1.0 - smoothstep(wmax - (pat < 1.5 ? 0.10 : 0.03), wmax, rad);
		vec3 wc = worley2(vec2((from_tail - time * flow * 0.25) / max(pat_scale, 1.0) * 1.3, rad * 1.6 + seed));
		float feat = pat < 1.5 ? (1.0 - smoothstep(0.0, 0.1, abs(wc.x - 0.3))) - 0.25 : -(1.0 - smoothstep(0.015, 0.075, wc.y - wc.x)) * 1.3 + 0.15;
		pat_tex = 1.0 + pat_k * feat;
		pat_ring = pat < 1.5 ? (1.0 - smoothstep(0.0, 0.1, abs(wc.x - 0.3))) : 0.0;
		pat_cell = pat < 1.5 ? -1.0 : wc.z;
	}
	// a pressed head is cut flat where it meets the other beam, not rounded off (press.w)
	float head_cap = mix(smoothstep(0.0, cap_e, len - from_tail), 1.0, clamp(press.w * 1.6, 0.0, 1.0));
	float ends = smoothstep(0.0, cap_e, from_tail) * head_cap;
	float swell = 1.0 + heel * exp(-from_tail / 70.0);
	float wl = 1.0 + wv0.w * wbump(from_tail, wv0) + wv1.w * wbump(from_tail, wv1);
	// the pattern is told apart by HUE, not brightness: the two tints have the same luminance, so a ring of the boil takes the second tint and a facet of the crystal takes its own flat mix of the two,
	// a mosaic of two close hues with no step in luminance at all (Legal fx03); the only brightness the pattern moves is `pat_k`, 6% at most
	if (pat > 0.5) {
		col = pat < 1.5 ? mix(col, tint_b.rgb, clamp(pat_ring * 0.9, 0.0, 1.0)) : mix(tint_a.rgb, tint_b.rgb, clamp(pat_cell * 0.9 + 0.05, 0.0, 1.0));
	}
	if (press.y > 0.0) {
		// the eddies take the second tint where they swell (hue, at the tints' same luminance), strongest near the head
		float hd2 = max(len - from_tail, 0.0);
		float tp2 = 1.0 - smoothstep(0.0, max(press2.z, 1.0), hd2);
		float arg2 = (hd2 - press.z * time) / max(press2.y, 20.0);
		float lob2 = vn(vec2(arg2, press2.x)) + 0.5 * vn(vec2(arg2 * 1.9 + 3.1, press2.x + 5.0));
		col = mix(col, tint_b.rgb, clamp(press2.w * tp2 * smoothstep(0.55, 1.05, lob2), 0.0, 1.0));
	}
	if (press.w > 0.0) {
		// the pressed face: a thin bright line along the head where the two beams meet (the lane colour lightened, held under 0.92: never white)
		float line = smoothstep(0.955, 1.0, 1.0 - max(len - from_tail, 0.0) / max(len, 1.0)) * press.w;
		col = mix(col, min(col * 1.3 + 0.07, vec3(0.92)), clamp(line, 0.0, 1.0));
	}
	ALBEDO = col;
	ALPHA = clamp(tint_a.a * strength * edge * shim * ends * swell * wl * pat_edge * pat_tex, 0.0, 1.0);
}
