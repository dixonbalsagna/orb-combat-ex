// The body of fighter_hull.gdshader and fighter_hull_under.gdshader; their notes are in fighter_hull.gdshader.

#include "res://render/shaders/bend.gdshaderinc"
#include "res://render/shaders/ortho.gdshaderinc"

uniform float outline_px = 1.5;   // RenderLook.OUTLINE_PX
uniform float min_px = 0.75;      // RenderLook.OUTLINE_MIN_PX
uniform vec4 col : source_color = vec4(0.04, 0.05, 0.08, 1.0);
#ifdef UNDER
uniform float under_level = 0.0;       // fighter_body.gdshaderinc's
uniform vec4 under_sheet : source_color = vec4(0.42, 0.68, 0.9, 0.55);
varying float v_wy;
#endif
uniform bool face_normals = false;   // an unbaked mesh: push along its faceted NORMAL (the outline check's failing control)

void vertex() {
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	float w = ortho > 0.5 ? (PROJECTION_MATRIX * (VIEW_MATRIX * vec4(anchor, 1.0))).w : (PROJECTION_MATRIX * (VIEW_MATRIX * wp)).w;
	// abs: drawing into a SubViewport (the panes), the Compatibility renderer flips the projection's y.
	float world_per_px = 2.0 * w / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y);
	float s = max(length(MODEL_MATRIX[0].xyz), 1e-6);
	// The fighter's size at his depth against his size on the fighter plane: w there over w here.
	float w0 = (PROJECTION_MATRIX * (VIEW_MATRIX * vec4(anchor.xy, 0.0, 1.0))).w;
	float px = ortho > 0.5 ? max(outline_px * clamp(w0 / max(w, 1e-6), 0.0, 2.0), min(outline_px, min_px)) : outline_px;
	vec3 d = face_normals ? NORMAL : NORMAL * UV2.x;
	vec3 v = VERTEX + d * (px * world_per_px / s);
	POSITION = ortho > 0.5 ? ortho_clip(MODEL_MATRIX, VIEW_MATRIX, PROJECTION_MATRIX, v) : bent_clip(MODEL_MATRIX, VIEW_MATRIX, PROJECTION_MATRIX, v);
#ifdef UNDER
	v_wy = wp.y;
#endif
}

void fragment() {
#ifdef UNDER
	if (v_wy > under_level) {
		discard;
	}
	ALBEDO = mix(col.rgb, under_sheet.rgb, under_sheet.a);
	ALPHA = 1.0;
#else
	ALBEDO = col.rgb;
#endif
}
