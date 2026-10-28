class_name DirRally
## The daze, the sell and the rally (Game Design's rulings-2026-10-23d, Orb's answer to the early B; its §8 for each
## fighter's own links). Behind data/director/interrupts.json rally.enabled (false: nothing runs, no slot is written, no
## cue is sent). With it on, the chase, the recoil flips and the wall kick are on too (they are its links and answers).
##  - The daze (items 1 to 3, item 1 as amended by 10-26 item 8): an earned stun of daze.ticks (40) live ticks, from a
##    broken guard, a perfect block that turns a heavy, a charged blow or an ender (the one perfect-blocked), a wall slam
##    (once he is up), a clean fully charged heavy, or a heavy's whiff punished by a medium, a heavy or a perfect
##    follow-up (never a light). He can't strike or guard. Each press of his takes daze.shave (3) ticks off, at most one
##    every daze.shaveEvery (6), so the fastest thumb cuts it by about a third; RT's burst breaks it after
##    daze.burstAfter (12), at the burst's price. After a rally ends on him he is wary for waryTicks (120): a daze source
##    on him is the plain stagger then. Cue "daze": start (source the why), shave, end.
##  - The sell (4, 5; 10-26 §2c): a landed medium at a dazed fighter holds the sell.weight hit-stop ("launch") with a
##    "sell" cue; the damage is the blow's own; lights aren't sold. B at a dazed fighter is the sure launcher at full
##    power, a decisive send that opens the rally, sold. The AI sells its level's rally.sells mediums first (10-26 item
##    10), and presses B with sell.bLeftTicks (8) of the daze left at least.
##  - The attacker is free after each send (10-26 item 7): its contact and hit-stop end the exchange for him, and a link
##    press made while he is still held by it waits (RL_Q) and starts on his first free tick, within link.queueTicks.
##  - The rally (6 to 11): any full send opens one. Its links, each the attacker's press while the body flies, through
##    DirChase: the chase strike, the overtake (the stick back against the flight), the spike (B from above him), and the
##    fighters' own links this build has: the Protagonist's Palm Turn (the stick across the flight: the body turned 90°)
##    and the Rival's Plate Chase (the chase with Y: sent exactly along the stick's eight-way line, with no bend). The
##    stick's class is read once, at the chase's commit (Controls' rule), and only on a deliberate lean (read.leanMin).
##  - Repetition (8, 17): at a link's arrival he techs with a guard press within tech.fresh (4) ticks for a kind not used
##    yet in the rally, tech.earlier (6) for one used before but not last, tech.repeat (8) for the same as the last; the
##    autoAt-th (3rd) of one kind is teched by itself. A teched link ends his journey in the air with the recoil flip's
##    counter-rush; landing it on the chaser in the air is a full send of him, and the rally is the other's (the turn).
##  - The ends (11): he lands and no link follows within endTicks (20), "ki" when the attacker is short of the next
##    link's price then (10-26 item 40), else "landed"; a teched link isn't turned within the
##    counter-rush's ticks; his burst in flight (after a link's first burstAfter ticks); a KO. Each link's send carries
##    power 1 for its journey's pay, so the rally's last landing pays by 9a.
##  - The choreographer (13, Combat's data/director/rally.json): the planner's candidates in a rally score its
##    destination terms and the world link's; the AI picks its link by the kind terms, its own links' lift and noise.
## Not in this build: the bank and Mantle Wall (a face the chaser or her mantle gives), the energy links, the grabs in
## flight (Net Haul, Ring Hold, Banner Drop, Crane Reel), the traps (Pillar Lift, Rope Return), Wreck Toss, Slag Catch,
## Stair Spike, the spike's glance, the bury and the lost struggle as daze sources, the meets.
## Cues (Camera's names): "sell" (actor the attacker, target the dazed, amount 1 or 2); "rally_link" (text the base kind, or
## "send" for the opening, source the own link, n its index, k 1 sold); "rally_tech" (text the base kind, k 1 by itself);
## "rally_turn" (actor the new attacker, target the new body); "rally_end" (text the reason, n links, k turns, dur).
## State: f.act.dirI slots after the water's (sized only when the switch is on).

const RL_ON: int = 0       # the rally he owns: his victim's slot plus 1; 0 none
const RL_AT: int = 1       # the live tick it opened, plus 1
const RL_LINKS: int = 2    # its links so far
const RL_K1: int = 3       # the last link's kind (kinds() index plus 1)
const RL_KC: int = 4       # the links of each kind, 4 bits a kind
const RL_D1: int = 5       # the last send's destination (destinations index plus 1)
const RL_D2: int = 6       # ... and the one before it
const RL_DM: int = 7       # the destinations used in this rally, a bit each
const RL_LAND: int = 8     # the live tick his victim came out of flight, plus 1; 0 in flight
const RL_TECH: int = 9     # the live tick a link of his was teched, plus 1; 0 none
const RL_TURNS: int = 10   # the times the rally has changed hands
const RL_SOLD: int = 11    # 1 when it opened out of a daze
const RL_LA: int = 12      # the live tick of the rally's last send, plus 1 (a link's first ticks)
const RL_STC: int = 13     # the chase's stick class, read at its commit: 1 back, 2 across; 0 neither
const RL_STD: int = 14     # ... and its eight-way way (the launch planner's tilt, 1 up then clockwise); 0 neutral
const WR_UNTIL: int = 15   # the live tick until which he is wary (a rally ended on him); 0 none
const DZ_UNTIL: int = 16   # the live tick his daze ends; 0 not dazed
const DZ_AT: int = 17      # the live tick it began, plus 1
const DZ_SH: int = 18      # the live tick of his last shave, plus 1
const DZ_PEND: int = 19    # 1 when a wall slam dazes him once he is up
const DZ_WHIFF: int = 20   # the live tick until which a blow on him punishes his heavy's whiff, plus 1
const RL_GP: int = 21      # the live tick of his last guard press, plus 1 (his tech at a link's arrival)
const RL_CRUSH: int = 22   # the live tick his counter-rush was spent, plus 1 (the turn)
const RL_AIB: int = 23     # the AI: 1 it will burst out of this daze, 2 it burst out of a link in flight
const DZ_SOLD: int = 24    # the mediums sold in his daze so far (10-26 item 10: the AI sells before B)
const RL_Q: int = 25       # a link press made while he was still held by his send: its kind (1 X, 2 Y, 3 B) + 4 x (the live tick + 1); 0 none
const RL_WL: int = 26      # the send (its RL_LA) whose world link is counted: one a send (10-26 item 22a)
const RL_N: int = 27
const OWN: Array = ["palm_turn", "plate_chase"]   # the fighters' own links this build has (their fighters: rally.own)


