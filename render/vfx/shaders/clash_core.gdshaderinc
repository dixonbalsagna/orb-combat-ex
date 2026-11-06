// The beam clash's air (render/vfx/clash_view.gd, clash_look.gd; docs/vfx/clash-look.md): where two beams meet, rippling glowing air, drawn on one camera-facing quad. Included by three shaders:
//   clash_glow.gdshader      (CLASH_GLOW, mixed over the scene): the colour: pressure rings, each side's front, rays erupting from the point, bursts on a surge, a knot at the centre. Capped so it is never white.
//   clash_air.gdshader       (CLASH_AIR + CLASH_SCREEN, mixed): the distortion: the screen behind the quad, displaced by the pressure rings and a slow warp. Reads the screen (hint_screen_texture): one full-frame copy.
//   clash_air_lite.gdshader  (CLASH_AIR, mixed): the cheaper fallback with no screen read: dark lens bands just past each ring's crest, which read as the air bending.
// The left half of the disc is one fighter's, the right the other's (the seam leans toward the side that is losing: the leader's energy pushes across the middle) and each side keeps its own palette, front (how its
// pressure moves: a wall, lances, a wire, jets) and texture (boil or facets). Where they meet the pair's mix colour erupts. Everything is a function of the sim's clock (`time`) and slow: a point of the disc sees
// a ring crest at `ring_hz` (1 Hz or under) and the fronts drift at `front_hz`; nothing steps, nothing is random per frame, and the glow's colour is capped (`glow_cap`) so it is never white.
#include "res://render/shaders/ortho.gdshaderinc"

uniform vec4 ca0 : source_color = vec4(0.4, 0.8, 1.0, 1.0);     // side A: its lane tint, and the second tint (the same luminance, the hue turned)
uniform vec4 ca1 : source_color = vec4(0.4, 0.6, 1.0, 1.0);
uniform vec4 cd0 : source_color = vec4(0.8, 0.4, 1.0, 1.0);     // side D
uniform vec4 cd1 : source_color = vec4(1.0, 0.4, 0.8, 1.0);
uniform vec4 acc_a : source_color = vec4(0.7, 0.9, 1.0, 1.0);   // what erupts from each side (an accent: lighter, or the row's own)
uniform vec4 acc_d : source_color = vec4(1.0, 0.7, 0.9, 1.0);
uniform vec4 cmix : source_color = vec4(0.8, 0.7, 1.0, 1.0);    // the pair's mix, where the two meet
uniform vec2 axis = vec2(1.0, 0.0);      // the unit vector on screen from A toward D
uniform float strength = 1.0;           // the clash's own rise and fall, calm scaled in
uniform float time = 0.0;               // the sim's clock in seconds
uniform float lead = 0.0;               // -1 (D ahead) to +1 (A ahead), eased
uniform float lean = 0.5;               // how far the seam moves with the lead
uniform float pwr_a = 0.5;              // each side's power: tier and form
uniform float pwr_d = 0.5;
uniform vec4 look_a = vec4(0.0, 0.0, 1.0, 1.0);   // x front, y texture, z scale, w ring_k
uniform vec4 look_d = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 spike = vec2(1.0, 1.0);    // spike_k of A and D
uniform float ring_n = 4.5;
uniform float ring_n_pp = 2.0;
uniform float ring_hz = 0.9;
uniform float front_hz = 0.7;
uniform float knot = 0.4;               // 0 to 1: the struggle's swell
uniform float core_r = 0.15;
uniform float core_pk = 0.7;
uniform float glow = 0.9;
uniform float glow_cap = 0.66;
uniform float lighten = 0.1;
uniform float spikes = 7.0;
uniform float spikes_pp = 5.0;
uniform float distort = 0.07;           // the displacement, a share of the quad's radius, at power 1
uniform float lens = 0.3;               // the lite form's dark band alpha
uniform vec4 keep_a = vec4(-9.0, 0.0, 0.1, 0.0);   // each fighter's body in the quad's own units: x, y and radius; the air thins toward it
uniform vec4 keep_d = vec4(9.0, 0.0, 0.1, 0.0);
uniform vec4 bst0 = vec4(-1.0, 0.0, 0.0, 0.0);     // a surge's eruption: x its age as a share of its life (outside 0 to 1: none), y amp, z side (0 A, 1 D)
uniform vec4 bst1 = vec4(-1.0, 0.0, 0.0, 0.0);
uniform float seed = 0.0;

