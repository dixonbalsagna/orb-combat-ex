// A fighter's outline under deep water: fighter_under.gdshader's, for the inverted hull. The body:
// fighter_hull.gdshaderinc.
shader_type spatial;
render_mode unshaded, cull_front, blend_mix, depth_draw_never;
#define UNDER

#include "res://render/shaders/fighter_hull.gdshaderinc"
