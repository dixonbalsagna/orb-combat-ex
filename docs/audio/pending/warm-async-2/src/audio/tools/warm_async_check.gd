extends SceneTree
## Does the audio warm-up across frames do the same work, a little at a time? (docs/audio/warm-async.md.) From the repo root:
##   godot --headless --path . --script res://audio/tools/warm_async_check.gd [-- --budget-us=1000]
## Checks:
##   1. the plan: warm_plan() is every sound warm() renders, once each, most wanted first (babble, grunts, hits and the rest, flashes, optional sets);
##   2. the work is bit-identical: every clip rendered across frames (a 1 ms budget, thousands of yields) has the same stream (format, rate, bytes)
##      as the one warm() renders in one block, for every id and variant the bank has, the set switched on;
##   3. the slices: the longest single run between two yields is about the budget (reported, and what a 4x slower CPU would make of the granularity);
##      the synths' sync wrappers still give the same answer while a run is suspended (a sound played un-warmed renders as ever);
##   4. a sound asked for before it is rendered is dropped while the warm-up runs (counted), and plays once it is rendered;
##   5. warm() itself stays one block in headless (as today) and the async path is only taken with a node in the tree and a screen;
##   6. the budget is adaptive: big while the host says nothing is playing (or, if it has not said, while no cue has been asked for a while), 6 ms in
##      play, a little more while cues wait;
##   7. a cue asked for while its sound is queued waits at the front of the queue and plays when the sound is rendered, with no sync render and
##      nothing skipped; a cue that would be later than its own length is lost, and named in the debug ring.
## Exit code 1 on any failure. No sound device is used (the dummy audio driver).

var fails: int = 0
var budget_us: int = 1000


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--budget-us="):
			budget_us = int(a.substr(12))
	_run.call_deferred()


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func _sig(w: AudioStreamWAV) -> String:
	return "%d|%d|%s|%d" % [w.format, w.mix_rate, str(w.stereo), hash_bytes(w.data)]


func hash_bytes(b: PackedByteArray) -> int:
	return b.hex_encode().sha256_text().hash()


func _wait_warmed(bank: AudioBank) -> void:
	if bank.warming:
		await bank.warmed


