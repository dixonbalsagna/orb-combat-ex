extends SceneTree
## Does the babble voice behave? From the repo root:
##   godot --headless --path . --script res://audio/tools/babble_check.gd
## Checks (exit code 1 on any failure):
##   1. the babble clock is the text-reveal clock (ui/core/ui_bark_timing.gd): same total and same time for every character
##   2. plans are reproducible (same seed, same plan) and vary with the seed and the line
##   3. punctuation shapes the pitch: a question rises, an exclamation punches its last word, an ellipsis trails away
##   4. moods differ the way they should (pitch, pace, loudness), averaged over seeds
##   5. laughs and cue gestures become laugh and grunt events
##   6. the bank renders for every voice, and what it costs (time, memory)
##   7. babbling never changes the sim: the gameplay hash of a seeded match is the same with and without it
##   8. the A/B voices (data/babble_ab.json): the Cyborg's growl and blip, the Empress's booming laugh and baked shimmer, the lurching
##      rhythm; each renders, is reproducible, and the current voices are unaffected

var bank: AudioBank
var bab: AudioBabble
var fails: int = 0


func _init() -> void:
	bank = AudioBank.new()
	bab = AudioBabble.new(bank)
	bab.reset(4)
	_clock()
	_repro()
	_punctuation()
	_moods()
	_gestures()
	_director_schema()
	_new_ids()
	_bank_cost()
	_sim_untouched()
	_ab_voices()
	print("\nbabble check %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func _plan(voice: String, text: String, mood: String, intensity: int = 1, sd: int = 7, cues: Array = []) -> AudioBabble.Plan:
	return bab.plan(voice, text, mood, intensity, cues, sd)


func _syl(P: AudioBabble.Plan) -> Array:
	return P.events.filter(func(e): return e.kind == "syl")


func _mean(a: Array, key: String) -> float:
	var s: float = 0.0
	for e in a:
		s += float(e.get(key))
	return s / maxf(float(a.size()), 1.0)


func _clock() -> void:
	print("1. the clock")
	var path := "res://ui/core/ui_bark_timing.gd"
	if not ResourceLoader.exists(path):
		print("  skip  ui_bark_timing.gd is not in this checkout")
		return
	var U = load(path)
	var worst: float = 0.0
	for text in ["Good. You came. Now show me everything.", "Not the chip! Anything but the chip!", "...Enough. Leave.", "A, b; c: d - e — f … g"]:
		for inten in range(4):
			var T: PackedFloat64Array = bab.times(text, inten)
			worst = maxf(worst, absf(T[text.length()] - U.reveal_total(text, inten)))
			for i in range(0, text.length(), 3):
				worst = maxf(worst, absf(T[i] - U.time_for_char(text, i, inten)))
	ok(worst < 1e-6, "reveal times equal ui_bark_timing.gd's (worst difference %.9f s)" % worst)


func _repro() -> void:
	print("2. reproducible")
	var t := "That was somebody's roof. I'll help rebuild it once I'm done here."
	var a := _plan("protagonist", t, "hurt", 1, 11)
	var b := _plan("protagonist", t, "hurt", 1, 11)
	var c := _plan("protagonist", t, "hurt", 1, 12)
	var d := _plan("protagonist", t + "!", "hurt", 1, 11)
	ok(a.digest() == b.digest(), "same seed, same plan (%s)" % a.digest())
	ok(a.digest() != c.digest(), "another seed gives another plan")
	ok(a.digest() != d.digest(), "another line gives another plan")
	bab.reset(5)
	var l := {"id": "x.1", "text": t, "mood": "hurt", "intensity": 1}
	var s1 := SimCore.createSim()
	SimCore.newMatch(s1, 5)
	var p1: AudioBabble.Plan = bab.speak_line(s1, 0, l)
	bab.reset(5)
	var p2: AudioBabble.Plan = bab.speak_line(s1, 0, l)
	bab.reset(6)
	var p3: AudioBabble.Plan = bab.speak_line(s1, 0, l)
	SimCore.dispose(s1)
	ok(p1 != null and p1.digest() == p2.digest(), "speak_line: the same match seed and line give the same plan")
	ok(p1.digest() != p3.digest(), "speak_line: another match seed gives another plan")
	bab.reset(4)


func _punctuation() -> void:
	print("3. punctuation")
	var q := _syl(_plan("protagonist", "Is there really a manager here?", "neutral", 1, 3))
	var head: Array = q.slice(0, q.size() - 4)
	ok(q[q.size() - 1].st - _mean(head, "st") > 3.0, "a question rises: last syllable %.1f st against %.1f before" % [q[q.size() - 1].st, _mean(head, "st")])
	var e := _syl(_plan("protagonist", "I suppose that is that...", "neutral", 1, 3))
	var ehead: Array = e.slice(0, e.size() - 3)
	ok(e[e.size() - 1].gain_db < _mean(ehead, "gain_db") - 3.0 and e[e.size() - 1].st < _mean(ehead, "st") - 2.0, "an ellipsis trails away: last %.1f st %.1f dB, before %.1f st %.1f dB" % [e[e.size() - 1].st, e[e.size() - 1].gain_db, _mean(ehead, "st"), _mean(ehead, "gain_db")])
	var x := _syl(_plan("protagonist", "That was a great big brilliant CHIP!", "neutral", 1, 3))
	var xr: Array = x.slice(0, x.size() - 3)
	var top: float = -99.0
	for s in x.slice(x.size() - 3):
		top = maxf(top, s.st)
	ok(top - _mean(xr, "st") > 2.5, "an exclamation punches its last word: %.1f st against %.1f before" % [top, _mean(xr, "st")])
	var caps := _syl(_plan("empress", "We appeal and appeal and APPEAL.", "neutral", 1, 3))
	var m: float = _mean(caps.slice(0, caps.size() - 3), "gain_db")
	ok(caps[caps.size() - 3].gain_db > m + 1.5 or caps[caps.size() - 2].gain_db > m + 1.5, "an ALL-CAPS word is louder")


func _moods() -> void:
	print("4. moods (mean over 24 seeds, the same 60-character line)")
	var t := "Hold on now, this is going to take a little while, I think."
	var stat: Dictionary = {}
	for mood in ["neutral", "smug", "angry", "hurt", "desperate", "laughing"]:
		var st: float = 0.0
		var gap: float = 0.0
		var gain: float = 0.0
		var laughs: int = 0
		for s in range(24):
			var P := _plan("protagonist", t, mood, 1, 100 + s)
			var sy := _syl(P)
			st += _mean(sy, "st")
			gain += _mean(sy, "gain_db")
			gap += (sy[sy.size() - 1].t - sy[0].t) / maxf(float(sy.size() - 1), 1.0)
			laughs += P.count("laugh")
		stat[mood] = {"st": st / 24.0, "gap": gap / 24.0, "gain": gain / 24.0, "laughs": laughs}
		print("     %-9s pitch %+5.2f st, gap %.3f s, level %+5.1f dB, laughs %d" % [mood, st / 24.0, gap / 24.0, gain / 24.0, laughs])
	ok(stat.hurt.st < stat.neutral.st - 0.8 and stat.neutral.st < stat.desperate.st - 0.8, "pitch: hurt < neutral < desperate")
	ok(stat.angry.gap < stat.smug.gap, "pace: angry is quicker than smug")
	ok(stat.angry.gain > stat.hurt.gain + 3.0, "level: angry is louder than hurt")
	ok(stat.laughing.laughs > 0 and stat.neutral.laughs == 0, "laughing mood laughs, neutral does not")
	var digests: Dictionary = {}
	for v in ["protagonist", "anti_hero", "empress", "cyborg"]:
		var P := _plan(v, "Good. You came. Now show me everything.", "neutral")
		digests[P.digest()] = true
		for e in _syl(P):
			var syl: String = e.sound.split(".")[3]
			if not bank.babble.voices[v].lexicon.has(syl):
				ok(false, "%s spoke a syllable outside its lexicon: %s" % [v, syl])
	ok(digests.size() == 4, "the four voices babble differently")


func _gestures() -> void:
	print("5. laughs and gestures")
	var P := _plan("empress", "Ohoho. Cute. Cute!", "neutral")
	ok(P.count("laugh") >= 1, "\"Ohoho\" is a laugh event (%d)" % P.count("laugh"))
	var Q := _plan("protagonist", "Well then, here we go.", "neutral", 1, 7, [{"at": 0, "gesture": "laugh.short", "intensity": 2}, {"at": 10, "gesture": "sigh", "intensity": 1}])
	ok(Q.count("laugh") >= 1 and Q.count("grunt") >= 1, "cues become a laugh and a grunt (%d, %d)" % [Q.count("laugh"), Q.count("grunt")])
	var N := _plan("anti_hero", "Fine. Fine.", "hurt")
	var in_order := true
	for i in range(1, N.events.size()):
		in_order = in_order and N.events[i].t >= N.events[i - 1].t
	ok(in_order, "events are in time order")


func _director_schema() -> void:
	print("5b. Narrative's line schema and mood graph")
	var b: Dictionary = bank.babble
	var missing: Array = []
	for node in ["sizing_up", "playful", "cocky", "heated", "grim", "contemptuous", "rattled", "desperate", "triumphant", "spent", "reverent",
			"respectful-grim", "cold", "resolved", "polite", "hungry", "frantic", "grim-heated"]:
		var emo: String = String(b.mood_map.get(node, node))
		if not b.moods.has(emo):
			missing.append(node)
	ok(missing.is_empty(), "every mood node in dialogue-director.md maps to a babble mood (missing: %s)" % str(missing))
	var t := "He means it. That is what makes it unbearable."
	var cap := _plan("anti_hero", t, "contemptuous", 1, 21)
	var th := bab.plan("anti_hero", t, "contemptuous", 0, [], 21, "thought")
	var sh := bab.plan("anti_hero", t, "contemptuous", 3, [], 21, "shout")
	ok(th.inner and not cap.inner, "a thought is marked inner (played muffled)")
	ok(_mean(_syl(th), "gain_db") < _mean(_syl(cap), "gain_db") - 7.0, "a thought is quieter (%.1f against %.1f dB)" % [_mean(_syl(th), "gain_db"), _mean(_syl(cap), "gain_db")])
	ok(_syl(th).size() < _syl(cap).size(), "a thought is sparser (%d against %d syllables)" % [_syl(th).size(), _syl(cap).size()])
	ok(_mean(_syl(sh), "gain_db") > _mean(_syl(cap), "gain_db") + 2.0, "a shout is louder")
	var thl := bab.plan("protagonist", "Ha ha. Ohoho.", "playful", 0, [{"at": 0, "gesture": "laugh.short", "intensity": 1}], 3, "thought")
	ok(thl.count("laugh") == 0, "a thought never laughs aloud")
	var rat := bab.plan("anti_hero", "I can't feel my arms. Help me.", "rattled", 1, [], 5)
	var con := bab.plan("anti_hero", "I can't feel my arms. Help me.", "contemptuous", 1, [], 5)
	ok(rat.emotion == "cracked" and con.emotion == "smug", "the Anti-hero's rattled mood is his cracked-facade voice (%s, and %s otherwise)" % [rat.emotion, con.emotion])
	var s2 := SimCore.createSim()
	SimCore.newMatch(s2, 5)
	bab.reset(5)
	var line := {"id": "anti.callback.bridge.001", "kind": "thought", "text": t, "mood": "contemptuous", "cues": [], "display": {"style": "thought", "dur_s": 2.4}}
	var P: AudioBabble.Plan = bab.speak_line(s2, 1, line)
	SimCore.dispose(s2)
	ok(P != null and P.inner, "speak_line takes Narrative's line object (kind, display.style, mood, cues)")
	bab.reset(4)


## The babble finds a fighter's voice by its roster id (f.id), never by its display name: a mirror arm or a renamed label
## (PROTAGONIST-A) must not change it.
func _new_ids() -> void:
	print("5c. voices are found by roster id")
	var line := {"id": "t.new.1", "text": "Hold on now, I'll be fine in a minute.", "mood": "desperate", "intensity": 2}
	var digests: Array = []
	for label in [["PROTAGONIST", "RIVAL"], ["PROTAGONIST-A", "RIVAL-B"]]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5)
		ok(S.fighters[0].id == "PROTAGONIST" and S.fighters[1].id == "RIVAL", "the sim's roster ids are PROTAGONIST and RIVAL")
		S.fighters[0].name = label[0]
		S.fighters[1].name = label[1]
		bab.reset(5)
		var a: AudioBabble.Plan = bab.speak_line(S, 0, line)
		var b: AudioBabble.Plan = bab.speak_line(S, 1, line)
		ok(a != null and b != null and a.voice == "protagonist" and b.voice == "anti_hero", "labels %s and %s: the protagonist and anti-hero voices" % [label[0], label[1]])
		digests.append(str([a.digest(), b.digest()]))
		SimCore.dispose(S)
	ok(digests[0] == digests[1], "the same plans whatever the display label")
	bab.reset(4)


