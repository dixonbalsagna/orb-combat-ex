"""Collateral window for the run (World, scratch, parked): the three tables in data, `present` and `peopleLeft`, a building's place and plan index, the owner lint.
python mk_collateral.py <root>      (root: an export of main's HEAD)
Lines in files that are not World's: state.gd (World.present, World.peopleLeft, Building.place, Building.plan), hash.gd (two conditional appends),
mood.gd (one token), launch.gd (one token), tools/schemas/map.json and tools/fixtures/cases.json (Tools'; separate diffs)."""
import sys, json, collections
from mk_wbc_lib import rw, rep

R = sys.argv[1].rstrip('/') + '/'


# ------------------------------------------------------------------ data
def data():
    doc = collections.OrderedDict()
    doc['schema'] = 'biomes.collateral/1'
    doc['_about'] = ('The collateral tables (docs/world/collateral-run.md; WorldCollateral). budget: the casualties a rolling 60 s admits, by tier 1 to 4, as shares of the people present at the stage\'s start; '
                     'ceiling: the cumulative total, by tier; eventAllow: what one set piece of each kind may borrow beyond the window\'s room, by tier. The fifth entry of each (the boss) lives in data/fight/tier5.json. '
                     'meterNorm: what the per-casualty meter gains (menace, power, anguish) are divided by: pop0 (the arena\'s people at full: a casualty is worth the same in ruins) or present (the people there now). '
                     'catastrophe: the mass-collapse set piece (Research); its allowance below tier 5 is zero.')
    doc['budget'] = [0.02, 0.04, 0.08, 0.15]
    doc['ceiling'] = [0.10, 0.30, 0.60, 0.90]
    doc['eventAllow'] = collections.OrderedDict([
        ('slide', [0.0, 0.0, 0.05, 0.10]), ('chain', [0.0, 0.0, 0.12, 0.20]), ('landslide', [0.0, 0.0, 0.05, 0.10]),
        ('quake', [0.0, 0.0, 0.0, 0.10]), ('catastrophe', [0.0, 0.0, 0.0, 0.0])])
    doc['meterNorm'] = 'pop0'
    open(R + 'data/biomes/collateral.json', 'w', encoding='utf-8', newline='').write(json.dumps(doc, indent=2, ensure_ascii=False) + '\n')
    four = {'type': 'array', 'minItems': 4, 'maxItems': 4, 'items': {'type': 'number', 'minimum': 0, 'maximum': 1}}
    sch = collections.OrderedDict()
    sch['$schema'] = 'https://json-schema.org/draft/2020-12/schema'
    sch['$id'] = 'meridian/biomes-collateral'
    sch['title'] = 'biomes.collateral/1'
    sch['description'] = ('data/biomes/collateral.json: the collateral tables (docs/world/collateral-run.md; WorldCollateral). budget and ceiling: four shares by tier; eventAllow: four shares by tier for each set-piece kind '
                          '(slide, chain, landslide, quake, catastrophe); meterNorm: pop0 or present. Every key required. Version field: schema. Policy: closed except keys starting with an underscore.')
    sch['type'] = 'object'
    sch['required'] = ['schema', 'budget', 'ceiling', 'eventAllow', 'meterNorm']
    sch['properties'] = collections.OrderedDict([
        ('schema', {'const': 'biomes.collateral/1'}), ('_about', {'type': 'string'}),
        ('budget', dict(four, description='Casualties per rolling 60 s by tier 1 to 4, shares of the people present at the stage start')),
        ('ceiling', dict(four, description='Cumulative casualties by tier 1 to 4, shares of the people present')),
        ('eventAllow', {'type': 'object', 'required': ['slide', 'chain', 'landslide', 'quake', 'catastrophe'], 'additionalProperties': False,
                        'properties': collections.OrderedDict((k, dict(four, description='What one %s may borrow beyond the window, by tier' % k)) for k in ['slide', 'chain', 'landslide', 'quake', 'catastrophe'])}),
        ('meterNorm', {'enum': ['pop0', 'present'], 'description': 'What the meter gains per casualty are divided by'})])
    sch['additionalProperties'] = False
    sch['patternProperties'] = {'^_': True}
    open(R + 'tools/schemas/biomes-collateral.schema.json', 'w', encoding='utf-8', newline='').write(json.dumps(sch, indent=2, ensure_ascii=False) + '\n')


# ------------------------------------------------------------------ state and hash
def state(s):
    s = rep(s, '''	var pop0: float = 0.0
''', '''	var pop0: float = 0.0
	var present: float = 0.0          # the people present at the stage's start: the budget and the ceiling are shares of it (pop0 in versus)
	var peopleLeft: float = -1.0      # the most people the run may still lose (-1: no limit, as in versus)
''')
    s = rep(s, '''	var idx: int = 0          # index in S.buildings (set at generation; not hashed)
''', '''	var idx: int = 0          # index in S.buildings (set at generation; not hashed)
	var place: int = -1       # the place it stands in: its settlement index today, the planet's place id (set at generation; not hashed: the world hash covers it)
	var plan: int = -1        # its index in that place's plan (the plan is seeded, so the same building has the same index every time; not hashed)
''')
    return s


def hashf(s):
    a = '''	for v in S.world.cbBuckets:
		out.append(v)
'''
    s = rep(s, a, '''	if S.world.present != S.world.pop0:
		out.append(S.world.present)   # a stage's people present, only when it differs from the arena's (a versus hash is as it was)
	if S.world.peopleLeft >= 0.0:
		out.append(S.world.peopleLeft)
''' + a)
    return s


def terrain(s):
    s = rep(s, '''			for e in g.buildings:
				var nb := SimState.Building.new()
''', '''			for ei in range(g.buildings.size()):
				var e = g.buildings[ei]
				var nb := SimState.Building.new()
				nb.place = si
				nb.plan = ei
''')
    return s


