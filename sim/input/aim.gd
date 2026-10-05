class_name SimAim
extends RefCounted
## The stick as an aim (docs/controls/agency-input.md 1b): the 8-sector snap and the latch of the stick's launch direction,
## for the fight alchemist (the recipe's pool, the launch's direction, a juggle's return blow). Pure functions over plain
## data: no state of its own, no engine, no clock, no RNG, and no trig (comparisons and multiplications only), so a replay and
## a peer read the same sector from the same intent. The latch is a small Dictionary the director keeps per fighter
## ({sector, tick}, two integers, hashed with the rest of its state).
##
## Sectors are screen-absolute, counter-clockwise from the right, as flight is steered (stick right flies right):
##   0 right, 1 up-right, 2 up, 3 up-left, 4 left, 5 down-left, 6 down, 7 down-right, and NONE (-1) inside the dead zone.
## `my` is up, as in the intent. A keyboard has only these eight directions; the stick is quantised to the same eight, so
## neither device is at an advantage, and the director snaps the sector to a real target (`snap`), so the tilt never has to
## be exact. All numbers are data (timing.json, the `aim` block).

const NONE: int = -1
const RIGHT: int = 0
const UP_RIGHT: int = 1
const UP: int = 2
const UP_LEFT: int = 3
const LEFT: int = 4
const DOWN_LEFT: int = 5
const DOWN: int = 6
const DOWN_RIGHT: int = 7

## tan(22.5 degrees), sqrt(2) - 1, as a float64 from its bit pattern (the sim's long-literal rule): a direction is on an axis
## while its minor component is below this fraction of its major one.
static func tan_22_5() -> float:
	return SimMathx.f64("3fda827999fcef33")

## The unit step of each sector, x then y: (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1).
const STEP_X: Array = [1, 1, 0, -1, -1, -1, 0, 1]
const STEP_Y: Array = [0, 1, 1, 1, 0, -1, -1, -1]

const DEFAULTS: Dictionary = {
	"deadZone": 0.35,     # the stick must pass this fraction of full deflection to aim (the move dead zone is 0.2)
	"latchTicks": 12,     # the latest aim within this many ticks of the launch decision still counts
	"snapMax": 1,         # the director snaps to a target within this many sectors (1 is 45 degrees)
}


## The numbers, from data over the defaults.
static func params() -> Dictionary:
	var p: Dictionary = DEFAULTS.duplicate()
	p["deadZone"] = SimInputData.tf(["aim", "deadZone"], float(DEFAULTS["deadZone"]))
	p["latchTicks"] = SimInputData.ti(["aim", "latchTicks"], int(DEFAULTS["latchTicks"]))
	p["snapMax"] = SimInputData.ti(["aim", "snapMax"], int(DEFAULTS["snapMax"]))
	return p


## The sector of a stick position: NONE inside the dead zone (a circle of radius `deadZone`), else 0 to 7. A direction within
## 22.5 degrees of an axis is that axis; the rest are the diagonals. Exact on the boundary: an angle of exactly 22.5 degrees
## reads as the diagonal.
static func sector(mx: float, my: float, dead_zone: float = -1.0) -> int:
	var dz: float = dead_zone if dead_zone >= 0.0 else float(params()["deadZone"])
	if mx * mx + my * my <= dz * dz:
		return NONE
	var ax: float = absf(mx)
	var ay: float = absf(my)
	var t: float = tan_22_5()
	if ay < ax * t:
		return RIGHT if mx > 0.0 else LEFT
	if ax < ay * t:
		return UP if my > 0.0 else DOWN
	if mx > 0.0:
		return UP_RIGHT if my > 0.0 else DOWN_RIGHT
	return UP_LEFT if my > 0.0 else DOWN_LEFT


## The sector an intent's stick is in.
static func of_intent(i: SimIntent, dead_zone: float = -1.0) -> int:
	return sector(i.mx, i.my, dead_zone)


## The unit step (x, y) of a sector as integers, (0, 0) for NONE. y is up.
static func step_x(s: int) -> int:
	return int(STEP_X[s]) if s >= 0 and s < 8 else 0


static func step_y(s: int) -> int:
	return int(STEP_Y[s]) if s >= 0 and s < 8 else 0


## A fresh latch: nothing aimed.
static func new_latch() -> Dictionary:
	return {"sector": NONE, "tick": -1000000}


## Feed the stick once a tick: a sample beyond the dead zone becomes the latch (the newest wins); a sample inside it changes
## nothing, so releasing the stick as the last button goes down keeps the aim. Returns the latch (mutated in place).
static func update(latch: Dictionary, mx: float, my: float, tick: int, opts: Dictionary = {}) -> Dictionary:
	var s: int = sector(mx, my, float(opts.get("deadZone", -1.0)))
	if s != NONE:
		latch["sector"] = s
		latch["tick"] = tick
	return latch


## The aim at the launch decision on `tick`: the latched sector if it is at most `latchTicks` old, else NONE.
static func read(latch: Dictionary, tick: int, opts: Dictionary = {}) -> int:
	var n: int = int(opts.get("latchTicks", params()["latchTicks"]))
	if int(latch["sector"]) != NONE and tick - int(latch["tick"]) <= n:
		return int(latch["sector"])
	return NONE