func _bank_cost() -> void:
	print("6. the bank")
	var total_ms: float = 0.0
	for v in ["protagonist", "anti_hero", "empress", "cyborg"]:
		var t0: int = Time.get_ticks_usec()
		var bytes: int = 0
		var n: int = 0
		for id in bank.babble_ids([v]):
			for k in range(bank.variants(id)):
				var w: AudioStreamWAV = bank.stream(id, k)
				bytes += w.data.size()
				n += 1
		var ms: float = (Time.get_ticks_usec() - t0) / 1000.0
		total_ms += ms
		print("     %-10s %3d clips, %4.0f KB, %5.0f ms" % [v, n, float(bytes) / 1024.0, ms])
	ok(total_ms < 4000.0, "all four voices render in %.0f ms" % total_ms)
	var t1: int = Time.get_ticks_usec()
	var P := _plan("protagonist", "That was somebody's roof. I'll help rebuild it once I'm done here.", "hurt")
	var plan_ms: float = (Time.get_ticks_usec() - t1) / 1000.0
	ok(plan_ms < 5.0, "planning a 66-character line takes %.2f ms (%d events)" % [plan_ms, P.events.size()])


func _sim_untouched() -> void:
	print("7. the sim is untouched")
	var hashes: Array = []
	for with_babble in [false, true]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 4)
		bab.reset(4)
		for t in range(1200):
			SimCore.step(S)
			if with_babble and t % 120 == 0:
				bab.speak_line(S, t % 2, {"id": "t%d" % t, "text": "Hold on now, I'll be fine in a minute.", "mood": "desperate", "intensity": 2})
			S.out.fx.clear()
			S.out.feed.clear()
		hashes.append(SimHash.stateHash(S).gameplay)
		SimCore.dispose(S)
	ok(str(hashes[0]) == str(hashes[1]), "gameplay hash after 1200 ticks is the same with and without babbling (%s)" % str(hashes[0]))


