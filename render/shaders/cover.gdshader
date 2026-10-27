// The biomes' cover (biome rendering window 2; render/core/cover_view.gd, render/core/cover_meshes.gd): Art's flat
// silhouettes standing in the strip's plane on the band's ground. Each instance's foot reads the ground under it as the
// terrain draws it (ground4: craters, grooves and all), so a shape rises and falls with the ground, and a shape inside a
// crater is gone (Art: the cover inside a crater is removed). What floats (a whitecap, a floe) sits at the water's level.
// A vertex's colour is its palette slot (COLOR.r) and tone step (COLOR.g) in the palette of the biome it grows in
// (INSTANCE_CUSTOM.r: RenderBiomeLook's column; the cover's rows from COVER_ROW), lit, mid and shade as Art drew it;
// hazed into the sky as the ground is. A fellable tree (render/core/tree_view.gd) is drawn by this shader too: while it
// burns (INSTANCE_CUSTOM.b, its burn in hard steps) its crown is char from the top down to that share of its height.
shader_type spatial;
render_mode unshaded, cull_disabled;

#include "res://render/shaders/color.gdshaderinc"
#include "res://render/shaders/bend.gdshaderinc"
#include "res://render/shaders/ground.gdshaderinc"
#include "res://render/shaders/skycol.gdshaderinc"

uniform vec3 wl_mul = vec3(1.0);   // the world's light, as the trees take it
uniform vec3 wl_add = vec3(0.0);
uniform float fog_far = 12000.0;
uniform float cover_cam_x = 0.0;   // this pane's camera x: a copy stands at k x the arena's length less it (planet_view.gd)
uniform int cover_row = 12;        // RenderBiomeLook.COVER_ROW
uniform vec4 tone_light : source_color = vec4(1.0, 0.965, 0.878, 1.0);   // RenderCoverMeshes.TONE_LIGHT and TONE_DARK (Art's lite() and dark())
uniform vec4 tone_dark : source_color = vec4(0.047, 0.039, 0.078, 1.0);
uniform vec4 char_col : source_color = vec4(0.173, 0.149, 0.133, 1.0);   // RenderCoverMeshes.CHAR_COLOUR: a burning crown

varying vec3 v_col;
varying vec3 v_view;
varying float v_wz;
varying float v_up;     // the shape's height share here (Art's frame: 0 at the foot, 1 at the top)
varying float v_burn;   // a burning tree's burn step; 0 for the cover

void vertex() {
	v_up = VERTEX.y;
	v_burn = INSTANCE_CUSTOM.b;
	// The foot's place on the band (any copy reads the same: the band repeats with the arena's length).
	float x = MODEL_MATRIX[3].x + cover_cam_x;
	float z = MODEL_MATRIX[3].z;
	float xm = x - world_w * floor(x / world_w);
	int i = int(xm / col_w) % nc;
	vec4 g = ground4(i, xm, z, false, 0.0);
	float foot = INSTANCE_CUSTOM.g > 0.5 ? max(g.x, 0.0) : g.x;
	VERTEX.y += foot / length(MODEL_MATRIX[1].xyz);
	VERTEX = g.w < -dent_min ? vec3(0.0) : VERTEX;   // inside a crater: gone (all its corners meet)
	int b = int(INSTANCE_CUSTOM.r * 32.0);
	int slot = int(COLOR.r * 16.0);
	float tone = (COLOR.g - 0.5) * 2.0;
	vec3 c = texelFetch(biome_pal, ivec2(b, cover_row + slot), 0).rgb;
	v_col = tone >= 0.0 ? mix(c, tone_light.rgb, tone) : mix(c, tone_dark.rgb, -tone);
	vec4 bw = bent_world(MODEL_MATRIX, VERTEX);
	v_view = bw.xyz - INV_VIEW_MATRIX[3].xyz;
	v_wz = bw.z;
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * bw);
}

void fragment() {
	vec3 c = (v_burn > 0.0 && v_up > 1.0 - v_burn) ? char_col.rgb : v_col;   // a hard line: no gradient
	ALBEDO = haze_ground(c * wl_mul + wl_add, v_view, -v_wz, fog_far);
}