const float TWO_PI = 6.2831853;

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

float fbm(vec2 p) {
	return 0.55 * vn(p) + 0.3 * vn(p * 2.1 + 7.0) + 0.15 * vn(p * 4.3 + 3.0);
}

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

float stripe(float x, float w) {
	return smoothstep(w, 0.0, abs(fract(x) - 0.5));
}

void vertex() {
	POSITION = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
}

// How much of the disc is clear of the two fighters' bodies (1 clear, 0 on a body): the air and the glow thin toward them, never over them.
float keep_mask(vec2 p) {
	float ma = smoothstep(keep_a.z * 0.7, keep_a.z * 1.4, length(p - keep_a.xy));
	float md = smoothstep(keep_d.z * 0.7, keep_d.z * 1.4, length(p - keep_d.xy));
	return ma * md;
}

// The pressure rings' phase at p: crests travel outward from the point at `ring_hz`, bent by a slow warp of the air; the leader's side runs tighter.
float ring_phase(vec2 p, float r, float pw, float scl) {
	float warp = (fbm(p * 2.4 * scl + vec2(time * 0.12, -time * 0.09) + seed) - 0.5) * (0.5 + 0.7 * pw);
	return r * (ring_n + ring_n_pp * pw) - time * ring_hz + warp * 1.6;
}

vec3 burst_col(vec4 b, vec2 p, float r) {
	if (b.x < 0.0 || b.x > 1.0 || b.y <= 0.0) {
		return vec3(0.0);
	}
	float rb = 0.08 + b.x * 0.85;
	float band = smoothstep(0.14 + 0.2 * b.x, 0.0, abs(r - rb));
	vec2 dir = p / max(r, 0.001);
	float ray = 0.4 + 1.2 * pow(vn(dir * 3.2 + seed + b.z * 5.0), 2.0);
	float fade = pow(1.0 - b.x, 1.5);
	vec3 bc = mix(acc_a.rgb, acc_d.rgb, b.z);
	return bc * band * ray * fade * b.y;
}

