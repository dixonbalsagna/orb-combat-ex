class_name SimStrikeRead
extends RefCounted
## The strike stick's read (docs/controls/right-hand-attacks.md section 1, re-cut for pitch 4a): one stick, one reader. The stick is a fifth
## "button" with a direction: a push past `on` is a request, it starts `settle` ticks later, the direction is taken then and locked, a stick that
## is back at rest before `dwell` live ticks (the QUICK strike, level 0) throws a quick strike, a stick still out at `dwell` is a charge that grows
## through the data's levels, and the return to rest throws it. Nothing throws by timer, and nothing but the left hand's guard or dodge (cancel())
## can end it early. One instance reads one stick for one slot; the layout owns it and feeds step() once per build.
##
## Pure and engine-agnostic: no Input, no clock. Time comes from the caller: `tick` (the layout's, advances on every build) times the settle and the
## crossing; `live` (the steps the sim took, a hit freeze does not count) times the charge, so a stick held and B held flash on the same step.
## Directions are SCREEN directions (UP 1, DOWN 2, LEFT 3, RIGHT 4); the director turns them into toward and away with the fighter's facing at the
## throw. The sector (0 to 31, 0 is right, counter-clockwise) is the beam's aim and sweep.
##
## The edges (start, release, cancel) are kept until clear_edges(), which the layout calls when a step took the intent, so a press made during a
## freeze is not lost and a flick shorter than the freeze still reports start and release together.

const LEVEL_MAX: int = 3    # the most the reader's `level` (the intent's rsLevel) can be: two bits on the wire, whatever the count of rungs
const NONE: int = 0
const UP: int = 1
const DOWN: int = 2
const LEFT: int = 3
const RIGHT: int = 4

const IDLE: int = 0        # the stick is at rest (or has not been pushed)
const CROSSED: int = 1     # past `on`, waiting for the settle (and for the law's floor)
const ACTIVE: int = 2      # started: the request is in the sim's hands
const SPENT: int = 3       # thrown or cancelled: wait for the stick to rest before the next request
const IGNORED: int = 4     # pushed on an inert layer (pure 4a: RT held, or the lay): the stick does nothing, and holds nothing, until it rests

var phase: int = IDLE
var down: bool = false                 # the stick is past the hysteresis (on until it falls under `off`)
var start: bool = false                # edge: the request began
var release: bool = false              # edge: the strike was thrown (the stick came back, or the toggle's second push)
var cancel: bool = false               # edge: the left hand's guard or dodge ended the charge
var dir: int = NONE                    # locked at the start
var level: int = 0                     # 0 quick, 1 to 3 the charge ladder, at the release; while held, the level reached
var layer: int = 0                     # the stance mask at the crossing tick
var aim: int = 0                       # the stick's sector right now (0 to 31), 0 when at rest
var lag: int = 0                       # ticks the oldest pending edge waited (a freeze held it)

var _cross_tick: int = 0
var _start_tick: int = 0
var _start_live: int = 0
var _peak: Vector2 = Vector2.ZERO
var _peak_r: float = -1.0
var _prev_r: float = 0.0               # last build's deflection: the pre-read follows a rising stick only
var _edge_tick: int = -1
var _rest_seen: bool = false           # toggle style: the stick rested after the start, so the next push throws

# numbers, from data
var dead: float
var quant: float
var on_at: float
var off_at: float
var settle: int
var dwell: int
var ladder: Array
var beam_ladder: Array
var toggle: bool = false               # strike_style "toggle": a push starts the charge, the NEXT push throws it
var pre_at: float                      # the quick read: the pre-read begins at this rescaled deflection (before `on`)
var pre_dir: int = NONE                # the quick read, for the pose only (never in the intent): the quadrant the stick is leaning to, before the request; NONE at rest
var pre_depth: float = 0.0             # ... and how far toward `on` it has got, 0 to 1
var aim_trail: float                   # the beam's aim (switches.beamAim): the radians the shown aim trails the stick before it moves
var aim_latch: int                     # ... the rim ticks the throw's aim is the mean of
var aim_peak: float                    # ... the fraction of the hold's peak deflection that counts as the rim
var _aim_angle: float = 0.0
var _aim_seen: bool = false
var _hold_peak: float = 0.0
var _rim: Array = []                   # the last rim vectors of the hold


func _init() -> void:
	dead = SimInputData.tf(["strike", "deadzone"], 0.25)
	quant = float(SimInputData.ti(["strike", "quant"], 16))
	on_at = SimInputData.tf(["strike", "on"], 0.60)
	off_at = SimInputData.tf(["strike", "off"], 0.35)
	settle = SimInputData.ti(["strike", "settleQuick"], 1) if SimInputData.quick_on() else SimInputData.ti(["strike", "settle"], 2)
	pre_at = SimInputData.tf(["strike", "preAt"], 0.25)
	aim_trail = SimInputData.tf(["strike", "aimTrail"], 4.0) / 180.0 * SimMathx.PI
	aim_latch = maxi(1, SimInputData.ti(["strike", "aimLatchTicks"], 3))
	aim_peak = SimInputData.tf(["strike", "aimLatchPeak"], 0.85)
	dwell = SimInputData.ti(["strike", "dwell"], 12)
	ladder = _ints(SimInputData.t(["strike", "levels"], [12, 30, 50]), [12, 30, 50])
	beam_ladder = _ints(SimInputData.t(["strike", "beamLevels"], [12, 28, 46, 66, 90, 120]), [12, 28, 46, 66, 90, 120])


