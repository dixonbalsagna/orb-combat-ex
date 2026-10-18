class_name WorldInterior
## The chain inside a tower (docs/design/buildings.md section 7.3, ruled 2026-10-17; the events are Animation's ABI, docs/animation/ragdoll-physics-paper.md section 5).
##
## A power send that enters a tower's face at 15 to 60 degrees up or down goes on inside along the floors. WorldBrunt.hit starts it (begin); WorldContact.stepFighter
## calls step each live tick until it ends. A slab (a floor, or the ceiling above him) is a contact: it breaks when the send's effective tier is high enough
## for it, and a slab that holds lodges him (a bounce off a held slab is not modelled yet: Game Design's question). Each broken slab is half a link of the chain
## (houseLink); the floors go through WorldBrunt.applyFloors, so their people, the budget and the collateral token are the brunt's own.
##
## The script of slabs is a pure function of the tower and the entry (plan): it is made at the face, so a plan is always its own outcome, and the per-tick
## driver only walks it. The motion is straight legs at the speed the last contact left (no gravity, no drag: the brake is off in the chain), so a shallow send
## usually leaves by the far face before the next slab, and a steep one meets slabs.
##
## Behind a switch (brunt.json interiorChain, 0 by default): off, nothing here runs and no event or hash field exists, so every golden is unchanged. Not
## written to the sim's hash while off. Needs S.contactOn (every shipped match has it).
##
## Events (one per contact, in order, then one end), made with SimFx.contactEvent, so they carry actor, x, y, z, spd and n (the launch number):
##   interior_contact: b, floor (the slab's index, -1 for the face), kind (face, floor, ceiling, wall), nx, ny (the surface's normal on the body's side), vn (the speed into
##                     it: negative into the surface), vt (along it), keep (the speed share he keeps, 0 when he stays), punch (the slab or face broke), k (the contact's number,
##                     0 for the entry face), stop (ticks held: the entry face's only)
##   interior_end:     b, end (lodge, exit, fall_out, capped), contacts, t (seconds from the face)

# the plan's entries are Dictionaries {"slab": int, "kind": "floor" or "ceiling", "act": "hold", "break" or "through", "turn": bool}
# slab j is the floor of storey j (j from 1: the storey's bit in fmask); slab 0 is the ground; slab R = topFloor + 1 is the roof (no bit)


static func on(S: SimState) -> bool:
	return S.contactOn and int(WorldBrunt.cfg().interiorChain) == 1


## The send's effective tier 1 to 4 (a finisher reads at least as the data's specialTier).
static func effTier(by, special: bool) -> int:
	return WorldBrunt.tierIx(by.tier, special) + 1


## Does this hit start the chain? The first building of the flight, a tower, and the send at 15 to 60 degrees to the horizontal (the data's tangents).
static func eligible(S: SimState, f, b) -> bool:
	if not on(S) or f.interior != null or f.flightHits != 1 or WorldBrunt.isHouse(b) or WorldBrunt.topFloor(b) < 0:
		return false
	var c: Dictionary = WorldBrunt.cfg()
	var ax: float = absf(f.vx) / f.launchT
	if ax <= 0.0:
		return false
	var r: float = absf(f.vy) / ax
	return r >= float(c.interiorTanMin) and r <= float(c.interiorTanMax)


# ===================================================================== the plan

## The standing slab below j (0, the ground, at the lowest), or -1 for j = 0.
static func _below(b, j: int) -> int:
	if j <= 0:
		return -1
	var k: int = j - 1
	while k > 0 and not WorldBrunt.isStanding(b, k):
		k -= 1
	return k


## The standing slab above j, up to the roof slab R.
static func _above(b, j: int, R: int) -> int:
	var k: int = j + 1
	while k < R and not WorldBrunt.isStanding(b, k):
		k += 1
	return mini(k, R)


## Add one entry; false when the plan is over (the ground is reached, or the roof is broken).
static func _add(out: Array, R: int, slab: int, kind: String, act: String, turn: bool) -> bool:
	if slab < 0:
		return false
	if slab == 0:
		out.append({"slab": 0, "kind": "floor", "act": "hold", "turn": false})
		return false
	out.append({"slab": slab, "kind": kind, "act": act, "turn": turn})
	return slab < R or act == "hold"


