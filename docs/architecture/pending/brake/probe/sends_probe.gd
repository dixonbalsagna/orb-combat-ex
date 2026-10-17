extends SceneTree
# Scratch (Simulation): how fast sends are, for the air brake's numbers. AI matches; every launch event's speed (the
# send's velocity, traversal included) by the launcher's tier, and whether it was special (a signature, finisher or
# break launch). Usage: godot --headless --path <export> --script res://zbrake/sends_probe.gd -- <matches> <ticks>


func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 20
	var ticks: int = int(a[1]) if a.size() > 1 else 9000
	var all: Array = []
	var plain: Array = []
	var special: Array = []
	var byTier: Dictionary = {}
	for k in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, 300 + k)
		for t in range(ticks):
			SimCore.step(S)
			for e in S.out.fx:
				if e.type == "launch":
					var f = S.fighters[int(e.actor)]
					var v: float = SimDetMath.hypot(f.vx / f.launchT, f.vy)   # the send's own speed, the traversal factor divided out
					var by = S.fighters[int(e.target)] if e.target >= 0.0 else null
					all.append(v)
					if f.launchSpecial:
						special.append(v)
					else:
						plain.append(v)
					var tk: int = int(by.tier) if by != null else 0
					if not byTier.has(tk):
						byTier[tk] = []
					byTier[tk].append(v)
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null and S.game.koT > 2.5:
				break
		SimCore.dispose(S)
	for pair in [["all", all], ["plain", plain], ["special", special]]:
		print("%s: %s" % [pair[0], _q(pair[1])])
	var keys: Array = byTier.keys()
	keys.sort()
	for tk in keys:
		print("launcher tier %d: %s" % [tk, _q(byTier[tk])])
	quit()


func _q(v: Array) -> String:
	if v.is_empty():
		return "none"
	var s: Array = v.duplicate()
	s.sort()
	var m: int = s.size()
	return "n %d, median %.0f, p90 %.0f, p99 %.0f, max %.0f" % [m, s[m / 2], s[int(m * 0.9)], s[mini(m - 1, int(m * 0.99))], s[m - 1]]
