// A signature beam's sheath (render/vfx/beam_look.gd; docs/vfx/beam-look.md): additive prisms, back faces only, with the ortho projection of the glow shader. See beam_core.gdshaderinc.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_front;

#include "res://render/vfx/shaders/beam_core.gdshaderinc"
