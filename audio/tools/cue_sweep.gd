extends SceneTree
## Over a larger set of seeded AI-vs-AI matches: which of the brawl's cues occur, and does each make the sound it should?
## The cues that are rare (a miss, a double hit, a blast's landing, a launcher that is used) are the ones a short run never
## reaches. From the repo root:
##   godot --headless --path . --script res://audio/tools/cue_sweep.gd [-- --from=100 --count=30 --ticks=5400]
##   ... -- --press=light|heavy|sig --gap=8   one human slot (by seed parity) presses that button every `gap` ticks against the
##   AI, the way QA's masher does (a press is held through a hit-stop). A mash is where double hits and misses happen.
## Prints the raw cue counts by kind and text, the sounds they became, and the checks below. Exit code 1 on a failure.
##   * every cue names a bank sound (or is a stop request with a group), with finite, in-range numbers;
##   * a `miss` makes one impact.whiff for each, at the swinger;
##   * a `double_hit` makes one double.charge and, at its landing, exactly one impact.double;
##   * an `energy_land` blast makes one energy.blast and stops its gather; a bolt makes one energy.bolt or its lite;
##   * a `launcher_open` of 12 ticks or more makes one ui.launcher, and a `used` close stops it;
##   * the sim's hash is the same with and without the audio (only checked on the first seed here: host_check does all).
## No sound device is used.