## The slabs of the chain, in order, for a send entering at height y of tower b (ground gy) going down or up, at effective tier E.
## Below the ceiling tier: E - 1 slabs broken in the direction of travel, then the next holds and lodges him (tier 1: the first holds). From the ceiling tier
## (Orb's picture): down, the floor he is on breaks, he is thrown up off the ceiling of his storey (it breaks), and he goes down through the next floor, and the
## next holds (a finisher, tier 4, keeps breaking floors down to the contact cap); up, the ceiling breaks and turns him, then the floors break down the same way.
static func plan(b, y: float, gy: float, down: bool, E: int, c: Dictionary) -> Array:
	var fh: float = WorldBrunt.floorH(b)
	var R: int = WorldBrunt.topFloor(b) + 1
	var maxC: int = int(c.interiorMaxContacts)
	var k0: int = clampi(int(floor((y - gy) / fh)), 0, R - 1)
	var lo: int = k0
	while lo > 0 and not WorldBrunt.isStanding(b, lo):
		lo -= 1
	var up: int = _above(b, k0, R)
	var out: Array = []
	var live: bool = true
	if E < int(c.interiorCeilTier):
		var cur: int = lo if down else up
		var kind: String = "floor" if down else "ceiling"
		for i in range(E - 1):
			live = _add(out, R, cur, kind, "through", false)
			if not live:
				break
			cur = _below(b, cur) if down else _above(b, cur, R)
		if live:
			_add(out, R, cur, kind, "hold", false)
	else:
		var cur2: int = lo
		if down:
			live = _add(out, R, lo, "floor", "break", true)
			if live:
				live = _add(out, R, up, "ceiling", "break", true)
		else:
			live = _add(out, R, up, "ceiling", "break", true)
			if live:
				live = _add(out, R, lo, "floor", "break", false)
		# the floors below the one he stood on (lo is gone already): the ceiling tier going down breaks one more, a finisher fills to the cap
		var extra: int = (1 if down else 0) if E == int(c.interiorCeilTier) else maxC
		var added: int = 0
		while live and added < extra and out.size() < maxC - 1:
			cur2 = _below(b, cur2)
			if cur2 < 0:
				live = false
				break
			live = _add(out, R, cur2, "floor", "break", false)
			added += 1
		if live:
			cur2 = _below(b, cur2)
			if cur2 >= 0:
				_add(out, R, cur2, "floor", "hold", false)
	while out.size() > maxC:
		out.pop_back()
	if out.size() == maxC and out[maxC - 1].act != "hold" and out[maxC - 1].slab < R:
		out[maxC - 1].act = "hold"
		out[maxC - 1].turn = false
	return out


# ===================================================================== start

## The face is hit and the chain starts (WorldBrunt.hit, after the building took the hit and the fighter his): keep the speed share kept through the face,
## punch whether the face broke, dir the way he travels. Sets the hit-stop (the face's ticks), emits the entry contact and puts him just inside.
static func begin(S: SimState, f, b, y: float, edge: float, dir: float, by, keep: float, punch: bool) -> void:
	var c: Dictionary = WorldBrunt.cfg()
	var trav: float = f.launchT
	var gy: float = WorldStructures.baseY(S, b)
	var E: int = effTier(by, f.launchSpecial)
	var down: bool = f.vy < 0.0
	var pl: Array = plan(b, y, gy, down, E, c)
	var vxn: float = f.vx / trav
	var sp: float = SimDetMath.hypot(vxn, f.vy)
	if f.chainEvt == 0.0:
		f.chainEvt = WorldCollateral.beginEvent(S, "chain", by)   # the chain holds a collateral token: the slabs' people are charged to it, and the air brake (which stays off in a chain) reads it
	f.interior = {"b": b.idx, "dir": dir, "E": E, "k": 0, "bn": 0, "t": 0, "i": 0, "gy": gy, "R": WorldBrunt.topFloor(b) + 1, "plan": pl}
	f.aimB = -1
	var ev := SimFx.contactEvent(S, "interior_contact", f, f.x, y, sp)
	ev.b = float(b.idx)
	ev.floor = -1
	ev.kind = "face"
	ev.nx = -dir
	ev.ny = 0.0
	ev.vn = -absf(vxn)
	ev.vt = f.vy
	ev.keep = keep
	ev.punch = punch
	ev.k = 0.0
	var stopTicks: int = int(c.interiorFaceStop)
	ev.stop = stopTicks
	S.dirS.stop = SimMathx.jmax(S.dirS.stop, float(stopTicks) * SimConst.DT)
	f.vx *= keep
	f.vy *= keep
	f.x = SimWrap.wrap(edge + dir * 2.0)
	f.y = y


