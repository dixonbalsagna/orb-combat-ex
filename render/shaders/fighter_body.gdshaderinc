// The body of fighter_body.gdshader and fighter_under.gdshader; their notes are in fighter_body.gdshader.

#include "res://render/shaders/color.gdshaderinc"
#include "res://render/shaders/bend.gdshaderinc"
#include "res://render/shaders/ortho.gdshaderinc"

uniform vec3 wl_mul = vec3(1.0);   // the world's light (SkyDrive.world_at), this layer's multiply in linear light
uniform vec3 wl_add = vec3(0.0);   // ... and its night lift
uniform vec4 albedo : source_color = vec4(1.0);
uniform float shade : hint_range(0.0, 1.0) = 0.35;
// The world's light on the body (AnimBody.set_tint, set each frame from the sky): one multiply colour, plain values like the palette's, white (no change) unless set. The mesh's vertex alpha is its mask: 1 on the
// body, 0 on the lane colour's parts (the forearms and sashes), which are never tinted. The outline (fighter_hull) is another pass and takes none; a hit flash is drawn with the tint white.
uniform vec4 tint = vec4(1.0);
uniform float hit_mix = 0.0;          // a hit that was granted its flash: the body's own colours this far toward white (RenderLook.HIT_TINT), a light tint and not pure white
uniform vec4 damage = vec4(0.0);      // per region (head, core, arms, legs): 0 fresh, 1 bruised, 2 battered, 3 broken, eased
uniform int bone_region[32];          // each bone's region: 0 head, 1 core, 2 arms, 3 legs
// Plain values, like the mesh's vertex colours (the palette's own numbers): no colour-space hint.
uniform vec4 skin = vec4(0.9, 0.75, 0.6, 1.0);      // the palette's skin: what a tear shows, and where bruises go
uniform vec4 gear = vec4(0.8, 0.84, 0.9, 1.0);      // the palette's gear (plates, boots, pack): it scuffs but does not tear
uniform vec4 grime = vec4(0.16, 0.13, 0.12, 1.0);   // RenderLook.DAMAGE_GRIME
uniform vec4 bruise = vec4(0.42, 0.22, 0.38, 1.0);  // RenderLook.DAMAGE_BRUISE
uniform vec3 mark_scuff = vec3(0.14, 0.3, 0.5);     // the outfit's scuffs: the share of clothing and gear marked at each stage
uniform vec3 mark_bruise = vec3(0.12, 0.24, 0.3);   // ... of skin bruised
uniform vec3 mark_tear = vec3(0.0, 0.1, 0.25);      // ... of clothing torn open
uniform float damage_seed = 0.0;      // so two fighters are not marked alike
uniform float damage_detail = 1.0;
#ifdef UNDER
uniform float under_level = 0.0;       // the water's level over him: only what's below it is drawn again
uniform vec4 under_sheet : source_color = vec4(0.42, 0.68, 0.9, 0.55);   // RenderLook.WATER_SURFACE: he reads through a plain sheet at any depth
varying float v_wy;
#endif

varying vec3 v_rest;
varying float v_dmg;
varying float v_head;

void vertex() {
	int r = bone_region[clamp(int(UV2.y + 0.5), 0, 31)];
	v_dmg = r == 0 ? damage.x : (r == 1 ? damage.y : (r == 2 ? damage.z : damage.w));
	v_head = r == 0 ? 1.0 : 0.0;
	v_rest = CUSTOM0.xyz;
	POSITION = ortho > 0.5 ? ortho_clip(MODEL_MATRIX, VIEW_MATRIX, PROJECTION_MATRIX, VERTEX) : bent_clip(MODEL_MATRIX, VIEW_MATRIX, PROJECTION_MATRIX, VERTEX);
#ifdef UNDER
	v_wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
#endif
}

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

// Value noise in 3D, 0 to 1.
float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash31(i), hash31(i + vec3(1.0, 0.0, 0.0)), f.x), mix(hash31(i + vec3(0.0, 1.0, 0.0)), hash31(i + vec3(1.0, 1.0, 0.0)), f.x), f.y);
	float b = mix(mix(hash31(i + vec3(0.0, 0.0, 1.0)), hash31(i + vec3(1.0, 0.0, 1.0)), f.x), mix(hash31(i + vec3(0.0, 1.0, 1.0)), hash31(i + vec3(1.0, 1.0, 1.0)), f.x), f.y);
	return mix(a, b, f.z);
}

// A mark's share of the surface at damage d (0 to 3), through its shares at stages 1, 2 and 3.
float share(vec3 m, float d) {
	return d <= 1.0 ? m.x * d : (d <= 2.0 ? mix(m.x, m.y, d - 1.0) : mix(m.y, m.z, d - 2.0));
}

// The noise value above which that share of the surface lies (measured on the two noises below).
float above(float s) {
	return s < 0.1 ? mix(0.80, 0.685, s / 0.1) : (s < 0.3 ? mix(0.685, 0.575, (s - 0.1) / 0.2) : mix(0.575, 0.455, clamp((s - 0.3) / 0.3, 0.0, 1.0)));
}

void fragment() {
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(n, VERTEX) > 0.0) {
		n = -n;   // toward the camera: the derivatives' sign flips with the render target's y
	}
	vec3 c = COLOR.rgb;
	if (v_dmg > 0.01) {
		bool bare = distance(c, skin.rgb) < 0.06;
		float d = min(v_dmg, 3.0);
		float s_mark = share(bare ? mark_bruise : mark_scuff, d);
		if (damage_detail < 0.5) {
			c = mix(c, bare ? bruise.rgb : grime.rgb, 0.65 * s_mark);
		} else {
			vec3 p = v_rest + damage_seed * vec3(17.3, 5.1, 9.7);
			// Tears: clothing opens to the skin, with a dark frayed edge. Not on the head, not on gear.
			float s_tear = share(mark_tear, d);
			if (s_tear > 0.004 && !bare && v_head < 0.5 && distance(c, gear.rgb) > 0.06) {
				float t = vnoise(p / 4.2 + 77.0) * 0.8 + vnoise(p / 1.6 + 5.0) * 0.2;
				float open = above(s_tear);
				if (t > open + 0.03) {
					c = skin.rgb;
					bare = true;
					s_mark = share(mark_bruise, d);
				} else if (t > open) {
					c = mix(c, grime.rgb, 0.75);
				}
			}
			// Scuffs and bruises.
			if (s_mark > 0.004 && vnoise(p / 5.5) * 0.75 + vnoise(p / 2.2 + 31.7) * 0.25 > above(s_mark)) {
				c = mix(c, bare ? bruise.rgb : grime.rgb, bare ? 0.5 : 0.45);
			}
		}
	}
	vec3 body = mix(flat_shade(albedo.rgb * c * mix(vec3(1.0), tint.rgb, COLOR.a), n, shade) * wl_mul + wl_add, vec3(1.0), hit_mix);   // a hit's white is never dimmed
#ifdef UNDER
	if (v_wy > under_level) {
		discard;
	}
	body = mix(body, under_sheet.rgb * wl_mul + wl_add, under_sheet.a);
	ALPHA = 1.0;
#endif
	ALBEDO = body;
}
