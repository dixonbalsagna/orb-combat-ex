// SCRATCH: the swing test's sky: the game's four colours by height, and soft bands of cloud on the planet's frame, so the sky turns with the world.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;
uniform float sky_turn = 0.0;
uniform float horizon = 0.46;
uniform vec3 c0 : source_color = vec3(0.067, 0.102, 0.243);
uniform vec3 c1 : source_color = vec3(0.294, 0.267, 0.514);
uniform vec3 c2 : source_color = vec3(0.851, 0.467, 0.420);
uniform vec3 c3 : source_color = vec3(0.957, 0.722, 0.478);
uniform bool magenta = false;
varying vec2 v_ndc;

void vertex() {
	v_ndc = VERTEX.xy;
}

float noise(float x, float y, float per) {
	float i = floor(x);
	float j = floor(y);
	float fx = fract(x);
	float fy = fract(y);
	fx = fx * fx * (3.0 - 2.0 * fx);
	fy = fy * fy * (3.0 - 2.0 * fy);
	float a = fract(sin(i * 12.9898 + j * 78.233) * 43758.5453);
	float i2 = mod(i + 1.0, per);
	float b = fract(sin(i2 * 12.9898 + j * 78.233) * 43758.5453);
	float c = fract(sin(i * 12.9898 + (j + 1.0) * 78.233) * 43758.5453);
	float d = fract(sin(i2 * 12.9898 + (j + 1.0) * 78.233) * 43758.5453);
	return mix(mix(a, b, fx), mix(c, d, fx), fy);
}

void fragment() {
	if (magenta) {
		ALBEDO = vec3(1.0, 0.0, 1.0);
	} else {
		float h = clamp((v_ndc.y - (horizon * 2.0 - 1.0)) / (2.0 - horizon * 2.0), 0.0, 1.0);
		vec3 c = h < 0.15 ? mix(c3, c2, h / 0.15) : (h < 0.55 ? mix(c2, c1, (h - 0.15) / 0.4) : mix(c1, c0, (h - 0.55) / 0.45));
		// Azimuth: the view's half width is 25 degrees at 16:9, so the sky moves with sky_turn in the same degrees as far land.
		float az = atan(v_ndc.x * 0.67) + sky_turn;
		float m = 0.0;
		float w = mod(az, 6.2831853) / 6.2831853 * 60.0;
		for (int k = 0; k < 3; k++) {
			float fq = float(1 << k);
			float v = noise(mod(w * fq, 60.0 * fq), h * 9.0 * fq, 60.0 * fq);
			m += v / fq;
		}
		ALBEDO = mix(c, mix(c, c3, 0.5), smoothstep(1.0, 1.6, m) * (1.0 - h) * 0.7);
	}
}
