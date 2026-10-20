

## The catastrophe's sky (sim/core/cata.gd): a blast cloud sends its cue (x, y, amount, n) and raises the ash by
## perCloud over riseTicks, evenly, at most max; a second raises it again to its cap; S.cata is null and unhashed until
## the first, and a match that has none is as before.
func _cata() -> String:
	if not SimCata.errors().is_empty():
		return "the catastrophe's data: " + "; ".join(SimCata.errors())
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false})
	if S.cata != null or SimCata.ash(S) != 0.0:
		return "a match starts with a catastrophe's state"
	var h0: String = SimHash.stateHash(S).gameplay
	S.out.fx.clear()
	SimCata.blastCloud(S, S.fighters[1], 1234.0, 50.0, S.tick + 8)
	var e = S.out.fx[S.out.fx.size() - 1]
	if e.type != "blast_cloud" or e.actor != 1.0 or e.x != 1234.0 or e.y != 50.0 or e.amount != SimCata.radius or int(e.n) != S.tick + 8:
		return "the blast_cloud cue's fields"
	if S.cata == null or S.cata.ash != 0 or S.cata.ashTo != SimCata.perCloud or SimHash.stateHash(S).gameplay == h0:
		return "the cloud's ash is not set, or not in the hash"
	var last: int = 0
	for t in range(SimCata.riseTicks):
		SimCata.tick(S)
		var want: int = int(SimMathx.jround(float(SimCata.perCloud) * float(t + 1) / float(SimCata.riseTicks)))
		if S.cata.ash < last or absi(S.cata.ash - want) > 1:
			return "tick %d of the rise: the ash is %d (want %d, never falling)" % [t + 1, S.cata.ash, want]
		last = S.cata.ash
	if S.cata.ash != SimCata.perCloud or S.cata.ashLeft != 0 or SimCata.ash(S) != float(SimCata.perCloud) / 1000.0:
		return "after its rise the ash is %d (want %d)" % [S.cata.ash, SimCata.perCloud]
	SimCata.blastCloud(S, null, 0.0, 0.0, S.tick)
	if S.out.fx[S.out.fx.size() - 1].actor != -1.0:
		return "a cloud by no one"
	while S.cata.ashLeft > 0:
		SimCata.tick(S)
	if S.cata.ash != mini(SimCata.ashMax, 2 * SimCata.perCloud):
		return "two clouds' ash is %d" % S.cata.ash
	# the rise runs in the step, and a cloud's match replays from its state
	var a0: int = S.cata.ash
	SimCata.blastCloud(S, null, 0.0, 0.0, S.tick)
	SimCore.step(S, [null, null])
	if S.cata.ashLeft != SimCata.riseTicks - 1 or S.cata.ash != a0:
		return "the step does not run the rise (left %d)" % S.cata.ashLeft
	SimCore.dispose(S)
	return ""
