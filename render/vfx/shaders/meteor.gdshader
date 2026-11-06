// The meteor trail (docs/vfx/meteor-trail.md): one ribbon of three nested layers (sheath, body, core) along a fighter's path, mixed over the scene (never added: added over a bright sky it went white).
// Vertex COLOR is the layer's heat colour at the point's age, alpha its strength; UV.x = the arc length along the path (so a pattern is fixed to the path, not to the screen), UV.y = -1..1 across;
// UV2.x = the layer (0 sheath, 1 body, 2 core), UV2.y = the point's age as a share of its life.
// The fighter's look is data: `look` = (front, texture, wavelength, braid). Fronts: 0 wall (broad rolling swell), 1 lances (straight filaments streaming along), 2 wire (a thin rim line near the edge),
// 3 sputter (gaps fixed in the world), 4 plain. Textures: 1 boil (bubble rings travelling down the ribbon), 2 facets (a flat hue mosaic). Hue and shape move; brightness moves by a few percent at most.
// Every travelling feature is a sine of (arc length - time x rate) with the rate `hz` at most 0.9 (0.55 calm): a pixel sees a feature pass at that rate or slower, never faster. `flow` 0 stills them (reduced motion).
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform float time = 0.0;
uniform vec4 look = vec4(0.0, 0.0, 100.0, 0.0);
uniform float hue = 0.08;
uniform float hz = 0.9;
uniform float flow = 1.0;
uniform float glow_cap = 0.92;
uniform vec4 fx = vec4(1.0, 0.0, 0.0, 0.30);  // flight lines: the share of the gaps open (1: all, as the meteor's), a dull core, sparks, and where the gaps' noise threshold starts
uniform vec4 rimc = vec4(0.0);                // flight lines: a thin rim line's colour and strength on the body (the Empress's gold; the Cyborg's hot slag edge)

varying float v_layer;
varying float v_age;

const float TWO_PI = 6.2831853;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
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
	v_layer = UV2.x;
	v_age = UV2.y;
}

void fragment() {
	float s = UV.x;
	float v = UV.y;
	float edge = abs(v);
	float lay = v_layer;
	float softness = lay < 0.5 ? 1.0 : (lay < 1.5 ? 0.5 : 0.3);
	float aa = max(fwidth(edge) * 1.5, 0.02);
	float a = 1.0 - smoothstep(1.0 - max(softness, aa * 2.0), 1.0, edge);
	vec3 col = COLOR.rgb;
	float al = COLOR.a * a;
	float wl = max(look.z, 8.0);
	float ph = s / wl * TWO_PI - time * TWO_PI * hz * flow;
	float amp = lay < 0.5 ? 0.16 : (lay < 1.5 ? 0.07 : 0.04);
	int front = int(look.x + 0.5);
	int tex = int(look.y + 0.5);
	float shift = 0.0;
	// Texture: boil rings travel down the ribbon; facets are a flat hue mosaic.
	if (tex == 1) {
		float ring = 0.5 + 0.5 * sin(ph);
		float cell = vnoise(vec2(s / wl * 1.7 - time * hz * flow * 0.35, v * 2.4));
		al *= 1.0 - amp * ring;
		shift = clamp(cell * 1.4 - 0.35, 0.0, 1.0);
	} else if (tex == 2) {
		vec2 c = floor(vec2(s / (wl * 0.5), v * 3.0 + 3.0));
		shift = step(0.5, hash21(c));
	}
	// Front: how the pressure moves.
	if (front == 0) {
		al *= 1.0 - amp * 0.6 * (0.5 + 0.5 * sin(ph * 0.5 + v * 1.7));
	} else if (front == 1) {
		float fil = smoothstep(0.62, 0.95, vnoise(vec2(s / (wl * 4.0) - time * hz * flow * 0.12, v * 8.0)));
		col = mix(col, min(col * 1.18 + 0.05, vec3(1.0)), fil * (lay > 1.5 ? 0.0 : 0.8));
		al *= 1.0 - amp * 0.4 * (1.0 - fil);
	} else if (front == 2) {
		float rim = smoothstep(0.7, 0.8, edge) * (1.0 - smoothstep(0.9, 0.97, edge));
		shift = max(shift, rim * (rimc.w > 0.0 ? 0.0 : 1.0));
	} else if (front == 3) {
		float g = vnoise(vec2(s / (wl * 2.0), lay * 3.1));
		al *= mix(0.12, 1.0, smoothstep(fx.w * fx.x, (fx.w + 0.12) * fx.x, g));
		// heavy sparks: bright flecks fixed to the path, never in time
		vec2 sc = vec2(s / (wl * 0.5), v * 4.0 + 4.0 + lay * 7.0);
		vec2 sf = (fract(sc) - 0.5) * vec2(0.55, 1.0);       // longer along the path than across: a fleck, not a square
		float spk = step(0.93, hash21(floor(sc))) * (1.0 - smoothstep(0.12, 0.42, length(sf))) * fx.z * (lay < 1.5 ? 1.0 : 0.0);
		col = mix(col, min(col * 1.25 + 0.06, vec3(1.0)), spk);
		al = max(al, COLOR.a * a * spk);
	}
	// A braid (the Protagonist's form steps): two strands crossing along the ribbon, hue and a little shape, at most half a hertz.
	if (look.w > 0.0) {
		float bw = clamp(look.w, 0.0, 1.0);
		float bp = s / (wl * 0.7) * TWO_PI - time * TWO_PI * hz * flow * 0.5;
		float strand = max(smoothstep(0.55, 0.9, sin(bp + v * 2.6)), smoothstep(0.55, 0.9, sin(bp - v * 2.6)));
		shift = max(shift, strand * bw);
		al *= 1.0 - amp * bw * (1.0 - strand);
	}
	if (shift > 0.0) {
		vec3 hsv = rgb2hsv(col);
		hsv.x = fract(hsv.x + hue * shift);
		col = hsv2rgb(hsv);
	}
	if (lay > 1.5) {
		col *= 1.0 - 0.45 * fx.y;        // a dull core
	}
	if (rimc.w > 0.0 && lay > 0.5 && lay < 1.5) {
		float band = smoothstep(0.80, 0.84, edge) * (1.0 - smoothstep(0.92, 0.96, edge));
		col = mix(col, rimc.rgb, band * rimc.w);
		al = max(al, COLOR.a * band * rimc.w);
	}
	ALBEDO = min(col, vec3(glow_cap));
	ALPHA = clamp(al, 0.0, 1.0);
}
