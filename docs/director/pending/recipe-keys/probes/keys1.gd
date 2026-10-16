extends SceneTree
## Scratch probe: Combat's mash key (docs/combat/split-and-pieces.md section 1). Slot 0 is scripted: a tap of Y every
## --every ticks (--btn=y) or of B (--btn=b), released after 2; slot 1 the medium AI. Every strike beat of slot 0's
## brawl is read once, when it is first seen: its strength, whether it was a mash (args.flurry), and the recipes'
## brawl cells whose pool for him holds its piece. -- <matches> <seed0> --btn=y|b [--every=12]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 3
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var btn := "y"
	var every := -1
	for s in args:
		if s.begins_with("--btn="):
			btn = s.substr(6)
		if s.begins_with("--every="):
			every = int(s.substr(8))
	if every < 0:
		every = 12 if btn == "y" else 28
	var rec: Dictionary = DirRecipe.rec() if DirRecipe.on() else {}
	var named: Dictionary = rec.get("brawl", {})
	var r := {"btn": btn, "every": every, "matches": n, "mash": {}, "tap": {}, "noPiece": 0, "beats": 0}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {"p1": false, "p2": true}, {"v2": [true, false]})
		var me = S.fighters[0]
		var seen := {}
		var up := -1
		while S.tick < 18000 and S.game.ko == null:
			var it := SimIntent.new()
			if S.tick % every == 0:
				if btn == "y":
					it.heavy = true
				else:
					it.sig = true
				up = S.tick + 2
			if S.tick < up:
				if btn == "y":
					it.heavyHeld = true
				else:
					it.sigHeld = true
			SimCore.step(S, [it, null])
			var ex = S.dirS.ex
			if ex == null:
				continue
			var role: String = "A" if ex.A == me else ("D" if ex.D == me else "")
			if role == "":
				continue
			for b in ex.beats:
				if b.op != "strike" or b.args == null or not b.args.get("brawl", false) or String(b.args.get("a", "")) != role:
					continue
				var id: int = b.get_instance_id()
				if seen.has(id):
					continue
				seen[id] = true
				var st: String = String(b.args.get("strength", ""))
				if st != ("medium" if btn == "y" else "heavy") or b.args.get("energy", "") != "" or b.args.get("launcher", false):
					continue
				r.beats += 1
				var piece: String = String(b.args.get("piece", ""))
				if piece == "":
					r.noPiece += 1
					continue
				var cells: Array = []
				var pk: String = DirRecipe.poolKey(me)
				for c in named.keys():
					if String(c).begins_with("_"):
						continue
					var list = rec.get("pools", {}).get(pk, {}).get(String(named[c]))
					if list is Array:
						for row in list:
							if String(row.get("id", "")) == piece:
								cells.append(String(c))
								break
				cells.sort()
				var key: String = ",".join(cells) if cells.size() > 0 else "(no cell)"
				var bucket: Dictionary = r.mash if bool(b.args.get("flurry", false)) else r.tap
				bucket[key] = int(bucket.get(key, 0)) + 1
	print(JSON.stringify(r))
	quit()
