class_name SimLeftHand
extends RefCounted
## The left hand's two upgrades (docs/controls/right-hand-attacks.md section 2, rules 4a): the BRACE and the VANISH. Both are read from the left stick
## and the two left shoulders, so no right-hand input is ever part of a defence (K5), and there is no claw question on the left hand at all. The slip
## (LT tap and a left flick) needs nothing here: the dodge edge and the stick already carry it (R34).
##
##   BRACE   LB down and a quick flick from rest. A pad: the stick sat at rest `braceRest` ticks, and rose past `on` within `braceRise` ticks of leaving
##           rest (a lean is slower and sets nothing); the direction is taken `settle` ticks after the crossing and the read goes out then. A
##           keyboard (digital stick): a TAP of a direction key, down and up inside `braceTap` ticks with LB down; the read goes out on the release.
##           One at a time: the stick must come back to rest before the next.
##   VANISH  LB and LT pressed within `vanishWindow` ticks of each other, either order, both still down when it resolves: an UPGRADE of the dodge, so
##           the dodge's press-tick start is untouched. It resolves at the later of (first press + window) and (second press + `vanishSettle`), with the
##           stick's strongest direction over the gather; the layout sends `escape` with that stick vector. A neutral stick sends a zero vector (the sim
##           goes away). LT pressed more than `vanishWindow` after LB is the ordinary dodge out of guard.
##
## Pure: no engine, no clock. The layout feeds step() once per build.

const NONE: int = 0

var flick_on: bool = true         # the flick read of the brace (the assist brace_style "press" turns it off; the brace BUTTON is the layout's)
var brace: bool = false          # edge: set a read
var brace_dir: int = 0           # screen direction, SimStrikeRead.UP.. RIGHT
var vanish: bool = false         # edge: the vanish resolved
var vanish_vec: Vector2 = Vector2.ZERO

# numbers, from data
var rest_ticks: int
var rise_ticks: int
var tap_ticks: int
var rest_level: float
var on_at: float
var off_at: float
var window: int
var v_settle: int
var settle: int

var _rest_run: int = 0
var _armed: bool = false         # left rest and rising: a brace may complete
var _onset: int = 0
var _crossed: bool = false
var _cross_tick: int = 0
var _peak: Vector2 = Vector2.ZERO
var _peak_m: float = 0.0
var _spent: bool = false         # a read went out: wait for rest
var _tap_t0: int = -1
var _t_guard: int = -1000000     # press ticks of the two left shoulders
var _t_dodge: int = -1000000
var _gather: bool = false
var _g_first: int = 0
var _g_second: int = 0
var _g_peak: Vector2 = Vector2.ZERO
var _g_peak_m: float = 0.0
var _hist: Array = []            # [tick, stick] for the last few ticks: a flick that began before the second press is still the gather's direction


func _init() -> void:
	rest_ticks = SimInputData.ti(["leftHand", "braceRest"], 10)
	rise_ticks = SimInputData.ti(["leftHand", "braceRise"], 3)
	tap_ticks = SimInputData.ti(["leftHand", "braceTap"], 8)
	rest_level = SimInputData.tf(["leftHand", "restLevel"], 0.2)
	window = SimInputData.ti(["leftHand", "vanishWindow"], SimInputData.ti(["tapHold", "chordWindow"], 6))
	v_settle = SimInputData.ti(["leftHand", "vanishSettle"], 2)
	settle = SimInputData.ti(["strike", "settle"], 2)
	on_at = SimInputData.tf(["strike", "on"], 0.60)
	off_at = SimInputData.tf(["strike", "off"], 0.35)


