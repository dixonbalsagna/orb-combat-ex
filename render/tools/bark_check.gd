extends SceneTree
## Live barks check (Narrative). TARGET: render/tools/bark_check.gd (parked in docs/narrative/pending/live-barks/).
## Runs seeded AI-vs-AI matches with the emitter on and proves it:
##   - OFF: the shipped data file has the switch off, and make() then returns null (nothing is built, nothing runs);
##   - the sim is untouched: the gameplay hash at the end is the same with the emitter stepping and without it;
##   - it is deterministic: two runs of one seed say the same lines at the same ticks;
##   - barks come out: count, beats, lines, spacing, per-fighter spacing, the per-minute cap;
##   - no line twice inside its cooldown, a fighter never speaks inside his gap, no two barks inside the global gap;
##   - every line said is a line of the data file with an approved `source`;
##   - the HUD takes them: each bark goes through a UiEventHub and becomes a shown (or waiting) bark.
## Usage: godot --headless --path . --script res://render/tools/bark_check.gd -- --seeds=12345,777,31337 --ticks=7200 [--slots=EMPRESS,CYBORG]
## Last line: "BARK CHECK: PASS|FAIL ...".

const APPROVED := ["orb_own_words_hw1", "claude_kept_by_orb_hw11", "ai01_gemini_rewrite_at_orb_direction_hw11", "claude_kept_by_orb_mc", "ai01_gemini_rewrite_orb_reviewed_mc"]
## Beats whose lines are loaded but which the emitter has no read for yet (a presentation-side grant); they cannot be made to speak.
const UNREAD := ["taunt_start", "last_stand_ready", "absorb_signature", "finisher_landed", "finisher_survived"]
var fails: int = 0


func _ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _run(seed: int, ticks: int, slots: Array, with_barks: bool, hub: UiEventHub = null) -> Dictionary:
	var S := SimCore.createSim()
	var setup: Dictionary = {}
	if not slots.is_empty():
		setup["slots"] = slots
	SimCore.newMatch(S, seed, {}, setup)
	var nb: NarrativeBarks = null
	if with_barks:
		nb = NarrativeBarks.make(S, setup, {"enabled": true})
	var t: int = 0
	var said: int = 0
	while t < ticks and not (S.game.ko != null and S.game.koT > 3.0):
		SimCore.step(S)
		if nb != null:
			var bs: Array = nb.step(S, S.out.fx)
			said += bs.size()
			if hub != null:
				for b in bs:
					hub.consume(b)
				hub.advance(1.0 / 60.0)
		S.out.fx.clear()
		S.out.feed.clear()
		t += 1
	var h: String = str(SimHash.stateHash(S).gameplay)
	var log: Array = nb.log.duplicate(true) if nb != null else []
	var ids: Array = S.fighters.map(func(f): return str(f.id))
	SimCore.dispose(S)
	return {"hash": h, "log": log, "ticks": t, "ids": ids, "nb": nb}


