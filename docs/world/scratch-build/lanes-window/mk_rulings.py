"""The lanes window's three rulings (+ the foreground switch) on a tree that has L1 with D1:
  - the population references scale with the starting population (shares in data/biomes/settlements.json pop_refs)
  - a damaged floor (fdmg above 0) of a skyscraper counts for stage 2 like a cut one
  - the core cap: one floors hit takes at most coreCapShare of a building's hit points (data/biomes/stages.json)
  - settlements.json "foreground": false leaves row 0 empty (the foreground row stands between the camera and the fight until Camera frames it)
python mk_rulings.py <root>"""
import sys, json
R = sys.argv[1].rstrip('/') + '/'


def rw(p, fn):
    s = open(R + p, encoding='utf-8', newline='').read()
    cr = '\r\n' in s
    s = fn(s.replace('\r\n', '\n'))
    open(R + p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if cr else s)


def rep(s, a, b, n=1):
    assert s.count(a) == n, (a[:100], s.count(a))
    return s.replace(a, b)


# ---------------------------------------------------------------- structures.gd
def structures(s):
    # the population references
    s = rep(s, 'const POP_NEAR_REF: float = 70.0 * SimConst.WS / SimConst.PS\n', '''const POP_NEAR_REF: float = 70.0 * SimConst.WS / SimConst.PS   # the old absolute reference (35 people at the original 390): kept for the parity oracle; the sim reads popNearRef(S)


## The reads of "populated" are shares of the planet's people, not counts (Game Design, balance-targets section 24): within a radius, 9% of the
## starting population is "populated" (1.0); a building's own cap for the planner's care is 2% of it. At 390 people that is 35 and 8, as before.
## data/biomes/settlements.json pop_refs {near_share, building_share}.
static func popNearRef(S: SimState) -> float:
	return float(WorldSettle.data().get("pop_refs", {}).get("near_share", 0.09)) * S.world.pop0


static func buildingPopRef(S: SimState) -> float:
	return float(WorldSettle.data().get("pop_refs", {}).get("building_share", 0.02)) * S.world.pop0
''')
    s = rep(s, '	return SimMathx.jclamp(s / POP_NEAR_REF, 0.0, 1.0)\n', '	return SimMathx.jclamp(s / popNearRef(S), 0.0, 1.0)\n')
    s = rep(s, '## Living civilians in standing buildings centred within r of x, scaled so POP_NEAR_REF or more reads 1.', '## Living civilians in standing buildings centred within r of x, scaled so popNearRef(S) or more reads 1.')
    # the damaged floor
    s = rep(s, '''	if b.floors >= WorldBrunt.FLOORS_MIN and b.fmask != (1 << b.floors) - 1:
		s = maxi(s, _cutStage)
''', '''	if b.floors >= WorldBrunt.FLOORS_MIN and b.fmask != (1 << b.floors) - 1:
		s = maxi(s, _cutStage)
	elif b.floors >= WorldBrunt.FLOORS_MIN and b.fdmg.size() > 0:   # a damaged floor counts like a cut one (Game Design, section 24): the tower empties sooner, as intended
		for v in b.fdmg:
			if v > 0.0:
				s = maxi(s, _cutStage)
				break
''')
    # the core cap
    s = rep(s, 'static var _leave: float = 0.0\n', 'static var _leave: float = 0.0\nstatic var _coreCap: float = 1.0\n')
    s = rep(s, '	_leave = clampf(float(j.get("leaveFrac", 0.0)), 0.0, 0.9)\n', '	_leave = clampf(float(j.get("leaveFrac", 0.0)), 0.0, 0.9)\n	_coreCap = clampf(float(j.get("coreCapShare", 1.0)), 0.05, 1.0)\n')
    s = rep(s, '## The share of its hit points a blast must leave a standing building', '''## The most of a building's hit points one floors hit may take from its core (stages.json coreCapShare; 1 is off): a tower of a few floors does not
## fall whole to the first cut.
static func coreCap() -> float:
	if not _stLoaded:
		_stLoad()
	return _coreCap


## The share of its hit points a blast must leave a standing building''')
    return s


rw('sim/world/structures.gd', structures)


# ---------------------------------------------------------------- brunt.gd
def brunt(s):
    s = rep(s, '	b.hp -= CORE_SHARE * oc.dmg\n', '	b.hp -= minf(CORE_SHARE * oc.dmg, WorldStructures.coreCap() * b.maxhp)   # the cap: one floors hit takes at most this share of the core\n')
    s = rep(s, 'static func _cheap(b) -> float:\n	return b.h / (BH * WS) + minf(b.popAlive, 8.0) + (2.0 if b.hp >= b.maxhp else 0.0)\n', 'static func _cheap(b, popCap: float) -> float:\n	return b.h / (BH * WS) + minf(b.popAlive, popCap) + (2.0 if b.hp >= b.maxhp else 0.0)\n')
    s = rep(s, '		sides[0 if dx < 0.0 else 1].append([_cheap(b), bi])\n', '		sides[0 if dx < 0.0 else 1].append([_cheap(b, popCap), bi])\n')
    return s