func _run() -> void:
	var sync_bank := AudioBank.new()
	sync_bank.world["enabled"] = true
	print("1. the plan")
	var plan: Array = sync_bank.warm_plan(true)
	var want: Array = []
	want.append_array(sync_bank.ids())
	want.append_array(sync_bank.extra_ids())
	var ranks_ok: bool = true
	for k in range(1, plan.size()):
		ranks_ok = ranks_ok and sync_bank.warm_rank(String(plan[k - 1])) <= sync_bank.warm_rank(String(plan[k]))
	var sorted_plan: Array = plan.duplicate()
	var sorted_want: Array = want.duplicate()
	sorted_plan.sort()
	sorted_want.sort()
	ok(sorted_plan == sorted_want and ranks_ok, "the plan is every sound warm() renders (%d ids), once each, in rank order (babble, grunts, hits, flashes, optional sets)" % plan.size())
	ok(sync_bank.warm_rank(String(plan[0])) == 0 and sync_bank.warm_rank(String(plan[plan.size() - 1])) >= 3, "it starts with the intro's babble and ends with the optional sets (%s ... %s)" % [plan[0], plan[plan.size() - 1]])

	print("2. bit-identical to the block")
	var t0: int = Time.get_ticks_usec()
	sync_bank.warm(true)
	var ms_sync: float = float(Time.get_ticks_usec() - t0) / 1000.0
	var async_bank := AudioBank.new()
	async_bank.world["enabled"] = true
	async_bank.quiet_budget_us = budget_us          # a small budget for the identity run: thousands of yields
	async_bank.play_budget_us = budget_us
	async_bank.pending_budget_us = budget_us
	AudioSlice.max_slice_us = 0
	AudioSlice.yields = 0
	var frames: int = 0
	var f0: int = Time.get_ticks_usec()
	async_bank.warm_async_begin(true)
	ok(async_bank.warming, "the run is on (a few milliseconds of it have already gone in the first slice)")
	# a sync play in the middle: an id the run has not reached renders at once, with the same bytes as later
	var last_id: String = String(plan[plan.size() - 1])
	var mid_sig: String = _sig(async_bank.stream(last_id, 0))
	ok(async_bank.is_ready(last_id, 0) and AudioSlice.on, "a sound asked for in the middle renders at once, as ever, and the run goes on (slicing is still on)")
	while async_bank.warming:
		await process_frame
		frames += 1
	var ms_async: float = float(Time.get_ticks_usec() - f0) / 1000.0
	ok(not AudioSlice.on and async_bank.warming == false, "the run ends and slicing is off again")
	var bad: int = 0
	var n: int = 0
	for id in plan:
		for v in range(sync_bank.variants(String(id))):
			n += 1
			if _sig(sync_bank.stream(String(id), v)) != _sig(async_bank.stream(String(id), v)):
				bad += 1
				print("    differs: %s#%d" % [id, v])
	ok(bad == 0 and n > 250, "%d clips across %d frames (%d yields, %.0f ms of waiting for frames, the block is %.0f ms): every stream the same as warm()'s (%d differ)" % [n, frames, AudioSlice.yields, ms_async, ms_sync, bad])
	ok(_sig(async_bank.stream(last_id, 0)) == mid_sig, "the sound rendered in the middle is the same one")

	print("3. the slices")
	var longest: float = float(AudioSlice.max_slice_us) / 1000.0
	print("    longest run between two yields: %.1f ms for a budget of %.1f ms (the overrun is the granularity of the checks: 256 iterations of the longest loop); a CPU 4 times slower makes the same budget run %.1f ms and the overrun %.1f ms" % [longest, float(budget_us) / 1000.0, float(budget_us) / 1000.0, maxf(longest - float(budget_us) / 1000.0, 0.0) * 4.0])
	ok(longest <= float(budget_us) / 1000.0 + 6.0, "no run is longer than the budget plus 6 ms (%.1f ms): at 4x CPU the granularity adds at most 4 times its 1x overrun to the budget, which stays under 50 ms" % longest)
	var overrun_4x: float = float(budget_us) / 1000.0 + maxf(longest - float(budget_us) / 1000.0, 0.0) * 4.0
	ok(overrun_4x < 50.0, "estimated longest main-thread call at 4x CPU: %.1f ms (the bar is about 50)" % overrun_4x)

	print("4. a sound asked for before it is rendered")
	var bank4 := AudioBank.new()
	var v4 := AudioVoices.new(bank4)
	root.add_child(v4)
	await process_frame
	ok(bank4.async_ok, "AudioVoices tells the bank a node is there to give frames")
	var first_unready: String = "impact.crater"
	bank4.warm_async_begin(false)
	var cue := AudioCues.Cue.new()
	cue.sound = first_unready
	cue.variant = 0
	cue.x = 0.0
	cue.gain_db = -6.0
	cue.pitch = 1.0
	cue.bus = "Sfx"
	var held: bool = not v4.play(cue, 0.0, 1.0)
	ok(bank4.warming and not bank4.is_ready(first_unready, 0) and held and bank4.deferred_n == 1 and bank4.skipped == 0, "while warming, a sound not yet rendered holds the cue (waiting %d, skipped %d)" % [bank4.deferred_n, bank4.skipped])
	var front: Array = bank4._wq[0] if not bank4._wq.is_empty() else []
	ok(not front.is_empty() and front[0] == first_unready, "and its sound is first in the queue (%s)" % str(front))
	var waited: int = 0
	while not bank4.is_ready(first_unready, 0) and waited < 4000:
		await process_frame
		waited += 1
	await process_frame
	ok(bank4.is_ready(first_unready, 0) and bank4.deferred_played == 1 and bank4.deferred_n == 0 and bank4.skipped == 0, "it is rendered in the next slices (%d frames) and the cue plays (played late %d, skipped %d)" % [waited, bank4.deferred_played, bank4.skipped])
	await _wait_warmed(bank4)
	var played: bool = v4.play(cue, 0.0, 1.0)
	ok(not bank4.warming and played, "once the run is over it plays at once")
	v4.queue_free()

	print("5. warm() in headless")
	var bank5 := AudioBank.new()
	bank5.async_ok = true
	var ms5: float = bank5.warm(false)
	var all5: Array = bank5.ids()
	ok(not bank5.warming and ms5 > 0.0 and bank5.is_ready(String(all5[0]), 0) and bank5.is_ready(String(all5[all5.size() - 1]), 0), "with a node in the tree but no screen, warm() still renders everything in one block (%.0f ms), as today" % ms5)

	print("6. the budget")
	var b6 := AudioBank.new()
	b6.warm_quiet = 1
	ok(b6._pick_budget() == b6.quiet_budget_us and b6.quiet_budget_us >= 20000, "the host says nothing is playing (a card, a menu): %.0f ms a frame" % (float(b6._pick_budget()) / 1000.0))
	b6.warm_quiet = 0
	ok(b6._pick_budget() == b6.play_budget_us and b6.play_budget_us <= 8000, "the host says a fight is on: %.0f ms" % (float(b6._pick_budget()) / 1000.0))
	b6.deferred_n = 2
	ok(b6._pick_budget() == b6.pending_budget_us and b6.pending_budget_us > b6.play_budget_us and b6.pending_budget_us < b6.quiet_budget_us, "with cues waiting in play: %.0f ms" % (float(b6._pick_budget()) / 1000.0))
	b6.deferred_n = 0
	b6.warm_quiet = -1
	b6.last_ask_ms = Time.get_ticks_msec()
	var recent: int = b6._pick_budget()
	b6.last_ask_ms = Time.get_ticks_msec() - 5000
	var idle: int = b6._pick_budget()
	ok(recent == b6.play_budget_us and idle == b6.quiet_budget_us, "with no word from the host, the cue traffic decides: cues asked for a moment ago, %.0f ms; none for 5 s, %.0f ms" % [float(recent) / 1000.0, float(idle) / 1000.0])
	# the run really takes the budget the bank names, frame by frame
	var b6r := AudioBank.new()
	b6r.warm_quiet = 1
	AudioSlice.max_slice_us = 0
	b6r.warm_async_begin(false)
	while b6r.warming:
		await process_frame
	var quiet_longest: float = float(AudioSlice.max_slice_us) / 1000.0
	ok(quiet_longest > 10.0 and quiet_longest < 25.0 + 6.0, "in a run told nothing is playing the longest run between two yields is %.1f ms (the 25 ms budget plus one chunk): the run finishes in fewer frames" % quiet_longest)

	print("7. a cue that would be too late, and the names")
	var bank7 := AudioBank.new()
	var v7 := AudioVoices.new(bank7)
	root.add_child(v7)
	await process_frame
	bank7.warm_async_begin(false)
	var c7 := AudioCues.Cue.new()
	c7.sound = "impact.light"
	c7.variant = 0
	c7.gain_db = -6.0
	c7.pitch = 1.0
	c7.bus = "Sfx"
	v7.play(c7, 0.0, 1.0)
	ok(v7._deferred.size() == 1, "a cue is held")
	v7._deferred[0]["at"] = int(v7._deferred[0]["at"]) - 5000          # it has been waiting 5 s: far more than the light hit's own length
	var w7: int = 0
	while bank7.skipped == 0 and w7 < 4000:
		await process_frame
		w7 += 1
	ok(bank7.skipped == 1 and bank7.deferred_played == 0 and bank7.skipped_log.size() == 1 and bank7.skipped_log[0].sound == "impact.light" and bank7.skipped_log[0].why == "late", "a cue that would play later than its own length is lost, and named: %s" % bank7.skipped_report())
	for i in range(70):
		bank7.note_skip("impact.heavy", 0, "timeout", 6000.0)
	ok(bank7.skipped_log.size() == 64 and bank7.skipped_by_sound["impact.heavy"] == 70, "the debug ring keeps the last 64 and the counts keep all")
	await _wait_warmed(bank7)
	v7.queue_free()

	print("\nwarm async check %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)