static func cfg() -> Dictionary:
	var d: Dictionary = DirInterrupt.data()
	if not is_same(d, _cfgOf):
		_cfg = d.get("rally", {})   # the same block every time for the same data (tools edit it in place)
		_cfgOf = d
	return _cfg


static var _cfg: Dictionary = {}
static var _cfgOf = null


const SCORING_PATH: String = "res://data/director/rally.json"
static var _sc = null
## Combat's scoring (data/director/rally.json, director.rally/1), read once.
static func scoring() -> Dictionary:
	if _sc == null:
		var j = JSON.parse_string(FileAccess.get_file_as_string(SCORING_PATH))
		if not (j is Dictionary):
			push_error("DirRally: could not parse " + SCORING_PATH)
			j = {}
		_sc = j
	return _sc


static func on() -> bool:
	return DirInterrupt.on() and bool(cfg().get("enabled", false))


## The link kinds: Combat's base kinds, then the own links this build has (each its own kind: 23d item 17).
static func kinds() -> Array:
	var k: Array = (scoring().get("kinds", []) as Array).duplicate()
	for o in OWN:
		if not k.has(o):
			k.append(o)
	return k


static func _base() -> int:
	if _baseAt < 0:
		_baseAt = DirWater._base() + DirWater.WT_N
	return _baseAt   # a constant: the chain is walked once


static var _baseAt: int = -1


static func _g(f, k: int) -> int:
	var i: int = _base() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	var b: int = _base()
	if f.act.dirI.size() < b + RL_N:   # sized: every part before this one is (it follows DirGrapple.END)
		DirGrapple._size(f)
		if f.act.dirI.size() < b + RL_N:
			f.act.dirI.resize(b + RL_N)
	f.act.dirI[b + k] = v


static func _ai() -> Dictionary:
	return DirAI.lv().get("rally", {})


static func _now(S: SimState) -> int:
	return DirBrawl._now(S)


static func _cue(S: SimState, f, kind: String, text: String, src: String = ""):
	SimFx.cue(S, f, kind, text, src)
	return S.out.fx[S.out.fx.size() - 1]


# ---------------------------------------------------------------- the daze

## True while f is dazed.
static func dazed(S: SimState, f) -> bool:
	return on() and _g(f, DZ_UNTIL) > _now(S) and f.stunTicks > 0


## f dazes o (why: the source). False when it doesn't (off, or o is wary): the caller's stagger stands then.
static func daze(S: SimState, ex, f, o, why: String) -> bool:
	if not on() or o == null or _now(S) < _g(o, WR_UNTIL):
		return false
	var c: Dictionary = cfg().get("daze", {})
	var n: int = int(c.get("ticks", 40))
	var now: int = _now(S)
	o.stunTicks = maxi(o.stunTicks, n)
	_s(o, DZ_UNTIL, now + n)
	_s(o, DZ_AT, now + 1)
	_s(o, DZ_SH, 0)
	_s(o, DZ_PEND, 0)
	_s(o, DZ_WHIFF, 0)
	_s(o, RL_AIB, 0)
	_s(o, DZ_SOLD, 0)
	if ex != null and DirBrawl.isBrawl(ex) and (o == ex.A or o == ex.D):
		DirBrawl._drop(S, ex, o)   # his blow on its way is lost
		if f != null and (f == ex.A or f == ex.D):
			DirBrawl._lcOpen(S, ex, f, o, n, "daze")   # an opening: B at him is the sure launcher
	if o.ai != null and SimRng.keyed(int(S.game.seed), "rally.dazeBurst", S.tick * 4 + S.fighters.find(o)) < float(_ai().get("dazeBurst", 0.0)):
		_s(o, RL_AIB, 1)
	var e = _cue(S, o, "daze", "start", why)
	e.target = float(S.fighters.find(f)) if f != null else -1.0
	e.n = S.tick + n
	SimEvents.feed(S, o.name + " IS DAZED", why + ": " + str(n) + " ticks, his presses shave it")
	return true


## A wall slam (DirWallKick.atWall, when he didn't kick): he is dazed once he is up again.
static func slammed(S: SimState, f) -> void:
	if on() and _now(S) >= _g(f, WR_UNTIL):
		_s(f, DZ_PEND, 1)


## A heavy of f's met nothing and left him open for `open` live ticks (DirBrawl._miss): a blow on him in it dazes.
static func whiffed(S: SimState, f, open: int) -> void:
	if on() and open > 0:
		_s(f, DZ_WHIFF, _now(S) + open + 1)


