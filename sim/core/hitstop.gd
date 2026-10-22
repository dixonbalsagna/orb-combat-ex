class_name SimHitstop
extends RefCounted
## Hit-stop by weight, with a freeze budget (Game Design's rulings-2026-10-19b.md section 4a and 4b, fight-feel.md
## section 6; Research's cinematic-storytelling.md recommendation 10; docs/architecture/feel-core.md). Behind
## data/fight/hitstop.json (off): with it off, every hit holds the clock as today, to the bit.
##
## With it on:
##   a hit names its weight (the hit's o.weight: light_mash, light, medium, heavy, launch, launch_full, decisive), and
##                its stop is the table's ticks for it, in place of the stop the director passed. A hit that names none
##                keeps the stop it passed, so each director moment moves to the table when its owner names it.
##   the core's own two: a hit that breaks a region holds `decisive` at least, and the KO (SimDamage.ko, the one place
##                a match ends) holds `ko`, the cap.
##   hold(S, weight): any other moment of the director's (a launch's send, a perfect's duel), merged the same way.
##   the budget:  the frozen ticks of the last windowS (10) seconds of fight (live seconds, in buckets) are counted,
##                whatever froze them. Over `share` (18%) of it, every stop under a decisive blow is x cutMul (0.75,
##                rounded, at least cutFloor 2) until the share falls back under (Game Design's rulings-2026-10-22.md
##                5b). Decisive blows and the KO are never cut. Stops merge (the longer one holds); they never add.
##   whole ticks: a stop of n ticks freezes n. The step counts a stop down in seconds, and 1/60 taken n times from n/60
##                leaves about 1e-17 for n of 3 or more, a tick more than asked; frozen() drops that residue. With the
##                switch off, today's count stands.
## Both bodies freeze, as every hit-stop does (the whole sim holds). The struck one's shake is Animation's.

const FILE: String = "res://data/fight/hitstop.json"
const WEIGHTS: Array = ["light_mash", "light", "medium", "heavy", "launch", "launch_full", "decisive", "ko"]
const NEVER_CUT: Array = ["decisive", "ko"]
const RESIDUE: float = 1.0e-9   # seconds: far under a tick, far over the count-down's float residue