static func _ints(a, fallback: Array) -> Array:
	if not (a is Array) or a.size() < 3 or a.size() > 6:   # three rungs for the martial ladder, and for a beam up to the six stages of Encounter's charge
		return fallback
	var out: Array = []
	for v in a:
		out.append(int(v))
	return out


## The stick's rescaled, quantised deflection: 0 inside the dead zone, 1 at full, in steps of 1 / quant.
func deflection(x: float, y: float) -> float:
	var m: float = sqrt(x * x + y * y)
	if m <= dead:
		return 0.0
	var r: float = clampf((m - dead) / (1.0 - dead), 0.0, 1.0)
	return roundf(r * quant) / quant


## The screen quadrant of a stick vector (x right, y up), 45 degrees each; a tie goes to the vertical. NONE for a vector in the dead zone.
static func quadrant(x: float, y: float) -> int:
	if x == 0.0 and y == 0.0:
		return NONE
	if absf(y) >= absf(x):
		return UP if y > 0.0 else DOWN
	return RIGHT if x > 0.0 else LEFT


## The sector, 0 to 31, of a stick vector: 0 is right, counter-clockwise, 11.25 degrees each.
static func sector(x: float, y: float) -> int:
	if x == 0.0 and y == 0.0:
		return 0
	var a: float = WorldPlanet.atan2f(y, x)
	if a < 0.0:
		a += SimMathx.TAU
	return int(floor(a / SimMathx.TAU * 32.0 + 0.5)) % 32


## toward or away from a screen direction, given the way he faces (+1 right, -1 left): the director's turn of a locked direction. 0 for none.
## Returns the pieces' names: "up", "down", "toward", "away".
static func relative(d: int, facing: int) -> String:
	match d:
		UP: return "up"
		DOWN: return "down"
		LEFT: return "toward" if facing < 0 else "away"
		RIGHT: return "toward" if facing > 0 else "away"
	return ""


## The ladder level a charge held for `held` live ticks has reached: 0 below the first rung, up to the count of rungs (3, or for a beam up to 6, the director's own reading of a plain charge). A beam or the signature uses its own rungs.
## The reader's `level`, and so the intent's rsLevel, is cut to LEVEL_MAX (3), the width the wire and every reader of rsLevel have.
func level_at(held: int, beam: bool = false) -> int:
	var lad: Array = beam_ladder if beam else ladder
	var n: int = 0
	for rung in lad:
		if held >= int(rung):
			n += 1
	return n


## Whether a stance mask uses the beam rungs: the energy layer's beams and the power layer's signature.
static func is_beam_layer(mask: int) -> bool:
	return (mask & (SimStance.ENERGY | SimStance.CHARGING)) != 0


## One build. (x, y) is the stick (or a digital form's vector); `mask` the stance mask this build; `floor_tick` the earliest tick the request may
## start (the law's reverse lockout after a face press; 0 for none).
func step(x: float, y: float, mask: int, tick: int, live: int, floor_tick: int = 0, pressed: bool = false, inert: bool = false) -> void:
	var r: float = 1.0 if pressed else deflection(x, y)
	var was_down: bool = down
	if not down and r >= on_at:
		down = true
	elif down and r < off_at:
		down = false
	var crossing: bool = down and not was_down
	aim = sector(x, y) if (r > 0.0 and (x != 0.0 or y != 0.0)) else 0
	if SimInputData.beam_aim_on():
		_aim_step(x, y, r, crossing)
	if (phase == IDLE or phase == CROSSED) and r >= pre_at and r >= _prev_r and not inert:   # leaning in, not falling back
		pre_dir = quadrant(x, y)
		pre_depth = minf(1.0, r / on_at)
	else:
		pre_dir = NONE
		pre_depth = 0.0
	_prev_r = r
	match phase:
		IDLE:
			if crossing and inert:
				phase = IGNORED   # the stick is inert on this layer: no request, and the faces stay free
			elif crossing:
				phase = CROSSED
				_cross_tick = tick
				layer = mask
				_peak = Vector2(x, y)
				_peak_r = r
				if settle <= 0:
					_try_start(x, y, tick, live, floor_tick)   # the quick read at settle 0: the direction is taken on the crossing tick itself (docs/controls/responsiveness.md)
		CROSSED:
			if r > _peak_r:
				_peak = Vector2(x, y)
				_peak_r = r
			_try_start(x, y, tick, live, floor_tick)
		ACTIVE:
			var held: int = live - _start_live
			level = mini(level_at(held, is_beam_layer(layer)), LEVEL_MAX)
			if toggle:
				if not down:
					_rest_seen = true
				elif _rest_seen and crossing:
					_throw(tick, live)
			elif not down:
				_throw(tick, live)
		SPENT, IGNORED:
			if not down:
				phase = IDLE
	if phase == IDLE and not down:
		_peak_r = -1.0