## 10-26 item 23 (and 24): a guard broken by the blow a dazes only when a charged blow or a tapped heavy outside a string
## broke it. Broken by a launcher (the newcomer's B among them), it gives the launcher's own result; worn through, a
## plain stagger.
static func breakDazes(a) -> bool:
	if bool(a.get("charged", false)):
		return true
	return not bool(a.get("launcher", false)) and int(a.get("k", 1)) <= 1


## 10-26 item 23 (and 25): a perfect block dazes the one it turned only when it turned a charged blow or a string's
## ender (a heavy after other blows of his string), never a plain heavy and never a launcher (that keeps its reversal,
## the stagger and the sure counter-launch).
static func pbDazes(a) -> bool:
	if DirBrawl._g(a, DirBrawl.FLAV) == 2:
		return false
	if DirBrawl._g(a, DirBrawl.CHG) == 3:
		return true
	return DirBrawl._g(a, DirBrawl.KIND) == DirBrawl.BIG and DirBrawl._g(a, DirBrawl.STR_K) > 1


## f's blow a landed clean on o (DirBrawl.contact, before its reel): true when it punished o's heavy whiff and dazed
## him. Only a tapped heavy or a perfect follow-up punishes it (10-26 items 8 and 23, dazes still over 8): a light or a
## medium never dazes, nor a launcher (it gives its own result), and the whiff's window stays open for the next blow.
static func whiffPunish(S: SimState, ex, f, o, a) -> bool:
	if not on() or _g(o, DZ_WHIFF) <= _now(S):
		return false
	if not bool(a.get("riposte", false)) and (int(a.get("bk", DirBrawl.LIGHT)) != DirBrawl.BIG or bool(a.get("launcher", false))):
		return false
	_s(o, DZ_WHIFF, 0)
	return daze(S, ex, f, o, "whiff_punished")


## The burst's gate (DirInterrupt._canBurst): no burst in a daze's first burstAfter ticks.
static func burstHeld(S: SimState, f) -> bool:
	if not dazed(S, f):
		return false
	return _now(S) - (_g(f, DZ_AT) - 1) < int(cfg().get("daze", {}).get("burstAfter", 12))


## f burst (DirInterrupt.burst): it breaks his daze, and in a rally's flight it ends his journey and the rally.
static func burstOut(S: SimState, f) -> void:
	if not on():
		return
	if _g(f, DZ_UNTIL) > 0:
		f.stunTicks = 0
		_s(f, DZ_UNTIL, 0)
		_cue(S, f, "daze", "end", "burst")
	var A = SimRoster.opp(S, f)
	if f.state == "launched" and _owner(S, A, f):
		_endFlight(S, f, "burst")
		end(S, A, "burst")


## The in-flight burst (DirInterrupt._canBurst lets it through while launched): in a rally link, after its first
## burstAfter ticks.
static func burstInFlight(S: SimState, f) -> bool:
	if not on() or f.state != "launched":
		return false
	var A = SimRoster.opp(S, f)
	if not _owner(S, A, f):
		return false
	return _now(S) - (maxi(_g(A, RL_LA), 1) - 1) >= int(cfg().get("daze", {}).get("burstAfter", 12))


# ---------------------------------------------------------------- the sell

## The hit-stop weight of a brawl blow that lands (DirBrawl.contact, at DirMelee.weigh): a landed medium at a dazed
## fighter is sold, with the sell cue (10-26 §2c: the sold blows are Y mediums; lights aren't sold, and B is the send).
## Else w.
static func sellWeight(S: SimState, f, o, a, w: String) -> String:
	if not dazed(S, o) or bool(a.get("launcher", false)):
		return w
	if int(a.get("bk", DirBrawl.LIGHT)) != DirBrawl.MEDIUM:
		return w
	_s(o, DZ_SOLD, _g(o, DZ_SOLD) + 1)
	var e = _cue(S, f, "sell", "medium")   # (Camera's: actor the attacker, target the dazed, amount 1 a medium)
	e.target = float(S.fighters.find(o))
	e.amount = 1.0
	return String(cfg().get("sell", {}).get("weight", "launch"))


## The AI at a dazed rival (DirBrawl.aiInput, before its launcher presses; 10-26 item 10): true while it sells, so B
## waits. It lands its level's rally.sells mediums, one at a time, while one more would still leave B its press with
## sell.bLeftTicks of the daze left; then the caller's B (the daze's opening) is pressed. On easy (sells 0) B at once.
static func aiSell(S: SimState, ex, f, o, i: SimIntent, bl: Dictionary) -> bool:
	if not dazed(S, o) or f.ai == null:
		return false
	var c: Dictionary = DirBrawl.cfg()
	var left: int = _g(o, DZ_UNTIL) - _now(S)
	var lead: int = int(c.medium.windupTicks) + DirBrawl._closeTicks(f, o)
	if _g(o, DZ_SOLD) >= int(_ai().get("sells", 0)) or left - lead < int(cfg().get("sell", {}).get("bLeftTicks", 8)) or f.ki < float(c.medium.ki):
		return false   # B now
	if DirBrawl._g(f, DirBrawl.LINE) != 0 or S.tick < DirBrawl._g(f, DirBrawl.AI_NEXT) or not DirBrawl._free(S, f):
		return true   # its medium is on its way, or it can't press yet: B waits
	DirBrawl._aiPress(S, f, i, 1, bl)
	return true


# ---------------------------------------------------------------- the rally

## True while A owns a rally on D.
static func _owner(S: SimState, A, D) -> bool:
	return A != null and D != null and _g(A, RL_ON) == S.fighters.find(D) + 1


## The rally A owns, if any: its victim, or null.
static func victimOf(S: SimState, A):
	var v: int = _g(A, RL_ON) - 1
	return S.fighters[v] if v >= 0 and v < S.fighters.size() else null