def structures(s):
    s = rep(s, 'get("near_share", 0.09)) * S.world.pop0', 'get("near_share", 0.09)) * S.world.present')
    s = rep(s, 'get("building_share", 0.02)) * S.world.pop0', 'get("building_share", 0.02)) * S.world.present')
    return s


def mood(s):
    return rep(s, '''	if S.world != null and S.world.pop0 > 0.0:
		var target: int = int(floor(float(mood.cas_perPerson) * float(mood.cas_popRef) * S.world.casualties / S.world.pop0))''', '''	if S.world != null and S.world.pop0 > 0.0:
		var target: int = int(floor(float(mood.cas_perPerson) * float(mood.cas_popRef) * S.world.casualties / WorldCollateral.normPeople(S)))''')


def launch(s):
    return rep(s, 'allow = WorldCollateral.EVENT_ALLOW["chain"][int(A.tier) - 1] * S.world.pop0', 'allow = WorldCollateral.eventAllow("chain", int(A.tier)) * S.world.present')


def collateral(s):
    s = rep(s, '''## Budget per rolling 60 s and ceiling on the cumulative total, by tier 1 to 4, as shares of the starting population.
const BUDGET: Array = [0.02, 0.04, 0.08, 0.15]
const CEILING: Array = [0.10, 0.30, 0.60, 0.90]
## What one set piece may borrow beyond the window's room, by tier 1 to 4 (0 at tier 1 and 2: no borrowing there).
const EVENT_ALLOW: Dictionary = {
	"slide": [0.0, 0.0, 0.05, 0.10],
	"chain": [0.0, 0.0, 0.12, 0.20],
	"landslide": [0.0, 0.0, 0.05, 0.10],
	"quake": [0.0, 0.0, 0.0, 0.10],
}
''', '''## The tables are data (data/biomes/collateral.json): budget per rolling 60 s and the ceiling on the cumulative total, by tier, as shares of the people present at the
## stage's start (pop0 in versus); what one set piece may borrow beyond the window's room, by tier, for each kind (slide, chain, landslide, quake, catastrophe).
## Loaded once when the class is first used; a fifth entry (the boss's: data/fight/tier5.json) extends a table and the tier functions follow its length.
const PATH := "res://data/biomes/collateral.json"
static var BUDGET: Array = []
static var CEILING: Array = []
static var EVENT_ALLOW: Dictionary = {}
static var METER_NORM: String = "pop0"
static var loadErrors: Array = []
static var dataHash: String = ""


static func _static_init() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		loadErrors.append("collateral.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != "biomes.collateral/1":
		loadErrors.append("collateral.json: schema is not biomes.collateral/1")
		return
	for v in j.budget:
		BUDGET.append(float(v))
	for v in j.ceiling:
		CEILING.append(float(v))
	for k in j.eventAllow:
		var a: Array = []
		for v in j.eventAllow[k]:
			a.append(float(v))
		EVENT_ALLOW[k] = a
	METER_NORM = str(j.meterNorm)
	dataHash = str(text.hash())


## What an allowance reads at a tier: the table's entry, or its last when the table is shorter than the tier.
static func eventAllow(kind: String, tier: int) -> float:
	if not EVENT_ALLOW.has(kind):
		return 0.0
	var a: Array = EVENT_ALLOW[kind]
	return a[clampi(tier - 1, 0, a.size() - 1)]


## What the meter gains per casualty are divided by (data: pop0 or present).
static func normPeople(S: SimState) -> float:
	return S.world.present if METER_NORM == "present" and S.world.present > 0.0 else S.world.pop0
''')
    s = rep(s, '''	w.maxTier = 1.0
	w.evtKind = ""''', '''	w.maxTier = 1.0
	w.present = w.pop0
	w.peopleLeft = -1.0
	w.evtKind = ""''')
    s = rep(s, "	return clampi(int(t), 1, 4)", "	return clampi(int(t), 1, BUDGET.size())")
    s = rep(s, "	return BUDGET[tier(S) - 1] * S.world.pop0", "	return BUDGET[tier(S) - 1] * S.world.present")
    s = rep(s, '''static func ceilingLeft(S: SimState) -> float:
	return maxf(0.0, CEILING[int(S.world.maxTier) - 1] * S.world.pop0 - S.world.casualties)''', '''static func ceilingLeft(S: SimState) -> float:
	var left: float = CEILING[clampi(int(S.world.maxTier), 1, CEILING.size()) - 1] * S.world.present - S.world.casualties
	if S.world.peopleLeft >= 0.0:
		left = minf(left, S.world.peopleLeft - S.world.casualties)   # the run's own limit: past it people shelter, as at the tier's ceiling
	return maxf(0.0, left)''')
    s = rep(s, '	w.evtLeft = EVENT_ALLOW[kind][t - 1] * w.pop0 if EVENT_ALLOW.has(kind) else 0.0', '	w.evtLeft = eventAllow(kind, t) * w.present')
    s = rep(s, "cause.md.menaceEvac * POP_REF / w.pop0)", "cause.md.menaceEvac * POP_REF / normPeople(S))")
    s = rep(s, "	var norm: float = POP_REF / S.world.pop0\n", "	var norm: float = POP_REF / normPeople(S)\n")
    return s


data()
rw(R, 'sim/core/state.gd', state)
rw(R, 'sim/core/hash.gd', hashf)
rw(R, 'sim/core/mood.gd', mood)
rw(R, 'sim/director/launch.gd', launch)
rw(R, 'sim/world/terrain.gd', terrain)
rw(R, 'sim/world/structures.gd', structures)
rw(R, 'sim/world/collateral.gd', collateral)
print('collateral window applied')
