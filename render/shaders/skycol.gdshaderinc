// The sky's colour for a view direction, anchored to the horizon (the far edge of the ground, where the terrain fog
// ends): the horizon colour at the line, then the lower, upper and top colours above it. As the camera climbs
// (space 0 to 1) the band thins to a narrow rim and the sky above turns to space. The sky shader draws it, and the
// terrain and water fog toward it in the same direction, so the far ground dissolves into the sky with no edge.
uniform vec4 sky_top : source_color;
uniform vec4 sky_upper : source_color;
uniform vec4 sky_lower : source_color;
uniform vec4 sky_horizon : source_color;
uniform vec4 space_col : source_color = vec4(0.01, 0.012, 0.035, 1.0);
uniform float space = 0.0;
uniform float horizon = 0.0;       // tan of the horizon's elevation seen from the camera (below eye level: negative)
uniform float sky_tan = 0.268;     // tan(fov / 2): half a screen height in tan units
uniform float sky_lower_at = 0.12;
uniform float sky_upper_at = 0.55;
uniform float sky_top_at = 1.45;
uniform float sky_thin = 2.5;
uniform vec4 haze_at = vec4(1500.0, 2500.0, 6000.0, 40000.0);   // RenderLook.HAZE_AT: distances from the camera
uniform vec3 haze_mix = vec3(0.2, 0.45, 0.8);                    // RenderLook.HAZE_MIX: the haze reached at each
uniform vec2 haze_line = vec2(0.04, 0.5);                        // RenderLook.HAZE_LINE: the glow at the horizon line
uniform float haze_sea = 0.9;                                    // RenderLook.HAZE_SEA: the sea's haze, of the horizon band's value
uniform float haze_value = 0.6;                                  // RenderLook.HAZE_VALUE: the ground's haze, of the horizon band's value
uniform float haze_sat = 0.7;                                    // RenderLook.HAZE_SAT: ... and of its saturation

// Height above the horizon in half-screen heights, thinned with altitude, for the tan of an elevation q.
float sky_height(float q) {
	return (q - horizon) / sky_tan * (1.0 + sky_thin * space);
}

vec3 sky_color(float q) {
	float d = sky_height(q);
	vec3 c;
	if (d <= 0.0) {
		c = sky_horizon.rgb;
	} else if (d < sky_lower_at) {
		c = mix(sky_horizon.rgb, sky_lower.rgb, d / sky_lower_at);
	} else if (d < sky_upper_at) {
		c = mix(sky_lower.rgb, sky_upper.rgb, (d - sky_lower_at) / (sky_upper_at - sky_lower_at));
	} else {
		c = mix(sky_upper.rgb, sky_top.rgb, clamp((d - sky_upper_at) / (sky_top_at - sky_upper_at), 0.0, 1.0));
	}
	return mix(c, space_col.rgb, space * clamp(d * 1.5, 0.0, 1.0));
}

// The tan of the elevation of a direction from the camera, in world axes.
float elevation(vec3 v) {
	return v.y / max(0.0001, length(v.xz));
}

// Aerial haze for the ground and the water seen along `view` (from the camera, world axes), `depth` behind the fighter
// plane: by that depth, not by height on the screen (RenderLook.HAZE_*), so the fight's own ground and all in front of
// it take none, toward the horizon band's
// colour, the distances stretched as the camera climbs (the air thins as the sky's rim does); a thin glow right at the
// horizon line beyond the second distance; and the last eighth before the far edge fading into the sky in its own
// direction, so the ground's end never shows, even where the curvature drops it below the line at the screen's sides.
// Returns (toward the horizon band, into the sky at the far edge).
vec2 haze_parts(vec3 view, float depth, float far) {
	float q = elevation(view);
	float d = max(depth, 0.0) / (1.0 + sky_thin * space);
	float f = haze_mix.x * smoothstep(haze_at.x, haze_at.y, d) + (haze_mix.y - haze_mix.x) * smoothstep(haze_at.y, haze_at.z, d) + (haze_mix.z - haze_mix.y) * smoothstep(haze_at.z, haze_at.w, d);
	float band = haze_line.x / (1.0 + sky_thin * space);
	float fl = haze_line.y * (1.0 - smoothstep(0.0, band, abs(horizon - q) / sky_tan)) * smoothstep(haze_at.y, haze_at.z, d);
	return vec2(max(f, fl), smoothstep(0.88 * far, far, depth));
}

// The ground's colour hazed (haze_parts: x toward the horizon band taken down to haze_value of its value and haze_sat
// of its saturation, the far mountains' ladder; y into the sky at the far edge).
vec3 haze_ground(vec3 c, vec3 view, float depth, float far) {
	vec2 h = haze_parts(view, depth, far);
	vec3 band = sky_horizon.rgb;
	vec3 toward = mix(vec3(dot(band, vec3(0.2126, 0.7152, 0.0722))), band, haze_sat) * haze_value;
	return mix(mix(c, toward, h.x), sky_color(elevation(view)), h.y);
}
