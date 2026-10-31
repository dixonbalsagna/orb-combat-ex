// Fighter outlines: the inverted hull, a fighter mesh's next pass (docs/rendering/outline-normals-plan.md). Each
// vertex moves along the direction baked into NORMAL (render/core/outline_bake.gd; skinned with its bone, so it
// follows the pose) by its reach in UV2.x times outline_px pixels, then takes the same projection as the body: the
// hybrid projection (ortho.gdshaderinc) or, with ortho 0, the bent perspective. Under the hybrid projection a fighter
// is orthographic at its anchor's scale, so one world-per-pixel factor holds for the whole fighter and the outline is
// as thick at the screen's edge as at its centre, at any zoom. A fighter at depth (B3) draws smaller, and his outline
// thins by the same perspective scale, down to min_px. Back faces only: the body's front always wins the depth.
shader_type spatial;
render_mode unshaded, cull_front;

#include "res://render/shaders/fighter_hull.gdshaderinc"