rw('sim/world/brunt.gd', brunt)


# ---------------------------------------------------------------- blast.gd
def blast(s):
    return rep(s, '	b.hp -= WorldBrunt.CORE_SHARE * oc.dmg\n', '	b.hp -= minf(WorldBrunt.CORE_SHARE * oc.dmg, WorldStructures.coreCap() * b.maxhp)\n')


rw('sim/world/blast.gd', blast)


# ---------------------------------------------------------------- launch.gd, location.gd (Encounter's, granted)
rw('sim/director/launch.gd', lambda s: rep(s, 'clampf(cb.popAlive / BRUNT_POP_REF, 0.0, 1.0)', 'clampf(cb.popAlive / WorldStructures.buildingPopRef(S), 0.0, 1.0)')
   .replace('const BRUNT_POP_REF: float = 8.0\n', 'const BRUNT_POP_REF: float = 8.0   # the old absolute cap: WorldStructures.buildingPopRef(S) (2% of the starting population) is what is read\n', 1))


def location(s):
    s = rep(s, 'var own: float = minf(hist[idx] / WorldStructures.POP_NEAR_REF, 1.0)', 'var own: float = minf(hist[idx] / ref, 1.0)')
    s = rep(s, 'ok = minf(hist[idx] / WorldStructures.POP_NEAR_REF, 1.0) > EMPTY', 'ok = minf(hist[idx] / ref, 1.0) > EMPTY')
    s = rep(s, 'var win: float = _window(hist, idx)\n', 'var win: float = _window(hist, idx, ref)\n')
    s = rep(s, 'var crowded: bool = _window(hist, i0) > LURE_START', 'var crowded: bool = _window(hist, i0, WorldStructures.popNearRef(S)) > LURE_START')
    s = rep(s, 'static func _window(hist: PackedFloat32Array, i: int) -> float:', 'static func _window(hist: PackedFloat32Array, i: int, ref: float) -> float:')
    s = rep(s, '	return minf(sum / WorldStructures.POP_NEAR_REF, 1.0)', '	return minf(sum / ref, 1.0)')
    s = rep(s, '## Population within +-WINDOW buckets of bucket i, as popNear reads it (POP_NEAR_REF or more is 1).', '## Population within +-WINDOW buckets of bucket i, as popNear reads it (ref, the near reference, or more is 1).')
    return s


rw('sim/director/location.gd', location)

# _search needs ref: find where the search starts its loop (the line "var bi: int = _bucketBiome[idx]" is inside it)
def location2(s):
    a = '	var best: float = '
    i = s.index('static func _search(')
    j = s.index('\n', i)
    # insert the reference as the first line of the body
    return s[:j + 1] + '	var ref: float = WorldStructures.popNearRef(S)\n' + s[j + 1:]


rw('sim/director/location.gd', location2)

# brunt.gd candidates: the cap read once
def brunt2(s):
    a = 'static func candidates(S: SimState, D) -> Array:\n'
    assert s.count(a) == 1
    return s.replace(a, a + '	var popCap: float = WorldStructures.buildingPopRef(S)\n')


rw('sim/world/brunt.gd', brunt2)


# ---------------------------------------------------------------- probe.gd (World's): the popNear check reads the same reference
def probe(s):
    s = rep(s, 'WorldStructures.popNear(Sr, xq, rq) * WorldStructures.POP_NEAR_REF', 'WorldStructures.popNear(Sr, xq, rq) * WorldStructures.popNearRef(Sr)')
    s = rep(s, 'minf(brute, WorldStructures.POP_NEAR_REF)', 'minf(brute, WorldStructures.popNearRef(Sr))')
    s = rep(s, 'rows[1] > 0 and rows[2] > 0 and rows[3] > 0 and rows[0] > 0, "every depth row has buildings")', 'rows[1] > 0 and rows[2] > 0 and rows[3] > 0 and (rows[0] > 0 or not bool(WorldSettle.data().get("foreground", true))), "every depth row has buildings (the foreground row may be switched off in settlements.json)")')
    return s


rw('sim/world/tools/probe.gd', probe)


