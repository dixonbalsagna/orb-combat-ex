extends SceneTree
## Render the babble A/B reels (docs/audio/babble-vs-gemini.md, homework/34-voices-ab.md): for each fighter one reel with the
## same two lines said three ways, in a shuffled order, so Orb can pick by ear. From the repo root:
##   godot --headless --path . --script res://audio/tools/render_babble_ab.gd [-- --out=DIR]
## A is the voice in data/babble.json as it is. B is Gemini's numbers played by our seeded plan with its bus chain baked. C is
## the hybrid. The letters' voices are in data/babble_ab.json and are merged into the bank here only; the game never sees
## them. Writes DIR/reel-<voice>.wav (default audio/preview/ab) and DIR/ANSWERS.md, which says what each reel's order is:
## do not read it before listening. Mono 16-bit at the babble's own rate (12 kHz). Deterministic: the same files every run.

const SUFFIX: Dictionary = {"A": "", "B": "_b", "C": "_c"}
const VOICE_NAMES: Dictionary = {"protagonist": "the Protagonist", "anti_hero": "the Rival (the Anti-hero)", "empress": "the Empress", "cyborg": "the Cyborg"}


func _init() -> void:
	var out_dir: String = ProjectSettings.globalize_path("res://audio/preview/ab")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var ab: Dictionary = AudioBank.load_json("res://audio/data/babble_ab.json")
	var bank := AudioBank.new()
	for k in ab.syllables:
		bank.babble.syllables[k] = ab.syllables[k]
	for k in ab.voices:
		bank.babble.voices[k] = ab.voices[k]
	for k in ab.voices:
		# the letters' voices speak with the base voice's grunts and mood overrides, so only the numbers differ
		var base: String = String(k).substr(0, String(k).rfind("_"))
		if bank.grunts.voices.has(base):
			bank.grunts.voices[k] = bank.grunts.voices[base]
		bank.babble.voice_moods[k] = bank.babble.voice_moods.get(base, {})
	var bab := AudioBabble.new(bank)
	var caps: Dictionary = AudioBank.load_json("res://audio/data/babble_captions.json").captions
	var rate: int = int(bank.babble.rate)
	var answers := PackedStringArray()
	answers.append("# A/B reels: the answer sheet\n")
	answers.append("**Do not read this before you have listened to a reel.** Each reel plays the same two lines three times in the order below. A is the voice as it is today, B is Gemini's numbers, C is the hybrid.\n")
	answers.append("| Reel | First | Second | Third |")
	answers.append("| :--- | :--- | :--- | :--- |")
	var detail := PackedStringArray()
	var total_bytes: int = 0
	for voice in ["protagonist", "anti_hero", "empress", "cyborg"]:
		var order: Array = _shuffled(["A", "B", "C"], SimRng.deriveSeed(int(ab.seed), "ab." + voice))
		var lines: Array = []
		for spec in ab.reels[voice]:
			if spec.has("caption"):
				lines.append(caps[voice][int(spec.caption)])
			else:
				lines.append(spec)
		var reel := PackedFloat32Array()
		var click := _click(rate)
		for letter in order:
			var vid: String = voice + String(SUFFIX[letter])
			var seg := PackedFloat32Array()
			var kinds: Dictionary = {}
			var k: int = 0
			for ln in lines:
				var plan = bab.plan(vid, String(ln.text), String(ln.mood), int(ln.intensity), [], int(ab.seed) + 17 * k)
				var clip: PackedFloat32Array = bab.mix(plan, rate)
				for ev in plan.events:
					kinds[ev.kind] = int(kinds.get(ev.kind, 0)) + 1
				AudioDsp.mix_into(seg, clip, seg.size() + (int(0.6 * rate) if k > 0 else 0), 1.0)
				k += 1
			print("   %s %s: %s" % [voice, letter, str(kinds)])
			_level(seg, -20.0)
			AudioDsp.mix_into(reel, click, reel.size() + int(0.5 * rate), 1.0)
			AudioDsp.mix_into(reel, seg, reel.size() + int(0.15 * rate), 1.0)
		AudioDsp.normalize(reel, AudioDsp.db_to_lin(-3.0))
		AudioDsp.fade(reel, 0.01, 0.3, rate)
		var path: String = "%s/reel-%s.wav" % [out_dir, voice]
		var err: int = AudioDsp.to_wav(reel, rate).save_to_wav(path)
		total_bytes += reel.size() * 2
		print("%s: %.1f s, error %d" % [path, float(reel.size()) / float(rate), err])
		answers.append("| %s (`reel-%s.wav`) | %s | %s | %s |" % [VOICE_NAMES[voice], voice, order[0], order[1], order[2]])
		detail.append("- **%s**: A is `%s`; B is `%s` (%s); C is `%s` (%s). Lines: %s" % [VOICE_NAMES[voice], voice, voice + "_b", bank.babble.voices[voice + "_b"].label, voice + "_c", bank.babble.voices[voice + "_c"].label, " / ".join(lines.map(func(l): return '"%s"' % String(l.text)))])
	answers.append("")
	answers.append_array(detail)
	answers.append("")
	answers.append("B's bus chain (chorus, reflection, crush, comb) is approximated by baked versions made by our own code, because a headless run cannot run the engine's live effects; the real chain would be judged on the web build with a window open.")
	var f := FileAccess.open(out_dir + "/ANSWERS.md", FileAccess.WRITE)
	f.store_string("\n".join(answers) + "\n")
	f.close()
	print("total %.1f MB" % (float(total_bytes) / 1048576.0))
	quit(0)


## The permutation of `items` the seed gives (Fisher-Yates on our own stream, so the same on every machine).
func _shuffled(items: Array, sd: int) -> Array:
	var a: Array = items.duplicate()
	var rnd := AudioDsp.Rand.new(sd)
	for burn in range(8):
		rnd.next()          # the first draws of nearby seeds are alike; let the stream settle
	for i in range(a.size() - 1, 0, -1):
		var j: int = int(rnd.next() * float(i + 1)) % (i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
	return a


## Scale a buffer so its RMS (over its non-silent part) is `db`, so a letter is never picked for being louder.
func _level(buf: PackedFloat32Array, db: float) -> void:
	var sum: float = 0.0
	var n: int = 0
	for x in buf:
		if absf(x) > 0.002:
			sum += x * x
			n += 1
	if n == 0:
		return
	var g: float = AudioDsp.db_to_lin(db) / maxf(sqrt(sum / float(n)), 1e-6)
	for i in range(buf.size()):
		buf[i] = clampf(buf[i] * g, -1.0, 1.0)


## A soft 40 ms tone between the three: where a new version starts.
func _click(rate: int) -> PackedFloat32Array:
	var n: int = int(0.04 * float(rate))
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t: float = float(i) / float(rate)
		out[i] = sin(TAU * 880.0 * t) * sin(PI * float(i) / float(n)) * AudioDsp.db_to_lin(-20.0)
	return out
