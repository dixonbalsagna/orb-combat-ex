"""warm-async-3 (docs/audio/pending/warm-async-3): the common hits first. Anchored edits to audio_bank.gd, audio_voices.gd and warm_async_check.gd as the
re-cut leaves them. Usage: python warm3_edits.py <root>"""
import os, sys


def edit(path, pairs):
    raw = open(path, encoding="utf-8", newline="").read()
    crlf = "\r\n" in raw
    t = raw.replace("\r\n", "\n")
    for old, new in pairs:
        assert t.count(old) == 1, (path, t.count(old), old[:80])
        t = t.replace(old, new)
    open(path, "w", encoding="utf-8", newline="").write(t.replace("\n", "\r\n") if crlf else t)


BANK_CONSTS = '''## The common hits, named by Performance's phone probe as the cues lost most (impact.light, impact.light.lite, impact.heavy, energy.bolt, then
## crater, whiff, medium): FIRST are the cheap ones (about 85 ms of CPU in all at 1x), rendered in the run's first slice and before anything
## else; SECOND are the dear ones (heavy, crater, medium, the blast), right after the intro's babble and grunts. Within a rank: this order.
const WARM_FIRST := ["impact.light", "impact.light.lite", "impact.whiff", "impact.guard", "impact.absorbed", "energy.bolt", "energy.bolt.lite", "windup.medium", "ui.launcher",
	"launcher.rest", "perfect.tick", "perfect.tok", "perfect.break", "charge.tick.light", "charge.tick.heavy", "energy.gather", "double.charge"]
const WARM_SECOND := ["impact.medium", "impact.heavy", "impact.crater", "energy.blast", "windup.heavy", "impact.double", "impact.medium.grind", "charge.hum", "charge.hum.y"]
'''

BANK_STATE = '''var boot_slice_us: int = 120000   # the run's first slice, inside warm() at boot: long enough for the FIRST set at 1x (a block of 0.1 s in a boot of 25 s or more)
var _boot_slice: bool = false
'''

BANK_RANK = '''func warm_rank(id: String) -> int:
	if WARM_FIRST.has(id):
		return 0
	if id.begins_with("babble."):
		return 1
	if id.begins_with("voice."):
		return 2
	if WARM_SECOND.has(id):
		return 3
	if id.begins_with("flash."):
		return 5
	if id.begins_with("drone.") or id.begins_with("amb.") or id.begins_with("surf."):
		return 6
	return 4


## The place of an id within its rank: the order of the lists above, else the bank's own order.
func _warm_pos(id: String, k: int) -> int:
	var a: int = WARM_FIRST.find(id)
	if a >= 0:
		return a
	var b: int = WARM_SECOND.find(id)
	return b if b >= 0 else k
'''

BANK_BEGIN = '''## The queue the run works through: each rank in turn, and within a rank the first variant of every sound, then the second of every sound,
## and so on, so every sound has one variant ready as early as possible (a cue for a variant not yet rendered plays another that is).
func warm_queue(with_extras: bool = true) -> Array:
	var plan: Array = warm_plan(with_extras)
	var q: Array = []
	var i: int = 0
	while i < plan.size():
		var r: int = warm_rank(String(plan[i]))
		var j: int = i
		var most: int = 1
		while j < plan.size() and warm_rank(String(plan[j])) == r:
			most = maxi(most, variants(String(plan[j])))
			j += 1
		for v in range(most):
			for k in range(i, j):
				if v < variants(String(plan[k])) and not _cache.has("%s#%d" % [plan[k], v]):
					q.append([String(plan[k]), v])
		i = j
	return q


## Queue that and start the frame-by-frame run (its first slice, here, renders the cheap common hits).
func warm_async_begin(with_extras: bool = true) -> void:
	_wq.append_array(warm_queue(with_extras))
	_boot_slice = true
	if not warming and not _wq.is_empty():
		Callable(self, "_warm_run").call()
'''

BANK_READY = '''## The variant of this sound to play now: the one asked for if it is rendered, else any that is (the variants differ by a little pitch, decay
## and level only), else -1.
func pick_ready(id: String, variant: int) -> int:
	var n: int = variants(id)
	var v: int = posmod(variant, n)
	if _cache.has("%s#%d" % [id, v]):
		return v
	for k in range(n):
		if _cache.has("%s#%d" % [id, k]):
			return k
	return -1


'''

edit(os.path.join(sys.argv[1], "audio/audio_bank.gd"), [
    ("signal warmed                     # the async warm-up has rendered everything it was given\n", BANK_CONSTS + "signal warmed                     # the async warm-up has rendered everything it was given\n" + BANK_STATE),
    ('''func warm_rank(id: String) -> int:
	if id.begins_with("babble."):
		return 0
	if id.begins_with("voice."):
		return 1
	if id.begins_with("flash."):
		return 3
	if id.begins_with("drone.") or id.begins_with("amb.") or id.begins_with("surf."):
		return 4
	return 2
''', BANK_RANK),
    ("		order.append([warm_rank(String(all[k])), k, String(all[k])])\n", "		order.append([warm_rank(String(all[k])), _warm_pos(String(all[k]), k), String(all[k])])\n"),
    ('''## Queue that plan and start the frame-by-frame run.
func warm_async_begin(with_extras: bool = true) -> void:
	warm_ids_async(warm_plan(with_extras))
''', BANK_BEGIN),
    ("	AudioSlice.budget_us = _pick_budget()\n	AudioSlice.start_frame()\n", "	AudioSlice.budget_us = boot_slice_us if _boot_slice else _pick_budget()\n	_boot_slice = false\n	AudioSlice.start_frame()\n"),
    ("## Is this variant rendered (so a play is free)?\n", BANK_READY + "## Is this variant rendered (so a play is free)?\n"),
])

