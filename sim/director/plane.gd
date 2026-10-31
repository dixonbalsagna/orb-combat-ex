class_name DirPlane
## Back to the plane (Game Design's rulings-2026-10-30f.md row 9, option A). With depth off, a flight aimed at a building
## still moves a fighter in depth (WorldBrunt.stepZ), and nothing brought him back: his blows then landed across the gap,
## with towers between. Here he eases back after every flight, depth.json planeEasePerTick units a tick on average,
## eased in and out, so a gap of 1,200 takes 60 ticks and 300 takes 15. Never a snap.
##  - It starts when the flight ends. A burial, a hold or a set piece delays it until he is let go, and it starts again
##    from where he is.
##  - An attacker's close takes him to his target's depth over the close's own ticks: a rush homes on it and arrives at
##    it. In an exchange, the two locked, the one nearer the plane follows the other in at the closing step's limit, and
##    the one further out eases home, so the gap closes from both ends and then they come back together.
##  - A face in the way is passed through, with no damage and no slowing (depth.md section 2: a drift never damages a building).
## With depth on (S.depthOn) or the number at 0 nothing here runs and no slot is sized. Depth is in the state and the
## hash already; the two slots are the director's integers, sized when a fighter is first off the plane.

const PATH: String = "res://data/combat/depth.json"
const PL_T: int = 0     # live ticks into this ease, 0 when none is running
const PL_Z0: int = 1    # the depth it started from, x 1024
const PL_N: int = 2

static var _rate: float = -1.0
static var _text: String = ""


static func _ensure() -> void:
	if _rate >= 0.0:
		return
	_text = FileAccess.get_file_as_string(PATH)
	var j = JSON.parse_string(_text)
	_rate = maxf(0.0, float(j.get("planeEasePerTick", 0.0))) if j is Dictionary else 0.0


## The number: units a tick on average, 0 for off. Tools may set it (setRate).
static func rate() -> float:
	_ensure()
	return _rate


static func setRate(v: float) -> void:
	_ensure()
	_rate = v


## The data file's text, for DirData.dataHash() (the replay header), once the number is on.
static func dataText() -> String:
	_ensure()
	return _text


static func _base() -> int:
	return DirLaunch._hkBase() + DirLaunch.HK_N


static func _sized(f) -> bool:
	return f.act.dirI.size() >= _base() + PL_N


static func _size(f) -> void:
	DirLaunch._hkSize(f)
	if not _sized(f):
		f.act.dirI.resize(_base() + PL_N)


static func _stop(f) -> void:
	if _sized(f):
		f.act.dirI[_base() + PL_T] = 0


## True while he is held where he is: buried, in a hold, or in a set piece (a signature, a finisher, a burial's follow-up,
## a brawl's break launch).
static func _held(S: SimState, f, ex) -> bool:
	if S.game.ko != null or DirBury.buried(f) or DirGrapple.holds(f):
		return true
	if ex == null or (f != ex.A and f != ex.D):
		return false
	if ex.kind == "sig" or ex.tpl == "finisher" or ex.branch == "finisher" or ex.tpl == DirBury.TPL or DirExchange.finisherPlanned(ex):
		return true
	return DirBrawl.isBrawl(ex) and DirBrawl._setPiece(ex)


## One tick of his ease home. The curve is a function of the start and the tick, so nothing drifts.
static func _ease(f) -> void:
	_size(f)
	var b: int = _base()
	if f.act.dirI[b + PL_T] == 0:
		f.act.dirI[b + PL_Z0] = int(round(f.z * 1024.0))
	var z0: float = float(f.act.dirI[b + PL_Z0]) / 1024.0
	var n: int = maxi(1, int(ceil(absf(z0) / rate())))
	var t: int = f.act.dirI[b + PL_T] + 1
	if t >= n:
		f.z = 0.0
		f.act.dirI[b + PL_T] = 0
		return
	var p: float = float(t) / float(n)
	f.z = z0 * (1.0 - p * p * (3.0 - 2.0 * p))
	f.act.dirI[b + PL_T] = t


## Of the two locked in ex, the one who eases home; the other follows him in. The one further from the plane; level, the
## one already easing, and then the first slot, so the choice can't flip back and forth as they come in together.
static func _leader(S: SimState, a, b):
	if absf(a.z) != absf(b.z):
		return a if absf(a.z) > absf(b.z) else b
	if _sized(b) and b.act.dirI[_base() + PL_T] > 0 and not (_sized(a) and a.act.dirI[_base() + PL_T] > 0):
		return b
	return a if S.fighters.find(a) < S.fighters.find(b) else b


## Once a live tick, last in the director's update.
static func tick(S: SimState, dt: float) -> void:
	if S.depthOn or dt <= 0.0 or rate() <= 0.0:
		return
	var ex = S.dirS.ex
	var pair: bool = ex != null and ex.A.state == "locked" and ex.D.state == "locked" and ex.A != ex.D
	var lead = _leader(S, ex.A, ex.D) if pair else null
	if lead != null and not _held(S, lead, ex) and lead.z != 0.0:
		_ease(lead)
	elif lead != null and _held(S, lead, ex):
		_stop(lead)
	for f in S.fighters:
		if f == lead:
			continue
		if pair and (f == ex.A or f == ex.D):
			if _held(S, f, ex):
				_stop(f)
			elif f.z != lead.z:
				_stop(f)
				var step: float = float(DirBrawl.cfg().give.closeMaxBh) * DirInterrupt.BH
				f.z = lead.z if absf(lead.z - f.z) <= step else f.z + step * signf(lead.z - f.z)
			continue
		if f.state == "launched":
			_stop(f)
		elif f.rush != null and f.rush.tgt != null:
			_stop(f)
			var rem: float = f.rush.end - S.T - dt   # the core lands the rush on the tick this reaches 0, before this runs
			f.z += (float(f.rush.tgt.z) - f.z) * minf(1.0, dt / maxf(rem, dt))
		elif _held(S, f, ex):
			_stop(f)
		elif f.z != 0.0:
			_ease(f)
