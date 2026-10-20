extends SceneTree
# The chain inside a tower (docs/design/buildings.md section 7.3; world/interior.gd; data/biomes/brunt.json interior*):
#   godot --headless --path . --script res://sim/world/tools/interior_check.gd [-- --show]
# A launch is made by hand (the tower, the angle, the speed, the tier) so the angle is the check's; the events are read in order.
var fails: int = 0
var show: bool = false


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func fresh(seed: int = 1) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false})
	S.out.fx.clear()
	return S


## The tallest standing tower on the plane's row.
func tower(S: SimState, lo: int = 9):
	var best = null
	for b in S.buildings:
		if b.floors >= lo and int(b.row) == 1 and b.alive and (best == null or b.floors > best.floors or (b.floors == best.floors and b.w > best.w)):
			best = b
	return best


## One launch at tower tw: effective tier `tier`, the tangent `tn` of the send above or below the horizontal, `down` its sense, `sp` the speed, entering at `frac` of the tower's height.
## Steps the flight until it lands (or the chain and the flight are over). Returns the events.
func chain(S: SimState, tw, tier: float, tn: float, down: bool, sp: float, frac: float = 0.5, special: bool = false, token: bool = true) -> Array:
	var A = S.fighters[1]
	var D = S.fighters[0]
	A.tier = tier
	A.hp = 1.0e9
	D.hp = 1.0e9
	var dir: float = 1.0
	var gy: float = WorldStructures.baseY(S, tw)
	var y: float = gy + tw.h * frac
	var edge: float = SimWrap.wrap(tw.x - dir * tw.w * 0.5)
	D.state = "launched"
	D.stateT = 0.0
	D.launchBy = A
	D.launchT = 1.0
	D.launchSpecial = special
	D.launchN += 1
	D.flightHits = 0
	D.splashed = PackedInt32Array()
	D.jContacts = 0
	D.jT = 0
	D.slide = 0.0
	D.chainEvt = WorldCollateral.beginEvent(S, "chain", A) if token else 0.0
	var vx: float = sp / sqrt(1.0 + tn * tn)
	D.vx = vx * dir
	D.vy = vx * tn * (-1.0 if down else 1.0)
	D.x = SimWrap.wrap(edge - dir * 6.0)
	D.y = y
	S.out.fx.clear()
	WorldBrunt.hit(S, D, tw, y, edge, dir)
	var ev: Array = []
	for e in S.out.fx:
		ev.append(e)
	S.out.fx.clear()
	var g: int = 0
	while D.state == "launched" and g < 900:
		S.dirS.stop = 0.0
		SimFighter.stepLaunched(S, D, SimConst.DT)
		for e in S.out.fx:
			ev.append(e)
		S.out.fx.clear()
		g += 1
		if D.interior == null and g > 400:
			break
	return ev


func S_step_once(S: SimState, D) -> void:
	S.dirS.stop = 0.0
	SimFighter.stepLaunched(S, D, SimConst.DT)
	S.out.fx.clear()


func names(ev: Array) -> String:
	var out: Array = []
	for e in ev:
		if e.type == "interior_contact":
			out.append("%s%s%s" % [e.kind, "!" if e.punch else "", "" if e.floor < 0 else str(e.floor)])
		elif e.type == "interior_end":
			out.append("END:" + e.end)
	return " ".join(out)


func shape(ev: Array) -> Dictionary:
	var cs: Array = ev.filter(func(e): return e.type == "interior_contact")
	var en: Array = ev.filter(func(e): return e.type == "interior_end")
	return {"cs": cs, "en": en}


