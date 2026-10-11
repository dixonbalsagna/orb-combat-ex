class_name VfxGhostTally
extends RefCounted
## The ghost count and budget (Legal's RL-122 and RL-125, rows f01, m05 and m12 of movegen-banned.json): every after-image on a screen, whoever draws it, counted at every instant, and
## VFX's own whole-figure ghosts held to what is left of the fighter's budget.
##
## Who draws what (2026-10-06 audit; Animation draws no ghost at all, it hands `press_pose(k)` and `press.ghosts` to VFX and keeps only the lab's path dots):
##   LIMB ghosts, f01 (at most 2 of one limb at any instant, at most 4 in all): VFX's tech echoes (a blow's, and a zip leg's) and VFX's speed smear (one a blow). The tech echoes are also whole
##   wire figures, so they take a place of the m12 budget too (counted conservatively).
##   WHOLE-FIGURE ghosts, m12 (at most 5 round one fighter from all sources together, so 10 on screen; each one keeps m05: a flat lane tint at 0.35 or less, behind him, fainter the older):
##   Rendering's after-images (the sim's `after` events, ParticleView: a dodge's, an escape's, one for each tick of a rush, each shown for RenderLook.AFTER_LIFE and only once it stands
##   24 to 60 units off the fighter), and VFX's heavy release stack (up to 5), the heavy ender's flying target (3) and a zip's speed or heavy smear (2).
## Rendering's are not VFX's to change, so they are read first: VFX's three take what is left of the five (`body_n` on a blow, `fly_n`, `zip_n`), never more than they asked for, in the order
## echoes, heavy stack, flying target, zip smear. With Rendering's alone above five nothing of VFX's is drawn, and the excess is theirs (`over_rendering`).
## Presentation only: it reads events and the other effects' state, writes nothing back to the sim.

const LIMB_MAX: int = 2         # f01: of any one limb
const LIMB_ALL_MAX: int = 4     # f01: on the screen in all
const BUDGET: int = 5           # m12: whole-figure ghosts of one fighter, all sources together
const BODY_MAX: int = BUDGET    # the old name, kept for the tests

var enforce: bool = true        # VFX's own whole-figure ghosts yield to the budget (the hub sets it; off, they draw as they always did and the tally only counts)
var record: bool = false        # tools: keep the per-ghost detail of the worst tick (owner, source, age, opacity, offset)
var after: Array = []           # [slot, ticks left, x, y, born tick]: Rendering's after-images alive
var limb_now: Dictionary = {}   # limb id -> limb-ghosts it holds now
var limb_total: int = 0
var echoes_now: Array = [0, 0]  # per slot: tech echoes alive (limb-ghosts that are also whole wire figures)
var body_now: Array = [0, 0]    # per slot: whole-figure ghosts drawn now, without the echoes (Rendering's shown after-images and VFX's three)
var total_now: Array = [0, 0]   # per slot: body_now plus the echoes: the figure m12 limits
var after_now: Array = [0, 0]   # ... of the body ghosts, Rendering's after-images that are shown (24 units or more off him)
var after_alive: Array = [0, 0] # ... Rendering's after-images alive, shown or not
var fly_n: Array = [3, 3]       # per slot: how many of the flying target's ghosts may be drawn
var zip_n: Array = [5, 5]       # per slot: how many of a zip's smear ghosts may be drawn
var zecho_n: Array = [3, 3]     # per slot: how many of his zip legs' wire echoes may be drawn
var limb_peak: int = 0          # the most limb-ghosts on the screen at any instant
var limb_peak_one: int = 0      # ... of any one limb
var body_peak: Array = [0, 0]   # the most whole-figure ghosts of one body (without echoes), by slot
var total_peak: Array = [0, 0]  # ... with the tech echoes
var after_peak: Array = [0, 0]  # ... of them Rendering's shown after-images
var asked_peak: Array = [0, 0]  # what the sources asked for before the budget (VFX's wants plus Rendering's shown and the echoes)
var all_peak: int = 0           # every ghost on the screen at one instant (for the record)
var over: Dictionary = {"limb": 0, "limb_all": 0, "body": 0, "rendering": 0}   # ticks that broke a limit ("body": over the budget with the budget applied; "rendering": Rendering's alone over it)
var ticks: int = 0
var detail: Array = [[], []]    # when `record`: this tick's ghosts by slot: {source, age, alpha, dx, dy}
var worst: Dictionary = {}      # when `record`: the tick with the most whole-figure ghosts on one fighter, before the budget ("asked"): its tick, slot, counts and detail


