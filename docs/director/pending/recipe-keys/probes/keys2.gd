extends SceneTree
## Scratch probe: the interject key on the ring beat (stage 3 of one versus many; docs/combat/split-and-pieces.md
## section 3). The AI on every body: the one is the Protagonist, the rest are the Rival. Every ring beat (args.a "X")
## is read once: its strength and its piece, and the recipes' brawl cells whose pool for the guard holds it; every
## interject wind-up cue's source. -- <matches> <seed0> [--bodies=3] [--cap=9000]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 3
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var nb := 3
	var cap := 9000
	for s in args:
		if s.begins_with("--bodies="):
			nb = int(s.substr(9))
		if s.begins_with("--cap="):
			cap = int(s.substr(6))
	var rec: Dictionary = DirRecipe.rec() if DirRecipe.on() else {}
	var named: Dictionary = rec.get("brawl", {})
	var r := {"matches": n, "bodies": nb, "ring": 0, "noPiece": 0, "cells": {}, "strength": {}, "cueSource": {}}
	for m in range(n):
		var S := SimCore.createSim()
		var slots := ["PROTAGONIST"]
		var names := ["ONE"]
		var ai := {}
		for k in range(nb):
			ai["p" + str(k + 1)] = true
			if k > 0:
				slots.append("RIVAL")
				names.append("G" + str(k))
		SimCore.newMatch(S, seed0 + m, ai, {"slots": slots, "names": names})
		var seen := {}
		while S.tick < cap and S.game.ko == null:
			SimCore.step(S, null)
			for e in S.out.fx:
				if e.type == "cue" and String(e.kind) == "windup" and String(e.text) == "interject":
					var src: String = String(e.source)
					r.cueSource[src] = int(r.cueSource.get(src, 0)) + 1
			S.out.fx.clear()
			S.out.feed.clear()
			var ex = S.dirS.ex
			if ex == null:
				continue
			for b in ex.beats:
				if b.op != "strike" or b.args == null or String(b.args.get("a", "")) != "X":
					continue
				var id: int = b.get_instance_id()
				if seen.has(id):
					continue
				seen[id] = true
				r.ring += 1
				var st: String = String(b.args.get("strength", ""))
				r.strength[st] = int(r.strength.get(st, 0)) + 1
				var piece: String = String(b.args.get("piece", ""))
				if piece == "":
					r.noPiece += 1
					continue
				var g = S.fighters[int(b.args.get("who", 0))]
				var cells: Array = []
				for c in named.keys():
					if String(c).begins_with("_"):
						continue
					var list = rec.get("pools", {}).get(DirRecipe.poolKey(g), {}).get(String(named[c]))
					if list is Array:
						for row in list:
							if String(row.get("id", "")) == piece:
								cells.append(String(c))
								break
				cells.sort()
				var key: String = ",".join(cells) if cells.size() > 0 else "(no cell)"
				r.cells[key] = int(r.cells.get(key, 0)) + 1
	print(JSON.stringify(r))
	quit()
