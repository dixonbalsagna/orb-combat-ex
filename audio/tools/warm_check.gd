extends SceneTree
## After bank.warm(), does anything a match can play still render on its first use? Rendering's timing found first plays of
## 7 to 23 ms in a warmed run (2026-10-17): the head flashes and the babble were outside warm(). This warms the bank the way
## the host does, then plays what a match plays and checks that every sound it asks for is already cached. From the repo root:
##   godot --headless --path . --script res://audio/tools/warm_check.gd [-- --ticks=3600] [--extras=0]
## --extras=0 warms only the one-shots, as bank.warm() did before 2026-10-17: the check then fails, naming what rendered late.
## It checks: the cues of two seeded AI-vs-AI matches; every head flash for both fighters; every babble line of every voice
## (the syllables, laughs, blips and the grunts that punctuate them). Exit code 1 if anything was not warmed.
## (A headless run does not call warm() at all, main.gd:203, so a headless timing run still renders on first use.)

var bank: AudioBank
var cues: AudioCues
var misses: Dictionary = {}
var max_ticks: int = 3600
var extras: bool = true


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			max_ticks = int(a.substr(8))
		elif a.begins_with("--extras="):
			extras = int(a.substr(9)) != 0
	_run.call_deferred()


func _need(id: String, variant: int) -> void:
	if id == "":
		return
	var key: String = "%s#%d" % [id, posmod(variant, bank.variants(id))]
	if not bank._cache.has(key):
		misses[key] = true


func _run() -> void:
	bank = AudioBank.new()
	cues = AudioCues.new(bank)
	var t0: int = Time.get_ticks_usec()
	bank.warm(extras)
	var ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	var cached: int = bank._cache.size()
	var only_ids: float = 0.0
	var b2 := AudioBank.new()
	var t1: int = Time.get_ticks_usec()
	b2.warm(false)
	only_ids = (Time.get_ticks_usec() - t1) / 1000.0
	print("warm(): %d clips in %.0f ms (the one-shots alone, as before: %d clips in %.0f ms; the flashes of the roster's voices and every voice's babble add %.0f ms)" % [cached, ms, b2._cache.size(), only_ids, ms - only_ids])
	# 1. two seeded matches
	var n_cues: int = 0
	for sd in [4, 12345]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, sd)
		cues.reset(sd)
		var t: int = 0
		while t < max_ticks and not (S.game.ko != null and S.game.koT > 3.0):
			SimCore.step(S)
			for c in cues.consume(S, S.out.fx):
				if c.sound != "":
					n_cues += 1
					_need(c.sound, c.variant)
			S.out.fx.clear()
			S.out.feed.clear()
			t += 1
		# 2. every head flash for both fighters
		for actor in range(S.fighters.size()):
			for fl in cues.cfg.flash.rank:
				var c = cues.flash(S, actor, fl)
				if c != null:
					_need(c.sound, c.variant)
		SimCore.dispose(S)
	# 3. every babble line of every voice
	var bab := AudioBabble.new(bank)
	var caps: Dictionary = AudioBank.load_json("res://audio/data/babble_captions.json").captions
	var n_ev: int = 0
	for v in caps:
		var k: int = 0
		for ln in caps[v]:
			var P = bab.plan(v, String(ln.text), String(ln.mood), int(ln.intensity), [{"at": 3, "gesture": "laugh"}, {"at": 9, "gesture": "wince"}], 40 + k)
			for e in P.events:
				n_ev += 1
				_need(e.sound, e.variant)
			k += 1
	print("checked %d cues of two matches, every flash, and %d babble events" % [n_cues, n_ev])
	var bad: bool = not misses.is_empty()
	print("  %s  nothing a match plays renders on its first use%s" % ["FAIL" if bad else "ok  ", (": " + ", ".join(misses.keys())) if bad else ""])
	print("\nwarm check %s" % ("FAILED" if bad else "passed"))
	quit(1 if bad else 0)
