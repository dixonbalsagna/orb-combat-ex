// The beam clash's fallback for the distortion (render/vfx/clash_view.gd; docs/vfx/clash-look.md): no screen read; dark lens bands past each ring. See clash_core.gdshaderinc.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

#define CLASH_AIR
#include "res://render/vfx/shaders/clash_core.gdshaderinc"