## A full send of att's has just been made (DirMelee, after doLaunch): it opens a rally on tgt, or turns one he owned.
static func onSend(S: SimState, att, tgt, power: float, args, plan: Dictionary) -> void:
	if not on() or att == null or tgt == null:
		return
	var full: float = float(DirBrawl.popCfg().get("full", 0.8)) if DirBrawl.popOn() else 0.8
	if power >= 0.0 and power < full - 0.0005:
		return   # a weak send opens nothing
	if tgt.launchSpecial:
		return   # a signature, a finisher or a break launch opens nothing: the chase can't follow one (7c), so it could have no link
	var turns: int = 0
	if _owner(S, tgt, att):
		turns = _g(tgt, RL_TURNS) + 1   # the turn: the rally is his now
		end(S, tgt, "turned", false)
	elif _g(att, RL_ON) > 0:
		end(S, att, "resent", false)
	var now: int = _now(S)
	_s(att, RL_ON, S.fighters.find(tgt) + 1)
	_s(att, RL_AT, now + 1)
	_s(att, RL_LINKS, 0)
	_s(att, RL_K1, 0)
	_s(att, RL_KC, 0)
	var di: int = _destIndex(dest(S, plan, ""))
	_s(att, RL_D1, di + 1)
	_s(att, RL_D2, 0)
	_s(att, RL_DM, (1 << di) if di >= 0 else 0)
	_s(att, RL_LAND, 0)
	_s(att, RL_TECH, 0)
	_s(att, RL_TURNS, turns)
	_s(att, RL_LA, now + 1)
	var sold: bool = args != null and bool(args.get("sold", false))
	_s(att, RL_SOLD, 1 if sold else 0)
	_s(tgt, DZ_UNTIL, 0)   # the send ends his daze (its own landing pays as a launcher's send does)
	if turns > 0:
		var te = _cue(S, att, "rally_turn", "")   # the new attacker, the new body
		te.target = float(S.fighters.find(tgt))
		te.n = turns
	var e = _cue(S, att, "rally_link", "send", "sold" if sold else "")   # the opening send: the link of index 0
	e.target = float(S.fighters.find(tgt))
	e.k = 1.0 if sold else 0.0
	e.n = 0


## Where a send takes him (Combat's destinations): a building, a mountainside (cliff), the sea, the ground (straight
## down), back along his flight (the overtake), open air.
static func dest(S: SimState, k: Dictionary, kind: String) -> String:
	var nm: String = String(k.get("name", ""))
	if k.has("brunt") or nm == "BUILDING SMASH":
		return "building"
	if nm == "MOUNTAINSIDE" or nm == "CLIFFSIDE":   # biomes W3: CLIFFSIDE is MOUNTAINSIDE for any biome
		return "cliff"
	if kind == "overtake":
		return "back_along"
	var p = k.get("p", null)
	if p is Dictionary and bool(p.get("water", false)):
		return "water"
	if nm == "DRIVE DOWN" or nm == "CRATER SLAM" or nm == "MARSH SWALLOW" or kind == "spike":
		return "ground"
	return "open_air"


static func _destIndex(d: String) -> int:
	return (scoring().get("destinations", []) as Array).find(d)


## The stick's class for a chase, read once at its commit (DirChase._begin; Controls' rule): back within read.sectorDeg
## (45°) of the reverse of his flight, across within it of either perpendicular, and only on a lean of read.leanMin
## (0.60) or more; its eight-way way for the own links that follow the stick. The AI's stick is its choice at the catch.
static func commitStick(S: SimState, A, D) -> void:
	if not on() or A.ai != null:
		return
	var rd: Dictionary = cfg().get("read", {})
	var mx: float = A.input.mx
	var my: float = A.input.my
	var lean: float = SimDetMath.hypot(mx, my)
	var cls: int = 0
	var way: int = 0
	if lean >= float(rd.get("leanMin", 0.6)):
		way = DirChase._tilt(A)
		var vl: float = SimDetMath.hypot(D.vx, D.vy)
		if vl > 1.0:
			var cosA: float = (mx * D.vx + my * D.vy) / (lean * vl)
			var edge: float = SimDetMath.cos(float(rd.get("sectorDeg", 45.0)) * SimMathx.PI / 180.0)
			if cosA <= -edge:
				cls = 1   # back: the overtake
			elif absf(cosA) <= edge:
				cls = 2   # across: the Palm Turn's
	_s(A, RL_STC, cls)
	_s(A, RL_STD, way)


## The base kind an own link is a variant of (rally.own.<id>.base: the Palm Turn an overtake, Plate Chase a chase), for
## Camera's shots; a base kind is itself.
static func baseKind(kind: String) -> String:
	return String(cfg().get("own", {}).get(kind, {}).get("base", kind))


## True when f's own link `own` is his (rally.own: the fighter it belongs to).
static func _his(f, own: String) -> bool:
	return String(cfg().get("own", {}).get(own, {}).get("fighter", "")) == String(f.id)