func _ab_voices() -> void:
	print("8. the A/B voices: growl and blip, booming laugh, lurching rhythm, baked shimmer")
	var ab: Dictionary = AudioBank.load_json("res://audio/data/babble_ab.json")
	var b2 := AudioBank.new()
	for k in ab.syllables:
		b2.babble.syllables[k] = ab.syllables[k]
	for k in ab.voices:
		b2.babble.voices[k] = ab.voices[k]
		var base: String = String(k).substr(0, String(k).rfind("_"))
		b2.babble.voice_moods[k] = b2.babble.voice_moods.get(base, {})
	var bb := AudioBabble.new(b2)
	bb.reset(4)
	# every letter's bank renders: no clip is empty or clipped
	var worst_peak: float = 0.0
	var empty: int = 0
	var clips: int = 0
	for v in ab.voices:
		for id in b2.babble_ids([v]):
			for var_i in range(b2.variants(id)):
				var buf: PackedFloat32Array = b2.buffer(id, var_i)
				clips += 1
				if buf.is_empty():
					empty += 1
				else:
					worst_peak = maxf(worst_peak, AudioDsp.peak(buf))
	ok(empty == 0 and worst_peak < 0.99, "every clip of the 8 letter voices renders (%d clips, none empty, loudest peak %.2f)" % [clips, worst_peak])
	ok(b2.has_sound("babble.cyborg_c.blip") and b2.has_sound("babble.empress_c.laugh_boom") and not b2.has_sound("babble.cyborg.blip") and not b2.has_sound("babble.empress.laugh_boom"), "the blip and the booming laugh exist for the letters that have them, and not for the current voices")
	# reproducible
	var line: String = "Protein. More protein! I can smell the marrow in your chassis."
	var d1: String = bb.plan("cyborg_c", line, "smug", 1, [], 11).digest()
	var d2: String = bb.plan("cyborg_c", line, "smug", 1, [], 11).digest()
	var d3: String = bb.plan("cyborg_c", line, "smug", 1, [], 12).digest()
	ok(d1 == d2 and d1 != d3, "a letter's plan is reproducible and varies with the seed")
	# the blip
	var blips: int = 0
	var blips_a: int = 0
	var in_notes: bool = true
	var min_gap_seen: float = 9.0
	for sd in range(12):
		var P := bb.plan("cyborg_c", line, "smug", 1, [], 100 + sd)
		blips += P.count("blip")
		blips_a += bb.plan("cyborg", line, "smug", 1, [], 100 + sd).count("blip")
		for e in P.events:
			if e.kind == "blip" and not (int(roundf(e.st)) in [0, 3, 7, 10]):
				in_notes = false
		var syl_t: Array = P.events.filter(func(e): return e.kind == "syl").map(func(e): return e.t)
		for i in range(1, syl_t.size()):
			min_gap_seen = minf(min_gap_seen, float(syl_t[i]) - float(syl_t[i - 1]))
	ok(blips > 0 and blips_a == 0, "the Cyborg C speaks growls with blips (%d in 12 lines); the current Cyborg has none" % blips)
	ok(in_notes, "each blip is one of the voice's four notes")
	var floor_gap: float = 0.6 * 0.055 * 0.85
	ok(min_gap_seen >= floor_gap - 0.001, "the lurching rhythm never packs two syllables closer than its shortest gap allows (%.3f s against %.3f)" % [min_gap_seen, floor_gap])
	# the booming laugh
	var boom_c: int = 0
	var boom_a: int = 0
	for e in bb.plan("empress_c", "Gahaha! Bring me their roof.", "smug", 1, [], 5).events:
		if e.kind == "laugh" and String(e.sound).ends_with("laugh_boom"):
			boom_c += 1
	for e in bb.plan("empress", "Gahaha! Bring me their roof.", "smug", 1, [], 5).events:
		if e.kind == "laugh":
			boom_a += 1
	var bright: int = 0
	for e in bb.plan("empress_c", "Hahaha! Bring me their roof.", "smug", 1, [], 5).events:
		if e.kind == "laugh" and not String(e.sound).ends_with("laugh_boom"):
			bright += 1
	ok(boom_c == 1 and boom_a == 0 and bright == 1, "'Gahaha' is the booming laugh for the Empress C only, 'Hahaha' stays her bright one (%d, %d, %d)" % [boom_c, boom_a, bright])
	var lb: PackedFloat32Array = b2.buffer("babble.empress_c.laugh_boom", 0)
	var lr: PackedFloat32Array = b2.buffer("babble.empress_c.laugh", 0)
	ok(_zcr(lb, b2.rate_of("babble.empress_c.laugh_boom")) < _zcr(lr, b2.rate_of("babble.empress_c.laugh")) * 0.8, "the booming laugh is lower than her bright one (%.0f against %.0f crossings a second)" % [_zcr(lb, 12000), _zcr(lr, 12000)])
	# the baked shimmer and comb lengthen a clip a little
	var raw_n: int = int(float(b2.babble.voices["empress"].syl_ms) * 0.001 * 12000.0)
	var sh: PackedFloat32Array = b2.buffer("babble.empress_c.base.be", 0)
	var cm: PackedFloat32Array = b2.buffer("babble.cyborg_b.base.gru", 0)
	ok(sh.size() > int(float(b2.babble.voices["empress_c"].syl_ms) * 0.001 * 12000.0) and cm.size() > int(float(b2.babble.voices["cyborg_b"].syl_ms) * 0.001 * 12000.0), "the Empress's early reflection and the Cyborg's comb tail are in the clip")
	# the current voices are unaffected by the new keys
	var cur: String = bb.plan("protagonist", "Good. You came. Now show me everything.", "playful", 1, [], 21).digest()
	var cur2: String = bab.plan("protagonist", "Good. You came. Now show me everything.", "playful", 1, [], 21).digest()
	ok(cur == cur2, "a current voice plans the same in a bank that also holds the letters")


func _zcr(buf: PackedFloat32Array, rate: int) -> float:
	var n: int = 0
	for i in range(1, buf.size()):
		if (buf[i - 1] < 0.0) != (buf[i] < 0.0):
			n += 1
	return float(n) / (float(buf.size()) / float(rate))