# ===================================================================== the tick

## One live tick of the chain (WorldContact.stepFighter calls it while f.interior is set).
static func step(S: SimState, f, dt: float) -> void:
	var s: Dictionary = f.interior
	var b = S.buildings[int(s.b)]
	var by = f.launchBy if f.launchBy != null else SimRoster.opp(S, f)
	var c: Dictionary = WorldBrunt.cfg()
	s.t += 1
	if not b.alive:
		_end(S, f, b, by, "fall_out")   # the tower went (its core): he falls with it, and the ground's own events play
		return
	if int(s.t) >= int(round(float(c.interiorCapSeconds) / SimConst.DT)):   # the cap, in whole ticks
		_end(S, f, b, by, "capped")
		return
	var dir: float = float(s.dir)
	var ox: float = f.x
	var oy: float = f.y
	var dx: float = f.vx * dt
	var dy: float = f.vy * dt
	var gy: float = float(s.gy)
	var fh: float = WorldBrunt.floorH(b)
	# the far face
	var farX: float = SimWrap.wrap(b.x + dir * b.w * 0.5)
	var frF: float = WorldBrunt.crossFrac(ox, SimWrap.wrap(ox + dx), farX, dir)
	# the next slab of the plan
	var pl: Array = s.plan
	var e = pl[int(s.i)] if int(s.i) < pl.size() else null
	var frS: float = -1.0
	if e != null and dy != 0.0:
		var h: float = gy + float(e.slab) * fh
		if e.kind == "floor":
			if f.vy < 0.0 and oy >= h and oy + dy <= h:
				frS = (oy - h) / (-dy)
		else:
			if f.vy > 0.0 and oy <= h and oy + dy >= h:
				frS = (h - oy) / dy
	if frS >= 0.0 and (frF < 0.0 or frS <= frF):
		f.x = SimWrap.wrap(ox + dx * frS)
		f.y = oy + dy * frS
		_slab(S, f, b, by, s, e)
		return
	if frF >= 0.0:
		f.x = SimWrap.wrap(ox + dx * frF)
		f.y = oy + dy * frF
		_face(S, f, b, by, s, farX, dir)
		return
	f.x = SimWrap.wrap(ox + dx)
	f.y = oy + dy
	if f.y <= gy:
		f.y = gy
		_end(S, f, b, by, "fall_out")
	elif f.y > gy + float(int(s.R)) * fh + 1.0:
		_end(S, f, b, by, "exit")   # out through the roof's line


## A contact with a slab of the plan.
static func _slab(S: SimState, f, b, by, s: Dictionary, e: Dictionary) -> void:
	var c: Dictionary = WorldBrunt.cfg()
	var trav: float = f.launchT
	var vxn: float = f.vx / trav
	var sp: float = SimDetMath.hypot(vxn, f.vy)
	if int(e.slab) == 0:
		_end(S, f, b, by, "fall_out")   # the ground floor is the ground: its events are the ground's
		return
	var isFloor: bool = e.kind == "floor"
	var ny: float = 1.0 if isFloor else -1.0
	s.k += 1
	var breaks: bool = e.act != "hold"
	var keep: float = 0.0
	if breaks:
		keep = float(c.interiorCeilKeep) if (not isFloor and e.act == "break") else float(c.interiorFloorKeep)
		_breakSlab(S, f, b, by, int(e.slab), sp)
		f.splashed.append(WorldBrunt.MARK_HOUSE)   # half a link (houseLink)
	var ev := SimFx.contactEvent(S, "interior_contact", f, f.x, f.y, sp)
	ev.b = float(b.idx)
	ev.floor = int(e.slab)
	ev.kind = String(e.kind)
	ev.nx = 0.0
	ev.ny = ny
	ev.vn = f.vy * ny
	ev.vt = vxn
	ev.keep = keep
	ev.punch = breaks
	ev.k = float(s.k)
	ev.stop = 0
	SimDamage.hurt(S, f, sp * WorldBrunt.FIGHTER_DMG * float(c.interiorHurt), by)
	if not breaks:
		_end(S, f, b, by, "lodge")
		return
	f.vx *= keep
	f.vy *= keep
	if e.turn:
		f.vy = -f.vy
	s.i += 1
	if int(e.slab) >= int(s.R):
		_end(S, f, b, by, "exit")   # through the roof: the flight goes on from there
	elif int(s.i) >= s.plan.size():
		_end(S, f, b, by, "capped")


