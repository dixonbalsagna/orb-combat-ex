

## Animation's view fields (docs/animation/ragdoll-physics-paper.md section 5), outside the hash: a launch carries its power
## tier (the launcher's); a hit's damage event carries the hit-stop ticks in force after it, which is exactly the number
## of frozen ticks the step then spends, and the hitter's tier. Neither moves the events' hash.
func _animFields() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false})
	var A = S.fighters[0]
	var D = S.fighters[1]
	A.tier = 3.0
	S.out.fx.clear()
	SimDamage.hit(S, null, A, D, 10.0, {"stop": 0.1})
	var dmg = null
	for e in S.out.fx:
		if e.type == "damage":
			dmg = e
			break
	if dmg == null:
		return "a hit sent no damage event"
	if dmg.tier != 3.0 or dmg.stop != SimFx.stopTicks(S.dirS.stop) or dmg.stop < 1:
		return "the hit's fields: stop %d (want %d), tier %s" % [dmg.stop, SimFx.stopTicks(S.dirS.stop), str(dmg.tier)]
	S.out.fx.clear()
	var frozen: int = 0
	while not SimCore.step(S):
		frozen += 1
		S.out.fx.clear()
		if frozen > 600:
			break
	if frozen != dmg.stop:
		return "the step froze %d ticks after a hit that said %d" % [frozen, dmg.stop]
	var h1 := SimHash.Hasher.new()
	SimHash.hashFx(h1, [dmg])
	dmg.stop = 0
	dmg.tier = 0.0
	var h2 := SimHash.Hasher.new()
	SimHash.hashFx(h2, [dmg])
	if h1.hex() != h2.hex():
		return "a hit's stop or tier moved the events' hash"
	S.out.fx.clear()
	SimFx.launch(S, D, A, 900.0, 1.0)
	var la = S.out.fx[S.out.fx.size() - 1]
	if la.type != "launch" or la.tier != 3.0:
		return "a launch by a tier-3 fighter does not say tier 3"
	var h3 := SimHash.Hasher.new()
	SimHash.hashFx(h3, [la])
	la.tier = 1.0
	var h4 := SimHash.Hasher.new()
	SimHash.hashFx(h4, [la])
	if h3.hex() != h4.hex():
		return "a launch's tier moved the events' hash"
	SimCore.dispose(S)
	return ""