static func after_ticks() -> int:
	return maxi(1, int(floor(RenderLook.AFTER_LIFE / SimConst.DT + 0.001)))


func reset() -> void:
	after.clear()
	limb_now = {}
	limb_total = 0
	echoes_now = [0, 0]
	body_now = [0, 0]
	total_now = [0, 0]
	after_now = [0, 0]
	after_alive = [0, 0]
	fly_n = [3, 3]
	zip_n = [5, 5]
	zecho_n = [3, 3]
	limb_peak = 0
	limb_peak_one = 0
	body_peak = [0, 0]
	total_peak = [0, 0]
	after_peak = [0, 0]
	asked_peak = [0, 0]
	all_peak = 0
	over = {"limb": 0, "limb_all": 0, "body": 0, "rendering": 0}
	ticks = 0
	detail = [[], []]
	worst = {}


## Whose an after-image is: the fighter whose aura colour it stands in, the nearer one if both share it, else the nearest fighter (ParticleView's own rule).
static func slot_of(S: SimState, e) -> int:
	var best: int = 0
	var best_d: float = INF
	var own_found: bool = false
	var col: String = String(e.col).to_lower()
	for i in range(mini(2, S.fighters.size())):
		var own: bool = String(S.fighters[i].aura).to_lower() == col
		var d: float = absf(SimWrap.sdx(S.fighters[i].x, float(e.x)))
		if (own and not own_found) or (own == own_found and d < best_d):
			best = i
			best_d = d
			own_found = own
	return best


## How far from his fighter an after-image stands (units): ParticleView draws it only as far as he has moved off it (smoothstep from AFTER_CLEAR.x to AFTER_CLEAR.y).
static func away_of(S: SimState, slot: int, x: float, y: float) -> float:
	var f = S.fighters[slot]
	var d: float = Vector2(SimWrap.sdx(f.x, x), y - f.y).length()
	return smoothstep(RenderLook.AFTER_CLEAR.x, RenderLook.AFTER_CLEAR.y, d)