## The slab's floor goes through the brunt's own floors machinery (people, budget, token, the pancake rule), as a punch.
static func _breakSlab(S: SimState, f, b, by, j: int, sp: float) -> void:
	if j >= b.floors or not WorldBrunt.isStanding(b, j):
		return
	var c: Dictionary = WorldBrunt.cfg()
	var dmg: float = sp * float(c.tierFactor[WorldBrunt.tierIx(by.tier, f.launchSpecial)]) * float(c.bruntMul)
	var oc: Dictionary = {"floors": true, "dmg": dmg, "ratio": maxf(dmg / WorldBrunt.floorStr(b, j), 1.0), "outcome": "punch", "k": j, "hit": [j], "pass": true, "keep": float(c.interiorFloorKeep), "deaths": 0.0}
	WorldBrunt.applyFloors(S, b, oc, by, f.chainEvt, f.x, f, f.y)


## The far face: it breaks from the exit tier (he leaves, with the floor keep), or it holds (a wall: he lodges against it).
static func _face(S: SimState, f, b, by, s: Dictionary, farX: float, dir: float) -> void:
	var c: Dictionary = WorldBrunt.cfg()
	var trav: float = f.launchT
	var vxn: float = f.vx / trav
	var sp: float = SimDetMath.hypot(vxn, f.vy)
	s.k += 1
	var breaks: bool = int(s.E) >= int(c.interiorExitTier)
	var keep: float = float(c.interiorFloorKeep) if breaks else 0.0
	var ev := SimFx.contactEvent(S, "interior_contact", f, f.x, f.y, sp)
	ev.b = float(b.idx)
	ev.floor = -1
	ev.kind = "face" if breaks else "wall"
	ev.nx = -dir
	ev.ny = 0.0
	ev.vn = -absf(vxn)
	ev.vt = f.vy
	ev.keep = keep
	ev.punch = breaks
	ev.k = float(s.k)
	ev.stop = 0
	SimDamage.hurt(S, f, sp * WorldBrunt.FIGHTER_DMG * float(c.interiorHurt), by)
	if not breaks:
		_end(S, f, b, by, "lodge")
		return
	f.vx *= keep
	f.vy *= keep
	f.x = SimWrap.wrap(farX + dir * 2.0)
	_end(S, f, b, by, "exit")


# ===================================================================== the end

## The chain is over: lodge and capped hold him where he is (the lodge's own hold, the last of his speed one more hit on the building), exit and fall_out
## hand the flight back (the brake is back; the ground's events play). Always the end event last.
static func _end(S: SimState, f, b, by, end: String) -> void:
	var s: Dictionary = f.interior
	var trav: float = f.launchT
	var spLeft: float = SimDetMath.hypot(f.vx / trav, f.vy)
	var cm: Dictionary = WorldBrunt.cfg()
	var held: bool = end == "lodge" or end == "capped"
	if held:
		var tfac: float = float(cm.tierFactor[WorldBrunt.tierIx(by.tier, f.launchSpecial)])
		var rest: float = spLeft * tfac * float(cm.bruntMul) * float(cm.lodgeDump)
		if b.alive and rest > 0.0:
			WorldStructures.damageBuilding(S, b, minf(rest, WorldStructures.coreCap() * b.maxhp), by, "burst", f.x, f.chainEvt, true)
		SimDamage.hurt(S, f, spLeft * WorldBrunt.FIGHTER_DMG, by)
		var holdS: float = WorldBrunt.lodgeSeconds(by.tier, f.launchSpecial)
		WorldBrunt._hold(S, f, holdS)
		f.vx = 0.0
		f.vy = 0.0
		SimFx.lodge(S, f, b, f.x, f.y, holdS, f.flightHits, by)
	var ev := SimFx.contactEvent(S, "interior_end", f, f.x, f.y, spLeft)
	ev.b = float(b.idx)
	ev.end = end
	ev.contacts = int(s.k)
	ev.t = float(s.t) * SimConst.DT
	f.interior = null
	WorldBrunt.endFlight(S, f)
