"""Window 15 (World, 2026-10-26): the surfacing rule, behind data/biomes/water.json surface.enabled (off).   python mk_s1.py <root>   (root: HEAD plus the window 13, wreck-toss, campaign-route and rivers diffs)
Game Design rulings 2026-10-23b item 7 (and rows 13 to 15): a fighter dropped or landing in water surfaces set within 30 ticks, with no down state beyond that, and counts as landed once he surfaces.
 - data/biomes/water.json: surface {enabled, ticks}; sim/world/fill.gd reads it (surfaceOn, surfaceTicks); tools/schemas/biomes-water.schema.json (Tools', granted)
 - sim/world/contact.gd (World's): a launched body in water (not waded) rises toward the surface so as to arrive on the last of `ticks` ticks, and its flight ends there, set on the surface (the sink rule, which ends it wherever it has slowed, is replaced while the rule is on); the data hash carries the switch when on
 - Simulation's: sim/core/state.gd Fighter.wetT (1 line) and sim/core/hash.gd (2 lines: hashed only while not 0)"""
import sys, json, collections
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def water_json(s):
    s = rep(s, '''  "douse": { "scorchMin": 0.3 }
}''', '''  "douse": { "scorchMin": 0.3 },
  "surface": { "enabled": false, "ticks": 30 }
}''')
    return rep(s, '''",
  "enabled": false,''', ''' surface: Game Design's rule for a fighter who lands in water (rulings 2026-10-23b item 7): with enabled, a launched body in water that is not waded rises so as to reach the surface on the last of `ticks` ticks, and his flight ends there, set on the surface and landed.",
  "enabled": false,''')


def fill(s):
    s = rep(s, '''static var K_DOUSE: float = 0.3
''', '''static var K_DOUSE: float = 0.3
static var K_SURF_ON: bool = false
static var K_SURF_TICKS: int = 30
''')
    s = rep(s, '''static func parsed() -> Dictionary:''', '''## The surfacing rule (Game Design 2026-10-23b item 7): on, and in how many ticks a body that has gone under surfaces. Independent of the fill's switch.
static func surfaceOn() -> bool:
	if not _loaded:
		_load()
	return K_SURF_ON


static func surfaceTicks() -> int:
	if not _loaded:
		_load()
	return K_SURF_TICKS


## For tools and checks: the surfacing rule's switch for this process (the file is not touched).
static func setSurface(on: bool) -> void:
	if not _loaded:
		_load()
	K_SURF_ON = on


static func parsed() -> Dictionary:''')
    s = rep(s, '''	if int(j.fill.halfMax) < 4''', '''	if j.has("surface") and (not (j.surface is Dictionary) or int(j.surface.ticks) < 2):
		_errors.append("water.json: surface is {enabled, ticks} with ticks at least 2")
	if int(j.fill.halfMax) < 4''')
    return rep(s, '''	K_DOUSE = float(j.douse.scorchMin)''', '''	K_DOUSE = float(j.douse.scorchMin)
	K_SURF_ON = bool(j.surface.enabled) if j.has("surface") else false
	K_SURF_TICKS = int(j.surface.ticks) if j.has("surface") else 30''')


def contact(s):
    s = rep(s, '''	var wet: bool = false
	var hopped: bool = false
	var tier: float = 1.0''', '''	var wet: bool = false
	var wetT: int = 0            # ticks under the surface since the launch took him in (the surfacing rule: WorldFill.surfaceOn)
	var hopped: bool = false
	var tier: float = 1.0''')
    s = rep(s, '''	b.wet = f.wet
	b.hopped = f.hopped''', '''	b.wet = f.wet
	b.wetT = f.wetT
	b.hopped = f.hopped''')
    s = rep(s, '''	f.wet = b.wet
	f.hopped = b.hopped''', '''	f.wet = b.wet
	f.wetT = b.wetT
	f.hopped = b.hopped''')
    s = rep(s, '''		b.vy *= SimDetMath.pow(0.1, dt)
		if SimDetMath.hypot(b.vx, b.vy) < K_SINK and b.age > 0.3:
			b.done = true
			b.end = "water"
			ev.append({"k": "sink", "x": b.x, "y": b.y})
''', '''		b.vy *= SimDetMath.pow(0.1, dt)
		if WorldFill.surfaceOn():   # Game Design 2026-10-23b item 7: he surfaces set within the data's ticks, with no down state, and counts as landed there
			b.wetT += 1
			var left: int = WorldFill.surfaceTicks() - b.wetT
			if left <= 0:
				b.y = wsurf
				b.vx = 0.0
				b.vy = 0.0
				b.wetT = 0
				b.done = true
				b.end = "water"
				ev.append({"k": "sink", "x": b.x, "y": b.y})
			else:
				b.vy = maxf(b.vy, (wsurf - b.y) / (float(left) * dt))   # rise so as to arrive on the last tick
		elif SimDetMath.hypot(b.vx, b.vy) < K_SINK and b.age > 0.3:
			b.done = true
			b.end = "water"
			ev.append({"k": "sink", "x": b.x, "y": b.y})
	else:
		b.wetT = 0
''')
    return rep(s, '''	if skateOn():
		h.text("biomes.skate")''', '''	if WorldFill.surfaceOn():
		h.text("biomes.surface")
		FighterData._canon(h, WorldFill.data().surface)   # the surfacing rule, on: a replay must know
	if skateOn():
		h.text("biomes.skate")''')


def state(s):
    return rep(s, '''	var wet: bool = false
	var launchT: float = 1.0''', '''	var wet: bool = false
	var wetT: int = 0              # World: ticks under the surface since a launch took him in (the surfacing rule); 0 when dry; hashed when not 0
	var launchT: float = 1.0''')


def hash_(s):
    return rep(s, '''		if int(f.ctrlT) != -1:''', '''		if int(f.wetT) != 0:
			out.append(f.wetT)   # World's surfacing rule: hashed only while a body is under
		if int(f.ctrlT) != -1:''')


rw(R, 'data/biomes/water.json', water_json)
rw(R, 'sim/world/fill.gd', fill)
rw(R, 'sim/world/contact.gd', contact)
rw(R, 'sim/core/state.gd', state)
rw(R, 'sim/core/hash.gd', hash_)
p = R + 'tools/schemas/biomes-water.schema.json'
j = json.load(open(p, encoding='utf-8'), object_pairs_hook=collections.OrderedDict)
j['required'].append('surface')
j['properties']['surface'] = collections.OrderedDict([("type", "object"), ("required", ["enabled", "ticks"]), ("additionalProperties", False),
    ("description", "The surfacing rule (Game Design 2026-10-23b item 7)."), ("properties", collections.OrderedDict([
        ("enabled", collections.OrderedDict([("type", "boolean"), ("description", "A launched body in water surfaces set within ticks, with no down state.")])),
        ("ticks", collections.OrderedDict([("type", "integer"), ("minimum", 2), ("maximum", 600), ("description", "How many ticks.")]))]))])
open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2) + '\n')
print('surfacing applied')
