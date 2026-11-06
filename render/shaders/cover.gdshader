// The biomes' cover (biome rendering window 2; render/core/cover_view.gd, render/core/cover_meshes.gd): Art's flat
// silhouettes standing in the strip's plane on the band's ground. Each instance's foot reads the ground under it as the
// terrain draws it (ground4: craters, grooves and all), so a shape rises and falls with the ground, and a shape inside a
// crater is gone (Art: the cover inside a crater is removed; a match's prop, render/core/prop_view.gd, stands, and on a slope its foot sinks a little, prop_sink). What floats (a whitecap, a floe) sits at the water's level.
// A vertex's colour is its palette slot (COLOR.r) and tone step (COLOR.g) in the palette of the biome it grows in
// (INSTANCE_CUSTOM.r: RenderBiomeLook's column; the cover's rows from COVER_ROW), lit, mid and shade as Art drew it, or,
// where COLOR.b is 1, one of the fixed tones from fixed_row, the same in every biome (Art's shell);
// hazed into the sky as the ground is. A fellable tree (render/core/tree_view.gd) is drawn by this shader too: while it
// burns (INSTANCE_CUSTOM.b, its burn in hard steps) its crown is char from the top down to that share of its height.
shader_type spatial;
render_mode unshaded, cull_disabled;

#include "res://render/shaders/cover.gdshaderinc"
