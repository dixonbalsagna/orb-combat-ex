

## Forms' branches (hero-forms.md section 3; docs/architecture/forms-core.md section 7), with forms on: Witness fills by
## the opponent's kills near him and never by his own, which take from it; his anguish no longer takes the opponent's
## kills; Trial fills by the opponent's forms (more when his own was held), the deficit seconds, his blows of a medium or
## more a tier down, the opponent's commitments and the coil; a release picks once, the higher fill, a tie to his branch
## and the first tie to Trial, and empties it; a cross is told; the branch's extras reach the gains, his care and the
## director's two reads; the fills are hashed.
func _formBranches() -> String:
	var dt: float = SimConst.DT
	var M := SimCore.createSim()
	SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"forms": true})
	var p = M.fighters[0]
	var r = M.fighters[1]
	if p.fd == null or p.fd.branchAt != [2, 4]:
		return "the branch steps are not II and IV"
	var norm: float = WorldCollateral.POP_REF / WorldCollateral.normPeople(M)
	# Witness
	SimForms.casualty(M, 3.0, r, SimWrap.wrap(p.x + 100.0))
	var w1: float = 3.0 * p.fd.wPerPerson * norm
	if p.form.witness != w1:
		return "three people the rival killed near him gave Witness %s, not %s" % [str(p.form.witness), str(w1)]
	SimForms.casualty(M, 3.0, r, SimWrap.wrap(p.x + p.fd.wRange + 500.0))
	SimForms.casualty(M, 3.0, null, p.x)
	if p.form.witness != w1:
		return "a kill beyond the range, or with no killer, filled Witness"
	SimForms.casualty(M, 1.0, p, p.x)
	var w2: float = SimMathx.jmax(0.0, w1 - 1.0 * p.fd.wOwnKill * norm)
	if p.form.witness != w2 or r.form.witness != 0.0 or p.form.trial != 0.0:
		return "his own kill: Witness %s (want %s); the rival's %s; Trial %s" % [str(p.form.witness), str(w2), str(r.form.witness), str(p.form.trial)]
	if SimForms.anguishOther(M, p) != 0.0 or SimForms.anguishOther(M, r) != r.md.anguishCasOther:
		return "his anguish still takes the opponent's kills, or the rival's no longer does"
	# Trial: the opponent's form while his tier is no higher; then held
	M.out.fx.clear()
	r.power = 40.0
	r.act.formReady = true
	SimFighter.transform(M, r)
	SimForms.events(M)
	if r.tier != 2.0 or p.form.trial != p.fd.tForm:
		return "the rival's form with his tier no higher gave Trial %s (want %s)" % [str(p.form.trial), str(p.fd.tForm)]
	p.power = 20.0
	var t0: float = p.form.trial
	var c0: float = p.form.coil
	SimForms.readyTick(M, p, dt)
	if not p.act.formReady or p.form.trial != t0 + p.fd.tPerSec * dt + (p.form.coil - c0) or p.form.coil <= c0:
		return "a deficit tick with his step ready: Trial %s (want %s, the second and the coil)" % [str(p.form.trial), str(t0 + p.fd.tPerSec * dt + (p.form.coil - c0))]
	M.out.fx.clear()
	t0 = p.form.trial
	r.power = 70.0
	r.act.formReady = true
	SimFighter.transform(M, r)
	SimForms.events(M)
	if r.tier != 3.0 or p.form.trial != t0 + p.fd.tFormHeld:
		return "the rival's form while his own was held gave %s (want %s)" % [str(p.form.trial - t0), str(p.fd.tFormHeld)]
	# Trial: his blows a tier down, the opponent's commitments
	M.out.fx.clear()
	t0 = p.form.trial
	SimFx.damage(M, r, p, 10.0, "core", "medium", "#ffffff", true, "brawl", "medium")
	SimFx.damage(M, r, p, 10.0, "core", "heavy", "#ffffff", true, "brawl", "heavy")
	SimFx.damage(M, r, p, 10.0, "core", "light", "#ffffff", true, "brawl", "light")
	SimFx.damage(M, r, p, 10.0, "arms", "guard", "#ffffff", true, "", "medium")
	SimFx.damage(M, p, r, 10.0, "core", "heavy", "#ffffff", true, "brawl", "heavy")
	SimFx.finisherStart(M, r, p)
	SimFx.brinkEnter(M, r)
	SimFx.beamOutcome(M, r, p, "CLASH")
	SimFx.beamOutcome(M, r, p, "HIT")
	SimFx.finisherStart(M, p, r)
	SimForms.events(M)
	var want: float = t0 + p.fd.tBlow + p.fd.tBlow + p.fd.tCommit + p.fd.tCommit + p.fd.tCommit
	if p.form.trial != want:
		return "two landed blows a tier down and three commitments gave %s (want %s)" % [str(p.form.trial - t0), str(want - t0)]
	M.out.fx.clear()
	var hb: String = SimHash.stateHash(M).gameplay
	p.form.witness += 1.0
	if SimHash.stateHash(M).gameplay == hb:
		return "the Witness fill is not in the hash"
	p.form.witness -= 1.0
	# the pick at II: Witness the higher; then Trial the higher at IV, a cross
	p.power = 35.0
	SimForms.readyTick(M, p, dt)
	p.form.witness = 30.0
	p.form.trial = 10.0
	M.out.fx.clear()
	SimFighter.transform(M, p)
	var st = null
	for e in M.out.fx:
		if e.type == "form_step":
			st = e
	if p.form.step != 2 or p.form.branch != "witness" or p.form.witness != 0.0 or p.form.trial != 10.0 or p.care != 0.5 or st == null or st.text != "witness" or st.source != "":
		return "the pick at II with Witness the higher: step %d, %s, fills %s and %s, care %s" % [p.form.step, p.form.branch, str(p.form.witness), str(p.form.trial), str(p.care)]
	if SimForms.damageMul(M, p) != (1.0 + p.fd.gDamage * 2.0 * p.form.lasting) * p.form.surgeMul * (1.0 + p.fd.wDamage) or SimForms.launchMul(M, p) != (1.0 + p.fd.gLaunch * 2.0 * p.form.lasting) * (1.0 + p.fd.wLaunch) or SimForms.blockWiden(M, p) != 0 or SimForms.followBonus(M, p) != 0:
		return "a Witness form's extras"
	p.power = 65.0
	SimForms.readyTick(M, p, dt)
	p.form.witness = 5.0
	p.form.trial = 50.0
	M.out.fx.clear()
	SimFighter.transform(M, p)
	st = null
	for e in M.out.fx:
		if e.type == "form_step":
			st = e
	if p.form.step != 4 or p.form.branch != "trial" or not p.form.crossed or p.form.trial != 0.0 or p.form.witness != 5.0 or p.care != 0.0 or st == null or st.text != "trial" or st.source != "cross":
		return "the cross at IV to Trial: step %d, %s, crossed %s, fills %s and %s, care %s" % [p.form.step, p.form.branch, str(p.form.crossed), str(p.form.witness), str(p.form.trial), str(p.care)]
	if SimForms.speedMul(M, p) != (1.0 + p.fd.gSpeed * 4.0 * p.form.lasting) * p.form.surgeMul * (1.0 + p.fd.tSpeed) or SimForms.blockWiden(M, p) != int(p.fd.tBlock[1]) or SimForms.followBonus(M, p) != p.fd.tFollow:
		return "a Trial form's extras at IV"
	SimCore.dispose(M)
	# ties: the first to Trial, then to the branch he is on; one pick for a release that passes II and IV
	var T := SimCore.createSim()
	SimCore.newMatch(T, 6, {"p1": false, "p2": false}, {"forms": true})
	p = T.fighters[0]
	p.power = 35.0
	SimForms.readyTick(T, p, dt)
	p.form.witness = 7.0
	p.form.trial = 7.0
	SimFighter.transform(T, p)
	if p.form.branch != "trial" or p.form.crossed:
		return "the first tie went to %s" % p.form.branch
	p.power = 65.0
	SimForms.readyTick(T, p, dt)
	p.form.witness = 3.0
	p.form.trial = 3.0
	SimFighter.transform(T, p)
	if p.form.branch != "trial" or p.form.crossed:
		return "a tie on Trial went to %s" % p.form.branch
	SimCore.dispose(T)
	var U := SimCore.createSim()
	SimCore.newMatch(U, 7, {"p1": false, "p2": false}, {"forms": true})
	p = U.fighters[0]
	p.power = 65.0
	SimForms.readyTick(U, p, dt)
	p.form.witness = 20.0
	p.form.trial = 10.0
	SimFighter.transform(U, p)
	if p.form.step != 4 or p.form.branch != "witness" or p.form.witness != 0.0 or p.form.trial != 10.0 or p.form.crossed:
		return "a release from base to IV picked more than once: %s, fills %s and %s" % [p.form.branch, str(p.form.witness), str(p.form.trial)]
	SimCore.dispose(U)
	return ""
