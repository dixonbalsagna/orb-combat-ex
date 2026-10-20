

## The run's rare boons (rulings-2026-10-18b.md section 4; docs/architecture/boons-core.md). A match that names none has
## none, and a replay's data hash takes boons.json only when its setup names one. Each starts its fighter in his boon's
## form at its floor, without forms (tiers 2, 3 and 4) and with them (steps I, II and V, the branch the first tie's);
## second skin on the rival fills the Protagonist's Trial at once; the borrowed form's wear runs 1 / (1 - share) as fast
## until a region breaks; the collateral reads the higher tier from the start; a boon match replays.
func _boons() -> String:
	if not SimBoons.errors().is_empty():
		return "the boons' data: " + "; ".join(SimBoons.errors())
	var d0: String = SimReplay.dataHash()
	if SimReplay.dataHash({"boons": {"0": "born_ready"}}) == d0:
		return "a replay that names a boon does not carry the boons' data"
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 5, {"p1": false, "p2": false})
	if S0.fighters[0].boon != "" or S0.fighters[0].tier != 1.0:
		return "a match that names no boon has one"
	SimCore.dispose(S0)
	for w in [["born_ready", 2.0, 35.0], ["second_skin", 3.0, 65.0], ["borrowed", 4.0, 100.0]]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"boons": {"0": w[0]}})
		var p = S.fighters[0]
		if p.boon != w[0] or p.tier != w[1] or p.power != w[2] or S.world.maxTier < w[1] or S.fighters[1].tier != 1.0:
			return "%s without forms: tier %s at power %s (want %s at %s), the world's top tier %s" % [w[0], str(p.tier), str(p.power), str(w[1]), str(w[2]), str(S.world.maxTier)]
		SimCore.dispose(S)
	for w in [["born_ready", 1, 1.0, 20.0, ""], ["second_skin", 2, 2.0, 35.0, "trial"], ["borrowed", 5, 4.0, 100.0, "trial"]]:
		var F := SimCore.createSim()
		SimCore.newMatch(F, 5, {"p1": false, "p2": false}, {"forms": true, "boons": {"0": w[0]}})
		var p = F.fighters[0]
		if p.form.step != w[1] or p.tier != w[2] or p.power != w[3] or p.form.branch != w[4]:
			return "%s with forms: step %d, tier %s, power %s, branch '%s'" % [w[0], p.form.step, str(p.tier), str(p.power), p.form.branch]
		SimCore.dispose(F)
	var R2 := SimCore.createSim()
	SimCore.newMatch(R2, 5, {"p1": false, "p2": false}, {"forms": true, "boons": {"1": "second_skin"}})
	if R2.fighters[1].tier != 3.0 or R2.fighters[0].form.trial != R2.fighters[0].fd.tForm:
		return "second skin on the rival: his tier %s, the Protagonist's Trial %s (want %s)" % [str(R2.fighters[1].tier), str(R2.fighters[0].form.trial), str(R2.fighters[0].fd.tForm)]
	SimCore.dispose(R2)
	# the borrowed form's price
	var B := SimCore.createSim()
	SimCore.newMatch(B, 5, {"p1": false, "p2": false}, {"boons": {"0": "borrowed"}})
	var p = B.fighters[0]
	var q = B.fighters[1]
	var want: int = int(SimMathx.jround(10.0 * (SimWounds.wearK(B, p) * (1.0 / (1.0 - SimBoons.sooner)))))
	var wq: int = int(SimMathx.jround(10.0 * SimWounds.wearK(B, q)))
	var p0: int = int(p.wear[SimWounds.CORE])
	var q0: int = int(q.wear[SimWounds.CORE])
	SimWounds.addWear(B, p, SimWounds.CORE, 10.0)
	SimWounds.addWear(B, q, SimWounds.CORE, 10.0)
	if int(p.wear[SimWounds.CORE]) - p0 != want or int(q.wear[SimWounds.CORE]) - q0 != wq or want <= wq:
		return "the borrowed form's wear: %d (want %d), the rival's %d (want %d)" % [int(p.wear[SimWounds.CORE]) - p0, want, int(q.wear[SimWounds.CORE]) - q0, wq]
	p.stage[SimWounds.ARMS] = 3
	if SimBoons.wearMul(p) != 1.0 or SimBoons.wearMul(q) != 1.0:
		return "the borrowed form's wear runs fast after his first broken region"
	SimCore.dispose(B)
	# a boon match replays
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 9, {}, {"boons": {"0": "born_ready"}})
	for t in range(1200):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != SimReplay.dataHash({"boons": {"0": "born_ready"}}) or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a boon match does not carry the boons' data, or does not play back"
	return ""