## The link kind A's catch of D is (DirChase._catch). A player's: the spike (B from above him), the Rival's Plate Chase
## (the chase with Y), the Protagonist's Palm Turn (the stick across, read at the commit), the overtake (the stick back),
## else the chase strike. The AI's: the best of the kinds open to it by Combat's scoring (item 13).
static func linkKind(S: SimState, A, D, spike: bool, heavy: bool) -> String:
	var above: bool = A.y > D.y + float(cfg().get("spikeAboveBh", 0.5)) * DirInterrupt.BH
	if A.ai == null:
		if spike and above:
			return "spike"
		if heavy and _his(A, "plate_chase"):
			return "plate_chase"
		var cls: int = _g(A, RL_STC)
		if cls == 2 and _his(A, "palm_turn"):
			return "palm_turn"
		if cls == 1:
			return "overtake"
		return "chase"
	var open: Array = ["chase", "overtake"]
	if above:
		open.append("spike")
	for o in OWN:
		if _his(A, o):
			open.append(o)
	var best: String = "chase"
	var bs: float = -INF
	for i in range(open.size()):
		var k: String = open[i]
		var s: float = _kindScore(A, k) + SimRng.keyed(int(S.game.seed), "rally.pick", S.tick * 16 + i) * float(scoring().get("variety", {}).get("noise", 6))
		if s > bs:
			bs = s
			best = k
	return best


## Combat's kind terms for the next link of A's rally: a kind new to it kindNew, the last link's kindLast, one used
## earlier kindEarlier, a third of one kind kindThird; an own link ownLink more.
static func _kindScore(A, kind: String) -> float:
	var v: Dictionary = scoring().get("variety", {})
	var ki: int = kinds().find(kind)
	var cnt: int = (_g(A, RL_KC) >> (ki * 4)) & 15 if ki >= 0 else 0
	var s: float = 0.0
	if cnt + 1 >= int(cfg().get("tech", {}).get("autoAt", 3)):
		s += float(v.get("kindThird", -1000))
	elif _g(A, RL_K1) == ki + 1:
		s += float(v.get("kindLast", -20))
	elif cnt > 0:
		s += float(v.get("kindEarlier", -10))
	else:
		s += float(v.get("kindNew", 20))
	if OWN.has(kind):
		s += float(v.get("ownLink", 8))
	return s


## The Rival's Plate Chase (23d item 19): the body sent exactly along the stick's eight-way line read at the commit,
## with no bend from the planner; with no stick, straight on along his flight.
static func plateLine(S: SimState, A, D) -> Dictionary:
	var way: int = _g(A, RL_STD) if A.ai == null else 0
	var ux: float = 0.0
	var uy: float = 0.0
	if way >= 1 and way <= 8:
		ux = float(DirChase.TILT_X[way - 1])
		uy = float(DirChase.TILT_Y[way - 1])
	else:
		var vl: float = maxf(SimDetMath.hypot(D.vx, D.vy), 0.001)
		ux = D.vx / vl
		uy = D.vy / vl
		if uy < -0.3:
			ux = SimMathx.jsign(D.vx) if D.vx != 0.0 else float(A.face)
			uy = 0.0   # 10-26 item 32: on a neutral stick a link's send is never down (his flight laid flat)
	return {"name": "PLATE CHASE", "ux": ux, "uy": uy, "s": 0.0}   # (no score: his choice, not the planner's)


## The way the Palm Turn turns him: the stick's eight-way read at the commit (across his flight); with none (the AI), up.
static func palmTilt(A) -> int:
	var way: int = _g(A, RL_STD) if A.ai == null else 0
	return way if way >= 1 and way <= 8 else 1


## The defender's tech at a link's arrival (DirChase._catch): true when D techs A's link of `kind`. A guard press of his
## within tech.fresh ticks (a kind new to the rally), tech.earlier (used before, not last) or tech.repeat (the same as
## the last); the autoAt-th of one kind is teched by itself. The AI techs at its level's shares.
static func teched(S: SimState, A, D, kind: String) -> bool:
	if not _owner(S, A, D):
		return false
	var t: Dictionary = cfg().get("tech", {})
	var ki: int = kinds().find(kind)
	var cnt: int = (_g(A, RL_KC) >> (ki * 4)) & 15 if ki >= 0 else 0
	var step: String = "repeat" if _g(A, RL_K1) == ki + 1 else ("earlier" if cnt > 0 else "fresh")
	var auto: bool = cnt + 1 >= int(t.get("autoAt", 3))
	var won: bool = auto
	if not won:
		if D.ai == null:
			var gp: int = _g(D, RL_GP) - 1
			won = gp >= 0 and _now(S) - gp <= int(t.get(step, 4))
		else:
			var sh: String = {"fresh": "tech", "earlier": "techEarlier", "repeat": "techRepeat"}[step]
			won = SimRng.keyed(int(S.game.seed), "rally.tech", S.tick * 4 + S.fighters.find(D)) < float(_ai().get(sh, 0.0))
	if won:
		_endFlight(S, D, "tech")
		DirRecoil._land(S, D)   # he is set in the air: the recoil flip's counter-rush within its ticks (the turn)
		_s(A, RL_TECH, _now(S) + 1)
		var e = _cue(S, D, "rally_tech", baseKind(kind), kind if OWN.has(kind) else "")
		e.target = float(S.fighters.find(A))
		e.k = 1.0 if auto else 0.0
		SimEvents.feed(S, D.name + " TECHS", ("by himself: a third " if auto else "the ") + kind + " (" + step + ")")
	return won


## A link of A's on D landed and sent him on (DirChase._catch, after the send).
static func onLink(S: SimState, A, D, kind: String, plan: Dictionary) -> void:
	if not _owner(S, A, D):
		return
	var ki: int = kinds().find(kind)
	_s(A, RL_LINKS, _g(A, RL_LINKS) + 1)
	_s(A, RL_K1, ki + 1)
	if ki >= 0:
		var kc: int = _g(A, RL_KC)
		var cnt: int = mini(15, ((kc >> (ki * 4)) & 15) + 1)
		_s(A, RL_KC, (kc & ~(15 << (ki * 4))) | (cnt << (ki * 4)))
	var di: int = _destIndex(dest(S, plan, kind))
	_s(A, RL_D2, _g(A, RL_D1))
	_s(A, RL_D1, di + 1)
	if di >= 0:
		_s(A, RL_DM, _g(A, RL_DM) | (1 << di))
	_s(A, RL_LAND, 0)
	_s(A, RL_LA, _now(S) + 1)
	DirBrawl.paySend(D, 1.0)
	var e = _cue(S, A, "rally_link", baseKind(kind), kind if OWN.has(kind) else "")   # (Camera's: text the base kind, source the own link)
	e.target = float(S.fighters.find(D))
	e.n = _g(A, RL_LINKS)