func fingerprint(ev: Array) -> String:
	var h := SimHash.Hasher.new()
	SimHash.hashFx(h, ev.filter(func(e): return e.type == "interior_contact" or e.type == "interior_end"))
	return h.hex()


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--show":
			show = true
	var c: Dictionary = WorldBrunt.cfg()
	ok(WorldBrunt.dataErrors().is_empty(), "brunt.json loads clean (%s)" % str(WorldBrunt.dataErrors()))
	ok(int(c.interiorChain) == 0, "the switch is off in the data (interiorChain %d)" % int(c.interiorChain))
	ok(float(c.interiorCeilKeep) == 0.4 and float(c.interiorFloorKeep) == 0.7 and int(c.interiorMaxContacts) == 5 and int(c.interiorMaxBounces) == 3 and int(c.interiorFaceStop) == 15 and float(c.interiorCapSeconds) == 2.5 and int(c.interiorCeilTier) == 3,
		"Game Design's values stand in the data (keep 0.4 and 0.7, 5 contacts, 3 bounces, stop 15, cap 2.5 s, ceiling from tier 3)")
	# --- off: nothing of the chain exists
	var S0 := fresh(1)
	var tw0 = tower(S0)
	ok(tw0 != null, "there is a tower to launch at (%d floors, %.0f wide)" % [tw0.floors, tw0.w])
	var ev0: Array = chain(S0, tw0, 3.0, 1.0, true, 3000.0)
	ok(ev0.filter(func(e): return e.type == "interior_contact" or e.type == "interior_end").is_empty() and S0.fighters[0].interior == null, "switch off: no interior event, no interior state")
	c.interiorChain = 1
	# --- the tiers, a steep send (60 degrees) at the middle of a tall tower, down and up
	var seen: Dictionary = {}
	for down in [true, false]:
		for tier in [1.0, 2.0, 3.0, 4.0]:
			var S := fresh(1)
			var tw = tower(S)
			var ev: Array = chain(S, tw, tier, 1.7, down, 3500.0, 0.5)
			var sh: Dictionary = shape(ev)
			var cs: Array = sh.cs
			var en: Array = sh.en
			var tag: String = "tier %d %s" % [int(tier), "down" if down else "up"]
			seen[tag] = names(ev)
			if show:
				print("   ", tag, ": ", names(ev), "  t=", (en[0].t if en.size() > 0 else -1.0))
			ok(cs.size() >= 1 and cs[0].kind == "face" and cs[0].k == 0.0 and cs[0].stop == 15 and cs[0].nx == -1.0, "%s: the entry face first (k 0, stop 15, nx -1)" % tag)
			ok(en.size() == 1 and ev.back().type == "interior_end" or (en.size() == 1 and ev.find(en[0]) >= ev.find(cs.back())), "%s: one interior_end, after the last contact" % tag)
			var inOrder: bool = true
			for i in range(cs.size()):
				if int(cs[i].k) != i:
					inOrder = false
			ok(inOrder, "%s: the contacts are numbered 0, 1, 2 ... in order" % tag)
			ok(cs.size() - 1 <= 5 and en.size() == 1 and en[0].contacts == cs.size() - 1 and en[0].t <= 2.5001, "%s: at most 5 contacts after the face (%d), t %.2f s <= 2.5, the end counts them" % [tag, cs.size() - 1, en[0].t if en.size() > 0 else -1.0])
			var wellFormed: bool = true
			for e in cs:
				var n2: float = e.nx * e.nx + e.ny * e.ny
				if absf(n2 - 1.0) > 0.0001 or e.vn >= 0.0 or not (e.kind in ["face", "floor", "ceiling", "wall"]):
					wellFormed = false
			ok(wellFormed, "%s: every contact has a unit normal, a speed into the surface (vn < 0) and a kind of face, floor, ceiling or wall" % tag)
			for e in cs:
				if e.kind == "ceiling" and e.punch and e.k > 0.0:
					var wantK: float = 0.4 if tier >= 3.0 and e.keep != 0.7 else 0.7
					ok(e.keep == wantK and e.ny == -1.0, "%s: a ceiling that breaks keeps %.1f (0.4 turning him from tier 3, 0.7 going through below it) and its normal points down" % [tag, wantK])
				if e.kind == "floor" and e.punch:
					ok(e.keep == 0.7 and e.ny == 1.0, "%s: a floor he goes through keeps 0.7 and its normal points up" % tag)
			if tier >= 3.0:
				var hasCeil: bool = cs.any(func(e): return e.kind == "ceiling" and e.punch)
				ok(hasCeil or en[0].end in ["exit", "fall_out"], "%s: from tier 3 the ceiling is reached (or he left first: %s)" % [tag, en[0].end])
			else:
				ok(not cs.any(func(e): return e.kind == "ceiling" and e.punch and e.keep == 0.4), "%s: below tier 3 no ceiling reverses him" % tag)
			if tier == 1.0:
				ok(not cs.any(func(e): return e.k > 0.0 and e.punch and e.kind in ["floor", "ceiling"]), "%s: tier 1 breaks no slab" % tag)
			var fhits: int = ev.filter(func(e): return e.type == "floor_hit" and e.outcome == "punch").size()
			var brk: int = cs.filter(func(e): return e.k > 0.0 and e.punch and e.kind in ["floor", "ceiling"]).size()
			ok(fhits >= brk - 0, "%s: each broken slab went through the floors machinery (%d floor_hit punches for %d broken slabs)" % [tag, fhits, brk])
	# --- a held slab bounces at 900 or more between 40 and 70 degrees to it (any tier), else lodges; at most 3 bounces and 5 slab contacts
	var Sb := fresh(1)
	var evb: Array = chain(Sb, tower(Sb), 1.0, 1.7, true, 3500.0, 0.5)
	var csb: Array = shape(evb).cs
	var bounces: Array = csb.filter(func(e): return e.k > 0.0 and not e.punch and e.keep > 0.0)
	ok(bounces.size() >= 1 and bounces.size() <= 3 and bounces[0].keep == 0.45 and csb.size() - 1 <= 5 and shape(evb).en[0].end == "lodge", "a fast steep send at tier 1 bounces off the held floor (%s)" % names(evb))
	var Ss := fresh(1)
	var evs: Array = chain(Ss, tower(Ss), 1.0, 1.7, true, 800.0, 0.5)
	ok(shape(evs).cs.filter(func(e): return e.keep > 0.0 and not e.punch and e.k > 0.0).is_empty() and shape(evs).en[0].end == "lodge", "under 900 he lodges on the held floor (%s)" % names(evs))
	var Sh2 := fresh(1)
	var evh2: Array = chain(Sh2, tower(Sh2), 1.0, 0.5, true, 3500.0, 0.5)
	ok(shape(evh2).cs.filter(func(e): return e.keep > 0.0 and not e.punch and e.k > 0.0).is_empty(), "shallower than 40 degrees to the slab he lodges (%s)" % names(evh2))
	# --- the angle gate
	for tn in [0.15, 2.5]:
		var Sg := fresh(1)
		var evg: Array = chain(Sg, tower(Sg), 3.0, tn, true, 3500.0)
		ok(shape(evg).cs.is_empty(), "a send at tangent %.2f (outside 15 to 60 degrees) takes today's path" % tn)
	# --- a house is not a tower
	var Sh := fresh(1)
	var house = null
	for b in Sh.buildings:
		if b.floors < WorldBrunt.FLOORS_MIN and int(b.row) == 1:
			house = b
			break
	if house != null:
		var evh: Array = chain(Sh, house, 3.0, 1.0, true, 3500.0, 0.3)
		ok(shape(evh).cs.is_empty(), "a house takes today's path")
	# --- determinism: the same launch twice gives the same events and the same end
	var fp: Array = []
	for r in range(2):
		var Sd := fresh(1)
		var evd: Array = chain(Sd, tower(Sd), 4.0, 1.7, true, 3500.0)
		fp.append(fingerprint(evd) + "|" + names(evd) + "|" + str(SimHash.stateHash(Sd).gameplay))
	ok(fp[0] == fp[1], "the same launch twice: the same events, the same state hash (%s)" % fp[0].substr(0, 8))
	# --- a launch with no token (an unaimed or single-building flight) gets one for the chain, so the air brake stays off and the slabs' people are charged to it
	var St := fresh(1)
	var Dt = St.fighters[0]
	chain(St, tower(St), 3.0, 1.7, true, 3500.0, 0.5, false, false)
	ok(Dt.chainEvt == 0.0 and Dt.interior == null, "the token is closed when the chain ends (chainEvt %s)" % str(Dt.chainEvt))
	var St2 := fresh(1)
	var Dt2 = St2.fighters[0]
	var evt_in: float = -1.0
	Dt2.state = "launched"
	var twt = tower(St2)
	Dt2.launchBy = St2.fighters[1]
	St2.fighters[1].tier = 3.0
	Dt2.launchT = 1.0
	Dt2.chainEvt = 0.0
	Dt2.flightHits = 0
	var edge_t: float = SimWrap.wrap(twt.x - twt.w * 0.5)
	Dt2.vx = 2400.0
	Dt2.vy = -2000.0
	Dt2.x = edge_t - 6.0
	Dt2.y = WorldStructures.baseY(St2, twt) + twt.h * 0.5
	WorldBrunt.hit(St2, Dt2, twt, Dt2.y, edge_t, 1.0)
	ok(Dt2.interior != null and Dt2.chainEvt != 0.0, "a chain that starts with no token takes one (chainEvt %s)" % str(Dt2.chainEvt))
	# --- mid-chain the state hashes (the fighter's chain fields are folded in only while it runs)
	var Sm := fresh(1)
	var twm = tower(Sm)
	var Dm = Sm.fighters[0]
	var evm: Array = chain(Sm, twm, 4.0, 1.7, true, 3500.0)
	var Sm2 := fresh(1)
	var tw2 = tower(Sm2)
	Sm2.fighters[0].hp = 1.0e9
	Sm2.fighters[1].tier = 4.0
	var Dm2 = Sm2.fighters[0]
	var h_before: String = str(SimHash.stateHash(Sm2).gameplay)
	# launch by hand and stop at the first tick inside
	Dm2.state = "launched"
	Dm2.launchBy = Sm2.fighters[1]
	Dm2.launchT = 1.0
	Dm2.chainEvt = WorldCollateral.beginEvent(Sm2, "chain", Sm2.fighters[1])
	var gy2: float = WorldStructures.baseY(Sm2, tw2)
	var edge2: float = SimWrap.wrap(tw2.x - tw2.w * 0.5)
	Dm2.vx = 2400.0
	Dm2.vy = -2400.0 * 0.9
	Dm2.x = edge2 - 6.0
	Dm2.y = gy2 + tw2.h * 0.5
	Dm2.flightHits = 0
	WorldBrunt.hit(Sm2, Dm2, tw2, Dm2.y, edge2, 1.0)
	var h_in1: String = str(SimHash.stateHash(Sm2).gameplay)
	S_step_once(Sm2, Dm2)
	var h_in2: String = str(SimHash.stateHash(Sm2).gameplay)
	ok(Dm2.interior != null and h_in1 != h_before and h_in1 != h_in2, "mid-chain the state hashes and the hash moves with it (inside: %s then %s, before %s)" % [h_in1.substr(0, 8), h_in2.substr(0, 8), h_before.substr(0, 8)])
	# --- the caps hold over many towers, tiers, angles and speeds
	var rg := SimRng.new(11)
	var runs: int = 0
	var worstC: int = 0
	var worstT: float = 0.0
	var ends: Dictionary = {}
	var bad: int = 0
	var links: int = 0
	var bounced: int = 0
	for n in range(160):
		var Sr := fresh(1 + n % 6)
		var cand: Array = Sr.buildings.filter(func(b): return b.floors >= 5 and b.alive)
		if cand.is_empty():
			continue
		var twr = cand[int(rg.next() * float(cand.size()))]
		var tn2: float = 0.3 + rg.next() * 1.4
		var evr: Array = chain(Sr, twr, float(1 + n % 4), tn2, rg.next() < 0.5, 1500.0 + rg.next() * 3000.0, 0.15 + rg.next() * 0.7, n % 9 == 0)
		var shr: Dictionary = shape(evr)
		if shr.cs.is_empty():
			continue
		links += evr.filter(func(e): return e.type == "chain_link").size()
		bounced += shr.cs.filter(func(e): return e.k > 0.0 and not e.punch and e.keep > 0.0).size()
		runs += 1
		if shr.en.size() != 1:
			bad += 1
			continue
		worstC = maxi(worstC, int(shr.en[0].contacts))
		worstT = maxf(worstT, shr.en[0].t)
		ends[shr.en[0].end] = int(ends.get(shr.en[0].end, 0)) + 1
		if Sr.fighters[0].interior != null:
			bad += 1
	ok(runs > 60 and bad == 0 and worstC <= 5 and worstT <= 2.5001, "%d random chains: one end each, at most %d contacts, longest %.2f s, none left running (ends %s; %d bounces, %d links to a next tower)" % [runs, worstC, worstT, str(ends), bounced, links])
	ok(bounced > 0, "bounces happen in the random chains")
	c.interiorChain = 0
	print("INTERIOR: %d check(s) failed" % fails)
	quit()