edit(os.path.join(sys.argv[1], "audio/audio_voices.gd"), [
    ('''	if bank.warming and not bank.is_ready(cue.sound, cue.variant):
		_defer(cue, cam_x, zoom)      # not rendered yet: its sound goes to the front of the queue, and the cue waits for it
		return false
''', '''	var vsel: int = cue.variant
	if bank.warming and not bank.is_ready(cue.sound, vsel):
		vsel = bank.pick_ready(cue.sound, vsel)      # another variant of the same sound is rendered: play that one
		if vsel < 0:
			_defer(cue, cam_x, zoom)      # none is: its sound goes to the front of the queue, and the cue waits for it
			return false
'''),
    ("	p.stream = _looped(bank.stream(cue.sound, cue.variant)) if cue.loop else bank.stream(cue.sound, cue.variant)\n", "	p.stream = _looped(bank.stream(cue.sound, vsel)) if cue.loop else bank.stream(cue.sound, vsel)\n"),
    ('''		if bank.is_ready(c.sound, c.variant):
			var own_ms: float = bank.stream(c.sound, c.variant).get_length() * 1000.0 / maxf(c.pitch, 0.1)
''', '''		var pv: int = bank.pick_ready(c.sound, c.variant)
		if pv >= 0:
			var own_ms: float = bank.stream(c.sound, pv).get_length() * 1000.0 / maxf(c.pitch, 0.1)
'''),
])

edit(os.path.join(sys.argv[1], "audio/tools/warm_async_check.gd"), [
    ("\tasync_bank.pending_budget_us = budget_us\n", "\tasync_bank.pending_budget_us = budget_us\n\tasync_bank.boot_slice_us = budget_us\n"),
    ("\tc7.sound = \"impact.light\"\n", "\tc7.sound = \"impact.crater\"          # a dear hit, not in the cheap set rendered in the first slice\n"),
    ("bank7.skipped_log[0].sound == \"impact.light\"", "bank7.skipped_log[0].sound == \"impact.crater\""),
    ("a cue that would play later than its own length is lost, and named: %s", "a cue that would play later than its own length is lost, and named: %s"),
    ("\tb6r.warm_quiet = 1\n\tAudioSlice.max_slice_us = 0\n", "\tb6r.warm_quiet = 1\n\tb6r.boot_slice_us = b6r.quiet_budget_us\n\tAudioSlice.max_slice_us = 0\n"),
    ('''	ok(sync_bank.warm_rank(String(plan[0])) == 0 and sync_bank.warm_rank(String(plan[plan.size() - 1])) >= 3, "it starts with the intro's babble and ends with the optional sets (%s ... %s)" % [plan[0], plan[plan.size() - 1]])
''', '''	ok(sync_bank.warm_rank(String(plan[0])) == 0 and sync_bank.warm_rank(String(plan[plan.size() - 1])) >= 5, "it starts with the cheap common hits and ends with the optional sets (%s ... %s)" % [plan[0], plan[plan.size() - 1]])
	var first_n: int = AudioBank.WARM_FIRST.size()
	var first_ok: bool = true
	for k in range(first_n):
		first_ok = first_ok and String(plan[k]) == String(AudioBank.WARM_FIRST[k])
	ok(first_ok, "the first %d are the cheap common hits in their order (impact.light first); the babble and the grunts follow, then the dear hits (heavy, crater, medium, blast)" % first_n)
	var q0: Array = sync_bank.warm_queue(true)
	var seen_v1: bool = false
	var vmajor: bool = true
	for k in range(q0.size()):
		var qe: Array = q0[k]
		if sync_bank.warm_rank(String(qe[0])) != 0:
			break
		if int(qe[1]) >= 1:
			seen_v1 = true
		elif seen_v1:
			vmajor = false
	ok(vmajor and int(q0[0][1]) == 0 and String(q0[0][0]) == "impact.light" and String(q0[1][0]) == "impact.light.lite", "the queue takes the first variant of every common hit before the second of any (impact.light#0, impact.light.lite#0, ...)")
'''),
    ('''	print("\\nwarm async check %s"''', '''	print("8. the common hits first")
	var bank8 := AudioBank.new()
	var v8 := AudioVoices.new(bank8)
	root.add_child(v8)
	await process_frame
	bank8.boot_slice_us = 30000          # a short first slice for this test: the first variants of the cheap hits, not all of them
	bank8.warm_async_begin(false)
	ok(bank8.is_ready("impact.light", 0) and bank8.is_ready("energy.bolt", 0), "the run's first slice (inside warm(), %.0f ms) has rendered the cheap common hits' first variants" % (float(bank8.boot_slice_us) / 1000.0))
	var asked: int = 0
	var pitch_cue := AudioCues.Cue.new()
	pitch_cue.sound = "impact.light"
	pitch_cue.variant = 3
	pitch_cue.gain_db = -6.0
	pitch_cue.pitch = 1.0
	pitch_cue.bus = "Sfx"
	var took: bool = v8.play(pitch_cue, 0.0, 1.0)
	ok(bank8.warming and not bank8.is_ready("impact.light", 3) and took and bank8.deferred_n == 0 and bank8.skipped == 0, "a cue for a variant not yet rendered plays another variant of the same sound at once (waiting %d, skipped %d)" % [bank8.deferred_n, bank8.skipped])
	ok(bank8.pick_ready("impact.light", 3) >= 0 and bank8.pick_ready("impact.crater", 0) == -1, "pick_ready gives the asked variant, else a rendered one, else -1")
	await _wait_warmed(bank8)
	v8.queue_free()

	print("\\nwarm async check %s"'''),
])
print("warm-async-3 edits applied")
