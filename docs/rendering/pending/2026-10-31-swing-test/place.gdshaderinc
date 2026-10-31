// SCRATCH: one world placement for everything in the swing test (rendering.md section 4): a planet direction to the view, by an azimuthal
// equidistant projection about the pivot. Turning about the pivot is exactly rigid on it.
uniform vec3 pv = vec3(1.0, 0.0, 0.0);    // the pivot, a unit vector
uniform vec3 hd = vec3(0.0, 1.0, 0.0);    // the line's heading there
uniform vec3 sd = vec3(0.0, 0.0, 1.0);    // toward the camera there
uniform float planet_r = 24446.2;
uniform vec3 cam = vec3(0.0, 300.0, 3000.0);
uniform float plane_low = 0.0;            // the plane's lowest ground in view
uniform sampler2D plane_tex : filter_nearest, repeat_disable;   // the line's own ground, 64 points
uniform float plane_span = 3000.0;
uniform float bend = 0.0;
uniform float near_line = -80.0;          // where a tower leaves, in view depth
uniform int near_mode = 0;                // 0 the rule, 1 sink, 2 hard clip, 3 rule and sink, 4 sink and clip

vec2 ae(vec3 d) {
	float x = dot(d, hd);
	float z = dot(d, sd);
	float s = sqrt(x * x + z * z);
	float k = s > 1.0e-5 ? atan(s, dot(d, pv)) / s : 1.0;
	return vec2(x, z) * k * planet_r;
}

// The foreground rule: nothing in front of the plane above the sight line to the plane's own lowest ground (or a head over it).
float sight_cap(float x, float z, float over) {
	float t = min(z / cam.z, 0.95);
	float u = clamp((x / (1.0 - t) + plane_span) / (2.0 * plane_span), 0.0, 1.0) * 63.0;
	int ua = int(u);
	float pl = mix(texelFetch(plane_tex, ivec2(ua, 0), 0).r, texelFetch(plane_tex, ivec2(min(ua + 1, 63), 0), 0).r, u - float(ua));
	return mix(pl + over, cam.y, t) - 0.03 * z;
}

// The globe: radius from the pivot is the arc, height is along the normal, so walls lean as on a planet.
vec3 globe(float x, float y, float z) {
	float r = sqrt(x * x + z * z);
	float ang = r / planet_r;
	if (ang > 1.5) {
		return vec3(x, y - 1.0e6, z);
	}
	float k = r > 0.01 ? (planet_r + y) * sin(ang) / r : 1.0;
	return vec3(x * k, (planet_r + y) * cos(ang) - planet_r, z * k);
}

// An anchored thing's place: its anchor and the way its local x runs, in the view.
void anchored(vec3 a, vec3 e, out vec2 c, out vec2 ex, out vec2 ez) {
	c = ae(a);
	vec2 c2 = ae(normalize(a + e * (40.0 / planet_r)));
	ex = normalize(c2 - c);
	ez = vec2(-ex.y, ex.x);
}
