extends SceneTree
# Every World switch on (interiorChain 1, repeatMarks 2): AI matches play, the events are well formed, and the same seed plays the same twice.
#   godot --headless --path . --script res://sim/world/tools/switchon_check.gd -- [--seeds=6] [--ticks=7200]
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func play(seed: int, ticks: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false})
	var ic: int = 0
	var ie: int = 0
	var bad: int = 0
	var bounces: int = 0
	var links: int = 0
	for t in range(ticks):
		SimCore.step(S)
		for e in S.out.fx:
			if e.type == "interior_contact":
				ic += 1
				if absf(e.nx * e.nx + e.ny * e.ny - 1.0) > 0.0001 or e.vn >= 0.0:
					bad += 1
				if e.k > 0.0 and not e.punch and e.keep > 0.0:
					bounces += 1
			elif e.type == "interior_end":
				ie += 1
			elif e.type == "chain_link":
				links += 1
		S.out.fx.clear()
		if S.game.ko != null:
			break
	var marks: int = 0
	for b in S.buildings:
		marks += b.marks
	return {"hash": str(SimHash.stateHash(S).gameplay), "ic": ic, "ie": ie, "bad": bad, "bounces": bounces, "links": links, "marks": marks, "ticks": S.tick}


func _init() -> void:
	var seeds: int = 6
	var ticks: int = 7200
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = int(a.substr(8))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	var c: Dictionary = WorldBrunt.cfg()
	c.interiorChain = 1
	c.repeatMarks = 2
	var tot := {"ic": 0, "ie": 0, "bad": 0, "bounces": 0, "links": 0, "marks": 0}
	var same: int = 0
	for s in range(1, seeds + 1):
		var r1: Dictionary = play(s, ticks)
		var r2: Dictionary = play(s, ticks)
		if r1.hash == r2.hash and r1.ic == r2.ic:
			same += 1
		for k in tot:
			tot[k] += r1[k]
	ok(same == seeds, "%d of %d seeds play the same twice (hash and events)" % [same, seeds])
	ok(tot.bad == 0 and tot.ic == 0 or tot.bad == 0, "every interior_contact is well formed (%d contacts, %d ends, %d bounces, %d links, %d marks on buildings)" % [tot.ic, tot.ie, tot.bounces, tot.links, tot.marks])
	ok(tot.ie <= tot.ic, "no end without a contact before it")
	c.interiorChain = 0
	c.repeatMarks = 0
	print("SWITCHON: %d check(s) failed" % fails)
	quit()