#ifdef CLASH_GLOW
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.y = -p.y;
	float r = length(p);
	if (r >= 1.0) {
		discard;
	}
	float s = dot(p, axis);
	float q = dot(p, vec2(-axis.y, axis.x));
	float edge = 1.0 - smoothstep(0.65, 1.0, r);
	// whose energy is here: A's on its side, D's on the other, the seam leaning toward the one losing ground
	float wob = (fbm(vec2(q * 2.2 + seed, time * 0.3)) - 0.5) * 0.5;
	float sd = smoothstep(-0.3, 0.3, s - lead * lean + wob);
	vec3 c0 = mix(ca0.rgb, cd0.rgb, sd);
	vec3 c1 = mix(ca1.rgb, cd1.rgb, sd);
	vec3 acc = mix(acc_a.rgb, acc_d.rgb, sd);
	vec4 lk = sd < 0.5 ? look_a : look_d;
	float seam = 1.0 - abs(2.0 * sd - 1.0);
	seam *= seam;
	float pw = mix(pwr_a, pwr_d, sd);
	float spk = mix(spike.x, spike.y, sd);
	float dsg = lead >= 0.0 ? 1.0 : -1.0;
	float sl = s * dsg;                       // along the way the energy goes: toward the one losing
	float tt = time * front_hz;
	float ph = ring_phase(p, r, pw, lk.z);
	float ring = pow(0.5 + 0.5 * sin(ph * TWO_PI), 2.5) * (1.0 - r) * (1.0 - r);
	vec3 base = mix(c0, c1, clamp(0.5 + 0.5 * sin(ph * TWO_PI * 0.5 + q * 2.0), 0.0, 1.0));
	// the front: how this side's pressure moves
	float fv = 0.0;
	if (lk.x < 0.5) {
		float x = sl * 2.2 - q * q * 0.9 - tt * 0.5;                    // a wall: broad arcs bowing toward the loser, pushed along
		fv = stripe(x, 0.2) * smoothstep(1.0, 0.2, r);
	} else if (lk.x < 1.5) {
		float lane = q * (7.0 + 5.0 * pw);                              // lances: straight streaks along the beams, in dashes that run toward the loser
		float id = floor(lane);
		float jit = h21(vec2(id, seed));
		float along = sl * 1.6 - tt * (0.8 + jit) + jit * 7.0;
		float dash = smoothstep(0.35, 0.65, vn(vec2(along * 1.3, id * 1.7)));
		fv = stripe(lane, 0.14) * dash * smoothstep(1.0, 0.1, r);
	} else if (lk.x < 2.5) {
		float rr = length(vec2(sl + 1.7, q)) + sin(q * 14.0 + tt * 3.0) * 0.012;   // a wire: taut arcs about a point far behind the winner, quivering
		fv = stripe(rr * 3.0 - tt * 0.4, 0.07) * smoothstep(1.0, 0.2, r) * (0.6 + 0.4 * vn(vec2(q * 4.0, tt)));
	} else if (lk.x < 3.5) {
		vec2 dir = p / max(r, 0.001);                                   // jets: ragged streams out of the point, in and out of being
		float n = vn(dir * 2.0 + vec2(seed, tt * 0.9)) * 0.7 + vn(dir * 4.6 + vec2(4.0, tt * 1.4)) * 0.3;
		float jets = smoothstep(0.5, 0.82, n + (1.0 - r) * 0.2);
		fv = jets * smoothstep(1.0, 0.1, r) * (0.55 + 0.6 * vn(vec2(r * 9.0 - tt * 2.0, dir.x * 3.0 + dir.y * 5.0)));
	} else {
		fv = 0.35 * smoothstep(1.0, 0.0, r);
	}
	// rays erupting out of the point, more of them and brighter with power and the struggle's knot
	vec2 dr = p / max(r, 0.001);
	float spn = (spikes + spikes_pp * pw) * 0.5;
	float rays = pow(smoothstep(0.55, 1.0, vn(dr * spn + seed + time * 0.2)), 1.6) * smoothstep(1.0, 0.12, r) * (0.3 + 0.7 * (1.0 - r));
	vec3 col = base * ring * (0.7 * lk.w) * (0.45 + pw);
	col += c1 * fv * (0.65 + 0.5 * pw);
	col += acc * rays * spk * (0.35 + 0.65 * knot) * (0.5 + 0.7 * pw);
	// the side's texture: boiling rings (bubbles) or crystal facets, in hue and a little brightness
	if (lk.y > 0.5) {
		vec3 wc = worley2(p * 3.2 * lk.z + vec2(seed, time * 0.05));
		if (lk.y < 1.5) {
			float bub = 1.0 - smoothstep(0.0, 0.1, abs(wc.x - 0.3));
			col = mix(col, c1 * (0.3 + length(col)), bub * 0.5 * edge);
			col += c1 * bub * 0.12 * edge;
		} else {
			float line = 1.0 - smoothstep(0.015, 0.075, wc.y - wc.x);
			col = mix(col, mix(c0, c1, wc.z) * (0.35 + length(col)), 0.45 * edge);
			col += acc * line * 0.16 * edge;
		}
	}
	// where the two meet, the pair's mix colour erupts
	col = mix(col, cmix.rgb * (ring * 0.9 + fv * 0.7 + rays * 1.1 + 0.18), seam * 0.65);
	// the knot at the point: a boiling core, never a flat disc and never white (the lane colours, lightened a tenth at most)
	float cr = core_r * (1.0 + core_pk * knot);
	float core = (1.0 - smoothstep(cr * 0.3, cr, r)) * (0.6 + 0.25 * vn(p * 7.0 + vec2(time * 0.4, seed)) + 0.15 * sin(ph * TWO_PI * 2.0));
	col += mix(cmix.rgb, mix(acc_a.rgb, acc_d.rgb, 0.5), 0.3) * (1.0 + lighten) * core * 0.6;
	col += burst_col(bst0, p, r) + burst_col(bst1, p, r);
	// the energy a pixel carries decides its alpha; its colour is the hue of what is there at a brightness capped by `glow_cap` (mixed over the scene, not added to it: added over a bright sky it would go white)
	float mx = max(col.r, max(col.g, col.b));
	float e = clamp(mx / 0.55, 0.0, 1.0);
	vec3 outc = col / max(mx, 0.0001) * mix(0.6 * glow_cap, glow_cap, e);
	outc += (vec3(1.0) - outc) * (0.4 * core * core);                      // the heart of the knot is a paler tint of the same colour, never white
	float m = keep_mask(p);
	ALBEDO = outc;
	ALPHA = clamp(e * edge * strength * glow * m, 0.0, 1.0);
}
#endif

