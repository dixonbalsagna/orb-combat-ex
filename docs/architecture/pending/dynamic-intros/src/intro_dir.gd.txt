class_name DirIntro
## The intro's composer (docs/director/dynamic-intros-plan.md; docs/architecture/intro-phase.md). When a match that plays
## an intro starts, it picks the scenario (a template of data/fight/intro.json), who arrives first, the gap between the
## arrivals and the part that fills each slot. SimIntro (sim/core/intro.gd) plays what it picks.
##
## Every pick is a keyed draw on the match seed (SimRng.keyed), so S.rng is not read, no stream shifts and a replay
## composes the same intro. Whatever is picked, the state at the clock is the same, so a fight does not depend on it.
## Each pick comes back with its reason, which SimIntro writes to the feed on the first pre-clock tick.
##
## The host's facts about the pair (Narrative's plotlines, docs/narrative/dynamic-intros.md section 11) bend the picks
## through five flat keys: weights (the scenario's draw), gap, look (a part), clock and gestures. The grammar that makes
## them stays on the host's side; nothing here knows a plot.

## req is the setup's "intro" record (SimIntro.setup): it may fix "scenario", "order" (the slot that arrives first) and
## "gap"; "avoid" lists the template ids played lately, the newest first (the host's no-repeat list); "classic": true
## asks for the classic opening. "facts" may hold: tones (the tones the pair allows), weights ({template id: multiplier},
## 1 when left out), gap (-1 to 1: the drawn gap moves that share of the way to the short or the long end of the
## template's range), look (a part id, taken by any slot whose pool holds it), clock (ticks added to the template's
## length, inside intro.json's clockBend, and dropped if the intro no longer fits), gestures ([{at, who, intent}]: at is
## land_first, land_second, wait, look_start or look_end; who is first, second, left, right or both), plot (an id, for
## the feed). Other keys are not read.
## Returns {"scenario": the template's index, "first": a slot, "gap": ticks, "picks": the parts (SimIntro.flatten),
## "clock": the intro's length, "gestures": [[tick, slot, intent, point]] in time order, "notes": [[tag, text]] for the feed}.
static func compose(S: SimState, req: Dictionary) -> Dictionary:
	var T: Array = SimIntro.templates
	var seed: int = int(S.game.seed)
	var left: int = SimIntro.leftSlot(S)
	var notes: Array = []
	if req.get("classic", false) == true:
		var ci: int = SimIntro.classicI
		notes.append(["INTRO: " + T[ci].id, "the classic opening was asked for: the left spot first, the default gap"])
		return {"scenario": ci, "first": left, "gap": T[ci].gapDef, "picks": 0, "clock": T[ci].clock, "gestures": [], "notes": notes}
	var facts = req.get("facts", {})
	if not (facts is Dictionary):
		facts = {}
	if String(facts.get("plot", "")) != "":
		notes.append(["INTRO plot: " + String(facts.plot), "the host's facts about the pair"])
	# the scenario: the one asked for, or a draw by weight among those whose tone the pair allows. The facts' weights
	# multiply; one played lately weighs less by each use (1 / (1 + uses)); one marked notTwice is passed over right
	# after itself.
	var ti: int = -1
	var why: String = ""
	if req.has("scenario"):
		for i in range(T.size()):
			if T[i].id == String(req.scenario):
				ti = i
		why = "asked for by the setup" if ti >= 0 else ""
	if ti < 0:
		var avoid = req.get("avoid", [])
		if not (avoid is Array):
			avoid = []
		var tones = facts.get("tones")
		var fw = facts.get("weights")
		var w := PackedFloat64Array()
		var total: float = 0.0
		var fit: int = 0
		var less: Array = []
		for i in range(T.size()):
			var x: float = T[i].weight
			if tones is Array and not tones.has(T[i].tone):
				x = 0.0
			if fw is Dictionary and (fw.get(T[i].id) is float or fw.get(T[i].id) is int):
				x *= maxf(0.0, float(fw[T[i].id]))
				if x > 0.0 and float(fw[T[i].id]) != 1.0:
					less.append("%s x%s (the facts)" % [T[i].id, str(float(fw[T[i].id]))])
			if x > 0.0:
				fit += 1
				var uses: int = avoid.count(T[i].id)
				if uses > 0 and T[i].notTwice and String(avoid[0]) == T[i].id:
					x = 0.0
					less.append(T[i].id + " passed over (played last)")
				elif uses > 0:
					x /= float(1 + uses)
					less.append("%s at 1/%d (played lately)" % [T[i].id, 1 + uses])
			w.append(x)
			total += x
		if total <= 0.0:
			ti = SimIntro.classicI
			why = "nothing else fits"
		else:
			var u: float = SimRng.keyed(seed, "intro.scenario", 0) * total
			var acc: float = 0.0
			for i in range(T.size()):
				if w[i] <= 0.0:
					continue
				ti = i   # (the last with a weight, should rounding leave u at the very top)
				acc += w[i]
				if u < acc:
					break
			why = "%d of %d fit" % [fit, T.size()] + ("" if less.is_empty() else "; " + ", ".join(less))
	var tp: Dictionary = T[ti]
	notes.append(["INTRO: " + tp.id, why])
	# who arrives first: the slot asked for, or an even draw
	var first: int = left
	var req1 = req.get("order")
	if (req1 is int or req1 is float) and (int(req1) == 0 or int(req1) == 1):
		first = int(req1)
		why = "asked for by the setup"
	else:
		first = left if SimRng.keyed(seed, "intro.order", 0) < 0.5 else 1 - left
		why = "an even draw"
	# the gap between the first landing and the second fall: asked for, or drawn in the template's range and then moved
	# by the facts toward its short end (below 0) or its long end (above 0)
	var gap: int = tp.gapDef
	var reqG = req.get("gap")
	if reqG is int or reqG is float:
		gap = clampi(int(reqG), tp.gapMin, tp.gapMax)
	else:
		gap = mini(tp.gapMax, tp.gapMin + int(floor(SimRng.keyed(seed, "intro.gap", 0) * float(tp.gapMax - tp.gapMin + 1))))
		var gb = facts.get("gap")
		if gb is float or gb is int:
			var b: float = clampf(float(gb), -1.0, 1.0)
			var to: float = float(tp.gapMin) if b < 0.0 else float(tp.gapMax)
			gap = clampi(int(floor(float(gap) + (to - float(gap)) * absf(b) + 0.5)), tp.gapMin, tp.gapMax)
			if b != 0.0:
				why += "; the facts move the gap %s" % ("shorter" if b < 0.0 else "longer")
	notes.append(["INTRO first: " + S.fighters[first].name, why + "; the gap is %d ticks (%d to %d)" % [gap, tp.gapMin, tp.gapMax]])
	# each slot's part: the part the facts name when the pool holds it; else an even keyed draw, or the pool's first part
	# for a slot that is not drawn
	var look: String = String(facts.get("look", ""))
	var picks: int = 0
	var mul: int = 1
	for si in range(tp.slots.size()):
		var sl: Dictionary = tp.slots[si]
		var n: int = sl.pool.size()
		var pick: int = 0
		var how: String = ""
		if look != "" and sl.pool.has(look):
			pick = sl.pool.find(look)
			how = "the facts' look"
		elif n > 1 and sl.draw:
			pick = mini(n - 1, int(floor(SimRng.keyed(seed, "intro.part", si) * float(n))))
			how = "of %d" % n
		if n > 1:
			notes.append(["INTRO slot %d: %s" % [si, sl.pool[pick]], how if how != "" else "the slot's own"])
		picks += pick * mul
		mul *= n
	var tl: Dictionary = SimIntro.flatten(ti, gap, picks)
	# the length: the template's, bent by the facts inside the data's range, while the intro still fits
	var clock: int = tp.clock
	var cb = facts.get("clock")
	if cb is float or cb is int:
		var want: int = tp.clock + clampi(int(cb), SimIntro.clockBend[0], SimIntro.clockBend[1])
		if want >= tl.need and want > SimIntro.skipFrom:
			clock = want
			if clock != tp.clock:
				notes.append(["INTRO length: %d ticks" % clock, "the facts move it by %d" % (clock - tp.clock)])
		else:
			notes.append(["INTRO length: %d ticks" % clock, "the facts' %d was dropped: the intro needs %d" % [int(cb), tl.need]])
	# the facts' gestures, each at its point
	var gestures: Array = []
	var gj = facts.get("gestures")
	if gj is Array:
		var dropped: int = 0
		for g in gj:
			if not (g is Dictionary) or gestures.size() >= SimIntro.MAX_GESTURES:
				dropped += 1
				continue
			var at: String = String(g.get("at", ""))
			var intent: String = String(g.get("intent", ""))
			var role: int = SimIntro.ROLES.get(String(g.get("who", "")), SimIntro.OWN)
			var anchor: int = -1
			if at == "land_first":
				anchor = tl.land[0]
			elif at == "land_second":
				anchor = tl.land[1]
			elif at == "wait":
				anchor = tl.wait
			elif at == "look_start":
				anchor = tl.staredown
			elif at == "look_end":
				anchor = clock
			var gt: int = anchor + int(SimIntro.points.get(at, 0))
			if anchor < 0 or intent == "" or role == SimIntro.OWN or gt < 0 or gt >= clock:
				dropped += 1   # a point this template does not have, or a gesture with no room: skipped
				continue
			var whoSlots: Array = [0, 1] if role == SimIntro.BOTH else [_slot(role, first, left)]
			for k in whoSlots:
				var ins: int = gestures.size()
				while ins > 0 and gestures[ins - 1][0] > gt:
					ins -= 1
				gestures.insert(ins, [gt, k, intent, at])
		if not gestures.is_empty() or dropped > 0:
			notes.append(["INTRO gestures: %d" % gestures.size(), "from the facts" + ("" if dropped == 0 else "; %d skipped (no such point here, or no room)" % dropped)])
	return {"scenario": ti, "first": first, "gap": gap, "picks": picks, "clock": clock, "gestures": gestures, "notes": notes}


## The slot a role names, given who arrives first and who stands on the left spot.
static func _slot(role: int, first: int, left: int) -> int:
	if role == SimIntro.FIRST:
		return first
	if role == SimIntro.SECOND:
		return 1 - first
	if role == SimIntro.LEFT:
		return left
	return 1 - left