static var _d = null
static var _hash: String = ""
static var _errors: Array = []
static var on_: bool = false
static var ticks_: Dictionary = {}
static var cutMul: float = 0.75
static var cutFloor: int = 2
static var windowS: int = 10
static var budgetTicks: int = 108   # derived: share x windowS seconds of ticks


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	ticks_ = {}
	var h := SimHash.Hasher.new()
	var j = FighterData._load(FILE, "fight/hitstop.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary):
		_err("missing, or not an object")
		_d = {}
		_hash = h.hex()
		return
	_d = j
	h.text("fight/hitstop.json")
	FighterData._canon(h, j)
	_hash = h.hex()
	if not (j.get("enabled") is bool):
		_err("enabled must be true or false")
	on_ = j.get("enabled") == true
	var t = j.get("ticks", {})
	if not (t is Dictionary):
		_err("ticks must be an object")
		t = {}
	for w in WEIGHTS:
		ticks_[w] = _int("ticks." + w, t.get(w), 0, 120)
	if ticks_.ko < ticks_.decisive:
		_err("ticks.ko is the cap: at least ticks.decisive")
	var cm = j.get("cutMul")
	if not (cm is float or cm is int) or float(cm) <= 0.0 or float(cm) > 1.0:
		_err("cutMul: a share above 0, at most 1")
		cm = 1.0
	cutMul = float(cm)
	cutFloor = _int("cutFloor", j.get("cutFloor"), 0, 120)
	var b = j.get("budget", {})
	if not (b is Dictionary):
		_err("budget must be an object")
		b = {}
	windowS = _int("budget.windowS", b.get("windowS"), 1, 600)
	var share: float = 0.0
	var sh = b.get("share")
	if not (sh is float or sh is int) or float(sh) <= 0.0 or float(sh) > 1.0:
		_err("budget.share: a share above 0, at most 1")
	else:
		share = float(sh)
	budgetTicks = int(SimMathx.jround(share * float(windowS) / SimConst.DT))


static func enabled() -> bool:
	_ensure()
	return on_


static func dataHash() -> String:
	_ensure()
	return _hash


static func errors() -> Array:
	_ensure()
	return _errors


## Tests only: read the file again on the next call.
static func reload() -> void:
	_d = null


## The budget's state for a new match (SimCore.newMatch), while hit-stop by weight is on.
static func setup(S: SimState) -> void:
	_ensure()
	S.hs = null
	if S.hitstopOn:
		S.hs = SimState.StopState.new()
		S.hs.sec.resize(windowS)
		S.hs.sec.fill(0)


## The frozen ticks of the last windowS seconds of fight are over the budget.
static func over(S: SimState) -> bool:
	return S.hs.sum >= budgetTicks


## The table's ticks for a weight, after the budget: over it, a stop under a decisive blow is x cutMul (rounded, at
## least cutFloor). -1 for a weight not in it.
static func ticks(S: SimState, weight: String) -> int:
	_ensure()
	if not ticks_.has(weight):
		return -1
	var n: int = int(ticks_[weight])
	if over(S) and not NEVER_CUT.has(weight):
		n = maxi(cutFloor, int(SimMathx.jround(float(n) * cutMul)))
	return n


## A hit's stop in seconds (SimDamage.hit): the table's for the weight it names, else the one the director passed.
static func forHit(S: SimState, o, passed: float) -> float:
	var w = o.get("weight") if o is Dictionary else null
	var n: int = ticks(S, String(w)) if w is String else -1
	return float(n) * SimConst.DT if n >= 0 else passed


## Any other moment's hold (the director's: a launch's send, a perfect's duel), merged with the stop in force.
static func hold(S: SimState, weight: String) -> void:
	var n: int = ticks(S, weight)
	if n > 0:
		S.dirS.stop = SimMathx.jmax(S.dirS.stop, float(n) * SimConst.DT)


## After a hit's damage (SimDamage.hit): a blow that breaks a region holds decisive. stage0 is the struck fighter's
## stages before the hit. (The KO's cap is held in SimDamage.ko, the one place a match ends.)
static func afterHit(S: SimState, D, stage0: Array) -> void:
	for r in range(stage0.size()):
		if int(stage0[r]) < 3 and int(D.stage[r]) >= 3:
			hold(S, "decisive")
			return


## Each frozen tick of a hit-stop (SimCore.step, after the count-down): counted in this second's bucket; and the
## count-down's float residue dropped, so a stop of n ticks freezes n.
static func frozen(S: SimState) -> void:
	if S.dirS.stop < RESIDUE:
		S.dirS.stop = 0.0
	var h = S.hs
	h.sec[h.i] = int(h.sec[h.i]) + 1
	h.sum += 1


## Each live tick (SimCore.step): the window is windowS live seconds; the oldest second's frozen ticks leave it.
static func live(S: SimState) -> void:
	var h = S.hs
	h.n += 1
	if h.n >= int(SimMathx.jround(1.0 / SimConst.DT)):
		h.n = 0
		h.i = (h.i + 1) % h.sec.size()
		h.sum -= int(h.sec[h.i])
		h.sec[h.i] = 0


static func _int(where: String, x, lo: int, hi: int) -> int:
	if not (x is float or x is int) or float(x) != floor(float(x)) or int(x) < lo or int(x) > hi:
		_err(where + ": a whole number from %d to %d" % [lo, hi])
		return lo
	return int(x)


static func _err(msg: String) -> void:
	_errors.append("fight/hitstop.json: " + msg)
	if not FighterData.quiet:
		push_error("SimHitstop: fight/hitstop.json: " + msg)