# ---------------------------------------------------------------- settlements.gd: the foreground switch
def settle(s):
    s = rep(s, '		for row in dd.rows:\n			var r := SimRng.new(SimRng.deriveSeed(LAYOUT_SEED, "settle:%s:%s:row%d" % [s.id, dd.name, int(row)]))\n',
            '		for row in dd.rows:\n			if int(row) == 0 and not bool(data().get("foreground", true)):\n				continue   # the foreground row stands between the camera and the fight: empty until Camera frames it (each row has its own stream, so no other building moves)\n			var r := SimRng.new(SimRng.deriveSeed(LAYOUT_SEED, "settle:%s:%s:row%d" % [s.id, dd.name, int(row)]))\n')
    return s


rw('sim/world/settlements.gd', settle)

# ---------------------------------------------------------------- stagecheck.gd: the cases
def stagecheck(s):
    a = '	print("STAGE: %d check(s) failed" % fails)'
    return rep(s, a, ADD + a)


ADD = '\t# the lanes window\'s rulings: a damaged floor is stage 2, the core cap, the population references as shares, row 0 off\n\tvar S10 := fresh()\n\tvar t10 = null\n\tfor b in S10.buildings:\n\t\tif b.kind == "tower" and b.alive and b.floors >= 8:\n\t\t\tt10 = b\n\t\t\tbreak\n\tok(WorldStructures.stage(t10) == 0, "a whole tower is stage 0 before its floor is damaged")\n\tt10.fdmg = PackedFloat32Array()\n\tt10.fdmg.resize(t10.floors)\n\tt10.fdmg.fill(0.0)\n\tt10.fdmg[3] = 40.0\n\tok(WorldStructures.stage(t10) == 2, "a tower with a damaged floor (no cut floor) is stage 2 (%d)" % WorldStructures.stage(t10))\n\tvar S11 := fresh()\n\tS11.fighters[0].tier = 3.0\n\tvar t11 = null\n\tfor b in S11.buildings:\n\t\tif b.kind == "tower" and b.alive and b.floors >= 5 and b.floors <= 9:\n\t\t\tt11 = b\n\t\t\tbreak\n\tif t11 != null:\n\t\tvar y11: float = WorldStructures.baseY(S11, t11) + t11.h * 0.4\n\t\tvar oc11: Dictionary = WorldBrunt.outcomeDmg(S11, t11, y11, 3000.0)\n\t\tWorldBrunt.applyFloors(S11, t11, oc11, S11.fighters[0], 0.0, t11.x, S11.fighters[1], y11)\n\t\tok(t11.hp >= t11.maxhp * (1.0 - WorldStructures.coreCap()) - 0.01, "one floors hit leaves a tower of %d floors at %.0f%% of its hit points at least (cap %.2f of the core)" % [t11.floors, 100.0 * t11.hp / t11.maxhp, WorldStructures.coreCap()])\n\tok(WorldStructures.coreCap() > 0.0 and WorldStructures.coreCap() <= 1.0, "the core cap is read (%.2f)" % WorldStructures.coreCap())\n\tvar S12 := fresh()\n\tok(absf(WorldStructures.popNearRef(S12) - 0.09 * S12.world.pop0) < 0.001 and absf(WorldStructures.buildingPopRef(S12) - 0.02 * S12.world.pop0) < 0.001, "the population references are 9%% and 2%% of the starting population (%.1f and %.1f of %.0f)" % [WorldStructures.popNearRef(S12), WorldStructures.buildingPopRef(S12), S12.world.pop0])\n\tif WorldSettle.enabled() and not bool(WorldSettle.data().get("foreground", true)):\n\t\tvar r0: int = 0\n\t\tfor b in S12.buildings:\n\t\t\tif int(b.row) == 0:\n\t\t\t\tr0 += 1\n\t\tok(r0 == 0, "the foreground row is empty while settlements.json foreground is false (%d buildings in row 0)" % r0)\n'
rw('sim/world/tools/stagecheck.gd', stagecheck)


# ---------------------------------------------------------------- data
p = R + 'data/biomes/stages.json'
d = json.load(open(p, encoding='utf-8'))
d['coreCapShare'] = 0.5
d['_about'] = d['_about'] + ' coreCapShare: one floors hit (a brunt or a shot through a skyscraper) wears the core by at most this share of the building\'s hit points (1 is off). A damaged floor counts for stage 2 like a cut one.'
open(p, 'w', encoding='utf-8', newline='').write(json.dumps(d, indent=2) + '\n')
p = R + 'data/biomes/settlements.json'
t = open(p, encoding='utf-8', newline='').read()
assert t.count('"enabled": true,') == 1
t = t.replace('"enabled": true,', '"enabled": true,\n  "foreground": false,\n  "pop_refs": {"near_share": 0.09, "building_share": 0.02},', 1)
json.loads(t)
open(p, 'w', encoding='utf-8', newline='').write(t)
print('rulings applied')