#ifdef CLASH_AIR
#ifdef CLASH_SCREEN
uniform sampler2D scr : hint_screen_texture, filter_linear;
#endif
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.y = -p.y;
	float r = length(p);
	if (r >= 1.0) {
		discard;
	}
	float s = dot(p, axis);
	float q = dot(p, vec2(-axis.y, axis.x));
	float wob = (fbm(vec2(q * 2.2 + seed, time * 0.3)) - 0.5) * 0.5;
	float sd = smoothstep(-0.3, 0.3, s - lead * lean + wob);
	float pw = mix(pwr_a, pwr_d, sd);
	vec4 lk = sd < 0.5 ? look_a : look_d;
	float ph = ring_phase(p, r, pw, lk.z);
	float fall = 1.0 - smoothstep(0.3, 1.0, r);
	float m = keep_mask(p);
#ifdef CLASH_SCREEN
	// the screen behind the quad, pushed along the radius by the rings' wave and warped slowly: the air bending with pressure
	vec2 dir = p / max(r, 0.001);
	vec2 warp = vec2(fbm(p * 3.1 + vec2(time * 0.2, seed)), fbm(p * 3.1 + vec2(17.0 - time * 0.2, seed))) - 0.5;
	vec2 d = dir * sin(ph * TWO_PI) * 0.6 + warp * 0.8;
	vec2 ks = vec2(length(vec2(dFdx(SCREEN_UV.x), dFdy(SCREEN_UV.x))), length(vec2(dFdx(SCREEN_UV.y), dFdy(SCREEN_UV.y)))) / max(vec2(length(vec2(dFdx(p.x), dFdy(p.x))), length(vec2(dFdx(p.y), dFdy(p.y)))), vec2(0.00001));
	vec2 off = d * distort * (0.4 + pw) * fall * m * strength;
	off.y = -off.y;
	vec3 sc = texture(scr, SCREEN_UV + off * ks).rgb;
	ALBEDO = sc;
	ALPHA = smoothstep(0.0, 0.2, fall) * clamp(strength * 4.0, 0.0, 1.0);
#else
	// no screen read: a dark band just past each ring's crest, which the eye takes for the air bending (the glow pass draws the crest)
	float band = pow(0.5 + 0.5 * sin(ph * TWO_PI - 1.3), 4.0);
	ALBEDO = vec3(0.0);
	ALPHA = band * fall * lens * (0.4 + pw) * m * strength;
#endif
}
#endif
