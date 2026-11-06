// The tile ground (RenderTileGround): the ground's body (terrain.gdshaderinc) with its own vertex stage (tile_vertex.gdshaderinc).
shader_type spatial;
render_mode unshaded, cull_disabled;

#define TILE_GROUND
#include "res://render/shaders/terrain.gdshaderinc"
