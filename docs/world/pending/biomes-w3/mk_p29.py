"""World, 2026-10-27: window 22, W3's world pieces (docs/combat/biomes.md section 6): trees on a path by mode, and the aftermath strips in surfaceAt and lookAt.   python mk_p29.py <root>   (root: main)
 - sim/world/structures.gd: damageArea takes a last parameter treeMode ("area", the default and today's; "burn", "fell", "snap", "none") for the trees its sample reaches
 - sim/world/after.gd: lookAt reads Combat's stripLooks (glaze ice, ember and crust "crust", flooded "water", burnt "ash"); surfaceAt(S, x) names the surface class a strip makes (rock)
 - sim/world/contact.gd: surfaceAt reads the strips (rubble first, as ever)
 - sim/world/ground.gd: LOOKS loses "ember" (a glowing strip reads crust, not a class of its own)
 - docs/world/after.md: the page"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def structures(s):
    s = rep(s, "static func damageArea(S: SimState, x: float, y: float, r0: float, dmg: float, cause, beam: bool = false, evt: float = 0.0, capLeft: int = -1, keep: float = 0.0, reachMul: float = -1.0) -> int:",
            "static func damageArea(S: SimState, x: float, y: float, r0: float, dmg: float, cause, beam: bool = false, evt: float = 0.0, capLeft: int = -1, keep: float = 0.0, reachMul: float = -1.0, treeMode: String = \"area\") -> int:")
    s = rep(s, '''## ringCap (cause.ld.reachRingCap, -1 off): at most this many buildings levelled beyond the old reach per call.
''', '''## ringCap (cause.ld.reachRingCap, -1 off): at most this many buildings levelled beyond the old reach per call.
## treeMode (the signature variant row's `trees`, docs/combat/biomes.md section 2): what the trees the area reaches become. "area" (the default) is what it always was: felled, with the fire cue. "burn": felled and charred
## (burn 1: the tree view draws a charred stump), with the fire cue. "fell": felled, no fire. "snap": felled with the crowns dropping (a debris cue at the crown), no fire. "none": the trees stand.
''')
    return rep(s, '''	for t in S.trees:
		if t.alive and absf(SimWrap.sdx(x, t.x)) < r * 0.7 and y < WorldTerrain.groundY(S, t.x) + r:
			t.alive = false
			SimFx.fire(S, t.x, WorldTerrain.groundY(S, t.x), 2)
	return levelled''', '''	if treeMode == "none":
		return levelled
	for t in S.trees:
		if t.alive and absf(SimWrap.sdx(x, t.x)) < r * 0.7 and y < WorldTerrain.groundY(S, t.x) + r:
			t.alive = false
			if treeMode == "burn":
				t.burn = 1.0
			if treeMode == "snap":
				SimFx.debris(S, t.x, WorldTerrain.groundY(S, t.x) + t.h * 0.8, 6, "#6b4f2a", 320.0)
			elif treeMode != "fell":
				SimFx.fire(S, t.x, WorldTerrain.groundY(S, t.x), 2)
	return levelled''')


def after(s):
    s = rep(s, '''## The look class a strip reads as, or "" when the ground's own stands: ice (glaze), ash (burnt grass), ember (glowing), crust (cooled).
static func lookAt(S: SimState, x: float) -> String:
	match kindAt(S, x):
		GLAZE:
			return "ice"
		BURNT:
			return "ash"
		EMBER:
			return "ember"
		CRUST:
			return "crust"
	return ""
''', '''## The look class a strip reads as (Combat's stripLooks), or "" when the ground's own stands: ice (glaze), ash (burnt grass), crust (a glowing ember strip and the cooled one: the glow is the hazard and the cue),
## water (a flooded groove). Scree reads rubble through the surface (S.rubble), not here.
static func lookAt(S: SimState, x: float) -> String:
	match kindAt(S, x):
		GLAZE:
			return "ice"
		BURNT:
			return "ash"
		EMBER, CRUST:
			return "crust"
		FLOODED:
			return "water"
	return ""


## The contact surface class a strip makes, or "" when the ground's own stands: ice and crust are rock (ground.json: sea_ice and volcanic are rock), as the look classes' "reads as" rows say.
static func surfaceAt(S: SimState, x: float) -> String:
	match kindAt(S, x):
		GLAZE, EMBER, CRUST:
			return "rock"
	return ""
''')
    s = rep(s, "ember EMBER while it glows (hazardAt; aftermathT is\n##   when it cools), then CRUST (look crust)", "ember EMBER while it glows (hazardAt; aftermathT is\n##   when it cools; look crust), then CRUST (look crust)")
    return s


def contact(s):
    return rep(s, '''	if S.rubble[col] >= K_RUBBLE_MIN:
		return "rubble"
	var c: int = _colSurf[col]''', '''	if S.rubble[col] >= K_RUBBLE_MIN:
		return "rubble"
	if S.aftermath.size() > 0:   # a beam's strip (glaze, ember, crust) is rock (after.gd)
		var al: String = WorldAfter.surfaceAt(S, x)
		if al != "":
			return al
	var c: int = _colSurf[col]''')


def ground(s):
    return rep(s, ', "shingle", "ember"]   # the look classes: the five built and the nine of Combat\'s biome park, and the one a beam\'s glowing ember strip reads as (after.gd)', ', "shingle"]   # the look classes: the five built and the nine of Combat\'s biome park')


rw(R, 'sim/world/structures.gd', structures)
rw(R, 'sim/world/after.gd', after)
rw(R, 'sim/world/contact.gd', contact)
rw(R, 'sim/world/ground.gd', ground)
print('p29 applied')
