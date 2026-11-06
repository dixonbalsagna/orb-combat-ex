// The biomes' cover and the trees on the tile ground (RenderTileGround): cover.gdshaderinc without the ground.
shader_type spatial;
render_mode unshaded, cull_disabled;

#define TILE_GROUND
#include "res://render/shaders/cover.gdshaderinc"
