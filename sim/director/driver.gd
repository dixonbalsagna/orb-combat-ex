class_name DirDriver
extends RefCounted
## RB + B, the Driver (docs/design/pad-first-press.md; docs/design/energy-overhaul.md E124 to E127). B with the energy family held gathers: a
## tap is a straight, heavy shot, and held it steps through three levels and goes when it's let go. Level 3 is a full send and breaks a guard.
## It never fires by itself: held at level 3 it costs ki a second, and it's lost when that runs out. A dodge or a guard press drops it for
## nothing. Built from the charged shot: DirBlast.hit decides what meeting him means, and this says what it does then. A player's only: the
## AI's signature is as it was. Off, no slot is sized.

const D_AT: int = 0     # the tick it began, plus 1; 0 none
const D_LV: int = 1     # the level it's reached
const D_SHOT: int = 2   # the id of his last Driver shot
const D_SHOTLV: int = 3 # ... and its level
const D_N: int = 4

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirBlast.data().get("driver", {})


static func on() -> bool:
	return bool(cfg().get("enabled", false)) if _force < 0 else _force == 1


static func _b() -> int:
	return DirFollow._b() + DirFollow.F_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + D_N:
		f.act.dirI.resize(_b() + D_N)
	f.act.dirI[_b() + k] = v


## A press of B with the energy family held. True when it's the Driver's.
static func takes(S: SimState, f, kind: String) -> bool:
	if not on() or kind != "sig" or f.ai != null or (int(f.input.stanceMask) & DirStick.RB) == 0 or S.game.ko != null or DirStick.firing:
		return false
	if _g(f, D_AT) != 0:
		return true
	var ex = S.dirS.ex
	if ex != null and ex.kind == "sig":
		return false   # a beam's on its way: it's the answer, as it was
	if (f.state != "free" and f.state != "charging") or f.stunTicks > 0:
		SimFx.cue(S, f, "driver_refused", "", "")
		return true
	if ex != null:
		if not DirBrawl.isBrawl(ex) or ex.branch != "" or DirBrawl._setPiece(ex):
			SimFx.cue(S, f, "driver_refused", "", "")
			return true
		DirBrawl.end(S, ex, "signature")   # the brawl gives way, as it does for a signature
	if f.ki < float(cfg().ki[0]):
		SimFx.cue(S, f, "driver_refused", "ki", "")
		return true
	DirBands.endTaunt(S, f, false, "cut")
	f.state = "free"
	_s(f, D_AT, S.tick + 1)
	_s(f, D_LV, 0)
	SimFx.cue(S, f, "driver_charge", "", "")
	return true


static func _drop(S: SimState, f, why: String) -> void:
	_s(f, D_AT, 0)
	SimFx.cue(S, f, "driver_drop", why, "")


## Once a live tick.
static func tick(S: SimState) -> void:
	if not on():
		return
	for f in S.fighters:
		if _g(f, D_AT) == 0:
			continue
		var i = f.input
		var c: Dictionary = cfg()
		if S.game.ko != null or (f.state != "free" and f.state != "charging") or f.stunTicks > 0 or S.dirS.ex != null:
			_drop(S, f, "taken")
			continue
		if i.dodge or i.guardPress:
			_drop(S, f, "dropped")
			continue
		var n: int = S.tick - (_g(f, D_AT) - 1)
		var lv: int = _g(f, D_LV)
		var levels: Array = c.levels
		if lv < levels.size() and n >= int(levels[lv]) and f.ki >= float(c.ki[lv + 1]):
			lv += 1
			_s(f, D_LV, lv)
			SimFx.cue(S, f, "charge_full" if lv == levels.size() else "charge_stage", str(lv), "")
		if not i.sigHeld:
			_fire(S, f, lv)
			continue
		if lv == levels.size():
			f.ki -= float(c.loadedKiPerSec) * SimConst.DT   # Loaded: a threat he carries, and it costs
			if f.ki < float(c.ki[lv]):
				_drop(S, f, "spent")


static func _fire(S: SimState, f, lv: int) -> void:
	var c: Dictionary = cfg()
	_s(f, D_AT, 0)
	var o = SimRoster.opp(S, f)
	f.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(f.x, o.x)), f.face)
	var sh = SimShots.fire(S, S.fighters.find(f), String(c.kind), {"target": S.fighters.find(o), "power": float(c.power[lv]), "dmg": float(SimShots.kinds[String(c.kind)].dmg) * DirBrawl.shotScale() * float(c.dmgMul[lv])})
	if sh == null:
		return
	f.ki -= float(c.ki[lv])
	_s(f, D_SHOT, sh.id)
	_s(f, D_SHOTLV, lv)
	DirInterrupt.si(f, DirInterrupt.BLAST_AT, S.tick)
	SimFx.cue(S, f, "driver_fire", str(lv), "")
	SimEvents.feed(S, f.name + " DRIVER", "level " + str(lv))


## The level of this shot, if it's a Driver's: -1 if not.
static func levelOf(by, sh) -> int:
	if not on() or by == null or _g(by, D_SHOT) != sh.id:
		return -1
	return _g(by, D_SHOTLV)


## A level that breaks a guard (DirBlast.hit).
static func breaks(by, sh) -> bool:
	return levelOf(by, sh) >= int(cfg().breakAt)


## What a Driver's shot does when it's met him clean, outside an exchange, on a fighter who's up. True when it was a Driver's.
static func landed(S: SimState, sh, by, f, outcome: String, brink0: bool) -> bool:
	var lv: int = levelOf(by, sh)
	if lv < 0:
		return false
	var c: Dictionary = cfg()
	if S.game.ko != null or S.dirS.ex != null or (outcome != "hit" and outcome != "stop") or (f.state != "free" and f.state != "charging"):
		return true
	if DirBands.pending(f):
		DirBands.drop(S, f, "a Driver knocked him back")
	if lv >= int(c.sendAt):
		var force: float = SimPower.sendForce(S, by, float(c.sendForce), "driverLevel3")
		DirLaunch.doLaunch(S, by, f, DirLaunch.chooseLaunch(S, by, f, force, false, "", 0, true).best, force)   # never the knock-back: it's a full send
		SimEvents.feed(S, "DRIVER: A FULL SEND", by.name + " sends " + f.name + ": decisive")
	else:
		DirLaunch.knock(S, by, f, float(c.knockMul[lv]))
		SimEvents.feed(S, "DRIVER: KNOCK BACK", f.name + " is knocked back: decisive")
	DirExchange.decisiveShot(S, by, f, -sh.id, brink0)
	return true
