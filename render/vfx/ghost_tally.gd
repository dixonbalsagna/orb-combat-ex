class_name VfxGhostTally
extends RefCounted
## The combined ghost count (Legal's RL-122 condition on the staggered echo): every after-image on a screen, whoever draws it, counted at every instant and checked against the two limits Legal set.
##
## Who draws what (2026-10-06 audit; Animation draws no ghost at all, it hands `press_pose(k)` and `press.ghosts` to VFX and keeps only the lab's path dots):
##   LIMB ghosts, Legal's f01 (at most 2 of one limb at any instant, at most 4 in all): VFX's tech echoes (a blow's, and a zip leg's), VFX's speed smear (one a blow).
##   BODY ghosts, Legal's m05 (a flat lane tint at 0.35 or less, at most 5 of one body): VFX's heavy release stack (up to 5), the heavy ender's flying target (3), a zip's speed or heavy smear
##   (2), and Rendering's after-images of the sim's `after` events (ParticleView: a dodge's, an escape's, and one for each tick of a rush, each shown for RenderLook.AFTER_LIFE).
## Rendering's are counted from the same `after` events it draws from, attributed to the fighter in whose colour they stand (else the nearest), and counted for their whole life, so the
## figure is an upper bound (ParticleView shows one only while the fighter has moved off the spot).
## Presentation only: it reads events and the other effects' state, writes nothing back.

const LIMB_MAX: int = 2         # f01: of any one limb
const LIMB_ALL_MAX: int = 4     # f01: on the screen in all
const BODY_MAX: int = 5         # m05: of one body

var after: Array = []           # [slot, ticks left]: Rendering's after-images alive
var limb_now: Dictionary = {}   # limb id -> limb-ghosts it holds now
var limb_total: int = 0
var body_now: Array = [0, 0]    # per slot: body ghosts (VFX's and Rendering's) now
var after_now: Array = [0, 0]   # ... of them Rendering's after-images
var limb_peak: int = 0          # the most limb-ghosts on the screen at any instant
var limb_peak_one: int = 0      # ... of any one limb
var body_peak: Array = [0, 0]   # the most body ghosts of one body, by slot
var after_peak: Array = [0, 0]  # ... of them Rendering's
var all_peak: int = 0           # every ghost on the screen at one instant (for the record)
var over: Dictionary = {"limb": 0, "limb_all": 0, "body": 0}   # ticks that broke a limit
var ticks: int = 0


static func after_ticks() -> int:
	return maxi(1, int(floor(RenderLook.AFTER_LIFE / SimConst.DT + 0.001)))


func reset() -> void:
	after.clear()
	limb_now = {}
	limb_total = 0
	body_now = [0, 0]
	after_now = [0, 0]
	limb_peak = 0
	limb_peak_one = 0
	body_peak = [0, 0]
	after_peak = [0, 0]
	all_peak = 0
	over = {"limb": 0, "limb_all": 0, "body": 0}
	ticks = 0


## Whose an after-image is: the fighter whose aura colour it stands in, the nearer one if both share it, else the nearest fighter.
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


## Once per consume(), after the blows of this tick's events are made (and the press's counter has run again).
func step(S: SimState, events: Array, press: VfxPress, zip: VfxZip, frozen: bool, red: bool) -> void:
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
				after.append([slot_of(S, e), after_ticks()])
	ticks += 1
	limb_now = {}
	var body: Array = [0, 0]
	var aft: Array = [0, 0]
	for a in after:
		aft[int(a[0])] += 1
		body[int(a[0])] += 1
	for e: VfxPress.Fx in press.fx:
		if e.ghost_ok:
			var u: int = VfxPress.limb_units(e)
			if u > 0 and red and e.style == "tech":
				u = mini(u, 1)
			if u > 0:
				limb_now[e.limb] = int(limb_now.get(e.limb, 0)) + u
		if e.style == "heavy" and not red and e.slot >= 0 and e.slot < 2 and e.age < VfxPress.p("ghost_life"):
			body[e.slot] += mini(e.ghosts if e.ghosts > 0 else 3, 5)
	if not red:
		for s in range(2):
			if float(press.fly[s]) > 0.0:
				body[s] += int(VfxPress.p("fly_ghosts"))
	for z: VfxZip.Zip in zip.zips:
		if z.slot < 0 or z.slot > 1 or z.age < z.t1():
			continue
		var out_phase: bool = z.age >= z.t3() and z.age < z.t4() and not z.stopped
		if z.style == "tech":
			var tt: float = (z.age - z.t1()) if z.age < z.t3() else (z.age - z.t3())
			if tt >= 0.0 and tt < 12.0:
				var u2: int = VfxZip.echoes_alive(tt, int(VfxZip.p("echoes")))
				if red:
					u2 = mini(u2, 1)
				if u2 > 0:
					limb_now[z.slot * 2] = int(limb_now.get(z.slot * 2, 0)) + u2
		elif (z.age < z.t2()) or out_phase:
			if not (z.stopped and z.age >= z.t2()):
				body[z.slot] += 1 if red else mini(int(VfxZip.p("ghosts")), 5)
	limb_total = 0
	var one: int = 0
	for k in limb_now:
		limb_total += int(limb_now[k])
		one = maxi(one, int(limb_now[k]))
	body_now = body
	after_now = aft
	limb_peak = maxi(limb_peak, limb_total)
	limb_peak_one = maxi(limb_peak_one, one)
	for s in range(2):
		body_peak[s] = maxi(int(body_peak[s]), int(body[s]))
		after_peak[s] = maxi(int(after_peak[s]), int(aft[s]))
	all_peak = maxi(all_peak, limb_total + int(body[0]) + int(body[1]))
	if one > LIMB_MAX:
		over["limb"] = int(over["limb"]) + 1
	if limb_total > LIMB_ALL_MAX:
		over["limb_all"] = int(over["limb_all"]) + 1
	if int(body[0]) > BODY_MAX or int(body[1]) > BODY_MAX:
		over["body"] = int(over["body"]) + 1


## The record for a test or a tool: peaks and the ticks that broke a limit.
func summary() -> Dictionary:
	return {"limb_peak": limb_peak, "limb_peak_one": limb_peak_one, "body_peak": body_peak.duplicate(), "after_peak": after_peak.duplicate(), "all_peak": all_peak, "over": over.duplicate(), "ticks": ticks}
