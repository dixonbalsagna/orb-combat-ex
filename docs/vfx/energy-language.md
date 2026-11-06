# One energy, in every beam, blast and impact (2026-11-01)

Orb (docs/ep/vision.md, 2026-11-01): "all energy should be consistent across the types of rules I described". The rules are the clash look's (docs/vfx/clash-look.md): a fighter's energy is **composed from his energy style, his form and his power** (`VfxClashLook.side`: his lane and a second tint at the same luminance, his front, his texture, his power, a data row per fighter), and drawn in one shader family, so his beam's body, the point where it meets another's, a blast's head and a blast's impact read as the same energy.

| | What it is | Where |
|---|---|---|
| A beam | the three-layer prism, his tints, ripple and pattern (boil or facets) | `beam.gdshader`, `beam_look.gd` (on main) |
| The clash | the air, the shine, and each beam's head pressed, flared and shedding eddies | `clash_view.gd`, `beam_core.gdshaderinc` |
| A blast's head (new) | a short shape in his front, in his tints, with his texture: **the Protagonist's thick wedge with bubble rings, the Anti-hero's needle with a crystal mosaic, a slim lens with a rim line, a jagged slug with gaps fixed along it, a capsule** | `energy_head.gdshader`, `energy_head.gd` |
| A blast's impact (new) | his own pieces thrown out of the point (a pressure fan of 5, a sheaf of 8 lances, 3 long arcs, 6 pieces of scrap, 4), in place of the flash disc, the splash lines and the burst's hoops | `shots_view.gd` |

**Not a ball, a disc or a hoop, and nothing rotates** (Legal RL-225 for the charged shot's look; e11): every head is longer than it is wide, and a check holds that. The tail the shots already drew (a ribbon in the beam's flavour) stays; the three concentric discs and the halo are what the head replaces. The pattern moves hue only (brightness within 6%).

**The charged shot (the Driver, B held; energy-overhaul section 21) and Y's wide explosion.** The charged shot has no event in the sim yet, so nothing here is drawn for it by name; when it exists it goes through the same call with its level as the shot's radius, and RL-225's per-kit shapes are the fronts: the Protagonist's short thick wedge (the shove), the Anti-hero's needle, the Empress's slim lens (a ground line that rears is Rendering's and VFX's to build with her kit), the Cyborg's jagged slug of scrap. Y's wide explosion is the impact's pieces at a larger size and count; the existing explosion look (flames, smoke) is on top and unchanged.

**Switch and cost.** Off by default (`VfxHub.energy_heads_enabled`, `VfxLook.HEADS_DEFAULT`); a local preview page turns it on with `?heads=1`. One MultiMesh of at most 96 pieces and one draw call; one quad each, a handful of noise samples at most per fragment, no screen read: cost arithmetic only, Performance benches it. Lower levels keep the shape and drop the texture is not built yet (the shader has one path).

**Look for Orb:** `docs/vfx/img/energy-language/` (a sheet and two real-speed clips of two fighters throwing blasts at each other: today's discs, then the heads; the same run at the same ticks).