## Forget the aim (a new exchange, or the launch has used it).
static func clear(latch: Dictionary) -> void:
	latch["sector"] = NONE
	latch["tick"] = -1000000


## How many sectors apart two sectors are, 0 to 4 (a half turn is 4). NONE is not near anything: 99.
static func distance(a: int, b: int) -> int:
	if a < 0 or b < 0:
		return 99
	var d: int = absi(a - b) % 8
	return mini(d, 8 - d)


## The director's snap: of `candidates` (sectors a real target or launch lies in, listed most dramatic first), the index of the
## one nearest `aim` within `snapMax` sectors, the earlier one on a tie; -1 if there is no aim or none is near enough. With
## no aim the director picks freely, as agency-pass.md says.
static func snap(aim: int, candidates: Array, opts: Dictionary = {}) -> int:
	if aim < 0:
		return -1
	var max_d: int = int(opts.get("snapMax", params()["snapMax"]))
	var best: int = -1
	var best_d: int = 99
	for k in range(candidates.size()):
		var d: int = distance(aim, int(candidates[k]))
		if d <= max_d and d < best_d:
			best = k
			best_d = d
	return best


## The pool the stick picks relative to the rival: "toward" (the horizontal part points at him), "away", or "level" (straight
## up or down, or no aim). `opp_sign` is +1 when the rival is to the right on the shortest arc, -1 to the left
## (`jsign(sdx(f.x, opp.x))`). A diagonal counts by its horizontal part.
static func pool(aim: int, opp_sign: int) -> String:
	var sx: int = step_x(aim) * (1 if opp_sign >= 0 else -1)
	if sx > 0:
		return "toward"
	if sx < 0:
		return "away"
	return "level"


# ---------------------------------------------------------------------------------------------------------------------------
# The zip's exit (docs/controls/lunge-control.md B6.2; Game Design, melee-press-feel.md 2c). The stick is read on the tick his blow
# lands: the direction held for at least `dwellTicks` of the last `exitWindow` ticks, as a VECTOR on the stick's own 1/127 grid, and the
# bearing and the angle off straight away are worked out from it to ONE DEGREE. Sixteen sectors (22.5 degrees) are for classifying and
# for what the HUD shows; they are too coarse for the distance (1.5 bh a step), for the bearing at the 12.5 bh cap (4.9 bh between
# spots) and for the zip away's 45-degree cone, whose edge falls inside a sector. No trig at run time: a 181-entry cosine table in whole
# degrees, built once from SimDetMath.cos, and a binary search.

const RING_SIZE: int = 12   # the window, in ticks: the ring holds this many samples

static var _cos_table: Array = []


## Sixteen sectors of 22.5 degrees, counter-clockwise from the right: 0 right, 4 up, 8 left, 12 down; NONE (-1) inside the dead zone.
## Comparisons and multiplications only. The 8-sector `sector` is the even ones of these (sector16 = 2 * sector for the axes and
## diagonals).
static func sector16(mx: float, my: float, dead_zone: float = -1.0) -> int:
	var dz: float = dead_zone if dead_zone >= 0.0 else float(params()["deadZone"])
	if mx * mx + my * my <= dz * dz:
		return NONE
	var ax: float = absf(mx)
	var ay: float = absf(my)
	var k: int = 4   # the offset from the horizontal axis in 22.5-degree steps: 0 on it, 4 straight up or down
	if ay < ax * SimMathx.f64("3fc975f5e0553158"):        # tan 11.25
		k = 0
	elif ay < ax * SimMathx.f64("3fe561b82ab7f990"):      # tan 33.75
		k = 1
	elif ay < ax * SimMathx.f64("3ff7f218e25a7461"):      # tan 56.25
		k = 2
	elif ay < ax * SimMathx.f64("40141bfee242476f"):      # tan 78.75
		k = 3
	if mx > 0.0 and my >= 0.0:
		return k
	if mx <= 0.0 and my > 0.0:
		return 8 - k
	if mx < 0.0 and my <= 0.0:
		return 8 + k
	return (16 - k) % 16


static func _cos_deg() -> Array:
	if _cos_table.is_empty():
		var deg: float = SimMathx.f64("3f91df46a2529d39")   # pi / 180
		for k in range(181):
			_cos_table.append(SimDetMath.cos(float(k) * deg))
	return _cos_table


## The angle in whole degrees (0 to 180) between a stick vector and a reference direction: the largest degree whose cosine is still at
## least the cosine between them. (0, 0) in either is 0.
static func angle_between_deg(mx: float, my: float, rx: float, ry: float) -> int:
	var lv: float = SimDetMath.hypot(mx, my)
	var lr: float = SimDetMath.hypot(rx, ry)
	if lv <= 0.0 or lr <= 0.0:
		return 0
	var c: float = clampf((mx * rx + my * ry) / (lv * lr), -1.0, 1.0)
	var tab: Array = _cos_deg()
	var lo: int = 0
	var hi: int = 180
	while lo < hi:   # the cosine falls as the angle rises: find the last degree with cos >= c
		var mid: int = (lo + hi + 1) / 2
		if float(tab[mid]) >= c:
			lo = mid
		else:
			hi = mid - 1
	return lo