## One build. (x, y) is the left stick (or the move keys as -1, 0, 1); `digital` says it is keys. `guard_down` and `dodge_down` are the shoulders as
## held (a toggled hold counts); `guard_press` and `dodge_press` their press edges this build.
func step(x: float, y: float, digital: bool, guard_down: bool, dodge_down: bool, guard_press: bool, dodge_press: bool, tick: int) -> void:
	brace = false
	vanish = false
	brace_dir = NONE
	vanish_vec = Vector2.ZERO
	var m: float = sqrt(x * x + y * y)
	if flick_on:
		if digital:
			_digital_brace(x, y, m, guard_down, tick)
		else:
			_pad_brace(x, y, m, guard_down, tick)
	_vanish(x, y, m, guard_down, dodge_down, guard_press, dodge_press, tick)


func _pad_brace(x: float, y: float, m: float, guard_down: bool, tick: int) -> void:
	if m < rest_level:
		_rest_run += 1
		_armed = false
		_crossed = false
		_peak_m = 0.0
		if _spent and m < off_at:
			_spent = false
		return
	var was_rest: int = _rest_run
	_rest_run = 0
	if _spent:
		return
	if not _armed and not _crossed and was_rest >= rest_ticks:
		_armed = true
		_onset = tick
	if _armed and not _crossed:
		if m >= on_at and tick - _onset <= rise_ticks:
			_crossed = true
			_cross_tick = tick
			_peak = Vector2(x, y)
			_peak_m = m
		elif tick - _onset > rise_ticks:
			_armed = false   # a lean, not a flick
	if _crossed:
		if m > _peak_m:
			_peak = Vector2(x, y)
			_peak_m = m
		if tick >= _cross_tick + settle:
			if guard_down:
				var v: Vector2 = Vector2(x, y) if m >= off_at else _peak
				var d: int = SimStrikeRead.quadrant(v.x, v.y)
				if d != NONE:
					brace = true
					brace_dir = d
			_spent = true
			_crossed = false
			_armed = false


func _digital_brace(x: float, y: float, m: float, guard_down: bool, tick: int) -> void:
	if m > 0.0:
		if _tap_t0 < 0:
			_tap_t0 = tick
			_peak = Vector2(x, y)
		return
	if _tap_t0 >= 0:
		var held: int = tick - _tap_t0
		_tap_t0 = -1
		if guard_down and held <= tap_ticks:
			var d: int = SimStrikeRead.quadrant(_peak.x, _peak.y)
			if d != NONE:
				brace = true
				brace_dir = d


func _vanish(x: float, y: float, m: float, guard_down: bool, dodge_down: bool, guard_press: bool, dodge_press: bool, tick: int) -> void:
	_hist.append([tick, Vector2(x, y)])
	while _hist.size() > 0 and tick - int(_hist[0][0]) > 16:
		_hist.pop_front()
	if guard_press:
		_t_guard = tick
	if dodge_press:
		_t_dodge = tick
	if not _gather and (guard_press or dodge_press) and guard_down and dodge_down and absi(_t_guard - _t_dodge) <= window:
		_gather = true
		_g_first = mini(_t_guard, _t_dodge)
		_g_second = maxi(_t_guard, _t_dodge)
		_g_peak = Vector2.ZERO
		_g_peak_m = 0.0
		for h in _hist:
			var hv: Vector2 = h[1]
			var hm: float = hv.length()
			if int(h[0]) >= _g_first and hm > _g_peak_m and hm >= off_at:
				_g_peak = hv
				_g_peak_m = hm
	if not _gather:
		return
	if m > _g_peak_m and m >= off_at:
		_g_peak = Vector2(x, y)
		_g_peak_m = m
	if not (guard_down and dodge_down):
		_gather = false   # one of them was let go before it resolved: a dodge and a guard, no vanish
		return
	if tick >= maxi(_g_first + window, _g_second + v_settle):
		vanish = true
		vanish_vec = _g_peak
		_gather = false
		_t_guard = -1000000
		_t_dodge = -1000000


func reset() -> void:
	brace = false
	vanish = false
	_rest_run = 0
	_armed = false
	_crossed = false
	_spent = false
	_tap_t0 = -1
	_gather = false
	_hist.clear()
	_t_guard = -1000000
	_t_dodge = -1000000
