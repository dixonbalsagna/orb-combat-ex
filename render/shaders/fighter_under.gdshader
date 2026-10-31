// A fighter under deep water (docs/rendering/biomes.md): his body drawn again after the water, at render priority 1, as
// seen through a plain sheet, so the water's depth steps hide the bed and never him. Only what's below the water's level
// is drawn, with the depth buffer the body wrote in its own pass: what stands in front of him still stands in front.
// Attached only while he's under (AnimBody.set_under), and its uniforms copied from the body's. The body:
// fighter_body.gdshaderinc. His outline: fighter_hull_under.gdshader.
shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_never;
#define UNDER

#include "res://render/shaders/fighter_body.gdshaderinc"