## The stick's bearing around the rival, in whole degrees counter-clockwise from the right, 0 to 359, y up (stick up is 90, left 180).
static func bearing_deg(mx: float, my: float) -> int:
	if mx == 0.0 and my == 0.0:
		return 0
	var phi: int = angle_between_deg(mx, my, 1.0, 0.0)
	return phi if my >= 0.0 else (360 - phi) % 360


## The angle, in whole degrees (0 to 180), between the stick and straight away from the rival. `away_sign` is +1 when the zipper
## started on the rival's right (so straight away is to the right on screen), -1 on his left.
static func angle_off_away_deg(mx: float, my: float, away_sign: int) -> int:
	return angle_between_deg(mx, my, 1.0 if away_sign >= 0 else -1.0, 0.0)


## Game Design's exit distance, in the units of `start` (body heights): the start distance plus `extra` (6 bh) times (1 - the angle
## off straight away over 90 degrees), never less than the start distance and never more than `cap` (12.5 bh). A stick square to his
## line or past it (90 degrees or more) adds nothing.
static func exit_distance(start: float, angle_off_away: int, extra: float = 6.0, cap: float = 12.5) -> float:
	var a: float = float(mini(angle_off_away, 90))
	var d: float = start + extra * (1.0 - a / 90.0)
	return maxf(start, minf(d, cap))


## Whether the stick is within `cone` degrees of straight away, inclusive (the zip away from inside the close band: 45).
static func within_away_cone(mx: float, my: float, away_sign: int, cone: int = 45) -> bool:
	if SimAim.sector16(mx, my) == NONE:
		return false
	return angle_off_away_deg(mx, my, away_sign) <= cone


## A fresh sample ring: 1 + 3 * RING_SIZE integers, [head, (sector + 1, x, y) per slot]. Flat, so a director can keep it in its own
## integer state and hash it. The sector is stored plus 1 so 0 means no sample (inside the dead zone, or never filled).
static func new_ring() -> Array:
	var r: Array = []
	r.resize(1 + 3 * RING_SIZE)
	r.fill(0)
	return r


## Feed the stick once a tick (live ticks): the sector (or none) and the vector on the 1/127 grid, into the ring.
static func push_sample(ring: Array, mx: float, my: float, dead_zone: float = -1.0) -> void:
	var h: int = int(ring[0])
	var s: int = sector16(mx, my, dead_zone)
	var o: int = 1 + 3 * h
	if s == NONE:
		ring[o] = 0
		ring[o + 1] = 0
		ring[o + 2] = 0
	else:
		ring[o] = s + 1
		ring[o + 1] = clampi(roundi(mx * 127.0), -127, 127)
		ring[o + 2] = clampi(roundi(my * 127.0), -127, 127)
	ring[0] = (h + 1) % RING_SIZE


## The exit read on the tick his blow lands: the sector held for at least `dwellTicks` of the last `exitWindow` (12) ticks, the most
## ticks winning and the newer sector a tie; the vector is the mean of that sector's samples, on the 1/127 grid. Returns
## {sector, x, y, count}; sector is NONE (-1) if nothing was held long enough: the zip goes back to where it began. `x` and `y` give
## `bearing_deg` and `angle_off_away_deg` (divide by 127.0 or pass as they are: both are scale-free).
static func read_exit(ring: Array, opts: Dictionary = {}) -> Dictionary:
	var dwell: int = int(opts.get("dwellTicks", SimInputData.ti(["aim", "dwellTicks"], 3)))
	var window: int = mini(int(opts.get("exitWindow", SimInputData.ti(["aim", "exitWindow"], RING_SIZE))), RING_SIZE)
	var head: int = int(ring[0])
	var counts: Dictionary = {}
	var sums: Dictionary = {}
	var newest: Dictionary = {}   # sector -> the age (0 is the latest sample) of its newest sample
	for age in range(window):
		var idx: int = ((head - 1 - age) % RING_SIZE + RING_SIZE) % RING_SIZE
		var o: int = 1 + 3 * idx
		var s: int = int(ring[o]) - 1
		if s < 0:
			continue
		counts[s] = int(counts.get(s, 0)) + 1
		var sm: Array = sums.get(s, [0, 0])
		sm[0] = int(sm[0]) + int(ring[o + 1])
		sm[1] = int(sm[1]) + int(ring[o + 2])
		sums[s] = sm
		if not newest.has(s):
			newest[s] = age
	var best: int = NONE
	for s in counts:
		if int(counts[s]) < dwell:
			continue
		if best == NONE or int(counts[s]) > int(counts[best]) or (int(counts[s]) == int(counts[best]) and int(newest[s]) < int(newest[best])):
			best = int(s)
	if best == NONE:
		return {"sector": NONE, "x": 0, "y": 0, "count": 0}
	var n: float = float(counts[best])
	return {"sector": best, "x": roundi(float(sums[best][0]) / n), "y": roundi(float(sums[best][1]) / n), "count": int(counts[best])}
