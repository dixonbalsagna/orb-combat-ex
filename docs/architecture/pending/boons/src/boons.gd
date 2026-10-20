class_name SimBoons
extends RefCounted
## The run's rare boons (Game Design, rulings-2026-10-18b.md section 4; run-mode.md section 1.4): a base form that is a
## transformation. Run-only: a match's setup names them ("boons": {slot: id}), which no versus match does, so a match
## without them is the same to the bit. data/fight/boons.json holds their numbers, and joins a replay's data hash only for
## a setup that names a boon (docs/architecture/boons-core.md).
##   born_ready    every fight starts in his first form above base: step I for a fighter with steps of his own, the tier-2
##                 form for anyone else; power at that step's floor
##   second_skin   one form higher still (II; tier 3), and an opponent with Trial fills it at once: he starts below
##   borrowed      the temptation: every fight starts at his highest form, and his first broken region comes sooner
## The run's ceiling (run-mode.md section 1.1) caps the form when the run builds it; until then the ladder's top does.

const FILE: String = "res://data/fight/boons.json"
const IDS: Array = ["born_ready", "second_skin", "borrowed"]

static var _d = null
static var _hash: String = ""
static var _errors: Array = []
static var steps_: Dictionary = {}   # id -> the forms above base it starts in (borrowed: as high as he goes)
static var sooner: float = 0.0       # borrowed: the share sooner his first broken region comes


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	steps_ = {}
	var h := SimHash.Hasher.new()
	var j = FighterData._load(FILE, "fight/boons.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary):
		_err("missing, or not an object")
		_d = {}
		_hash = h.hex()
		return
	_d = j
	h.text("fight/boons.json")
	FighterData._canon(h, j)
	_hash = h.hex()
	for id in ["born_ready", "second_skin"]:
		var b = j.get(id)
		var n = b.get("steps") if b is Dictionary else null
		if not (n is float or n is int) or float(n) != floor(float(n)) or int(n) < 1:
			_err(id + ".steps: a whole number, 1 or more")
			n = 1
		steps_[id] = int(n)
	if steps_.second_skin <= steps_.born_ready:
		_err("second_skin.steps must be above born_ready's")
	steps_["borrowed"] = 99
	var bo = j.get("borrowed")
	var s = bo.get("firstBreakSooner") if bo is Dictionary else null
	if not (s is float or s is int) or float(s) < 0.0 or float(s) >= 0.9:
		_err("borrowed.firstBreakSooner: a share from 0 to under 0.9")
		s = 0.0
	sooner = float(s)


static func dataHash() -> String:
	_ensure()
	return _hash


static func errors() -> Array:
	_ensure()
	return _errors


## Tests only: read the file again on the next call.
static func reload() -> void:
	_d = null


## At a new match (SimCore.newMatch, after the forms' setup): each fighter the setup's "boons" names starts in his
## boon's form, with power at its floor. An opponent with Trial fills it at once when a boon starts the other above him.
## The collateral's budget is the higher tier's from the first second.
static func apply(S: SimState, setup: Dictionary) -> void:
	var bs = setup.get("boons", {})
	if not (bs is Dictionary) or bs.is_empty():
		return
	_ensure()
	for key in bs:
		var slot: int = int(key)
		var id: String = String(bs[key])
		if slot < 0 or slot >= S.fighters.size() or not IDS.has(id):
			push_error("SimBoons: the setup's boon %s for slot %s is not one" % [id, str(key)])
			continue
		var f = S.fighters[slot]
		f.boon = id
		_start(S, f, int(steps_[id]))
	for f in S.fighters:
		if f.boon == "":
			continue
		var o = SimRoster.opp(S, f)
		if SimForms.has(S, o) and o.form != null and f.tier > o.tier:
			o.form.trial += o.fd.tForm
		S.world.maxTier = maxf(S.world.maxTier, f.tier)


static func _start(S: SimState, f, n: int) -> void:
	if SimForms.has(S, f):
		var k: int = mini(n, f.fd.steps.size())
		var st: Dictionary = f.fd.steps[k - 1]
		f.form.step = k
		f.tier = float(st.tier)
		f.power = float(st.power)
		SimForms._pick(S, f, 0)   # a branch step passed: the pick, with both fills empty (the first tie's branch)
		return
	var t: int = mini(1 + n, int(SimFighter.topTier(f)))
	f.tier = float(t)
	f.power = float(f.ld.thresholds[t - 2]) if t >= 2 else 0.0


## The borrowed form's price: his wear comes faster until his first region breaks, so it breaks sooner by `sooner`
## (SimWounds.addWear reads it only for a fighter with a boon). 1 otherwise.
static func wearMul(f) -> float:
	if f.boon != "borrowed":
		return 1.0
	for st in f.stage:
		if int(st) >= 3:
			return 1.0
	return 1.0 / (1.0 - sooner)


static func _err(msg: String) -> void:
	_errors.append("fight/boons.json: " + msg)
	if not FighterData.quiet:
		push_error("SimBoons: fight/boons.json: " + msg)
