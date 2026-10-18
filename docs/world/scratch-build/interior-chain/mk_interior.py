"""The chain inside a tower (World, scratch, parked): sim/world/interior.gd, the hooks in brunt.gd and contact.gd, the data keys, and the lines Simulation owns.
python mk_interior.py <root> <interior.gd>     (root: an export of main's HEAD)"""
import sys, shutil
from mk_wbc_lib import rw, rep, data_keys

R = sys.argv[1].rstrip('/') + '/'
src = sys.argv[2]

KEYS = {
    "interiorChain": 0, "interiorTanMin": 0.26795, "interiorTanMax": 1.73205, "interiorCeilKeep": 0.4, "interiorFloorKeep": 0.7,
    "interiorMaxContacts": 5, "interiorMaxBounces": 3, "interiorFaceStop": 15, "interiorCapSeconds": 2.5, "interiorCeilTier": 3,
    "interiorExitTier": 3, "interiorHurt": 0.5,
}


def brunt(s):
    s = rep(s, '''	"wallSlamMul": 2.0, "wallStaggerTicks": 24,
}''', '''	"wallSlamMul": 2.0, "wallStaggerTicks": 24,
	# the chain inside a tower (buildings.md section 7.3, world/interior.gd): 0 off (today's behaviour) or 1 on; the send's angle (tangents of 15 and 60 degrees),
	# the speed kept through a ceiling and through a slab or face that breaks, the contact and bounce caps, the face's stop in ticks, the cap in seconds,
	# the effective tier that reaches the ceiling and the tier whose far face breaks, the share of a hit's damage a slab does him
	"interiorChain": 0, "interiorTanMin": 0.26795, "interiorTanMax": 1.73205, "interiorCeilKeep": 0.4, "interiorFloorKeep": 0.7,
	"interiorMaxContacts": 5, "interiorMaxBounces": 3, "interiorFaceStop": 15, "interiorCapSeconds": 2.5, "interiorCeilTier": 3,
	"interiorExitTier": 3, "interiorHurt": 0.5,
}''')
    s = rep(s, '''static func endFlight(S: SimState, f) -> void:
	f.aimB = -1''', '''static func endFlight(S: SimState, f) -> void:
	f.interior = null
	f.aimB = -1''')
    s = rep(s, '''	var passes: bool = oc.pass or hitText == "collapse" or hitText == "pancake"
''', '''	var passes: bool = oc.pass or hitText == "collapse" or hitText == "pancake"
	var broke: bool = passes
	var inside: bool = WorldInterior.eligible(S, f, b)   # the chain inside a tower (world/interior.gd), behind brunt.json interiorChain: he goes on inside, the face is passed either way
	if inside:
		passes = true
''')
    s = rep(s, '''	if passes and chainUsed(f) < chainCap(by.tier, f.launchSpecial) - 0.0001 and spLeft >= CHAIN_MIN_SP:''',
            '''	if passes and not inside and chainUsed(f) < chainCap(by.tier, f.launchSpecial) - 0.0001 and spLeft >= CHAIN_MIN_SP:''')
    s = rep(s, '''	var lodge: bool = passes and nx.b < 0
''', '''	var lodge: bool = passes and nx.b < 0 and not inside
''')
    s = rep(s, '''	var stop: float = STOP_FIRST if link == 1 else STOP_LINK
	S.dirS.stop = SimMathx.jmax(S.dirS.stop, minf(stop, STOP_TOTAL))
	if lodge:''', '''	if not inside:
		var stop: float = STOP_FIRST if link == 1 else STOP_LINK
		S.dirS.stop = SimMathx.jmax(S.dirS.stop, minf(stop, STOP_TOTAL))
	else:
		WorldInterior.begin(S, f, b, y, edge, dir, by, keep, broke)   # the face's stop is the data's ticks; the rest is the chain's (interior.gd step)
		return
	if lodge:''')
    return s


def contact(s):
    return rep(s, '''static func stepFighter(S: SimState, f, dt: float) -> void:
	var by = f.launchBy''', '''static func stepFighter(S: SimState, f, dt: float) -> void:
	if f.interior != null:
		WorldInterior.step(S, f, dt)   # the chain inside a tower (world/interior.gd): the ground's contact waits for it
		return
	var by = f.launchBy''')


