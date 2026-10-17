// A signature beam's body and core (render/vfx/beam_look.gd; docs/vfx/beam-look.md): alpha-blended prisms, back faces only, with the ortho projection of the glow shader. See beam_core.gdshaderinc.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_front;

#include "res://render/vfx/shaders/beam_core.gdshaderinc"
