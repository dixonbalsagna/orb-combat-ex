// The water on the tile ground (RenderTileGround): the wet tiles a second time, the fragment of water.gdshaderinc with a vertex stage of its own.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

#define TILE_GROUND
#include "res://render/shaders/water.gdshaderinc"
