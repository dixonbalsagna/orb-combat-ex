

## Forms (hero-forms.md sections 4 and 4b; docs/architecture/forms-core.md). Off (the committed switch), a match has no
## form state and a replay carries no forms data. On: the Protagonist's five steps come ready at their powers and his tier
## for the world steps at three of them; steps that come ready while he waits are banked, and one release takes them all,
## none lost; the coil fills a point a second, twice that a tier behind, and a point for every 20 traded, to its max;
## patience; a release with a coil adds the surge, the armour and the lasting gain by its share and spends the coil; the
## gains, and today's for a fighter without steps; a release of live steps never pauses; the hold and the release are
## told, for a fighter without steps too; a forms match replays, with the forms data in its data hash.
func _forms() -> String:
	if not SimForms.errors().is_empty():
		return "the forms data: " + "; ".join(SimForms.errors())
	if SimForms.enabled():
		return "forms are on in the committed data"
	var d0: String = SimReplay.dataHash()
	if SimReplay.dataHash({"forms": false}) != d0 or SimReplay.dataHash({"forms": true}) == d0:
		return "the forms data is not in a replay's data hash exactly when forms are on"
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 5, {"p1": false, "p2": false})
	if S0.formsOn or S0.fighters[0].form != null or S0.fighters[0].fd != null:
		return "a match without forms has form state"
	SimCore.dispose(S0)
	var dt: float = SimConst.DT
	# the five steps, taken one at a time
	var M := SimCore.createSim()
	SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"forms": true})
	var p = M.fighters[0]
	var r = M.fighters[1]
	if not M.formsOn or p.fd == null or r.fd != null or p.form == null or r.form == null:
		return "forms on: the Protagonist takes no steps of his own, or the rival does, or a fighter has no form state"
	if p.id != "PROTAGONIST" or p.fd.steps.size() != 5:
		return "forms on: slot 0 is %s with %d steps" % [p.id, p.fd.steps.size()]
	M.out.fx.clear()
	for w in [[19.9, 0, 1.0], [20.0, 1, 1.0], [35.0, 2, 2.0], [50.0, 3, 2.0], [65.0, 4, 3.0], [100.0, 5, 4.0]]:
		p.power = w[0]
		SimForms.readyTick(M, p, dt)
		if int(w[1]) > p.form.step:
			if not p.act.formReady or p.form.ready != int(w[1]) - p.form.step:
				return "at power %s: not ready for one step (ready %d)" % [str(w[0]), p.form.ready]
			if not SimFighter.transform(M, p):
				return "at power %s: the step was not taken" % str(w[0])
		elif p.act.formReady:
			return "at power %s: ready with no step to take" % str(w[0])
		if p.form.step != int(w[1]) or p.tier != float(w[2]):
			return "at power %s: step %d at tier %s, not %d at %s" % [str(w[0]), p.form.step, str(p.tier), int(w[1]), str(w[2])]
	var nUp: int = 0
	var nStep: int = 0
	var nRel: int = 0
	for e in M.out.fx:
		nUp += 1 if e.type == "tier_up" else 0
		nStep += 1 if e.type == "form_step" else 0
		nRel += 1 if e.type == "form_release" else 0
	if nUp != 3 or nStep != 5 or nRel != 5:
		return "five steps sent %d tier_up, %d form_step and %d form_release (3, 5 and 5)" % [nUp, nStep, nRel]
	if p.form.lasting != 1.0 or p.form.surgeT != 0:
		return "a step taken at once carried a release's extras"
	if SimForms.speedMul(M, p) != 1.0 + p.fd.gSpeed * 5.0 * p.form.lasting or SimForms.damageMul(M, p) != 1.0 + p.fd.gDamage * 5.0 * p.form.lasting:
		return "the speed or damage gain at five steps"
	if SimForms.launchMul(M, p) != 1.0 + p.fd.gLaunch * 5.0 * p.form.lasting or SimForms.recoverAfter(M, p, 0.3) != 0.3 * (1.0 - p.fd.gRecover * 5.0 * p.form.lasting):
		return "the launch or recovery gain at five steps"
	if SimForms.speedMul(M, r) != 1.0 + r.ld.speed * (r.tier - 1.0) or SimForms.damageMul(M, r) != 1.0 + r.ld.damage * (r.tier - 1.0) or SimForms.launchMul(M, r) != 1.0 + r.ld.launch * (r.tier - 1.0) or SimForms.recoverAfter(M, r, 0.3) != 0.3:
		return "a fighter without steps reads other than today's gains"
	if SimForms.taken(M, p, 10.0, "guard") != 10.0 * (1.0 - p.fd.gChip * 5.0 * p.form.lasting):
		return "the guard's step gain"
	SimCore.dispose(M)
	# banked: four steps ready at 65 while he waits, a fifth at 100; one release takes all five
	var B := SimCore.createSim()
	SimCore.newMatch(B, 5, {"p1": false, "p2": false}, {"forms": true})
	p = B.fighters[0]
	r = B.fighters[1]
	B.out.fx.clear()
	p.power = 65.0
	var coil: float = 0.0
	for t in range(120):
		SimForms.readyTick(B, p, dt)
		SimForms.holdTick(B, p)
		coil = SimMathx.jmin(100.0, coil + p.fd.coilPerSec * 1.0 * dt)
	if p.form.ready != 4 or not p.act.formReady or p.form.step != 0 or p.form.coil != coil:
		return "at power 65, waiting: ready %d, step %d, coil %s (want 4, 0, %s)" % [p.form.ready, p.form.step, str(p.form.coil), str(coil)]
	r.tier = 3.0   # the rival two tiers above: the coil runs at double, and patience holds
	for t in range(60):
		SimForms.readyTick(B, p, dt)
		SimForms.holdTick(B, p)
		coil = SimMathx.jmin(100.0, coil + p.fd.coilPerSec * 2.0 * dt)
	if p.form.coil != coil:
		return "the coil two tiers behind: %s, not %s" % [str(p.form.coil), str(coil)]
	var m2: float = 1.0 - SimMathx.jmin(0.12, 0.04 * 2.0)
	if SimForms.taken(B, p, 10.0, "spread") != 10.0 * m2:
		return "patience two tiers behind: %s of 10" % str(SimForms.taken(B, p, 10.0, "spread"))
	SimDamage.hurt(B, p, 20.0, r)
	coil = SimMathx.jmin(100.0, coil + (20.0 * m2) * p.fd.coilPerDamage * 2.0)
	if p.form.coil != coil:
		return "the coil from damage traded: %s, not %s" % [str(p.form.coil), str(coil)]
	p.power = 100.0
	SimForms.readyTick(B, p, dt)
	SimForms.holdTick(B, p)
	coil = SimMathx.jmin(100.0, coil + p.fd.coilPerSec * 2.0 * dt)
	var holds: Array = []
	for e in B.out.fx:
		if e.type == "form_hold":
			holds.append(int(e.n))
	if holds != [4, 5] or p.form.ready != 5 or p.form.coil != coil:
		return "the hold was told %s, with %d ready (want [4, 5] and 5)" % [str(holds), p.form.ready]
	var c: float = p.form.coil
	B.out.fx.clear()
	if not SimFighter.transform(B, p) or p.form.step != 5 or p.tier != 4.0 or p.act.formReady or p.form.ready != 0:
		return "the release did not take all five banked steps: step %d at tier %s" % [p.form.step, str(p.tier)]
	var rel = null
	var stepE = null
	var ups: int = 0
	for e in B.out.fx:
		if e.type == "form_release":
			rel = e
		elif e.type == "form_step":
			stepE = e
		elif e.type == "tier_up":
			ups += 1
	if rel == null or int(rel.n) != 5 or rel.amount != c or int(rel.k) != 5 or rel.tier != 4.0 or ups != 1 or stepE == null or stepE.amount != c or int(stepE.k) != 5:
		return "the release's events: a form_release of 5 with the coil, one tier_up and a form_step at 5"
	var share: float = c / 100.0
	if p.form.coil != 0.0 or p.form.coiling or p.form.surgeT != 600 or p.form.surgeMul != 1.0 + 0.15 * share:
		return "the release's surge, or the coil not spent"
	if p.form.armour != int(SimMathx.jround(3.0 * share)) or p.form.lasting != SimMathx.jmin(1.5, SimMathx.jmax(1.0, 1.0 + c * 0.005)):
		return "the release's armour (%d) or lasting gain (%s) at a coil of %s" % [p.form.armour, str(p.form.lasting), str(c)]
	if SimForms.speedMul(B, p) != (1.0 + p.fd.gSpeed * 5.0 * p.form.lasting) * p.form.surgeMul:
		return "the surge's speed"
	for t in range(600):
		SimForms.readyTick(B, p, dt)
	if p.form.surgeT != 0 or p.form.surgeMul != 1.0 or SimForms.speedMul(B, p) != 1.0 + p.fd.gSpeed * 5.0 * p.form.lasting:
		return "the surge did not end after its ticks"
	var a0: int = p.form.armour
	SimForms.useArmour(B, p)
	if a0 > 0 and p.form.armour != a0 - 1:
		return "an armoured blow was not spent"
	p.form.coiling = true
	SimForms.traded(B, p, null, 100000.0)
	if p.form.coil != 100.0:
		return "the coil passed its max: %s" % str(p.form.coil)
	SimCore.dispose(B)
	# the coil starts at the first break after the step came ready: inside an exchange it coils nothing
	var X := SimCore.createSim()
	SimCore.newMatch(X, 5, {"p1": false, "p2": false}, {"forms": true})
	p = X.fighters[0]
	X.dirS.ex = SimState.Exchange.new()
	p.power = 20.0
	for t in range(30):
		SimForms.readyTick(X, p, dt)
	if not p.act.formReady or p.form.coiling or p.form.coil != 0.0:
		return "a step that came ready inside an exchange coiled %s (coiling %s)" % [str(p.form.coil), str(p.form.coiling)]
	X.dirS.ex = null
	SimForms.readyTick(X, p, dt)
	if not p.form.coiling or p.form.coil != p.fd.coilPerSec * 1.0 * dt:
		return "at the break after it came ready the coil did not start: %s" % str(p.form.coil)
	SimCore.dispose(X)
	# a release of live steps never pauses the fight
	var L := SimCore.createSim()
	SimCore.newMatch(L, 5, {"p1": false, "p2": false}, {"forms": true})
	p = L.fighters[0]
	p.power = 20.0
	SimForms.readyTick(L, p, dt)
	if not SimForms.releaseLive(p) or int(SimPause.request(L, SimPause.TRANSFORM, 0).version) != SimPause.LIVE:
		return "a release of step I alone is not live"
	p.act.breakIn = -1
	p.power = 35.0
	SimForms.readyTick(L, p, dt)
	if SimForms.releaseLive(p) or p.form.ready != 2:
		return "a release with step II in it is live"
	SimCore.dispose(L)
	# a fighter without steps: his hold and his one-step take are told
	var N := SimCore.createSim()
	SimCore.newMatch(N, 5, {"p1": false, "p2": false}, {"forms": true})
	r = N.fighters[1]
	r.power = 40.0
	r.act.formReady = true
	N.out.fx.clear()
	for t in range(60):
		SimForms.holdTick(N, r)
	if not SimFighter.transform(N, r) or r.tier != 2.0:
		return "the rival's one step with forms on"
	var told: Array = []
	for e in N.out.fx:
		if e.type == "form_hold" or e.type == "form_release":
			told.append([e.type, int(e.n)])
	if told != [["form_hold", 1], ["form_release", 1]]:
		return "a fighter without steps: told %s" % str(told)
	SimCore.dispose(N)
	# a forms match replays, and carries the forms data
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 11, {}, {"forms": true})
	for t in range(3000):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != SimReplay.dataHash({"forms": true}) or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a forms match does not carry the forms data, or does not play back"
	return ""
