class_name DirPace
extends RefCounted
## Easy matches the player's pace (ai.json levels.<level>.brawl.paceMatch, off; Game Design, docs/design/gauntlet-plan.md section 6; the EP's
## overnight brief item 2, from Encounter's control audit; Orb's order of 2026-11-08: "adaptive to what the player is trying to do"). At a
## level with paceMatch on, the gap between the computer's taps in a brawl string is never shorter than the player's recent gap between attack
## presses: the median of his last windowSec seconds of face presses and stick strikes (guards don't count), kept between floor and ceiling.
## With fewer than two presses in that time it's ceiling, so the computer never goes passive. Against another computer, noHuman. It changes
## when the computer throws, never what its blows are worth. State: his last RING attack-press ticks after DirRefuse's on f.act.dirI,
## written only for a player, and only while the level has it on (off, nothing is sized or written).

const RING: int = 8        # the last attack presses kept (a masher's 8 span about a second: the median is his)
const PC_I: int = 0        # the next ring slot to write
const PC_T: int = 1        # RING slots: an attack press's tick, plus 1; 0 empty
const PC_N: int = 1 + RING


static func _b() -> int:
	return DirRefuse._b() + DirRefuse.RF_N


static func _g(f, k: int) -> int:
	var i: int = _b() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + PC_N:
		f.act.dirI.resize(_b() + PC_N)
	f.act.dirI[_b() + k] = v


static func cfg() -> Dictionary:
	return DirAI.lv().get("brawl", {}).get("paceMatch", {})


static func on() -> bool:
	return bool(cfg().get("enabled", false))


## Each live tick (DirExchange._update): a player's attack press of this tick goes into his ring.
static func note(S: SimState) -> void:
	if not on():
		return
	for f in S.fighters:
		if f.ai != null or f.input == null:
			continue
		var i = f.input
		if not (i.light or i.heavy or i.sig or i.rsStart):
			continue
		var k: int = _g(f, PC_I)
		_s(f, PC_T + k, S.tick + 1)
		_s(f, PC_I, (k + 1) % RING)


## His recent gap: the median of the gaps between his attack presses in the last windowSec seconds; -1 with fewer than two.
static func recentGap(S: SimState, f, windowSec: float) -> int:
	var w: int = int(windowSec * float(DirData.TICKS_PER_SEC))
	var ts: Array = []
	for k in range(RING):
		var t: int = _g(f, PC_T + k) - 1
		if t >= 0 and S.tick - t <= w:
			ts.append(t)
	if ts.size() < 2:
		return -1
	ts.sort()
	var gaps: Array = []
	for k in range(1, ts.size()):
		gaps.append(int(ts[k]) - int(ts[k - 1]))
	gaps.sort()
	return int(gaps[gaps.size() / 2])


## The tap gap of the computer's string against o: g as drawn, or o's recent gap if that's longer, kept between floor and ceiling (ceiling
## with too few presses to read); noHuman against another computer. At a level with paceMatch off, g.
static func gap(S: SimState, o, g: int, bl: Dictionary) -> int:
	var mp: Dictionary = bl.get("paceMatch", {})
	if not bool(mp.get("enabled", false)) or o == null:
		return g
	if o.ai != null:
		return maxi(g, int(mp.get("noHuman", 27)))
	var lo: int = int(mp.get("floor", 12))
	var hi: int = int(mp.get("ceiling", 30))
	var r: int = recentGap(S, o, float(mp.get("windowSec", 3.0)))
	return maxi(g, hi if r < 0 else clampi(r, lo, hi))
