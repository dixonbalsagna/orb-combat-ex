// The planet's distant towns and cities (render/core/far_land.gd): low blocks standing on the planet's own far land where
// World's places are, turned by the slow drift with the land under them, and hazed into the sky as the ground is. One
// instance a block: its transform is its size and its foot's place on the planet copy (behind the fighter plane, where
// the far land is whole); its colour's red is its palette entry (town_cols) and its green its shade.
shader_type spatial;
render_mode unshaded, cull_disabled;

#include "res://render/shaders/color.gdshaderinc"
#include "res://render/shaders/bend.gdshaderinc"
#include "res://render/shaders/ground.gdshaderinc"
#include "res://render/shaders/skycol.gdshaderinc"

uniform vec3 wl_mul = vec3(1.0);   // the world's light, as the ground takes it
uniform vec3 wl_add = vec3(0.0);
uniform float fog_far = 12000.0;
uniform float town_cam_x = 0.0;    // this pane's camera x: a copy stands at k x the planet's length less it (planet_view.gd)
uniform vec4 town_cols[6] : source_color;   // RenderLook.FAR_TOWN_COLS: three for a city, three for a town
uniform float town_row0 = 9000.0;  // the ground mesh past the crater rows (planet_view.gd ground_rows): its first row's depth (-Z_TERRAIN_BACK),
uniform float town_row_k = 1.15;   // each next row this much deeper (1 + ROW_GROWTH),
uniform float town_stride = 8.0;   // and its columns this many apart (the last of RenderLook.STRIDES)
uniform float town_slope = 0.8;    // RenderLook.FAR_TOWN_SLOPE: no block stands on ground steeper than this (rise over run)

// The far land's height at (x, z) as the ground's mesh draws it, not as far4 reads it between the mesh's points (rows
// thousands of units apart there): the quad of its columns and rows round the point, split as the mesh splits it, across
// the diagonal from (column, deeper row) to (next column, nearer row) (planet_view.gd _make_ground_meshes). slope: the
// quad's steepest rise over run along its edges.
float far_mesh_h(float x, float z, out float slope) {
	float d = max(abs(z), town_row0);
	float k = floor(log(d / town_row0) / log(town_row_k));
	float d0 = town_row0 * pow(town_row_k, k);
	float d1 = min(d0 * town_row_k, fog_far);
	float z0 = sign(z) * d0;
	float z1 = sign(z) * d1;
	float cs = town_stride * col_w;
	float x0 = floor(x / cs) * cs;
	float u = (x - x0) / cs;
	float v = clamp((d - d0) / max(d1 - d0, 1.0), 0.0, 1.0);
	bool wet;
	float a = far4(x0, z0, far_weight(z0), false, wet).x;
	float b = far4(x0, z1, far_weight(z1), false, wet).x;
	float c = far4(x0 + cs, z0, far_weight(z0), false, wet).x;
	float e = far4(x0 + cs, z1, far_weight(z1), false, wet).x;
	slope = max(max(abs(c - a), abs(e - b)) / cs, max(abs(b - a), abs(e - c)) / max(d1 - d0, 1.0));
	if (u + v <= 1.0) {
		return a + u * (c - a) + v * (b - a);
	}
	return e + (1.0 - u) * (b - e) + (1.0 - v) * (c - e);
}

varying vec3 v_col;
varying vec3 v_view;
varying float v_wz;

void vertex() {
	// The foot's place on the planet (any copy reads the same place: the far land repeats with the planet's length).
	// The slow drift moves the place read at a screen x by z x drift_tan, so a place is drawn that far the other way;
	// the foot stands on the ground's mesh there. A foot in the sea or a lake, or on ground steeper than a town builds on,
	// leaves no block (all its corners meet).
	float x = MODEL_MATRIX[3].x + town_cam_x;
	float z = MODEL_MATRIX[3].z;
	float shift = z * drift_tan * far_weight(z);
	float slope;
	float h = far_mesh_h(x + shift, z, slope);
	VERTEX = (h < 0.0 || slope > town_slope) ? vec3(0.0) : VERTEX;
	VERTEX += vec3(shift / length(MODEL_MATRIX[0].xyz), h / length(MODEL_MATRIX[1].xyz), 0.0);
	v_col = town_cols[clamp(int(COLOR.r * 8.0), 0, 5)].rgb * COLOR.g;
	vec4 bw = bent_world(MODEL_MATRIX, VERTEX);
	v_view = bw.xyz - INV_VIEW_MATRIX[3].xyz;
	v_wz = bw.z;
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * bw);
}

void fragment() {
	vec3 c = flat_shade(v_col, NORMAL, 0.55) * wl_mul + wl_add;
	ALBEDO = haze_ground(c, v_view, -v_wz, fog_far);
}
