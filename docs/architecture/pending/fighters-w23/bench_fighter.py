# PARKED BUILD (Simulation): window 2 of docs/architecture/fighters-as-data.md, on top of window 1.
# The reference fighter, on a bench outside the roster, and a hash a fighter.
#   new   data/fighters/REFERENCE/fighter.json, data/fighters/bench.json
#   edits sim/core/fighter_data.gd, sim/core/replay.gd, sim/core/tools/parity.gd
# The roster file, the roster's order and the roster's data hash do not change, so no golden moves: a bench fighter is
# hashed into a replay only when the replay's setup names him.
# Provisional until Game Design rules: his role word (reference), his Rally rule (second_wind, as the two have) and his
# finisher (generic, which belongs to nobody).
# Usage: python bench_fighter.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s=open(p,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(p,a[:80],s.count(a))
        s=s.replace(a,b)
    open(p,'w',encoding='utf-8',newline='\n').write(s)

os.makedirs('data/fighters/REFERENCE', exist_ok=True)
open('data/fighters/REFERENCE/fighter.json','w',encoding='utf-8',newline='\n').write('''{
  "schema": "fighter/1",
  "id": "REFERENCE",
  "identity": {
    "role": "reference",
    "col": "#b9b9b9",
    "aura": "#e8e8e8",
    "hair": "#6f6f6f"
  },
  "stats": {
    "care": 0.0,
    "dmgMul": 1.0,
    "spd": 1.0,
    "maxhp": 1600.0
  },
  "kit": {
    "canHide": false
  },
  "rally": {
    "rule": "second_wind",
    "_note": "the rule the two fighters in the build have, so the yardstick plays the system as they do. Provisional until Game Design rules"
  },
  "finishers": {
    "base": "generic"
  },
  "sigCooldown": 120
}
''')
open('data/fighters/bench.json','w',encoding='utf-8',newline='\n').write('["REFERENCE"]\n')

edit('sim/core/fighter_data.gd', [
('''## Loaded once per process, like DirData; the data are match inputs.
''','''## data/fighters/bench.json, optional, lists fighters that load and can be named in a match's setup but are not in the
## roster: not on the select screen, and not in the roster's data hash. The reference fighter is one.
## Loaded once per process, like DirData; the data are match inputs.
'''),
('''static var _order: Array = []
''','''static var _order: Array = []
static var _bench: Array = []        # the bench's ids, in the file's order
static var _hashes: Dictionary = {}  # id -> the hash of what he resolves to, for every fighter loaded
'''),
('''	_defs = {}
	_order = []
	_errors = []
''','''	_defs = {}
	_order = []
	_bench = []
	_hashes = {}
	_errors = []
'''),
('''		var fj = _read(id + "/fighter.json", h)
		var wj = _resolve(id, "wounds.json", sw, h)
		var mj = _read(id + "/meters.json", h) if FileAccess.file_exists(root + id + "/meters.json") else {}
		var lj = _resolve(id, "ladder.json", sl, h)
		if not (fj is Dictionary and wj is Dictionary and lj is Dictionary):
			continue
		var def := _fighter(id, fj)
		def.wd = _wounds(id, wj)
		var meters: Dictionary = mj.get("meters", {}) if mj is Dictionary else {}
		for m in meters:
			if not String(m).begins_with("_") and not METERS.has(m):
				_err(id + "/meters.json: unknown meter '" + m + "' (D1b knows anguish and menace)")
		def.anguish = meters.has("anguish")
		def.menace = meters.has("menace")
		def.md = _meters(id, meters)
		def.ld = _ladder(id, lj)
		_defs[id] = def
		_order.append(id)
	_hash = h.hex()
''','''		if _one(id, h, sw, sl):
			_order.append(id)
	_hash = h.hex()
	# the bench: loaded as the roster's fighters are, and left out of the roster's hash
	if FileAccess.file_exists(root + "bench.json"):
		var bj = _load(root + "bench.json", "bench.json")
		if not (bj is Array):
			_err("bench.json: expected an array of fighter ids")
			bj = []
		for id in bj:
			if not (id is String) or _defs.has(id):
				_err("bench.json: bad id, or one the roster already has: " + str(id))
				continue
			if _one(id, SimHash.Hasher.new(), sw, sl):
				_bench.append(id)


## Load one fighter into _defs, folding his files into h under their names, and keep the hash of what he resolves to.
## False when a file of his is missing or does not parse.
static func _one(id: String, h: SimHash.Hasher, sw, sl) -> bool:
	var fj = _read(id + "/fighter.json", h)
	var wj = _resolve(id, "wounds.json", sw, h)
	var mj = _read(id + "/meters.json", h) if FileAccess.file_exists(root + id + "/meters.json") else {}
	var lj = _resolve(id, "ladder.json", sl, h)
	if not (fj is Dictionary and wj is Dictionary and lj is Dictionary):
		return false
	var def := _fighter(id, fj)
	def.wd = _wounds(id, wj)
	var meters: Dictionary = mj.get("meters", {}) if mj is Dictionary else {}
	for m in meters:
		if not String(m).begins_with("_") and not METERS.has(m):
			_err(id + "/meters.json: unknown meter '" + m + "' (D1b knows anguish and menace)")
	def.anguish = meters.has("anguish")
	def.menace = meters.has("menace")
	def.md = _meters(id, meters)
	def.ld = _ladder(id, lj)
	_defs[id] = def
	var hf := SimHash.Hasher.new()
	hf.text(id)
	for part in [["fighter.json", fj], ["wounds.json", wj], ["meters.json", mj], ["ladder.json", lj]]:
		hf.text(part[0])
		_canon(hf, part[1])
	_hashes[id] = hf.hex()
	return true
'''),
('''## The roster order (the select screen; the first two are the default pairing).
static func order() -> Array:
	_ensure()
	return _order
''','''## The roster order (the select screen; the first two are the default pairing).
static func order() -> Array:
	_ensure()
	return _order


## The bench: fighters a match's setup may name that are not in the roster.
static func bench() -> Array:
	_ensure()
	return _bench


## True when id is a fighter the data has, in the roster or on the bench.
static func has(id: String) -> bool:
	_ensure()
	return _defs.has(id)


## The hash of what one fighter resolves to (his fighter.json and meters.json, and the game's wounds and ladder with his
## differences). A replay folds it in for a bench fighter it names.
static func hashOf(id: String) -> String:
	_ensure()
	return String(_hashes.get(id, ""))
'''),
('''	if not ["hero", "villain", "rival"].has(d.role):''','''	if not ["hero", "villain", "rival", "reference"].has(d.role):'''),
])