## 10-26 item 22(b): set around the planner's pick of a send that will open a rally (DirMelee.launchBeat): with the
## stick neutral (tilt 0), the planner picks across or up for it, so there is a flight to link. A stick held down still
## wins. Not state: set and cleared within the one call.
static var _noDown: bool = false

static func openNoDown(S: SimState, att, tgt, lpow: float, special: bool, tilt: int) -> void:
	var full: float = float(DirBrawl.popCfg().get("full", 0.8)) if DirBrawl.popOn() else 0.8
	_noDown = on() and att != null and tgt != null and tilt == 0 and not special and (lpow < 0.0 or lpow >= full - 0.0005)


static func clearNoDown() -> void:
	_noDown = false


## 10-26 item 32: set around the planner's pick for a link's send (DirChase._catch): on a neutral stick it goes across
## or up, as the opening's does; a held-down stick still wins, and the spike is the deliberate down link.
static func linkNoDown(tilt: int, kind: String) -> void:
	_noDown = on() and tilt == 0 and kind != "spike"


## 10-26 item 22(a): the world's links count, with no press. A send of a rally carried into a building (World's
## building_hit on the body), across water (a skim beside him) or against a face (DirWallKick.atWall: a cliff or a
## building's face) is a link, one a send. No tech: his answers to it are the wall kick, the brake and the burst.
static func worldLink(S: SimState, D, where: String) -> void:
	if not on() or D == null or D.state != "launched":
		return
	var A = SimRoster.opp(S, D)
	if not _owner(S, A, D) or _g(A, RL_WL) == _g(A, RL_LA):
		return
	_s(A, RL_WL, _g(A, RL_LA))
	var ki: int = kinds().find("world")
	_s(A, RL_LINKS, _g(A, RL_LINKS) + 1)
	_s(A, RL_K1, ki + 1)
	if ki >= 0:
		var kc: int = _g(A, RL_KC)
		var cnt: int = mini(15, ((kc >> (ki * 4)) & 15) + 1)
		_s(A, RL_KC, (kc & ~(15 << (ki * 4))) | (cnt << (ki * 4)))
	var e = _cue(S, A, "rally_link", "world", "")   # (Camera's: text the base kind)
	e.target = float(S.fighters.find(D))
	e.n = _g(A, RL_LINKS)
	SimEvents.feed(S, A.name + " RALLY", "the world's link: " + where)


## This tick's world contacts of D's flight (World's events, this tick only): a building hit, a skim.
static func _worldContacts(S: SimState, A, D) -> void:
	if _g(A, RL_WL) == _g(A, RL_LA):
		return
	var di: int = S.fighters.find(D)
	for e in S.out.fx:
		if int(e.tick) != S.tick:
			continue
		var t: String = String(e.type)
		if t == "building_hit" and int(e.actor) == di:
			worldLink(S, D, "building")
			return
		if t == "skim" and absf(SimWrap.sdx(D.x, float(e.x))) <= 2.0 * DirInterrupt.BH:
			worldLink(S, D, "water")
			return


## 10-26 item 22(d): no Escape stance for the attacker while his rally runs, nor for a rally's body while he is sent.
static func noEscape(S: SimState, f) -> bool:
	if not on() or f == null:
		return false
	if _g(f, RL_ON) > 0:
		return true
	return f.state == "launched" and _owner(S, SimRoster.opp(S, f), f)


## 10-26 item 40: the AI's link in its own rally, drawn at its share, waits for the zip's price while the body flies
## and starts the moment its ki allows (DirChase.steer), as a player presses. The rally ends when the attacker has no
## ki for the next link (23d item 11), not when the AI's one draw came too early.
static func waitsKi(S: SimState, A, D) -> bool:
	return on() and _owner(S, A, D)


## 10-26 item 33: a link's blow deals rally.linkWorth of its damage (the opening send and the sell are not links).
static func linkWorth(S: SimState, A, D) -> float:
	return float(cfg().get("linkWorth", 1.0)) if _owner(S, A, D) else 1.0


## The choreographer's variety for the planner's candidates in a rally (DirLaunch.chooseLaunch, each candidate; Combat's
## destination and world terms): a destination new to this rally destNew, the last one's destLast, the one before
## destSecondLast; a world candidate (a building, a mountainside, the sea) worldLink and its place. 0 outside a rally.
static func variety(S: SimState, A, k: Dictionary) -> float:
	if _noDown and float(k.get("uy", 0.0)) < -0.3:
		return -1000.0   # 10-26 item 22(b): a rally's opening send on a neutral stick is never down
	if not on() or A == null or _g(A, RL_ON) <= 0:
		return 0.0
	var v: Dictionary = scoring().get("variety", {})
	var d: String = dest(S, k, "")
	var di: int = _destIndex(d)
	var s: float = 0.0
	if di >= 0:
		if _g(A, RL_D1) == di + 1:
			s += float(v.get("destLast", -12))
		elif _g(A, RL_D2) == di + 1:
			s += float(v.get("destSecondLast", -6))
		elif (_g(A, RL_DM) & (1 << di)) == 0:
			s += float(v.get("destNew", 12))
	var wp: Dictionary = v.get("worldPlace", {})
	if wp.has(d):
		s += float(v.get("worldLink", 18)) + float(wp[d])
	return s