## The beam's aim (docs/controls/beam-aim-feel.md). While the stick is down the shown aim follows it through a trailing dead band (it moves only once the stick is
## more than `aim_trail` from it, then stays that far behind), so a thumb that is holding still does not walk the sector; the rim vectors of the hold are kept for the throw.
func _aim_step(x: float, y: float, r: float, crossing: bool) -> void:
	if crossing:
		_rim.clear()
		_hold_peak = 0.0
		_aim_seen = false
	if not down:
		aim = 0
		return
	if r > _hold_peak:
		_hold_peak = r
	if r >= aim_peak * _hold_peak and (x != 0.0 or y != 0.0):
		_rim.append(Vector2(x, y))
		if _rim.size() > aim_latch:
			_rim.pop_front()
	if x == 0.0 and y == 0.0:
		return
	var a: float = WorldPlanet.atan2f(y, x)
	if not _aim_seen:
		_aim_angle = a
		_aim_seen = true
	else:
		var e: float = a - _aim_angle
		if e > SimMathx.PI:
			e -= SimMathx.TAU
		elif e < -SimMathx.PI:
			e += SimMathx.TAU
		if e > aim_trail:
			_aim_angle = a - aim_trail
		elif e < -aim_trail:
			_aim_angle = a + aim_trail
	var t: float = _aim_angle
	while t < 0.0:
		t += SimMathx.TAU
	while t >= SimMathx.TAU:
		t -= SimMathx.TAU
	aim = int(floor(t / SimMathx.TAU * 32.0 + 0.5)) % 32


## The throw's aim: the sector of the mean of the last rim vectors (the thumb's last steady direction), or the peak of a flick that never had a rim.
func _latched_aim() -> int:
	var v: Vector2 = Vector2.ZERO
	for p in _rim:
		v += p
	if v == Vector2.ZERO:
		v = _peak
	if v == Vector2.ZERO:
		return aim
	return sector(v.x, v.y)


func _try_start(x: float, y: float, tick: int, live: int, floor_tick: int) -> void:
	if tick < _cross_tick + settle or tick < floor_tick:
		return
	var v: Vector2 = Vector2(x, y) if down else _peak
	dir = quadrant(v.x, v.y)
	if dir == NONE:
		dir = quadrant(_peak.x, _peak.y)
	_start_tick = tick
	_start_live = live
	start = true
	_mark(tick)
	phase = ACTIVE
	_rest_seen = not down
	level = 0
	if not down and not toggle:
		_throw(tick, live)   # a flick shorter than the settle: it starts and throws together


func _throw(tick: int, live: int) -> void:
	level = mini(level_at(live - _start_live, is_beam_layer(layer)), LEVEL_MAX)
	release = true
	if SimInputData.beam_aim_on():
		aim = _latched_aim()   # the stick has sprung home by the tick it is read: the throw carries the aim it held (docs/controls/beam-aim-feel.md)
	_mark(tick)
	phase = SPENT
	_rest_seen = false
	if not down:
		phase = IDLE


## The left hand's guard or dodge: a charge that has started is lost (no throw); one still waiting to start is dropped. The stick must rest before
## the next request. Returns true if a started strike was cancelled.
func cancel_now(tick: int) -> bool:
	if phase == ACTIVE:
		cancel = true
		_mark(tick)
		phase = SPENT if down else IDLE
		_rest_seen = false
		return true
	if phase == CROSSED:
		phase = SPENT if down else IDLE
	return false


## Whether the strike is in the sim's hands and not yet thrown or cancelled.
func is_active() -> bool:
	return phase == ACTIVE


## Whether the stick is in a request of any kind (the law holds the face buttons from the crossing).
func in_request() -> bool:
	return phase == CROSSED or phase == ACTIVE


## The tick of the crossing of the request in progress.
func cross_tick() -> int:
	return _cross_tick


func _mark(tick: int) -> void:
	if _edge_tick < 0:
		_edge_tick = tick


## How many ticks the oldest pending edge has waited as of `tick` (0 on a live tick), capped at 15 like `waited`.
func pending_lag(tick: int) -> int:
	return clampi(tick - _edge_tick, 0, 15) if _edge_tick >= 0 else 0


func has_edges() -> bool:
	return start or release or cancel


## A step took the intent: the edges are spent.
func clear_edges() -> void:
	start = false
	release = false
	cancel = false
	_edge_tick = -1


## Everything let go: no pending request, no held direction.
func reset() -> void:
	phase = IDLE
	down = false
	dir = NONE
	level = 0
	aim = 0
	pre_dir = NONE
	pre_depth = 0.0
	_prev_r = 0.0
	_peak_r = -1.0
	_rest_seen = false
	_rim.clear()
	_hold_peak = 0.0
	_aim_seen = false
	clear_edges()