def state(s):
    s = rep(s, '''	var flightHits: int = 0          # M1: buildings hit in the current launched flight (building_hit's n)
''', '''	var flightHits: int = 0          # M1: buildings hit in the current launched flight (building_hit's n)
	var interior = null              # World: the chain inside a tower (world/interior.gd): a Dictionary while he is in it, else null. Hashed only while set
''')
    s = rep(s, '''	var stop: int = 0             # damage (a hit)''', '''	var nx: float = 0.0           # interior_contact: the surface's normal on the body's side
	var ny: float = 0.0
	var punch: bool = false       # interior_contact: the slab or face broke
	var end: String = ""          # interior_end: lodge, exit, fall_out or capped
	var t: float = 0.0            # interior_end: seconds from the face
	var stop: int = 0             # damage (a hit)''')
    s = rep(s, "Animation). Not hashed", "Animation). Not hashed; interior_contact: the ticks held at the face (hashed there)")
    return s


def hashf(s):
    s = rep(s, '''		out.append(float(f.flightHits))
''', '''		out.append(float(f.flightHits))
		if f.interior != null:   # World's chain inside a tower (world/interior.gd): only while it runs, so a match without it hashes as before
			_obj(out, f.interior, ["b", "dir", "E", "k", "bn", "t", "i"])
''')
    s = rep(s, '''"journey_end": ["actor", "x", "y", "z", "spd", "n", "kind", "contacts", "lips", "nb", "dur"],''',
            '''"journey_end": ["actor", "x", "y", "z", "spd", "n", "kind", "contacts", "lips", "nb", "dur"],
	"interior_contact": ["actor", "x", "y", "z", "spd", "n", "b", "floor", "kind", "nx", "ny", "vn", "vt", "keep", "punch", "k", "stop"], "interior_end": ["actor", "x", "y", "z", "spd", "n", "b", "end", "contacts", "t"],''')
    return s


def viewfx(s):
    return rep(s, '"drop_end", "decisive", ', '"drop_end", "decisive", "interior_contact", "interior_end", ')


shutil.copyfile(src, R + 'sim/world/interior.gd')
rw(R, 'sim/world/brunt.gd', brunt)
rw(R, 'sim/world/contact.gd', contact)
rw(R, 'sim/core/state.gd', state)
rw(R, 'sim/core/hash.gd', hashf)
rw(R, 'sim/core/view/fx.gd', viewfx)
data_keys(R, KEYS,
          "The chain inside a tower (buildings.md section 7.3, ruled 2026-10-17; WorldInterior): interiorChain 0 off or 1 on; interiorTanMin and interiorTanMax the send's angle (tangents of 15 and 60 degrees); interiorCeilKeep and interiorFloorKeep the speed kept through a ceiling and through a slab or face that breaks; interiorMaxContacts and interiorMaxBounces the caps (no bounce is produced yet); interiorFaceStop the entry face's stop in ticks; interiorCapSeconds the ragdolled time from the face; interiorCeilTier the effective tier that reaches the ceiling; interiorExitTier the tier whose far face breaks; interiorHurt the share of a hit's damage a slab does him.",
          {
              "interiorChain": {"enum": [0, 1], "description": "The chain inside a tower: 0 off (today's behaviour), 1 on."},
              "interiorTanMin": {"type": "number", "exclusiveMinimum": 0, "maximum": 10, "description": "The shallowest send that goes on inside: the tangent of 15 degrees."},
              "interiorTanMax": {"type": "number", "exclusiveMinimum": 0, "maximum": 10, "description": "The steepest send that goes on inside: the tangent of 60 degrees."},
              "interiorCeilKeep": {"type": "number", "minimum": 0, "maximum": 1, "description": "The speed kept off a ceiling (Game Design: 0.4)."},
              "interiorFloorKeep": {"type": "number", "minimum": 0, "maximum": 1, "description": "The speed kept through a floor, or a face, that breaks (Game Design: 0.7)."},
              "interiorMaxContacts": {"type": "integer", "minimum": 1, "maximum": 8, "description": "The most slab and wall contacts of a chain (Game Design: 5)."},
              "interiorMaxBounces": {"type": "integer", "minimum": 0, "maximum": 8, "description": "The most bounces of a chain (Game Design: 3); no bounce is produced yet."},
              "interiorFaceStop": {"type": "integer", "minimum": 0, "maximum": 120, "description": "The entry face's hit-stop in ticks (Game Design: 15)."},
              "interiorCapSeconds": {"type": "number", "exclusiveMinimum": 0, "maximum": 4, "description": "The ragdolled time from the face to the end (Game Design: 2.5 s, inside the journey's 4 s)."},
              "interiorCeilTier": {"type": "integer", "minimum": 1, "maximum": 4, "description": "The effective tier from which a send reaches the ceiling (Game Design: 3)."},
              "interiorExitTier": {"type": "integer", "minimum": 1, "maximum": 4, "description": "The effective tier from which the far face breaks and he leaves; below it he lodges against it."},
              "interiorHurt": {"type": "number", "minimum": 0, "maximum": 2, "description": "The share of the face's per-speed damage a slab does him."},
          })
print('interior applied')
