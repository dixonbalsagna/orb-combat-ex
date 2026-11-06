// The beam clash's distortion (render/vfx/clash_view.gd; docs/vfx/clash-look.md): the screen behind the quad displaced by the pressure rings. Reads the screen: one full-frame copy while a clash is on. See clash_core.gdshaderinc.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

#define CLASH_AIR
#define CLASH_SCREEN
#include "res://render/vfx/shaders/clash_core.gdshaderinc"
