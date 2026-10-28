class_name NetBot
extends RefCounted
## A scripted player for the rollback harness: one seeded stream per slot, asked for its intent tick by tick in order, so
## the same (seed, slot) gives the same inputs to a peer, to the other peer's view of it and to a straight replay. It
## holds sticks, guard, sprint, power and the legacy dash and charge for runs of ticks (a prediction gets those right) and
## presses attacks, dodges, stances and specials on single ticks (a prediction gets each of those wrong), at about the
## rates of golden_recipes.gd's scripted human, with the v2 stance mask too. Not a fighter AI: it does not read the state.

var r: SimRng
var mx: float = 0.0
var my: float = 0.0
var dash: bool = false
var charge: bool = false
var guard: bool = false
var sprint: bool = false
var power: bool = false
var mode: int = -1
var stanceMask: int = 0
var tick: int = 0   # the next tick it answers for

const STEER: Array = [-1.0, 0.0, 1.0]
const MASKS: Array = [0, 1, 2, 4, 8]


func _init(seed: int, slot: int) -> void:
	r = SimRng.new(SimRng.deriveSeed(seed & 0xFFFFFFFF, "netbot%d" % slot))


## The packed intent for the next tick.
func next() -> int:
	tick += 1
	if r.next() < 0.05:
		mx = STEER[int(floor(r.next() * 3.0))]
	if r.next() < 0.05:
		my = STEER[int(floor(r.next() * 3.0))]
	if r.next() < 0.02:
		dash = not dash
	if r.next() < 0.01:
		charge = not charge
	if r.next() < 0.02:
		guard = not guard
	if r.next() < 0.02:
		sprint = not sprint
	if r.next() < 0.015:
		power = not power
	if r.next() < 0.01:
		mode = int(floor(r.next() * 3.0)) - 1
	if r.next() < 0.004:
		stanceMask = MASKS[int(floor(r.next() * 5.0))]
	var i := SimIntent.new()
	i.mx = mx
	i.my = my
	i.dash = dash
	i.charge = charge
	i.guard = guard
	i.sprint = sprint
	i.power = power
	i.mode = mode
	i.stanceMask = stanceMask
	i.light = r.next() < 0.03
	i.heavy = r.next() < 0.015
	i.sig = r.next() < 0.008
	i.lightHeld = i.light or (r.next() < 0.02)
	i.stance = floor(r.next() * 4.0) if r.next() < 0.004 else -1.0
	i.guardPress = r.next() < 0.02
	i.dodge = r.next() < 0.02
	i.powerPress = r.next() < 0.01
	i.powerTap = r.next() < 0.01
	i.upgrade = (1 + int(floor(r.next() * 2.0))) if r.next() < 0.01 else 0
	i.special = (1 + int(floor(r.next() * 7.0))) if r.next() < 0.005 else 0
	i.context = r.next() < 0.01
	i.transform = r.next() < 0.002
	i.escape = r.next() < 0.003
	return SimIntent.pack(i)
