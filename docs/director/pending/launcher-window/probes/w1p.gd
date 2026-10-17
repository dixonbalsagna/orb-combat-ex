extends SceneTree
## Probe: the launcher's wider window. Slot 0 is a scripted player against the medium AI: X every 8 ticks; after each
## launcher_open of his, one B tap a set number of ticks after it (0, 6, 12, 18, 22, 26, 32 in turn). With --early, the
## B is pressed instead the tick his closing light leaves (his run is full and that light is on its way), so it waits
## on his line. For each B it reads the beat it threw: the launcher or not, sure or not; and whether it launched (a
## launch of the rival within 60 ticks), landed as the hammer, or was answered (guarded or perfect-blocked).
## -- <matches> <seed0> [--early]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var early := false
	for s in args:
		if s == "--early":
			early = true
	var delays := [0, 6, 12, 18, 22, 26, 32]
	var r := {"early": early, "matches": n, "byDelay": {}}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {"p1": false, "p2": true}, {"v2": [true, false]})
		var me = S.fighters[0]
		var last := -1000
		var k := 0
		var bAt := -1
		var bUp := -1
		var d := -1
		var watch = null   # the B's beat, once thrown
		var wTick := -1
		var openAt := -1
		while S.tick < 18000 and S.game.ko == null:
			var it := SimIntent.new()
			var ex = S.dirS.ex
			if early and bAt < 0 and ex != null and DirBrawl.isBrawl(ex) and (ex.A == me or ex.D == me) and DirBrawl._closes(S, ex, me) and DirBrawl._g(me, DirBrawl.LINE) == 1 and S.tick - last <= 1:
				bAt = S.tick + 1
				d = -1
			if S.tick == bAt:
				it.sig = true
				bUp = S.tick + 2
				bAt = -1
			elif S.tick < bUp:
				it.sigHeld = true
			elif S.tick - last >= 8 and bAt < 0:
				it.light = true
				last = S.tick
			SimCore.step(S, [it, null])
			ex = S.dirS.ex
			for e in S.out.fx:
				if e.type == "cue" and String(e.kind) == "launcher_open" and int(e.actor) == 0:
					openAt = S.tick
					if not early:
						d = delays[k % delays.size()]
						k += 1
						bAt = S.tick + d
				elif e.type == "cue" and String(e.kind) == "blow" and int(e.actor) == 0 and String(e.text) == "heavy" and watch == null and ex != null:
					for b in ex.beats:
						if not b.done and b.op == "strike" and b.args != null and b.args.get("brawl", false) and String(b.args.a) == ("A" if ex.A == me else "D") and String(b.args.get("strength", "")) == "heavy":
							watch = b
							wTick = S.tick
							break
				elif e.type == "launch" and int(e.actor) == 1 and int(e.target) == 0 and watch != null:   # actor: the fighter launched; target: who launched him
					_add(r, d, watch, "launched", openAt)
					watch = null
				elif e.type == "damage" and int(e.attacker) == 0 and watch != null and String(e.kind) == "guard":
					_add(r, d, watch, "guarded", openAt)
					watch = null
				elif e.type == "cue" and String(e.kind) == "perfect_block" and int(e.actor) == 1 and watch != null:
					_add(r, d, watch, "perfect", openAt)
					watch = null
			if watch != null and S.tick - wTick > 60:
				_add(r, d, watch, "other", openAt)
				watch = null
			S.out.fx.clear()
			S.out.feed.clear()
	print(JSON.stringify(r))
	quit()


static func _add(r: Dictionary, d: int, b, how: String, openAt: int) -> void:
	var key: String = "early" if d < 0 else str(d)
	if not r.byDelay.has(key):
		r.byDelay[key] = {"n": 0, "launcher": 0, "sure": 0, "launched": 0, "guarded": 0, "perfect": 0, "other": 0}
	var x: Dictionary = r.byDelay[key]
	x.n += 1
	if bool(b.args.get("launcher", false)):
		x.launcher += 1
	if bool(b.args.get("sure", false)):
		x.sure += 1
	x[how] += 1
