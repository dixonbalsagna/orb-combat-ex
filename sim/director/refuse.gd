class_name DirRefuse
extends RefCounted
## Every press answered (docs/controls/refusals.md; the EP, 2026-11-07, from Tools' ledger of Orb's save on a8bc66e2): a press the director
## lets go of with nothing happening is told, with why, once a burst. A burst is presses let go of no more than press.refusedBurstTicks
## apart (2: the same press held on, tick after tick); each press of a mash is its own, and is told. Said through DirExchange.refused, so it needs
## press.refusedCue, and never the computer's. State: one integer after DirBeamMove's on f.act.dirI, written only for a player.

const RF_LAST: int = 0   # the tick of the last press let go of, plus 1; 0 none
const RF_N: int = 1


static func _b() -> int:
	return DirBeamMove._b() + DirBeamMove.M_N


static func _g(f, k: int) -> int:
	var i: int = _b() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + RF_N:
		f.act.dirI.resize(_b() + RF_N)
	f.act.dirI[_b() + k] = v


## A press let go of: told with this code unless it's in the burst of the last one.
static func burst(S: SimState, f, code: String) -> void:
	if f == null or f.ai != null or not bool(DirExchange.pressCfg().get("refusedCue", false)):
		return
	var last: int = _g(f, RF_LAST)
	_s(f, RF_LAST, S.tick + 1)
	if last > 0 and S.tick - (last - 1) <= int(DirExchange.pressCfg().get("refusedBurstTicks", 2)):
		return
	DirExchange.refused(S, f, code)