## Once per consume(), after the blows of this tick's events are made (and the press's counter has run again).
func step(S: SimState, events: Array, press: VfxPress, zip: VfxZip, frozen: bool, red: bool) -> void:
	var life: int = after_ticks()
	if not frozen:
		var i: int = 0
		while i < after.size():
			after[i][1] = int(after[i][1]) - 1
			if int(after[i][1]) <= 0:
				after.remove_at(i)
			else:
				i += 1
		for e in events:
			if e.type == "after":
				after.append([slot_of(S, e), life, float(e.x), float(e.y), S.tick])
	ticks += 1
	if record:
		detail = [[], []]
	# Rendering's: counted for their whole life, and the shown ones (away from him) apart.
	# Rendering holds at most RenderLook.AFTER_MAX round one fighter and leaves the oldest out (ParticleView), so that is the most that is drawn whatever is sent.
	var aft_alive: Array = [0, 0]
	var aft: Array = [0, 0]
	var shown_list: Array = [[], []]
	for a in after:
		var s: int = int(a[0])
		aft_alive[s] += 1
		var away: float = away_of(S, s, float(a[2]), float(a[3]))
		if away > 0.0:
			shown_list[s].append([a, away])
	for s in range(2):
		var sl: Array = shown_list[s]
		while sl.size() > RenderLook.AFTER_MAX:
			sl.pop_front()
		aft[s] = sl.size()
		if record:
			var f = S.fighters[s]
			for it in sl:
				var a2: Array = it[0]
				var age_a: int = life - int(a2[1])
				detail[s].append({"source": "after-image (Rendering)", "age": age_a, "alpha": snappedf(RenderLook.AFTER_ALPHA * (1.0 - float(age_a) / float(life)) * float(it[1]), 0.001), "dx": snappedf(SimWrap.sdx(f.x, float(a2[2])), 0.1), "dy": snappedf(float(a2[3]) - f.y, 0.1)})
	# VFX's echoes (limb-ghosts and whole wire figures) ...
	limb_now = {}
	var ech: Array = [0, 0]
	var tech_fx: Array = []     # [Fx, units]: the tech blows' echoes alive, newest last
	var zip_ech: Array = [0, 0]
	for e: VfxPress.Fx in press.fx:
		if e.ghost_ok:
			var u: int = VfxPress.limb_units(e)
			if u > 0 and red and e.style == "tech":
				u = mini(u, 1)
			if u > 0:
				limb_now[e.limb] = int(limb_now.get(e.limb, 0)) + u
				if e.style == "tech" and e.slot >= 0 and e.slot < 2:
					ech[e.slot] += u
					tech_fx.append([e, u])
	for z: VfxZip.Zip in zip.zips:
		if z.slot < 0 or z.slot > 1 or z.age < z.t1() or z.style != "tech":
			continue
		var tt: float = (z.age - z.t1()) if z.age < z.t3() else (z.age - z.t3())
		if tt >= 0.0 and tt < 12.0:
			var u2: int = VfxZip.echoes_alive(tt, int(VfxZip.p("echoes")))
			if red:
				u2 = mini(u2, 1)
			if u2 > 0:
				limb_now[z.slot * 2] = int(limb_now.get(z.slot * 2, 0)) + u2
				ech[z.slot] += u2
				zip_ech[z.slot] += u2
	# ... and what its three whole-figure sources ask for.
	var want_zip: Array = [0, 0]
	var want_fly: Array = [0, 0]
	var heavies: Array = []     # the heavy release stacks, newest last
	if not red:
		for s in range(2):
			if float(press.fly[s]) > 0.0:
				want_fly[s] = int(VfxPress.p("fly_ghosts"))
	for e: VfxPress.Fx in press.fx:
		if e.style == "heavy" and not red and e.slot >= 0 and e.slot < 2 and e.age < VfxPress.p("ghost_life"):
			heavies.append(e)
	for z: VfxZip.Zip in zip.zips:
		if z.slot < 0 or z.slot > 1 or z.age < z.t1() or z.style == "tech":
			continue
		var out_phase: bool = z.age >= z.t3() and z.age < z.t4() and not z.stopped
		if (z.age < z.t2() or out_phase) and not (z.stopped and z.age >= z.t2()):
			want_zip[z.slot] += 1 if red else mini(int(VfxZip.p("ghosts")), 5)
	var heavy_want: Array = [0, 0]
	for e: VfxPress.Fx in heavies:
		heavy_want[e.slot] += mini(e.ghosts if e.ghosts > 0 else 3, 5)
	# The budget: what is left of the five after Rendering's shown after-images and the echoes goes to the heavy stack, the flying target, the zip's smear, in that order.
	var asked: Array = [0, 0]
	var body: Array = [0, 0]
	for s in range(2):
		asked[s] = int(aft[s]) + int(ech[s]) + int(heavy_want[s]) + int(want_fly[s]) + int(want_zip[s])
		var left: int = maxi(0, BUDGET - int(aft[s])) if enforce else 99
		# Echoes first (they are the blow itself), the press's tech blows newest first, then his zip legs'.
		var egiven: int = 0
		for i in range(tech_fx.size() - 1, -1, -1):
			var te: VfxPress.Fx = tech_fx[i][0]
			if te.slot != s:
				continue
			var eg: int = mini(int(tech_fx[i][1]), left)
			te.echo_n = eg if enforce else -1
			left -= eg
			egiven += eg
			if record and eg > 0:
				detail[s].append({"source": "tech echo x%d (VFX)" % eg, "age": snappedf(te.age, 0.1), "alpha": snappedf(VfxPress.p("alpha"), 0.01), "dx": snappedf(-te.dir * te.lunge * 0.5, 0.1), "dy": 0.0})
		var zg0: int = mini(int(zip_ech[s]), left)
		zecho_n[s] = zg0 if enforce else 3
		left -= zg0
		egiven += zg0
		if record and zg0 > 0:
			detail[s].append({"source": "zip-leg echo x%d (VFX)" % zg0, "age": 0.0, "alpha": 0.9, "dx": 0.0, "dy": 0.0})
		ech[s] = egiven
		var gh: int = 0
		for i in range(heavies.size() - 1, -1, -1):
			var h: VfxPress.Fx = heavies[i]
			if h.slot != s:
				continue
			var give: int = mini(mini(h.ghosts if h.ghosts > 0 else 3, 5), left)
			h.body_n = give if enforce else -1
			left -= give
			gh += give
			if record:
				for k in range(give):
					var fr: float = float(k + 1) / float(give + 1)
					detail[s].append({"source": "heavy release stack %d of %d (VFX)" % [k + 1, give], "age": snappedf(h.age, 0.1), "alpha": snappedf(VfxZip.p("ghost_alpha") * float(k + 1) / float(maxi(give, 1)) * (1.0 - clampf(h.age / VfxPress.p("ghost_life"), 0.0, 1.0)), 0.001), "dx": snappedf(-h.dir * h.lunge * (1.0 - fr) * 1.3, 0.1), "dy": 0.0})
		fly_n[s] = mini(int(want_fly[s]), left) if enforce else int(want_fly[s])
		left -= int(fly_n[s]) if enforce else 0
		gh += int(fly_n[s])
		if record:
			for k in range(1, int(fly_n[s]) + 1):
				var hp: Vector2 = press.back(S, s, k * 4)
				detail[s].append({"source": "flying target's ghost %d (VFX)" % k, "age": k * 4, "alpha": snappedf(0.34 - 0.09 * float(k), 0.001), "dx": snappedf(SimWrap.sdx(S.fighters[s].x, hp.x), 0.1), "dy": snappedf(hp.y - S.fighters[s].y, 0.1)})
		zip_n[s] = mini(int(want_zip[s]), left) if enforce else 5
		var zg: int = mini(int(want_zip[s]), int(zip_n[s]))
		gh += zg
		if record and zg > 0:
			var tpts: Array = VfxZip.trail_points(press.hist[s], VfxZip.p("ghost_gap"), zg)
			for g in range(tpts.size()):
				var tp: Vector2 = tpts[g]
				detail[s].append({"source": "zip smear ghost %d of %d (VFX)" % [g + 1, tpts.size()], "age": 0, "alpha": snappedf(VfxZip.p("ghost_alpha") * (1.0 - float(g) / float(maxi(zg, 1))), 0.001), "dx": snappedf(SimWrap.sdx(S.fighters[s].x, tp.x), 0.1), "dy": snappedf(tp.y - S.fighters[s].y, 0.1)})
		body[s] = int(aft[s]) + gh
	limb_total = 0
	var one: int = 0
	for k in limb_now:
		limb_total += int(limb_now[k])
		one = maxi(one, int(limb_now[k]))
	echoes_now = ech
	body_now = body
	after_now = aft
	after_alive = aft_alive
	var tot: Array = [int(body[0]) + int(ech[0]), int(body[1]) + int(ech[1])]
	total_now = tot
	limb_peak = maxi(limb_peak, limb_total)
	limb_peak_one = maxi(limb_peak_one, one)
	for s in range(2):
		body_peak[s] = maxi(int(body_peak[s]), int(body[s]))
		total_peak[s] = maxi(int(total_peak[s]), int(tot[s]))
		after_peak[s] = maxi(int(after_peak[s]), int(aft[s]))
		asked_peak[s] = maxi(int(asked_peak[s]), int(asked[s]))
	all_peak = maxi(all_peak, limb_total + int(body[0]) + int(body[1]))
	if one > LIMB_MAX:
		over["limb"] = int(over["limb"]) + 1
	if limb_total > LIMB_ALL_MAX:
		over["limb_all"] = int(over["limb_all"]) + 1
	if int(tot[0]) > BUDGET or int(tot[1]) > BUDGET:
		over["body"] = int(over["body"]) + 1
	if int(aft[0]) > BUDGET or int(aft[1]) > BUDGET:
		over["rendering"] = int(over["rendering"]) + 1
	if record:
		for s in range(2):
			if int(asked[s]) > int(worst.get("asked", 0)):
				worst = {"tick": S.tick, "slot": s, "asked": int(asked[s]), "drawn": int(tot[s]), "rendering_shown": int(aft[s]), "rendering_alive": int(aft_alive[s]), "echoes": int(ech[s]),
					"vfx_asked": {"heavy": int(heavy_want[s]), "flying_target": int(want_fly[s]), "zip": int(want_zip[s])}, "entries": (detail[s] as Array).duplicate(true),
					"fighter": {"x": S.fighters[s].x, "y": S.fighters[s].y}}


## The record for a test or a tool: peaks and the ticks that broke a limit.
func summary() -> Dictionary:
	return {"limb_peak": limb_peak, "limb_peak_one": limb_peak_one, "body_peak": body_peak.duplicate(), "total_peak": total_peak.duplicate(), "after_peak": after_peak.duplicate(), "asked_peak": asked_peak.duplicate(),
		"all_peak": all_peak, "over": over.duplicate(), "ticks": ticks}
