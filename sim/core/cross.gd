class_name SimCross
extends RefCounted
## 2v2: blows, shots and beams that reach a body of the other fight (docs/architecture/cross-fights.md; Game Design's "Hits
## across fights" in docs/design/two-v-two.md), in a match of two fights (sim/core/stage.gd) with data/fight/cross.json's
## switch on, or the setup's "cross". Teams are by the slot a body started in: 0 and 2 against 1 and 3. Anything may reach
## an enemy, and nothing reaches a partner.
## Whatever reaches a body of another fight is met there, on that fight's clock and under its rules, so a hit on someone held
## lands the tick his fight is free: a shot goes over into his fight as a shot from outside (owner -1, "from" its shooter's
## keys) and his guard, dodge and deflect answer it; a blow, a mine's blast and a beam's hit wait on the stage
## (S.stage.mail), addressed by his keys so they follow him through a trade, and land at the start of his fight's next
## live tick. Off, nothing here runs and nothing is hashed. Nothing here draws from S.rng.

const FILE: String = "res://data/fight/cross.json"

static var _d = null
static var _hash: String = ""
static var _errors: Array = []
static var on_: bool = false
static var beamDmg: float = 230.0
static var beamStop: float = 0.14
static var beamShake: float = 16.0
static var rejoinAfter: float = 2.2    # seconds of a fight's KO before its winner can be rejoined with the other fight's (SimStage.rejoin)
static var blind: int = 0              # tests only: 1 loses what's sent, 2 lands it twice, 3 loses a shot going over (cross_check's negative control); 4 a fallen body stays standing (cross_end_check's); 5 a setup's "outside" is ignored, 6 the stage's clock stands still, 7 the step clears the picture's lists as it used to (coop_check's)
static var _cap: float = 840.0         # 2v2's time cap, seconds on the stage's clock (timeCap)
static var _last: float = 900.0        # ... and the ending's last event (lastAt)
static var sent: Dictionary = {}       # tests only: what's been sent across, by kind (a shot gone over counts as "shot")
static var landed: Dictionary = {}     # ... and what's landed from the stage
static var partners: int = 0           # ... and what was refused for being sent to a partner


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	var h := SimHash.Hasher.new()
	var j = FighterData._load(FILE, "fight/cross.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary):
		_errors.append("fight/cross.json: missing, or not an object")
		_d = {}
		_hash = h.hex()
		return
	_d = j
	h.text("fight/cross.json")
	FighterData._canon(h, j)
	_hash = h.hex()
	on_ = j.get("enabled") == true
	beamDmg = float(j.beam.dmg)
	beamStop = float(j.beam.stop)
	beamShake = float(j.beam.shake)
	rejoinAfter = float(j.rejoinAfter)
	_cap = float(j.timeCapAt)
	_last = float(j.lastAt)


static func enabled() -> bool:
	_ensure()
	return on_


static func dataHash() -> String:
	_ensure()
	return _hash


static func errors() -> Array:
	_ensure()
	return _errors


## On for this match: two fights, and the switch.
static func on(S: SimState) -> bool:
	return S.stage != null and S.stage.cross


## 2v2's time cap (Game Design: 14:00, docs/design/two-v-two.md) and the ending's last event, in seconds on the stage's
## clock (S.stage.clock), for a match with hits across on: DirExchange and DirEnding read them in place of a 1v1's, so
## both fights reach them on one tick. 0: none.
static func timeCap() -> float:
	_ensure()
	return _cap


static func lastAt() -> float:
	_ensure()
	return _last


## A body's team, by the slot he started in ("p1" is slot 0): 0 for slots 0 and 2, 1 for 1 and 3.
static func team(f) -> int:
	return teamOf(f.keys)


static func teamOf(keys: String) -> int:
	return (int(keys.substr(1)) - 1) % 2


## His bit, by the slot he started in: what a beam has met is kept by these.
static func bit(f) -> int:
	return 1 << (int(String(f.keys).substr(1)) - 1)


## The body of these keys, in any fight; null for none.
static func body(S: SimState, keys: String):
	return _of(SimStage.bodies(S), keys) if keys != "" else null


## Who fired a shot: its owner in S's fight, or its shooter in another for a shot from outside.
static func shooter(S: SimState, sh):
	return S.fighters[sh.owner] if sh.owner >= 0 else body(S, sh.from)


## The slot in S's fight of a team's body, for a shot from outside that trades with the other's shots there; -1 for none.
static func slotOf(S: SimState, t: int) -> int:
	for k in range(S.fighters.size()):
		if team(S.fighters[k]) == t:
			return k
	return -1


## The bodies of the fights not in S's that an attack of team t can reach: the other team's, out of the intro, and not out
## for the match. A fight with a KO keeps its winner, who can be reached. Fight by fight, in slot order.
static func enemies(S: SimState, t: int) -> Array:
	var st = S.stage
	var out: Array = []
	for i in range(st.fights.size()):
		if i == st.cur:
			continue
		for f in st.fights[i].fighters:
			if team(f) != t and f.state != "intro" and not f.out:
				out.append(f)
	return out


## Encounter's: the enemies of f in the other fights within reach of him, centre to centre and in depth, nearest first (in
## fight and slot order when tied).
static func enemiesNear(S: SimState, f, reach: float) -> Array:
	var near: Array = []   # [distance squared, body]
	for g in enemies(S, team(f)):
		var dx: float = SimWrap.sdx(f.x, g.x)
		var dy: float = g.y - f.y
		var d2: float = dx * dx + dy * dy
		if d2 > reach * reach or absf(g.z - f.z) > reach:
			continue
		var at: int = near.size()
		while at > 0 and near[at - 1][0] > d2:
			at -= 1
		near.insert(at, [d2, g])
	var out: Array = []
	for e in near:
		out.append(e[1])
	return out


## Encounter's: A, of the fight in S, sends a blow to D, of another. It lands through SimDamage.hit in D's fight at the start
## of its next live tick, by A's multipliers and D's stance then; o is hit's options (weight, stop, kind, region ...).
static func strike(S: SimState, A, D, dmg: float, o: Dictionary = {}) -> void:
	send(S, "blow", A, D, dmg, o)


## Encounter's: A, of the fight in S, fires a shot of this kind at D, of another. It's made in D's fight as a shot from
## outside, seeking him from A's chest, so his fight sees it coming as it sees its own: his guard, dodge and perfect block
## answer it there, on his clock. o: power and dmg, as SimShots.fire's. Returns the shot, or null.
static func fireAt(S: SimState, A, kind: String, D, o: Dictionary = {}):
	SimShots._ensure()
	var j: int = SimStage.fightOf(S, D)
	if j < 0 or j == S.stage.cur or team(A) == team(D) or A.out or D.out or not SimShots.kinds.has(kind):
		return null
	var kd: Dictionary = SimShots.kinds[kind]
	var r = S.stage.fights[j]
	if kd.mine != null or r.shots.size() >= SimShots.cap:
		return null
	var sh := SimState.Shot.new()
	r.shotSeq += 1
	sh.id = r.shotSeq
	sh.owner = -1
	sh.from = A.keys
	sh.kind = kind
	sh.x = A.x
	sh.y = A.y + SimShots.chest
	sh.z = A.z
	sh.power = float(o.get("power", kd.power))
	sh.dmg = float(o.get("dmg", kd.dmg))
	sh.mode = SimShots.SEEK
	sh.tgt = r.fighters.find(D)
	sh.left = SimShots._seekTicks(sh, D, kd.speed)
	sh.total = sh.left
	sh.vx = SimWrap.sdx(sh.x, D.x) / (float(sh.left) / SimShots.TPS)
	sh.vy = (D.y + SimShots.chest - sh.y) / (float(sh.left) / SimShots.TPS)
	sh.fresh = false
	sh.inT = S.tick   # it starts on its fight's next tick, whichever order the fights step in
	r.shots.append(sh)
	sent["shot"] = int(sent.get("shot", 0)) + 1
	SimFx.shotFire(S, sh)
	return sh


## A hit for a body of another fight, to land on his fight's next live tick: mine, beam or blow. Refused for a partner.
static func send(S: SimState, kind: String, A, D, dmg: float, o: Dictionary = {}) -> void:
	if A != null and team(A) == team(D):
		partners += 1
		return
	if D.out or (A != null and A.out):   # out for the match: inert
		return
	sent[kind] = int(sent.get(kind, 0)) + 1
	if blind == 1:
		return
	for k in range(2 if blind == 2 else 1):
		var it := SimState.Cross.new()
		it.tick = S.tick
		it.kind = kind
		it.from = A.keys if A != null else ""
		it.to = D.keys
		it.dmg = dmg
		it.o = o.duplicate(true)
		S.stage.mail.append(it)


## At the start of a fight's live tick (SimCore._fightTick): what was sent to its bodies on an earlier tick lands, in the
## order it was sent. A fight with a KO takes nothing more.
static func deliver(S: SimState) -> void:
	var st = S.stage
	if st.mail.is_empty():
		return
	var keep: Array = []
	var due: Array = []
	for it in st.mail:
		var D = _of(S.fighters, it.to)
		if D == null or it.tick >= S.tick:
			keep.append(it)
		else:
			due.append([it, D])
	if due.is_empty():
		return
	st.mail = keep
	for e in due:
		_land(S, e[0], e[1])


static func _of(list: Array, keys: String):
	for f in list:
		if f.keys == keys:
			return f
	return null


static func _land(S: SimState, it, D) -> void:
	var A = body(S, it.from)
	if D.out or D.state == "intro" or A == null or A.out:   # a fight with a KO still takes a hit on its winner
		return
	landed[it.kind] = int(landed.get(it.kind, 0)) + 1
	var o: Dictionary = it.o
	if it.kind == "mine":   # the director's mine rule, but for its knock: his guard takes it, else it's clean
		o = {"kind": "blast", "weight": "medium", "shot": it.o.get("power", 3.0), "ignoreStance": not guarding(D), "shake": 7.0}
	SimDamage.hit(S, null, A, D, it.dmg, o)
	if it.kind == "blow":
		SimDir.outsideLanded(S, A, D, o)   # Encounter's: what a blow from outside does to the fight it lands in


## Up and guarding: what a mine's blast or a beam from outside meets, as the director's rules read it.
static func guarding(f) -> bool:
	return f.stance == 1.0 and f.state != "down" and f.state != "launched"


## In his dodge: a beam from outside passes him, as a shot does (DirBlast.hit's rule).
static func dodging(S: SimState, f) -> bool:
	return f.state != "launched" and f.state != "down" and f.stunTicks <= 0 and S.tick - f.act.dodgeTick < SimAct.dodgeWindow


## After a fight's tick (SimCore._stepFights): each of its beams stops at the first enemy of another fight on its line, ahead
## of its own target, and passes the shooter's partner (Game Design). Whoever is first on the line is named on the beam
## (b.first: his warning, from that moment); when the front reaches him he takes it, by his guard, and the beam stops there
## (b.stopAt), unless he's in his dodge, when it passes him and goes on.
static func beams(S: SimState) -> void:
	if S.beams.is_empty():
		return
	SimShots._ensure()
	for b in S.beams:
		if b.A == null or b.stopAt >= 0.0 or b.A.out:
			continue
		var n: float = SimDetMath.hypot(b.ux, b.uy)
		if n <= 0.0:
			continue
		var r: float = b.w * 0.5 + SimShots.bodyR
		var lim: float = b.len
		var own = null   # its own target: the shooter's enemy in his own fight
		for g in S.fighters:
			if team(g) != team(b.A):
				own = g
		if own != null and not own.out:
			var so: float = _along(b, n, own.x, own.y + SimShots.chest, own.z, r)
			if so >= 0.0 and so <= b.len:
				lim = so   # his own target's on the line: nobody past him is first
		var first = null
		var fs: float = INF
		for D in enemies(S, team(b.A)):
			if (b.cross & bit(D)) != 0:
				continue
			var s: float = _along(b, n, D.x, D.y + SimShots.chest, D.z, r)
			if s >= 0.0 and s <= lim and s < fs:
				first = D
				fs = s
		b.first = first.keys if first != null else ""
		if first == null or b.p * b.len < fs:
			continue
		b.cross |= bit(first)
		if dodging(S, first):
			b.first = ""
			continue
		b.stopAt = fs
		send(S, "beam", b.A, first, beamDmg, {"stop": beamStop, "shake": beamShake, "big": true, "kind": "beam", "ignoreStance": not guarding(first)})


## How far along a beam a point is, when it's within r of the beam's line, across it and in depth; -1 when it isn't. The
## beam's whole length, drawn or not.
static func _along(b, n: float, x: float, y: float, z: float, r: float) -> float:
	var ux: float = b.ux / n
	var uy: float = b.uy / n
	var dx: float = SimWrap.sdx(b.ox, x)
	var dy: float = y - b.oy
	var s: float = dx * ux + dy * uy
	if s < 0.0 or absf(dx * uy - dy * ux) > r or absf(z - (b.oz + b.zs * s)) > r:
		return -1.0
	return s


## The beam of another fight whose first on the line f is now: his warning (Encounter's AI and Rendering read it). Or null.
static func warned(S: SimState, f):
	var st = S.stage
	for i in range(st.fights.size()):
		for b in (S.beams if i == st.cur else st.fights[i].beams):
			if b.first == f.keys:
				return b
	return null


## A shot of the fight in S on this tick's segment, (x - mx, y - my) to (x, y), meets an enemy of its shooter's in another
## fight: it goes over into his fight from where it met him, as a shot from outside, and his fight's rules meet it there on
## its next tick. True when it went over (the caller drops it from this fight). r is its radius and a body's.
static func shot(S: SimState, sh, mx: float, my: float, r: float) -> bool:
	var A = shooter(S, sh)
	if A == null or A.out:
		return false
	for D in enemies(S, team(A)):
		var fy: float = D.y + SimShots.chest - (sh.y - my)
		if absf(fy) > r + absf(my):
			continue
		var fx: float = SimWrap.sdx(sh.x - mx, D.x)
		if absf(fx) > r + absf(mx):
			continue
		var s: float = SimShots._closest(-fx, -fy, mx, my)
		var cx: float = mx * s - fx
		var cy: float = my * s - fy
		if cx * cx + cy * cy > r * r or absf(sh.z - D.z) > r:
			continue
		_over(S, sh, A, D, mx, my, s)
		return true
	return false


## A shot goes over into D's fight at the point where it met him: a shot from outside, flying on as it flew. A seeking shot
## flies straight on (its target was in the fight it left). Its id is new in that fight; what it had passed or been kept
## from there is forgotten.
static func _over(S: SimState, sh, A, D, mx: float, my: float, s: float) -> void:
	var r = S.stage.fights[SimStage.fightOf(S, D)]
	sh.x = SimWrap.wrap(sh.x - mx + mx * s)
	sh.y = sh.y - my + my * s
	if sh.mode == SimShots.SEEK:
		SimShots.release(S, sh)
	sh.owner = -1
	sh.from = A.keys
	sh.passed = 0
	sh.safe = -1
	sh.safeT = 0
	sh.group = 0
	r.shotSeq += 1
	sh.id = r.shotSeq
	sh.inT = S.tick
	if blind != 3:
		r.shots.append(sh)
	sent["shot"] = int(sent.get("shot", 0)) + 1


## A shot of the fight in S inside another fight's beam, as far as it's drawn, is eaten (Game Design: a beam struggle stays
## two fighters, and a third's shots are eaten).
static func eaten(S: SimState, sh, rad: float) -> bool:
	var st = S.stage
	for i in range(st.fights.size()):
		if i == st.cur:
			continue
		for b in st.fights[i].beams:
			var n: float = SimDetMath.hypot(b.ux, b.uy)
			if n <= 0.0:
				continue
			var s: float = _along(b, n, sh.x, sh.y, sh.z, b.w * 0.5 + rad)
			if s >= 0.0 and s <= b.p * b.len and (b.stopAt < 0.0 or s <= b.stopAt):
				return true
	return false


## A mine of the fight in S: an enemy of its owner's in another fight within its trigger sets it off.
static func trips(S: SimState, sh, tr: float) -> bool:
	var A = shooter(S, sh)
	if A == null or A.out:
		return false
	for D in enemies(S, team(A)):
		var ty: float = D.y + SimShots.chest - sh.y
		if absf(ty) > tr:
			continue
		var tx: float = SimWrap.sdx(sh.x, D.x)
		if tx * tx + ty * ty <= tr * tr and absf(D.z - sh.z) <= tr:
			return true
	return false


## A mine of the fight in S blows: each enemy of its owner's in another fight within rr (its radius squared) takes it.
static func blast(S: SimState, sh, rr: float) -> void:
	var A = shooter(S, sh)
	if A == null or A.out:
		return
	for D in enemies(S, team(A)):
		var dx: float = SimWrap.sdx(sh.x, D.x)
		var dy: float = D.y + SimShots.chest - sh.y
		if dx * dx + dy * dy <= rr:
			send(S, "mine", A, D, sh.dmg, {"power": sh.power})


## The hash's values: what's on its way, in the order it was sent; who's out, the team with nobody standing, the rejoins.
static func collect(S: SimState, out: Array) -> void:
	out.append(float(S.stage.mail.size()))
	for it in S.stage.mail:
		out.append(float(it.tick)); out.append(it.kind); out.append(it.from); out.append(it.to); out.append(it.dmg)
		SimHash._args(out, it.o)
	for f in SimStage.bodies(S):
		if f.out:
			out.append(f.keys)
	out.append(float(S.stage.over))
	out.append(float(S.stage.rejoined))


## SimDamage.ko, with this switch on: D falls in the fight in S. He's out for the match: inert, with what he sent across and his
## shots gone. His fight keeps its KO, and its winner steps on as a free body. True when his team has nobody standing: the
## match is over (S.stage.over is his team; SimCore.ended).
static func fallen(S: SimState, D) -> bool:
	var st = S.stage
	if blind != 4:
		D.out = true
	var keep: Array = []
	for it in st.mail:
		if it.from != D.keys and it.to != D.keys:
			keep.append(it)
	st.mail = keep
	for i in range(st.fights.size()):
		for sh in (S.shots if i == st.cur else st.fights[i].shots):
			if sh.dead:
				continue
			if i == st.cur and sh.owner >= 0 and S.fighters[sh.owner] == D:
				SimShots.end(S, sh, "life")
			elif sh.from == D.keys:
				sh.dead = true   # a shot of his gone over to another fight: dropped at its next step there
	var t: int = team(D)
	for f in SimStage.bodies(S):
		if team(f) == t and not f.out:
			return false
	st.over = t
	return true


## After the fights' tick (SimCore._stepFights): the two standing, one on each team, are rejoined once both fights are finished.
static func settle(S: SimState) -> void:
	if S.stage.over < 0:
		SimStage.rejoin(S, rejoinAfter)


## Encounter's: the middle of fight i's standing bodies on the ring, read through the stage with nothing written; -1 when
## nobody stands there.
static func middleOf(S: SimState, i: int) -> float:
	var st = S.stage
	var a = null
	var sum: float = 0.0
	var n: int = 0
	for f in (S.fighters if i == st.cur else st.fights[i].fighters):
		if f.out:
			continue
		if a == null:
			a = f
		sum += SimWrap.sdx(a.x, f.x)
		n += 1
	return -1.0 if a == null else SimWrap.wrap(a.x + sum / float(n))


## The winning team's starting slots, for the last KO's event ("p1" is slot 0): with this switch on, every body of A's team, out or
## not; in any other match, A's own.
static func winnersOf(S: SimState, A) -> Array:
	if not on(S):
		return [int(String(A.keys).substr(1)) - 1]
	var out: Array = []
	for f in SimStage.bodies(S):
		if team(f) == team(A):
			out.append(int(String(f.keys).substr(1)) - 1)
	out.sort()
	return out


## The same for NetDesync's digest.
static func digest(S: SimState) -> String:
	var v: Array = []
	collect(S, v)
	return SimHash.hashValues(v)