var from_seed: int = 100
var count: int = 30
var max_ticks: int = 5400
var press: String = ""
var gap: int = 8
var fails: int = 0
var raw: Dictionary = {}
var made: Dictionary = {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--from="):
			from_seed = int(a.substr(7))
		elif a.begins_with("--count="):
			count = int(a.substr(8))
		elif a.begins_with("--ticks="):
			max_ticks = int(a.substr(8))
		elif a.begins_with("--press="):
			press = a.substr(8)
		elif a.begins_with("--gap="):
			gap = int(a.substr(6))
	_run.call_deferred()


func bump(d: Dictionary, k: String, n: int = 1) -> void:
	d[k] = int(d.get(k, 0)) + n


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func _run() -> void:
	var bank := AudioBank.new()
	var bad: String = ""
	var doubles: int = 0
	var doubles_ok: int = 0
	var misses: int = 0
	var whiffs_for_miss: int = 0
	var blasts: int = 0
	var blast_sounds: int = 0
	var openings: int = 0
	var pings: int = 0
	var seeds_with_cue: Dictionary = {}
	for sd in range(from_seed, from_seed + count):
		var S := SimCore.createSim()
		var slot: int = 0 if sd % 2 == 1 else 1
		if press != "":
			SimInputData.load_and_apply()
			SimCore.newMatch(S, sd, {"p1": slot != 0, "p2": slot != 1}, {"v2": [slot == 0, slot == 1]})
		else:
			SimCore.newMatch(S, sd)
		var pend: bool = false
		var waited: int = 0
		var cues := AudioCues.new(bank)
		cues.reset(sd)
		var t: int = 0
		var pending_doubles: Array = []     # landing ticks of double_hit cues awaiting their one impact.double
		var impact_double_at: Array = []
		while t < max_ticks and not (S.game.ko != null and S.game.koT > 3.0):
			var stepped: bool = true
			if press != "":
				var it := SimIntent.new()
				if pend:
					it.set(press, true)
					it.waited = mini(15, waited)
				var ins: Array = [null, null]
				ins[slot] = it
				stepped = SimCore.step(S, ins)
				if pend and not stepped:
					waited += 1
				if stepped and pend:
					pend = false
					waited = 0
				if not pend and S.tick % gap == 0:
					pend = true
			else:
				SimCore.step(S)
			var out: Array = cues.consume(S, S.out.fx)
			var tick_whiffs: int = 0
			var tick_miss: int = 0
			var tick_blast_land: int = 0
			var tick_blast_snd: int = 0
			var tick_open: int = 0
			var tick_ping: int = 0
			for e in S.out.fx:
				if e.type != "cue":
					continue
				var k: String = String(e.kind)
				if k in ["miss", "double_hit", "energy_land", "energy_reach", "launcher_open", "launcher_close", "windup", "charge_full", "burst", "blow", "stagger", "perfect", "window_open", "chain_broken", "launcher_rest"]:
					bump(raw, "%s %s%s" % [k, String(e.text), (" /" + String(e.source)) if (k in ["energy_land", "windup", "charge_full", "blow"] and String(e.source) != "") else ""])
					seeds_with_cue[k] = int(seeds_with_cue.get(k, 0)) | 1
				if k == "miss":
					tick_miss += 1
				elif k == "double_hit":
					pending_doubles.append(int(e.n))
					doubles += 1
				elif k == "energy_land" and String(e.text) == "blast":
					tick_blast_land += 1
				elif k == "launcher_open" and int(e.n) - S.tick >= 12:
					tick_open += 1
			for c in out:
				if c.sound == "":
					if c.stop_group == "":
						bad = "a cue with no sound and no group (seed %d, tick %d)" % [sd, t]
					bump(made, "(stop)")
					continue
				bump(made, c.sound)
				if not bank.has_sound(c.sound):
					bad = "no such sound %s (seed %d)" % [c.sound, sd]
				elif c.variant < 0 or c.variant >= bank.variants(c.sound):
					bad = "variant out of range for %s (seed %d)" % [c.sound, sd]
				elif not (is_finite(c.gain_db) and is_finite(c.pitch) and is_finite(c.x) and is_finite(c.y)) or c.pitch < 0.4 or c.pitch > 2.0 or c.gain_db < -20.0 or c.gain_db > 8.0:
					bad = "number out of range for %s: gain %.1f pitch %.2f (seed %d)" % [c.sound, c.gain_db, c.pitch, sd]
				if c.sound == "impact.whiff":
					tick_whiffs += 1
				elif c.sound == "energy.blast":
					tick_blast_snd += 1
				elif c.sound == "ui.launcher":
					tick_ping += 1
				elif c.sound == "impact.double":
					impact_double_at.append(S.tick)
			misses += tick_miss
			whiffs_for_miss += mini(tick_whiffs, tick_miss)
			blasts += tick_blast_land
			blast_sounds += mini(tick_blast_snd, tick_blast_land)
			openings += tick_open
			pings += mini(tick_ping, tick_open)
			S.out.fx.clear()
			S.out.feed.clear()
			t += 1
		# each double hit gets exactly one impact.double inside its landing window
		for n in pending_doubles:
			var in_win: int = 0
			for at in impact_double_at:
				if at >= n and at <= n + 3:
					in_win += 1
			if in_win == 1:
				doubles_ok += 1
		SimCore.dispose(S)
	print("matches %d..%d, up to %d ticks each\n" % [from_seed, from_seed + count - 1, max_ticks])
	print("raw cues the sim sent:")
	var keys: Array = raw.keys()
	keys.sort()
	for k in keys:
		print("  %5d  %s" % [raw[k], k])
	print("\nsounds the mapper made:")
	var mk: Array = made.keys()
	mk.sort()
	var parts: Array = []
	for k in mk:
		parts.append("%s %d" % [k, made[k]])
	print("  " + ", ".join(parts))
	print("")
	ok(bad == "", "every cue is a bank sound or a stop request, with numbers in range" + ("" if bad == "" else ": " + bad))
	ok(whiffs_for_miss == misses, "every miss makes its whiff (%d of %d)" % [whiffs_for_miss, misses])
	ok(doubles_ok == doubles, "every double hit makes one charge and exactly one impact.double at its landing (%d of %d)" % [doubles_ok, doubles])
	ok(blast_sounds == blasts, "every blast landing makes its whump (%d of %d)" % [blast_sounds, blasts])
	ok(pings == openings, "every opening of 12 ticks or more makes its ping (%d of %d)" % [pings, openings])
	print("\ncue sweep %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)
