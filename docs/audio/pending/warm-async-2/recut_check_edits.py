import sys, os
path = os.path.join(sys.argv[1], "audio/tools/warm_async_check.gd")
raw = open(path, encoding="utf-8", newline="").read()
crlf = "\r\n" in raw
t = raw.replace("\r\n", "\n")


def rep(a, b):
    global t
    assert t.count(a) == 1, (t.count(a), a[:70])
    t = t.replace(a, b)


rep("##   5. warm() itself stays one block in headless (as today) and the async path is only taken with a node in the tree and a screen.\n",
    "##   5. warm() itself stays one block in headless (as today) and the async path is only taken with a node in the tree and a screen;\n"
    "##   6. the budget is adaptive: big while the host says nothing is playing (or, if it has not said, while no cue has been asked for a while), 6 ms in\n"
    "##      play, a little more while cues wait;\n"
    "##   7. a cue asked for while its sound is queued waits at the front of the queue and plays when the sound is rendered, with no sync render and\n"
    "##      nothing skipped; a cue that would be later than its own length is lost, and named in the debug ring.\n")
# section 4 used to expect the drop: it now expects the wait
rep('''	var dropped: bool = not v4.play(cue, 0.0, 1.0)
	ok(bank4.warming and not bank4.is_ready(first_unready, 0) and dropped and bank4.skipped == 1, "while warming, a sound not yet rendered is dropped, silently and counted (skipped %d)" % bank4.skipped)
	await _wait_warmed(bank4)
	var played: bool = v4.play(cue, 0.0, 1.0)
	ok(not bank4.warming and played, "once the run is over it plays")
''', '''	var held: bool = not v4.play(cue, 0.0, 1.0)
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
''')
rep('''	print("\\nwarm async check %s"''', '''	print("6. the budget")
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

	print("\\nwarm async check %s"''')
open(path, "w", encoding="utf-8", newline="").write(t.replace("\n", "\r\n") if crlf else t)
print("check edited")