edit('sim/core/replay.gd', [
('''"data": dataHash(), "seed": seed,''','''"data": dataHash(setup), "seed": seed,'''),
('''	if rp.get("data", "") != dataHash():''','''	if rp.get("data", "") != dataHash(rp.get("setup", {})):'''),
('''static func dataHash() -> String:
	var h := SimHash.Hasher.new()
''','''## setup is the match's: a fighter from the bench that its slots name is folded in too. He is not in the roster, so he is
## not in the roster's hash; a replay that does not name him is the same whatever his data are.
static func dataHash(setup: Dictionary = {}) -> String:
	var h := SimHash.Hasher.new()
'''),
('''	h.text(WorldBrunt.dataHash())          # World's brunt ladder and lodge: data/biomes/brunt.json
''','''	h.text(WorldBrunt.dataHash())          # World's brunt ladder and lodge: data/biomes/brunt.json
	for id in setup.get("slots", []):
		if id is String and FighterData.bench().has(id):
			h.text(id)
			h.text(FighterData.hashOf(id))
'''),
])

edit('sim/core/tools/parity.gd', [
('''	check("the game's wounds and ladder files, and a fighter's differences", _sharedFiles())
''','''	check("the game's wounds and ladder files, and a fighter's differences", _sharedFiles())
	check("the bench, and the reference fighter", _benchFighter())
'''),
('''## D1a negative controls: fixtures made from PROTAGONIST's real files with one fault each''','''## The bench (data/fighters/bench.json): fighters that load and can be named in a match's setup but are not in the
## roster. The reference fighter is on it: base stats, no care, no meter, the game's wounds and ladder. The roster, its
## order and its hash are as they were (the roster check above holds them to the golden). A match can name him in either
## slot, or twice. A replay that names him carries his data in its data hash, plays back, and is refused when his data
## change; a replay that does not name him is as it was.
func _benchFighter() -> String:
	if FighterData.bench() != ["REFERENCE"] or not FighterData.has("REFERENCE") or FighterData.order().has("REFERENCE") or FighterData.has("NOBODY"):
		return "the bench reads %s" % str(FighterData.bench())
	var d: Dictionary = FighterData.def("REFERENCE")
	var p: Dictionary = FighterData.def("PROTAGONIST")
	if d.dmgMul != 1.0 or d.spd != 1.0 or d.care != 0.0 or d.anguish or d.menace or d.role != "reference":
		return "the reference fighter is not plain: damage %s, speed %s, care %s" % [str(d.dmgMul), str(d.spd), str(d.care)]
	if d.wd.wearPerDamage != p.wd.wearPerDamage or d.wd.family.light != p.wd.family.light or d.ld.taken != p.ld.taken or d.ld.thresholds != p.ld.thresholds:
		return "the reference fighter's wounds or ladder are not the game's"
	var hs := {}
	for id in ["PROTAGONIST", "RIVAL", "REFERENCE"]:
		var hx: String = FighterData.hashOf(id)
		if hx == "" or hs.has(hx):
			return "the hash of %s is empty, or another fighter's" % id
		hs[hx] = true
	var d0: String = SimReplay.dataHash()
	if SimReplay.dataHash({"slots": ["RIVAL", "PROTAGONIST"]}) != d0 or SimReplay.dataHash({"flip": true}) != d0:
		return "a replay of the roster's fighters changed its data hash"
	var dref: String = SimReplay.dataHash({"slots": ["REFERENCE", "RIVAL"]})
	if dref == d0:
		return "a replay that names the reference fighter does not carry his data"
	for slots in [["REFERENCE", "REFERENCE"], ["REFERENCE", "PROTAGONIST"], ["RIVAL", "REFERENCE"]]:
		var S := SimCore.createSim()
		var su := {"slots": slots}
		if slots[0] == slots[1]:
			su.names = ["REFERENCE-A", "REFERENCE-B"]
		SimCore.newMatch(S, 5, {}, su)
		for t in range(900):
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
		for i in range(2):
			var f = S.fighters[i]
			if f.id != slots[i] or not is_finite(f.x) or not is_finite(f.y) or (f.id == "REFERENCE" and (f.hasAnguish or f.hasMenace or f.dmgMul != 1.0)):
				return "a match of %s: slot %d did not play as %s" % [str(slots), i, slots[i]]
		SimCore.dispose(S)
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 7, {}, {"slots": ["REFERENCE", "RIVAL"]})
	for t in range(600):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != dref:
		return "a recorded match of the reference fighter does not carry his data hash"
	var res: Dictionary = SimReplay.play(JSON.parse_string(JSON.stringify(rp)))
	if not res.ok:
		return "a replay of the reference fighter: %s at tick %d" % [res.reason, res.firstBadTick]
	# his data change: the roster's hash and a roster replay hold, and his own replay is refused
	var h0: String = FighterData.dataHash()
	var dir := "user://bench_fixture/"
	for id in ["PROTAGONIST", "RIVAL", "REFERENCE"]:
		DirAccess.make_dir_recursive_absolute(dir + id)
		for fname in ["fighter.json", "meters.json"]:
			if not FileAccess.file_exists(FighterData.ROOT + id + "/" + fname):
				continue
			var text: String = FileAccess.get_file_as_string(FighterData.ROOT + id + "/" + fname)
			if id == "REFERENCE" and fname == "fighter.json":
				if text.count("\\"dmgMul\\": 1.0") != 1:
					return "the fixture's pattern is not in the reference fighter's file once"
				text = text.replace("\\"dmgMul\\": 1.0", "\\"dmgMul\\": 1.04")
			var fw := FileAccess.open(dir + id + "/" + fname, FileAccess.WRITE)
			fw.store_string(text)
			fw.close()
	for name in ["roster.json", "bench.json"]:
		var fr := FileAccess.open(dir + name, FileAccess.WRITE)
		fr.store_string(FileAccess.get_file_as_string(FighterData.ROOT + name))
		fr.close()
	FighterData.quiet = true
	FighterData.loadFrom(dir)
	var out: String = ""
	if not FighterData.errors().is_empty():
		out = "the bench fixture: " + "; ".join(FighterData.errors())
	elif FighterData.dataHash() != h0 or SimReplay.dataHash() != d0:
		out = "a change to a bench fighter's data changed the roster's hash, or a roster replay's"
	elif SimReplay.dataHash({"slots": ["REFERENCE", "RIVAL"]}) == dref or SimReplay.play(JSON.parse_string(JSON.stringify(rp))).reason != "data":
		out = "a replay of the reference fighter was not refused after his data changed"
	FighterData.quiet = false
	FighterData.loadFrom()
	return out


## D1a negative controls: fixtures made from PROTAGONIST's real files with one fault each'''),
])
print("window 2: the reference fighter is on the bench, and every fighter has a hash")
