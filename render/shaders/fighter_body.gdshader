// A skinned fighter mesh's body (baked by render/core/outline_bake.gd): flat-coloured and faceted like every greybox
// part, lit by the fixed fake light. The mesh's NORMAL carries the outline's smoothed direction, so the facet's own
// normal is taken here from the screen-space derivatives of the view-space position: exact per face, whatever the
// skinning does. Drawn with the hybrid projection (ortho.gdshaderinc) like fighter_flat; its outline is the next pass
// (fighter_hull.gdshader).
//
// Battle damage (docs/design/rule-of-cool.md feature 1; docs/rendering/README.md, "Battle damage"): marks that stay and
// build with the wounds' stages, per region (head, core, arms, legs). Scuffs on clothing and gear, bruises on skin, and
// tears in clothing: patches open to the skin under it, with a dark frayed edge (not on the head, and not on gear). How
// much of each a stage shows is the outfit's, from Art's stage data (mark_scuff, mark_bruise, mark_tear: the share of
// the surface at stages 1, 2 and 3; render/core/damage_look.gd). The pattern is a noise in the mesh's rest space (CUSTOM0, from the
// bake), so a mark stays on its spot of the body through every pose. The region comes from the vertex's bone (UV2.y,
// from the bake) through bone_region. damage_detail 0 is the reduced version: a flat tint by stage, no pattern.
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://render/shaders/fighter_body.gdshaderinc"