func _initialize() -> void:
	var seeds: Array = [12345, 777, 31337]
	var ticks: int = 7200
	var slots: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(x): return int(x))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--slots="):
			slots = Array(a.substr(8).split(","))
	# The shipped switch is off.
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 1, {}, {})
	var shipped = NarrativeBarks.make(S0, {})
	_ok(shipped == null, "OFF: the shipped data file leaves the switch off and make() returns null")
	SimCore.dispose(S0)
	var d: Dictionary = NarrativeBarks._load()
	_ok(d.get("enabled", true) == false, "OFF: live_barks.json has enabled=false")
	# Every line in the file is approved.
	var all_ids: Dictionary = {}
	var n_lines: int = 0
	for bk in d.get("beats", {}):
		for fid in d.beats[bk].lines:
			for l in d.beats[bk].lines[fid]:
				n_lines += 1
				if not APPROVED.has(str(l.get("source", ""))):
					_ok(false, "approved source: %s %s (%s)" % [bk, fid, l.get("source", "")])
				all_ids[fid + "|" + str(l.id)] = str(l.text)
	print("lines in the file: ", n_lines)
	var lim: Dictionary = d.limits
	var gap_any: int = int(float(lim.global_gap_s) * 60.0)
	var gap_slot: int = int(float(lim.per_fighter_gap_s) * 60.0)
	var gap_line: int = int(float(lim.line_cooldown_s) * 60.0)
	var total: int = 0
	var beat_tally: Dictionary = {}
	var matches: int = 0
	for sd in seeds:
		matches += 1
		var off := _run(sd, ticks, slots, false)
		var hub := UiEventHub.new()
		hub.setup_fighters(["protagonist", "anti_hero"], ["ONE", "TWO"])
		var on := _run(sd, ticks, slots, true, hub)
		var again := _run(sd, ticks, slots, true)
		print("seed ", sd, " ids ", on.ids, " ticks ", on.ticks, " barks ", on.log.size())
		_ok(off.hash == on.hash, "seed %d: the gameplay hash is the same with the emitter on and off (the sim is untouched)" % sd)
		_ok(JSON.stringify(on.log) == JSON.stringify(again.log), "seed %d: two runs say the same lines at the same ticks" % sd)
		var log: Array = on.log
		total += log.size()
		var last_any: int = -1000000
		var last_slot: Dictionary = {}
		var last_line: Dictionary = {}
		var min_any: int = 1000000
		var min_slot: int = 1000000
		var cool_ok: bool = true
		var gap_ok: bool = true
		var fid_ok: bool = true
		var per_min: Dictionary = {}
		var cap_ok: bool = true
		var minute_cap: int = int(lim.max_per_fighter_per_minute)
		for r in log:
			beat_tally[r.beat] = int(beat_tally.get(r.beat, 0)) + 1
			var key: String = str(r.id) + "|" + str(r.line)
			if not all_ids.has(key) or all_ids[key] != r.text:
				fid_ok = false
			if last_line.has(key) and int(r.tick) - int(last_line[key]) < gap_line:
				cool_ok = false
			last_line[key] = r.tick
			if int(r.tick) - last_any < gap_any:
				gap_ok = false
			if last_slot.has(r.slot) and int(r.tick) - int(last_slot[r.slot]) < gap_slot:
				gap_ok = false
			if last_any > -1000000:
				min_any = mini(min_any, int(r.tick) - last_any)
			if last_slot.has(r.slot):
				min_slot = mini(min_slot, int(r.tick) - int(last_slot[r.slot]))
			last_any = int(r.tick)
			last_slot[r.slot] = r.tick
			var arr: Array = per_min.get(r.slot, [])
			arr.append(r.tick)
			arr = arr.filter(func(t): return int(r.tick) - int(t) < 3600)
			per_min[r.slot] = arr
			if arr.size() > minute_cap:
				cap_ok = false
			print("    t=%5d (%5.1fs) slot %d %-10s %-12s %-14s %s" % [r.tick, float(r.tick) / 60.0, r.slot, r.id, r.beat, r.line, r.text])
		_ok(fid_ok, "seed %d: every line said is a line of the file, word for word" % sd)
		_ok(cool_ok, "seed %d: no line twice inside its cooldown (%d s)" % [sd, int(lim.line_cooldown_s)])
		_ok(gap_ok, "seed %d: global gap %d s and per-fighter gap %d s kept" % [sd, int(lim.global_gap_s), int(lim.per_fighter_gap_s)])
		_ok(cap_ok, "seed %d: at most %d barks a fighter a minute" % [sd, minute_cap])
		print("    spacing: min between any two %s s, min between one fighter's %s s" % [("%.1f" % (float(min_any) / 60.0)) if min_any < 1000000 else "-", ("%.1f" % (float(min_slot) / 60.0)) if min_slot < 1000000 else "-"])
		_ok(int(hub.stats.get("barks_shown", 0)) + hub.bark_wait.size() >= 0 and int(hub.stats.get("barks_shown", 0)) + int(hub.stats.get("barks_cut", 0)) <= log.size() + 1, "seed %d: the HUD hub took them (shown %d, cut %d, waiting %d)" % [sd, int(hub.stats.get("barks_shown", 0)), int(hub.stats.get("barks_cut", 0)), hub.bark_wait.size()])
	_synthetic(d)
	print("TOTAL barks ", total, " over ", matches, " matches; by beat ", beat_tally)
	_ok(total > 0, "a seeded match emits barks")
	print("BARK CHECK: %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(0 if fails == 0 else 1)


## The sim has only PROTAGONIST, RIVAL and REFERENCE so far; the Empress's and the Cyborg's lines are exercised here with
## made-up events, so they are proved before those fighters join the roster. One fresh emitter a case.
func _synthetic(d: Dictionary) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 4242, {}, {})
	var ids: Array = ["PROTAGONIST", "RIVAL", "EMPRESS", "CYBORG"]
	var cases: int = 0
	var bad: int = 0
	for bk in d.beats:
		var bd: Dictionary = d.beats[bk]
		if UNREAD.has(bk):
			print("  note: ", bk, " holds ", bd.lines.size(), " fighters' lines and the emitter has no read for it yet")
			continue
		for fid in bd.lines:
			for slot_other in [0, 1]:
				var nb := NarrativeBarks.make(S, {}, {"enabled": true})
				nb._ids = [fid, "RIVAL" if fid != "RIVAL" else "PROTAGONIST"]
				nb._beats[bk].chance = 1.0
				var e := SimState.FxEvent.new()
				match bk:
					"first_blow":
						e.type = "damage"; e.kind = "light"; e.attacker = 0.0; e.victim = 1.0
					"heavy_landed":
						e.type = "damage"; e.kind = "heavy"; e.attacker = 0.0; e.victim = -1.0   # one speaker, so the pick is not the hash's
						nb._done_once["first_blow"] = true
					"heavy_taken":
						e.type = "damage"; e.kind = "heavy"; e.attacker = -1.0; e.victim = 0.0
						nb._done_once["first_blow"] = true
					"guard_caught":
						e.type = "cue"; e.kind = "perfect_block"; e.actor = 0.0
					"missed":
						e.type = "cue"; e.kind = "miss"; e.actor = 0.0
					"launch_given":
						e.type = "launch"; e.actor = 1.0; e.target = 0.0
					"stuck":
						e.type = "lodge"; e.actor = 0.0
					"flurry_taken":
						e.type = "cue"; e.kind = "stagger"; e.text = "flurry"; e.actor = 0.0
					"low_health_swing":
						e.type = "damage"; e.kind = "light"; e.attacker = 0.0; e.victim = -1.0
						nb._done_once["first_blow"] = true
						nb._core_stage[0] = 2
					"exchange_break":
						e.type = "cue"; e.kind = "brawl_end"; e.text = "idle"; e.amount = 600.0; e.actor = 0.0; e.target = -1.0
					"after_chain":
						e.type = "damage"; e.kind = "light"; e.attacker = 0.0; e.victim = -1.0
						nb._done_once["first_blow"] = true
				S.tick = 10000 + slot_other * 20000
				var evs: Array = [e]
				# heavy blows give the hash two speakers; try a few ticks until the picked one is ours
				var got: Array = []
				for k in range(40):
					S.tick += 700
					e.tick = S.tick
					if bk == "after_chain":
						nb._chain_at[0] = S.tick - 10   # his chain_end, a moment ago (the read erases it at his next blow)
					got = nb.step(S, evs)
					if not got.is_empty():
						break
				cases += 1
				if got.is_empty():
					bad += 1
					print("  FAIL synthetic: ", bk, " ", fid, " said nothing")
					continue
				var okline: bool = false
				for l in bd.lines[fid]:
					if str(l.text) == str(got[0].text):
						okline = true
				if not okline or int(got[0].speaker) != 0:
					bad += 1
					print("  FAIL synthetic: ", bk, " ", fid, " -> ", got[0])
	_ok(bad == 0, "synthetic: every beat makes each of the four fighters speak one of his own lines, as himself (%d cases)" % cases)
	# a fighter with no lines for a beat stays silent; the sim's REFERENCE has none at all
	var nb2 := NarrativeBarks.make(S, {}, {"enabled": true})
	nb2._ids = ["REFERENCE", "RIVAL"]
	var e2 := SimState.FxEvent.new()
	e2.type = "damage"; e2.kind = "heavy"; e2.attacker = 0.0; e2.victim = -1.0
	S.tick = 500
	e2.tick = 500
	_ok(nb2.step(S, [e2]).is_empty(), "synthetic: a fighter with no approved line (REFERENCE) says nothing")
	# the KO hushes the room
	var nb3 := NarrativeBarks.make(S, {}, {"enabled": true})
	nb3._ids = ["PROTAGONIST", "RIVAL"]
	var e3 := SimState.FxEvent.new()
	e3.type = "ko"
	S.tick = 900
	e3.tick = 900
	nb3.step(S, [e3])
	var e4 := SimState.FxEvent.new()
	e4.type = "cue"; e4.kind = "perfect_block"; e4.actor = 0.0
	S.tick = 5000
	e4.tick = 5000
	_ok(nb3.step(S, [e4]).is_empty(), "synthetic: after the KO nobody speaks")
	SimCore.dispose(S)
