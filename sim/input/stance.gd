class_name SimStance
extends RefCounted
## The stances as a mask (docs/controls/lunge-control.md A2): one bit per shoulder button, resolved by the layout from what is
## held, so the intent, the replay and the AI carry one number and the sim looks the stance up in a table. Pure functions: no
## state, no engine, no clock.
##
##   LB 1 defensive, RB 2 energy, RT 4 charging, LT 8 manoeuvre; 0 is the martial arts stance.
##
## Rules (ruled 2026-10-04): a stance is EXCLUSIVE until hybrids exist. With RT down the set is RT alone (RT dominates). Otherwise
## a held set that is not an enabled hybrid reports only its newest bit. A hybrid is a set listed in data/input/stances.json
## (LT+RB 10, LB+RB 3, LT+LB 9); until one is listed, holding its two buttons reads as the newer of the two. The transform chord
## (LT+RT) changes no stance while it is pending: its two bits are left out of the set before the rules run.

const MARTIAL: int = 0
const DEFENSIVE: int = 1   # LB
const ENERGY: int = 2      # RB
const CHARGING: int = 4    # RT
const MANOEUVRE: int = 8   # LT
const HYBRID_EVASIVE: int = 10   # LT + RB
const HYBRID_WARD: int = 3       # LB + RB
const HYBRID_TERRAIN: int = 9    # LT + LB
const BITS: Array = [1, 2, 4, 8]


## The enabled hybrid masks, from data/input/stances.json (none until Game Design ships one).
static func hybrids() -> Array:
	return SimInputData.hybrids()


## The stance mask for a set of held stance buttons. `on` is the set (bits), `newest` the bit that went on last among them.
static func resolve(on: int, newest: int, enabled: Array = []) -> int:
	if on & CHARGING != 0:
		return CHARGING
	if on == 0:
		return MARTIAL
	if popcount(on) == 1:
		return on
	if enabled.has(on):
		return on
	return newest if (newest & on) != 0 else _lowest(on)


static func popcount(m: int) -> int:
	var n: int = 0
	for b in BITS:
		if m & b != 0:
			n += 1
	return n


static func _lowest(m: int) -> int:
	for b in BITS:
		if m & b != 0:
			return b
	return 0


## The bit that went on last: `since` maps a bit to the tick it went on; the later tick wins and a tie goes to the higher bit.
static func newest_of(on: int, since: Dictionary) -> int:
	var best: int = 0
	var best_t: int = -1073741824
	for b in BITS:
		if on & b != 0:
			var t: int = int(since.get(b, 0))
			if t >= best_t:
				best_t = t
				best = b
	return best


## A name for a mask, for feeds and tests.
static func label(mask: int) -> String:
	match mask:
		0: return "martial"
		1: return "defensive"
		2: return "energy"
		4: return "charging"
		8: return "manoeuvre"
		10: return "evasive energy"
		3: return "defensive ki"
		9: return "terrain while flying"
	return "stance %d" % mask
