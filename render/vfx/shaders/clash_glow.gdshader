// The beam clash's colour (render/vfx/clash_view.gd; docs/vfx/clash-look.md): the glow on one quad, mixed over the scene (added over a bright sky it went white). See clash_core.gdshaderinc.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

#define CLASH_GLOW
#include "res://render/vfx/shaders/clash_core.gdshaderinc"
