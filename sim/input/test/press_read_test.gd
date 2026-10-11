extends SceneTree
## Headless checks for the press reader (sim/input/press_read.gd, docs/controls/agency-input.md 1a): holds, rhythm, mash and
## taps, the precedence between them, the beat windows (touch, assist, the player's offset), staleness, the mix, the log's size
## and its helpers, and that the numbers come from data. Pure functions, so the checks are plain arrays. From the repo root:
##   godot --headless --path . --script res://sim/input/test/press_read_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0
const NB: int = SimPressRead.NO_BEAT


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	_data()
	_log()
	_hold()
	_cells()
	_windup()
	_zip()
	_burst()
	_pairs()
	_flurries()
	_aread()
	_repress()
	_rhythm()
	_mash()
	_taps_and_stale()
	_windows()
	_mix()
	_grades()
	_timing()
	_section20_steady()
	_section20_hitstop()
	_freeze_own_tick()
	_section20_recipe()
	_release()
	_determinism()
	print("press_read_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


## A log of presses at `ticks` (light), each with the given beat offset (or NB), all released 3 ticks after the press.
func _mk(ticks: Array, beats: Array = [], kinds: Array = [], modes: Array = []) -> Array:
	var log: Array = []
	for k in range(ticks.size()):
		var kind: int = int(kinds[k]) if k < kinds.size() else SimPressRead.LIGHT
		var mode: int = int(modes[k]) if k < modes.size() else 0
		var b: int = int(beats[k]) if k < beats.size() else NB
		SimPressRead.push(log, kind, mode, int(ticks[k]), b)
		SimPressRead.release(log, kind, int(ticks[k]) + 3)
	return log


func _data() -> void:
	var p: Dictionary = SimPressRead.params()
	ok(p["logSize"] == 20 and p["mixShort"] == 5 and p["expireTicks"] == 90, "data: the log holds 20 presses, the recipe reads the latest 5, a press expires after 90 ticks")
	ok(p["holdTicks"] == SimInputData.ti(["tapHold", "holdStart"], 12) and p["holdTicks"] == 12, "data: a hold is the game's hold, 12 ticks")
	ok(p["beatHalf"] == 4 and p["touchBeatHalf"] == 5, "data: the beat window is 8 ticks, 10 on touch")
	ok(p["mashPresses"] == 4 and p["mashGap"] == 10 and p["mashClear"] == 20, "data: a mash is 4 presses 10 ticks apart or fewer, over after 20")
	ok(SimInputData.ti(["read", "debounce"], -1) == 2, "data: the debounce is 2 ticks")
	# A value in the file moves the reader.
	var saved = SimInputData.timing.get("read", null)
	SimInputData.timing["read"] = (saved as Dictionary).duplicate()
	SimInputData.timing["read"]["mashGap"] = 6
	ok(SimPressRead.params()["mashGap"] == 6, "data: a changed mashGap in the data is the reader's")
	SimInputData.timing["read"] = saved


func _log() -> void:
	var log: Array = []
	for k in range(25):
		SimPressRead.push(log, SimPressRead.LIGHT, 0, 100 + k * 10)
	ok(log.size() == 20, "log: 25 presses leave the last 20")
	ok(int(log[0]["down"]) == 150 and int(log[19]["down"]) == 340, "log: oldest first, the oldest dropped")
	SimPressRead.release(log, SimPressRead.LIGHT, 345)
	ok(int(log[19]["up"]) == 345 and int(log[18]["up"]) == 340, "log: a release closes the latest held entry of its kind (and a fresh press lets the one before go, at the point it was read)")
	var l2: Array = []
	SimPressRead.push(l2, SimPressRead.LIGHT, 0, 10)
	SimPressRead.push(l2, SimPressRead.HEAVY, 0, 12)
	SimPressRead.release(l2, SimPressRead.LIGHT, 14)
	ok(int(l2[0]["up"]) == 14 and int(l2[1]["up"]) == -1, "log: a release closes its own kind, not the latest entry")
	ok(SimPressRead.beat_offset(100, []) == NB, "beat: no blows is no beat")
	ok(SimPressRead.beat_offset(100, [90, 103, 130]) == -3, "beat: the nearest blow, and early is negative")
	ok(SimPressRead.beat_offset(100, [96]) == 4, "beat: late is positive")
	ok(SimPressRead.classify([], 100)["style"] == "none", "classify: an empty log reads as nothing")


func _hold() -> void:
	var log: Array = []
	SimPressRead.push(log, SimPressRead.HEAVY, 0, 100)
	ok(SimPressRead.classify(log, 105)["style"] == "taps" and SimPressRead.classify(log, 105)["hold_ticks"] == 5, "hold: down 5 ticks is not yet a hold")
	ok(SimPressRead.classify(log, 115)["style"] != "hold", "hold: 15 ticks of a heavy is not a hold (Y's cell is 16)")
	var c: Dictionary = SimPressRead.classify(log, 116)
	ok(c["style"] == "hold" and c["hold_ticks"] == 16, "hold: 16 ticks down is a heavy's hold, live, before the release")
	ok(SimPressRead.classify(log, 400)["style"] == "hold", "hold: a button still down stays a hold however long")
	SimPressRead.release(log, SimPressRead.HEAVY, 130)
	ok(SimPressRead.classify(log, 131)["style"] == "taps", "hold: released, it is over")
	# A tap that is released inside 12 ticks is never a hold.
	var t: Array = _mk([100])
	ok(SimPressRead.classify(t, 103)["style"] == "taps", "hold: a tap released at 3 ticks is a tap")
	# A hold beats a rhythm and a mash.
	var m: Array = _mk([100, 108, 116, 124], [0, 0, 0, 0])
	SimPressRead.push(m, SimPressRead.LIGHT, 0, 130, 0)
	ok(SimPressRead.classify(m, 143)["style"] == "hold", "hold: the precedence puts a hold over a rhythm and a mash")


## A one-press log of `kind` made in `stance`, down at 100 and released at 100 + `held` (still down if held < 0).
func _one(kind: int, stance: int, held: int) -> Array:
	var log: Array = []
	SimPressRead.push(log, kind, 0, 100, NB, -1, stance)
	if held >= 0:
		SimPressRead.release(log, kind, 100 + held)
	return log


## The hold of each cell (brawl second pass): X the burst's start 8; Y 16, B 32 in the martial stance, A 16 (the wind-up plus the grace);
## a stance's own signature (B outside the martial stance) the game's hold.
func _cells() -> void:
	var p: Dictionary = SimPressRead.params()
	ok(p["burstStart"] == 16 and p["windupMedium"] == 12 and p["windupHeavy"] == 28 and p["windupContext"] == 12 and p["windupGrace"] == 4, "cells: the data's wind-ups, the grace and the burst's start")
	ok(not p.has("holdHeavy") and not p.has("holdSig") and not p.has("holdSigCharging") and not p.has("holdContext") and not p.has("holdLight"), "cells: the old per-cell holds are retired")
	var cells: Array = [[SimPressRead.LIGHT, 0, 8, "X"], [SimPressRead.HEAVY, 0, 16, "Y"], [SimPressRead.SIG, 0, 32, "B"], [SimPressRead.SIG, 8, 12, "B in manoeuvre"], [SimPressRead.SIG, 2, 12, "B in energy"],
		[SimPressRead.SIG, 4, 12, "B in charging"], [SimPressRead.CONTEXT, 0, 16, "A"], [SimPressRead.HEAVY, 2, 16, "Y in energy (the blast)"]]
	for c in cells:
		var below: Dictionary = SimPressRead.classify(_one(c[0], c[1], -1), 100 + int(c[2]) - 1)
		var live: Dictionary = SimPressRead.classify(_one(c[0], c[1], -1), 100 + int(c[2]))
		var over: Dictionary = SimPressRead.classify(_one(c[0], c[1], int(c[2])), 100 + int(c[2]) + 1)
		ok(below["style"] != "hold", "cells: %s down %d ticks is not yet a hold" % [c[3], int(c[2]) - 1])
		ok(live["style"] == "hold", "cells: %s still down at %d ticks is a hold, live" % [c[3], c[2]])
		ok(over["style"] != "hold", "cells: %s let go is no longer a hold" % c[3])
	ok(SimPressRead.hold_ticks_for({"kind": SimPressRead.SIG, "stance": 4}, p) == 12 and SimPressRead.hold_ticks_for({"kind": SimPressRead.SIG}, p) == 32, "cells: an entry with no stance field reads as martial")
	ok(SimPressRead.hold_ticks_for({"kind": SimPressRead.HEAVY}, p, {"hold_ticks": 30}) == 30, "cells: a caller can set one number for every cell")
	# The CONTEXT kind has its own log slot and mix count, and does not stand in for a blow.
	var l: Array = []
	SimPressRead.push(l, SimPressRead.CONTEXT, 0, 100)
	SimPressRead.push(l, SimPressRead.LIGHT, 0, 110)
	SimPressRead.release(l, SimPressRead.CONTEXT, 105)
	ok(int(l[0]["up"]) == 105 and int(l[1]["up"]) == -1 and int(l[0]["stance"]) == 0, "context: a release closes its own kind; the stance field is stored")
	var m: Dictionary = SimPressRead.classify(l, 112)["mix_long"]
	ok(int(m.get("context", -1)) == 1 and int(m["light"]) == 1, "context: the mix counts it on its own")
	var s: Array = []
	SimPressRead.push(s, SimPressRead.LIGHT, 0, 100, NB, -1, 12)
	ok(int(s[0]["stance"]) == 12, "stance: the stance mask the press was made in is on the entry")


## A one-press log with live ticks: down at tick 100 (live `ld`), released `held` live ticks later (still down if held < 0).
func _live(kind: int, stance: int, held: int, ld: int = 50) -> Array:
	var log: Array = []
	SimPressRead.push(log, kind, 0, 100, NB, -1, stance, ld)
	if held >= 0:
		SimPressRead.release(log, kind, 100 + held, ld + held)
	return log


## windup_for, decision_for, charge_read and tap_throw_at (docs/controls/windup-read.md section 2).
func _windup() -> void:
	var p: Dictionary = SimPressRead.params()
	ok(SimPressRead.windup_for({"kind": SimPressRead.HEAVY}, p) == 12 and SimPressRead.windup_for({"kind": SimPressRead.SIG}, p) == 28 and SimPressRead.windup_for({"kind": SimPressRead.CONTEXT}, p) == 12, "windup: Y 12, B 28, A 12")
	ok(SimPressRead.windup_for({"kind": SimPressRead.LIGHT}, p) == -1 and SimPressRead.windup_for({"kind": SimPressRead.PAIR}, p) == -1, "windup: X and a pair have none")
	ok(SimPressRead.windup_for({"kind": SimPressRead.SIG, "stance": 1}, p) == -1 and SimPressRead.windup_for({"kind": SimPressRead.SIG, "stance": 4}, p) == -1, "windup: B outside the martial stance is the stance's own signature, no wind-up here")
	ok(SimPressRead.windup_for({"kind": SimPressRead.HEAVY, "stance": 2}, p) == 12 and SimPressRead.windup_for({"kind": SimPressRead.HEAVY, "stance": 4}, p) == -1, "windup: Y keeps its 12 in the energy stance (the blast), none under RT")
	ok(SimPressRead.decision_for({"kind": SimPressRead.HEAVY}, p) == 16 and SimPressRead.decision_for({"kind": SimPressRead.SIG}, p) == 32 and SimPressRead.decision_for({"kind": SimPressRead.CONTEXT}, p) == 16 and SimPressRead.decision_for({"kind": SimPressRead.LIGHT}, p) == -1, "decision: the wind-up plus the grace (16, 32, 16)")
	# Y: winding before 16, charge at 16 still down; a release at 16 or before is a tap, after it a charge.
	var y: int = SimPressRead.HEAVY
	ok(SimPressRead.charge_read(_live(y, 0, -1)[0], 50 + 5) == "winding", "charge_read: Y down 5 live ticks is winding")
	ok(SimPressRead.charge_read(_live(y, 0, -1)[0], 50 + 15) == "winding" and SimPressRead.charge_read(_live(y, 0, -1)[0], 50 + 16) == "charge", "charge_read: still down at 16 live ticks it is the charge")
	ok(SimPressRead.charge_read(_live(y, 0, 3)[0], 200) == "tap" and SimPressRead.charge_read(_live(y, 0, 12)[0], 200) == "tap" and SimPressRead.charge_read(_live(y, 0, 16)[0], 200) == "tap", "charge_read: a release at 3, 12 or 16 (inside the grace) is a tap")
	ok(SimPressRead.charge_read(_live(y, 0, 17)[0], 200) == "charge", "charge_read: a release at 17 is a charge's release")
	# B and A.
	ok(SimPressRead.charge_read(_live(SimPressRead.SIG, 0, 32)[0], 200) == "tap" and SimPressRead.charge_read(_live(SimPressRead.SIG, 0, 33)[0], 200) == "charge" and SimPressRead.charge_read(_live(SimPressRead.SIG, 0, -1)[0], 50 + 32) == "charge", "charge_read: B decides at 32")
	ok(SimPressRead.charge_read(_live(SimPressRead.CONTEXT, 0, 16)[0], 200) == "tap" and SimPressRead.charge_read(_live(SimPressRead.CONTEXT, 0, -1)[0], 50 + 16) == "charge", "charge_read: A decides at 16")
	ok(SimPressRead.charge_read(_live(SimPressRead.LIGHT, 0, 30)[0], 200) == "none" and SimPressRead.charge_read(_live(SimPressRead.SIG, 4, 30)[0], 200) == "none", "charge_read: X, and a stance's signature, have no wind-up read")
	# The live clock, not the real one: a freeze of 9 real ticks between the press and the release adds nothing.
	var f: Array = []
	SimPressRead.push(f, y, 0, 100, NB, -1, 0, 50)
	SimPressRead.release(f, y, 100 + 25, 50 + 14)   # 25 real ticks down, 14 live
	ok(SimPressRead.charge_read(f[0], 300) == "tap", "charge_read: a release made after a 11-tick freeze is read at its live point (14 of 16: a tap)")
	var g: Array = []
	SimPressRead.push(g, y, 0, 100, NB, -1, 0, 50)
	ok(SimPressRead.charge_read(g[0], 50 + 15) == "winding", "charge_read: still down at 15 live ticks, however long the real clock says")
	# Without live stamps the real ticks stand in.
	ok(SimPressRead.charge_read(_one(y, 0, 3)[0], 500) == "tap" and SimPressRead.charge_read(_one(y, 0, 20)[0], 500) == "charge", "charge_read: no live stamps, the real ticks stand in")
	# tap_throw_at: the wind-up's end, or the release if later (inside the grace).
	ok(SimPressRead.tap_throw_at(_live(y, 0, 3)[0]) == 50 + 12, "tap_throw_at: an early tap's blow lands when the wind-up ends (live 62)")
	ok(SimPressRead.tap_throw_at(_live(y, 0, 14)[0]) == 50 + 14, "tap_throw_at: a release in the grace goes at once, at the release (live 64)")
	ok(SimPressRead.tap_throw_at(_live(y, 0, 17)[0]) == -1 and SimPressRead.tap_throw_at(_live(y, 0, -1)[0]) == -1, "tap_throw_at: not a tap, no throw tick")
	ok(SimPressRead.tap_throw_at(_live(SimPressRead.SIG, 0, 5)[0]) == 50 + 28, "tap_throw_at: B's tap lands at 28")


func _burst() -> void:
	var x: int = SimPressRead.LIGHT
	var b0: Dictionary = SimPressRead.burst_read(_live(x, 0, -1)[0], 50 + 15)
	ok(not b0["ready"] and b0["held"] == 15 and b0["stance"] == 0, "burst: down 15 live ticks, not yet (a held X is one light and a 10-tick set until 16)")
	var b1: Dictionary = SimPressRead.burst_read(_live(x, 0, -1)[0], 50 + 16)
	ok(b1["ready"] and b1["since"] == 0, "burst: at 16 live ticks the burst is on")
	ok(SimPressRead.burst_read(_live(x, 0, -1)[0], 50 + 20)["since"] == 4, "burst: it counts the live ticks past its start")
	ok(not SimPressRead.burst_read(_live(x, 0, 30)[0], 500)["ready"], "burst: letting go ends it")
	ok(SimPressRead.burst_read(_live(x, 2, -1)[0], 50 + 10)["stance"] == 2, "burst: the stance is reported (the director rules a held X in the energy stance)")
	ok(not SimPressRead.burst_read(_live(SimPressRead.HEAVY, 0, -1)[0], 50 + 40)["ready"], "burst: only X has one")
	# The burst's own lights are the director's: nothing here pushes them. A real second press afterwards is an ordinary press.
	var log: Array = _live(x, 0, -1)
	ok(log.size() == 1, "burst: reading it adds nothing to the log")
	var c: Dictionary = SimPressRead.classify(log, 100 + 20)
	ok(c["style"] == "hold", "burst: the classifier calls a held X a hold, as the alchemist always did")


## pair_read, pair_commit (docs/controls/q19-input.md section 2; brawl second pass section 6).
func _pairs() -> void:
	var xk: int = SimPressRead.LIGHT
	var yk: int = SimPressRead.HEAVY
	var bk: int = SimPressRead.SIG
	var ak: int = SimPressRead.CONTEXT
	var p: Dictionary = SimPressRead.params()
	ok(p["pairWindow"] == 3 and p["pairFresh"] == 8, "pairs: the window 3 and the freshness 8 are data")
	# The four pairs, either order, in the same build (gap 0) and up to the window.
	var cases: Array = [[xk, yk, "xy"], [xk, ak, "xa"], [yk, bk, "yb"], [ak, bk, "ab"]]
	for c in cases:
		for gap in [0, 1, 2, 3]:
			var fwd: Array = []
			SimPressRead.push(fwd, c[0], 0, 100)
			SimPressRead.push(fwd, c[1], 0, 100 + gap)
			var r1: Dictionary = SimPressRead.pair_read(fwd)
			ok(r1.get("pair", "") == c[2] and r1["first"] == c[0] and r1["second"] == c[1] and r1["keep_light"] == (c[0] == xk), "pairs: %s forward at gap %d" % [c[2], gap])
			var back: Array = []
			SimPressRead.push(back, c[1], 0, 100)
			SimPressRead.push(back, c[0], 0, 100 + gap)
			var r2: Dictionary = SimPressRead.pair_read(back)
			ok(r2.get("pair", "") == c[2] and r2["keep_light"] == (c[1] == xk), "pairs: %s the other way at gap %d (a light pressed first is the one kept)" % [c[2], gap])
	# Outside the window, not a pair.
	var late: Array = []
	SimPressRead.push(late, xk, 0, 100)
	SimPressRead.push(late, yk, 0, 104)
	ok(SimPressRead.pair_read(late).is_empty(), "pairs: 4 ticks apart is two presses")
	var assist: Dictionary = SimPressRead.pair_read(late, {"assist": true})
	ok(assist.get("pair", "") == "xy", "pairs: the assist setting doubles the window to 6")
	var very_late: Array = []
	SimPressRead.push(very_late, xk, 0, 100)
	SimPressRead.push(very_late, yk, 0, 107)
	ok(SimPressRead.pair_read(very_late, {"assist": true}).is_empty(), "pairs: 7 apart is two presses even with the assist")
	# The cross-pad pairs are not pairs.
	var xb: Array = []
	SimPressRead.push(xb, xk, 0, 100)
	SimPressRead.push(xb, bk, 0, 101)
	var ya: Array = []
	SimPressRead.push(ya, yk, 0, 100)
	SimPressRead.push(ya, ak, 0, 101)
	ok(SimPressRead.pair_read(xb).is_empty() and SimPressRead.pair_read(ya).is_empty(), "pairs: X+B and Y+A cross the pad and are never read")
	var same: Array = []
	SimPressRead.push(same, xk, 0, 100)
	SimPressRead.push(same, xk, 0, 101)
	ok(SimPressRead.pair_read(same).is_empty() and SimPressRead.pair_read([]).is_empty() and SimPressRead.pair_read(_one(xk, 0, 3)).is_empty(), "pairs: one button twice, an empty log and a single press are no pair")
	# Freshness: a button pressed in the 8 ticks before is a mash, not a pair.
	var mash: Array = []
	SimPressRead.push(mash, xk, 0, 94)
	SimPressRead.push(mash, xk, 0, 100)
	SimPressRead.push(mash, yk, 0, 102)
	ok(SimPressRead.pair_read(mash).is_empty(), "pairs: an X pressed 6 ticks before is a mash: the Y is not paired with the next X")
	var mash2: Array = []
	SimPressRead.push(mash2, xk, 0, 100)
	SimPressRead.push(mash2, yk, 0, 106)
	SimPressRead.push(mash2, xk, 0, 108)
	ok(SimPressRead.pair_read(mash2).is_empty(), "pairs: Y then X 2 ticks apart after a Y 2 ticks before: not fresh")
	var ok_fresh: Array = []
	SimPressRead.push(ok_fresh, xk, 0, 80)
	SimPressRead.push(ok_fresh, yk, 0, 100)
	SimPressRead.push(ok_fresh, xk, 0, 101)
	ok(SimPressRead.pair_read(ok_fresh).get("pair", "") == "xy", "pairs: presses 20 ticks before are fresh: a pair")
	var ab_other: Array = []
	SimPressRead.push(ab_other, ak, 0, 95)   # an A is not part of an X+Y pair
	SimPressRead.push(ab_other, xk, 0, 100)
	SimPressRead.push(ab_other, yk, 0, 101)
	ok(SimPressRead.pair_read(ab_other).get("pair", "") == "xy", "pairs: another button's recent press does not spoil it")
	# No pairs under RT.
	var rt: Array = []
	SimPressRead.push(rt, xk, 0, 100, NB, -1, 4)
	SimPressRead.push(rt, yk, 0, 101, NB, -1, 4)
	ok(SimPressRead.pair_read(rt).is_empty(), "pairs: none under the charging stance")
	var en: Array = []
	SimPressRead.push(en, xk, 1, 100, NB, -1, 2)
	SimPressRead.push(en, yk, 1, 101, NB, -1, 2)
	ok(SimPressRead.pair_read(en).get("pair", "") == "xy", "pairs: the other stances keep the four pairs")
	# A pair is one press: commit replaces the two entries, counts once, and a pair that used a button makes it unfresh.
	var cm: Array = []
	SimPressRead.push(cm, xk, 0, 200)
	SimPressRead.push(cm, ak, 0, 201)
	var pr: Dictionary = SimPressRead.pair_read(cm)
	SimPressRead.pair_commit(cm, pr)
	ok(cm.size() == 1 and int(cm[0]["kind"]) == SimPressRead.PAIR and cm[0]["pair"] == "xa" and int(cm[0]["down"]) == 200, "pairs: a pair is one press in the log")
	var mix: Dictionary = SimPressRead.classify(cm, 205)["mix_long"]
	ok(int(mix.get("pair", 0)) == 1 and int(mix["light"]) == 0 and int(mix["context"]) == 0, "pairs: the mix counts it once, as a pair")
	SimPressRead.push(cm, xk, 0, 204)
	SimPressRead.push(cm, yk, 0, 205)
	ok(SimPressRead.pair_read(cm).is_empty(), "pairs: an X 4 ticks after an X+A pair is not fresh")
	SimPressRead.push(cm, xk, 0, 300)
	SimPressRead.push(cm, yk, 0, 301)
	ok(SimPressRead.pair_read(cm).get("pair", "") == "xy", "pairs: later, with the pair long past, a new pair is read")
	SimPressRead.pair_commit(cm, {})
	ok(cm.size() == 5, "pairs: committing no pair changes nothing")
	# Marked entries are not reused.
	var used: Array = []
	SimPressRead.push(used, xk, 0, 100)
	SimPressRead.push(used, yk, 0, 101)
	used[1]["paired"] = true
	ok(SimPressRead.pair_read(used).is_empty(), "pairs: an entry already marked as paired is not used again")


func _flurries() -> void:
	var xk: int = SimPressRead.LIGHT
	var yk: int = SimPressRead.HEAVY
	var bk: int = SimPressRead.SIG
	var ak: int = SimPressRead.CONTEXT
	ok(SimPressRead.flurry_gap(xk) == 12 and SimPressRead.flurry_gap(yk) == 16 and SimPressRead.flurry_gap(bk) == 34, "flurries: each button's pace is X 12, Y 16, B 34")
	# mash_of: each button on its own.
	var lx: Array = _mk([100, 106, 112, 118])
	var m1: Dictionary = SimPressRead.mash_of(lx, xk, 120)
	ok(m1["mash"] and m1["presses"] == 4 and m1["gap"] == 6 and m1["going"], "mash_of: four X presses 6 apart are an X flurry")
	ok(not SimPressRead.mash_of(_mk([100, 106, 112]), xk, 114)["mash"], "mash_of: three X are not (X needs four)")
	var ly: Array = _mk([100, 114], [], [yk, yk])
	ok(SimPressRead.mash_of(ly, yk, 118)["mash"] and SimPressRead.mash_of(ly, yk, 118)["presses"] == 2, "mash_of: two Y presses 14 apart are a Y flurry (it needs two)")
	ok(not SimPressRead.mash_of(_mk([100, 120], [], [yk, yk]), yk, 122)["mash"], "mash_of: Y presses 20 apart are two presses (the pace is 16)")
	ok(SimPressRead.mash_of(_mk([100, 130], [], [bk, bk]), bk, 135)["mash"], "mash_of: two B presses 30 apart are a B flurry (the pace is 34)")
	ok(not SimPressRead.mash_of(_mk([100, 106, 112, 118]), xk, 140)["going"], "mash_of: 22 ticks after the last it is over")
	ok(SimPressRead.mash_of([], xk, 100)["presses"] == 0, "mash_of: an empty log")
	# Other buttons in between do not break one button's flurry.
	var mixed: Array = _mk([100, 104, 108, 112], [], [yk, xk, yk, xk])
	ok(SimPressRead.mash_of(mixed, yk, 114)["mash"] and SimPressRead.mash_of(mixed, yk, 114)["presses"] == 2, "mash_of: a Y flurry with an X between its blows is still a Y flurry")
	# alternation.
	var alt: Array = _mk([100, 108, 116, 124], [], [xk, yk, xk, yk])
	var a1: Dictionary = SimPressRead.alternation(alt, 126)
	ok(a1["presses"] == 4 and a1["switches"] == 3 and a1["kinds"] == 3 and a1["mixup"], "alternation: X Y X Y 8 apart is a mix-up of 3 switches over X and Y")
	var three: Array = _mk([100, 110, 120], [], [xk, yk, bk])
	var a2: Dictionary = SimPressRead.alternation(three, 125)
	ok(a2["presses"] == 3 and a2["kinds"] == 7 and a2["switches"] == 2 and a2["mixup"], "alternation: X Y B is the three in order, a mix-up")
	var pure: Array = _mk([100, 108, 116, 124], [], [xk, xk, xk, xk])
	var a3: Dictionary = SimPressRead.alternation(pure, 126)
	ok(a3["presses"] == 4 and a3["switches"] == 0 and not a3["mixup"], "alternation: four X is a flurry, not a mix-up")
	var one_sw: Array = _mk([100, 108, 116], [], [xk, xk, yk])
	ok(SimPressRead.alternation(one_sw, 118)["switches"] == 1 and not SimPressRead.alternation(one_sw, 118)["mixup"], "alternation: one change is not a mix-up")
	# The chain breaks at a gap longer than the previous button's pace, and when it has stopped.
	var gapchain: Array = _mk([100, 140, 148, 156], [], [xk, xk, yk, xk])
	var a4: Dictionary = SimPressRead.alternation(gapchain, 158)
	ok(a4["presses"] == 3 and a4["switches"] == 2, "alternation: an X to X gap of 40 ends the chain (X pace 12): the latest three")
	ok(SimPressRead.alternation(alt, 160)["presses"] == 0, "alternation: long after the last it is over")
	var b_then_x: Array = _mk([100, 130], [], [bk, xk])
	ok(SimPressRead.alternation(b_then_x, 132)["presses"] == 2, "alternation: an X 30 after a B is inside B's pace")
	var b_far: Array = _mk([100, 140], [], [bk, xk])
	ok(SimPressRead.alternation(b_far, 142)["presses"] == 1, "alternation: an X 40 after a B is not (the pace is 34)")
	var with_a: Array = _mk([100, 108], [], [ak, xk])
	ok(SimPressRead.alternation(with_a, 110)["presses"] == 1, "alternation: an A press is not part of a mix-up of the three")
	ok(SimPressRead.alternation([], 100)["presses"] == 0, "alternation: an empty log")
	# Energy arts in reach: X pressed as a punch and as a bolt (mode 0 and 1) is one button; a mode count makes it a mix-up.
	var fist_bolt: Array = _mk([100, 108, 116, 124], [], [xk, xk, xk, xk], [0, 1, 0, 1])
	ok(SimPressRead.alternation(fist_bolt, 126)["switches"] == 0 and not SimPressRead.alternation(fist_bolt, 126)["mixup"], "alternation: fist and bolt are all X: no switch by default")
	var fb: Dictionary = SimPressRead.alternation(fist_bolt, 126, {"count_mode": true})
	ok(fb["switches"] == 3 and fb["mixup"] and fb["presses"] == 4, "alternation: with count_mode a change of mode is a switch (punch, bolt, punch, bolt)")
	var flurry_across: Dictionary = SimPressRead.mash_of(fist_bolt, xk, 126)
	ok(flurry_across["mash"] and flurry_across["presses"] == 4, "mash_of: an X flurry carries across fist and bolt (the flurry's clock does not care about the mode)")
	ok(int(SimPressRead.classify(fist_bolt, 126)["mix_long"]["energy"]) == 2, "classify: the mix still counts the two bolts as energy")


func _aread() -> void:
	var ak: int = SimPressRead.CONTEXT
	# One press: winding, then a shove (a tap), or the coil.
	var live_a: Array = _live(ak, 0, -1)
	ok(SimPressRead.a_read(live_a, 50 + 5)["read"] == "winding", "a_read: down 5 live ticks is the shove winding up")
	ok(SimPressRead.a_read(live_a, 50 + 15)["read"] == "winding", "a_read: still winding at 15")
	var coil: Dictionary = SimPressRead.a_read(live_a, 50 + 16)
	ok(coil["read"] == "coil" and coil["since"] == 0 and coil["frac"] == 0.0, "a_read: still down at 16 live ticks he coils for the tackle (no shove)")
	var coil2: Dictionary = SimPressRead.a_read(live_a, 50 + 26)
	ok(coil2["read"] == "coil" and coil2["since"] == 10 and absf(coil2["frac"] - 0.5) < 1e-9, "a_read: the coil's share runs to full at 36 (half at 26)")
	ok(SimPressRead.a_read(live_a, 50 + 46)["frac"] == 1.0 and SimPressRead.a_read(live_a, 50 + 46, {"coil_full": 56})["frac"] == 0.75, "a_read: full at 36, and the full tick is the caller's")
	for h in [2, 12, 16]:
		var sh: Dictionary = SimPressRead.a_read(_live(ak, 0, h), 300)
		ok(sh["read"] == "shove" and sh["throw_at"] == 50 + maxi(12, h), "a_read: let go at %d, the shove goes at live %d" % [h, 50 + maxi(12, h)])
	ok(SimPressRead.a_read(_live(ak, 0, 17), 300)["read"] == "coil", "a_read: let go at 17 is the tackle's release, not a shove")
	ok(SimPressRead.a_read([], 100)["read"] == "none" and SimPressRead.a_read(_live(SimPressRead.HEAVY, 0, -1), 100)["read"] == "none", "a_read: no A press, nothing")
	# A second press inside the shove's wind-up is the clinch.
	var cl: Array = []
	SimPressRead.push(cl, ak, 0, 100, NB, -1, 0, 50)
	SimPressRead.release(cl, ak, 103, 53)
	SimPressRead.push(cl, ak, 0, 108, NB, -1, 0, 58)
	var c1: Dictionary = SimPressRead.a_read(cl, 60)
	ok(c1["read"] == "clinch" and c1["taps"] == 0 and c1["since"] == 2, "a_read: a second A inside the shove's 12 ticks is the clinch (no shove)")
	SimPressRead.release(cl, ak, 111, 61)
	SimPressRead.push(cl, ak, 0, 118, NB, -1, 0, 68)
	SimPressRead.release(cl, ak, 120, 70)
	SimPressRead.push(cl, ak, 0, 126, NB, -1, 0, 76)
	var c2: Dictionary = SimPressRead.a_read(cl, 78)
	ok(c2["read"] == "clinch" and c2["taps"] == 2, "a_read: each further tap is counted (the vicious blows)")
	# A second press AFTER the shove's wind-up is a new shove, not a clinch.
	var two: Array = []
	SimPressRead.push(two, ak, 0, 100, NB, -1, 0, 50)
	SimPressRead.release(two, ak, 103, 53)
	SimPressRead.push(two, ak, 0, 120, NB, -1, 0, 70)
	var c3: Dictionary = SimPressRead.a_read(two, 72)
	ok(c3["read"] == "winding", "a_read: a second A at 20 live ticks is a new press of its own (winding)")
	# Live ticks, not real: a freeze between the two presses does not make a clinch late.
	var fz: Array = []
	SimPressRead.push(fz, ak, 0, 100, NB, -1, 0, 50)
	SimPressRead.release(fz, ak, 103, 53)
	SimPressRead.push(fz, ak, 0, 118, NB, -1, 0, 58)   # 18 real ticks later but 8 live
	ok(SimPressRead.a_read(fz, 60)["read"] == "clinch", "a_read: the clinch is judged on the live clock (18 real, 8 live)")
	# The run lapses: an old press does not join a new one.
	var old: Array = []
	SimPressRead.push(old, ak, 0, 100, NB, -1, 0, 50)
	SimPressRead.release(old, ak, 103, 53)
	SimPressRead.push(old, ak, 0, 400, NB, -1, 0, 350)
	ok(SimPressRead.a_read(old, 352)["read"] == "winding", "a_read: a press long after the last is a fresh one")


## A fresh press edge on a button the log still has held means released, then pressed (a release and a re-press in one freeze).
func _repress() -> void:
	var y: int = SimPressRead.HEAVY
	var log: Array = []
	SimPressRead.push(log, y, 0, 100, NB, -1, 0, 50)
	SimPressRead.push(log, y, 0, 109, NB, -1, 0, 53)   # the edge for a re-press that came with the old press still believed held
	ok(log.size() == 2 and int(log[0]["up"]) == 109 and int(log[0]["lup"]) == 53 and int(log[1]["up"]) == -1, "repress: the new edge lets the old press go at the point it was read")
	ok(SimPressRead.charge_read(log[0], 53) == "tap", "repress: and the old wind-up resolves as a tap (3 live ticks)")
	# A press that was already a charge resolves as a charge's release.
	var old: Array = []
	SimPressRead.push(old, y, 0, 100, NB, -1, 0, 50)
	SimPressRead.push(old, y, 0, 130, NB, -1, 0, 80)
	ok(SimPressRead.charge_read(old[0], 80) == "charge", "repress: a press held past its decision is a charge's release when the new edge arrives")
	# Not on a latched button: the next press is the release and the log is not touched here.
	var lat: Array = []
	SimPressRead.push(lat, y, 0, 100, NB, -1, 0, 50)
	SimPressRead.push(lat, y, 0, 130, NB, -1, 0, 80, true)
	ok(int(lat[0]["up"]) == -1 and lat.size() == 2, "repress: on a latched button the rule does not apply")
	# Only the same button: an edge of another kind does not release it.
	var other: Array = []
	SimPressRead.push(other, y, 0, 100, NB, -1, 0, 50)
	SimPressRead.push(other, SimPressRead.LIGHT, 0, 105, NB, -1, 0, 55)
	ok(int(other[0]["up"]) == -1, "repress: another button's press does not release it")
	# Without live stamps it works on the real ticks.
	var real: Array = _one(y, 0, -1)
	SimPressRead.push(real, y, 0, 108)
	ok(int(real[0]["up"]) == 108 and not real[0].has("lup"), "repress: no live stamps, no live field")
	# An entry with no live stamp is not given one.
	ok(not SimPressRead.push([], y, 0, 100)[0].has("ldown"), "repress: an entry pushed without a live tick carries no ldown")


## zip_read: the starter is the press at `zip_start`; heavy, tech, speed, else plain (docs/controls/lunge-control.md B6.4).
func _zip() -> void:
	var p: Dictionary = SimPressRead.params()
	ok(p["zipMashPresses"] == 3 and p["zipMashGap"] == 10, "zip: the speed reading is 3 presses, 10 ticks apart")
	# No starter in the log: plain.
	ok(SimPressRead.zip_read([], 120, 100, NB) == "plain" and SimPressRead.zip_read(_one(SimPressRead.LIGHT, 8, 3), 120, 77, NB) == "plain", "zip: no starter is plain")
	# Plain: a tap, off the beat, with nothing after.
	ok(SimPressRead.zip_read(_one(SimPressRead.LIGHT, 8, 3), 120, 100, NB) == "plain", "zip: a single tap is plain")
	# Heavy: the starter is a charge, still down at its wind-up plus grace or let go after it.
	ok(SimPressRead.zip_read(_one(SimPressRead.HEAVY, 8, 17), 130, 100, NB) == "heavy", "zip: Y let go at 17 ticks is a charge: heavy")
	ok(SimPressRead.zip_read(_one(SimPressRead.HEAVY, 8, 16), 130, 100, NB) == "heavy", "zip: an unstamped log keeps today's rule: Y down 16 ticks is heavy, so nothing live changes")
	ok(SimPressRead.zip_read(_live(SimPressRead.HEAVY, 8, 16), 130, 100, NB) == "plain" and SimPressRead.zip_read(_live(SimPressRead.HEAVY, 8, 17), 130, 100, NB) == "heavy", "zip: with live stamps Y let go at 16 (inside the grace) is a tap, at 17 a charge")
	ok(SimPressRead.zip_read(_one(SimPressRead.LIGHT, 8, 8), 140, 100, NB) == "heavy" and SimPressRead.zip_read(_one(SimPressRead.LIGHT, 8, 7), 140, 100, NB) == "plain", "zip: X held 8 ticks is heavy (the legacy hold, unchanged until C2a), 7 is not")
	ok(SimPressRead.zip_read(_live(SimPressRead.CONTEXT, 8, 17), 130, 100, NB) == "heavy" and SimPressRead.zip_read(_live(SimPressRead.CONTEXT, 8, 16), 130, 100, NB) == "plain", "zip: A (stamped) let go at 17 is the tackle's coil, 16 is a shove")
	ok(SimPressRead.zip_read(_one(SimPressRead.SIG, 8, 11), 140, 100, NB) == "plain" and SimPressRead.zip_read(_one(SimPressRead.SIG, 8, 12), 140, 100, NB) == "heavy", "zip: B in the manoeuvre stance has no wind-up here: the game's hold (12) applies")
	ok(SimPressRead.zip_read(_one(SimPressRead.HEAVY, 8, -1), 116, 100, NB) == "heavy" and SimPressRead.zip_read(_one(SimPressRead.HEAVY, 8, -1), 115, 100, NB) == "plain", "zip: still down at now counts, live")
	# On the live clock when the log carries it: a 9-tick freeze inside the hold does not make a tap a charge, nor a charge a tap.
	var lz: Array = []
	SimPressRead.push(lz, SimPressRead.HEAVY, 0, 100, NB, -1, 8, 50)
	ok(SimPressRead.zip_read(lz, 125, 100, NB, {"live_now": 50 + 15}) == "plain" and SimPressRead.zip_read(lz, 125, 100, NB, {"live_now": 50 + 16}) == "heavy", "zip: a starter still down is judged on the live clock (25 real, 15 live: not yet)")
	# Tech: the starter on a blow's beat.
	var t: Array = []
	SimPressRead.push(t, SimPressRead.LIGHT, 0, 100, 4, -1, 8)
	SimPressRead.release(t, SimPressRead.LIGHT, 103)
	ok(SimPressRead.zip_read(t, 120, 100, NB) == "tech", "zip: a starter 4 ticks off a blow's contact is tech")
	var t5: Array = []
	SimPressRead.push(t5, SimPressRead.LIGHT, 0, 100, 5, -1, 8)
	SimPressRead.release(t5, SimPressRead.LIGHT, 103)
	ok(SimPressRead.zip_read(t5, 120, 100, NB) == "plain" and SimPressRead.zip_read(t5, 120, 100, NB, {"touch": true}) == "tech", "zip: 5 ticks off is plain, and tech on touch (the wider window)")
	ok(SimPressRead.zip_read(t5, 120, 100, NB, {"offset": 2}) == "tech", "zip: the device offset is applied")
	# Tech: a later press on the zip's arrival.
	var a: Array = _one(SimPressRead.LIGHT, 8, 3)
	SimPressRead.push(a, SimPressRead.LIGHT, 0, 140, NB, -1, 8)
	SimPressRead.release(a, SimPressRead.LIGHT, 143)
	ok(SimPressRead.zip_read(a, 150, 100, 142) == "tech" and SimPressRead.zip_read(a, 150, 100, 150) == "plain", "zip: a press within 4 ticks of the arrival is tech, 10 ticks off is not")
	ok(SimPressRead.zip_read(a, 150, 100, NB) == "plain", "zip: with no arrival yet there is nothing to time")
	# Speed: the starter and two more presses, each within 10 ticks of the last.
	var s: Array = _mk([100, 108, 116])
	ok(SimPressRead.zip_read(s, 125, 100, NB) == "speed", "zip: three presses 8 ticks apart is speed")
	var s2: Array = _mk([100, 108])
	ok(SimPressRead.zip_read(s2, 125, 100, NB) == "plain", "zip: two presses is not enough")
	var s3: Array = _mk([100, 111, 119])
	ok(SimPressRead.zip_read(s3, 125, 100, NB) == "plain", "zip: a gap of 11 breaks the string")
	var s4: Array = _mk([100, 110, 120])
	ok(SimPressRead.zip_read(s4, 130, 100, NB) == "speed", "zip: a gap of exactly 10 holds the string")
	# A press made before the starter does not count toward it.
	var s5: Array = _mk([90, 100, 108])
	ok(SimPressRead.zip_read(s5, 125, 100, NB) == "plain", "zip: earlier presses are not part of the zip")
	# Precedence: heavy over tech over speed.
	var h: Array = []
	SimPressRead.push(h, SimPressRead.HEAVY, 0, 100, 0, -1, 8)
	SimPressRead.release(h, SimPressRead.HEAVY, 120)
	SimPressRead.push(h, SimPressRead.LIGHT, 0, 105, NB, -1, 8)
	SimPressRead.push(h, SimPressRead.LIGHT, 0, 112, NB, -1, 8)
	ok(SimPressRead.zip_read(h, 130, 100, NB) == "heavy", "zip: heavy beats tech and speed")
	var tm: Array = []
	SimPressRead.push(tm, SimPressRead.LIGHT, 0, 100, 1, -1, 8)
	SimPressRead.release(tm, SimPressRead.LIGHT, 103)
	SimPressRead.push(tm, SimPressRead.LIGHT, 0, 108, NB, -1, 8)
	SimPressRead.push(tm, SimPressRead.LIGHT, 0, 115, NB, -1, 8)
	ok(SimPressRead.zip_read(tm, 130, 100, NB) == "tech", "zip: tech beats speed")
	# Deterministic.
	ok(SimPressRead.zip_read(s, 125, 100, NB) == SimPressRead.zip_read(s.duplicate(true), 125, 100, NB), "zip: the same log, the same reading")


func _rhythm() -> void:
	# Three presses 15 ticks apart, each within 2 ticks of a blow.
	var log: Array = _mk([100, 115, 130], [1, -2, 0])
	var c: Dictionary = SimPressRead.classify(log, 133)
	ok(c["style"] == "rhythm" and c["on_beat"] == 3, "rhythm: three presses on the blows")
	# Two of three on the beat is enough; one is not.
	ok(SimPressRead.classify(_mk([100, 115, 130], [1, 9, -3]), 133)["style"] == "rhythm", "rhythm: two of the last three is rhythm")
	ok(SimPressRead.classify(_mk([100, 115, 130], [1, 9, -9]), 133)["style"] == "taps", "rhythm: one of three is not")
	# Only the last three count: an old on-beat press does not.
	ok(SimPressRead.classify(_mk([60, 80, 100, 115, 130], [0, 0, 9, 9, 0]), 133)["on_beat"] == 1, "rhythm: only the last three presses count")
	# Presses outside an exchange have no beat.
	ok(SimPressRead.classify(_mk([100, 115, 130]), 133)["style"] == "taps", "rhythm: no beat to be on, no rhythm")
	# A mash that lands on the blows is rhythm, not a mash.
	var fast: Array = _mk([100, 107, 114, 121], [0, 1, 0, -1])
	ok(SimPressRead.classify(fast, 124)["style"] == "rhythm", "rhythm: a mash on the blows is rhythm")
	# Two presses on the beat from a fresh log count (2 of 2).
	ok(SimPressRead.classify(_mk([100, 115], [0, 1]), 118)["style"] == "rhythm", "rhythm: the second on-beat press makes it")
	ok(SimPressRead.classify(_mk([100], [0]), 103)["style"] == "taps", "rhythm: one press is not yet rhythm")


func _mash() -> void:
	var log: Array = _mk([100, 108, 116, 124])
	var c: Dictionary = SimPressRead.classify(log, 127)
	ok(c["style"] == "mash", "mash: four presses 8 ticks apart")
	ok(absf(float(c["rate"]) - 7.5) < 0.01, "mash: the rate is 7.5 presses a second")
	ok(SimPressRead.classify(_mk([100, 110, 120, 130]), 133)["style"] == "mash", "mash: gaps of exactly 10 still count")
	ok(SimPressRead.classify(_mk([100, 111, 122, 133]), 136)["style"] == "taps", "mash: gaps of 11 do not")
	ok(SimPressRead.classify(_mk([100, 108, 116]), 119)["style"] == "taps", "mash: three presses are not enough")
	ok(SimPressRead.classify(_mk([100, 130, 138, 146, 154]), 157)["style"] == "mash", "mash: the last four decide, an earlier slow press does not")
	ok(SimPressRead.classify(_mk([100, 108, 116, 124]), 145)["style"] == "taps", "mash: over after 20 ticks without a press")
	ok(SimPressRead.classify(_mk([100, 108, 116, 124]), 144)["style"] == "mash", "mash: still on at 20 ticks")
	# A jittered mash, as a person does it.
	ok(SimPressRead.classify(_mk([100, 106, 116, 123, 133]), 136)["style"] == "mash", "mash: a jittered mash")
	# Alternating light and heavy is still a mash.
	ok(SimPressRead.classify(_mk([100, 108, 116, 124], [], [0, 1, 0, 1]), 127)["style"] == "mash", "mash: light and heavy together are a mash")


func _taps_and_stale() -> void:
	var log: Array = _mk([100, 125, 150])
	ok(SimPressRead.classify(log, 153)["style"] == "taps", "taps: presses spaced out and off the beat")
	ok(SimPressRead.classify(log, 150 + 60)["style"] == "taps", "taps: still read at the stale limit")
	ok(SimPressRead.classify(log, 150 + 61)["style"] == "none", "taps: a log older than 60 ticks reads as nothing")


func _windows() -> void:
	var log: Array = _mk([100, 115], [4, -4])
	ok(SimPressRead.classify(log, 118)["style"] == "rhythm", "window: plus and minus 4 is on the beat (8 ticks)")
	var wide: Array = _mk([100, 115], [5, -5])
	ok(SimPressRead.classify(wide, 118)["style"] == "taps", "window: 5 is off the beat")
	ok(SimPressRead.classify(wide, 118, {"touch": true})["style"] == "rhythm", "window: 5 is on the beat on touch (10 ticks)")
	var wider: Array = _mk([100, 115], [8, -8])
	ok(SimPressRead.classify(wider, 118, {"assist": true})["style"] == "rhythm", "window: assist doubles it (8)")
	ok(SimPressRead.classify(wider, 118)["style"] == "taps", "window: and without assist 8 is off")
	# The player's timing offset moves where the beat is for them.
	var late: Array = _mk([100, 115], [7, 6])
	ok(SimPressRead.classify(late, 118)["style"] == "taps", "window: a player who presses 6 to 7 ticks late misses")
	ok(SimPressRead.classify(late, 118, {"offset": 6})["style"] == "rhythm", "window: their offset of 6 puts them on the beat")


func _mix() -> void:
	var log: Array = _mk([100, 115, 130, 145, 160], [], [0, 0, 1, 1, 2], [0, 1, 1, 0, 0])
	var c: Dictionary = SimPressRead.classify(log, 163)
	var ms: Dictionary = c["mix_short"]
	var ml: Dictionary = c["mix_long"]
	ok(ms["light"] == 2 and ms["heavy"] == 2 and ms["sig"] == 1 and ms["energy"] == 2, "mix: the latest five presses (the recipe's read: 2 light, 2 heavy, 1 signature, 2 energy)")
	ok(ml == ms, "mix: with only five presses the long mix is the same")
	# The long mix reads 20: eight lights, then three heavies, 8 ticks apart.
	var ticks: Array = []
	var kinds: Array = []
	for k in range(11):
		ticks.append(100 + k * 8)
		kinds.append(0 if k < 8 else 1)
	var long_log: Array = _mk(ticks, [], kinds)
	var c2: Dictionary = SimPressRead.classify(long_log, 183)
	ok(c2["mix_long"]["light"] == 8 and c2["mix_long"]["heavy"] == 3, "mix: the long mix counts every unexpired press (8 light, 3 heavy)")
	ok(c2["mix_short"]["light"] == 2 and c2["mix_short"]["heavy"] == 3, "mix: and the short mix the latest five (2 light, 3 heavy)")
	ok(SimPressRead.classify(long_log, 190)["mix_long"]["light"] == 8, "mix: a press exactly 90 ticks old still counts")
	var c3: Dictionary = SimPressRead.classify(long_log, 191)
	ok(c3["mix_long"]["light"] == 8 and c3["mix_long"]["heavy"] == 3, "mix: old presses stay while the window is live (section 20: the lapse is of the whole window, not press by press)")
	ok(SimPressRead.classify(long_log, 270)["mix_long"]["heavy"] == 3, "mix: 90 ticks after the last press the window is still whole")
	var cold: Dictionary = SimPressRead.classify(long_log, 271)
	ok(cold["mix_long"]["light"] == 0 and cold["mix_long"]["heavy"] == 0 and cold["mix_short"]["heavy"] == 0 and cold["presses"] == 0, "mix: after 90 idle ticks the whole window is empty")


func _determinism() -> void:
	var a: Array = _mk([100, 108, 116, 124], [0, 3, -2, 1])
	var b: Array = _mk([100, 108, 116, 124], [0, 3, -2, 1])
	ok(str(SimPressRead.classify(a, 127)) == str(SimPressRead.classify(b, 127)), "same log, same reading")
	var before: String = str(a)
	SimPressRead.classify(a, 127)
	ok(str(a) == before, "classify does not change the log")


func _grades() -> void:
	ok(SimPressRead.grade_of(0) == "perfect" and SimPressRead.grade_of(4) == "perfect" and SimPressRead.grade_of(-4) == "perfect", "grade: within 4 ticks is perfect")
	ok(SimPressRead.grade_of(5) == "good" and SimPressRead.grade_of(-8) == "good", "grade: within 8 is good")
	ok(SimPressRead.grade_of(9) == "off", "grade: past 8 is off")
	ok(SimPressRead.grade_of(5, {"touch": true}) == "perfect" and SimPressRead.grade_of(11, {"touch": true}) == "off", "grade: touch widens the perfect window to 5")
	ok(SimPressRead.grade_of(8, {"assist": true}) == "perfect" and SimPressRead.grade_of(16, {"assist": true}) == "good", "grade: assist doubles both windows")
	ok(SimPressRead.grade_of(7, {"offset": 6}) == "perfect", "grade: the player's offset shifts the mark")


func _timing() -> void:
	# A steady mash is perfect; a ragged one is not.
	var steady: Dictionary = SimPressRead.classify(_mk([100, 108, 116, 124], [0, 1, 0, -1]), 127)
	ok(steady["steady"] and steady["timing"] == "perfect", "timing: an even mash on the blows is steady, a perfect blur")
	var blind: Dictionary = SimPressRead.classify(_mk([100, 108, 116, 124]), 127)
	ok(blind["style"] == "mash" and not blind["steady"] and blind["timing"] == "none", "timing: the same spacing with no blows to be on is a mash, not steady")
	var ragged: Dictionary = SimPressRead.classify(_mk([100, 106, 116, 123]), 126)
	ok(ragged["style"] == "mash" and not ragged["steady"] and ragged["timing"] == "none", "timing: a ragged mash is a mash, not a perfect one")
	ok(SimPressRead.classify(_mk([100, 108, 117, 125], [0, 0, 0, 0]), 128)["steady"], "timing: gaps of 8, 9, 8 on the blows are steady (within 3)")
	ok(SimPressRead.classify(_mk([100, 108, 121, 129], [0, 0, 0, 0]), 132)["steady"], "timing: gaps of 8, 13, 8 on the blows are steady (no spacing test)")
	# Taps in time: perfect after three in a row, good before.
	var three: Dictionary = SimPressRead.classify(_mk([100, 115, 130], [0, 2, -3]), 133)
	ok(three["style"] == "rhythm" and three["streak"] == 3 and three["timing"] == "perfect", "timing: three perfect taps in a row land clean (perfect)")
	var two: Dictionary = SimPressRead.classify(_mk([100, 115], [0, 2]), 118)
	ok(two["style"] == "rhythm" and two["streak"] == 2 and two["timing"] == "good", "timing: two perfect taps are good, not yet perfect")
	var broken: Dictionary = SimPressRead.classify(_mk([100, 115, 130], [0, 9, 1]), 133)
	ok(broken["streak"] == 1 and broken["timing"] == "good", "timing: an off press breaks the streak (rhythm, but only good)")
	var plain: Dictionary = SimPressRead.classify(_mk([100, 125, 150]), 153)
	ok(plain["style"] == "taps" and plain["timing"] == "none", "timing: taps off the beat have no timing")
	ok(SimPressRead.classify(_mk([100, 125, 150], [0, 30, 30]), 153)["timing"] == "good", "timing: taps with one perfect press are good")


func _release() -> void:
	var log: Array = []
	SimPressRead.push(log, SimPressRead.HEAVY, 0, 100)
	ok(SimPressRead.release_grade(log[0]) == "none", "release: no flash, no grade")
	SimPressRead.set_flash(log, SimPressRead.HEAVY, 136)
	ok(int(log[0]["flash"]) == 136 and SimPressRead.release_grade(log[0]) == "held", "release: still held, flashed at 136")
	var c: Dictionary = SimPressRead.classify(log, 140)
	ok(c["style"] == "hold" and c["timing"] == "none" and c["release"] == "none", "release: a held charge is a hold with no grade yet")
	SimPressRead.release(log, SimPressRead.HEAVY, 138)
	ok(SimPressRead.release_grade(log[0]) == "perfect", "release: let go 2 ticks after the flash is perfect (a hold released on the flash)")
	c = SimPressRead.classify(log, 139)
	ok(c["release"] == "perfect", "release: classify reports it")
	var cases: Array = [[132, "perfect"], [140, "perfect"], [143, "good"], [128, "good"], [120, "early"], [150, "late"]]
	for k in cases:
		var l2: Array = []
		SimPressRead.push(l2, SimPressRead.LIGHT, 0, 100)
		SimPressRead.set_flash(l2, SimPressRead.LIGHT, 136)
		SimPressRead.release(l2, SimPressRead.LIGHT, int(k[0]))
		ok(SimPressRead.release_grade(l2[0]) == k[1], "release: let go at %d with the flash at 136 is %s" % [k[0], k[1]])
	# Touch, assist and the offset apply to a release as to a press.
	var l3: Array = []
	SimPressRead.push(l3, SimPressRead.LIGHT, 0, 100)
	SimPressRead.set_flash(l3, SimPressRead.LIGHT, 136)
	SimPressRead.release(l3, SimPressRead.LIGHT, 141)
	ok(SimPressRead.release_grade(l3[0]) == "good" and SimPressRead.release_grade(l3[0], {"touch": true}) == "perfect", "release: touch widens the flash window")
	SimPressRead.release(l3, SimPressRead.LIGHT, 141)
	# A release on the flash lifts a hold; the next press is read fresh.
	var l4: Array = []
	SimPressRead.push(l4, SimPressRead.HEAVY, 0, 100)
	SimPressRead.set_flash(l4, SimPressRead.HEAVY, 136)
	SimPressRead.release(l4, SimPressRead.HEAVY, 136)
	SimPressRead.push(l4, SimPressRead.LIGHT, 0, 150)
	var c4: Dictionary = SimPressRead.classify(l4, 153)
	ok(c4["release"] == "perfect" and c4["style"] == "taps", "release: the latest release grade stays available after the next press")


## A log of presses at `press_ticks` against blow contacts at `blows` (each press's beat is its distance to the nearest blow).
func _beat_log(press_ticks: Array, blows: Array) -> Array:
	var log: Array = []
	for pt in press_ticks:
		SimPressRead.push(log, SimPressRead.LIGHT, 0, int(pt), SimPressRead.beat_offset(int(pt), blows))
		SimPressRead.release(log, SimPressRead.LIGHT, int(pt) + 3)
	return log


## Section 20 (ruled: four on-beat presses within 2 ticks): steady needs the blows. A blind metronome against a blur's cadence.
func _section20_steady() -> void:
	var p: Dictionary = SimPressRead.params()
	var need: int = int(p["steadyPresses"])
	ok(need == 4 and p["blurBeatHalf"] == 2 and p["blurBeatBonus"] == 0 and p["powerShare"] == 60, "s20 data: four presses, 2 ticks, no bonus, power over 60 percent")
	# Presses on the contacts, for each cadence in the set, are steady and a perfect blur.
	for cad in [7, 8, 9, 10]:
		var blows: Array = []
		for k in range(16):
			blows.append(100 + cad * k)
		var on: Array = []
		for k in range(need):
			on.append(100 + cad * (2 + k))
		var c: Dictionary = SimPressRead.classify(_beat_log(on, blows), on[need - 1] + 3)
		ok(c["steady"] and c["timing"] == "perfect", "s20: %d presses on the contacts of a %d-tick cadence are steady and perfect" % [need, cad])
		ok(not SimPressRead.classify(_beat_log(on.slice(1), blows), on[need - 1] + 3)["steady"], "s20: one fewer is not enough (%d-tick cadence)" % cad)
		# A person's jitter of 1 tick is still on them; 3 ticks is not.
		var near: Array = []
		for k in range(need):
			near.append(int(on[k]) + (1 if k < need / 2 else -1))
		ok(SimPressRead.classify(_beat_log(near, blows), near[need - 1] + 3)["steady"], "s20: 1 tick of jitter on a %d-tick cadence is still steady" % cad)
		var off: Array = on.duplicate()
		off[need - 2] += 3
		ok(not SimPressRead.classify(_beat_log(off, blows), off[need - 1] + 3)["steady"], "s20: one press 3 ticks off a %d-tick cadence breaks it" % cad)
	# The two bands over whole strings, with the ruled numbers. Blind: an 8-tick metronome at any phase against each cadence,
	# the four cadences equally likely, steady at ANY point of a string of 8, 12 and 20 presses.
	var line: String = ""
	for length in [8, 12, 20]:
		var hit: Dictionary = {}
		for cad in [7, 8, 9, 10]:
			var blows2: Array = []
			for k in range(40):
				blows2.append(100 + cad * k)
			var n_hit: int = 0
			for phase in range(cad):
				var pt: Array = []
				for k in range(length):
					pt.append(100 + phase + 8 * k)
				if _steady_somewhere(pt, blows2):
					n_hit += 1
			hit[cad] = n_hit
		var share: float = (0.25 * float(hit[7]) / 7.0 + 0.25 * float(hit[8]) / 8.0 + 0.25 * float(hit[9]) / 9.0 + 0.25 * float(hit[10]) / 10.0) * 100.0
		line += " %d presses: %.1f%% (cadence 7: %d of 7 phases, 8: %d of 8, 9: %d of 9, 10: %d of 10);" % [length, share, hit[7], hit[8], hit[9], hit[10]]
	print("s20 measured, blind 8-tick masher on SYNTHETIC contacts with no hit-stop (information only; the band is asserted under live spacing below):" + line)
	# The script that presses on every contact: every cadence, strings of 8 presses or more.
	var script_hits: int = 0
	var script_total: int = 0
	for length in [8, 12, 20]:
		for cad in [7, 8, 9, 10]:
			var blows3: Array = []
			for k in range(40):
				blows3.append(100 + cad * k)
			var pt3: Array = []
			for k in range(length):
				pt3.append(100 + cad * k)
			script_total += 1
			if _steady_somewhere(pt3, blows3):
				script_hits += 1
	ok(script_hits * 100 >= script_total * 80, "s20: the on-contact script earns the perfect blur on at least 80 percent of strings of 8 presses or more, synthetic contacts (%d of %d)" % [script_hits, script_total])
	# A human-ish script: each press within one tick of its contact, a seeded jitter, strings of 8 to 20 presses.
	var rng := SimRng.new(2026)
	var strings: Array = []
	for length in [8, 12, 20]:
		for cad in [7, 8, 9, 10]:
			for rep in range(25):
				var pt4: Array = []
				for k in range(length):
					pt4.append(100 + cad * k + int(floor(rng.next() * 3.0)) - 1)
				strings.append([cad, pt4])
	var h_hits: int = 0
	for sc in strings:
		var blows4: Array = []
		for k in range(40):
			blows4.append(100 + int(sc[0]) * k)
		if _steady_somewhere(sc[1], blows4):
			h_hits += 1
	print("s20 measured, a player with uniform jitter of up to one tick on every contact (synthetic contacts): %d of %d strings (%.0f%%)" % [h_hits, strings.size(), 100.0 * float(h_hits) / float(strings.size())])
	ok(h_hits * 100 >= strings.size() * 80, "s20: a player within one tick of every contact earns it on at least 80 percent of strings")
	# Touch and 30 fps get no extra tolerance (ruled); the assist still doubles the window, and the offset moves the mark.
	var blows5: Array = []
	for k in range(14):
		blows5.append(100 + 8 * k)
	var late3: Array = []
	for k in range(need):
		late3.append(100 + 8 * (2 + k) + 3)
	var l3: Array = _beat_log(late3, blows5)   # 3 ticks late each time, even
	var at3: int = int(late3[need - 1]) + 3
	ok(not SimPressRead.classify(l3, at3)["steady"], "s20: 3 ticks late each time is outside the blur's 2")
	ok(not SimPressRead.classify(l3, at3, {"touch": true})["steady"], "s20: touch gets no extra tolerance for the blur's beat")
	ok(not SimPressRead.classify(l3, at3, {"slow": true})["steady"], "s20: nor does a 30 fps client")
	ok(SimPressRead.classify(l3, at3, {"assist": true})["steady"], "s20: the assist (accessibility) still doubles the window")
	ok(SimPressRead.classify(l3, at3, {"offset": 3})["steady"], "s20: and the player's timing offset moves the mark")
	# The EP's rule: no spacing test. Any gaps on different blows are steady; the opener's 28 and 44 ticks, then a cadence.
	for cad in [7, 8, 9, 10]:
		var opener: Array = [100, 128, 172, 172 + cad, 172 + 2 * cad]
		ok(SimPressRead.classify(_beat_log(opener.slice(0, 4), opener), opener[3] + 3)["steady"], "s20: presses on the contacts with gaps 28, 44 and %d are steady" % cad)
		ok(SimPressRead.classify(_beat_log(opener.slice(1, 5), opener), opener[4] + 3)["steady"], "s20: and gaps 44, %d and %d (the opener's tail) are steady" % [cad, cad])
		var live: Array = [100, 100 + cad + 4, 100 + 2 * (cad + 4), 100 + 3 * (cad + 4)]
		ok(SimPressRead.classify(_beat_log(live, live), live[3] + 3)["steady"], "s20: contacts a cadence of %d plus 4 ticks of hit-stop apart are steady" % cad)
		var live5: Array = [100, 100 + cad + 5, 100 + 2 * (cad + 5), 100 + 3 * (cad + 5)]
		ok(SimPressRead.classify(_beat_log(live5, live5), live5[3] + 3)["steady"], "s20: and a cadence of %d plus 5 ticks of hit-stop" % cad)
	# Two presses on one blow count once.
	var blows7: Array = [100, 128, 172, 180, 188]
	var twice: Array = _beat_log([128, 130, 172, 180], blows7)
	ok(not SimPressRead.classify(twice, 183)["steady"], "s20: two presses on one blow do not count twice (128 and 130 are one blow)")
	var thrice: Array = _beat_log([100, 128, 172, 180, 188, 188 + 1], [100, 128, 172, 180, 188])
	ok(not SimPressRead.classify(thrice, 192)["steady"], "s20: a double press on the last blow breaks the last four")
	# A press 4 ticks late is not on the blow.
	var late4: Array = _beat_log([100, 128, 172, 184], [100, 128, 172, 180])
	ok(not SimPressRead.classify(late4, 187)["steady"], "s20: a press 4 ticks late is not steady")
	var late2: Array = _beat_log([100, 128, 172, 182], [100, 128, 172, 180])
	ok(SimPressRead.classify(late2, 185)["steady"], "s20: 2 ticks late is still on the blow")
	# An off-beat press between them breaks it, and four clean presses after it make it again.
	var blows8: Array = [100, 128, 172, 180, 188, 196, 204]
	var broken: Array = _beat_log([100, 128, 150, 172, 180], blows8)
	ok(not SimPressRead.classify(broken, 183)["steady"], "s20: a press off every blow among the last four breaks it")
	var healed: Array = _beat_log([100, 128, 150, 172, 180, 188, 196], blows8)
	ok(SimPressRead.classify(healed, 199)["steady"], "s20: four clean presses after it are steady again")
	# Out of order or outside an exchange: no blows, no steady.
	ok(not SimPressRead.classify(_beat_log([100, 128, 172, 180], []), 183)["steady"], "s20: with no blows to be on there is no steady")
	# No absolute spacing: gaps of 12, 13 and 15 on the beat are steady (live contacts are a cadence plus the hit-stop apart).
	for gap in [11, 12, 13, 14, 15]:
		var even: Array = []
		for k in range(need):
			even.append(100 + gap * k)
		ok(SimPressRead.classify(_beat_log(even, even), even[need - 1] + 3)["steady"], "s20: %d presses on the beat %d ticks apart are steady (no absolute gap cap)" % [need, gap])


## Whether the log of these presses (the latest 8 at each step, as the director keeps them) is steady at any point.
func _steady_somewhere(press_ticks: Array, blows: Array, opts: Dictionary = {}) -> bool:
	for k in range(press_ticks.size()):
		var sub: Array = press_ticks.slice(maxi(0, k - 7), k + 1)
		if SimPressRead.classify(_beat_log(sub, blows), int(sub[sub.size() - 1]) + 3, opts)["steady"]:
			return true
	return false


## Live contacts: a blur's blows are a cadence of 7 to 10 live ticks plus the chain strike's hit-stop (4 to 5 ticks) apart, because
## S.tick runs through hit-stop, so presses on the contacts are 11 to 15 ticks apart (Encounter measured 11, 12, 12, 12 at cadence 7).
## `hs` is the hit-stop per blow: 4, 5, or "mixed" (a seeded 4 or 5 each blow).
func _live_contacts(cad: int, hs: String, count: int, seed_: int) -> Array:
	var r := SimRng.new(seed_)
	var out: Array = []
	var at: int = 100
	for k in range(count):
		out.append(at)
		var h: int = 4 if hs == "4" else (5 if hs == "5" else (4 + int(floor(r.next() * 2.0))))
		at += cad + h
	return out


## The opener a TRADE BLOWS string starts with: blows 28 and 44 ticks apart, then the cadence plus hit-stop.
func _opener_contacts(cad: int, hs: String, count: int, seed_: int) -> Array:
	var r := SimRng.new(seed_)
	var out: Array = [100, 128, 172]
	var at: int = 172
	while out.size() < count:
		var h: int = 4 if hs == "4" else (5 if hs == "5" else (4 + int(floor(r.next() * 2.0))))
		at += cad + h
		out.append(at)
	return out


func _section20_hitstop() -> void:
	var combos: Array = []
	for cad in [7, 8, 9, 10]:
		for hs in ["4", "5", "mixed"]:
			combos.append([cad, hs])
	# Encounter's measured case: contacts 11, 12, 12, 12 ticks apart.
	var measured: Array = [100, 111, 123, 135, 147]
	ok(SimPressRead.classify(_beat_log(measured.slice(0, 4), measured), 138)["steady"], "hit-stop: presses on contacts 11, 12, 12 apart (measured at cadence 7) are steady")
	# The script that presses on every contact, every cadence and hit-stop, strings of 8 presses or more.
	var script_hits: int = 0
	var script_total: int = 0
	for length in [5, 8, 12, 20]:
		for c in combos:
			var blows: Array = _live_contacts(int(c[0]), str(c[1]), 40, 11 + length)
			var pt: Array = blows.slice(0, length)
			script_total += 1
			if _steady_somewhere(pt, blows):
				script_hits += 1
	print("hit-stop measured, on-contact script: %d of %d strings steady (%.0f%%)" % [script_hits, script_total, 100.0 * float(script_hits) / float(script_total)])
	ok(script_hits * 100 >= script_total * 80, "hit-stop: the on-contact script earns the perfect blur on at least 80 percent of strings (five blows or more) under live spacing")
	# The same with the opener's rhythm (blows 28 and 44 apart before the links), strings of five blows or more.
	var op_hits: int = 0
	var op_total: int = 0
	for length in [5, 8, 12]:
		for c in combos:
			var blows_o: Array = _opener_contacts(int(c[0]), str(c[1]), 40, 70 + length)
			op_total += 1
			if _steady_somewhere(blows_o.slice(0, length), blows_o):
				op_hits += 1
	print("opener measured, on-contact script (28 and 44 ticks, then the cadence plus hit-stop): %d of %d strings steady (%.0f%%)" % [op_hits, op_total, 100.0 * float(op_hits) / float(op_total)])
	ok(op_hits * 100 >= op_total * 80, "opener: the on-contact script earns the perfect blur on at least 80 percent of strings that start with the 28 and 44 tick opener (five blows or more)")
	var op_blind: float = 0.0
	for length in [5, 8, 12]:
		var o_total: float = 0.0
		var o_hits: float = 0.0
		for c in combos:
			var blows_b: Array = _opener_contacts(int(c[0]), str(c[1]), 60, 900 + length)
			var o_n: int = 0
			for phase in range(40):
				var ptb: Array = []
				for k in range(length):
					ptb.append(100 + phase + 8 * k)
				if _steady_somewhere(ptb, blows_b):
					o_n += 1
			o_hits += float(o_n) / 40.0
			o_total += 1.0
		op_blind = maxf(op_blind, 100.0 * o_hits / o_total)
	print("opener measured, blind 8-tick masher, worst of strings of 5, 8 and 12 presses: %.1f%%" % op_blind)
	ok(op_blind <= 20.0, "opener: a blind 8-tick masher earns the perfect blur on at most 20 percent of strings with the opener (%.1f)" % op_blind)
	# A person within one tick of every contact (seeded jitter).
	var rng := SimRng.new(77)
	var h_hits: int = 0
	var h_total: int = 0
	for length in [5, 8, 12, 20]:
		for c in combos:
			for rep in range(8):
				var blows2: Array = _live_contacts(int(c[0]), str(c[1]), 40, 500 + rep)
				var pt2: Array = []
				for k in range(length):
					pt2.append(int(blows2[k]) + int(floor(rng.next() * 3.0)) - 1)
				h_total += 1
				if _steady_somewhere(pt2, blows2):
					h_hits += 1
	print("hit-stop measured, uniform jitter of up to one tick on every contact: %d of %d strings (%.0f%%)" % [h_hits, h_total, 100.0 * float(h_hits) / float(h_total)])
	# The blind 8-tick masher under live spacing: every phase of every spacing, equally likely.
	var line: String = ""
	var worst_share: float = 0.0
	for length in [5, 8, 12, 20]:
		var total_phases: float = 0.0
		var hits: float = 0.0
		for c in combos:
			var blows3: Array = _live_contacts(int(c[0]), str(c[1]), 60, 900 + length)
			var period: int = int(c[0]) + 4
			var n_hit: int = 0
			for phase in range(period + 2):
				var pt3: Array = []
				for k in range(length):
					pt3.append(100 + phase + 8 * k)
				if _steady_somewhere(pt3, blows3):
					n_hit += 1
			hits += float(n_hit) / float(period + 2)
			total_phases += 1.0
		var share: float = 100.0 * hits / total_phases
		worst_share = maxf(worst_share, share)
		line += " %d presses: %.1f%%;" % [length, share]
	print("hit-stop measured, blind 8-tick masher:" + line)
	ok(worst_share <= 20.0, "hit-stop: a blind 8-tick masher earns the perfect blur on at most 20 percent of strings under live spacing, at every string length (worst %.1f)" % worst_share)
	# Which blind rates can ride a live spacing: a metronome whose gap equals the spacing keeps the beat by luck of phase.
	var rate_line: String = ""
	for gap in [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]:
		var rh: int = 0
		var rt: int = 0
		for c in combos:
			var blows4: Array = _live_contacts(int(c[0]), "4", 60, 31)
			for phase in range(int(c[0]) + 6):
				var pt4: Array = []
				for k in range(12):
					pt4.append(100 + phase + gap * k)
				rt += 1
				if _steady_somewhere(pt4, blows4):
					rh += 1
		rate_line += " %d:%.0f%%" % [gap, 100.0 * float(rh) / float(rt)]
	print("hit-stop measured, blind metronome by gap (strings of 12, hit-stop 4, share of phases and cadences):" + rate_line)
	# The assist still doubles the window under live spacing.
	var blows5: Array = _live_contacts(7, "4", 20, 3)
	var late: Array = []
	for k in range(int(SimPressRead.params()["steadyPresses"])):
		late.append(int(blows5[2 + k]) + 3)
	var ll: Array = _beat_log(late, blows5)
	ok(not SimPressRead.classify(ll, int(late[late.size() - 1]) + 3)["steady"] and SimPressRead.classify(ll, int(late[late.size() - 1]) + 3, {"assist": true})["steady"], "hit-stop: 3 ticks late each time is not steady, and the assist's doubled window makes it so")


func _section20_recipe() -> void:
	var lone: Array = []
	SimPressRead.push(lone, SimPressRead.HEAVY, 0, 100)
	ok(SimPressRead.classify(lone, 103)["recipe"] == "power", "s20 recipe: one heavy alone reads power")
	var lone_l: Array = []
	SimPressRead.push(lone_l, SimPressRead.LIGHT, 0, 100)
	ok(SimPressRead.classify(lone_l, 103)["recipe"] == "blur", "s20 recipe: one light alone is blur")
	ok(SimPressRead.classify([], 103)["recipe"] == "none", "s20 recipe: no presses, none")
	var two: Array = _mk([100, 130], [], [1, 1])
	ok(SimPressRead.classify(two, 133)["recipe"] == "power", "s20 recipe: two heavies running read power")
	var mixed: Array = _mk([100, 130, 160], [], [0, 1, 0])
	ok(SimPressRead.classify(mixed, 163)["recipe"] == "combo", "s20 recipe: a heavy among lights (one in three) is a combo")
	# Four heavies 47 ticks apart: the old press-by-press expiry could never hold them; the window does.
	var four: Array = _mk([100, 147, 194, 241], [], [1, 1, 1, 1])
	var c4: Dictionary = SimPressRead.classify(four, 244)
	ok(c4["recipe"] == "power" and c4["mix_short"]["heavy"] == 4 and c4["presses"] == 4, "s20 recipe: four heavies 47 ticks apart read power, all four present")
	# Five presses: the old rule exactly (none blur, one to three combo, four or five power).
	var rules: Array = [[0, "blur"], [1, "combo"], [2, "combo"], [3, "combo"], [4, "power"], [5, "power"]]
	for r in rules:
		var kinds: Array = []
		for k in range(5):
			kinds.append(1 if k < int(r[0]) else 0)
		var l5: Array = _mk([100, 110, 120, 130, 140], [], kinds)
		ok(SimPressRead.classify(l5, 143)["recipe"] == r[1], "s20 recipe: five presses with %d heavies read %s (the old rule)" % [r[0], r[1]])
	# Only the latest five count: eight presses of which the last five are lights.
	var old_heavy: Array = _mk([100, 110, 120, 130, 140, 150, 160, 170], [], [1, 1, 1, 0, 0, 0, 0, 0])
	ok(SimPressRead.classify(old_heavy, 173)["recipe"] == "blur", "s20 recipe: the recipe reads the latest five, so earlier heavies are out")
	# The lapse: the window holds for 90 idle ticks, then clears as a whole.
	var held: Array = _mk([100, 147, 194, 241], [], [1, 1, 1, 1])
	ok(SimPressRead.classify(held, 241 + 90)["recipe"] == "power", "s20 lapse: 90 ticks after the last press the window still reads")
	var gone: Dictionary = SimPressRead.classify(held, 241 + 91)
	ok(gone["recipe"] == "none" and gone["presses"] == 0 and gone["mix_short"]["heavy"] == 0, "s20 lapse: 91 idle ticks clears the whole window")
	# A new press after the lapse starts a fresh window of its own (the director clears the log; the read of a stale entry is empty).
	SimPressRead.push(held, SimPressRead.LIGHT, 0, 400)
	var fresh: Dictionary = SimPressRead.classify(held, 403)
	ok(fresh["mix_short"]["light"] == 1 and fresh["mix_short"]["heavy"] == 4, "s20 lapse: a log the director has not cleared still counts its entries once a press comes (clearing is the director's)")


## Presses made in a hit-stop are graded at their own tick (`waited`): the director's S.tick - waited. A blow lands at C and freezes
## the sim for h ticks (C+1 to C+h); the press arrives on the first live tick, C+h+1. A press made d ticks after the contact
## (1 <= d <= h) waited h+1-d ticks, so S.tick - waited is C+d, its own tick. Only presses within blurBeatHalf (2) of the contact
## are on the blur's beat: the first 2 ticks of the freeze.
func _graded_own(c: int, h: int, d: int) -> int:
	if d >= 1 and d <= h:
		var arrival: int = c + h + 1
		var waited: int = arrival - (c + d)
		return arrival - waited
	return c + d


## The rule before: every press in the freeze (and the first live tick) graded at S.tick - h, the contact plus 1.
func _graded_old(c: int, h: int, d: int) -> int:
	if d >= 1 and d <= h + 1:
		return c + 1
	return c + d


func _freeze_own_tick() -> void:
	for h in [4, 5]:
		for cad in [7, 8, 9, 10]:
			var blows: Array = []
			for k in range(6):
				blows.append(100 + k * (cad + h))
			for d in range(-3, h + 2):
				var own: Array = []
				var old: Array = []
				for k in range(4):
					own.append(_graded_own(int(blows[1 + k]), h, d))
					old.append(_graded_old(int(blows[1 + k]), h, d))
				var s_own: bool = SimPressRead.classify(_beat_log(own, blows), int(own[3]) + 3)["steady"]
				var s_old: bool = SimPressRead.classify(_beat_log(old, blows), int(old[3]) + 3)["steady"]
				var in_freeze: bool = d >= 1 and d <= h
				var on_beat: bool = absi(d) <= 2
				ok(s_own == on_beat, "freeze: four presses %d ticks from the contact (hit-stop %d, cadence %d) are %s the blur's beat" % [d, h, cad, "on" if on_beat else "off"])
				if in_freeze and d > 2:
					ok(s_old, "freeze: the rule before graded the same press at the freeze's start, so it was on the beat (d %d, h %d)" % [d, h])
	# The first two ticks of a freeze count; the fourth does not (the brief's numbers, hit-stop 5).
	var blows5: Array = [100, 117, 134, 151, 168]
	var first2: Array = [_graded_own(117, 5, 2), _graded_own(134, 5, 2), _graded_own(151, 5, 2), _graded_own(168, 5, 2)]
	var fourth: Array = [_graded_own(117, 5, 4), _graded_own(134, 5, 4), _graded_own(151, 5, 4), _graded_own(168, 5, 4)]
	ok(SimPressRead.classify(_beat_log(first2, blows5), int(first2[3]) + 3)["steady"], "freeze: a press 2 ticks into a freeze is on the blur's beat")
	ok(not SimPressRead.classify(_beat_log(fourth, blows5), int(fourth[3]) + 3)["steady"], "freeze: a press 4 ticks into a freeze is not")
	# The combo's timed press (beatHalf, 4) still takes the first 4 ticks of a freeze, and not the fifth.
	var p: Dictionary = SimPressRead.params()
	ok(SimPressRead.grade_of(_graded_own(100, 5, 4) - 100) == "perfect" and SimPressRead.grade_of(_graded_own(100, 5, 5) - 100) == "good", "freeze: a timed combo press (4 ticks) takes the first 4 ticks of a freeze, the fifth is good")
	ok(p["blurBeatHalf"] == 2 and p["beatHalf"] == 4, "freeze: the blur's window is 2 and the combo's 4")
