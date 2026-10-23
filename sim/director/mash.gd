class_name DirMash
## A mash's later blows flow (Game Design's rulings-2026-10-22.md 6 (b); Simulation's light_flow, docs/architecture/feel-core.md
## section 7). A mash is a run of one fighter's mashed or burst blows (a brawl blow that names light_mash: a flurry's, a held
## pace's, a burst's), each within mash.flowGapTicks (12) live ticks of his last; it starts again after that many without
## one. Its first blow keeps light_mash (2 ticks); each later one names light_flow, which Simulation's table holds for no
## stop and the budget's floor never raises. Every other blow keeps its table stop.
## Only while hit-stop by weight is on (S.hitstopOn): off, nothing is written and the slot is never sized, so the golden
## doesn't move. State: one f.act.dirI slot, the first after the grapple's (the press wait's follows it).

const MS_AT: int = 0   # the live tick of his last mashed or burst blow, plus 1; 0 none
const MS_N: int = 1


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("mash", {})


static func _base() -> int:
	return DirGrapple.END   # the chain's front: this block and the press wait's are written with every switch off, so no later block's slots move them


static func _g(f, k: int) -> int:
	var i: int = _base() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirGrapple._size(f)
	if f.act.dirI.size() < _base() + MS_N:
		f.act.dirI.resize(_base() + MS_N)
	f.act.dirI[_base() + k] = v


## The weight a brawl blow of f's names (DirBrawl's strike, after weightOf): a mash's later blow light_flow, else w as it
## is. Each mashed or burst blow marks the run's clock.
static func name(S: SimState, f, w: String) -> String:
	if not S.hitstopOn or w != "light_mash":
		return w
	var now: int = DirBrawl._now(S)
	var last: int = _g(f, MS_AT) - 1
	_s(f, MS_AT, now + 1)
	if last >= 0 and now - last <= int(cfg().get("flowGapTicks", 12)):
		return "light_flow"
	return w