## The turn (DirBrawl.contact, a blow of f's landing clean on o): f's counter-rush, spent within turnTicks, lands on o in
## the air while o owns a rally on f: a full send of o, and the rally is f's. True when it took the blow.
## 10-26 item 30: f's blow on o is the counter-rush of o's rally: the one he flew in with (RL_CRUSH, within
## turnTicks of its press), or his next blow inside his counter window (DirRecoil.due: an air tech's, a wall kick's or
## a flip's). It lands on the chaser through his guard (DirBrawl.contact), a perfect block aside.
static func counterLive(S: SimState, f, o) -> bool:
	if not on() or f == null or o == null or not _owner(S, o, f):
		return false
	var cr: int = _g(f, RL_CRUSH) - 1
	if cr >= 0 and _now(S) - cr <= int(cfg().get("turnTicks", 60)):
		return true
	return DirRecoil.due(S, f) or DirWallKick.due(S, f)   # (10-26 item 37: his wall kick's rush blow too)


static func turn(S: SimState, ex, f, o, a) -> bool:
	if not counterLive(S, f, o):
		return false
	var g: float = WorldTerrain.groundY(S, o.x)
	if o.y - g <= float(cfg().get("airBh", 1.0)) * DirInterrupt.BH:
		return false   # the chaser is down: a plain blow
	_s(f, RL_CRUSH, 0)
	if DirRecoil.due(S, f):
		DirRecoil.counter(S, f)   # his window's blow is the counter-rush: it spends the window, with its cue
	elif DirWallKick.due(S, f):
		DirWallKick.rushBlow(S, f)   # 10-26 item 37: his kick's rush blow is the counter-rush, as a flip's
	DirBrawl._send(S, ex, f, o, 0, "the turn", 1.0)
	return true


## 10-26 item 37: D's answer to f's rally is under way: his recoil flip in the air, his wall kick's push, or his
## counter-rush (counterLive). The rally stays open while it is.
static func answering(S: SimState, D, f) -> bool:
	return DirRecoil.flipping(S, D) or DirWallKick.pushing(S, D) or counterLive(S, D, f)


## 10-26 item 37(3): the defending AI's counter-rush share after an answer in a rally of the other's (its level's
## rally.counter), in place of the recoil flip's (brawl.recoil.counter). dflt outside a rally.
static func counterShare(S: SimState, f, dflt: float) -> float:
	if not on() or f == null or not _owner(S, SimRoster.opp(S, f), f):
		return dflt
	return float(_ai().get("counter", dflt))


## 23d item 9: a rally's body lands (World's land contact this tick: a skid, a tumble or a slam), and his recoil flip's
## window opens as a knock-back skid's does (DirRecoil.landed). 10-26 item 37: the counter-rush after the flip lands on
## a committed chaser, as after the air tech. 10-26 item 39: only at the landing that would end his flight. A contact
## that carries the flight on is a link, not a landing: a skip across water and a glance off a face are World's bounces
## (no land), and a slam's hop (a spike's bounce off hard ground) is a land his leaving the ground follows this tick.
static func _landing(S: SimState, A, D) -> void:
	var di: int = S.fighters.find(D)
	var down: bool = false
	for e in S.out.fx:
		var ty: String = String(e.type)
		if (ty == "land" or ty == "left_ground") and int(e.tick) == S.tick and int(e.actor) == di:
			down = ty == "land"   # the tick's last contact decides: a land, or the flight carried on
	if down:
		DirRecoil.landed(S, A, D)


## His counter-rush was spent (DirRecoil.counter): the turn may follow when it lands.
static func markCounter(S: SimState, f) -> void:
	if on():
		_s(f, RL_CRUSH, _now(S) + 1)


## f's journey ends where he is (a tech, a burst): World's journey end, or the brake's control back.
static func _endFlight(S: SimState, f, kind: String) -> void:
	if f.state != "launched":
		return
	if S.contactOn:
		WorldContact.brakeEnd(S, f, kind)
	else:
		SimBrake.controlBack(S, f)


## The rally A owns ends (why). victimWary: his victim is wary for waryTicks.
static func end(S: SimState, A, why: String, victimWary: bool = true) -> void:
	var D = victimOf(S, A)
	if D == null:
		return
	var now: int = _now(S)
	var e = _cue(S, A, "rally_end", why)   # (Camera's: text the reason)
	e.target = float(S.fighters.find(D))
	e.n = _g(A, RL_LINKS)
	e.k = float(_g(A, RL_TURNS))
	e.dur = float(now - (maxi(_g(A, RL_AT), 1) - 1))
	_s(A, RL_ON, 0)
	_s(A, RL_TECH, 0)
	_s(A, RL_LAND, 0)
	if victimWary:
		_s(D, WR_UNTIL, now + int(cfg().get("waryTicks", 120)))


# ---------------------------------------------------------------- each live tick

