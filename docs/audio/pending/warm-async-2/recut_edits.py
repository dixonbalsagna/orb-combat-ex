"""The re-cut of the warm-async park (docs/audio/pending/warm-async-2): an adaptive budget, a sound asked for while it is queued jumps to the
front and the cue waits for it, and the cues lost are named. Anchored edits to slice.gd, audio_bank.gd and audio_voices.gd as the first park
leaves them. Usage: python recut_edits.py <root>"""
import os, sys


def edit(path, pairs):
    raw = open(path, encoding="utf-8", newline="").read()
    crlf = "\r\n" in raw
    t = raw.replace("\r\n", "\n")
    for old, new in pairs:
        assert t.count(old) == 1, (path, t.count(old), old[:80])
        t = t.replace(old, new)
    open(path, "w", encoding="utf-8", newline="").write(t.replace("\n", "\r\n") if crlf else t)


SLICE_VARS = '''static var budget_fn: Callable = Callable()   # asked for the budget at the start of every frame the run gets (the bank's: adaptive)
'''
SLICE_NEXT = '''	_t0 = Time.get_ticks_usec()
	if budget_fn.is_valid():
		budget_us = int(budget_fn.call())
'''

BANK_STATE = '''var warm_quiet: int = -1          # the host's word: 1 nothing is playing (a card, a menu, the sim paused), 0 a fight is on, -1 judge by the cue traffic
var quiet_budget_us: int = 25000  # microseconds of synthesis a frame while nothing is playing (a long frame costs nothing behind a card)
var play_budget_us: int = 6000    # ... while a fight is on
var pending_budget_us: int = 10000   # ... while cues wait for their sound in play
var last_ask_ms: int = -100000    # when AudioVoices was last asked for any cue (the traffic)
var quiet_after_ms: int = 1500    # no cue asked for this long is "nothing is playing" when the host has not said
var deferred_n: int = 0           # cues waiting in AudioVoices for their sound to be rendered
var deferred_played: int = 0      # cues that waited and then played
var skipped_log: Array = []       # debug ring of the last 64 cues lost: {sound, variant, why, late_ms, ms}
var skipped_by_sound: Dictionary = {}
'''

BANK_FUNCS = '''## The budget for the next frame of the run: big while nothing is playing, 6 ms in play, a little more while cues wait for their sound.
func _pick_budget() -> int:
	var quiet: bool = warm_quiet == 1 or (warm_quiet < 0 and Time.get_ticks_msec() - last_ask_ms > quiet_after_ms)
	if quiet:
		return quiet_budget_us
	if deferred_n > 0:
		return pending_budget_us
	return play_budget_us


## A cue is waiting for this sound: render it next (sliced like the rest), ahead of the queue.
func warm_want(id: String, variant: int) -> void:
	var v: int = posmod(variant, variants(id))
	for k in range(_wq.size()):
		if _wq[k][0] == id and _wq[k][1] == v:
			_wq.remove_at(k)
			break
	_wq.push_front([id, v])


## Name a cue that was lost (debug): why is "late" (it would have played later than its own length), "timeout" or "overflow".
func note_skip(id: String, variant: int, why: String, late_ms: float) -> void:
	skipped += 1
	skipped_by_sound[id] = int(skipped_by_sound.get(id, 0)) + 1
	skipped_log.append({"sound": id, "variant": variant, "why": why, "late_ms": int(late_ms), "ms": Time.get_ticks_msec()})
	if skipped_log.size() > 64:
		skipped_log.pop_front()


## The lost cues by sound, most first, for a probe to print.
func skipped_report() -> String:
	var rows: Array = []
	for k in skipped_by_sound:
		rows.append([int(skipped_by_sound[k]), String(k)])
	rows.sort()
	rows.reverse()
	var parts: PackedStringArray = []
	for r in rows:
		parts.append("%s x%d" % [r[1], r[0]])
	return "skipped %d: %s (played late: %d)" % [skipped, ", ".join(parts), deferred_played]


'''

VOICES_STATE = '''var _deferred: Array = []      # {cue, cam_x, zoom, at}: cues whose sound the warm-up has not rendered yet; they play when it has, if not too late
const DEFER_MAX := 24
const DEFER_TIMEOUT_MS := 6000
'''

