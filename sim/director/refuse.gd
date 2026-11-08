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


## Every press answered: the power press and the transform (Tools' corrected ledger of Orb's 1229 play: 7 of 8 power presses and all 3
## transforms had no answer). Each live tick, after the director's own (DirExchange._update), for a player's press of this tick:
##   the power press   a burst it fired is told (power_burst); a charge it began is told (power_start); held (locked, launched, down,
##                     stunned) it's refused with why. Free with nothing to say, nothing: a knock where none is due would be worse
##   the transform     one that didn't transform is refused: not_ready with no form ready, else with what holds him
## Through press.refusedCue, never the computer's.
static func presses(S: SimState) -> void:
	if not bool(DirExchange.pressCfg().get("refusedCue", false)):
		return
	for f in S.fighters:
		if f.ai != null or f.input == null:
			continue
		var i = f.input
		if i.powerPress:
			if f.act.burstFired:
				SimFx.cue(S, f, "power_burst", "", "")   # his burst went: that's its answer
			elif f.state == "charging" or i.charge:
				SimFx.cue(S, f, "power_start", "", "")   # his charge begins
			else:
				var why: String = DirExchange.cantWhy(S, f)
				if why != "busy":
					DirExchange.refused(S, f, why)
		if i.transform and not _transformed(S, f):
			var why2: String = "not_ready" if not f.act.formReady else DirExchange.cantWhy(S, f)
			if why2 != "busy":
				DirExchange.refused(S, f, why2)


## He transformed on this tick (SimFx.transform's event).
static func _transformed(S: SimState, f) -> bool:
	var slot: int = S.fighters.find(f)
	for e in S.out.fx:
		if String(e.type) == "transform" and int(e.actor) == slot:
			return true
	return false