## DirExchange.dirUpdate, once a live tick: guard presses noted (the tech), dazes shaved, ended or begun after a slam,
## the AI's bursts out, and each rally's end by its landing or its untaken tech.
## 10-26 item 7: the send's contact and its hit-stop end the exchange for its attacker. On the first live tick after a
## rally's send (this runs last in dirUpdate, and the hit-stop has passed), the exchange that still holds him ends (a
## template exchange's chain window held him; a finisher and a beam stay), and a link press of his that waited starts.
static func _release(S: SimState, f, D, now: int) -> void:
	var ex = S.dirS.ex
	if ex != null and (ex.A == f or ex.D == f) and now - (_g(f, RL_LA) - 1) >= 1 and String(ex.kind) != "sig" and not DirExchange.finisherPlanned(ex):
		if DirBrawl.isBrawl(ex):
			DirBrawl.end(S, ex, "launch")
		else:
			DirExchange.endEx(S, ex)
	var q: int = _g(f, RL_Q)
	if q <= 0:
		return
	if now - (q / 4 - 1) > int(cfg().get("queueTicks", 12)):
		_s(f, RL_Q, 0)   # it lapsed
	elif f.state == "free" and S.dirS.ex == null and f.stunTicks <= 0:
		_s(f, RL_Q, 0)
		DirChase.startQueued(S, f, D, q % 4)


## A player's attack press (DirExchange._request, before the brawl's): true when it is a link press (LT with X or Y,
## or B) of a rally of his whose body flies, made while his send still holds him. It waits for his first free tick
## (10-26 item 7), within queueTicks; a later press replaces it.
static func queues(S: SimState, A, kind: String) -> bool:
	if not on() or A.ai != null:
		return false
	var D = victimOf(S, A)
	if D == null or D.state != "launched" or D.launchBy != A:
		return false
	if A.state == "free" and S.dirS.ex == null and A.stunTicks <= 0:
		return false   # he is free: the chase takes it as it comes
	var k: int = 0
	if kind == "sig" and DirBrawl.isB(A, "sig"):
		k = 3
	elif (A.input.stanceMask & DirZip.LT) != 0 and (kind == "light" or kind == "heavy"):
		k = 1 if kind == "light" else 2
	if k == 0:
		return false
	_s(A, RL_Q, k + 4 * (_now(S) + 1))
	return true


## The live ticks since A's rally's last send (the AI's chase reaction runs from it: 10-26 item 7).
static func sinceSend(S: SimState, A) -> int:
	return _now(S) - (maxi(_g(A, RL_LA), 1) - 1)


static func tick(S: SimState) -> void:
	if not on():
		return
	var c: Dictionary = cfg()
	var dc: Dictionary = c.get("daze", {})
	var now: int = _now(S)
	for f in S.fighters:
		if f.ai == null and f.input != null and f.input.guardPress:
			_s(f, RL_GP, now + 1)
		if _g(f, DZ_PEND) == 1 and f.state == "free" and f.stunTicks <= 0:
			daze(S, S.dirS.ex, SimRoster.opp(S, f), f, "wall_slam")
		var du: int = _g(f, DZ_UNTIL)
		if du > 0:
			if now >= du or f.stunTicks <= 0:
				_s(f, DZ_UNTIL, 0)
				_cue(S, f, "daze", "end", "time")
			else:
				var every: int = maxi(1, int(dc.get("shaveEvery", 6)))
				var last: int = _g(f, DZ_SH) - 1
				var pressed: bool = false
				if f.ai == null:
					pressed = f.input != null and (f.input.light or f.input.heavy or f.input.sig or f.input.guardPress or f.input.context or f.input.dodge)
				elif (now - (_g(f, DZ_AT) - 1)) % every == 0 and SimRng.keyed(int(S.game.seed), "rally.shave", S.tick * 4 + S.fighters.find(f)) < float(_ai().get("dazeMash", 0.0)):
					pressed = true
				if pressed and (last < 0 or now - last >= every):
					var sh: int = int(dc.get("shave", 3))
					f.stunTicks = maxi(0, f.stunTicks - sh)
					_s(f, DZ_UNTIL, du - sh)
					_s(f, DZ_SH, now + 1)
					_cue(S, f, "daze", "shave", "")
				if f.ai != null and _g(f, RL_AIB) == 1 and now - (_g(f, DZ_AT) - 1) >= int(dc.get("burstAfter", 12)):
					_s(f, RL_AIB, 0)
					DirInterrupt.burst(S, f)
		var D = victimOf(S, f)
		if D == null:
			continue
		if S.game.ko != null:
			end(S, f, "ko", false)
			continue
		if D.state == "launched":
			_release(S, f, D, now)
			_worldContacts(S, f, D)
			_landing(S, f, D)   # 23d item 9: his landing opens his recoil flip's window (10-26 item 37)
			_s(f, RL_LAND, 0)
			if D.ai != null and _g(D, RL_AIB) != 2 and now - (maxi(_g(f, RL_LA), 1) - 1) == int(dc.get("burstAfter", 12)) and SimRng.keyed(int(S.game.seed), "rally.airBurst", S.tick * 4 + S.fighters.find(D)) < float(_ai().get("airBurst", 0.0)):
				_s(D, RL_AIB, 2)
				DirInterrupt.burst(S, D)
			continue
		_s(f, RL_Q, 0)   # he came down: a waiting link press lapses
		if DirWater.under(D):
			continue   # 10-26 row 6: a drop into the water lands when he surfaces
		var tk: int = _g(f, RL_TECH) - 1
		if tk >= 0:
			if now - tk > int(DirRecoil.cfg().get("counterTicks", 20)) and not counterLive(S, D, f):
				end(S, f, "teched")   # (10-26 item 30: not while his counter-rush is on its way)
			continue
		var ld: int = _g(f, RL_LAND) - 1
		if ld < 0:
			_s(f, RL_LAND, now + 1)
		elif now - ld > int(c.get("endTicks", 20)) and not DirChase.chasing(f) and not answering(S, D, f):
			end(S, f, "ki" if f.ki < DirChase._price(false) else "landed")   # (10-26 item 37: not while his answer is under way; item 40: "ki" when he is short of the next link)