VOICES_PROCESS = '''	_run_deferred()
'''

VOICES_FUNCS = '''## A cue for a sound the warm-up has not rendered: move that sound to the front of the queue, and hold the cue. It plays when the sound
## is ready if it would not be later than its own length; otherwise it is lost (and named in bank.skipped_log).
func _defer(cue: AudioCues.Cue, cam_x: float, zoom: float) -> void:
	bank.warm_want(cue.sound, cue.variant)
	if _deferred.size() >= DEFER_MAX:
		var o: Dictionary = _deferred.pop_front()
		bank.note_skip(o.cue.sound, o.cue.variant, "overflow", float(Time.get_ticks_msec() - int(o.at)))
	_deferred.append({"cue": cue, "cam_x": cam_x, "zoom": zoom, "at": Time.get_ticks_msec()})
	bank.deferred_n = _deferred.size()


func _run_deferred() -> void:
	if _deferred.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	var keep: Array = []
	for d in _deferred:
		var c: AudioCues.Cue = d.cue
		var late: float = float(now - int(d.at))
		if bank.is_ready(c.sound, c.variant):
			var own_ms: float = bank.stream(c.sound, c.variant).get_length() * 1000.0 / maxf(c.pitch, 0.1)
			if late > own_ms:
				bank.note_skip(c.sound, c.variant, "late", late)
			else:
				bank.deferred_played += 1
				play(c, d.cam_x, d.zoom)
		elif late > DEFER_TIMEOUT_MS:
			bank.note_skip(c.sound, c.variant, "timeout", late)
		else:
			keep.append(d)
	_deferred = keep
	bank.deferred_n = _deferred.size()


'''

root = sys.argv[1]
edit(os.path.join(root, "audio/synth/slice.gd"), [
    ("static var yields: int = 0\n", "static var yields: int = 0\n" + SLICE_VARS),
    ("	await Engine.get_main_loop().process_frame\n	_t0 = Time.get_ticks_usec()\n", "	await Engine.get_main_loop().process_frame\n" + SLICE_NEXT),
])
edit(os.path.join(root, "audio/audio_bank.gd"), [
    ("signal warmed                     # the async warm-up has rendered everything it was given\n", "signal warmed                     # the async warm-up has rendered everything it was given\n" + BANK_STATE),
    ("	AudioSlice.start_frame()\n	while not _wq.is_empty():\n", "	AudioSlice.budget_fn = Callable(self, \"_pick_budget\")\n	AudioSlice.budget_us = _pick_budget()\n	AudioSlice.start_frame()\n	while not _wq.is_empty():\n"),
    ("	AudioSlice.on = false\n	warming = false\n", "	AudioSlice.on = false\n	AudioSlice.budget_fn = Callable()\n	warming = false\n"),
    ("func _warm_run() -> void:\n", BANK_FUNCS + "func _warm_run() -> void:\n"),
])
edit(os.path.join(root, "audio/audio_voices.gd"), [
    ("const DUCK_RELEASE := 0.08     # seconds to come back up\n", "const DUCK_RELEASE := 0.08     # seconds to come back up\n" + VOICES_STATE),
    ("func _process(delta: float) -> void:\n	_clock += delta\n", "func _process(delta: float) -> void:\n	_clock += delta\n" + VOICES_PROCESS),
    ("func play(cue: AudioCues.Cue, cam_x: float, zoom: float = 1.0) -> bool:\n", "func play(cue: AudioCues.Cue, cam_x: float, zoom: float = 1.0) -> bool:\n	bank.last_ask_ms = Time.get_ticks_msec()      # the cue traffic: the warm-up's budget reads it when the host has not said\n"),
    ("	if bank.warming and not bank.is_ready(cue.sound, cue.variant):\n		bank.skipped += 1      # not rendered yet: dropped, silently, while the warm-up runs (the most wanted sounds are first)\n		return false\n",
     "	if bank.warming and not bank.is_ready(cue.sound, cue.variant):\n		_defer(cue, cam_x, zoom)      # not rendered yet: its sound goes to the front of the queue, and the cue waits for it\n		return false\n"),
    ("## How far a bus is held down right now, in dB (0 when it is not).\n", VOICES_FUNCS + "## How far a bus is held down right now, in dB (0 when it is not).\n"),
])
print("re-cut edits applied")
