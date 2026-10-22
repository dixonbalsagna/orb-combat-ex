class_name SimRicochet
extends RefCounted
## The ricochet's glance (Game Design's fight-feel.md section 3; rulings-2026-10-22.md 2b; docs/architecture/ricochet-core.md).
## Behind data/fight/ricochet.json (off): with it off, every match, replay and checkpoint is the same to the bit.
##
## A sent body meeting a surface that holds, at `line` units a second or more into it (the speed along its normal, the
## traversal factor divided out) and under `maxAngle` to it, glances: it keeps `keep` of its speed, angle in equal to
## angle out, and flies on. Below the line it is Combat's plant (Encounter's, which tells it here too); steeper, the
## wall slam, the lodge or the chain, as before. At most `maxInRow` ricochets in a row (glances and plants together, for
## one send): then the next surface is a plain contact.
## Where: World's contact meets the ground, a slope or a cliff (WorldContact._land, a granted branch) and a building's
## face (WorldBrunt.checkHit, a granted call to offFace). rule() is the classification in a surface's frame, shared by
## them, by World's journey predictor and by predict() for the choreographer. told() counts, hands the curve's paced leg
## over (his velocity takes the speed he showed) and sends the `ricochet` event that Encounter and Camera read.

const FILE: String = "res://data/fight/ricochet.json"
const HASHED: Array = ["rics", "ricN"]
const NONE: int = 0      # not a ricochet: steeper than maxAngle, moving away, or the row is full
const GLANCE: int = 1
const BELOW: int = 2     # under the line: Combat's plant (Encounter's)

static var _d = null
static var _hash: String = ""
static var _errors: Array = []
static var on_: bool = false
static var line: float = 1500.0
static var maxAngle: float = 40.0
static var keep: float = 0.7
static var maxInRow: int = 2
static var sin2Max: float = 0.413   # derived: sin^2(maxAngle)


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	var h := SimHash.Hasher.new()
	var j = FighterData._load(FILE, "fight/ricochet.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary):
		_err("missing, or not an object")
		_d = {}
		_hash = h.hex()
		return
	_d = j
	h.text("fight/ricochet.json")
	FighterData._canon(h, j)
	_hash = h.hex()
	if not (j.get("enabled") is bool):
		_err("enabled must be true or false")
	on_ = j.get("enabled") == true
	line = _num("line", j.get("line"), 0.0, 100000.0)
	maxAngle = _num("maxAngle", j.get("maxAngle"), 1.0, 89.0)
	keep = _num("keep", j.get("keep"), 0.0, 1.0)
	var n = j.get("maxInRow")
	if not (n is float or n is int) or float(n) != floor(float(n)) or int(n) < 0 or int(n) > 16:
		_err("maxInRow: a whole number from 0 to 16")
		n = 0
	maxInRow = int(n)
	var sn: float = SimDetMath.sin(maxAngle * SimMathx.f64("400921fb54442d18") / 180.0)   # the sim's own sine and pi (the same bits on every platform)
	sin2Max = sn * sn


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


## The rule in a surface's frame (normalised units): vn the speed along its outward normal (negative: into it), vt along
## it; inRow the ricochets so far in this row. [GLANCE, vn', vt'] for a glance (keep of the speed, angle in equal to angle
## out); [BELOW, vn, vt] under the line (Combat's plant); [NONE, vn, vt] otherwise (steeper than maxAngle at or over the
## line, moving away, or the row is full). Every caller's classification, live and predicted.
static func rule(vn: float, vt: float, inRow: int) -> PackedFloat64Array:
	_ensure()
	var into: float = -vn
	if into <= 0.0 or inRow >= maxInRow:
		return PackedFloat64Array([float(NONE), vn, vt])
	if into < line:
		return PackedFloat64Array([float(BELOW), vn, vt])
	if into * into >= sin2Max * (vn * vn + vt * vt):
		return PackedFloat64Array([float(NONE), vn, vt])
	return PackedFloat64Array([float(GLANCE), -keep * vn, keep * vt])


## For the choreographer: a contact at velocity (vx, vy) (normalised: the traversal factor divided out) with a surface
## whose outward unit normal is (nx, ny), after inRow ricochets. [kind, vx', vy'] (kind as in rule; the velocity after a
## glance, else the same). The ground's normal at slope s is (-s, 1) / sqrt(1 + s^2); a building's face toward +x is (1, 0).
static func predict(vx: float, vy: float, nx: float, ny: float, inRow: int = 0) -> PackedFloat64Array:
	var r: PackedFloat64Array = rule(vx * nx + vy * ny, vx * ny - vy * nx, inRow)
	return PackedFloat64Array([r[0], r[1] * nx + r[2] * ny, r[1] * ny - r[2] * nx])


## The ricochets so far in his current send's row (0 for a new send). World's contact reads it into its body.
static func inRow(f) -> int:
	return int(f.rics) if int(f.ricN) == int(f.launchN) else 0


## A ricochet told, after the surface changed his velocity (World's contact for the ground, offFace for a building's
## face; Encounter's plant): the row's count; the curve's paced leg handed over (his velocity takes the speed he showed,
## as at the brake); the event. kind glance or plant; surface what he met (ground's surface name, building).
static func told(S: SimState, f, kind: String, surface: String, x: float, y: float) -> void:
	if int(f.ricN) != int(f.launchN):
		f.ricN = f.launchN
		f.rics = 0
	f.rics += 1
	if S.flightOn and f.flt != null and f.flt.on:
		f.vx *= f.flt.k
		f.vy *= f.flt.k
		SimFlight.endLeg(S, f, kind)
	var vxo: float = f.vx / f.launchT
	var sp: float = SimDetMath.hypot(vxo, f.vy)
	SimFx.ricochet(S, f, kind, surface, x, y, vxo / sp if sp > 0.0 else 0.0, f.vy / sp if sp > 0.0 else 0.0, sp, int(f.rics))


## A building's face (World's WorldBrunt.checkHit and its swept test, before the hit): a glance off it, if it is one. The
## face is level-normal, back toward where he came from (dir his heading). True when he glanced: his velocity reflected
## at keep, he stands just outside the face at yc, no longer aimed at it, and it is told. False: World's hit as before.
static func offFace(S: SimState, f, b, yc: float, edge: float, dir: float) -> bool:
	var tv: float = f.launchT
	var r: PackedFloat64Array = predict(f.vx / tv, f.vy, -dir, 0.0, inRow(f))
	if int(r[0]) != GLANCE:
		return false
	f.vx = r[1] * tv
	f.vy = r[2]
	f.x = SimWrap.wrap(edge - dir)
	f.y = yc
	f.aimB = -1
	told(S, f, "glance", "building", f.x, f.y)
	return true


static func _num(where: String, x, lo: float, hi: float) -> float:
	if not (x is float or x is int) or float(x) < lo or float(x) > hi:
		_err(where + ": a number from %s to %s" % [str(lo), str(hi)])
		return lo
	return float(x)


static func _err(msg: String) -> void:
	_errors.append("fight/ricochet.json: " + msg)
	if not FighterData.quiet:
		push_error("SimRicochet: fight/ricochet.json: " + msg)
