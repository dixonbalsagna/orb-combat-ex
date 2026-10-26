extends SceneTree
## Golden check for the GDScript sim (the CI gate). It recomputes every golden vector with the recipes in
## golden_recipes.gd and exits 0 only if all match the golden file bit for bit. From the repo root:
##   godot --headless --path . --import
##   godot --headless --path . --script res://sim/core/tools/parity.gd [-- --golden=res://path.json] [-- --no-bench]
## The default golden file is sim/core/test/golden.json, written by tools/golden.gd. The frozen JS record
## (sim/core/test/frozen/golden-js.json) is checked the same way with --golden; it matches only while the GDScript
## sim still behaves like the frozen JS core. It also prints the tick cost.

const DEFAULT_GOLDEN := "res://sim/core/test/golden.json"
const LIT_RE := "(?<![\\w.])(\\d+\\.\\d+(?:e[+-]?\\d+)?|\\d+e[+-]?\\d+)(?![\\w.])"

var failures: int = 0


func _init() -> void:
	var t0: int = Time.get_ticks_usec()
	var path: String = DEFAULT_GOLDEN
	var bench: bool = true
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--golden="):
			path = a.substr(9)
		elif a == "--no-bench":
			bench = false
	print("Orb Combat EX golden check   Godot %s   %s" % [Engine.get_version_info().string, path])
	var g = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (g is Dictionary):
		print("FAIL  cannot read %s (generate it with: godot --headless --path . --script res://sim/core/tools/golden.gd)" % path)
		quit(1)
		return
	check("long float literals", _literals())
	check("constants", _list("constants", SimGolden.constants(), g.constants))
	check("cosmetic stream seeds", _stream_seeds(g))
	check("rng", _keyed(g.rng, func(s): return SimGolden.rngHash(s)))
	check("wrap", "" if SimGolden.wrapHash() == g.wrap else "differs")
	check("sin/cos", "" if SimGolden.sincosHash() == g.sincos else "differs")
	check("pow/exp/log/hypot", "" if SimGolden.powHash() == g.powexplog else "differs")
	check("tick-0 state", _tick0(g))
	check("wounds (forced hits)", "" if SimGolden.woundsHash() == g.get("wounds", "") else "differs")
	check("rally (forced)", "" if SimGolden.rallyHash() == g.get("rally", "") else "differs")
	check("crippling (forced)", "" if SimGolden.crippleHash() == g.get("cripple", "") else "differs")
	check("mood and style (forced)", "" if SimGolden.moodHash() == g.get("mood", "") else "differs")
	check("fight data", _fightData(g))
	check("roster data", _roster(g))
	check("roster loader rejects bad data", _rosterRejects())
	check("the game's wounds and ladder files, and a fighter's differences", _sharedFiles())
	check("the training dummy in the roster", _dummyFighter())
	check("a match's slots name two fighters the data has", _slotGuard())
	check("one versus many: a match of three to five bodies", _nBodies())
	check("one versus many: what the core counts of a guard", _guardRules())
	check("wired numbers change a match", _wiredNumbers())
	check("keyed draws", _keyedDraws(g))
	check("arm setups", _armSetups())
	check("intent pack", _intentPack())
	check("a stun ends the held states", _stunGate())
	check("action state", _actState())
	check("pausing set pieces", _pause())
	check("act rule and time cap", _actRule())
	check("the break", _formBreak())
	check("the form impulse", _formImpulse())
	check("blocked blows and the arms", _blockedArms())
	check("blocked shots and the arms", _blockedShots())
	check("the second breath waits for quiet", _breathQuiet())
	check("a bowed rush", _rushArc())
	check("a drop", _drop())
	check("the mood by a blow's form", _moodForms())
	check("the free-flight speed and the locked damping, as reads", _flightReads())
	check("the stick as held, through a stun", _heldStick())
	check("a medium blow, rule by rule", _mediumWeight())
	check("a blow that names its region", _namedRegion())
	check("no tier past the ladder's last", _tierCap())
	check("the view's particles carry their depth", _partDepth())
	check("depth in the core", _depth())
	check("a fighter's depth outside a flight, and the contact rule", _depthStep())
	check("the intro phase", _intro())
	check("composed intros", _introComposed())
	check("the intro's default facts and the take", _introDefault())
	check("the last stand", _lastStand())
	check("a hidden fighter is found when he charges or is launched", _foundAnnounced())
	check("shots", _plainShots())
	check("shots: buildings, wild deflects, the spray, mines", _shots2())
	check("agency lines", _agencyLines())
	check("a clash's meeting point", _clashMid())
	check("SimMathx.PI and TAU", _piTau())
	check("the blow cue's run stays out of the hash", _cueRun())
	check("the run's rare boons", _boons())
	check("the catastrophe's blast cloud and ash", _cata())
	check("the launch's curve", _flight())
	check("hit-stop by weight", _hitstop())
	check("the ricochet's glance", _ricochet())
	check("the run's ground", _runGround())
	check("the run's state and carry", _runState())
	check("the campaign's arc and episode", _campaign())
	check("the planet's load", _planetLoad())
	check("the curve's shared functions, the brake's control back, the camera feed", _shared())
	check("the air brake", _brake())
	check("forms: five steps and the slingshot", _forms())
	check("forms: Witness and Trial", _formBranches())
	check("Animation's view fields: a launch's tier, a hit's stop and tier", _animFields())
	check("the intro phase (golden)", "" if SimGolden.introHash() == g.get("intro", "") else "differs")
	check("composed intros (golden)", "" if SimGolden.introComposedHash() == g.get("introComposed", "") else "differs")
	check("replay module", _replayModule())
	var tm: int = Time.get_ticks_usec()
	check("matches", _matches(g))
	check("human-input replays", _replays(g))
	check("planet worlds (golden)", _planetGolden(g))
	print("      (matches and replays: %.1f s)" % ((Time.get_ticks_usec() - tm) / 1e6))
	if bench:
		_bench()
	print("time  %.1f s" % ((Time.get_ticks_usec() - t0) / 1e6))
	print("\ngolden check FAILED" if failures else "\ngolden check passed")
	quit(1 if failures else 0)


## err is "" for a pass. Anything else fails, including null: a check that stops on a script error returns null, and must
## not read as a pass.
func check(name: String, err) -> void:
	if err is String and err == "":
		print("ok    " + name)
	else:
		failures += 1
		print("FAIL  %s: %s" % [name, err])


## GDScript's parser is not correctly rounded for long literals, and whether its result can differ between platforms is
## unproven, so the sim may not contain float literals with more than 15 significant digits: build such constants from
## their bits with SimMathx.f64 (sim/README.md, GDScript traps).
func _literals() -> String:
	var re := RegEx.create_from_string(LIT_RE)
	var strip_str := RegEx.create_from_string("\"[^\"\\n]*\"")
	var strip_com := RegEx.create_from_string("(?m)#.*$")
	var bad: Array = []
	for file in _gd_files("res://sim"):
		var src: String = strip_com.sub(strip_str.sub(FileAccess.get_file_as_string(file), "\"\"", true), "", true)
		for m in re.search_all(src):
			var lit: String = m.get_string(1)
			var digits: String = lit.split("e")[0].split("E")[0].replace(".", "").lstrip("0")
			if digits.length() > 15:
				bad.append("%s in %s" % [lit, file])
	return "" if bad.is_empty() else "use SimMathx.f64 for: " + ", ".join(bad)


func _gd_files(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_gd_files(dir.path_join(d)))
	return out


func _list(what: String, got: Array, want: Array) -> String:
	if got.size() != want.size():
		return "%d %s, golden %d" % [got.size(), what, want.size()]
	for i in range(got.size()):
		if str(got[i]) != str(want[i]):
			return "%s %d is %s, golden %s" % [what, i, got[i], want[i]]
	return ""


func _keyed(want: Dictionary, fn: Callable) -> String:
	for k in want:
		var got: String = fn.call(int(k))
		if got != want[k]:
			return "seed %s: %s, golden %s" % [k, got, want[k]]
	return ""


func _stream_seeds(g: Dictionary) -> String:
	for k in g.streamSeeds:
		var got: Array = SimGolden.streamSeeds(int(k))
		for i in range(got.size()):
			if got[i] != int(g.streamSeeds[k][i]):
				return "seed %s %s: %d, golden %d" % [k, SimGolden.STREAM_IDS[i], got[i], int(g.streamSeeds[k][i])]
	return ""


func _tick0(g: Dictionary) -> String:
	for k in g.tick0:
		var got: String = SimGolden.tick0Hash(int(k))
		if got != g.tick0[k]:
			var why := "seed %s: %s (golden %s)" % [k, got, g.tick0[k]]
			if k == "1":
				why += "; " + _first_diff(SimGolden.tick0Values(1), g.tick0Values)
			return why
	return ""


func _first_diff(got: Array, want: Array) -> String:
	for i in range(maxi(got.size(), want.size())):
		var a: String = got[i] if i < got.size() else "(missing)"
		var b: String = want[i] if i < want.size() else "(missing)"
		if a != b:
			return "first difference at value %d: %s, golden %s" % [i, a, b]
	return "value lists are equal (the hash code differs)"


func _matches(g: Dictionary) -> String:
	var bad: Array = []
	var ticks: int = 0
	for m in g.matches:
		var got: Dictionary = SimGolden.goldenRun(m.arm, int(m.seed), null, int(m.get("cap", SimGolden.CAP)))
		ticks += got.ticks
		var e := SimGolden.compareRun(got, m, "%s seed %d" % [m.arm, int(m.seed)])
		if e != "":
			bad.append(e)
	if bad.size():
		return "; ".join(bad)
	print("      %d matches, %d ticks: every per-tick digest and full-state checkpoint identical" % [g.matches.size(), ticks])
	return ""


func _replays(g: Dictionary) -> String:
	for r in g.replays:
		var got: Dictionary = SimGolden.goldenRun("default", int(r.replay.seed), r.replay)
		var e := SimGolden.compareRun(got, r.run, "replay seed %d" % int(r.replay.seed))
		if e != "":
			return e
	return ""


## A stunned fighter's intent (SimWounds.gateIntent): the stick, every edge and every held state end, the stance mask and
## the two held levels of intent version 4 among them; the mode stays, and so does escape (the way out of any situation).
func _stunGate() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var hold := SimIntent.new()
	hold.mx = 1.0
	hold.mode = 1
	hold.escape = true
	hold.stanceMask = 13
	for k in ["guard", "sprint", "power", "light", "heavy", "lightHeld", "heavyHeld", "contextHeld", "sigHeld", "context", "dodge"]:
		hold.set(k, true)
	var res: String = ""
	for stunned in [false, true]:
		var f = S.fighters[0]
		f.stunTicks = 30 if stunned else 0
		SimControl.control(S, f, hold)
		var i: SimIntent = f.input
		var held: bool = i.guard or i.sprint or i.power or i.lightHeld or i.heavyHeld or i.contextHeld or i.sigHeld or i.stanceMask != 0 or i.mx != 0.0
		if stunned and (held or i.light or i.context or i.dodge):
			res = "a stunned fighter's intent still holds something (mask %d, contextHeld %s, sigHeld %s)" % [i.stanceMask, str(i.contextHeld), str(i.sigHeld)]
		elif stunned and (i.mode != 1 or not i.escape):
			res = "a stun dropped the mode or the escape"
		elif not stunned and (i.stanceMask != 13 or not i.contextHeld or not i.sigHeld or not i.lightHeld):
			res = "a free fighter's held states did not reach his input"
	SimCore.dispose(S)
	return res


## I1 (intent v2) to version 4: pack and unpack are inverse on every field's range, canon() puts the stick on its 1 / 127
## grid, unpack refuses integers that are not packed intents, and a replay's two-number entry carries the whole record.
func _intentPack() -> String:
	var bools: Array = ["guard", "guardPress", "dodge", "sprint", "power", "powerPress", "powerTap", "light", "heavy", "sig", "context", "transform", "dash", "charge", "lightHeld", "heavyHeld", "escape", "contextHeld", "sigHeld"]
	var fields: Array = ["mx", "my", "mode", "upgrade", "special", "stance", "waited", "stanceMask"] + bools
	var same := func(x: SimIntent, y: SimIntent) -> bool:
		for k in fields:
			if x.get(k) != y.get(k):
				return false
		return true
	var cases: Array = []
	var neutral := SimIntent.new()
	if SimIntent.unpack(SimIntent.pack(neutral)) == null or not same.call(neutral, SimIntent.unpack(SimIntent.pack(neutral))):
		return "the neutral intent does not round-trip"
	for b in bools:
		var i := SimIntent.new()
		i.set(b, true)
		cases.append(i)
	for v in [[-1, 0, 0, -1.0], [0, 1, 1, 0.0], [1, 2, 4, 1.0], [1, 2, 7, 2.0], [0, 0, 3, 3.0]]:
		var i2 := SimIntent.new()
		i2.mode = v[0]; i2.upgrade = v[1]; i2.special = v[2]; i2.stance = v[3]
		cases.append(i2)
	for w in range(16):   # waited, 0 to 15
		var iw := SimIntent.new()
		iw.waited = w
		cases.append(iw)
	for m in range(16):   # the stance mask, 0 to 15, alone and with the two held levels
		for lv in range(4):
			var im := SimIntent.new()
			im.stanceMask = m
			im.contextHeld = (lv & 1) != 0
			im.sigHeld = (lv & 2) != 0
			cases.append(im)
	for k in range(-127, 128):
		var i3 := SimIntent.new()
		i3.mx = float(k) / 127.0
		i3.my = float(-k) / 127.0
		cases.append(i3)
	var r := SimRng.new(2024)
	for n in range(4000):
		var i4 := SimIntent.new()
		i4.mx = float(int(floor(r.next() * 255.0)) - 127) / 127.0
		i4.my = float(int(floor(r.next() * 255.0)) - 127) / 127.0
		i4.mode = int(floor(r.next() * 3.0)) - 1
		i4.upgrade = int(floor(r.next() * 3.0))
		i4.special = int(floor(r.next() * 8.0))
		i4.stance = float(int(floor(r.next() * 5.0)) - 1)
		i4.waited = int(floor(r.next() * 16.0))
		i4.stanceMask = int(floor(r.next() * 16.0))
		for b in bools:
			i4.set(b, r.next() < 0.5)
		cases.append(i4)
	for i in cases:
		var p: int = SimIntent.pack(i)
		var u: SimIntent = SimIntent.unpack(p)
		if u == null or not same.call(i, u):
			return "unpack(pack(i)) differs for packed %d" % p
		if SimIntent.pack(u) != p:
			return "pack(unpack(p)) differs for %d" % p
		# the replay's entry: two numbers, each exact as a JSON number, that join back to the same integer
		var two: Array = SimReplay.split(p)
		var back = JSON.parse_string(JSON.stringify(two))
		if two[0] < 0 or two[0] > SimReplay.LOW_MASK or two[1] < 0 or SimReplay.join(back[0], back[1]) != p:
			return "a replay entry does not carry packed %d through JSON (%s)" % [p, str(two)]
	var top := SimIntent.new()
	top.sigHeld = true   # the record's top bit
	if (SimIntent.pack(top) ^ SimIntent.pack(neutral)) != 1 << (SimIntent.BITS - 1) or SimIntent.BITS != 53:
		return "sigHeld is not the top bit of a 53-bit record (BITS %d, packed %d)" % [SimIntent.BITS, SimIntent.pack(top)]
	if SimReplay.split(-1) != [null, null] or SimReplay.join(null, null) != -1:
		return "no intent is not [null, null] in a replay entry"
	for badpair in [[null, 0], [0, null], [0.5, 0], [0, 0.5], [-1, 0], [0, -1], [SimReplay.LOW_MASK + 1, 0], [0, SimReplay.HIGH_MAX + 1], ["1", 0]]:
		if SimReplay.join(badpair[0], badpair[1]) != -2:
			return "a replay entry %s was joined" % str(badpair)
	var off := SimIntent.new()
	off.mx = 0.5
	off.my = -0.3333
	var c: SimIntent = SimIntent.canon(off)
	if c.mx != 64.0 / 127.0 or c.my != -42.0 / 127.0 or SimIntent.pack(c) != SimIntent.pack(off):
		return "canon() does not put the stick on its 1 / 127 grid"
	for badp in [-1, 1 << 53, 1 << 62, 255, 255 << 8, 3 << 16, 3 << 18, 5 << 35, 7 << 35]:
		if SimIntent.unpack(badp) != null:
			return "unpack accepted %d, which is not a packed intent" % badp
	return ""


## I2a: the action state's rules (sim/core/act.gd), each asserted: the setup's v2 and assists, the stance from the held
## states (and today's stance field for a slot that is not v2), guard, dodge, mode and the cooldowns, the stun gate, the
## burst flag, the queue, and the tier-up gate with its data flag on and off.
func _actState() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"v2": [true, false], "assists": [["autoBurst"], []]})
	var a = S.fighters[0]
	var b = S.fighters[1]
	if not a.act.v2 or b.act.v2 or not SimAct.assisted(a, "autoBurst") or SimAct.assisted(a, "specialAuto") or SimAct.assisted(b, "autoBurst"):
		return "the setup's v2 and assists did not reach the fighters"
	var ia := SimIntent.new()
	var ib := SimIntent.new()
	var away: float = -SimMathx.jsign(SimWrap.sdx(a.x, b.x))
	var go := func() -> void:
		SimCore.step(S, [ia, ib])
		S.out.fx.clear()
		S.out.feed.clear()
	ib.stance = 1.0
	ia.stance = 1.0          # ignored for the v2 slot
	go.call()
	if b.stance != 1.0 or a.stance != 0.0:
		return "the stance field: b %s (wants 1, not v2), a %s (wants 0, v2 ignores it)" % [str(b.stance), str(a.stance)]
	ia.guard = true
	go.call()
	var t0: int = S.tick
	if a.stance != 1.0 or a.act.guardSince != t0:
		return "guard held: stance %s, guardSince %d (tick %d)" % [str(a.stance), a.act.guardSince, t0]
	go.call()
	if a.act.guardSince != t0:
		return "guardSince moved while the guard was held"
	ia.guard = false
	go.call()
	if a.stance != 0.0 or a.act.guardSince != -1:
		return "guard released: stance %s, guardSince %d" % [str(a.stance), a.act.guardSince]
	ia.dodge = true
	go.call()
	ia.dodge = false
	var held: int = 1
	while a.stance == 2.0 and held < 40:
		go.call()
		held += 1
	if held != SimAct.dodgeWindow + 1:
		return "a dodge read as Dodge for %d ticks, not %d" % [held - 1, SimAct.dodgeWindow]
	ia.sprint = true
	ia.mx = away
	go.call()
	if a.stance != 3.0:
		return "sprint away is not Escape (stance %s)" % str(a.stance)
	ia.mx = -away
	go.call()
	if a.stance != 0.0:
		return "sprint toward read as %s" % str(a.stance)
	ia.sprint = false
	ia.mx = 0.0
	ia.mode = 1
	go.call()
	ia.mode = -1
	go.call()
	if a.act.mode != 1:
		return "the mode did not hold through auto (%d)" % a.act.mode
	a.act.dodgeCool = 3
	a.act.burstCool = 2
	go.call(); go.call(); go.call()
	if a.act.dodgeCool != 0 or a.act.burstCool != 0:
		return "the cooldowns did not count down"
	ia.guard = true
	a.stunTicks = 5
	go.call()
	if a.stance != 0.0 or a.input.guard:
		return "a stunned fighter kept its guard"
	a.stunTicks = 0
	ia.guard = false
	# the burst flag
	var ip := SimIntent.new()
	ip.powerPress = true
	SimAct.update(S, a, ip)
	if not SimAct.wantsBurst(a, ip, true):
		return "a threatened power press did not burst"
	var it := SimIntent.new()
	it.powerTap = true
	SimAct.update(S, a, it)
	if SimAct.wantsBurst(a, it, false):
		return "the tap after a burst-on-press fired a second burst"
	SimAct.update(S, a, ip)
	if SimAct.wantsBurst(a, ip, false):
		return "an unthreatened press burst at once"
	SimAct.update(S, a, it)
	if not SimAct.wantsBurst(a, it, false):
		return "an unthreatened tap did not burst"
	# the queue
	var pushed: int = 0
	for n in range(5):
		if SimAct.push(a, SimAct.LIGHT, 0, 1, 100 + n):
			pushed += 1
	if pushed != SimAct.queueMax or a.act.queue.size() != SimAct.queueMax:
		return "the queue took %d requests, not %d" % [pushed, SimAct.queueMax]
	if not SimAct.upgrade(a, SimAct.HEAVY) or a.act.queue[SimAct.queueMax - 1][0] != SimAct.HEAVY or a.act.queue[0][0] != SimAct.LIGHT:
		return "an upgrade did not replace the newest request's weight"
	SimAct.expire(a, 138, 36)   # pushed at ticks 100, 101, 102: the first two are older than 36 ticks, the last is exactly 36
	if a.act.queue.size() != SimAct.queueMax - 2 or SimAct.peek(a)[3] != 100 + SimAct.queueMax - 1:
		return "expiry left %d requests" % a.act.queue.size()
	if SimAct.pop(a)[0] != SimAct.HEAVY or not SimAct.pop(a).is_empty() or SimAct.upgrade(a, SimAct.SIG):
		return "pop or upgrade on an empty queue"
	# the tier-up gate, on (the data, since I2b): a threshold makes the form ready and the tier waits for the transform
	a.power = a.ld.thresholds[1] + 1.0   # two steps earned, whatever the thresholds are
	SimFighter.stepFighter(S, a, SimConst.DT)
	if a.tier != 1.0 or not a.act.formReady:
		return "with manualTierUp on the tier did not wait (tier %s, ready %s)" % [str(a.tier), str(a.act.formReady)]
	if not SimFighter.transform(S, a) or a.tier != 2.0 or not a.act.formReady:
		return "the first transform: tier %s, ready %s" % [str(a.tier), str(a.act.formReady)]
	if not SimFighter.transform(S, a) or a.tier != 3.0 or a.act.formReady or SimFighter.transform(S, a):
		return "the second transform: tier %s, ready %s" % [str(a.tier), str(a.act.formReady)]
	SimCore.dispose(S)
	# ... and off, from a copy of the data: the tier rises by itself
	var dir := "user://i2a_gate/"
	for id in ["PROTAGONIST", "RIVAL"]:
		DirAccess.make_dir_recursive_absolute(dir + id)
		for fname in ["fighter.json", "wounds.json", "meters.json", "ladder.json"]:
			var text: String = _fighterText(id, fname)
			if fname == "ladder.json":
				var d = JSON.parse_string(text)
				d.manualTierUp = false
				text = JSON.stringify(d, "  ")
			var fw := FileAccess.open(dir + id + "/" + fname, FileAccess.WRITE)
			fw.store_string(text)
			fw.close()
	var rf := FileAccess.open(dir + "roster.json", FileAccess.WRITE)
	rf.store_string("[\"PROTAGONIST\", \"RIVAL\"]")
	rf.close()
	FighterData.quiet = true
	FighterData.loadFrom(dir)
	var err: String = "; ".join(FighterData.errors())
	if err == "":
		var G := SimCore.createSim()
		SimCore.newMatch(G, 5)
		var f = G.fighters[0]
		f.power = f.ld.thresholds[0] + 1.0   # one step earned
		SimFighter.stepFighter(G, f, SimConst.DT)
		if f.tier != 2.0 or f.act.formReady or SimFighter.transform(G, f):
			err = "with manualTierUp off the tier did not rise by itself"
		SimCore.dispose(G)
	FighterData.quiet = false
	FighterData.loadFrom()
	return err


## Q10: pausing set pieces (sim/core/pause.gd), each rule asserted: the bank's start, accrual and cap; the full, short
## and live versions and what each spends; the final-form length; a live step; the time cap; two requests on one tick; a
## pause as frozen ticks (no input consumed, the clock and the fighters still, a hit-stop resumed after it); and a replay
## of an AI match that runs through a pause.
func _pause() -> String:
	if not SimPause.errors().is_empty():
		return "; ".join(SimPause.errors())
	var fresh := func() -> SimState:
		var S0 := SimCore.createSim()
		SimCore.newMatch(S0, 5)
		return S0
	var started := func(S0: SimState) -> int:
		var n: int = 0
		for e in S0.out.fx:
			if e.type == "pause_start":
				n += 1
		return n
	# the bank
	var S: SimState = fresh.call()
	var p = S.pause
	if p.bank != SimPause.bankStart or p.left != 0 or p.total != 0:
		return "a new match's bank is %d ticks, not %d" % [p.bank, SimPause.bankStart]
	p.bank = 0
	for t in range(SimPause.TPM):
		SimPause.liveTick(S)
	if p.bank != mini(SimPause.bankMax, SimPause.bankGain):
		return "a minute of match time gave the bank %d ticks, not %d" % [p.bank, SimPause.bankGain]
	p.bank = SimPause.bankMax - 1
	for t in range(SimPause.TPM):
		SimPause.liveTick(S)
	if p.bank != SimPause.bankMax:
		return "the bank passed its cap (%d)" % p.bank
	SimCore.dispose(S)
	# full, then a second request on the same tick, then the frozen ticks
	S = fresh.call()
	p = S.pause
	var kai = S.fighters[0]
	p.bank = SimPause.bankMax
	S.dirS.stop = 0.2
	var r: Dictionary = SimPause.request(S, SimPause.TRANSFORM, 0)
	if r.version != SimPause.FULL or r.ticks != SimPause.fullTicks or p.left != SimPause.fullTicks or p.bank != SimPause.bankMax - SimPause.fullTicks or started.call(S) != 1:
		return "the first set piece was not the full version (%s, bank %d)" % [str(r), p.bank]
	var r2: Dictionary = SimPause.request(S, SimPause.TRANSFORM, 1)
	if r2.version != SimPause.LIVE or r2.ticks != SimPause.liveTicks or p.left != SimPause.fullTicks or started.call(S) != 1:
		return "a second request on the same tick was not live (%s)" % str(r2)
	var t0: float = S.T
	var x0: float = kai.x
	var ki0: float = kai.ki
	var tick0: int = S.tick
	var ended: int = 0
	for t in range(SimPause.fullTicks):
		S.out.fx.clear()
		if SimCore.step(S, null):
			return "a paused tick consumed input (tick %d of the pause)" % t
		for e in S.out.fx:
			if e.type == "pause_end":
				ended += 1
	if S.T != t0 or kai.x != x0 or kai.ki != ki0 or S.tick != tick0 + SimPause.fullTicks or p.left != 0 or p.total != SimPause.fullTicks or ended != 1:
		return "the pause did not hold the sim still (T %s to %s, left %d, total %d, ends %d)" % [str(t0), str(S.T), p.left, p.total, ended]
	if S.dirS.stop != 0.2:
		return "the pause spent the hit-stop (%s)" % str(S.dirS.stop)
	var stops: int = 0
	while not SimCore.step(S, null) and stops < 100:
		stops += 1
	var H: SimState = fresh.call()   # the same hit-stop with no pause before it
	H.dirS.stop = 0.2
	var plain: int = 0
	while not SimCore.step(H, null) and plain < 100:
		plain += 1
	SimCore.dispose(H)
	if stops != plain or plain == 0 or S.T == t0:
		return "the hit-stop after the pause ran %d ticks, not %d" % [stops, plain]
	# short: a repeat, with the bank and the gap it needs; live below either
	p.bank = SimPause.shortTicks
	p.sinceEnd = SimPause.shortGap - 1
	r = SimPause.request(S, SimPause.TRANSFORM, 0)
	if r.version != SimPause.LIVE or p.bank != SimPause.shortTicks or p.left != 0:
		return "a request inside the short gap was not live (%s)" % str(r)
	p.sinceEnd = SimPause.shortGap
	r = SimPause.request(S, SimPause.TRANSFORM, 0)
	if r.version != SimPause.SHORT or r.ticks != SimPause.shortTicks or p.bank != 0 or p.left != SimPause.shortTicks:
		return "a repeat with the bank and the gap was not short (%s, bank %d)" % [str(r), p.bank]
	SimCore.dispose(S)
	# a first set piece inside the full gap, or with a thin bank
	S = fresh.call()
	p = S.pause
	p.bank = SimPause.bankMax
	p.sinceEnd = SimPause.fullGap - 1
	r = SimPause.request(S, SimPause.TRANSFORM, 0)
	if r.version != SimPause.SHORT:
		return "a first set piece inside the full gap was not short (%s)" % str(r)
	SimCore.dispose(S)
	S = fresh.call()
	p = S.pause
	p.bank = SimPause.shortTicks - 1
	r = SimPause.request(S, SimPause.TRANSFORM, 0)
	if r.version != SimPause.LIVE or p.bank != SimPause.shortTicks - 1 or p.left != 0 or started.call(S) != 0:
		return "a set piece the bank cannot cover was not live (%s)" % str(r)
	SimCore.dispose(S)
	# a final-form reveal takes what the bank covers, up to its own length
	S = fresh.call()
	p = S.pause
	p.bank = SimPause.bankMax
	r = SimPause.request(S, SimPause.TRANSFORM, 0, true)
	if r.version != SimPause.FULL or r.ticks != mini(SimPause.finalTicks, SimPause.bankMax):
		return "a final-form reveal: %s" % str(r)
	SimCore.dispose(S)
	# a live step never pauses and leaves the bank and the first-of-kind mark alone
	S = fresh.call()
	p = S.pause
	p.bank = SimPause.bankMax
	var kinds: Array = S.fighters[0].ld.stepKinds
	var was: String = kinds[0]
	kinds[0] = "live"
	r = SimPause.request(S, SimPause.TRANSFORM, 0)
	kinds[0] = was
	if r.version != SimPause.LIVE or p.bank != SimPause.bankMax or p.seen != 0 or p.left != 0:
		return "a live step: %s, bank %d, seen %d" % [str(r), p.bank, p.seen]
	# the time cap always pauses, outside the bank
	p.bank = 0
	r = SimPause.request(S, SimPause.TIMECAP, -1)
	if r.ticks != SimPause.capTicks or p.left != SimPause.capTicks or p.bank != 0:
		return "the time cap: %s, left %d" % [str(r), p.left]
	SimCore.dispose(S)
	# an AI match recorded through a pause plays back
	for seed in [3, 7, 12]:
		var R := SimCore.createSim()
		var rec := SimReplay.recorder(R, seed, {})
		var n: int = 0
		while n < 14400 and R.pause.total == 0:
			rec.step(null)
			R.out.fx.clear()
			R.out.feed.clear()
			n += 1
		var paused: bool = R.pause.total > 0
		for t in range(600):
			rec.step(null)
			R.out.fx.clear()
			R.out.feed.clear()
		var rp: Dictionary = rec.finish()
		SimCore.dispose(R)
		if not paused:
			continue
		var res: Dictionary = SimReplay.play(JSON.parse_string(JSON.stringify(rp)))
		return "" if res.ok else "a replay through a pause: %s at tick %d" % [res.reason, res.firstBadTick]
	return "no AI match of seeds 3, 7 and 12 reached a pause in four minutes"


## The agency pass's small core lines: the autoCharge assist reaches a slot from the setup; the flow count is 0 at the
## start and setFlow sends one flow event for a change and none for the same value; the embed fields start clear; the
## four events (knockback, exchange_end, flow, embed) carry their fields; and no default match sends any of them.
## Hiding ends announced (QA's lock-break trace): a hidden fighter who starts to charge, or is launched, is found on that
## tick (the found event, hidden cleared, and lockBackT set so the lock cannot break again at once).
func _foundAnnounced() -> String:
	for launched in [false, true]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
		for t in range(30):
			SimCore.step(S)
		var a = S.fighters[0]
		var b = S.fighters[1]
		S.out.fx.clear()
		b.hidden = true
		b.hiddenFor = 1.0
		b.lockBackT = -100.0
		var what: String
		if launched:
			what = "launched"
			DirLaunch.doLaunch(S, a, b, {"ux": 1.0, "uy": 0.3}, 1300.0)
		else:
			what = "charging"
			b.state = "free"
			b.rush = null
			b.stunTicks = 0
			b.input.charge = true
			SimFighter.stepFighter(S, b, SimConst.DT)
		var found: int = 0
		for e in S.out.fx:
			if e.type == "found" and e.actor == 1.0 and e.tick == S.tick:
				found += 1
		var res: String = ""
		if b.state != what:
			res = "the test did not get him %s (state %s)" % [what, b.state]
		elif found != 1 or b.hidden or b.lockBackT != S.T:
			res = "a hidden fighter %s: %d found events, hidden %s, lockBackT %s at T %s" % [what, found, str(b.hidden), str(b.lockBackT), str(S.T)]
		# a fighter who was not hidden is not announced
		S.out.fx.clear()
		if res == "" and not launched:
			b.state = "free"
			SimFighter.stepFighter(S, b, SimConst.DT)
			for e in S.out.fx:
				if e.type == "found":
					res = "a fighter who was not hidden was announced as found when he charged"
		SimCore.dispose(S)
		if res != "":
			return res
	return ""


## The first round's check, with the second round's two rules off whatever the data's switches say.
func _plainShots() -> String:
	if not SimShots.errors().is_empty():
		return "; ".join(SimShots.errors())
	var hadS: bool = SimShots.structures
	var hadD: bool = SimShots.scatter
	SimShots.structures = false
	SimShots.scatter = false
	var res: String = _shots()
	SimShots.structures = hadS
	SimShots.scatter = hadD
	return res


## The second round (docs/architecture/shots.md sections 13 to 17), each rule forced whatever the data's switches say.
func _shots2() -> String:
	if not SimShots.errors().is_empty():
		return "; ".join(SimShots.errors())
	var hadS: bool = SimShots.structures
	var hadD: bool = SimShots.scatter
	var res: String = _shots2Run()
	SimShots.structures = hadS
	SimShots.scatter = hadD
	return res


func _shots2Run() -> String:
	var dt: float = SimConst.DT
	var bolt: Dictionary = SimShots.kinds.bolt
	if not SimShots.kinds.has("mine") or SimShots.kinds.mine.mine == null:
		return "the data has no mine kind"
	var mk: Dictionary = SimShots.kinds.mine
	var md: Dictionary = mk.mine
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var a = S.fighters[0]
	var b = S.fighters[1]
	var count := func(type: String, key: String = "", val = null) -> int:
		var c: int = 0
		for e in S.out.fx:
			if e.type == type and (key == "" or e.get(key) == val):
				c += 1
		return c
	var run := func(ticks: int) -> void:
		for t in range(ticks):
			SimShots.step(S, dt)
	var clear := func() -> void:
		for q in S.shots:
			q.dead = true
		SimShots.step(S, dt)
		S.out.fx.clear()
	# ---- buildings: a building in a blast's reach of the plane, with clear air on its left
	var bi: int = -1
	for i in range(S.buildings.size()):
		var c = S.buildings[i]
		if not c.alive or WorldStructures.dz(c) > WorldStructures.Z_REACH or WorldStructures.curH(c) < 120.0:
			continue
		var sx0: float = SimWrap.wrap(c.x - c.w * 0.5 - 200.0)
		var free: bool = true
		for o in S.buildings:
			if o != c and o.alive and absf(SimWrap.sdx(sx0, o.x)) < o.w * 0.5 + 220.0:
				free = false
		if free:
			bi = i
			break
	if bi < 0:
		return "no building in reach of the plane with clear air beside it"
	var bd = S.buildings[bi]
	var base: float = WorldStructures.baseY(S, bd)
	var top: float = base + WorldStructures.curH(bd)
	b.x = SimWrap.wrap(bd.x + 60000.0); b.y = 9000.0
	a.x = SimWrap.wrap(bd.x - bd.w * 0.5 - 200.0)
	a.y = (base + top) * 0.5 - SimShots.chest
	SimShots.scatter = false
	SimShots.structures = false
	var sh = SimShots.fire(S, 0, "bolt", {"ux": 1.0, "uy": 0.0})
	run.call(12)
	if sh.dead or SimWrap.sdx(bd.x, sh.x) < bd.w * 0.5:
		return "with structures off a bolt did not fly through the building"
	clear.call()
	SimShots.structures = true
	sh = SimShots.fire(S, 0, "bolt", {"ux": 1.0, "uy": 0.0})
	run.call(12)
	if not sh.dead or count.call("shot_end", "cause", "building") != 1 or absf(SimWrap.sdx(sh.x, bd.x) - (bd.w * 0.5 + bolt.r)) > 0.01:
		return "a bolt did not stop on the building's face (dead %s, %s from its centre, half width %s)" % [str(sh.dead), str(SimWrap.sdx(sh.x, bd.x)), str(bd.w * 0.5)]
	clear.call()
	# over every roof along its way (a taller building of another row may stand behind this one)
	var over: float = top
	for o in S.buildings:
		if o.alive and WorldStructures.dz(o) <= WorldStructures.Z_REACH and absf(SimWrap.sdx(SimWrap.wrap(a.x + 330.0), o.x)) < o.w * 0.5 + 400.0:
			over = maxf(over, WorldStructures.baseY(S, o) + WorldStructures.curH(o))
	a.y = over + bolt.r + 30.0 - SimShots.chest
	sh = SimShots.fire(S, 0, "bolt", {"ux": 1.0, "uy": 0.0})
	run.call(12)
	if sh.dead:
		return "a bolt over the roofs was stopped"
	clear.call()
	# from above, onto the roof
	a.x = bd.x
	a.y = top + 300.0 - SimShots.chest
	sh = SimShots.fire(S, 0, "bolt", {"ux": 0.0, "uy": -1.0})
	run.call(12)
	if not sh.dead or count.call("shot_end", "cause", "building") != 1 or absf(sh.y - (top + bolt.r)) > 0.01:
		return "a bolt from above did not stop on the roof (y %s, roof %s)" % [str(sh.y), str(top)]
	clear.call()
	# fired from inside it: it is let out
	a.x = bd.x
	a.y = (base + top) * 0.5 - SimShots.chest
	sh = SimShots.fire(S, 0, "bolt", {"ux": -1.0, "uy": 0.0})
	run.call(1 + int(ceil((bd.w * 0.5 + 100.0) / bolt.speed)))
	if sh.dead or SimWrap.sdx(sh.x, bd.x) < bd.w * 0.5:
		return "a bolt fired from inside a building did not leave it"
	clear.call()
	# a seeking shot is not stopped by it
	a.x = SimWrap.wrap(bd.x - bd.w * 0.5 - 200.0)
	a.y = (base + top) * 0.5 - SimShots.chest
	b.x = SimWrap.wrap(bd.x + bd.w * 0.5 + 200.0)
	b.y = a.y
	sh = SimShots.fire(S, 0, "bolt", {"target": 1})
	run.call(sh.left + 1)
	if count.call("shot_hit", "victim", 1.0) != 1 or count.call("shot_end", "cause", "building") != 0:
		return "a seeking bolt was stopped by a building"
	clear.call()
	SimShots.structures = false
	# ---- the wild deflect
	SimShots.scatter = true
	var D: Dictionary = SimShots.defl
	var sides: Array = [0, 0]
	var fars: int = 0
	for n in range(60):
		a.x = 40000.0; a.y = 3000.0
		b.x = 40900.0; b.y = 3000.0 + float(n % 5) * 200.0
		sh = SimShots.fire(S, 0, "bolt", {"target": 1})
		run.call(4)
		var x0: float = sh.x
		var y0: float = sh.y
		SimShots.deflect(S, sh, 1)
		if sh.owner != 0 or sh.mode != SimShots.LOB or not sh.wild or sh.safe != 1 or sh.tgt != -1 or sh.deflected != 1:
			return "a wild deflect did not make the shot a wild lob of its shooter's"
		var dist: float = absf(SimWrap.sdx(x0, sh.px))
		if dist < D.nearMin - 0.001 or dist > D.farMax + 0.001 or sh.py != maxf(WorldTerrain.groundY(S, sh.px), WorldWater.surfaceAt(S, sh.px)):
			return "a wild shot is bound %s away, to a point off the ground" % str(dist)
		var key: int = sh.id * 16
		var far: bool = SimRng.keyed(int(S.game.seed), "shot.deflect.far", key) < D.farChance
		var u: float = SimRng.keyed(int(S.game.seed), "shot.deflect.dist", key)
		var want: float = (D.farMin + (D.farMax - D.farMin) * u) if far else (D.nearMin + (D.nearMax - D.nearMin) * u)
		if absf(dist - want) > 0.001:
			return "a wild shot's distance is %s, the seeded draw says %s" % [str(dist), str(want)]
		fars += 1 if far else 0
		var wantT: int = maxi(int(D.minTicks), int(ceil(SimDetMath.hypot(dist, sh.py - y0) / (D.speedMul * bolt.speed))))
		var bandArc: float = dist * (D.arcFar if far else D.arcNear)
		if sh.left != wantT or (sh.arc != bandArc and sh.arc != 0.0):
			return "a wild shot flies %d ticks with an arc of %s; %d and %s (or flat) wanted" % [sh.left, str(sh.arc), wantT, str(bandArc)]
		sides[0 if SimWrap.sdx(x0, sh.px) < 0.0 else 1] += 1
		var lx: float = SimWrap.sdx(x0, sh.px)
		var ly: float = sh.py - y0 + 4.0 * sh.arc
		var tx: float = SimWrap.sdx(x0, a.x)
		var ty: float = a.y + SimShots.chest - y0
		var cosv: float = (lx * tx + ly * ty) / (SimDetMath.hypot(lx, ly) * SimDetMath.hypot(tx, ty))
		if cosv > D.backCos + 0.000001:
			return "a wild shot left within 30 degrees of the line back to its shooter (cosine %s)" % str(cosv)
		sh.dead = true
	if sides[0] == 0 or sides[1] == 0 or fars == 0 or fars > 30 or sides[1] <= sides[0]:
		return "60 wild deflects: %d toward the shooter, %d away, %d far" % [sides[0], sides[1], fars]
	if count.call("shot_deflect") != 60:
		return "60 wild deflects sent %d shot_deflect events" % count.call("shot_deflect")
	clear.call()
	# it lands and ends there, hitting nobody who is not in its way: not the deflector it starts on
	a.x = 40000.0; a.y = 3000.0
	b.x = 40900.0; b.y = 3000.0
	sh = SimShots.fire(S, 0, "bolt", {"target": 1})
	run.call(4)
	b.x = sh.x; b.y = sh.y - SimShots.chest
	SimShots.deflect(S, sh, 1)
	var px: float = sh.px
	a.x = SimWrap.wrap(a.x + 80000.0)
	run.call(sh.left + 2)
	if not S.shots.is_empty() or count.call("shot_hit") != 0 or count.call("shot_end", "cause", "ground") + count.call("shot_end", "cause", "water") != 1:
		return "a wild shot did not land (hits %d)" % count.call("shot_hit")
	if absf(SimWrap.sdx(sh.x, px)) > 0.001 and sh.y > WorldTerrain.groundY(S, sh.x) + 0.001 and sh.y > WorldWater.surfaceAt(S, sh.x) + 0.001:
		return "a wild shot ended in the air"
	clear.call()
	# its own shooter, standing where it lands, is hit
	a.x = 40000.0; a.y = 3000.0
	b.x = 40900.0; b.y = 3000.0
	sh = SimShots.fire(S, 0, "bolt", {"target": 1})
	run.call(4)
	SimShots.deflect(S, sh, 1)
	a.x = sh.px
	a.y = sh.py
	var hpA: float = a.hp
	run.call(sh.left + 2)
	if count.call("shot_hit", "victim", 0.0) != 1 or a.hp != hpA - bolt.dmg:
		return "a wild shot did not hit its own shooter in its way"
	clear.call()
	# the deflector is safe for safeTicks, and not after
	a.x = 40000.0; a.y = 3000.0
	b.x = 40900.0; b.y = 3000.0
	sh = SimShots.fire(S, 0, "bolt", {"target": 1})
	run.call(4)
	SimShots.deflect(S, sh, 1)
	var hpB: float = b.hp
	for t in range(int(D.safeTicks) + 3):
		b.x = sh.x; b.y = sh.y - SimShots.chest   # he rides on it
		run.call(1)
		if t < int(D.safeTicks) and (sh.dead or b.hp != hpB):
			return "a wild shot hit its deflector %d ticks after the deflect" % (t + 1)
	if b.hp != hpB - bolt.dmg:
		return "a wild shot never hit its deflector, who stayed in its way past the safe ticks"
	clear.call()
	SimShots.scatter = false
	# ---- the spray
	a.x = 40000.0; a.y = 3000.0
	b.x = 41200.0; b.y = 3500.0
	var lo: float = 9.0
	var hi: float = -9.0
	for n in range(40):
		sh = SimShots.fire(S, 0, "bolt", {"aim": 1, "spread": 0.3})
		var ex: float = SimWrap.sdx(sh.x, b.x)
		var ey: float = b.y + SimShots.chest - sh.y
		# the turn's slope: the cross product over the dot product of the exact aim and the shot's direction
		var sl: float = (ex * sh.vy - ey * sh.vx) / (ex * sh.vx + ey * sh.vy)
		var wantS: float = 0.3 * (SimRng.keyed(int(S.game.seed), "shot.spray", sh.id) * 2.0 - 1.0)
		if sh.mode != SimShots.LINE or absf(sl - wantS) > 0.000001 or absf(sl) > 0.3:
			return "a sprayed bolt is turned by %s, the seeded draw says %s" % [str(sl), str(wantS)]
		if absf(SimDetMath.hypot(sh.vx, sh.vy) - bolt.speed * 60.0) > 0.001:
			return "a sprayed bolt's speed is %s" % str(SimDetMath.hypot(sh.vx, sh.vy))
		lo = minf(lo, sl)
		hi = maxf(hi, sl)
		sh.dead = true
		if n % 20 == 19:
			run.call(1)
	if lo > -0.15 or hi < 0.15:
		return "40 sprayed bolts covered only %s to %s of a cone of 0.3" % [str(lo), str(hi)]
	clear.call()
	sh = SimShots.fire(S, 0, "bolt", {"aim": 1})
	if absf(sh.vx * (b.y + SimShots.chest - sh.y) - sh.vy * SimWrap.sdx(sh.x, b.x)) > 0.001:
		return "an aimed bolt with no spread is not on its target"
	clear.call()
	# a seeking shot with a spread: a small one lands, a wide one passes him and flies on
	for wide in [false, true]:
		var hits: int = 0
		var flew: int = 0
		for n in range(12):
			S.out.fx.clear()
			sh = SimShots.fire(S, 0, "bolt", {"target": 1, "spread": 0.5 if wide else 0.02})
			var offD: float = SimDetMath.hypot(sh.ax, sh.ay)
			var reach: float = bolt.r + SimShots.bodyR
			if absf(sh.ax * SimWrap.sdx(sh.x, b.x) + sh.ay * (b.y + SimShots.chest - sh.y)) > 0.001:
				return "a sprayed seeking bolt's offset is not across its line of fire"
			run.call(sh.left + 1)
			var hitN: int = count.call("shot_hit", "victim", 1.0)
			if (offD <= reach) != (hitN == 1):
				return "a seeking bolt aimed %s beside him (reach %s) made %d hits" % [str(offD), str(reach), hitN]
			hits += hitN
			if hitN == 0:
				if sh.dead or sh.mode != SimShots.LINE:
					return "a sprayed seeking bolt that passed him did not fly on"
				flew += 1
			sh.dead = true
		if (not wide and hits != 12) or (wide and flew == 0):
			return "12 seeking bolts with a %s spread: %d hits, %d flew on" % ["wide" if wide else "small", hits, flew]
	clear.call()
	# ---- mines
	a.x = 40000.0; a.y = 3000.0
	b.x = 90000.0; b.y = 3000.0
	var m = SimShots.fire(S, 0, "mine")
	if m == null or m.mode != SimShots.MINE or m.arm != md.armTicks or m.fuse != -1 or m.left != mk.lifeTicks:
		return "a mine was not laid"
	if SimShots.fire(S, 0, "mine", {"x": a.x + SimShots.mineGap - 1.0}) != null or SimShots.fire(S, 1, "mine", {"x": a.x, "y": m.y + SimShots.mineGap - 1.0}) != null:
		return "a mine was laid within the gap of another"
	var idAfter: int = S.shotSeq
	if idAfter != m.id:
		return "a refused mine used up a shot id"
	var mx0: float = m.x
	var my0: float = m.y
	# not armed yet: the rival beside it does not set it off, and neither does a blow
	b.x = a.x + 20.0; b.y = a.y
	run.call(int(md.armTicks) - 2)
	if m.fuse >= 0 or SimShots.trip(S, m, "blow", 1) or count.call("mine_trip") != 0:
		return "an unarmed mine was set off"
	b.x = 90000.0
	run.call(40)
	if m.dead or m.x != mx0 or m.y != my0 or m.arm != 0 or m.fuse >= 0:
		return "a mine moved, or its owner beside it set it off"
	# the rival comes within the trigger radius: it blows, he takes its damage, its owner beside it takes his share
	S.out.fx.clear()
	hpA = a.hp
	hpB = b.hp
	b.x = a.x + md.trigR + 5.0; b.y = a.y
	run.call(2)
	if m.fuse >= 0:
		return "a mine was set off from beyond its trigger radius"
	b.x = a.x + md.trigR - 5.0
	run.call(1)
	if m.fuse != int(md.fuseBodyTicks) or (md.fuseBodyTicks > 0 and m.dead) or count.call("mine_trip", "kind", "fighter") != 1:
		return "a rival within the trigger radius did not light the body's fuse (fuse %d)" % m.fuse
	run.call(int(md.fuseBodyTicks))
	if not m.dead or count.call("mine_trip", "kind", "fighter") != 1 or count.call("shot_end", "cause", "mine") != 1:
		return "a rival within the trigger radius did not set the mine off"
	if b.hp != hpB - mk.dmg or absf(a.hp - (hpA - mk.dmg * md.ownShare)) > 0.000001:
		return "a mine's blast: the rival lost %s (its damage is %s), its owner %s" % [str(hpB - b.hp), str(mk.dmg), str(hpA - a.hp)]
	clear.call()
	# the cap per fighter: one more fizzles the oldest
	b.x = 90000.0
	var first = null
	for n in range(SimShots.mineCap + 1):
		var q = SimShots.fire(S, 0, "mine", {"x": 40000.0 + 400.0 * n})
		if q == null:
			return "mine %d of the cap was refused" % (n + 1)
		if n == 0:
			first = q
	run.call(1)
	if not first.dead or S.shots.size() != SimShots.mineCap or count.call("shot_end", "cause", "life") != 1:
		return "one mine past the cap did not fizzle the oldest (%d live)" % S.shots.size()
	clear.call()
	# on the ground
	m = SimShots.fire(S, 0, "mine", {"ground": true})
	if m.y != WorldTerrain.groundY(S, m.x) + mk.r or not m.ground:
		return "a ground mine does not rest on the ground"
	clear.call()
	# a shot that hits it sets it off, the rival's or its owner's, and ends there
	for own in [false, true]:
		S.out.fx.clear()
		a.x = 40000.0; a.y = 3000.0
		b.x = 41000.0; b.y = 3000.0
		m = SimShots.fire(S, 0, "mine", {"x": 40500.0})
		run.call(int(md.armTicks) + 1)
		sh = SimShots.fire(S, 0 if own else 1, "bolt", {"ux": 1.0 if own else -1.0, "uy": 0.0})
		run.call(12 + int(md.fuseShotTicks))
		if not m.dead or not sh.dead or count.call("mine_trip", "kind", "shot") != 1 or count.call("shot_end", "cause", "mine") != 1 or count.call("shot_end", "cause", "clash") != 1:
			return "%s bolt did not set the mine off" % ("its owner's" if own else "the rival's")
		clear.call()
	# a chain: two mines within the first one's chain radius follow it, the nearer first, one chain delay apart
	a.x = 80000.0
	b.x = 90000.0
	var g: float = SimShots.mineGap
	if md.chainR < g:
		return "the chain radius is under the gap between mines: no chain can happen"
	var m1 = SimShots.fire(S, 0, "mine", {"x": 40000.0, "y": 3000.0})
	var m2 = SimShots.fire(S, 1, "mine", {"x": 40000.0 + g, "y": 3000.0})
	var m3 = SimShots.fire(S, 0, "mine", {"x": 40000.0 - g * 0.8, "y": 3000.0 - g * 0.6})
	var m4 = SimShots.fire(S, 0, "mine", {"x": 40000.0 + g * 2.0, "y": 3000.0})
	if m1 == null or m2 == null or m3 == null or m4 == null:
		return "the chain's mines were not laid"
	run.call(int(md.armTicks) + 1)
	if not SimShots.trip(S, m1, "blow", 1) or m1.fuse != int(md.fuseBodyTicks):
		return "a blow did not set off an armed mine with the body's fuse"
	var ends: Array = [-1, -1, -1, -1]
	for t in range(int(md.fuseBodyTicks) + 3 * int(md.chainTicks) + 3):
		run.call(1)
		var ms: Array = [m1, m2, m3, m4]
		for n in range(4):
			if ms[n].dead and ends[n] < 0:
				ends[n] = t
	# m2 and m3 are both one gap from m1: the tie goes to the one laid first; m4 is in reach of m2 only
	if ends[0] < 0 or ends[1] - ends[0] != md.chainTicks or ends[2] - ends[0] != 2 * md.chainTicks or ends[3] - ends[1] != md.chainTicks:
		return "the chain blew at ticks %s, a chain delay is %d" % [str(ends), md.chainTicks]
	if count.call("mine_trip", "kind", "chain") != 3 or count.call("shot_end", "cause", "mine") != 4:
		return "the chain sent %d chain events and %d blasts" % [count.call("mine_trip", "kind", "chain"), count.call("shot_end", "cause", "mine")]
	clear.call()
	# the chain's reach is the same at every tier: at tier 4 a mine just past chainR does not follow
	var tier0: float = a.tier
	a.tier = 4.0
	var c1 = SimShots.fire(S, 0, "mine", {"x": 40000.0, "y": 3000.0})
	var c2 = SimShots.fire(S, 0, "mine", {"x": 40000.0 + md.chainR + 10.0, "y": 3000.0})
	run.call(int(md.armTicks) + 1)
	SimShots.trip(S, c1, "shot", 1)
	if c1.fuse != int(md.fuseShotTicks):
		return "a shot did not light the shot's fuse"
	run.call(int(md.fuseShotTicks) + 2 * int(md.chainTicks) + 2)
	if not c1.dead or c2.dead or c2.fuse >= 0:
		return "at tier 4 a mine past chainR followed the chain"
	a.tier = tier0
	clear.call()
	# its life: it fizzles, and hurts nobody
	m = SimShots.fire(S, 0, "mine", {"x": 40000.0, "y": 3000.0})
	b.x = 40000.0 + md.blastR - 10.0; b.y = 3000.0 - SimShots.chest
	hpB = b.hp
	b.state = "intro"   # (he cannot set it off)
	run.call(int(mk.lifeTicks) + 1)
	b.state = "free"
	if not S.shots.is_empty() or count.call("shot_end", "cause", "life") != 1 or b.hp != hpB:
		return "a mine did not fizzle at the end of its life"
	# mines count toward the cap
	clear.call()
	var made: int = 0
	for n in range(SimShots.cap):
		if SimShots.fire(S, 0, "bolt", {"ux": 1.0, "uy": 0.0}) != null:
			made += 1
	if made != SimShots.cap or SimShots.fire(S, 1, "mine", {"x": 60000.0}) != null:
		return "a mine was laid past the cap on live shots"
	clear.call()
	SimCore.dispose(S)
	return ""


func _agencyLines() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"assists": [["autoCharge"], []]})
	var a = S.fighters[0]
	var b = S.fighters[1]
	if not SimAct.assisted(a, "autoCharge") or SimAct.assisted(b, "autoCharge") or SimAct.assisted(a, "autoBurst"):
		return "the autoCharge assist did not reach its slot alone"
	if a.act.flow != 0 or a.embedT != 0 or a.embedCool > -1.0e8:
		return "the flow count or the embed fields do not start clear"
	S.out.fx.clear()
	SimAct.setFlow(S, a, 3)
	SimAct.setFlow(S, a, 3)
	SimAct.setFlow(S, a, 0)
	var flows: Array = []
	for e in S.out.fx:
		if e.type == "flow" and int(e.actor) == 0:
			flows.append(int(e.n))
	if flows != [3, 0] or a.act.flow != 0:
		return "setFlow sent %s, not [3, 0]" % str(flows)
	S.out.fx.clear()
	SimFx.knockback(S, b, a, "long slide", 450.0, S.tick + 30)
	SimFx.exchangeEnd(S, a, "knockback")
	SimFx.embed(S, b, b.x, 12.0, 130.0, 300.0, 4.0, 1.5, 7)
	var k = S.out.fx[0]
	var x = S.out.fx[1]
	var m = S.out.fx[2]
	if k.type != "knockback" or int(k.victim) != 1 or int(k.attacker) != 0 or k.kind != "long slide" or k.amount != 450.0 or k.dur != 0.5 or k.n != S.tick + 30:
		return "the knockback event's fields"
	if x.type != "exchange_end" or int(x.actor) != 0 or x.kind != "knockback":
		return "the exchange_end event's fields"
	if m.type != "embed" or int(m.actor) != 1 or m.y != 12.0 or m.depth != 130.0 or m.r != 300.0 or m.energy != 4.0 or m.dur != 1.5 or m.n != 7:
		return "the embed event's fields"
	SimCore.dispose(S)
	return ""


## Shots (sim/core/shots.gd): none in a default match; a straight shot's speed, its life, the ground, and the seam; a
## seeking shot arriving on its tick at a moving target, near and far, with its damage; the fire tick's rest; trades in
## pairs with the rest landing, and a charged shot eating bolts; a deflect; the cap; a lob's arc and landing.
func _shots() -> String:
	if not SimShots.errors().is_empty():
		return "; ".join(SimShots.errors())
	# no shot comes from nowhere: a match in which nobody presses (two human slots, no input) never has one, and a new
	# match starts with none and its count at zero whatever the last one left (the AI does fire in a default match)
	var D := SimCore.createSim()
	SimCore.newMatch(D, 5, {"p1": false, "p2": false})
	for t in range(600):
		SimCore.step(D)
		D.out.fx.clear()
		D.out.feed.clear()
		if not D.shots.is_empty() or D.shotSeq != 0:
			return "a match in which nobody presses has a shot in flight"
	if SimShots.fire(D, 0, "bolt", {"ux": 1.0, "uy": 0.0}) == null or D.shots.size() != 1 or D.shotSeq != 1:
		return "a bolt could not be fired into the quiet match"
	SimCore.newMatch(D, 6, {"p1": false, "p2": false})
	if not D.shots.is_empty() or D.shotSeq != 0:
		return "a new match kept the last one's shots"
	SimCore.dispose(D)
	var dt: float = SimConst.DT
	var bolt: Dictionary = SimShots.kinds.bolt
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var a = S.fighters[0]
	var b = S.fighters[1]
	var count := func(type: String, key: String = "", val = null) -> int:
		var c: int = 0
		for e in S.out.fx:
			if e.type == type and (key == "" or e.get(key) == val):
				c += 1
		return c
	var run := func(ticks: int) -> void:
		for t in range(ticks):
			SimShots.step(S, dt)
	# a straight shot: the fire tick's rest, the speed, the life
	a.x = 40000.0; a.y = 3000.0
	b.x = 70000.0; b.y = 9000.0
	var sh = SimShots.fire(S, 0, "bolt", {"ux": 1.0, "uy": 0.0})
	if sh == null or sh.id != 1 or count.call("shot_fire") != 1:
		return "fire did not make shot 1"
	var x0: float = sh.x
	run.call(1)
	if sh.x != x0:
		return "a shot moved on its fire tick"
	run.call(10)
	if absf(SimWrap.sdx(x0, sh.x) - 10.0 * bolt.speed) > 0.001 or sh.y != a.y + SimShots.chest:
		return "a straight bolt moved %s in 10 ticks, not %s" % [str(SimWrap.sdx(x0, sh.x)), str(10.0 * bolt.speed)]
	run.call(int(bolt.lifeTicks))
	if not S.shots.is_empty() or count.call("shot_end", "cause", "life") != 1:
		return "a straight bolt did not end with its life"
	# the seam
	S.out.fx.clear()
	a.x = SimConst.W - 100.0
	sh = SimShots.fire(S, 0, "bolt", {"ux": 1.0, "uy": 0.0})
	run.call(4)
	if absf(sh.x - (3.0 * bolt.speed - 100.0)) > 0.001:
		return "a bolt across the seam is at %s" % str(sh.x)
	SimShots.end(S, sh, "test")
	run.call(1)
	# the ground stops a straight shot
	S.out.fx.clear()
	a.x = 40000.0
	a.y = WorldTerrain.groundY(S, a.x) + 200.0
	sh = SimShots.fire(S, 0, "bolt", {"ux": 0.3, "uy": -1.0})
	run.call(30)
	if not S.shots.is_empty() or count.call("shot_end", "cause", "ground") != 1:
		return "a bolt fired at the ground did not end on it"
	# a seeking shot: near (the speed sets the time) and far (arriveTicks does), at a target that moves
	for far in [false, true]:
		S.out.fx.clear()
		a.y = 3000.0
		b.x = SimWrap.wrap(a.x + (30000.0 if far else 600.0))
		b.y = 3200.0
		var hp0: float = b.hp
		sh = SimShots.fire(S, 0, "bolt", {"target": 1})
		var want: int = mini(SimShots.arriveTicks, int(ceil(SimDetMath.hypot(SimWrap.sdx(a.x, b.x), b.y - a.y) / bolt.speed)))
		if (far and want != SimShots.arriveTicks) or (not far and want >= SimShots.arriveTicks):
			return "the seeking test's distances no longer straddle arriveTicks"
		if sh.left != want:
			return "a seeking bolt %s away takes %d ticks, not %d" % ["far" if far else "600", sh.left, want]
		run.call(1)
		for t in range(want):
			if S.shots.is_empty():
				return "a seeking bolt ended %d ticks early" % (want - t)
			b.x = SimWrap.wrap(b.x + 150.0)
			b.y += 20.0
			run.call(1)
		if not S.shots.is_empty() or count.call("shot_hit", "victim", 1.0) != 1 or b.hp != hp0 - bolt.dmg:
			return "a seeking bolt did not land on its tick (hits %d, hp %s to %s)" % [count.call("shot_hit"), str(hp0), str(b.hp)]
	# trades: three bolts against two cancel in pairs and one lands; a charged shot eats two bolts and lands
	for charged in [false, true]:
		S.out.fx.clear()
		a.x = 40000.0; a.y = 3000.0
		b.x = 42400.0; b.y = 3000.0
		var hpA: float = a.hp
		var hpB: float = b.hp
		if charged:
			SimShots.fire(S, 0, "charged", {"target": 1})
		else:
			for n in range(3):
				SimShots.fire(S, 0, "bolt", {"target": 1, "group": 7})
		for n in range(2):
			SimShots.fire(S, 1, "bolt", {"target": 0})
		run.call(60)
		var hitsB: int = count.call("shot_hit", "victim", 1.0)
		if not S.shots.is_empty() or count.call("shot_clash") != 2 or hitsB != 1 or a.hp != hpA or b.hp >= hpB:
			return "%s against two bolts: %d clashes, %d hits on the defender, attacker hp %s to %s" % ["a charged shot" if charged else "three bolts", count.call("shot_clash"), hitsB, str(hpA), str(a.hp)]
	# a deflect sends it back to its owner
	S.out.fx.clear()
	var hpA2: float = a.hp
	sh = SimShots.fire(S, 0, "bolt", {"target": 1})
	run.call(5)
	SimShots.deflect(S, sh, 1)
	if sh.owner != 1 or sh.tgt != 0 or sh.deflected != 1:
		return "a deflect did not turn the shot"
	run.call(60)
	if count.call("shot_hit", "victim", 0.0) != 1 or a.hp != hpA2 - bolt.dmg:
		return "a deflected bolt did not land on its old owner"
	# a seeking shot that cannot hit its target flies on as a straight shot, and then the ground stops it
	S.out.fx.clear()
	a.x = 40000.0
	a.y = WorldTerrain.groundY(S, a.x) + 400.0
	b.x = a.x + 600.0
	b.y = WorldTerrain.groundY(S, b.x)
	b.state = "intro"   # he cannot be hit
	sh = SimShots.fire(S, 0, "bolt", {"target": 1})
	var n0: int = sh.left
	run.call(n0 + 1)
	if S.shots.is_empty() or sh.mode != SimShots.LINE or sh.tgt != -1 or sh.vy >= 0.0:
		return "a seeking bolt that could not hit did not fly on as a straight shot"
	run.call(int(bolt.lifeTicks))
	if not S.shots.is_empty() or count.call("shot_end", "cause", "ground") != 1 or count.call("shot_hit") != 0:
		return "a released bolt did not end on the ground"
	b.state = "free"
	sh = SimShots.fire(S, 0, "bolt", {"target": 1})
	SimShots.release(S, sh)
	if sh.mode != SimShots.LINE or sh.vx == 0.0:
		return "release before the first move left the shot still"
	SimShots.end(S, sh, "test")
	run.call(1)
	a.y = 3000.0
	b.y = 3000.0
	# the cap
	b.x = SimWrap.wrap(a.x + 60000.0)
	var made: int = 0
	for n in range(SimShots.cap + 5):
		if SimShots.fire(S, 0, "bolt", {"target": 1}) != null:
			made += 1
	if made != SimShots.cap or S.shots.size() != SimShots.cap:
		return "the cap let %d shots fly, not %d" % [made, SimShots.cap]
	for q in S.shots:
		SimShots.end(S, q, "test")
	run.call(1)
	# a lob: up, over, and down on its point
	S.out.fx.clear()
	a.y = WorldTerrain.groundY(S, a.x) + 100.0
	var lobk: Dictionary = SimShots.kinds.lob
	sh = SimShots.fire(S, 0, "lob", {"px": a.x + 900.0, "py": WorldTerrain.groundY(S, a.x + 900.0)})
	var top: float = sh.y
	run.call(1)
	for t in range(int(lobk.lobTicks)):
		if S.shots.is_empty():
			return "a lob ended %d ticks early" % (int(lobk.lobTicks) - t)
		top = maxf(top, sh.y)
		run.call(1)
	if not S.shots.is_empty() or count.call("shot_end", "cause", "ground") != 1 or top < a.y + SimShots.chest + lobk.lobArc * 0.5:
		return "a lob did not arc and land (top %s)" % str(top)
	SimCore.dispose(S)
	return ""


## The last stand (sim/core/fighter.gd): the window opens at a fighter's first brink and not at a second; it counts only
## while he is free and not stunned; it runs out with last_stand_end expired; a use closes it; with the data's window at
## 0 nothing opens. When the director's gates are in (they read sigFree), a free signature starts with no ki and inside
## the cooldown, costs nothing and closes the window.
func _lastStand() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false})
	var a = S.fighters[0]
	var n: int = a.wd.lastStandTicks
	var core: int = SimWounds.CORE
	var toBrink := func() -> void:
		a.wear[core] = SimWounds.STAGE_AT[2]
		SimWounds.updateStages(S, a)
	var count := func(type: String, kind: String) -> int:
		var c: int = 0
		for e in S.out.fx:
			if e.type == type and (kind == "" or e.kind == kind) and int(e.actor) == 0:
				c += 1
		return c
	toBrink.call()
	if not a.brink:
		return "the forced brink did not take"
	if n <= 0:
		SimCore.dispose(S)
		return "" if (a.lastStandLeft == 0 and count.call("last_stand_ready", "") == 0) else "with the window at 0 a last stand opened"
	if not a.lastStandUsed or a.lastStandLeft != n or count.call("last_stand_ready", "") != 1 or not SimFighter.sigFree(a):
		return "the first brink did not open the last stand (left %d of %d)" % [a.lastStandLeft, n]
	# it counts only while he is free and not stunned
	a.state = "locked"
	for t in range(10):
		SimFighter.stepFighter(S, a, SimConst.DT)
	a.state = "free"
	a.stunTicks = 100
	for t in range(10):
		SimFighter.stepFighter(S, a, SimConst.DT)
	if a.lastStandLeft != n:
		return "the window ran while he was locked or stunned (%d of %d)" % [a.lastStandLeft, n]
	a.stunTicks = 0
	for t in range(10):
		SimFighter.stepFighter(S, a, SimConst.DT)
	if a.lastStandLeft != n - 10:
		return "the window did not count his free ticks (%d, wants %d)" % [a.lastStandLeft, n - 10]
	# a use closes it
	S.out.fx.clear()
	SimFighter.lastStandUse(S, a)
	if a.lastStandLeft != 0 or SimFighter.sigFree(a) or count.call("last_stand_end", "used") != 1:
		return "a use did not close the window"
	# a second brink gives nothing
	a.wear[core] = 0
	SimWounds.updateStages(S, a)
	S.out.fx.clear()
	toBrink.call()
	if a.lastStandLeft != 0 or count.call("last_stand_ready", "") != 0:
		return "a second brink opened a second last stand"
	# it runs out
	var b = S.fighters[1]
	b.wear[core] = SimWounds.STAGE_AT[2]
	SimWounds.updateStages(S, b)
	b.lastStandLeft = 2
	b.state = "free"
	b.stunTicks = 0
	S.out.fx.clear()
	SimFighter.stepFighter(S, b, SimConst.DT)
	SimFighter.stepFighter(S, b, SimConst.DT)
	var expired: int = 0
	for e in S.out.fx:
		if e.type == "last_stand_end" and e.kind == "expired" and int(e.actor) == 1:
			expired += 1
	if b.lastStandLeft != 0 or expired != 1:
		return "the window did not run out with one last_stand_end (left %d, %d events)" % [b.lastStandLeft, expired]
	SimCore.dispose(S)
	return _lastStandGates()


## The director's side of the last stand; "" until its gates are in.
func _lastStandGates() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false})
	var a = S.fighters[0]
	if a.wd.lastStandTicks <= 0:
		SimCore.dispose(S)
		return ""
	S.dirS.cool = 0.0
	a.ki = 0.0
	a.sigReadyT = S.T + 100.0
	a.input.stanceMask = 4   # a stance held: with three strengths B alone is the heavy
	DirExchange.requestAttack(S, a, "sig")
	if S.dirS.ex != null:
		return "a signature with no ki, inside the cooldown, started without a last stand"
	a.lastStandUsed = true
	a.lastStandLeft = 600
	S.out.fx.clear()
	DirExchange.requestAttack(S, a, "sig")
	var used: int = 0
	for e in S.out.fx:
		if e.type == "last_stand_end" and e.kind == "used":
			used += 1
	if S.dirS.ex == null or S.dirS.ex.kind != "sig" or a.ki != 0.0 or a.lastStandLeft != 0 or used != 1:
		return "the free signature: exchange %s, ki %s, window %d, %d used events" % [str(S.dirS.ex != null), str(a.ki), a.lastStandLeft, used]
	if a.sigReadyT <= S.T:
		return "the free signature did not start the ordinary cooldown"
	SimCore.dispose(S)
	return ""


## The intro phase (sim/core/intro.gd): off unless the setup asks; with it, the timeline's events on their ticks, every
## tick pre-clock (step false, S.T at 0), the falls going down, both craters dug, both fighters free on the ground at the
## clock; a press before skipFrom ignored and one after it skipping; the state at the clock the same whether the intro
## ran, was skipped at any tick, or was applied by the setup's "skip"; AI slots never skipping; a replay through a skip.
func _intro() -> String:
	if not SimIntro.errors().is_empty():
		return "; ".join(SimIntro.errors())
	var D := SimCore.createSim()
	SimCore.newMatch(D, 5)
	if D.intro.left != 0 or D.craters.size() != 2 or not SimCore.step(D, null):
		return "a match whose setup does not say did not start from the intro's end state"
	SimCore.newMatch(D, 5, {}, {"intro": false})
	if D.intro.left != 0 or D.craters.size() != 0 or D.fighters[0].y != 60.0:
		return "intro false did not give the flat start"
	SimCore.dispose(D)
	var quiet := SimIntent.new()
	var press := SimIntent.new()
	press.light = true
	var clockState := func(S0: SimState) -> String:   # the state at the clock, without the tick counters and the intro's own record
		S0.tick = 0
		S0.intro.t = 0
		S0.intro.scenario = -1
		S0.intro.first = 0
		S0.intro.gap = 0
		S0.intro.picks = 0
		S0.intro.clock = 0
		return SimHash.stateHash(S0).gameplay
	# the full intro, two human slots that press nothing
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": true})
	var a = S.fighters[0]
	var b = S.fighters[1]
	if a.state != "intro" or S.intro.left != SimIntro.clock or a.y != WorldTerrain.groundY(S, a.x) + SimIntro.fallHeight:
		return "the intro did not start (state %s, left %d)" % [a.state, S.intro.left]
	var at := {}
	var lastY: Array = [a.y, b.y]
	var cool0: float = S.dirS.cool
	var marks: int = 0
	for t in range(SimIntro.clock):
		S.out.fx.clear()
		if SimCore.step(S, [quiet, quiet]):
			return "pre-clock tick %d was live" % t
		if S.T != 0.0 or S.mood.t != 0 or S.pause.bank != SimPause.bankStart or S.dirS.cool != cool0:
			return "the clock, the mood, the pause bank or the director's cooldown moved during the intro"
		for e in S.out.fx:
			if e.type == "tick" and not e.frozen:
				marks += 1   # an intro tick is live for effects (dust settles at full speed), though the sim holds
			if e.type in ["intro_start", "entrance_fall", "entrance_land", "staredown_start", "clock_start"]:
				at["%s%s" % [e.type, ("" if e.actor < 0.0 or e.type == "intro_start" else str(int(e.actor)))]] = t
		for k in range(2):
			if S.fighters[k].y > lastY[k]:
				return "slot %d rose during his fall" % k
			lastY[k] = S.fighters[k].y
	if marks != SimIntro.clock:
		return "%d of the intro's %d ticks were marked live for effects" % [marks, SimIntro.clock]
	var want := {"intro_start": 0, "entrance_fall0": SimIntro.fall[0], "entrance_land0": SimIntro.land[0], "entrance_fall1": SimIntro.fall[1],
		"entrance_land1": SimIntro.land[1], "staredown_start": SimIntro.staredown, "clock_start": SimIntro.clock - 1}
	for k in want:
		if at.get(k, -1) != want[k]:
			return "%s came at tick %s, not %d" % [k, str(at.get(k, "never")), want[k]]
	if a.state != "free" or b.state != "free" or a.y != WorldTerrain.groundY(S, a.x) or S.craters.size() != 2 or S.intro.left != 0:
		return "at the clock: states %s and %s, %d craters" % [a.state, b.state, S.craters.size()]
	var full: String = clockState.call(S)
	if not SimCore.step(S, [quiet, quiet]) or S.T <= 0.0:
		return "the tick after the clock was not live"
	SimCore.dispose(S)
	# a press too early is ignored; a press later skips, from any point, to the same state
	for at_tick in [SimIntro.skipFrom, SimIntro.land[0] + 3, SimIntro.land[1] + 3, SimIntro.clock - 1]:
		var K := SimCore.createSim()
		SimCore.newMatch(K, 5, {"p1": false, "p2": false}, {"intro": true})
		for t in range(at_tick):
			SimCore.step(K, [press if t < SimIntro.skipFrom else quiet, quiet])
		if K.intro.left != SimIntro.clock - at_tick:
			return "a press before skipFrom skipped the intro"
		K.out.fx.clear()
		if SimCore.step(K, [quiet, press]) or K.intro.left != 0:
			return "a press at tick %d did not skip" % at_tick
		var kind: String = ""
		for e in K.out.fx:
			if e.type == "clock_start":
				kind = e.kind
		if kind != "skip":
			return "a skip's clock_start kind is '%s'" % kind
		if clockState.call(K) != full:
			return "a skip at tick %d left another state at the clock than the full intro" % at_tick
		SimCore.dispose(K)
	var Q := SimCore.createSim()
	SimCore.newMatch(Q, 5, {"p1": false, "p2": false}, {"intro": "skip"})
	if Q.intro.left != 0 or not Q.out.fx.is_empty() or clockState.call(Q) != full:
		return "the setup's skip did not give the state at the clock"
	SimCore.dispose(Q)
	# AI slots never skip
	var A := SimCore.createSim()
	SimCore.newMatch(A, 5, {}, {"intro": true})
	for t in range(SimIntro.clock - 1):
		SimCore.step(A, [press, press])
	if A.intro.left != 1:
		return "an AI slot's intent skipped the intro"
	SimCore.dispose(A)
	# a replay through a skip
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 9, {"p1": false, "p2": true}, {"intro": true})
	for t in range(400):
		rec.step([press if t == SimIntro.skipFrom + 5 else quiet, null])
		R.out.fx.clear()
		R.out.feed.clear()
	if R.intro.t != SimIntro.skipFrom + 6:
		return "the recorded match did not skip where it pressed (%d)" % R.intro.t
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	var res: Dictionary = SimReplay.play(JSON.parse_string(JSON.stringify(rp)))
	return "" if res.ok else "a replay through a skipped intro: %s at tick %d" % [res.reason, res.firstBadTick]


## Composed intros (docs/architecture/intro-phase.md): every template, with either fighter first, at its shortest, default
## and longest gap, plays its beats on their ticks and ends in the state the setup's skip gives, and so does a skip press
## at any point; the first to arrive waits where a template says so; the composer's draws are keyed (the same seed and
## record give the same intro) and follow the weights, the no-repeat list and the tones; a replay with a record composes
## the same intro.
func _introComposed() -> String:
	if not SimIntro.errors().is_empty():
		return "; ".join(SimIntro.errors())
	var quiet := SimIntent.new()
	var press := SimIntent.new()
	press.light = true
	var clockState := func(S0: SimState) -> String:   # the state at the clock, without the tick counters and the intro's own record
		S0.tick = 0
		S0.intro.t = 0
		S0.intro.scenario = -1
		S0.intro.first = 0
		S0.intro.gap = 0
		S0.intro.picks = 0
		S0.intro.clock = 0
		return SimHash.stateHash(S0).gameplay
	var Q := SimCore.createSim()
	SimCore.newMatch(Q, 5, {"p1": false, "p2": false}, {"intro": "skip"})
	var want: String = clockState.call(Q)
	SimCore.dispose(Q)
	var T: Array = SimIntro.templates
	var waits: int = 0
	var lines: int = 0
	for ti in range(T.size()):
		var tp: Dictionary = T[ti]
		var gaps: Array = [tp.gapMin]
		for g in [tp.gapDef, tp.gapMax]:
			if not gaps.has(g):
				gaps.append(g)
		for first in [0, 1]:
			for gap in gaps:
				var label: String = "%s, slot %d first, gap %d" % [tp.id, first, gap]
				var rec := {"play": true, "scenario": tp.id, "order": first, "gap": gap, "facts": {}}   # (no facts at all: the template's own beats)
				var S := SimCore.createSim()
				SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": rec})
				var tl: Dictionary = SimIntro.flatten(ti, gap, S.intro.picks)
				if S.intro.scenario != ti or S.intro.first != first or S.intro.gap != gap or S.intro.left != tp.clock or S.intro.clock != tp.clock or S.fighters[0].state != "intro":
					return label + ": the match did not start as the record asked"
				var view: Dictionary = SimIntro.timeline(S)
				var exp: Array = ["0 intro_start %d %s" % [first, tp.id], "%d clock_start -1 full" % (tp.clock - 1)]
				for b in view.beats:
					if b.kind == "fall":
						exp.append("%d entrance_fall %d " % [b.t, b.actor])
					elif b.kind == "land":
						exp.append("%d entrance_land %d " % [b.t, b.actor])
					elif b.kind == "wait":
						exp.append("%d intro_beat %d wait" % [b.t, b.actor])
						waits += 1
					elif b.kind == "line":
						exp.append("%d intro_line %d %s" % [b.t, b.actor, b.intent])
						lines += 1
					else:
						exp.append("%d staredown_start -1 " % b.t)
				var seen: Array = []
				var waitFrom: int = -1
				for t in range(tp.clock):
					S.out.fx.clear()
					if SimCore.step(S, [quiet, quiet]) or S.T != 0.0:
						return label + ": pre-clock tick %d was live" % t
					for e in S.out.fx:
						if e.type in ["intro_start", "entrance_fall", "entrance_land", "intro_beat", "intro_line", "staredown_start", "clock_start"]:
							seen.append("%d %s %d %s" % [t, e.type, int(e.actor), e.kind])
						if e.type == "entrance_fall" and e.mode != "drop":
							return label + ": a fall's mode is '%s'" % e.mode
						if e.type == "intro_line" and e.variant != ("first" if int(e.actor) == first else "second"):
							return label + ": a line's role is '%s'" % e.variant
						if e.type == "intro_start" and (int(e.n) != gap or absf(e.dur - float(tp.clock) / 60.0) > 0.000001):
							return label + ": intro_start says a gap of %d and %s seconds" % [int(e.n), str(e.dur)]
					for k in range(2):
						if S.fighters[k].state == "waiting":
							if k != first or t >= tl.staredown or t < tl.land[0]:
								return label + ": slot %d is waiting at tick %d" % [k, t]
							if waitFrom < 0:
								waitFrom = t
				exp.sort()
				seen.sort()
				if exp != seen:
					return label + ": the events were %s, the timeline says %s" % [str(seen), str(exp)]
				var hasWait: bool = false
				for b in view.beats:
					hasWait = hasWait or b.kind == "wait"
				if hasWait != (waitFrom >= 0):
					return label + ": the first to arrive %s" % ("never waited" if hasWait else "waited with no wait beat")
				if S.intro.left != 0 or S.fighters[0].state != "free" or S.fighters[1].state != "free" or S.craters.size() != 2:
					return label + ": at the clock the states are %s and %s, with %d craters" % [S.fighters[0].state, S.fighters[1].state, S.craters.size()]
				if clockState.call(S) != want:
					return label + ": the state at the clock is not the one the setup's skip gives"
				if not SimCore.step(S, [quiet, quiet]) or S.T <= 0.0:
					return label + ": the tick after the clock was not live"
				SimCore.dispose(S)
				# a skip press, from four points
				for at_tick in [SimIntro.skipFrom, tl.land[0] + 2, tl.land[1] - 1, tp.clock - 1]:
					var K := SimCore.createSim()
					SimCore.newMatch(K, 5, {"p1": false, "p2": false}, {"intro": rec})
					for t in range(at_tick):
						SimCore.step(K, [quiet, quiet])
					if SimCore.step(K, [quiet, press]) or K.intro.left != 0:
						return label + ": a press at tick %d did not skip" % at_tick
					if clockState.call(K) != want:
						return label + ": a skip at tick %d left another state at the clock" % at_tick
					SimCore.dispose(K)
	if waits == 0 or lines == 0:
		return "no template has a wait beat, or none has a line (%d, %d)" % [waits, lines]
	var bent: String = _introFacts(want, clockState)
	if bent != "":
		return bent
	# the composer's draws
	var C := SimCore.createSim()
	SimCore.newMatch(C, 5, {"p1": false, "p2": false}, {"intro": "skip"})
	var left: int = SimIntro.leftSlot(C)
	var N: int = 600
	var by: Array = []
	by.resize(T.size())
	by.fill(0)
	var firsts: Array = [0, 0]
	var gapsSeen := {}
	var notLast: int = 0
	var lessOften: int = 0
	var grave: int = -1
	var heavy: int = 0   # the template with the most weight
	for i in range(T.size()):
		if T[i].notTwice:
			grave = i
		if T[i].weight > T[heavy].weight:
			heavy = i
	for s in range(1, N + 1):
		C.game.seed = s
		var c: Dictionary = DirIntro.compose(C, {"play": true})
		var c2: Dictionary = DirIntro.compose(C, {"play": true})
		if c.scenario != c2.scenario or c.first != c2.first or c.gap != c2.gap or c.picks != c2.picks:
			return "the same seed composed two different intros"
		var tp: Dictionary = T[c.scenario]
		if c.gap < tp.gapMin or c.gap > tp.gapMax or (c.first != 0 and c.first != 1) or SimIntro.flatten(c.scenario, c.gap, c.picks).why != "":
			return "seed %d composed an intro outside its template (%s, gap %d)" % [s, tp.id, c.gap]
		by[c.scenario] += 1
		firsts[c.first] += 1
		gapsSeen["%d:%d" % [c.scenario, c.gap]] = true
		if grave >= 0 and DirIntro.compose(C, {"play": true, "avoid": [T[grave].id, T[heavy].id]}).scenario == grave:
			notLast += 1
		if DirIntro.compose(C, {"play": true, "avoid": [T[heavy].id, T[heavy].id, T[heavy].id]}).scenario == heavy:
			lessOften += 1
		for forced in [{"play": true, "facts": {"tones": [T[heavy].tone]}}, {"play": true, "scenario": T[T.size() - 1].id, "order": 1 - left, "gap": 99999}, {"classic": true}, {"play": true, "facts": {"tones": ["no such tone"]}}]:
			var f: Dictionary = DirIntro.compose(C, forced)
			var ok: bool
			if forced.has("scenario"):
				ok = f.scenario == T.size() - 1 and f.first == 1 - left and f.gap == T[T.size() - 1].gapMax
			elif forced.has("classic"):
				ok = f.scenario == SimIntro.classicI and f.first == left and f.gap == T[SimIntro.classicI].gapDef
			elif forced.facts.tones[0] == "no such tone":
				ok = f.scenario == SimIntro.classicI
			else:
				ok = T[f.scenario].tone == T[heavy].tone
			if not ok or f.notes.is_empty():
				return "seed %d: the record %s composed %s" % [s, str(forced), str(f)]
	var total: float = 0.0
	for i in range(T.size()):
		total += T[i].weight
	for i in range(T.size()):
		var share: float = float(by[i]) / float(N)
		var wshare: float = T[i].weight / total
		if absf(share - wshare) > 0.07:
			return "%s was drawn %d times in %d, its weight says %s" % [T[i].id, by[i], N, str(wshare)]
	if firsts[0] < N * 2 / 5 or firsts[1] < N * 2 / 5:
		return "who arrives first: slot 0 %d times, slot 1 %d times in %d" % [firsts[0], firsts[1], N]
	if gapsSeen.size() < 40:
		return "only %d different template and gap pairs in %d seeds" % [gapsSeen.size(), N]
	if notLast != 0:
		return "a template marked notTwice was drawn right after itself %d times" % notLast
	if lessOften >= by[heavy]:
		return "a template played three times lately was drawn as often as before (%d against %d)" % [lessOften, by[heavy]]
	SimCore.dispose(C)
	# a replay carries the record and composes the same intro, played through and skipped
	for skipAt in [-1, SimIntro.skipFrom + 20]:
		var R := SimCore.createSim()
		var setup := {"intro": {"play": true, "avoid": [T[heavy].id], "take": 2, "facts": {"tones": ["light", "neutral", "grave"]}}}
		var rec2 := SimReplay.recorder(R, 11, {"p1": false, "p2": true}, setup)
		var sc: int = R.intro.scenario
		var fed: bool = false
		for t in range(700):
			rec2.step([press if t == skipAt else quiet, null])
			for line in R.out.feed:
				fed = fed or String(line.tag).begins_with("INTRO: ")
			R.out.fx.clear()
			R.out.feed.clear()
		if not fed:
			return "the composer's reasons did not reach the feed"
		if R.intro.left != 0 or (skipAt >= 0 and R.intro.t != skipAt + 1):
			return "the recorded match's intro did not end where it should (t %d)" % R.intro.t
		var rp: Dictionary = rec2.finish()
		SimCore.dispose(R)
		var back = JSON.parse_string(JSON.stringify(rp))
		if not (back.setup.intro is Dictionary) or back.setup.intro.avoid[0] != T[heavy].id or int(back.setup.intro.take) != 2:
			return "the replay's header lost the intro record"
		var res: Dictionary = SimReplay.play(back)
		if not res.ok:
			return "a replay of a composed intro (%s): %s at tick %d" % [T[sc].id, res.reason, res.firstBadTick]
	return ""


## A composed intro whose record sends no facts takes the data's default (intro.json defaultFacts, a first meeting): its
## gestures and voice tags play. A record with facts of its own, even an empty set, and the classic opening take none of
## it. The take (the host's rematch counter) is the index of the composer's draws: none is take 0, a take composes the
## same intro every time, what the record fixes stays fixed, and over six takes a seed composes different openings.
func _introDefault() -> String:
	if not SimIntro.errors().is_empty():
		return "; ".join(SimIntro.errors())
	var D: Dictionary = SimIntro.defaultFacts
	if D.is_empty() or not (D.get("gestures") is Array) or D.gestures.is_empty() or not (D.get("intents") is Dictionary) or D.intents.is_empty():
		return "intro.json has no defaultFacts with a gesture and a voice slot's tags"
	var quiet := SimIntent.new()
	var press := SimIntent.new()
	press.light = true
	var T: Array = SimIntro.templates
	var tagged: int = 0
	var recs: Array = [["the classic opening", {"classic": true}, false]]
	for tp in T:
		recs.append([tp.id + " with no facts", {"play": true, "scenario": tp.id}, true])
		recs.append([tp.id + " with an empty set of facts", {"play": true, "scenario": tp.id, "facts": {}}, false])
	for r in recs:
		var label: String = r[0]
		var S := SimCore.createSim()
		SimCore.newMatch(S, 9, {"p1": false, "p2": false}, {"intro": r[1]})
		var it = S.intro
		var left: int = SimIntro.leftSlot(S)
		var want: Array = []
		if r[2]:
			var rec2: Dictionary = r[1].duplicate()
			rec2["facts"] = D
			want = DirIntro.compose(S, rec2).gestures
			if want.is_empty():
				return label + ": the default facts give this template no gesture"
		if it.gestures != want or (it.facts != D if r[2] else not it.facts.is_empty()):
			return label + ": the match holds %d gestures, and %d were expected" % [it.gestures.size(), want.size()]
		var got: Array = []
		var fed: bool = false
		for t in range(it.clock):
			S.out.fx.clear()
			S.out.feed.clear()
			if SimCore.step(S, [quiet, quiet]):
				return label + ": pre-clock tick %d was live" % t
			for line in S.out.feed:
				fed = fed or String(line.tag) == "INTRO facts: the default"
			for e in S.out.fx:
				if e.type == "intro_gesture":
					got.append([t, int(e.actor), e.kind, e.text])
				elif e.type == "intro_line":
					var tg: Dictionary = SimIntro.lineTags(D if r[2] else {}, e.kind, [e.variant, "left" if int(e.actor) == left else "right"])
					if e.angle != tg.angle or e.stance != tg.stance or e.event != tg.event or absf(e.p - tg.p) > 0.000001:
						return label + ": the line %s was tagged '%s' at %s" % [e.kind, e.angle, str(e.p)]
					tagged += 1 if e.angle != "" else 0
		if got != want or fed != r[2]:
			return label + ": the gestures sent were %s, expected %s (the feed %s the default)" % [str(got), str(want), "named" if fed else "did not name"]
		if S.intro.left != 0 or S.fighters[0].state != "free" or S.fighters[1].state != "free":
			return label + ": the intro did not end at its clock"
		SimCore.dispose(S)
		# a press still skips it, and the gestures left are not sent after the skip
		var K := SimCore.createSim()
		SimCore.newMatch(K, 9, {"p1": false, "p2": false}, {"intro": r[1]})
		for t in range(SimIntro.skipFrom):
			SimCore.step(K, [quiet, quiet])
		K.out.fx.clear()
		if SimCore.step(K, [quiet, press]) or K.intro.left != 0 or K.fighters[0].state != "free" or K.fighters[1].state != "free" or K.craters.size() != 2:
			return label + ": a press at tick %d did not skip the intro" % SimIntro.skipFrom
		for t in range(60):
			SimCore.step(K, [quiet, quiet])
		for e in K.out.fx:
			if e.type == "intro_gesture" or e.type == "intro_line":
				return label + ": a %s was sent after the skip" % e.type
		SimCore.dispose(K)
	if tagged == 0:
		return "no voice slot was tagged by the default facts"
	# the take
	var C := SimCore.createSim()
	SimCore.newMatch(C, 5, {"p1": false, "p2": false}, {"intro": "skip"})
	var key := func(c: Dictionary) -> String:
		return "%d:%d:%d:%d" % [c.scenario, c.first, c.gap, c.picks]
	var N: int = 200
	var varied: int = 0
	var second: int = 0   # seeds whose second take is another opening than their first
	var last: Dictionary = T[T.size() - 1]
	for s in range(1, N + 1):
		C.game.seed = s
		var k0: String = key.call(DirIntro.compose(C, {"play": true}))
		for same in [0, 0.0, -3, "two", DirIntro.MAX_TAKE + 1000]:   # (none of these is a later take; past the most is the most)
			var want0: String = k0 if not (same is int and same > 0) else key.call(DirIntro.compose(C, {"play": true, "take": DirIntro.MAX_TAKE}))
			if key.call(DirIntro.compose(C, {"play": true, "take": same})) != want0:
				return "seed %d: a take of %s did not compose the intro it should" % [s, str(same)]
		var seen := {k0: true}
		for take in range(1, 6):
			var a: Dictionary = DirIntro.compose(C, {"play": true, "take": take})
			if key.call(a) != key.call(DirIntro.compose(C, {"play": true, "take": float(take)})):
				return "seed %d: take %d composed two different intros" % [s, take]
			var tp: Dictionary = T[a.scenario]
			if a.gap < tp.gapMin or a.gap > tp.gapMax or SimIntro.flatten(a.scenario, a.gap, a.picks).why != "":
				return "seed %d, take %d composed an intro outside its template" % [s, take]
			seen[key.call(a)] = true
			second += 1 if take == 1 and key.call(a) != k0 else 0
			var f: Dictionary = DirIntro.compose(C, {"play": true, "take": take, "scenario": last.id, "order": 1, "gap": last.gapMin})
			if f.scenario != T.size() - 1 or f.first != 1 or f.gap != last.gapMin:
				return "seed %d, take %d moved what the record fixed" % [s, take]
		varied += 1 if seen.size() >= 3 else 0
	SimCore.dispose(C)
	if varied < N * 9 / 10 or second < N * 9 / 10:
		return "of %d seeds, %d composed another opening on the second take and %d three or more over six takes" % [N, second, varied]
	return ""


## The host's facts (Narrative's plotlines, docs/narrative/dynamic-intros.md section 11) bend a composed intro through five
## keys, and whatever they say the state at the clock is the same. want: that state; clockState: how it is taken.
func _introFacts(want: String, clockState: Callable) -> String:
	var quiet := SimIntent.new()
	var T: Array = SimIntro.templates
	var ids: Array = []
	for tp in T:
		ids.append(tp.id)
	var C := SimCore.createSim()
	SimCore.newMatch(C, 5, {"p1": false, "p2": false}, {"intro": "skip"})
	var N: int = 300
	# weights: a template at 0 is never drawn; one at 10 is drawn more often than without
	var plain: Array = []
	plain.resize(T.size())
	plain.fill(0)
	var heavy: Array = plain.duplicate()
	var last: int = T.size() - 1
	for s in range(1, N + 1):
		C.game.seed = s
		plain[DirIntro.compose(C, {"play": true}).scenario] += 1
		var c: Dictionary = DirIntro.compose(C, {"play": true, "facts": {"weights": {ids[last]: 10.0, ids[0]: 0.0}, "unknown key": [1, 2], "avoidPlot": ["a.b.c"]}})
		heavy[c.scenario] += 1
	if heavy[0] != 0 or heavy[last] <= plain[last]:
		return "the facts' weights: %s drawn %d times at weight 0, %s %d times at x10 against %d plain" % [ids[0], heavy[0], ids[last], heavy[last], plain[last]]
	# the gap: -1 is the short end, 1 the long end, 0 no bend, and between them it moves that share of the way
	for s in range(1, 60):
		C.game.seed = s
		for tp in T:
			var base: int = DirIntro.compose(C, {"play": true, "scenario": tp.id}).gap
			for bend in [-1.0, -0.6, 0.0, 0.5, 1.0]:
				var g: int = DirIntro.compose(C, {"play": true, "scenario": tp.id, "facts": {"gap": bend}}).gap
				var to: float = float(tp.gapMin) if bend < 0.0 else float(tp.gapMax)
				var wantG: int = clampi(int(floor(float(base) + (to - float(base)) * absf(bend) + 0.5)), tp.gapMin, tp.gapMax)
				if g != wantG or (bend == -1.0 and g != tp.gapMin) or (bend == 1.0 and g != tp.gapMax) or (bend == 0.0 and g != base):
					return "the facts' gap %s moved %s's gap from %d to %d (range %d to %d)" % [str(bend), tp.id, base, g, tp.gapMin, tp.gapMax]
			if DirIntro.compose(C, {"play": true, "scenario": tp.id, "gap": tp.gapDef, "facts": {"gap": 1.0}}).gap != tp.gapDef:
				return "the facts moved a gap the setup fixed"
	SimCore.dispose(C)
	# the look, the clock, the gestures and the voice tags, played through: the template with the most ways to fill it
	var ti: int = 0
	for i in range(T.size()):
		if T[i].fills > T[ti].fills:
			ti = i
	var tp2: Dictionary = T[ti]
	var lookSlot: int = -1
	var lookPart: String = ""
	for si in range(tp2.slots.size()):
		if tp2.slots[si].pool.size() > 1 and not tp2.slots[si].draw:
			lookSlot = si
			lookPart = tp2.slots[si].pool[tp2.slots[si].pool.size() - 1]
	if lookSlot < 0:
		return "no template has a slot the facts' look can choose for"
	var bendC: int = mini(24, SimIntro.clockBend[1])
	var facts := {"plot": "test.plot.id", "look": lookPart, "clock": bendC, "gap": -1.0,
		"gestures": [{"at": "land_first", "who": "second", "intent": "check"}, {"at": "look_start", "who": "both", "intent": "appraise"},
			{"at": "look_end", "who": "left", "intent": "harden"}, {"at": "no_such_point", "who": "first", "intent": "ease"}, {"at": "land_second", "who": "nobody", "intent": "ease"}],
		"intents": {"arrive_remark": {"who": "first", "stance": "guarded", "angle": "then", "p": 0.9, "event": "last_ko"},
			"staredown_pair": {"lines": [{"who": "left", "stance": "warm", "angle": "us", "p": 0.5}, {"who": "right", "stance": "smug", "angle": "you"}]}}}
	var pairTags: int = 0
	for run in range(4):   # either fighter first, with the facts' look and then with the slot's own
		var first: int = run % 2
		var lookWant: String = lookPart if run < 2 else tp2.slots[lookSlot].pool[0]
		facts.look = lookWant
		var label: String = "%s with facts (look %s), slot %d first" % [tp2.id, lookWant, first]
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": {"play": true, "scenario": tp2.id, "order": first, "facts": facts}})
		var it = S.intro
		var left: int = SimIntro.leftSlot(S)
		var tl: Dictionary = SimIntro.flatten(ti, it.gap, it.picks)
		if it.gap != tp2.gapMin or it.clock != tp2.clock + bendC or it.left != it.clock or tp2.slots[lookSlot].pool[(it.picks / _fillsBelow(tp2, lookSlot)) % tp2.slots[lookSlot].pool.size()] != lookWant:
			return label + ": gap %d, clock %d, picks %d are not what the facts ask" % [it.gap, it.clock, it.picks]
		var wantG: Array = ["%d %d check land_first" % [tl.land[0] + SimIntro.points.land_first, 1 - first],
			"%d 0 appraise look_start" % (tl.staredown + SimIntro.points.look_start), "%d 1 appraise look_start" % (tl.staredown + SimIntro.points.look_start),
			"%d %d harden look_end" % [it.clock + SimIntro.points.look_end, left]]
		var gotG: Array = []
		var view: Dictionary = SimIntro.timeline(S)
		if view.plot != "test.plot.id" or view.clock != it.clock:
			return label + ": the timeline does not carry the plot and the bent clock"
		var viewG: int = 0
		for b in view.beats:
			viewG += 1 if b.kind == "gesture" else 0
		var plotSeen: bool = false
		var fed: bool = false
		for t in range(it.clock):
			S.out.fx.clear()
			S.out.feed.clear()
			if SimCore.step(S, [quiet, quiet]) or S.T != 0.0:
				return label + ": pre-clock tick %d was live" % t
			for line in S.out.feed:
				fed = fed or String(line.tag) == "INTRO plot: test.plot.id"
			for e in S.out.fx:
				if e.type == "intro_start":
					plotSeen = e.text == "test.plot.id" and absf(e.dur - float(it.clock) / 60.0) < 0.000001
				elif e.type == "intro_gesture":
					gotG.append("%d %d %s %s" % [t, int(e.actor), e.kind, e.text])
				elif e.type == "staredown_start" and absf(e.dur - float(it.clock - t) / 60.0) > 0.000001:
					return label + ": the staredown's length does not follow the bent clock"
				elif e.type == "intro_line":
					var k: int = int(e.actor)
					var tags: String = "%s|%s|%s|%s" % [e.stance, e.angle, e.event, str(e.p)]
					var wantT: String = "|||1.0"
					if e.kind == "arrive_remark" and k == first:
						wantT = "guarded|then|last_ko|0.9"
					elif e.kind == "staredown_pair":
						wantT = "warm|us||0.5" if k == left else "smug|you||1.0"
						pairTags += 1
					if tags != wantT:
						return label + ": the %s slot of slot %d carries %s, wanted %s" % [e.kind, k, tags, wantT]
		wantG.sort()
		gotG.sort()
		if gotG != wantG or viewG != wantG.size():
			return label + ": the gestures were %s, wanted %s (%d in the timeline)" % [str(gotG), str(wantG), viewG]
		if not plotSeen or not fed:
			return label + ": the plot id did not reach intro_start and the feed"
		if S.intro.left != 0 or clockState.call(S) != want:
			return label + ": the state at the clock is not the one the setup's skip gives"
		SimCore.dispose(S)
	if pairTags == 0:
		return "no run offered the staredown's pair of lines, so their tags went unchecked"
	# a clock bend past the data's range is clamped; one that leaves no room is dropped
	var K := SimCore.createSim()
	SimCore.newMatch(K, 5, {}, {"intro": {"play": true, "scenario": tp2.id, "facts": {"clock": 100000}}})
	if K.intro.clock != tp2.clock + SimIntro.clockBend[1]:
		return "a clock bend of 100000 gave %d ticks" % K.intro.clock
	var need: int = SimIntro.flatten(K.intro.scenario, K.intro.gap, K.intro.picks).need
	SimCore.newMatch(K, 5, {}, {"intro": {"play": true, "scenario": tp2.id, "gap": tp2.gapMax, "facts": {"clock": SimIntro.clockBend[0]}}})
	need = SimIntro.flatten(K.intro.scenario, K.intro.gap, K.intro.picks).need
	if K.intro.clock < need or (tp2.clock + SimIntro.clockBend[0] >= need) != (K.intro.clock == tp2.clock + SimIntro.clockBend[0]):
		return "a negative clock bend gave %d ticks where the intro needs %d" % [K.intro.clock, need]
	SimCore.dispose(K)
	# a replay carries the facts and plays the same intro
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 23, {"p1": false, "p2": true}, {"intro": {"play": true, "facts": facts}})
	var sc: int = R.intro.scenario
	for t in range(700):
		rec.step([quiet, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	var back = JSON.parse_string(JSON.stringify(rp))
	if not (back.setup.intro.facts is Dictionary) or back.setup.intro.facts.plot != "test.plot.id" or back.setup.intro.facts.gestures.size() != facts.gestures.size():
		return "the replay's header lost the facts"
	var res: Dictionary = SimReplay.play(back)
	if not res.ok:
		return "a replay of an intro with facts (%s): %s at tick %d" % [T[sc].id, res.reason, res.firstBadTick]
	return ""


## The product of the pool sizes of the slots before slot si: the weight of its digit in a template's picks.
func _fillsBelow(tp: Dictionary, si: int) -> int:
	var m: int = 1
	for i in range(si):
		m *= tp.slots[i].pool.size()
	return m


## Fight lanes, L0 and L2 (docs/architecture/fight-lanes.md). The player never steers depth: the intent has no depth field
## and nothing in sim/input writes a depth. Depth is off unless the setup or the director's switch asks for it, and a
## default match keeps every home depth at 0. With it on (a forced setup): a free fighter eases to his home depth, at the
## cap at most; a rush homes in depth and leaves him there; an exchange's depth is the director's and moves nobody's home;
## a flight's end is the new home; and nothing leaves the band, which is World's lane table.
func _depth() -> String:
	for prop in SimIntent.new().get_property_list():
		var pn: String = prop.name
		if pn == "z" or pn == "zT" or pn == "depth" or pn == "lane" or pn == "mz":
			return "SimIntent has a depth field: " + pn
	var rx := RegEx.new()
	rx.compile("\\.(z|zT|zWay|aimZ0|aimZ1|pz|oz|zs)\\s*(=[^=]|\\+=|-=|\\*=)")
	var d := DirAccess.open("res://sim/input")
	for fname in d.get_files():
		if not fname.ends_with(".gd"):
			continue
		var src: String = FileAccess.get_file_as_string("res://sim/input/" + fname)
		var m := rx.search(src)
		if m != null:
			return "sim/input/%s writes a depth: %s" % [fname, m.get_string()]
	var P := SimCore.createSim()
	SimCore.newMatch(P, 5)
	if P.depthOn:
		return "depth is on in a default match"
	for t in range(600):
		SimCore.step(P)
		P.out.fx.clear()
		P.out.feed.clear()
		for f in P.fighters:
			if f.zT != 0.0:
				return "with depth off a home depth moved (%s at tick %d)" % [str(f.zT), t]
	SimCore.dispose(P)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"depth": true})
	if not S.depthOn:
		return "the setup's depth switch did not reach the sim"
	var a = S.fighters[0]
	var b = S.fighters[1]
	var dt: float = SimConst.DT
	# the free ease, at the cap at most, and the band
	var lim: Array = WorldLanes.limits()
	if SimDepth.zFront != float(lim[0]) or SimDepth.zBack != float(lim[1]) or SimDepth.zFront <= SimDepth.zBack:
		return "the band is not World's lane table (%s to %s)" % [str(SimDepth.zFront), str(SimDepth.zBack)]
	a.z = 150.0
	a.zT = -600.0
	var last: float = a.z
	for t in range(520):
		SimFighter.stepDepth(S, a, dt)
		if a.z > last or last - a.z > SimDepth.cap * dt + 0.000000001:
			return "the free ease moved %s in a tick (the cap gives %s)" % [str(last - a.z), str(SimDepth.cap * dt)]
		last = a.z
	if a.z != -600.0:
		return "a free fighter did not reach his home depth (%s)" % str(a.z)
	a.zT = -99999.0
	for t in range(1200):
		SimFighter.stepDepth(S, a, dt)
	if a.z != SimDepth.zBack or a.zT != SimDepth.zBack:
		return "the band did not hold the back edge (z %s, home %s)" % [str(a.z), str(a.zT)]
	a.z = 99999.0
	SimFighter.stepDepth(S, a, dt)
	if a.z > SimDepth.zFront:
		return "the band did not hold the front edge"
	# a rush homes in depth and leaves him there
	a.z = 0.0
	a.zT = 0.0
	b.z = -900.0
	b.zT = -900.0
	var r := SimState.Rush.new()
	r.tgt = b
	r.off = -60.0
	r.end = S.T + 0.5
	a.rush = r
	var steps: int = 0
	while a.rush != null and steps < 200:
		SimFighter.stepRush(S, a, dt)
		SimFighter.stepDepth(S, a, dt)
		S.T += dt
		steps += 1
	if a.z != -900.0 or a.zT != -900.0:
		return "a rush did not home in depth (z %s, home %s after %d ticks)" % [str(a.z), str(a.zT), steps]
	var r2 := SimState.Rush.new()
	r2.px = a.x + 400.0
	r2.py = a.y
	r2.pz = -300.0
	r2.end = S.T + 0.3
	a.rush = r2
	steps = 0
	while a.rush != null and steps < 200:
		SimFighter.stepRush(S, a, dt)
		S.T += dt
		steps += 1
	if a.z != -300.0:
		return "a point rush did not reach its depth (%s)" % str(a.z)
	# a fighter rush may end a little to one side of its target
	var r3 := SimState.Rush.new()
	r3.tgt = b
	r3.off = -60.0
	r3.offZ = 24.0
	r3.end = S.T + 0.3
	a.rush = r3
	steps = 0
	while a.rush != null and steps < 200:
		SimFighter.stepRush(S, a, dt)
		SimFighter.stepDepth(S, a, dt)
		S.T += dt
		steps += 1
	if a.z != b.z + 24.0 or a.zT != a.z:
		return "a rush with a depth offset ended at %s (its target is at %s)" % [str(a.z), str(b.z)]
	# an exchange's depth is the director's: it moves nobody's home
	var ex := SimState.Exchange.new()
	ex.A = a
	ex.D = b
	ex.z = -450.0
	S.dirS.ex = ex
	var za: float = a.z
	var zb: float = b.z
	SimFighter.stepDepth(S, a, dt)
	SimFighter.stepDepth(S, b, dt)
	if a.zT != za or b.zT != zb or a.z != za or b.z != zb:
		return "an exchange's depth moved a fighter or his home (%s, %s)" % [str(a.zT), str(b.zT)]
	S.dirS.ex = null
	# a flight's end is the new home
	a.state = "launched"
	a.z = -1200.0
	SimFighter.stepDepth(S, a, dt)
	a.state = "free"
	SimFighter.stepDepth(S, a, dt)
	if a.zT != -1200.0 or a.z != -1200.0:
		return "a flight's end did not become the home depth (z %s, home %s)" % [str(a.z), str(a.zT)]
	SimCore.dispose(S)
	return ""


## A fighter's depth outside a flight (docs/architecture/depth-core.md, part a). The data loads and its switch is off;
## the camera's start. With depth on, in the city at a crossing: a locked fighter's velocity in depth is damped and moves
## him as his vx does, so a push along the line keeps its angle; the cap holds vz and not vzX, and the data says which
## cause goes where; in a street the depth part stops at a block's face and the part along the street goes on; at a
## crossing he passes the kerb line; in an avenue the part along the street stops at a block's end and the depth part
## goes on; a roof holds him; a body inside a standing building is put out; a seeded walk never leaves him inside one or
## outside the band; the director's own step goes through the same rule; the new state is in the hash only with depth on;
## and a match with depth on replays to the same hash.
func _depthStep() -> String:
	if not SimDepth.errors().is_empty():
		return "data/combat/depth.json: " + str(SimDepth.errors()[0])
	if SimDepth.enabled():
		return "the depth switch is on in the data: this check, and every golden, is for a tree with it off"
	if absf(SimDepth.cap - 1.2 * 75.0) > 0.000001 or SimDepth.margin <= 0.0 or SimDepth.rx < SimDepth.margin or SimDepth.rz < SimDepth.margin or SimDepth.lanes.is_empty():
		return "the depth numbers read: cap %s, margin %s, half extents %s and %s, %d streets" % [str(SimDepth.cap), str(SimDepth.margin), str(SimDepth.rx), str(SimDepth.rz), SimDepth.lanes.size()]
	var dt: float = SimConst.DT
	var keep: float = SimFighter.lockedKeep(dt)
	# the camera's start: the default start is today's number to the bit, flipped or not; a start elsewhere is where the pair is
	for flip in [false, true]:
		var C := SimCore.createSim()
		SimCore.newMatch(C, 5, {}, {"flip": true} if flip else {})
		var cam := SimCamera.new()
		cam.x = 0.0
		cam.reset(C)
		if cam.x != SimConst.START_X + 350.0 or C.depthOn:
			return "the camera's start for the default match reads %s, or depth is on" % str(cam.x)
		SimCore.dispose(C)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 3, {"p1": false, "p2": false}, {"intro": false, "depth": true, "start": "crossing"})
	if not S.depthOn:
		return "the setup's depth did not reach the sim"
	var f = S.fighters[0]
	var o = S.fighters[1]
	var mid: float = SimWrap.wrap(f.x + SimWrap.sdx(f.x, o.x) * 0.5)
	var cam2 := SimCamera.new()
	cam2.reset(S)
	if absf(SimWrap.sdx(cam2.x, mid) - 100.0) > 0.000001 or absf(SimWrap.sdx(SimConst.START_X, mid)) < 5000.0:
		return "the camera's start at a crossing reads %s for a pair at %s" % [str(cam2.x), str(mid)]
	var isect: Array = WorldLanes.intersections(S, mid, 600.0)
	if isect.is_empty():
		return "the crossing start is not at a crossing"
	var cx: float = float(isect[0][0])
	var rx: float = SimDepth.rx
	var ry: float = SimDepth.ry
	var rz: float = SimDepth.rz
	var body: Array = WorldLanes.body()
	var lane0: Array = SimDepth.lanes[0]
	# World builds nothing in a street lane: the contact rule makes no sweep there
	for b in S.buildings:
		if not b.alive:
			continue
		for l in SimDepth.lanes:
			if b.z + b.d * 0.5 > float(l[1]) + 0.01 and b.z - b.d * 0.5 < float(l[0]) - 0.01:
				return "a building at x %s stands in a street lane (depth %s, %s deep)" % [str(b.x), str(b.z), str(b.d)]
	# the two buildings the cases stand by: one fronting the front street, wide enough to walk along; one at the avenue's end
	var front = null
	var endB = null
	var bestF: float = 1.0e30
	var bestE: float = 1.0e30
	for b in S.buildings:
		var face: float = b.z + b.d * 0.5
		if not b.alive or face > float(lane0[1]) + 0.5 or face < float(lane0[1]) - 150.0:
			continue
		var dx: float = SimWrap.sdx(cx, b.x)
		if b.w >= 4.0 * rx + 120.0 and absf(dx) < bestF and WorldStructures.curH(b) > 3.0 * ry:
			bestF = absf(dx)
			front = b
		var gap: float = dx - b.w * 0.5
		if dx > 0.0 and gap > rx and gap < bestE and b.d > 4.0 * rz and WorldStructures.curH(b) > 3.0 * ry:
			bestE = gap
			endB = b
	if front == null or endB == null:
		return "no building fronts the front street by the crossing (the cases need one, and one at the avenue's end)"
	var place := func(x: float, y: float, z: float) -> void:
		f.state = "locked"
		f.rush = null
		f.x = SimWrap.wrap(x)
		f.y = y
		f.z = z
		f.zT = z
		f.vx = 0.0
		f.vy = 0.0
		f.vz = 0.0
		f.vzX = 0.0
		f.stunTicks = 0
	var inside := func() -> bool:
		return WorldStructures.blocked(S, f.x, f.y, f.z, float(body[0]), float(body[1]), float(body[2])) >= 0
	var gz: float = WorldTerrain.groundY(S, cx, 0.0)
	# 1. at the crossing, a push along a line: vz is damped and integrated as vx is
	place.call(cx, gz + 20.0, 0.0)
	f.vx = 120.0
	f.vz = 60.0
	var xa: float = f.x
	for t in range(60):
		SimFighter.stepFighter(S, f, dt)
		if f.vx == 0.0 or absf(f.vz / f.vx - 0.5) > 0.000000001 or f.zT != f.z:
			return "tick %d: a locked fighter's vz and vx read %s and %s, home %s at depth %s" % [t, str(f.vz), str(f.vx), str(f.zT), str(f.z)]
	var gone: float = SimWrap.sdx(xa, f.x)
	if gone < 20.0 or absf(f.z / gone - 0.5) > 0.000001:
		return "a push along a line of one in two went %s along and %s deep" % [str(gone), str(f.z)]
	# 2. the cap holds vz and not vzX; the data says which cause goes where
	place.call(cx, gz + 20.0, 0.0)
	f.vz = 5000.0
	SimFighter.stepFighter(S, f, dt)
	if absf(f.z - SimDepth.cap * dt) > 0.000000001:
		return "a drift of 5000 a second moved him %s in a tick (the cap gives %s)" % [str(f.z), str(SimDepth.cap * dt)]
	place.call(cx, gz + 20.0, 0.0)
	f.vzX = 600.0
	SimFighter.stepFighter(S, f, dt)
	if absf(f.z - 600.0 * keep * dt) > 0.000000001:
		return "an exempt velocity of 600 moved him %s in a tick" % str(f.z)
	place.call(cx, gz + 20.0, 0.0)
	SimFighter.addDepth(f, "push", 30.0)
	SimFighter.addDepth(f, "carry", 10.0)
	SimFighter.addDepth(f, "shove", -200.0)
	if f.vz != 40.0 or f.vzX != -200.0 or not SimDepth.isExempt("shove") or SimDepth.isExempt("push"):
		return "the causes went to vz %s and vzX %s" % [str(f.vz), str(f.vzX)]
	# 3. in the street, beside a building: the depth part stops at its face and the part along the street goes on
	var stopZ: float = front.z + (front.d * 0.5 + rz + SimDepth.SKIN)   # as the contact rule works it out, to the bit
	var xs: float = SimWrap.wrap(front.x - front.w * 0.5 + rx + 30.0)
	place.call(xs, WorldTerrain.groundY(S, xs, 0.0) + 20.0, stopZ + 30.0)
	var stopped: int = 0
	var room: float = front.w - 2.0 * rx - 60.0
	var t3: int = 0
	while SimWrap.sdx(xs, f.x) < room - 6.0 and t3 < 2000:
		var xb: float = f.x
		f.vx = 150.0
		f.vz = -80.0
		SimFighter.stepFighter(S, f, dt)
		t3 += 1
		if f.z < stopZ:
			return "in the street he went past the face: depth %s, and he stops at %s" % [str(f.z), str(stopZ)]
		if SimWrap.sdx(xb, f.x) <= 0.0:
			return "in the street his step along it stopped (tick %d at depth %s)" % [t3, str(f.z)]
		if f.z == stopZ:
			stopped += 1
			if f.vz != 0.0 or f.zT != f.z:
				return "stopped at the face he kept a depth velocity of %s, or a home of %s" % [str(f.vz), str(f.zT)]
	if stopped < 10:
		return "in the street he never came to the face (depth %s after %d ticks; the face stops him at %s)" % [str(f.z), t3, str(stopZ)]
	# 4. at the crossing he passes the kerb line into the avenue
	place.call(cx, gz + 20.0, float(lane0[1]) + rz + 20.0)
	for t in range(240):
		f.vz = -80.0
		SimFighter.stepFighter(S, f, dt)
	if f.z > float(lane0[1]) - 100.0:
		return "at the crossing he did not pass the kerb line (depth %s; the kerb is at %s)" % [str(f.z), str(lane0[1])]
	# 5. in the avenue, at the block's depth: the part along the street stops at the block's end, and the depth part goes on
	var endX: float = SimWrap.wrap(endB.x - (endB.w * 0.5 + rx + SimDepth.SKIN))
	place.call(cx, WorldTerrain.groundY(S, cx, endB.z) + 20.0, endB.z + endB.d * 0.5 - rz - 40.0)
	if inside.call():
		return "the avenue is not clear at the block's depth"
	var held: int = 0
	for t in range(400):
		var zb: float = f.z
		f.vx = 200.0
		f.vz = -30.0
		SimFighter.stepFighter(S, f, dt)
		if SimWrap.sdx(f.x, endX) < 0.0:
			return "in the avenue he went past the block's end (x %s; it stops him at %s)" % [str(f.x), str(endX)]
		if f.z >= zb:
			return "in the avenue his depth part stopped (tick %d)" % t
		if f.x == endX:
			held += 1
			if f.vx != 0.0:
				return "stopped at the block's end he kept a vx of %s" % str(f.vx)
			if held >= 20:
				break
	if held < 20:
		return "in the avenue he never came to the block's end (x %s; it stops him at %s)" % [str(f.x), str(endX)]
	# 6. a roof holds him, and he walks on it; a body inside a standing building is put out
	var top: float = WorldStructures.baseY(S, front) + WorldStructures.curH(front)
	place.call(front.x - 20.0, top + 60.0, front.z)
	var onRoof: int = 0
	for t in range(80):
		var xr: float = f.x
		f.vx = 60.0
		f.vy = -300.0
		SimFighter.stepFighter(S, f, dt)
		if f.y < top:
			return "he went through the roof (height %s; the roof is at %s)" % [str(f.y), str(top)]
		if f.y == top + SimDepth.SKIN:
			onRoof += 1
			if f.vy != 0.0 or SimWrap.sdx(xr, f.x) <= 0.0:
				return "on the roof he kept falling, or did not walk"
	if onRoof < 20 or WorldStructures.standingAt(S, f.x, f.y, f.z).kind != "roof":
		return "the roof did not hold him (height %s; the roof is at %s)" % [str(f.y), str(top)]
	place.call(front.x, WorldStructures.baseY(S, front) + 10.0, front.z + front.d * 0.5 - 30.0)
	if not inside.call():
		return "the staging did not put him inside the building"
	SimFighter.stepFighter(S, f, dt)
	if inside.call():
		return "a body inside a standing building was not put out"
	# 7. a seeded walk through the city: never inside a standing building below its roof, never outside the band
	var R := SimRng.new(SimRng.deriveSeed(3, "parity.depth.walk"))
	place.call(cx, gz + 20.0, 0.0)
	var wx: float = 0.0
	var wy: float = 0.0
	var wz: float = 0.0
	for t in range(2000):
		if t % 25 == 0:
			wx = R.range_(-420.0, 420.0)
			wy = R.range_(-220.0, 220.0)
			wz = R.range_(-260.0, 260.0)
			if absf(SimWrap.sdx(cx, f.x)) > 2400.0:
				wx = -420.0 if SimWrap.sdx(cx, f.x) > 0.0 else 420.0
		f.vx = wx
		f.vy = wy
		f.vzX = wz
		SimFighter.stepFighter(S, f, dt)
		if inside.call():
			return "tick %d of the walk: he is inside a standing building at (%s, %s, %s)" % [t, str(f.x), str(f.y), str(f.z)]
		if f.z > SimDepth.zFront or f.z < SimDepth.zBack or f.y < WorldTerrain.groundY(S, f.x, f.z) - 0.000001:
			return "tick %d of the walk: he left the band or the ground (%s, %s)" % [t, str(f.y), str(f.z)]
	# 8. the director's own step goes through the same rule
	place.call(cx, gz + 20.0, 0.0)
	if not SimFighter.stepTo(S, f, cx + 30.0, gz + 25.0, -40.0) or f.x != SimWrap.wrap(cx + 30.0) or f.y != gz + 25.0 or f.z != -40.0 or f.zT != -40.0:
		return "a clear step to a place did not put him there (%s, %s, %s)" % [str(f.x), str(f.y), str(f.z)]
	place.call(xs + 40.0, WorldTerrain.groundY(S, xs, 0.0) + 20.0, stopZ + 10.0)
	if SimFighter.stepTo(S, f, f.x + 12.0, f.y, stopZ - 30.0) or f.z != stopZ or f.zT != stopZ or absf(SimWrap.sdx(xs + 40.0, f.x) - 12.0) > 0.000001:
		return "a step into a face ended at depth %s (the face stops him at %s)" % [str(f.z), str(stopZ)]
	var P := SimCore.createSim()
	SimCore.newMatch(P, 5, {"p1": false, "p2": false}, {"intro": false})
	var pf = P.fighters[0]
	var px: float = pf.x
	if not SimFighter.stepTo(P, pf, px + 9.0, pf.y + 3.0, -300.0) or pf.x != SimWrap.wrap(px + 9.0) or pf.z != 0.0:
		return "with depth off a step to a place moved his depth, or missed the place"
	# 9. the new state is in the hash only with depth on
	var h0: String = SimHash.stateHash(P).gameplay
	pf.vz = 12.0
	pf.vzX = -7.0
	P.dirS.lineSin = 0.3
	P.dirS.sideT = 4
	if SimHash.stateHash(P).gameplay != h0:
		return "with depth off the depth step's state changed the hash"
	SimCore.dispose(P)
	place.call(cx, gz + 20.0, 0.0)
	var h1: String = SimHash.stateHash(S).gameplay
	for k in range(4):
		if k == 0: f.vz = 3.0
		elif k == 1: f.vzX = 3.0
		elif k == 2: S.dirS.lineSin = 0.25
		else: S.dirS.homeWait = 9
		var h2: String = SimHash.stateHash(S).gameplay
		if h2 == h1:
			return "with depth on, field %d of the depth step's state is not in the hash" % k
		h1 = h2
	SimCore.dispose(S)
	# 10. a match with depth on replays to the same hash
	for seed in [3, 5, 12345]:
		var hs: Array = []
		for run in range(2):
			var M := SimCore.createSim()
			SimCore.newMatch(M, seed, {}, {"depth": true})
			for t in range(1500):
				SimCore.step(M)
				M.out.fx.clear()
				M.out.feed.clear()
				for mf in M.fighters:
					if mf.z > SimDepth.zFront or mf.z < SimDepth.zBack or mf.z != mf.z:
						return "seed %d, tick %d: a fighter's depth reads %s" % [seed, t, str(mf.z)]
			hs.append(SimHash.stateHash(M).gameplay)
			SimCore.dispose(M)
		if hs[0] != hs[1]:
			return "seed %d with depth on did not replay to the same hash" % seed
	return ""


## The second breath (spec-wounds.md section 1c): a battered region fades once the fighter has had quiet for the wait
## (fade.breathAfterTicks). The wait starts again on a hit he takes, landed or blocked, and on his own approach from its
## tell. It does not start again when he fires a shot or when a hit of his own lands: a fighter who only shoots still
## gets his second breath. (An exchange he is in restarts it too, through f.exT.) Counted in live ticks through the step.
func _breathQuiet() -> String:
	var quiet := SimIntent.new()
	var cases: Array = [["a hit he takes", true], ["a hit he blocks", true], ["a shot he fires", false], ["a hit of his own", false]]
	for ci in range(cases.size()):
		var label: String = cases[ci][0]
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
		var f = S.fighters[0]
		var o = S.fighters[1]
		var wd = f.wd
		var wait: int = int(round(wd.breathAfter * 60.0))
		if wait < 10 or wd.fadeBreath <= 0:
			return "the wounds data gives a wait of %d ticks and a fade of %d" % [wait, wd.fadeBreath]
		f.wear[SimWounds.HEAD] = wd.stageAt[1] + 120000
		SimWounds.updateStages(S, f)
		f.exT = -100.0
		f.breathT = -100.0
		var liveStep := func() -> bool:
			for k in range(40):
				S.out.fx.clear()
				if SimCore.step(S, [quiet, quiet]):
					return true
			return false
		var b0: int = f.breathWear
		for t in range(5):
			liveStep.call()
		if f.breathWear != b0 + 5 * wd.fadeBreath:
			return label + ": with quiet behind him the region faded %d in 5 ticks" % (f.breathWear - b0)
		if ci == 0:
			f.stance = 0.0
			SimDamage.hit(S, null, o, f, 4.0, {"kind": "blast", "ignoreStance": true, "stop": 0.0})
		elif ci == 1:
			f.stance = 1.0
			SimDamage.hit(S, null, o, f, 4.0, {"kind": "blast", "shot": 1.0, "stop": 0.0})
		elif ci == 2:
			var sh = SimShots.fire(S, 0, "bolt", {"ux": -o.face, "uy": 0.0})
			if sh == null:
				return "a bolt could not be fired"
			SimShots.end(S, sh, "life")
		else:
			SimDamage.hit(S, null, f, o, 4.0, {"kind": "blast", "ignoreStance": true, "stop": 0.0})
		f.wear[SimWounds.HEAD] = wd.stageAt[1] + 120000   # (a hit may have worn it: keep it battered and short of broken)
		for r in [SimWounds.CORE, SimWounds.ARMS, SimWounds.LEGS]:
			f.wear[r] = 0
		SimWounds.updateStages(S, f)
		var b1: int = f.breathWear
		if cases[ci][1]:
			for t in range(wait - 2):
				liveStep.call()
			if f.breathWear != b1:
				return label + ": the region faded %d inside the wait" % (f.breathWear - b1)
			for t in range(6):
				liveStep.call()
			if f.breathWear <= b1:
				return label + ": the region did not fade again after the wait"
		else:
			for t in range(5):
				liveStep.call()
			if f.breathWear != b1 + 5 * wd.fadeBreath:
				return label + ": it stopped the fade (%d in 5 ticks); only a hit he takes, an exchange or his approach does" % (f.breathWear - b1)
		SimCore.dispose(S)
	# his own approach, from its tell (the director's line in DirBands.begin)
	var A := SimCore.createSim()
	SimCore.newMatch(A, 5, {"p1": false, "p2": false}, {"intro": false})
	for t in range(30):
		SimCore.step(A, [quiet, quiet])
	var af = A.fighters[0]
	af.breathT = -100.0
	DirBands.begin(A, af, A.fighters[1], SimAct.LIGHT, 0, A.tick)
	if af.breathT != A.T:
		return "his own approach did not restart the wait at its tell"
	SimCore.dispose(A)
	return ""


## A bowed rush (Rush.arc). With no arc a rush is the straight one it was. With one it leaves from the same place and
## arrives at the same point on the same tick, and between them it sits off the straight line by the arc x 4u(1 - u),
## square to the line, on the mover's left for an arc above 0 (up when he travels toward +x). It holds across the seam
## and for a rush at a fighter. The ground holds a bow that would dip under it. The arc is in the hash. Every rush keeps
## where it began from its first step, and rushAt at rushU is where he is, for a straight rush and a bowed one.
func _rushArc() -> String:
	var quiet := SimIntent.new()
	var cases: Array = [   # [start x, start height, target x, target height, arc, at the rival]
		[2000.0, 0.0, 2900.0, 0.0, 240.0, false],      # level, toward +x: bows up
		[2900.0, 0.0, 2000.0, 0.0, 240.0, false],      # level, toward -x: bows down
		[2000.0, 0.0, 2600.0, 800.0, -180.0, false],   # a climb, bowed to the mover's right
		[9500.0, 100.0, 150.0, 300.0, 300.0, false],   # across the seam
		[2000.0, 0.0, 2900.0, 0.0, 200.0, true],       # at the rival (a fighter rush), who stands still
	]
	for ci in range(cases.size()):
		var c: Array = cases[ci]
		var label: String = "rush %d (arc %s)" % [ci, str(c[4])]
		var P: Array = []   # the straight twin, then the bowed one
		for arc in [0.0, c[4]]:
			var S := SimCore.createSim()
			SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
			var f = S.fighters[0]
			var o = S.fighters[1]
			var top: float = 0.0   # well above any ground on the way, so the straight line is clear
			for k in range(41):
				top = maxf(top, WorldTerrain.groundY(S, SimWrap.wrap(c[0] + SimWrap.sdx(c[0], c[2]) * float(k) / 40.0)))
			f.x = c[0]; f.y = top + 2500.0 + c[1]; f.vx = 0.0; f.vy = 0.0
			o.x = 6000.0; o.y = WorldTerrain.groundY(S, 6000.0) + 400.0
			var r := SimState.Rush.new()
			if c[5]:
				o.x = c[2]; o.y = top + 2500.0 + c[3]
				r.tgt = o
				r.off = -60.0
			else:
				r.px = c[2]; r.py = top + 2500.0 + c[3]; r.pz = f.z
			r.end = S.T + 20.0 * SimConst.DT
			r.arc = arc
			f.rush = r
			P.append({"S": S, "f": f, "o": o, "r": r, "x": [], "y": [], "x0": f.x, "y0": f.y})
		if SimHash.stateHash(P[0].S).gameplay == SimHash.stateHash(P[1].S).gameplay:
			return label + ": the arc is not in the hash"
		for q in P:   # before its first step: 0 is where he is, 1 is the target, and he has not moved along it
			var a0: PackedFloat64Array = SimFighter.rushAt(q.S, q.f, 0.0)
			var a1: PackedFloat64Array = SimFighter.rushAt(q.S, q.f, 1.0)
			var wx: float = q.r.tgt.x + q.r.off if q.r.tgt != null else q.r.px
			var wy: float = q.r.tgt.y if q.r.tgt != null else q.r.py
			if a0[0] != q.x0 or a0[1] != q.y0 or absf(SimWrap.sdx(a1[0], wx)) > 0.000001 or absf(a1[1] - wy) > 0.000001 or SimFighter.rushU(q.S, q.f) != 0.0:
				return label + ": before its first step rushAt gives %s and %s" % [str(a0), str(a1)]
		for q in P:
			for t in range(60):
				if q.f.rush == null:
					break
				SimCore.step(q.S, [quiet, quiet])
				q.x.append(q.f.x)
				q.y.append(q.f.y)
				if t == 0 and q.f.rush != null and not (q.r.dur > 0.0 and q.r.x0 == q.x0 and q.r.y0 == q.y0):
					return label + ": after its first step the rush's start is %s,%s with %s left" % [str(q.r.x0), str(q.r.y0), str(q.r.dur)]
				var here: PackedFloat64Array = SimFighter.rushAt(q.S, q.f, SimFighter.rushU(q.S, q.f))
				if absf(SimWrap.sdx(here[0], q.f.x)) > 0.001 or absf(here[1] - q.f.y) > 0.001 or (q.f.rush == null and SimFighter.rushU(q.S, q.f) != 1.0):
					return label + ": at tick %d rushAt at rushU is %s and he is at %s,%s" % [t, str(here), str(q.f.x), str(q.f.y)]
		var M: int = P[0].x.size()
		if M < 10 or P[1].x.size() != M or P[0].f.rush != null or P[1].f.rush != null:
			return label + ": the straight rush took %d ticks and the bowed one %d" % [M, P[1].x.size()]
		if P[0].x[M - 1] != P[1].x[M - 1] or P[0].y[M - 1] != P[1].y[M - 1]:
			return label + ": the bowed rush arrived at %s,%s and the straight one at %s,%s" % [str(P[1].x[M - 1]), str(P[1].y[M - 1]), str(P[0].x[M - 1]), str(P[0].y[M - 1])]
		var dx: float = SimWrap.sdx(P[0].x0, P[0].x[M - 1])
		var dy: float = P[0].y[M - 1] - P[0].y0
		var dl: float = SimDetMath.hypot(dx, dy)
		var peak: float = 0.0
		for i in range(M - 1):
			var u: float = float(i + 1) / float(M)
			var bow: float = c[4] * 4.0 * u * (1.0 - u)
			var ox: float = SimWrap.sdx(P[0].x[i], P[1].x[i])
			var oy: float = P[1].y[i] - P[0].y[i]
			if absf(ox - (-dy / dl) * bow) > 0.001 or absf(oy - (dx / dl) * bow) > 0.001:
				return label + ": at tick %d it is %s,%s off the straight line, and the bow there is %s" % [i, str(ox), str(oy), str(bow)]
			peak = maxf(peak, SimDetMath.hypot(ox, oy))
			if ci < 2 and oy * dx * c[4] <= 0.0:
				return label + ": a level rush toward %s bowed %s" % ["+x" if dx > 0.0 else "-x", "down" if oy < 0.0 else "up"]
		if absf(peak - absf(c[4])) > absf(c[4]) * 0.02:
			return label + ": the bow's peak was %s" % str(peak)
		for q in P:
			SimCore.dispose(q.S)
	# the ground holds a bow that would dip under it
	var G := SimCore.createSim()
	SimCore.newMatch(G, 5, {"p1": false, "p2": false}, {"intro": false})
	var gf = G.fighters[0]
	gf.x = 2000.0
	gf.y = WorldTerrain.groundY(G, gf.x)
	var gr := SimState.Rush.new()
	gr.px = 2600.0; gr.py = WorldTerrain.groundY(G, 2600.0); gr.pz = gf.z
	gr.end = G.T + 20.0 * SimConst.DT
	gr.arc = -400.0
	gf.rush = gr
	for t in range(40):
		SimCore.step(G, [quiet, quiet])
		if gf.y < WorldTerrain.groundY(G, gf.x) - 0.000001:
			return "a bow that dips took him %s under the ground at tick %d" % [str(WorldTerrain.groundY(G, gf.x) - gf.y), t]
	if gf.rush != null or absf(SimWrap.sdx(gf.x, 2600.0)) > 0.000001:
		return "the dipping rush did not arrive"
	SimCore.dispose(G)
	return ""


## A drop (SimFighter.drop; melee-press-feel.md section 2c): a fighter knocked out of a rush falls from where he is and
## reads no stick for the ticks given, then is free. Nothing is hurt, worn, dug, launched or scored, in the air or when
## he reaches the ground; a frozen tick does not count; dropEnd ends it sooner with the caller's word; a fighter who is
## launched, down or already dropped is not dropped.
func _drop() -> String:
	var quiet := SimIntent.new()
	var push := SimIntent.new()
	push.mx = 1.0
	push.my = 1.0
	var loud: Array = ["damage", "launch", "crater", "decisive", "knockback", "land", "left_ground", "bounce", "journey_end", "region_stage", "ko"]
	for height in [3000.0, 30.0]:   # a fall that ends in the air, and one that reaches the ground
		var label: String = "a drop from %d up" % int(height)
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
		var f = S.fighters[0]
		f.y = WorldTerrain.groundY(S, f.x) + height
		var r := SimState.Rush.new()
		r.px = f.x; r.py = f.y; r.pz = f.z
		r.end = S.T + 30.0 * SimConst.DT
		f.rush = r
		SimCore.step(S, [quiet, quiet])
		var x0: float = f.x
		var hp0: float = f.hp
		var wear0: Array = f.wear.duplicate()
		var craters0: int = S.craters.size()
		S.out.fx.clear()
		if SimFighter.drop(S, f, 0) or not SimFighter.drop(S, f, 24) or f.state != "dropped" or f.rush != null or f.dropT != 24:
			return label + ": drop left him %s with %d ticks" % [f.state, f.dropT]
		if SimFighter.drop(S, f, 24) or S.out.fx.size() != 1 or S.out.fx[0].type != "drop_start" or int(S.out.fx[0].actor) != 0 or absf(S.out.fx[0].dur - 0.4) > 0.000001:
			return label + ": a second drop took, or drop_start was not sent once"
		var y: float = f.y
		var vy: float = 0.0
		var landed: int = 0
		var ended: String = ""
		var live: int = 0
		var frozen: int = 0
		for t in range(40):
			if live == 3 and frozen == 0:
				S.dirS.stop = 0.05   # a hit-stop: its ticks are not the drop's
			S.out.fx.clear()
			var was: int = f.dropT
			var yb: float = f.y
			if not SimCore.step(S, [push, quiet]):
				frozen += 1
				if f.dropT != was or f.y != yb:
					return label + ": a frozen tick moved the drop on"
				continue
			live += 1
			vy -= SimFighter.DROP_GRAV * SimConst.DT
			y += vy * SimConst.DT
			var g: float = WorldTerrain.groundY(S, f.x)
			if y <= g:
				y = g
				vy = 0.0
			for e in S.out.fx:
				if e.type in loud:
					return label + ": a %s event at live tick %d" % [e.type, live]
				if e.type == "drop_land":
					landed += 1
				elif e.type == "drop_end":
					ended = e.kind
			if f.spin != 0.0 or (live <= 24 and absf(f.stateT - float(live) * SimConst.DT) > 0.000001):
				return label + ": at live tick %d his stateT is %s and his spin %s" % [live, str(f.stateT), str(f.spin)]
			if live <= 24 and (f.x != x0 or absf(f.y - y) > 0.000001):
				return label + ": at live tick %d he is at %s,%s (expected %s,%s)" % [live, str(f.x), str(f.y), str(x0), str(y)]
			if (f.state == "dropped") != (live < 24) or (live >= 24 and (f.state != "free" or f.dropT != 0)):
				return label + ": at live tick %d his state is %s with %d ticks left" % [live, f.state, f.dropT]
			if live == 24:
				break
		if frozen == 0 or ended != "end" or landed != (1 if height < 100.0 else 0) or f.hp != hp0 or f.wear != wear0 or S.craters.size() != craters0 or f.launchBy != null:
			return label + ": %d frozen ticks, ended '%s', landed %d times, hp %s (was %s), %d craters (were %d)" % [frozen, ended, landed, str(f.hp), str(hp0), S.craters.size(), craters0]
		SimCore.step(S, [push, quiet])
		if f.x == x0:
			return label + ": free again, he did not answer the stick"
		SimCore.dispose(S)
	# ended sooner by the caller (a tech), a starting speed, and who cannot be dropped
	var T := SimCore.createSim()
	SimCore.newMatch(T, 5, {"p1": false, "p2": false}, {"intro": false})
	var tf = T.fighters[0]
	tf.y = WorldTerrain.groundY(T, tf.x) + 2000.0
	var tx0: float = tf.x
	if not SimFighter.drop(T, tf, 24, 300.0, 0.0):
		return "a free fighter could not be dropped"
	for t in range(5):
		SimCore.step(T, [quiet, quiet])
	if tf.state != "dropped" or tf.dropT != 19 or SimWrap.sdx(tx0, tf.x) <= 0.0:
		return "five ticks into a drop with a sideways speed: %s, %d left, moved %s" % [tf.state, tf.dropT, str(SimWrap.sdx(tx0, tf.x))]
	T.out.fx.clear()
	SimFighter.dropEnd(T, tf, "tech")
	if tf.state != "free" or tf.dropT != 0 or T.out.fx.size() != 1 or T.out.fx[0].type != "drop_end" or T.out.fx[0].kind != "tech":
		return "dropEnd did not free him with its word"
	SimFighter.dropEnd(T, tf, "tech")
	if T.out.fx.size() != 1:
		return "dropEnd on a free fighter sent an event"
	for st in ["launched", "down"]:
		tf.state = st
		if SimFighter.drop(T, tf, 24) or tf.state != st:
			return "a fighter who is %s was dropped" % st
	SimCore.dispose(T)
	return ""


## Blocked blows and the arms (melee-press-feel.md section 9d, ruling 1): a blocked light puts block.streamArmShare of
## its wear on the arms and none on the legs; a blocked heavy splits as guardWearSplit says; no blocked blow takes the arms
## past block.armWearCap, so blocking alone never batters them and nothing spills into the core; an arm already past the
## cap takes nothing from a block; and the damage path passes a blocked light through as one.
func _blockedArms() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var f = S.fighters[0]
	var wd = f.wd
	var A: int = SimWounds.ARMS
	var L: int = SimWounds.LEGS
	var k: float = SimWounds.wearK(S, f)
	if wd.blockArmCap <= 0 or wd.blockArmCap >= wd.stageAt[1] or wd.blockArmShare <= 0.0:
		return "the block data gives a share of %s and a cap of %d" % [str(wd.blockArmShare), wd.blockArmCap]
	SimWounds.addGuardWear(S, f, 10.0, SimWounds.BLOCK_LIGHT)
	if f.wear[A] != int(SimMathx.jround(10.0 * wd.blockArmShare * k)) or f.wear[L] != 0:
		return "a blocked light put %d on the arms and %d on the legs" % [f.wear[A], f.wear[L]]
	f.wear[A] = 0
	SimWounds.addGuardWear(S, f, 10.0)
	if f.wear[A] != int(SimMathx.jround(10.0 * wd.guardArms * k)) or f.wear[L] != int(SimMathx.jround(10.0 * wd.guardLegs * k)):
		return "a blocked heavy put %d on the arms and %d on the legs" % [f.wear[A], f.wear[L]]
	var legs0: int = f.wear[L]
	for n in range(300):
		SimWounds.addGuardWear(S, f, 10.0, SimWounds.BLOCK_LIGHT if n % 2 == 0 else SimWounds.BLOCK_HEAVY)
		if f.wear[A] > wd.blockArmCap or f.stage[A] >= 2:
			return "blocked blows took the arms to %d, past the cap of %d (stage %d)" % [f.wear[A], wd.blockArmCap, f.stage[A]]
	if f.wear[A] != wd.blockArmCap or f.wear[L] <= legs0 or f.wear[SimWounds.CORE] != 0 or f.wear[SimWounds.HEAD] != 0:
		return "after 300 blocked blows: arms %d (cap %d), legs %d, core %d" % [f.wear[A], wd.blockArmCap, f.wear[L], f.wear[SimWounds.CORE]]
	f.wear[A] = wd.blockArmCap + 6000
	SimWounds.addGuardWear(S, f, 50.0, SimWounds.BLOCK_LIGHT)
	SimWounds.addGuardWear(S, f, 50.0)
	if f.wear[A] != wd.blockArmCap + 6000:
		return "a block wore an arm that was already past the cap"
	f.wear[A] = 0
	S.out.fx.clear()
	SimDamage.hurt(S, f, 10.0, S.fighters[1], "guard", "guard", "", true, "brawl", SimWounds.BLOCK_LIGHT)
	var e = S.out.fx[S.out.fx.size() - 1] if not S.out.fx.is_empty() else null
	for q in S.out.fx:
		if q.type == "damage":
			e = q
	if f.wear[A] != int(SimMathx.jround(10.0 * wd.blockArmShare * k)) or e == null or e.type != "damage" or e.mode != "brawl" or e.kind != "guard":
		return "a blocked brawl blow through the damage path wore the arms %d and sent %s" % [f.wear[A], "nothing" if e == null else e.kind + "/" + e.mode]
	SimCore.dispose(S)
	return ""


## Blocked shots are ruled apart from blocked blows (melee-press-feel.md section 9d): a blocked shot of any kind puts
## block.shotArmShare of its wear on the arms, up to block.shotArmWearCap (under broken), and what is over the cap goes
## into the core; a blocked blow's wear over its own cap is soaked and never reaches the core. A blocked bolt puts nothing
## on the legs, and a heavy or charged shot keeps guardWearSplit's share there. Through the damage path, a guarded hit of
## kind blast is a shot: a bolt when the director names a power under 2, else a heavy one.
func _blockedShots() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var f = S.fighters[0]
	var by = S.fighters[1]
	var wd = f.wd
	var A: int = SimWounds.ARMS
	var L: int = SimWounds.LEGS
	var C: int = SimWounds.CORE
	var k: float = SimWounds.wearK(S, f)
	var one: int = int(SimMathx.jround(10.0 * wd.shotArmShare * k))
	var legs1: int = int(SimMathx.jround(10.0 * wd.guardLegs * k))
	if one <= 0 or wd.shotArmCap < 2 * one or wd.shotArmCap >= wd.stageAt[2]:
		return "the block data gives shots a share of %s and a cap of %d" % [str(wd.shotArmShare), wd.shotArmCap]
	SimWounds.addGuardWear(S, f, 10.0, SimWounds.BLOCK_SHOT)
	if f.wear[A] != one or f.wear[L] != 0 or f.wear[C] != 0:
		return "a blocked bolt put %d on the arms, %d on the legs and %d on the core" % [f.wear[A], f.wear[L], f.wear[C]]
	SimWounds.addGuardWear(S, f, 10.0, SimWounds.BLOCK_SHOT_HEAVY)
	if f.wear[A] != 2 * one or f.wear[L] != legs1 or f.wear[C] != 0:
		return "a blocked heavy shot put %d on the arms and %d on the legs" % [f.wear[A] - one, f.wear[L]]
	# the bolt that crosses the cap: the arms stop on it and the rest is the core's
	var part: int = one / 3 + 1
	f.wear[A] = wd.shotArmCap - part
	f.wear[L] = 0
	SimWounds.updateStages(S, f)
	SimWounds.addGuardWear(S, f, 10.0, SimWounds.BLOCK_SHOT)
	if f.wear[A] != wd.shotArmCap or f.wear[C] != one - part or f.wear[L] != 0:
		return "the bolt that crossed the cap left the arms at %d (cap %d) and the core at %d (expected %d)" % [f.wear[A], wd.shotArmCap, f.wear[C], one - part]
	# at the cap every blocked shot's arm share is the core's; the arms stay, and shots never break them
	for n in range(40):
		SimWounds.addGuardWear(S, f, 10.0, SimWounds.BLOCK_SHOT)
	if f.wear[A] != wd.shotArmCap or f.wear[C] != one - part + 40 * one or f.wear[L] != 0 or f.wear[SimWounds.HEAD] != 0 or f.stage[A] != SimWounds.stageOf(wd.shotArmCap, wd.stageAt) or f.stage[A] >= 3:
		return "after 40 bolts on arms at the cap: arms %d (cap %d, stage %d), core %d (expected %d), legs %d" % [f.wear[A], wd.shotArmCap, f.stage[A], f.wear[C], one - part + 40 * one, f.wear[L]]
	var core0: int = f.wear[C]
	SimWounds.addGuardWear(S, f, 10.0, SimWounds.BLOCK_SHOT_HEAVY)
	if f.wear[A] != wd.shotArmCap or f.wear[C] != core0 + one or f.wear[L] != legs1:
		return "a blocked heavy shot on arms at the cap: arms %d, core %d (expected %d), legs %d" % [f.wear[A], f.wear[C], core0 + one, f.wear[L]]
	# a blocked blow over its own cap is soaked: nothing reaches the core
	f.wear[A] = wd.blockArmCap
	f.wear[C] = 0
	SimWounds.updateStages(S, f)
	SimWounds.addGuardWear(S, f, 50.0, SimWounds.BLOCK_LIGHT)
	SimWounds.addGuardWear(S, f, 50.0)
	if f.wear[A] != wd.blockArmCap or f.wear[C] != 0:
		return "a blocked blow over its cap: arms %d (cap %d), core %d" % [f.wear[A], wd.blockArmCap, f.wear[C]]
	# through the damage path: the defender holds DEFENSIVE; the event's amount is what was dealt
	for c in [[1.0, SimWounds.BLOCK_SHOT], [3.0, SimWounds.BLOCK_SHOT_HEAVY], [null, SimWounds.BLOCK_SHOT_HEAVY]]:
		for r in range(4):
			f.wear[r] = 0
		SimWounds.updateStages(S, f)
		f.stance = 1.0
		f.state = "free"
		S.out.fx.clear()
		var o := {"kind": "blast", "stop": 0.0, "shake": 3.0}
		if c[0] != null:
			o["shot"] = c[0]
		var dealt: float = SimDamage.hit(S, null, by, f, 20.0, o)
		var e = null
		for q in S.out.fx:
			if q.type == "damage":
				e = q
		var k2: float = SimWounds.wearK(S, f)
		var wantA: int = int(SimMathx.jround(dealt * wd.shotArmShare * k2))
		var wantL: int = int(SimMathx.jround(dealt * wd.guardLegs * k2)) if c[1] == SimWounds.BLOCK_SHOT_HEAVY else 0
		if e == null or e.kind != "blast" or e.region != "arms" or dealt <= 0.0 or f.wear[A] != wantA or f.wear[L] != wantL:
			return "a guarded shot of power %s wore the arms %d (expected %d) and the legs %d (expected %d)" % [str(c[0]), f.wear[A], wantA, f.wear[L], wantL]
	# an unguarded shot is not a blocked one: its wear lands by the spread family, whole
	for r in range(4):
		f.wear[r] = 0
	SimWounds.updateStages(S, f)
	f.stance = 0.0
	var dealt2: float = SimDamage.hit(S, null, by, f, 20.0, {"kind": "blast", "shot": 1.0, "ignoreStance": true})
	var sum: int = f.wear[0] + f.wear[1] + f.wear[2] + f.wear[3]
	if sum != int(SimMathx.jround(dealt2 * SimWounds.wearK(S, f))):
		return "an unguarded shot wore %d in all, and %d was dealt" % [sum, int(SimMathx.jround(dealt2 * SimWounds.wearK(S, f)))]
	SimCore.dispose(S)
	return ""


## The view's particles carry a depth (SimFxView.Part.z): the event's z, on every kind the view spawns, and a damage
## number its hit's. A part does not move in depth and nothing else about it depends on its depth: with depth off the
## same events on the plane and at a depth make the same parts but for z, tick after tick. With depth on, a debris part
## lands on the ground at its depth, not on the plane's.
func _partDepth() -> String:
	var runs: Array = []
	for z in [0.0, -1000.0]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
		var V := SimFxView.new(5)
		var f = S.fighters[0]
		var g: float = WorldTerrain.groundY(S, f.x)
		S.out.fx.clear()
		f.z = z   # the after-image and the charge take their depth from the fighter
		f.y = g   # on the ground, so the charge raises dust
		SimFx.spark(S, f.x, g + 200.0, 12, "#ffffff", 600.0, z)
		SimFx.debris(S, f.x, g + 40.0, 10, "#666666", 600.0, z)
		SimFx.dust(S, f.x, g, 6, "#998877", z)
		SimFx.splash(S, f.x, g, 5, z)
		SimFx.fire(S, f.x, g, 5, z)
		SimFx.ring(S, f.x, g + 34.0, 1300.0, "#ffffff", 0.8, 20.0, z)
		SimFx.afterimage(S, f)
		for n in range(200):
			SimFx.chargeFx(S, f, g)
			SimFx.beamSplash(S, f.x, z)
		SimFx.damage(S, f, null, 12.0, "core", "light", "#ffffff", true)
		V.consume(S, S.out.fx)
		var kinds := {}
		for p in V.parts:
			kinds[p.type] = int(kinds.get(p.type, 0)) + 1
			if p.z != z:
				return "a %s part made at depth %s reads %s" % [p.type, str(z), str(p.z)]
		for k in ["spark", "deb", "dust", "splash", "flame", "ring", "after"]:
			if int(kinds.get(k, 0)) == 0:
				return "the view made no %s part" % k
		if kinds["spark"] <= 12 or kinds["splash"] <= 5 or kinds["dust"] <= 6:
			return "the charge or the beam's splash made no part"
		if V.floats.size() != 1 or V.floats[0].z != z:
			return "the damage number's depth reads %s" % ("nothing" if V.floats.is_empty() else str(V.floats[0].z))
		var sig: Array = []
		for t in range(100):
			S.out.fx.clear()
			SimFx.tickMark(S, SimConst.DT, false)
			V.consume(S, S.out.fx)
			for p in V.parts:
				if p.z != z:
					return "tick %d: a %s part moved in depth to %s" % [t, p.type, str(p.z)]
				sig.append("%s %s %s %s %s %s" % [p.type, str(p.x), str(p.y), str(p.vx), str(p.vy), str(p.age)])
		runs.append(sig)
		SimCore.dispose(S)
	if runs[0].size() == 0 or runs[0] != runs[1]:
		return "with depth off, the same events on the plane and at a depth made different parts (%d and %d records)" % [runs[0].size(), runs[1].size()]
	# depth on: the plane's ground lowered under the debris, the rows of ground at its depth left as they are
	var D := SimCore.createSim()
	SimCore.newMatch(D, 5, {"p1": false, "p2": false}, {"intro": false, "depth": true})
	if not D.depthOn or D.deformZ.is_empty():
		return "the setup's depth did not give the rows of ground"
	var W := SimFxView.new(5)
	var x: float = D.fighters[0].x
	var zd: float = -1050.0
	var c: int = int(floor(SimWrap.wrap(x) / SimConst.COL))
	for i in range(c - 70, c + 71):
		D.deform[posmod(i, SimConst.NC)] -= 300.0
	var plane: float = WorldTerrain.groundY(D, x)
	var row: float = WorldTerrain.groundY(D, x, zd)
	if row - plane < 250.0:
		return "the ground at depth reads %s over a plane lowered to %s" % [str(row), str(plane)]
	D.out.fx.clear()
	SimFx.debris(D, x, row + 60.0, 10, "#666666", 500.0, zd)
	W.consume(D, D.out.fx)
	var landed: int = 0
	for t in range(110):
		D.out.fx.clear()
		SimFx.tickMark(D, SimConst.DT, false)
		W.consume(D, D.out.fx)
		for p in W.parts:
			var gz: float = WorldTerrain.groundY(D, p.x, p.z)
			if p.y < gz:
				return "tick %d: a debris part at depth %s is %s under the ground at its depth" % [t, str(p.z), str(gz - p.y)]
			if p.y == gz:
				landed += 1
	if landed == 0:
		return "no debris part came down onto the ground at its depth"
	SimCore.dispose(D)
	return ""


## The tier cap (SimFighter.topTier): 1 plus the ladder's thresholds. The last real step is still taken. On the last tier
## a form set ready by hand is refused by transform, a break asked for raises nothing, and through the sim's own step the
## flag is dropped before the director can start the set piece: no transform or tier_up event, no pause, and the world's
## highest tier stays inside the collateral ceiling's table.
func _tierCap() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var f = S.fighters[0]
	var top: float = SimFighter.topTier(f)
	if top != 1.0 + float(f.ld.thresholds.size()) or top != 4.0:
		return "the ladder's last tier reads %s" % str(top)
	f.y = WorldTerrain.groundY(S, f.x) + 900.0
	# the last real step is taken
	f.tier = top - 1.0
	f.act.breakIn = -1
	f.act.formReady = true
	if not SimFighter.transform(S, f) or f.tier != top or f.act.formReady:
		return "the step to the last tier was not taken (tier %s)" % str(f.tier)
	# on the last tier a ready form is refused, and its gather with it
	f.act.formReady = true
	f.act.breakIn = 30
	if SimFighter.transform(S, f) or f.tier != top or f.act.formReady or f.act.breakIn != -1:
		return "a form on the last tier was taken (tier %s, gather %d)" % [str(f.tier), f.act.breakIn]
	# a break asked for on the last tier raises nothing
	f.act.breakIn = 1
	S.out.fx.clear()
	SimFighter.formBreak(S, f)
	for e in S.out.fx:
		if e.type == "tier_up":
			return "a break on the last tier sent tier_up"
	if f.tier != top or f.act.breakIn != -1:
		return "a break on the last tier raised it to %s" % str(f.tier)
	# through the step, with the form set ready by hand on every tick and the transform asked for
	var press := SimIntent.new()
	press.transform = true
	var quiet := SimIntent.new()
	for t in range(240):
		f.act.formReady = true
		S.out.fx.clear()
		SimCore.step(S, [press, quiet])
		for e in S.out.fx:
			if e.type == "transform" or e.type == "tier_up" or e.type == "transform_ready":
				return "tick %d on the last tier: the sim sent %s" % [t, e.type]
		if f.tier != top or f.act.formReady or f.act.breakIn > 0 or S.world.maxTier > top or S.pause.left != 0:
			return "tick %d on the last tier: tier %s, ready %s, gather %d, the world's highest %s, pause %d" % [t, str(f.tier), str(f.act.formReady), f.act.breakIn, str(S.world.maxTier), S.pause.left]
		if WorldCollateral.ceilingLeft(S) < 0.0:
			return "the collateral ceiling read below 0"
	SimCore.dispose(S)
	return ""


## The third weight (brawl-second-pass.md section 2): what the core decides for a medium blow, beside a light and a
## heavy. Where it lands is its own row (family.medium). On a block it wears as a light. It does not stagger and cannot
## cripple a battered limb. Thrown with a broken arm it has its own multiplier. The event's kind is medium. The weight is
## the exchange's kind when the blow lands (the brawl sets it for each press).
func _mediumWeight() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var a = S.fighters[0]
	var d = S.fighters[1]
	var wd = d.wd
	var A: int = SimWounds.ARMS
	var L: int = SimWounds.LEGS
	if not wd.family.has("medium") or wd.family.medium.size() != 4:
		return "the wounds data has no family.medium row"
	var reset := func() -> void:
		for f in [a, d]:
			for r in range(4):
				f.wear[r] = 0
			SimWounds.updateStages(S, f)
			f.stunTicks = 0
			f.limbBreaks = 0
			f.state = "free"
			f.stance = 0.0
		S.out.fx.clear()
	var mk := func(kind: String, guard: bool):
		var ex = DirExchange.newEx(a, d, kind)
		ex.tpl = "brawl"
		ex.sA = 0.0
		ex.sD = 1.0 if guard else 0.0
		d.stance = ex.sD
		return ex
	var last := func():
		var e = null
		for q in S.out.fx:
			if q.type == "damage":
				e = q
		return e
	# where it lands: its own row
	reset.call()
	var sum: float = 0.0
	for x in wd.family.medium:
		sum += x
	var counts: Array = [0, 0, 0, 0]
	for n in range(3200):
		counts[SimWounds.pickRegion(S, d, "medium")] += 1
	for r in range(4):
		if absf(float(counts[r]) / 3200.0 - wd.family.medium[r] / sum) > 0.04:
			return "a medium picked the %s %d times in 3200, and its row says %s in %s" % [SimWounds.REGIONS[r], counts[r], str(wd.family.medium[r]), str(sum)]
	for kind in ["light", "medium", "heavy"]:
		# landed: the family and the event's kind
		reset.call()
		var ex = mk.call(kind, false)
		if SimWounds.family(ex, d, {}, ex.sD) != kind:
			return "a landed %s takes the wound family %s" % [kind, SimWounds.family(ex, d, {}, ex.sD)]
		var dealt: float = SimDamage.hit(S, ex, a, d, 10.0, {})
		var e = last.call()
		if dealt <= 0.0 or e == null or e.kind != kind or e.mode != "brawl" or e.weight != kind:
			return "a landed %s sent a damage event of kind %s and weight %s" % [kind, "none" if e == null else e.kind, "none" if e == null else e.weight]
		# a battered head: only a heavy staggers (a medium's short reel is the director's)
		reset.call()
		d.wear[SimWounds.HEAD] = wd.stageAt[1] + 6000
		SimWounds.updateStages(S, d)
		d.stunTicks = 0
		ex = mk.call(kind, false)
		SimDamage.hit(S, ex, a, d, 10.0, {"region": "core"})
		if not SimWounds.battered(d, SimWounds.HEAD) or (d.stunTicks > 0) != (kind == "heavy"):
			return "a landed %s on a fighter with a battered head left a stagger of %d ticks" % [kind, d.stunTicks]
		# blocked: a medium wears as a light (its share to the arms, nothing to the legs); a heavy splits
		reset.call()
		ex = mk.call(kind, true)
		var k: float = SimWounds.wearK(S, d)
		dealt = SimDamage.hit(S, ex, a, d, 10.0, {})
		var asLight: bool = kind != "heavy"
		var wantA: int = int(SimMathx.jround(dealt * (wd.blockArmShare if asLight else wd.guardArms) * k))
		var wantL: int = 0 if asLight else int(SimMathx.jround(dealt * wd.guardLegs * k))
		e = last.call()
		if e != null and e.weight != kind:
			return "a blocked %s sent a damage event of weight %s" % [kind, e.weight]
		if e == null or e.kind != "guard" or wantA <= 0 or d.wear[A] != wantA or d.wear[L] != wantL:
			return "a blocked %s wore the arms %d (expected %d) and the legs %d (expected %d)" % [kind, d.wear[A], wantA, d.wear[L], wantL]
		# a battered arm: only a heavy marks it for the crippling roll
		reset.call()
		d.wear[A] = wd.stageAt[1] + 6000
		SimWounds.updateStages(S, d)
		ex = mk.call(kind, false)
		SimWounds.onExchangeStart(S, ex)
		SimDamage.hit(S, ex, a, d, 10.0, {"region": "arms"})
		if d.stage[A] != 2 or (ex.cripR == A) != (kind == "heavy"):
			return "a %s on a battered arm left the crippling mark at %d" % [kind, ex.cripR]
		# thrown with a broken arm: each weight's own multiplier
		reset.call()
		ex = mk.call(kind, false)
		var whole: float = SimDamage.hit(S, ex, a, d, 10.0, {"region": "core"})
		reset.call()
		a.wear[A] = a.wd.stageAt[2]
		SimWounds.updateStages(S, a)
		ex = mk.call(kind, false)
		var broken: float = SimDamage.hit(S, ex, a, d, 10.0, {"region": "core"})
		var mul: float = a.wd.armsBrokenMul if kind == "heavy" else (a.wd.armsBrokenMediumMul if kind == "medium" else a.wd.armsBrokenLightMul)
		if not SimWounds.broken(a, A) or whole <= 0.0 or absf(broken - whole * mul) > 0.000000001 * whole:
			return "a %s thrown with a broken arm did %s against %s whole, and its multiplier is %s" % [kind, str(broken), str(whole), str(mul)]
		# the medium's multiplier is its own key: moved for one blow, only a medium follows it
		var keep: float = a.wd.armsBrokenMediumMul
		a.wd.armsBrokenMediumMul = 0.5
		ex = mk.call(kind, false)
		var moved: float = SimDamage.hit(S, ex, a, d, 10.0, {"region": "core"})
		a.wd.armsBrokenMediumMul = keep
		if absf(moved - whole * (0.5 if kind == "medium" else mul)) > 0.000000001 * whole:
			return "with the medium's broken-arm multiplier at 0.5, a %s did %s against %s whole" % [kind, str(moved), str(whole)]
	# a blocked hit loses a weight named on its form: it feeds the mood nothing
	reset.call()
	d.stance = 1.0
	SimDamage.hit(S, null, a, d, 10.0, {"kind": "blast", "shot": 1.0, "form": "brawl_light"})
	var be = last.call()
	if be == null or be.kind != "blast" or be.mode != "" or be.weight != "":
		return "a blocked point-blank shot kept its form (%s)" % ("none" if be == null else be.mode)
	d.stance = 0.0
	SimDamage.hit(S, null, a, d, 10.0, {"kind": "blast", "shot": 1.0, "form": "brawl_light"})
	be = last.call()
	if be == null or be.kind != "blast" or be.mode != "brawl_light":
		return "a landed point-blank shot lost its form"
	SimCore.dispose(S)
	return ""


## A blow that names its region (the option region on SimDamage.hit): a landed blow wears that region and no other, its
## event names it, and no region is drawn (the seeded stream does not move). A blocked blow ignores the name: the block's
## rule decides. A name that is not a region is drawn as usual.
func _namedRegion() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var a = S.fighters[0]
	var d = S.fighters[1]
	var reset := func() -> void:
		for r in range(4):
			d.wear[r] = 0
		SimWounds.updateStages(S, d)
		d.stunTicks = 0
		d.state = "free"
		S.out.fx.clear()
	var last := func():
		var e = null
		for q in S.out.fx:
			if q.type == "damage":
				e = q
		return e
	for r in range(4):
		reset.call()
		d.stance = 0.0
		var rng0: int = S.rng.state_i32()
		var k: float = SimWounds.wearK(S, d)
		var dealt: float = SimDamage.hit(S, null, a, d, 10.0, {"region": SimWounds.REGIONS[r], "ignoreStance": true})
		var e = last.call()
		var want: int = int(SimMathx.jround(dealt * k))
		for q in range(4):
			if want <= 0 or d.wear[q] != (want if q == r else 0):
				return "a blow naming the %s wore the %s by %d" % [SimWounds.REGIONS[r], SimWounds.REGIONS[q], d.wear[q]]
		if e == null or e.region != SimWounds.REGIONS[r] or S.rng.state_i32() != rng0:
			return "a blow naming the %s reported %s, or drew a region" % [SimWounds.REGIONS[r], "nothing" if e == null else e.region]
	# with no name, and with a name that is not a region, the region is drawn
	for o in [{"ignoreStance": true}, {"region": "tail", "ignoreStance": true}]:
		reset.call()
		var rng1: int = S.rng.state_i32()
		var k2: float = SimWounds.wearK(S, d)
		var dealt2: float = SimDamage.hit(S, null, a, d, 10.0, o)
		var e2 = last.call()
		if S.rng.state_i32() == rng1 or e2 == null or not SimWounds.REGIONS.has(e2.region) or d.wear[0] + d.wear[1] + d.wear[2] + d.wear[3] != int(SimMathx.jround(dealt2 * k2)):
			return "a blow with %s did not draw its region" % ("no name" if not o.has("region") else "a name that is no region")
	# blocked: the name is ignored
	reset.call()
	d.stance = 1.0
	SimDamage.hit(S, null, a, d, 10.0, {"region": "head"})
	var eb = last.call()
	if eb == null or eb.kind != "guard" or eb.region != "arms" or d.wear[SimWounds.HEAD] != 0 or d.wear[SimWounds.ARMS] <= 0:
		return "a blocked blow naming the head reported %s and wore the head %d" % ["nothing" if eb == null else eb.region, d.wear[SimWounds.HEAD]]
	SimCore.dispose(S)
	return ""


## The stick as held (f.heldMx, f.heldMy): what the player holds this tick, recorded before the stun's gate. A stunned
## fighter's intent loses its stick, as before, and he does not move by it; the record keeps it, and it is in the hash.
## A launched or a dropped fighter's record is blank: nobody steers a knock-back.
func _heldStick() -> String:
	var hold := SimIntent.new()
	hold.mx = 0.6
	hold.my = -0.4
	var other := SimIntent.new()
	other.mx = -1.0
	other.my = 0.25
	var quiet := SimIntent.new()
	var H: Array = []
	for stick in [hold, other]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
		var f = S.fighters[0]
		f.y = WorldTerrain.groundY(S, f.x) + 900.0
		SimCore.step(S, [stick, quiet])
		if f.heldMx != stick.mx or f.heldMy != stick.my or f.input.mx != stick.mx:
			return "a free fighter's held stick reads %s,%s and his intent %s" % [str(f.heldMx), str(f.heldMy), str(f.input.mx)]
		f.vx = 0.0
		f.vy = 0.0
		f.stunTicks = 12
		var x0: float = f.x
		var y0: float = f.y
		for t in range(8):
			SimCore.step(S, [stick, quiet])
			if f.input.mx != 0.0 or f.input.my != 0.0 or f.heldMx != stick.mx or f.heldMy != stick.my:
				return "stunned, tick %d: his intent's stick is %s,%s and the held stick %s,%s" % [t, str(f.input.mx), str(f.input.my), str(f.heldMx), str(f.heldMy)]
		if f.x != x0 or f.y != y0 or f.stunTicks != 4:
			return "a stunned fighter moved by his stick (%s, %s), or his stun did not count down (%d left)" % [str(SimWrap.sdx(x0, f.x)), str(f.y - y0), f.stunTicks]
		H.append(SimHash.stateHash(S).gameplay)
		for st in ["launched", "dropped"]:
			f.state = st
			SimWounds.gateIntent(f, stick)
			if f.heldMx != 0.0 or f.heldMy != 0.0:
				return "a %s fighter's held stick reads %s,%s" % [st, str(f.heldMx), str(f.heldMy)]
		f.state = "free"
		SimWounds.gateIntent(f, stick)
		if f.heldMx != stick.mx or f.heldMy != stick.my:
			return "free again, the held stick did not come back"
		SimCore.dispose(S)
	if H[0] == H[1]:
		return "two stunned fighters holding different sticks hash the same: the held stick is not in the hash"
	return ""


## Two reads for the director (Encounter's control slice). SimFighter.flightSpeed is what a free fighter's step steers
## toward: from rest with the stick held, one step's velocity is the stick times it times the step's easing, by tier,
## stance, battered legs, the dash near and far, and the sea. SimFighter.lockedKeep(dt) is the share of his speed a locked
## fighter keeps over a step: he moves by that share of what he had, and keeps it.
func _flightReads() -> String:
	var dt: float = SimConst.DT
	var ease: float = 1.0 - SimDetMath.pow(0.0008, dt)
	var seen := {}
	for c in [[1.0, 0.0, false, false, 600.0], [3.0, 1.0, false, false, 600.0], [2.0, 2.0, true, false, 600.0], [1.0, 3.0, false, true, 600.0], [4.0, 0.0, false, true, 6000.0]]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
		var f = S.fighters[0]
		var o = S.fighters[1]
		f.y = WorldTerrain.groundY(S, f.x) + 900.0
		o.x = SimWrap.wrap(f.x + c[4])
		f.tier = c[0]
		f.stance = c[1]
		if c[2]:
			f.wear[SimWounds.LEGS] = f.wd.stageAt[1] + 6000
			SimWounds.updateStages(S, f)
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
		f.input.mx = 1.0
		f.input.my = 0.0
		f.input.dash = c[3]
		f.input.charge = false
		var want: float = SimFighter.flightSpeed(S, f, c[3])
		seen[want] = true
		SimFighter.stepFighter(S, f, dt)
		if want <= 0.0 or absf(f.vx - want * ease) > 0.000000001 * want:
			return "tier %s, stance %s, dash %s: one step from rest gave a speed of %s, and flightSpeed says %s" % [str(c[0]), str(c[1]), str(c[3]), str(f.vx / ease), str(want)]
		SimCore.dispose(S)
	if seen.size() < 5:
		return "flightSpeed gave the same speed for different tiers, stances and dashes"
	var L := SimCore.createSim()
	SimCore.newMatch(L, 5, {"p1": false, "p2": false}, {"intro": false})
	var g = L.fighters[0]
	g.y = WorldTerrain.groundY(L, g.x) + 900.0
	g.state = "locked"
	g.vx = 300.0
	g.vy = -120.0
	var x0: float = g.x
	var y0: float = g.y
	var keep: float = SimFighter.lockedKeep(dt)
	SimFighter.stepFighter(L, g, dt)
	if keep <= 0.9 or keep >= 1.0 or g.vx != 300.0 * keep or g.vy != -120.0 * keep or absf(SimWrap.sdx(x0, g.x) - 300.0 * keep * dt) > 0.000000001 or absf(g.y - y0 - (-120.0 * keep * dt)) > 0.000000001:
		return "a locked fighter kept %s of his speed in a step and lockedKeep says %s" % [str(g.vx / 300.0), str(keep)]
	SimCore.dispose(L)
	return ""


## The mood by a blow's form (melee-press-feel.md section 9d, ruling 2): each kind of blow adds its own impulse, read from
## this tick's events; a strike of a planned exchange outside a brawl is still strike or heavyStrike; the AGGRESSIVE
## multiplier applies to who did it.
func _moodForms() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var a = S.fighters[0]
	var b = S.fighters[1]
	var I: Dictionary = SimMood.imp
	for key in ["brawlLight", "brawlMedium", "blocked", "skillStrike", "brawlHeavy", "flurryClose", "guardBreak", "knockback"]:
		if not I.has(key):
			return "mood.json impulses." + key + " is not loaded"
	if I.brawlLight[0] <= 0 or I.brawlLight[0] >= I.strike[0] or I.brawlHeavy[0] >= I.heavyStrike[0] or I.blocked[0] != 0:
		return "a brawl's blow should feed the mood less than a planned strike, and a blocked one nothing"
	# what one tick adds with these events, over what the same tick adds with none
	var gain := func(make: Callable) -> int:
		var out: Array = [0, 0]
		for pass_ in range(2):
			S.mood.v = SimMood.mood.range / 2
			S.out.fx.clear()
			if pass_ == 1:
				make.call()
			var v0: int = S.mood.v
			SimMood.tick(S)
			out[pass_] = S.mood.v - v0
		S.out.fx.clear()
		return out[1] - out[0]
	var cue := func(name: String, text: String) -> void:
		SimFx.cue(S, b, name, text, "")
		S.out.fx[S.out.fx.size() - 1].target = 0.0
	for aggressive in [false, true]:
		a.stance = 0.0 if aggressive else 1.0
		b.stance = 1.0
		var col: int = 1 if aggressive else 0
		var cases: Array = [
			["brawlLight", func(): SimFx.damage(S, b, a, 5.0, "core", "light", "", true, "brawl")],
			["brawlHeavy", func(): SimFx.damage(S, b, a, 5.0, "core", "heavy", "", true, "brawl")],
			["brawlMedium", func(): SimFx.damage(S, b, a, 5.0, "core", "medium", "", true, "brawl")],
			["strike", func(): SimFx.damage(S, b, a, 5.0, "core", "medium", "", true)],   # a medium outside a brawl is a strike
			["brawlLight", func(): SimFx.damage(S, b, a, 5.0, "core", "blast", "", true, "brawl_light")],    # a weight named on the form:
			["brawlMedium", func(): SimFx.damage(S, b, a, 5.0, "core", "blast", "", true, "brawl_medium")],   # a point-blank shot
			["brawlHeavy", func(): SimFx.damage(S, b, a, 5.0, "core", "blast", "", true, "brawl_heavy")],
			["skillStrike", func(): SimFx.damage(S, b, a, 5.0, "core", "light", "", true, "skill")],
			["strike", func(): SimFx.damage(S, b, a, 5.0, "core", "light", "", true)],
			["heavyStrike", func(): SimFx.damage(S, b, a, 5.0, "core", "heavy", "", true)],
			["blocked", func(): SimFx.damage(S, b, a, 5.0, "arms", "guard", "", true, "brawl")],
			["flurryClose", func(): cue.call("stagger", "flurry")],
			["guardBreak", func(): cue.call("guard_break", "")],
			["knockback", func(): SimFx.knockback(S, b, a, "short", 300.0, S.tick + 12)],
		]
		for c in cases:
			var got: int = gain.call(c[1])
			if got != I[c[0]][col]:
				return "%s%s added %d to the mood, the data says %d" % [c[0], " (AGGRESSIVE)" if aggressive else "", got, I[c[0]][col]]
		# the director's double hit is the clash's units, whoever sends it and whatever his stance
		if gain.call(func(): cue.call("double_hit", "")) != I.clash[0]:
			return "the double hit's cue did not add the clash's %d" % I.clash[0]
		# a shot with no weight named, and a form the mood does not know, feed nothing
		if gain.call(func(): SimFx.damage(S, b, a, 5.0, "core", "blast", "", true)) != 0 or gain.call(func(): SimFx.damage(S, b, a, 5.0, "core", "blast", "", true, "brawl_huge")) != 0:
			return "a shot with no weight named fed the mood"
		# a knock-back with no attacker (the double hit throws both back) is nobody's blow and adds nothing
		if gain.call(func(): SimFx.knockback(S, b, null, "short", 300.0, S.tick + 12)) != 0:
			return "a knock-back with no attacker fed the mood"
		# a lone heavy's stagger is not a flurry's close, and a blow with no number is nothing
		if gain.call(func(): cue.call("stagger", "heavy")) != 0 or gain.call(func(): SimFx.damage(S, b, a, 5.0, "core", "light", "", false, "brawl")) != 0:
			return "a heavy's stagger or an unnumbered blow fed the mood"
	SimCore.dispose(S)
	return ""


## The mood's form impulse: a transformation's break adds impulses.form to the mood, by a call (SimMood.onForm) and not
## from the tier_up event, so it is also given when the break lands on a frozen tick inside a full pause.
func _formImpulse() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5)
	var a = S.fighters[0]
	a.stance = 1.0   # not AGGRESSIVE: the plain impulse
	var want: int = SimMood.imp["form"][0]
	if want <= 0:
		return "mood.json impulses.form is 0"
	a.power = a.ld.thresholds[0] + 1.0
	a.act.formReady = true
	a.y = 20000.0
	S.pause.bank = SimPause.bankMax
	var r: Dictionary = SimPause.request(S, SimPause.TRANSFORM, 0)
	SimFighter.transform(S, a)
	if r.version != SimPause.FULL:
		return "the set-up did not give a full pause"
	var v0: int = S.mood.v
	var g: int = SimPause.gather[SimPause.FULL]
	for t in range(1, g + 1):
		if SimCore.step(S, null):
			return "tick %d of the pause was live" % t
		if S.mood.v != (v0 + want if t == g else v0):
			return "at paused tick %d the mood is %d (it was %d; the impulse is %d and the gather %d)" % [t, S.mood.v, v0, want, g]
	SimCore.dispose(S)
	return ""


## The break (moveset-rules.md section 10.8): a transformation's tier-up lands at the end of the version's gather, not on
## the request tick. Full and short: on a frozen tick inside the pause, exactly the gather after the request, with its
## tier_up there. Live: after the gather in live ticks. A second fighter's live gather starts when the first one's pause
## ends. A taken step cannot be taken again during its gather. No break once the match is over. A further step already
## earned is ready at the break, with its transform_ready.
func _formBreak() -> String:
	var ready := func(f) -> void:
		f.power = f.ld.thresholds[0] + 1.0
		f.act.formReady = true
		f.y = 20000.0   # airborne: no crater
	var take := func(S0: SimState, slot: int, bank: int) -> Dictionary:
		S0.pause.bank = bank
		var r0: Dictionary = SimPause.request(S0, SimPause.TRANSFORM, slot)
		SimFighter.transform(S0, S0.fighters[slot])
		return r0
	var tierUps := func(S0: SimState) -> int:
		var n: int = 0
		for e in S0.out.fx:
			if e.type == "tier_up":
				n += 1
		return n
	for version in [SimPause.FULL, SimPause.SHORT]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5)
		var a = S.fighters[0]
		ready.call(a)
		if version == SimPause.SHORT:
			S.pause.seen = 1   # a repeat
		var r: Dictionary = take.call(S, 0, SimPause.bankMax)
		var g: int = SimPause.gather[version]
		if r.version != version or a.tier != 1.0 or a.act.breakIn != g or a.act.formReady or SimFighter.transform(S, a):
			return "%s: after the request tier %s, breakIn %d, ready %s" % [SimPause.VERSIONS[version], str(a.tier), a.act.breakIn, str(a.act.formReady)]
		for t in range(1, int(r.ticks) + 1):
			S.out.fx.clear()
			if SimCore.step(S, null):
				return "%s: tick %d of the pause was live" % [SimPause.VERSIONS[version], t]
			var want: float = 2.0 if t >= g else 1.0
			if a.tier != want or tierUps.call(S) != (1 if t == g else 0):
				return "%s: at paused tick %d the tier is %s and %d tier_up events (the gather is %d)" % [SimPause.VERSIONS[version], t, str(a.tier), tierUps.call(S), g]
		if a.act.breakIn != -1:
			return "%s: breakIn %d after the pause" % [SimPause.VERSIONS[version], a.act.breakIn]
		SimCore.dispose(S)
	# live, and a second fighter whose gather waits for the first one's pause
	var L := SimCore.createSim()
	SimCore.newMatch(L, 5)
	var k = L.fighters[0]
	var v = L.fighters[1]
	ready.call(k)
	ready.call(v)
	var r1: Dictionary = take.call(L, 0, SimPause.bankMax)
	var r2: Dictionary = take.call(L, 1, L.pause.bank)
	if r1.version != SimPause.FULL or r2.version != SimPause.LIVE or v.act.breakIn != SimPause.gather[SimPause.LIVE]:
		return "two requests on one tick: %s then %s" % [str(r1), str(r2)]
	for t in range(int(r1.ticks)):
		SimCore.step(L, null)
	if k.tier != 2.0 or v.tier != 1.0 or v.act.breakIn != SimPause.gather[SimPause.LIVE]:
		return "the second fighter's gather ran during the first one's pause (tier %s, breakIn %d)" % [str(v.tier), v.act.breakIn]
	var live: int = 0
	while v.tier == 1.0 and live < 200:
		if SimCore.step(L, null):
			live += 1
	if live != SimPause.gather[SimPause.LIVE]:
		return "a live break came after %d live ticks, not %d" % [live, SimPause.gather[SimPause.LIVE]]
	# a further step already earned is ready at the break
	k.power = k.ld.thresholds[2] + 0.0
	k.act.formReady = true
	L.pause.sinceEnd = 0
	take.call(L, 0, 0)
	L.out.fx.clear()
	var again: int = 0
	live = 0
	while k.tier == 2.0 and live < 200:
		L.out.fx.clear()
		if SimCore.step(L, null):
			live += 1
	for e in L.out.fx:
		if e.type == "transform_ready" and int(e.actor) == 0 and e.tier == 4.0:
			again += 1
	if k.tier != 3.0 or not k.act.formReady or again != 1:
		return "a further earned step at the break: tier %s, ready %s, %d transform_ready events" % [str(k.tier), str(k.act.formReady), again]
	SimCore.dispose(L)
	# no break once the match is over
	var E := SimCore.createSim()
	SimCore.newMatch(E, 5)
	var e0 = E.fighters[0]
	ready.call(e0)
	take.call(E, 0, 0)
	E.game.ko = E.fighters[1]
	for t in range(60):
		SimCore.step(E, null)
	if e0.tier != 1.0:
		return "the break landed after the KO"
	SimCore.dispose(E)
	return ""


## Q10: the act rule under actBeats.formSteps (1 + the larger of form steps and wound beats, + region breaks, capped), a
## form step announced as an act with cause form, and the finisher contest with no survival from the time cap (both
## contest paths; before the cap the chance is above 0).
func _actRule() -> String:
	if not SimMood.formSteps:
		return "mood.json actBeats.formSteps is off"
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5)
	var a = S.fighters[0]
	var b = S.fighters[1]
	var m = S.mood
	var cases: Array = [   # [tier a, tier b, once mask, breaks, act]
		[1.0, 1.0, 0, 0, 1], [2.0, 1.0, 0, 0, 2], [2.0, 3.0, 0, 0, 3], [1.0, 1.0, 7, 0, 4], [3.0, 1.0, 1, 0, 3],
		[1.0, 1.0, 3, 0, 3], [2.0, 2.0, 1, 1, 3], [3.0, 1.0, 1, 1, 4], [4.0, 4.0, 7, 5, 4], [1.0, 1.0, 0, 2, 3]]
	for c in cases:
		a.tier = c[0]
		b.tier = c[1]
		m.onceMask = c[2]
		m.breaks = c[3]
		if SimMood.act(S) != c[4]:
			return "act for tiers %s and %s, wound beats mask %d, breaks %d is %d, not %d" % [str(c[0]), str(c[1]), c[2], c[3], SimMood.act(S), c[4]]
	a.tier = 1.0
	b.tier = 1.0
	m.onceMask = 0
	m.breaks = 0
	a.act.formReady = true
	a.y = 20000.0   # airborne: no crater
	S.out.fx.clear()
	if not SimFighter.transform(S, a):
		return "the forced transform did not run"
	SimMood.tick(S)
	var cause: String = ""
	for e in S.out.fx:
		if e.type == "act_change":
			cause = "%d %s" % [int(e.n), e.kind]
	if cause != "2 form":
		return "a form step announced '%s', not act 2 with cause form" % cause
	# the contest: no survival from the time cap
	for path in ["plain", "branch"]:
		for capped in [false, true]:
			S.game.timeCap = capped
			S.out.fx.clear()
			var ex := SimState.Exchange.new()
			ex.A = a
			ex.D = b
			if path == "plain":
				DirExchange._opContest(S, ex, {"w": "A"})
			else:
				DirExchange._opContestBranch(S, ex, {"w": "A"})
			var chance: float = -1.0
			var lived: bool = false
			for e in S.out.fx:
				if e.type == "finisher_contest":
					chance = e.chance
					lived = e.survived
			if capped and (chance != 0.0 or lived):
				return "from the time cap the %s contest gave chance %s, survived %s" % [path, str(chance), str(lived)]
			if not capped and chance <= 0.0:
				return "before the time cap the %s contest's chance was %s" % [path, str(chance)]
			S.game.ko = null
	SimCore.dispose(S)
	return ""


## SimReplay (S4): record a scripted two-human run, play it back and play its JSON round trip; a changed input and a
## replay from other combat data must both fail.
func _replayModule() -> String:
	var src: Dictionary = SimGolden.scriptedReplay(13, 1200, true, [600])
	var S := SimCore.createSim()
	var rec := SimReplay.recorder(S, 13, src.ai)
	var cur: Array = [null, null]
	var ii: int = 0
	var ti: int = 0
	for t in range(int(src.ticks)):
		while ti < src.toggles.size() and int(src.toggles[ti][0]) == t:
			rec.toggle(int(src.toggles[ti][1]))
			ti += 1
		while ii < src.inputs.size() and int(src.inputs[ii][0]) == t:
			cur[int(src.inputs[ii][1])] = SimGolden._intent(src.inputs[ii][2])
			ii += 1
		rec.step(cur)
	var rp: Dictionary = rec.finish()
	SimCore.dispose(S)
	var r: Dictionary = SimReplay.play(rp)
	if not r.ok:
		return "playback: %s at tick %d" % [r.reason, r.firstBadTick]
	r = SimReplay.play(JSON.parse_string(JSON.stringify(rp)))
	if not r.ok:
		return "JSON round trip: %s at tick %d" % [r.reason, r.firstBadTick]
	var bad: Dictionary = rp.duplicate(true)
	bad.data = "0"
	if SimReplay.play(bad).reason != "data":
		return "a replay from other combat data was not refused"
	bad = rp.duplicate(true)
	# From the middle on, every record steers the other way: one altered record can fall on ticks where the fighter cannot
	# act, so the change is made to last.
	var at: int = int(floor(bad.inputs.size() / 2.0))
	for q in range(at, bad.inputs.size()):
		if bad.inputs[q][2] == null:
			continue
		var alt: SimIntent = SimIntent.unpack(SimReplay.join(bad.inputs[q][2], bad.inputs[q][3]))
		alt.mx = -1.0 if alt.mx > 0.0 else 1.0
		var two: Array = SimReplay.split(SimIntent.pack(alt))
		bad.inputs[q][2] = two[0]
		bad.inputs[q][3] = two[1]
	if SimReplay.play(bad).ok:
		return "a changed input was not caught"
	# Format v4 refuses an older file, another intent schema, and an input that is not a packed intent.
	for edit in [["v", 3], ["v", 2], ["intent", SimIntent.VERSION + 1], ["intent", SimIntent.VERSION - 1], ["intent", 1]]:
		bad = rp.duplicate(true)
		bad[edit[0]] = edit[1]
		if SimReplay.play(bad).reason != "format":
			return "a replay with %s %s was not refused" % [edit[0], str(edit[1])]
	# an entry above the 53-bit record, one of the old shape, one with half an intent, one with a fraction
	for wrong in [[0, 1 << (SimIntent.BITS - 32)], [1 << 40], [0, null], [0.5, 0]]:
		bad = rp.duplicate(true)
		bad.inputs[at] = [bad.inputs[at][0], bad.inputs[at][1]] + wrong
		if SimReplay.play(bad).reason != "format":
			return "an invalid input entry %s was not refused" % str(wrong)
	# the new fields travel: a recorded match whose human holds the top bits plays back through JSON
	var S4 := SimCore.createSim()
	var rec4 := SimReplay.recorder(S4, 31, {"p1": false, "p2": false})   # two human slots, the second idle: nobody strikes him
	var hold := SimIntent.new()
	var compared: int = 0
	for t in range(240):
		hold.stanceMask = (t / 20) % 16
		hold.contextHeld = (t / 30) % 2 == 1
		hold.sigHeld = (t / 45) % 2 == 0
		var stunned: bool = S4.fighters[0].stunTicks > 0   # a stun ends the held states (SimWounds.gateIntent): such a tick carries none
		var live: bool = rec4.step([hold, null])   # (a hit-stop tick consumes no input)
		if not live or stunned:
			continue
		compared += 1
		if S4.fighters[0].input.stanceMask != hold.stanceMask or S4.fighters[0].input.sigHeld != hold.sigHeld or S4.fighters[0].input.contextHeld != hold.contextHeld:
			return "the stance mask and the held levels did not reach the fighter's input"
	if compared < 200:
		return "only %d of 240 ticks carried the held fields to the fighter's input" % compared
	var rp4: Dictionary = rec4.finish()
	SimCore.dispose(S4)
	var high: int = 0
	for inp in rp4.inputs:
		if inp[3] != null:
			high = maxi(high, int(inp[3]))
	if high < (1 << (SimIntent.BITS - 33)):
		return "the recorded entries never used the record's top bit (high part %d)" % high
	r = SimReplay.play(JSON.parse_string(JSON.stringify(rp4)))
	if not r.ok:
		return "a replay with the version 4 fields: %s at tick %d" % [r.reason, r.firstBadTick]
	# D1a: a replay of a mirror setup plays back from its header alone.
	var S2 := SimCore.createSim()
	var rec2 := SimReplay.recorder(S2, 21, {}, SimGolden.armSetup("mirror-hero-flip"))
	for t in range(900):
		rec2.step(null)
	var rp2: Dictionary = rec2.finish()
	SimCore.dispose(S2)
	r = SimReplay.play(JSON.parse_string(JSON.stringify(rp2)))
	if not r.ok or rp2.setup.get("names", []) != ["PROTAGONIST-A", "PROTAGONIST-B"]:
		return "setup replay: %s at tick %d" % [r.reason, r.firstBadTick]
	# I2a: two v2 slots, their stance following the scripted held fields, record and play back from the header alone.
	var src3: Dictionary = SimGolden.scriptedReplay(17, 900, true, [])
	var S3 := SimCore.createSim()
	var rec3 := SimReplay.recorder(S3, 17, src3.ai, {"v2": [true, true]})
	var cur3: Array = [null, null]
	var i3: int = 0
	var stances := {}
	for t in range(int(src3.ticks)):
		while i3 < src3.inputs.size() and int(src3.inputs[i3][0]) == t:
			cur3[int(src3.inputs[i3][1])] = SimGolden._intent(src3.inputs[i3][2])
			i3 += 1
		rec3.step(cur3)
		stances[S3.fighters[0].stance] = true
	var rp3: Dictionary = rec3.finish()
	SimCore.dispose(S3)
	r = SimReplay.play(JSON.parse_string(JSON.stringify(rp3)))
	if not r.ok:
		return "v2 replay: %s at tick %d" % [r.reason, r.firstBadTick]
	if stances.size() < 3:
		return "the v2 replay's derived stance took only %d values" % stances.size()
	return ""


## D1a: the roster data load clean, and their canonical hash matches the goldens (a data edit shows here by name).
func _roster(g: Dictionary) -> String:
	if not FighterData.errors().is_empty():
		return "data/fighters: " + "; ".join(FighterData.errors())
	if FighterData.order() != ["PROTAGONIST", "RIVAL", "REFERENCE"]:
		return "roster order " + str(FighterData.order())
	if FighterData.dataHash() != g.get("rosterHash", ""):
		return "the roster data hash differs (data/fighters/ changed): %s vs golden %s; regenerate the goldens if the edit is meant" % [FighterData.dataHash(), g.get("rosterHash", "")]
	return ""


## The text of one of a fighter's four files, for the fixtures below: his own file where he has one, and the game's
## (data/fight/) for a wounds.json or ladder.json he does not have. A fixture fighter then carries a full copy, laid
## over the game's file by the loader: the same keys, so every edit a fixture makes shows.
func _fighterText(id: String, fname: String) -> String:
	var own: String = FighterData.ROOT + id + "/" + fname
	if FileAccess.file_exists(own) or not (fname == "wounds.json" or fname == "ladder.json"):
		return FileAccess.get_file_as_string(own)
	return FileAccess.get_file_as_string(FighterData.SHARED + fname)


## The game's wounds model and ladder are one file each (docs/architecture/fighters-as-data.md, window 1): a fighter with
## no file of his own resolves to the game's; his own file replaces one leaf and nothing else; a list is replaced whole; a
## key the game's file does not have is refused; a note is free; and the roster's hash is the hash of what each fighter
## resolves to, so a full copy in his folder, or none, hash alike.
func _sharedFiles() -> String:
	for id in FighterData.order():
		for fname in ["wounds.json", "ladder.json"]:
			if FileAccess.file_exists(FighterData.ROOT + id + "/" + fname):
				return "%s has a %s of his own: this check is for a roster with no differences" % [id, fname]
	if not FileAccess.file_exists(FighterData.SHARED + "wounds.json") or not FileAccess.file_exists(FighterData.SHARED + "ladder.json"):
		return "data/fight/wounds.json or ladder.json is missing"
	var h0: String = FighterData.dataHash()
	var wd0 = FighterData.def("PROTAGONIST").wd
	var w0: float = wd0.wearPerDamage
	var light0: Array = wd0.family.light.duplicate()
	var crip0: float = wd0.cripBase
	var taken0: float = FighterData.def("PROTAGONIST").ld.taken
	if FighterData.def("RIVAL").wd.wearPerDamage != w0 or FighterData.def("RIVAL").ld.taken != taken0:
		return "the two fighters resolve to different numbers with no file of their own"
	var out: String = ""
	FighterData.quiet = true
	var mk := func(tag: String, files: Dictionary) -> String:
		var dir: String = "user://shared_files/%s/" % tag
		for id in FighterData.order():
			DirAccess.make_dir_recursive_absolute(dir + id)
			for fname in ["fighter.json", "meters.json"]:
				if not FileAccess.file_exists(FighterData.ROOT + id + "/" + fname):
					continue
				var fw := FileAccess.open(dir + id + "/" + fname, FileAccess.WRITE)
				fw.store_string(_fighterText(id, fname))
				fw.close()
			for fname in ["wounds.json", "ladder.json"]:
				if FileAccess.file_exists(dir + id + "/" + fname):
					DirAccess.remove_absolute(dir + id + "/" + fname)
		for key in files:
			var fo := FileAccess.open(dir + key, FileAccess.WRITE)
			fo.store_string(files[key])
			fo.close()
		var rf := FileAccess.open(dir + "roster.json", FileAccess.WRITE)
		rf.store_string(JSON.stringify(FighterData.order()))
		rf.close()
		return dir
	# no file of his own: the game's, and the same hash
	FighterData.loadFrom(mk.call("none", {}))
	if not FighterData.errors().is_empty() or FighterData.dataHash() != h0:
		out = "a roster with no wounds or ladder file of its own: %s" % ("; ".join(FighterData.errors()) if not FighterData.errors().is_empty() else "the hash differs")
	# a full copy in each folder: the same hash again
	if out == "":
		var full := {}
		for id in FighterData.order():
			for fname in ["wounds.json", "ladder.json"]:
				full[id + "/" + fname] = FileAccess.get_file_as_string(FighterData.SHARED + fname)
		FighterData.loadFrom(mk.call("full", full))
		if not FighterData.errors().is_empty() or FighterData.dataHash() != h0:
			out = "a full copy of both files in each folder does not hash as none"
	# his own file with one number, one nested number, one list and a note: those change for him, and nothing else, for nobody else
	if out == "":
		FighterData.loadFrom(mk.call("diff", {"RIVAL/wounds.json": "{\"_note\": \"his own\", \"wearPerDamage\": 123.0, \"cripple\": {\"base\": 0.5}, \"family\": {\"light\": [1.0, 2.0, 3.0, 4.0]}}", "RIVAL/ladder.json": "{\"takenPerDamage\": 0.25}"}))
		var rw = FighterData.def("RIVAL").wd
		var pw = FighterData.def("PROTAGONIST").wd
		if not FighterData.errors().is_empty():
			out = "a fighter's own differences were refused: " + "; ".join(FighterData.errors())
		elif rw.wearPerDamage != 123.0 or rw.cripBase != 0.5 or rw.family.light != [1.0, 2.0, 3.0, 4.0] or FighterData.def("RIVAL").ld.taken != 0.25:
			out = "a fighter's own differences did not reach him"
		elif rw.focusWear != wd0.focusWear or rw.cripTierAhead != wd0.cripTierAhead or rw.family.heavy != wd0.family.heavy or FighterData.def("RIVAL").ld.dealt != FighterData.def("PROTAGONIST").ld.dealt:
			out = "a fighter's own differences changed a number they do not name"
		elif pw.wearPerDamage != w0 or pw.cripBase != crip0 or pw.family.light != light0 or FighterData.def("PROTAGONIST").ld.taken != taken0:
			out = "one fighter's differences reached the other"
		elif FighterData.dataHash() == h0:
			out = "a fighter's own differences did not change the data hash"
	# a key the game's file does not have is refused, at the top and inside
	if out == "":
		FighterData.loadFrom(mk.call("typo", {"RIVAL/wounds.json": "{\"wearPerDamge\": 123.0}"}))
		if not "; ".join(FighterData.errors()).contains("wearPerDamge is not a key"):
			out = "a misspelt key in a fighter's own file was not refused"
	if out == "":
		FighterData.loadFrom(mk.call("typo2", {"RIVAL/wounds.json": "{\"cripple\": {\"bass\": 0.5}}"}))
		if not "; ".join(FighterData.errors()).contains("cripple.bass is not a key"):
			out = "a misspelt key inside a fighter's own file was not refused"
	# with no game's file (a fixture folder that is the whole), a fighter needs his own
	if out == "":
		FighterData.loadFrom(mk.call("alone", {}), "")
		if not "; ".join(FighterData.errors()).contains("the game's wounds.json is missing too"):
			out = "a fighter with no wounds file anywhere was not refused"
	FighterData.quiet = false
	FighterData.loadFrom()
	if out == "" and (FighterData.dataHash() != h0 or not FighterData.errors().is_empty()):
		out = "reloading data/fighters/ changed the hash"
	return out


## The training dummy (fighter-pipeline.md section 8): the reference fighter, in the roster, last. His numbers are frozen:
## base stats, no care, no meter, the game's wounds and ladder. The bench is empty. Every fighter has a hash of his own, and
## a replay's data hash takes only the fighters in its slots: a change to the dummy's data moves the roster's hash and his
## own replays, and leaves a replay of the other two alone. He plays in either slot, and against himself.
func _dummyFighter() -> String:
	if FighterData.order() != ["PROTAGONIST", "RIVAL", "REFERENCE"] or not FighterData.bench().is_empty():
		return "the roster reads %s and the bench %s" % [str(FighterData.order()), str(FighterData.bench())]
	var d: Dictionary = FighterData.def("REFERENCE")
	var p: Dictionary = FighterData.def("PROTAGONIST")
	if d.dmgMul != 1.0 or d.spd != 1.0 or d.care != 0.0 or d.anguish or d.menace or d.role != "reference":
		return "the dummy's numbers are not the frozen base: damage %s, speed %s, care %s" % [str(d.dmgMul), str(d.spd), str(d.care)]
	for fname in ["wounds.json", "ladder.json", "meters.json"]:
		if FileAccess.file_exists(FighterData.ROOT + "REFERENCE/" + fname):
			return "the dummy has a %s of his own: his numbers are the game's" % fname
	if d.wd.wearPerDamage != p.wd.wearPerDamage or d.wd.family.light != p.wd.family.light or d.ld.taken != p.ld.taken or d.ld.thresholds != p.ld.thresholds:
		return "the dummy's wounds or ladder are not the game's"
	var hs := {}
	for id in FighterData.order():
		var hx: String = FighterData.hashOf(id)
		if hx == "" or hs.has(hx):
			return "the hash of %s is empty, or another fighter's" % id
		hs[hx] = true
	var d0: String = SimReplay.dataHash()
	if SimReplay.dataHash({"slots": ["PROTAGONIST", "RIVAL"]}) != d0:
		return "a replay of the default pairing named or not reads two data hashes"
	var dref: String = SimReplay.dataHash({"slots": ["REFERENCE", "RIVAL"]})
	if dref == d0:
		return "a replay of the dummy does not carry his data"
	for slots in [["REFERENCE", "REFERENCE"], ["REFERENCE", "PROTAGONIST"], ["RIVAL", "REFERENCE"]]:
		var S := SimCore.createSim()
		var su := {"slots": slots}
		if slots[0] == slots[1]:
			su.names = ["REFERENCE-A", "REFERENCE-B"]
		SimCore.newMatch(S, 5, {}, su)
		for t in range(900):
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
		for i in range(2):
			var f = S.fighters[i]
			if f.id != slots[i] or not is_finite(f.x) or not is_finite(f.y):
				return "a match of %s: slot %d did not play as %s" % [str(slots), i, slots[i]]
		SimCore.dispose(S)
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 7, {}, {"slots": ["REFERENCE", "RIVAL"]})
	for t in range(600):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != dref or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a replay of the dummy does not carry his data hash, or does not play back"
	# his data change: the roster's hash and his own replays move; a replay of the other two does not
	var h0: String = FighterData.dataHash()
	var dir := "user://dummy_fixture/"
	for id in FighterData.order():
		DirAccess.make_dir_recursive_absolute(dir + id)
		for fname in ["fighter.json", "meters.json"]:
			if not FileAccess.file_exists(FighterData.ROOT + id + "/" + fname):
				continue
			var text: String = FileAccess.get_file_as_string(FighterData.ROOT + id + "/" + fname)
			if id == "REFERENCE" and fname == "fighter.json":
				if text.count("\"dmgMul\": 1.0") != 1:
					return "the fixture's pattern is not in the dummy's file once"
				text = text.replace("\"dmgMul\": 1.0", "\"dmgMul\": 1.04")
			var fw := FileAccess.open(dir + id + "/" + fname, FileAccess.WRITE)
			fw.store_string(text)
			fw.close()
	for name in ["roster.json", "bench.json"]:
		var fr := FileAccess.open(dir + name, FileAccess.WRITE)
		fr.store_string(FileAccess.get_file_as_string(FighterData.ROOT + name))
		fr.close()
	FighterData.quiet = true
	FighterData.loadFrom(dir)
	var out: String = ""
	if not FighterData.errors().is_empty():
		out = "the dummy fixture: " + "; ".join(FighterData.errors())
	elif FighterData.dataHash() == h0:
		out = "a change to the dummy's data did not move the roster's hash"
	elif SimReplay.dataHash() != d0:
		out = "a change to the dummy's data moved a replay of the other two"
	elif SimReplay.dataHash({"slots": ["REFERENCE", "RIVAL"]}) == dref or SimReplay.play(JSON.parse_string(JSON.stringify(rp))).reason != "data":
		out = "a replay of the dummy was not refused after his data changed"
	FighterData.quiet = false
	FighterData.loadFrom()
	return out


## One versus many: Game Design's rulings on what the core counts of a guard (docs/design/empress-guards.md). Only a
## principal's KO ends the match, and a principal felled by a guard loses to the guard's principal. A guard has no brink.
## A guard's stance never sets the mood's AGGRESSIVE column, and his landed blow feeds the mood at half. The acts count the
## principals' form steps and wounds only. The hit-stop stays one for the whole match.
func _guardRules() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"slots": ["PROTAGONIST", "RIVAL", "REFERENCE"], "intro": false})
	var one = S.fighters[0]
	var emp = S.fighters[1]
	var guard = S.fighters[2]
	if not SimRoster.isPrincipal(S, one) or not SimRoster.isPrincipal(S, emp) or SimRoster.isPrincipal(S, guard):
		return "the principals are not slots 0 and 1"
	# KO
	SimDamage.ko(S, guard, one)
	if S.game.ko != null:
		return "a guard's KO ended the match"
	S.out.fx.clear()
	SimDamage.ko(S, one, guard)
	var won: float = -1.0
	for e in S.out.fx:
		if e.type == "ko":
			won = e.winner
	if S.game.ko != one or won != 1.0:
		return "a principal felled by a guard: the KO is %s, won by slot %s" % [str(S.game.ko != null), str(won)]
	SimCore.dispose(S)
	# the brink
	var B := SimCore.createSim()
	SimCore.newMatch(B, 5, {"p1": false, "p2": false}, {"slots": ["PROTAGONIST", "RIVAL", "REFERENCE"], "intro": false})
	for k in [0, 2]:
		var f = B.fighters[k]
		f.wear[SimWounds.CORE] = f.wd.stageAt[2]
		SimWounds.updateStages(B, f)
		if f.brink != (k == 0):
			return "slot %d's core broken: the brink reads %s" % [k, str(f.brink)]
	SimCore.dispose(B)
	# the mood: a blow's units by who threw it, and the stance column
	var M := SimCore.createSim()
	SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"slots": ["PROTAGONIST", "RIVAL", "REFERENCE"], "intro": false})
	var gain := func(make: Callable) -> int:
		var out: Array = [0, 0]
		for pass_ in range(2):
			M.mood.v = SimMood.mood.range / 2
			M.out.fx.clear()
			if pass_ == 1:
				make.call()
			var v0: int = M.mood.v
			SimMood.tick(M)
			out[pass_] = M.mood.v - v0
		M.out.fx.clear()
		return out[1] - out[0]
	var I: Dictionary = SimMood.imp
	for f in M.fighters:
		f.stance = 1.0
	M.fighters[2].stance = 0.0   # the guard AGGRESSIVE: it must not pick the AGGRESSIVE column
	var byOne: int = gain.call(func(): SimFx.damage(M, M.fighters[1], M.fighters[0], 5.0, "core", "light", "", true, "brawl"))
	var byGuard: int = gain.call(func(): SimFx.damage(M, M.fighters[0], M.fighters[2], 5.0, "core", "light", "", true, "brawl"))
	if byOne != I.brawlLight[0] or byGuard != int(SimMathx.jround(float(I.brawlLight[0]) * 0.5)):
		return "a brawl's light fed %d from a principal and %d from a guard; the data say %d and half of it" % [byOne, byGuard, I.brawlLight[0]]
	# both principals AGGRESSIVE add to the mood; a guard's stance changes nothing
	for f in M.fighters:
		f.stance = 1.0
	M.fighters[2].stance = 0.0
	var calm: int = gain.call(func(): pass)
	M.mood.v = SimMood.mood.range / 2
	M.out.fx.clear()
	var v1: int = M.mood.v
	SimMood.tick(M)
	var withGuard: int = M.mood.v - v1
	M.fighters[2].stance = 1.0
	M.mood.v = SimMood.mood.range / 2
	M.out.fx.clear()
	var v2: int = M.mood.v
	SimMood.tick(M)
	if M.mood.v - v2 != withGuard or calm != 0:
		return "a guard's stance changed the mood's tick"
	SimCore.dispose(M)
	# the acts: a guard's tier and wounds do not count
	var A := SimCore.createSim()
	SimCore.newMatch(A, 5, {"p1": false, "p2": false}, {"slots": ["PROTAGONIST", "RIVAL", "REFERENCE"], "intro": false})
	var a0: int = SimMood.act(A)
	var mask0: int = A.mood.onceMask
	A.fighters[2].tier = 4.0
	SimMood.onStage(A, A.fighters[2], SimWounds.ARMS, 2, 1)
	SimMood.onStage(A, A.fighters[2], SimWounds.CORE, 3, 2)
	if SimMood.act(A) != a0 or A.mood.onceMask != mask0:
		return "a guard's tier or wounds moved the act (%d, was %d)" % [SimMood.act(A), a0]
	SimMood.onStage(A, A.fighters[1], SimWounds.ARMS, 2, 1)
	if A.mood.onceMask == mask0:
		return "a principal's battered limb made no act beat"
	SimCore.dispose(A)
	return ""


## One versus many, stage 1 (docs/director/one-v-many.md): a match holds 2 to SimRoster.MAX_BODIES fighters. Slots 0
## and 1 are the pair; a body past them stands beyond the second, GUARD_SPACING apart, facing the first, with the first
## as his opponent; he is idle unless the setup's ai names him. Matches of 3, 4 and 5 bodies run with the pair's AI and
## replay to the same hash; the hash walks every body; the replay records every slot (a 1v1's header is as it was); an
## intro brings in the pair only, and digs no crater under a guard; six slots, or an unknown id, play the default pairing.
func _nBodies() -> String:
	var three: Array = ["PROTAGONIST", "RIVAL", "REFERENCE"]
	var five: Array = ["PROTAGONIST", "RIVAL", "REFERENCE", "REFERENCE", "REFERENCE"]
	for flip in [false, true]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {}, {"slots": five, "names": ["PROTAGONIST", "RIVAL", "GUARD-A", "GUARD-B", "GUARD-C"], "flip": flip, "intro": false})
		if S.fighters.size() != 5:
			return "a five-slot setup made %d fighters" % S.fighters.size()
		var away: float = -1.0 if flip else 1.0
		for k in range(5):
			var f = S.fighters[k]
			if f.id != five[k] or f.keys != "p%d" % (k + 1):
				return "slot %d is %s (keys %s)" % [k, f.id, f.keys]
			if k >= 2:
				var want: float = SimWrap.wrap(S.fighters[1].x + away * SimRoster.GUARD_SPACING * float(k - 1))
				if f.x != want or f.ai != null or f.face != -away or SimRoster.opp(S, f) != S.fighters[0] or f.name != ["GUARD-A", "GUARD-B", "GUARD-C"][k - 2]:
					return "guard %d (flip %s): at %s (want %s), ai %s, face %s" % [k, str(flip), str(f.x), str(want), str(f.ai != null), str(f.face)]
		if SimRoster.opp(S, S.fighters[0]) != S.fighters[1] or SimRoster.opp(S, S.fighters[1]) != S.fighters[0]:
			return "the pair's opponents changed with guards present"
		SimCore.dispose(S)
	# matches of 3, 4 and 5 bodies, the pair the AI's and the rest idle: they run, stay in the world, and replay alike
	for n in [3, 4, 5]:
		var hs: Array = []
		for run in range(2):
			var M := SimCore.createSim()
			SimCore.newMatch(M, 7 + n, {}, {"slots": five.slice(0, n)})
			var stand: Array = []
			for k in range(2, n):
				stand.append(M.fighters[k].x)
			for t in range(1500):
				SimCore.step(M)
				M.out.fx.clear()
				M.out.feed.clear()
			for k in range(n):
				var f = M.fighters[k]
				if not is_finite(f.x) or not is_finite(f.y) or f.x < 0.0 or f.x >= SimConst.W:
					return "%d bodies: fighter %d left the world (%s, %s)" % [n, k, str(f.x), str(f.y)]
			hs.append(SimHash.stateHash(M).gameplay)
			SimCore.dispose(M)
		if hs[0] != hs[1]:
			return "a match of %d bodies did not replay to the same hash" % n
	# the hash walks every body
	var H := SimCore.createSim()
	SimCore.newMatch(H, 5, {}, {"slots": five, "intro": false})
	var h0: String = SimHash.stateHash(H).gameplay
	H.fighters[4].x += 1.0
	if SimHash.stateHash(H).gameplay == h0:
		return "the hash does not see the fifth body"
	SimCore.dispose(H)
	# a recorded match of four bodies, with a human guard, plays back; a 1v1's header names two
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 9, {"p1": true, "p2": true, "p3": false, "p4": true}, {"slots": five.slice(0, 4), "intro": false})
	if rec.replay.ai.keys().size() != 4 or rec.replay.ai.p3 != false or rec.replay.ai.p4 != true or R.fighters[3].ai == null:
		return "a four-body replay's header reads %s" % str(rec.replay.ai)
	var walk := SimIntent.new()
	walk.mx = 1.0
	var quiet := SimIntent.new()
	var x2: float = R.fighters[2].x
	for t in range(600):
		rec.step([null, null, walk if (t / 40) % 2 == 0 else quiet, null])
		R.out.fx.clear()
		R.out.feed.clear()
	if R.fighters[2].x == x2:
		return "a guard given intents did not move"
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	var slots2: int = 0
	for inp in rp.inputs:
		if int(inp[1]) == 2:
			slots2 += 1
	if slots2 == 0:
		return "the replay recorded nothing for the third slot"
	var res: Dictionary = SimReplay.play(JSON.parse_string(JSON.stringify(rp)))
	if not res.ok:
		return "a four-body replay: %s at tick %d" % [res.reason, res.firstBadTick]
	var bad: Dictionary = JSON.parse_string(JSON.stringify(rp))
	bad.inputs.append([1, 7, 0, 0])
	if SimReplay.play(bad).reason != "format":
		return "a replay with a slot the match does not have was not refused"
	var R2 := SimCore.createSim()
	var rec2 := SimReplay.recorder(R2, 9, {}, {})
	if rec2.replay.ai.keys() != ["p1", "p2"]:
		return "a 1v1 replay's header changed: %s" % str(rec2.replay.ai)
	SimCore.dispose(R2)
	# an intro brings in the pair only: the guard stands on the ground, and only two craters are dug
	var I := SimCore.createSim()
	SimCore.newMatch(I, 5, {}, {"slots": three, "intro": true})
	var g: float = WorldTerrain.groundY(I, I.fighters[2].x)
	if I.fighters[2].y != g:
		return "with an intro the guard stands at %s, and the ground is at %s" % [str(I.fighters[2].y), str(g)]
	if I.fighters[0].state != "intro" or I.fighters[2].state == "intro":
		return "the intro took the guard in, or left the pair out"
	SimCore.dispose(I)
	var K := SimCore.createSim()
	SimCore.newMatch(K, 5, {}, {"slots": three})
	if K.craters.size() != 2:
		return "the skipped intro dug %d craters with a guard present" % K.craters.size()
	SimCore.dispose(K)
	# six slots, and an unknown id among five, play the default pairing
	FighterData.quiet = true
	var out: String = ""
	for badSlots in [five + ["RIVAL"], ["PROTAGONIST", "RIVAL", "NOBODY"]]:
		var D := SimCore.createSim()
		SimCore.newMatch(D, 5, {}, {"slots": badSlots})
		if D.fighters.size() != 2 or D.fighters[0].id != "PROTAGONIST":
			out = "slots %s did not play the default pairing" % str(badSlots)
		SimCore.dispose(D)
	FighterData.quiet = false
	return out


## A match's setup names the fighters the data has. Slots that are not 2 to 5 such fighters (an id nobody has, one id,
## six, a number) play the default pairing: the match is the default match to the hash.
func _slotGuard() -> String:
	var want: String = ""
	var D := SimCore.createSim()
	SimCore.newMatch(D, 5)
	for t in range(300):
		SimCore.step(D)
		D.out.fx.clear()
		D.out.feed.clear()
	want = SimHash.stateHash(D).gameplay
	SimCore.dispose(D)
	FighterData.quiet = true
	var out: String = ""
	for bad in [["NOBODY", "RIVAL"], ["PROTAGONIST"], ["PROTAGONIST", "RIVAL", "REFERENCE", "REFERENCE", "REFERENCE", "REFERENCE"], [1, 2], []]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {}, {"slots": bad})
		if S.fighters.size() != 2 or S.fighters[0].id != "PROTAGONIST" or S.fighters[1].id != "RIVAL":
			out = "slots %s did not play the default pairing" % str(bad)
		else:
			for t in range(300):
				SimCore.step(S)
				S.out.fx.clear()
				S.out.feed.clear()
			if SimHash.stateHash(S).gameplay != want:
				out = "slots %s played a match that is not the default match" % str(bad)
		SimCore.dispose(S)
		if out != "":
			break
	FighterData.quiet = false
	if out == "":
		var G := SimCore.createSim()
		SimCore.newMatch(G, 5, {}, {"slots": ["RIVAL", "REFERENCE"]})
		if G.fighters[0].id != "RIVAL" or G.fighters[1].id != "REFERENCE":
			out = "good slots were refused"
		SimCore.dispose(G)
	return out


## D1a negative controls: fixtures made from PROTAGONIST's real files with one fault each (edits keyed to the key name, not its
## value, so a retune does not break them; the old value stays behind as a "_was" note), in user://, must each be rejected with
## the right message; a changed _note must not change the data hash, and a changed number must. Reloads data/fighters/
## at the end.
func _rosterRejects() -> String:
	var base := {"fighter.json": _fighterText("PROTAGONIST", "fighter.json"), "wounds.json": _fighterText("PROTAGONIST", "wounds.json"),
		"meters.json": _fighterText("PROTAGONIST", "meters.json"), "ladder.json": _fighterText("PROTAGONIST", "ladder.json")}
	var h0: String = FighterData.dataHash()
	var cases: Array = [
		["note", "", "", "", ""],
		["number", "wounds.json", "\"focusWear\": ", "\"focusWear\": 31.5, \"_was\": ", ""],
		["nonint", "wounds.json", "\"out\": ", "\"out\": 25.5, \"_was\": ", "must be an integer"],
		["digits", "wounds.json", "\"wearPerDamage\": ", "\"wearPerDamage\": 204.00000000000001, \"_was\": ", "more than 15 significant digits"],
		["rally", "fighter.json", "\"second_wind\"", "\"berserk\"", "unknown Rally rule"],
		["profile", "wounds.json", "\"type\": \"plain\"", "\"type\": \"spread\"", "unknown profile type"],
		["pinned", "wounds.json", "\"legsSlip\": ", "\"legsSlip\": 0.3, \"_was\": ", "is pinned"],
		["meter", "meters.json", "\"anguish\": {", "\"pride\": {", "unknown meter"],
		["dup", "", "", "", "duplicate"],
	]
	var hashes := {}
	var err: String = ""
	FighterData.quiet = true
	for c in cases:
		var dir: String = "user://d1a_fixtures/%s/" % c[0]
		DirAccess.make_dir_recursive_absolute(dir + "PROTAGONIST")
		var ros := FileAccess.open(dir + "roster.json", FileAccess.WRITE)
		ros.store_string("[\"PROTAGONIST\", \"PROTAGONIST\"]" if c[0] == "dup" else "[\"PROTAGONIST\"]")
		ros.close()
		for fname in base:
			var text: String = base[fname]
			if fname == c[1]:
				if text.count(c[2]) != 1:
					err = "fixture %s: pattern not found once" % c[0]
				text = text.replace(c[2], c[3])
			if c[0] == "note" and fname == "wounds.json":
				text = text.replace("\"_about\": \"", "\"_about\": \"(edited note) ")
			var fw := FileAccess.open(dir + "PROTAGONIST/" + fname, FileAccess.WRITE)
			fw.store_string(text)
			fw.close()
		FighterData.loadFrom(dir)
		var errs: String = "; ".join(FighterData.errors())
		hashes[c[0]] = FighterData.dataHash()
		if err == "" and c[4] == "" and errs != "":
			err = "fixture %s: unexpected errors: %s" % [c[0], errs]
		elif err == "" and c[4] != "" and not errs.contains(c[4]):
			err = "fixture %s: not rejected (%s)" % [c[0], errs]
	if err != "":
		FighterData.quiet = false
		FighterData.loadFrom()
		return err
	var numberBlind: bool = hashes.note == hashes.number
	# The note fixture is PROTAGONIST alone, so compare it with PROTAGONIST alone unedited: the dup-free base is the "number" case minus the edit.
	var plain := "user://d1a_fixtures/plain/"
	DirAccess.make_dir_recursive_absolute(plain + "PROTAGONIST")
	var rp := FileAccess.open(plain + "roster.json", FileAccess.WRITE)
	rp.store_string("[\"PROTAGONIST\"]")
	rp.close()
	for fname in base:
		var fp := FileAccess.open(plain + "PROTAGONIST/" + fname, FileAccess.WRITE)
		fp.store_string(base[fname])
		fp.close()
	FighterData.loadFrom(plain)
	var hPlain: String = FighterData.dataHash()
	# A third fighter from data alone (the stage-5 modding test in miniature): PROTAGONIST's files copied as TEST, no code change.
	var third := "user://d1a_fixtures/third/"
	for id in ["PROTAGONIST", "TEST"]:
		DirAccess.make_dir_recursive_absolute(third + id)
		for fname in base:
			var ft := FileAccess.open(third + id + "/" + fname, FileAccess.WRITE)
			ft.store_string(base[fname].replace("\"PROTAGONIST\"", "\"TEST\"") if id == "TEST" else base[fname])
			ft.close()
	var rt := FileAccess.open(third + "roster.json", FileAccess.WRITE)
	rt.store_string("[\"PROTAGONIST\", \"TEST\"]")
	rt.close()
	FighterData.loadFrom(third)
	var thirdErr: String = "; ".join(FighterData.errors())
	var played: String = ""
	if thirdErr == "":
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {}, {"slots": ["TEST", "PROTAGONIST"]})
		for t in range(1200):
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
		if S.fighters[0].id != "TEST" or S.fighters[0].name != "TEST" or not is_finite(S.fighters[0].x):
			played = "the TEST fighter did not play"
		SimCore.dispose(S)
	FighterData.quiet = false
	FighterData.loadFrom()
	if numberBlind:
		return "a changed number did not change the data hash"
	if hPlain != hashes.note:
		return "a changed _note changed the data hash"
	if thirdErr != "":
		return "a third fighter from data: " + thirdErr
	if played != "":
		return played
	if FighterData.dataHash() != h0:
		return "reloading data/fighters/ changed the hash"
	return ""


## M1: data/fight/ loads clean, and its canonical hash matches the goldens (a data edit shows here by name).
func _fightData(g: Dictionary) -> String:
	if not SimMood.errors().is_empty():
		return "data/fight: " + "; ".join(SimMood.errors())
	if not SimPause.errors().is_empty():
		return "data/fight/pause.json: " + "; ".join(SimPause.errors())
	if not SimIntro.errors().is_empty():
		return "data/fight/intro.json: " + "; ".join(SimIntro.errors())
	if not SimShots.errors().is_empty():
		return "data/fight/shots.json: " + "; ".join(SimShots.errors())
	var fh: String = SimMood.dataHash() + SimPause.dataHash() + SimIntro.dataHash() + SimShots.dataHash()
	if fh != g.get("fightHash", ""):
		return "the fight data hash differs (data/fight/ changed): %s vs golden %s; regenerate the goldens if the edit is meant" % [fh, g.get("fightHash", "")]
	return ""


## D1b, made robust in I1: every wired number in meters.json, ladder.json and guardWearSplit changes what the sim does
## when edited (QA found the meters were documentation only). Each row copies data/fighters/ to user://, sets one value
## (ladder and guard edits in both fighters' files) and runs a forced probe: a fresh match, the state that number needs,
## one call into the code that reads it, and the values that call produced. The probe's result with the edited data must
## differ from its result with the real data. No probe plays a match, so a changed opening cannot break a row (the old
## check played seeds and needed new ones after B2 and after the terrain fixes). The end-to-end row is forced as well: RIVAL,
## with menace set, attacks PROTAGONIST through the director, and what PROTAGONIST took must differ (it played seeds until they needed
## replacing three times). composure.below is left out: it only matters while composure's cap is not 0.
const WIRED: Array = [
	["PROTAGONIST/meters.json", ["meters", "anguish", "effects", 0, "perPoint"], 0.2, "kaiTick"],
	["PROTAGONIST/meters.json", ["meters", "anguish", "effects", 0, "cap"], 0.05, "kaiTick"],
	["PROTAGONIST/meters.json", ["meters", "anguish", "effects", 1, "cap"], 0.3, "kaiHit"],
	["PROTAGONIST/meters.json", ["meters", "anguish", "effects", 2, "cap"], 2.0, "kaiHit"],
	["PROTAGONIST/meters.json", ["meters", "anguish", "decay", "rate"], 3.0, "kaiTick"],
	["PROTAGONIST/meters.json", ["meters", "anguish", "sources", 0, "amount"], 5.0, "feedSelf"],
	["PROTAGONIST/meters.json", ["meters", "anguish", "sources", 1, "amount"], 5.0, "feedOther"],
	["RIVAL/meters.json", ["meters", "menace", "effects", 0, "perPoint"], 0.3, "vorrTick"],
	["RIVAL/meters.json", ["meters", "menace", "effects", 0, "cap"], 0.01, "vorrTick"],
	["RIVAL/meters.json", ["meters", "menace", "effects", 1, "cap"], 1.0, "vorrHit"],
	["RIVAL/meters.json", ["meters", "menace", "effects", 2, "perPoint"], 50.0, "beam"],
	["RIVAL/meters.json", ["meters", "menace", "decay", "rate"], 3.0, "vorrTick"],
	["RIVAL/meters.json", ["meters", "menace", "decay", "delayTicks"], 30, "vorrQuiet"],
	["RIVAL/meters.json", ["meters", "menace", "sources", 0, "amount"], 5.0, "feedOther"],
	["RIVAL/meters.json", ["meters", "menace", "sources", 1, "amount"], 5.0, "evac"],
	[["PROTAGONIST/ladder.json", "RIVAL/ladder.json"], ["fillPerSec"], 2.0, "ladderTick"],
	[["PROTAGONIST/ladder.json", "RIVAL/ladder.json"], ["thresholds"], [10.0, 50.0, 75.0], "ladderTick"],
	[["PROTAGONIST/ladder.json", "RIVAL/ladder.json"], ["chargePerSec"], 7.0, "chargeTick"],
	["PROTAGONIST/ladder.json", ["takenPerDamage"], 0.5, "powerHit"],
	["RIVAL/ladder.json", ["dealtPerDamage"], 0.5, "powerHit"],
	[["PROTAGONIST/ladder.json", "RIVAL/ladder.json"], ["tiers", "speed"], 0.5, "speed"],
	[["PROTAGONIST/ladder.json", "RIVAL/ladder.json"], ["tiers", "damage"], 0.5, "tierHit"],
	[["PROTAGONIST/ladder.json", "RIVAL/ladder.json"], ["tiers", "launch"], 0.8, "launch"],
	[["PROTAGONIST/ladder.json", "RIVAL/ladder.json"], ["powerUp", "areaR"], 600.0, "powerUp"],
	[["PROTAGONIST/ladder.json", "RIVAL/ladder.json"], ["powerUp", "areaRPerTier"], 300.0, "powerUp"],
	[["PROTAGONIST/ladder.json", "RIVAL/ladder.json"], ["powerUp", "areaDmg"], 900.0, "powerUp"],
	[["PROTAGONIST/ladder.json", "RIVAL/ladder.json"], ["powerUp", "areaDmgPerTier"], 900.0, "powerUp"],
	[["PROTAGONIST/wounds.json", "RIVAL/wounds.json"], ["guardWearSplit"], {"arms": 0.75, "legs": 0.25}, "guard"],
	["RIVAL/meters.json", ["meters", "menace", "effects", 1, "cap"], 1.0, "vorrExchange"],   # end to end, forced: through the director
]


func _wiredNumbers() -> String:
	var files := {}
	for id in ["PROTAGONIST", "RIVAL"]:   # the wired probes play the default pairing, in a roster of the two
		for fname in ["fighter.json", "wounds.json", "meters.json", "ladder.json"]:
			files[id + "/" + fname] = _fighterText(id, fname)
	var base := {}
	for c in WIRED:
		if not base.has(c[3]):
			base[c[3]] = _wiredProbe(c[3])
			if base[c[3]].begins_with("!"):
				return "probe %s cannot run on the real data: %s" % [c[3], base[c[3]]]
	var bad: Array = []
	FighterData.quiet = true
	for i in range(WIRED.size()):
		var c: Array = WIRED[i]
		var dir: String = "user://d1b_wired/%d/" % i
		for id in ["PROTAGONIST", "RIVAL"]:
			DirAccess.make_dir_recursive_absolute(dir + id)
		var rf := FileAccess.open(dir + "roster.json", FileAccess.WRITE)
		rf.store_string("[\"PROTAGONIST\", \"RIVAL\"]")
		rf.close()
		var targets: Array = c[0] if c[0] is Array else [c[0]]
		for key in files:
			var text: String = files[key]
			if targets.has(key):
				var d = JSON.parse_string(text)
				var node = d
				for k in range(c[1].size() - 1):
					node = node[c[1][k]]
				node[c[1][c[1].size() - 1]] = c[2]
				text = JSON.stringify(d, "  ")
			var fw := FileAccess.open(dir + key, FileAccess.WRITE)
			fw.store_string(text)
			fw.close()
		FighterData.loadFrom(dir)
		if not FighterData.errors().is_empty():
			bad.append("%s %s: %s" % [str(c[0]), str(c[1]), "; ".join(FighterData.errors())])
		elif _wiredProbe(c[3]) == base[c[3]]:
			bad.append("%s %s: no effect on probe %s" % [str(c[0]), str(c[1]), c[3]])
	FighterData.quiet = false
	FighterData.loadFrom()
	return "" if bad.is_empty() else "; ".join(bad)


## One forced probe on the loaded data: a fresh match (seed 3), the state its number needs, one call into the reader, and
## the values it produced as text. A result starting with "!" means the probe could not set its scenario up.
func _wiredProbe(kind: String) -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 3)
	var kai = S.fighters[0]
	var vorr = S.fighters[1]
	var out: Array = []
	match kind:
		"kaiTick":      # anguish: the regen penalty, its cap and the decay
			kai.anguish = 50.0
			kai.ki = 10.0
			SimFighter.stepFighter(S, kai, SimConst.DT)
			out = [kai.ki, kai.anguish]
		"vorrTick":     # menace: the regen bonus, its cap and the decay (long unfed)
			vorr.menace = 50.0
			vorr.menaceSeen = 50.0
			vorr.menaceQuiet = 1000
			vorr.casSeen = S.world.casualties
			vorr.ki = 10.0
			SimFighter.stepFighter(S, vorr, SimConst.DT)
			out = [vorr.ki, vorr.menace]
		"vorrQuiet":    # menace: the decay's delay (unfed for 100 ticks: under the real delay, over the edited one)
			vorr.menace = 50.0
			vorr.menaceSeen = 50.0
			vorr.menaceQuiet = 100
			vorr.casSeen = S.world.casualties
			SimFighter.stepFighter(S, vorr, SimConst.DT)
			out = [vorr.menace]
		"kaiHit", "vorrHit", "tierHit":   # damage: composure and the comeback; menace's damage_mul; the tier's damage step
			var A = vorr if kind == "vorrHit" else kai
			var D = kai if kind == "vorrHit" else vorr
			if kind == "kaiHit":
				A.wear[SimWounds.CORE] = 300000
				SimWounds.updateStages(S, A)
			elif kind == "vorrHit":
				A.menace = 50.0
			else:
				A.tier = 3.0
			var ex := SimState.Exchange.new()
			ex.A = A
			ex.D = D
			ex.kind = "light"
			out = [SimDamage.hit(S, ex, A, D, 20.0, {})]
		"beam":         # menace's beam power
			vorr.menace = 50.0
			out = [DirBeam._clashScore(S, vorr)]
		"feedSelf", "feedOther":   # the casualty sources: caused by PROTAGONIST, or by RIVAL
			WorldCollateral._feed(S, 10.0, kai if kind == "feedSelf" else vorr)
			out = [kai.anguish, vorr.menace]
		"evac":         # the evacuee source: RIVAL's blows empty buildings until someone flees
			for b in S.buildings:
				if b.alive and b.popAlive > 0.0:
					WorldCollateral.kill(S, b.idx, b.popAlive, vorr, 0.0, b.x)
					if S.world.evacuated > 0.0:
						break
			if S.world.evacuated <= 0.0:
				out = ["!no evacuees"]
			else:
				out = [vorr.menace, S.world.evacuated]
		"vorrExchange":   # end to end, forced: RIVAL, with menace, attacks PROTAGONIST through the director; what PROTAGONIST took
			kai.ai = null
			vorr.ai = null
			var hp0: float = kai.hp
			var asked: int = 0
			for t in range(600):
				vorr.menace = 50.0
				vorr.menaceSeen = 50.0
				vorr.menaceQuiet = 0
				if S.dirS.ex == null and kai.hp == hp0 and t >= 60:
					DirExchange.requestAttack(S, vorr, "heavy")
					asked += 1
				SimCore.step(S)
				S.out.fx.clear()
				S.out.feed.clear()
				if kai.hp != hp0 and S.dirS.ex == null:
					break
			if kai.hp == hp0:
				out = ["!RIVAL's attack never hurt PROTAGONIST (%d requests)" % asked]
			else:
				out = [kai.hp, kai.wear[0], kai.wear[1], kai.wear[2], kai.wear[3]]
		"powerHit":     # the ladder's two power rates: RIVAL hits PROTAGONIST, and each one's power rises by his own file's rate
			kai.power = 10.0
			vorr.power = 10.0
			SimDamage.hit(S, null, vorr, kai, 50.0, {"ignoreStance": true})
			out = [kai.power, vorr.power]
		"chargeTick":   # Q10: the charge rate
			kai.power = 15.0
			kai.state = "charging"
			kai.input.charge = true
			SimFighter.stepFighter(S, kai, SimConst.DT)
			out = [kai.power]
		"ladderTick":   # the fill and the thresholds
			kai.power = 15.0
			SimFighter.stepFighter(S, kai, SimConst.DT)
			out = [kai.power, kai.tier, kai.act.formReady]   # I2b: the tier waits for the transform, so the thresholds show in formReady
		"speed":        # the tier's speed step
			kai.tier = 3.0
			kai.power = 60.0
			kai.input.mx = 1.0
			SimFighter.stepFighter(S, kai, SimConst.DT)
			out = [kai.vx]
		"launch":       # the tier's launch step
			kai.tier = 3.0
			DirLaunch.doLaunch(S, kai, vorr, {"ux": 1.0, "uy": 0.2}, 1500.0)
			out = [vorr.vx, vorr.vy]
		"powerUp":      # the power-up's area and damage, on the ground beside the building with the most neighbours
			var best = null
			var most: int = -1
			for b in S.buildings:
				if not b.alive:
					continue
				var near: int = WorldStructures.near(S, b.x, 6000.0).size()
				if near > most:
					most = near
					best = b
			if best == null:
				out = ["!no buildings"]
			else:
				kai.x = best.x
				kai.y = WorldTerrain.groundY(S, kai.x)
				kai.tier = 2.0
				SimFighter.tierUp(S, kai)
				var hp: float = 0.0
				var alive: int = 0
				for b in S.buildings:
					hp += b.hp
					alive += 1 if b.alive else 0
				out = [hp, alive]
		"guard":        # the guard wear split
			SimWounds.addGuardWear(S, kai, 100.0)
			out = [kai.wear[SimWounds.ARMS], kai.wear[SimWounds.LEGS]]
		_:
			out = ["!unknown probe " + kind]
	SimCore.dispose(S)
	var parts: PackedStringArray = []
	for v in out:
		parts.append(SimMathx.bits(v) if v is float else str(v))
	return ",".join(parts)


## D1a: SimRng.keyed is stateless (same inputs, same value; no stream moves), spread over keys and indices, in [0, 1), and
## the same as the golden vector (so the same in every process).
func _keyedDraws(g: Dictionary) -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 3)
	var a0: int = S.rng.a
	var seen := {}
	for n in range(1000):
		var x: float = SimRng.keyed(int(S.game.seed), "compose", n)
		if x < 0.0 or x >= 1.0:
			return "out of [0, 1): " + str(x)
		if x != SimRng.keyed(int(S.game.seed), "compose", n):
			return "not stateless at n %d" % n
		seen[x] = true
	var moved: bool = S.rng.a != a0
	SimCore.dispose(S)
	if moved:
		return "a keyed draw moved S.rng"
	if seen.size() < 1000:
		return "only %d distinct values over 1000 indices" % seen.size()
	if SimRng.keyed(3, "compose", 5) == SimRng.keyed(3, "chain", 5):
		return "keys do not separate"
	return "" if SimGolden.keyedHash() == g.get("keyed", "") else "the keyed vector differs from the golden"


## D1a: each QA arm as a match setup gives the same match as newMatch plus applyArm (full state at ticks 0, 60, 150, 300).
func _armSetups() -> String:
	for arm in ["default", "swap", "mirror-villain", "mirror-hero", "default-flip", "swap-flip", "mirror-villain-flip", "mirror-hero-flip"]:
		var A := SimCore.createSim()
		SimCore.newMatch(A, 2)
		SimGolden.applyArm(arm, A.fighters)
		var B := SimCore.createSim()
		SimCore.newMatch(B, 2, {}, SimGolden.armSetup(arm))
		var e: String = ""
		for t in range(301):
			if (t == 0 or t == 60 or t == 150 or t == 300) and SimHash.stateHash(A).gameplay != SimHash.stateHash(B).gameplay:
				e = "%s: setup and applyArm differ by tick %d" % [arm, t]
				break
			SimCore.step(A)
			SimCore.step(B)
			A.out.fx.clear(); A.out.feed.clear(); B.out.fx.clear(); B.out.feed.clear()
		SimCore.dispose(A)
		SimCore.dispose(B)
		if e != "":
			return e
	return ""


## Tick cost: AI-vs-AI matches with no hashing. The sim tick (step) and the render side's reference cosmetic consumer
## (view/fx.gd plus the camera follow) are timed apart; the first tick of each match (warm-up) is left out.
func _bench() -> void:
	var sim_t := PackedInt64Array()
	var view_t := PackedInt64Array()
	for seed in range(1, 11):
		var S := SimCore.createSim()
		var cam := SimCamera.new()
		var V := SimFxView.new(seed)
		SimCore.newMatch(S, seed)
		var steps: int = 0
		while steps < 18000 and not (S.game.ko != null and S.game.koT > 3.0):
			var t0: int = Time.get_ticks_usec()
			SimCore.step(S)
			var t1: int = Time.get_ticks_usec()
			V.consume(S, S.out.fx)
			cam.camStep(S, S.dt, 1200.0, 700.0)
			var t2: int = Time.get_ticks_usec()
			S.out.fx.clear()
			S.out.feed.clear()
			if steps > 0:
				sim_t.append(t1 - t0)
				view_t.append(t2 - t1)
			steps += 1
		SimCore.dispose(S)
	print("time  sim tick:  " + _dist(sim_t))
	print("time  cosmetic consumer and camera (render side): " + _dist(view_t))


static func _dist(v: PackedInt64Array) -> String:
	var s := v.duplicate()
	s.sort()
	var n: int = s.size()
	var tot: int = 0
	for x in s:
		tot += x
	return "mean %.1f us, p50 %d, p99 %d, p99.9 %d, max %d us over %d ticks of 10 matches" % [float(tot) / n, s[n / 2], s[int(n * 0.99)], s[int(n * 0.999)], s[n - 1], n]


## The beam struggle's meeting point (Encounter's beam struggle): `S.game.clash.mid`, 0 at A's hands to 1 at D's, written by
## the director while a struggle holds it, -1 for none. A clash with none hashes as before (a negative value is not read)
## and throws its sparks on the old glide; one with a meeting point moves the hash and throws the sparks there.
func _clashMid() -> String:
	if SimState.Clash.new().mid != -1.0:
		return "a new clash's meeting point is not -1"
	var hs: Array = []
	for mid in [-1.0, -0.25, 0.3, 0.7]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 9, {"p1": false, "p2": false})
		for t in range(30):
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
		var c := SimState.Clash.new()
		c.A = S.fighters[0]
		c.D = S.fighters[1]
		c.t0 = S.T - 0.4
		c.dur = 1.6
		c.aw = mid != -0.25   # both sides of the glide
		c.mid = mid
		S.game.clash = c
		hs.append(SimHash.stateHash(S).gameplay)
		SimCore.step(S)
		var sp = null
		for e in S.out.fx:
			if e.type == "spark":
				sp = e
		if sp == null or sp.n != 3 or sp.col != "#ffffff":
			return "a clash with meeting point %s threw no clash spark" % str(mid)
		var A = c.A
		var D = c.D
		var m: float = mid
		if mid < 0.0:
			m = 0.5 + (1.0 if c.aw else -1.0) * 0.35 * SimMathx.jclamp((S.T - c.t0) / c.dur, 0.0, 1.0)
		var ex: float = SimWrap.wrap(A.x + SimWrap.sdx(A.x, D.x) * m)
		var ey: float = (A.y + (D.y - A.y) * m) + 38.0
		if absf(sp.x - ex) > 1e-9 or absf(sp.y - ey) > 1e-9:
			return "meeting point %s: the spark is at %.3f, %.3f, not %.3f, %.3f" % [str(mid), sp.x, sp.y, ex, ey]
		SimCore.dispose(S)
	# the same match and clash: no meeting point hashes alike whatever the negative value and the side; a point moves it
	if hs[2] == hs[0] or hs[3] == hs[2]:
		return "a meeting point did not move the hash"
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 9, {"p1": false, "p2": false})
	for t in range(30):
		SimCore.step(S2)
		S2.out.fx.clear()
		S2.out.feed.clear()
	var c2 := SimState.Clash.new()
	c2.A = S2.fighters[0]
	c2.D = S2.fighters[1]
	c2.t0 = S2.T - 0.4
	c2.dur = 1.6
	c2.aw = true
	S2.game.clash = c2
	var hNone: String = SimHash.stateHash(S2).gameplay
	c2.mid = -0.25
	var hNeg: String = SimHash.stateHash(S2).gameplay
	SimCore.dispose(S2)
	if hNone != hs[0] or hNeg != hNone:
		return "a clash with no meeting point does not hash as before"
	return ""


## UI's blow cue (Encounter fills it): `run` and `run_to` ride on the cue as view fields. A cue hashes only its actor, kind,
## text and source, so they move no hash; a fresh event has both at 0 (run_to 0: not set).
func _cueRun() -> String:
	var a := SimState.FxEvent.new()
	if a.run != 0 or a.run_to != 0:
		return "a fresh event's run or run_to is not 0"
	var b := SimState.FxEvent.new()
	for e in [a, b]:
		e.type = "cue"
		e.actor = 0.0
		e.kind = "blow"
		e.text = "light"
	b.run = 3
	b.run_to = 1
	var ha := SimHash.Hasher.new()
	SimHash.hashFx(ha, [a])
	var hb := SimHash.Hasher.new()
	SimHash.hashFx(hb, [b])
	if ha.hex() != hb.hex():
		return "a cue's run or run_to moved the events' hash"
	return ""


## Animation's view fields (docs/animation/ragdoll-physics-paper.md section 5), outside the hash: a launch carries its power
## tier (the launcher's); a hit's damage event carries the hit-stop ticks in force after it, which is exactly the number
## of frozen ticks the step then spends, and the hitter's tier. Neither moves the events' hash.
func _animFields() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false})
	var A = S.fighters[0]
	var D = S.fighters[1]
	A.tier = 3.0
	S.out.fx.clear()
	SimDamage.hit(S, null, A, D, 10.0, {"stop": 0.1})
	var dmg = null
	for e in S.out.fx:
		if e.type == "damage":
			dmg = e
			break
	if dmg == null:
		return "a hit sent no damage event"
	if dmg.tier != 3.0 or dmg.stop != SimFx.stopTicks(S.dirS.stop) or dmg.stop < 1:
		return "the hit's fields: stop %d (want %d), tier %s" % [dmg.stop, SimFx.stopTicks(S.dirS.stop), str(dmg.tier)]
	S.out.fx.clear()
	var frozen: int = 0
	while not SimCore.step(S):
		frozen += 1
		S.out.fx.clear()
		if frozen > 600:
			break
	if frozen != dmg.stop:
		return "the step froze %d ticks after a hit that said %d" % [frozen, dmg.stop]
	var h1 := SimHash.Hasher.new()
	SimHash.hashFx(h1, [dmg])
	dmg.stop = 0
	dmg.tier = 0.0
	var h2 := SimHash.Hasher.new()
	SimHash.hashFx(h2, [dmg])
	if h1.hex() != h2.hex():
		return "a hit's stop or tier moved the events' hash"
	S.out.fx.clear()
	SimFx.launch(S, D, A, 900.0, 1.0)
	var la = S.out.fx[S.out.fx.size() - 1]
	if la.type != "launch" or la.tier != 3.0:
		return "a launch by a tier-3 fighter does not say tier 3"
	var h3 := SimHash.Hasher.new()
	SimHash.hashFx(h3, [la])
	la.tier = 1.0
	var h4 := SimHash.Hasher.new()
	SimHash.hashFx(h4, [la])
	if h3.hex() != h4.hex():
		return "a launch's tier moved the events' hash"
	SimCore.dispose(S)
	return ""


## Forms (hero-forms.md sections 4 and 4b; docs/architecture/forms-core.md). Off (the committed switch), a match has no
## form state and a replay carries no forms data. On: the Protagonist's five steps come ready at their powers and his tier
## for the world steps at three of them; steps that come ready while he waits are banked, and a release takes the next
## one only, none lost; the coil fills a point a second, twice that a tier behind, and a point for every 20 traded, to its max;
## patience; a release with a coil adds the surge, the armour and the lasting gain by its share and spends the coil; the
## gains, and today's for a fighter without steps; a release of live steps never pauses; the hold and the release are
## told, for a fighter without steps too; a forms match replays, with the forms data in its data hash.
func _forms() -> String:
	if not SimForms.errors().is_empty():
		return "the forms data: " + "; ".join(SimForms.errors())
	if SimForms.enabled():
		return "forms are on in the committed data"
	var d0: String = SimReplay.dataHash()
	if SimReplay.dataHash({"forms": false}) != d0 or SimReplay.dataHash({"forms": true}) == d0:
		return "the forms data is not in a replay's data hash exactly when forms are on"
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 5, {"p1": false, "p2": false})
	if S0.formsOn or S0.fighters[0].form != null or S0.fighters[0].fd != null:
		return "a match without forms has form state"
	SimCore.dispose(S0)
	var dt: float = SimConst.DT
	# the five steps, taken one at a time
	var M := SimCore.createSim()
	SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"forms": true})
	var p = M.fighters[0]
	var r = M.fighters[1]
	if not M.formsOn or p.fd == null or r.fd != null or p.form == null or r.form == null:
		return "forms on: the Protagonist takes no steps of his own, or the rival does, or a fighter has no form state"
	if p.id != "PROTAGONIST" or p.fd.steps.size() != 5:
		return "forms on: slot 0 is %s with %d steps" % [p.id, p.fd.steps.size()]
	M.out.fx.clear()
	for w in [[19.9, 0, 1.0], [20.0, 1, 1.0], [35.0, 2, 2.0], [50.0, 3, 2.0], [65.0, 4, 3.0], [100.0, 5, 4.0]]:
		p.power = w[0]
		SimForms.readyTick(M, p, dt)
		if int(w[1]) > p.form.step:
			if not p.act.formReady or p.form.ready != int(w[1]) - p.form.step:
				return "at power %s: not ready for one step (ready %d)" % [str(w[0]), p.form.ready]
			if not SimFighter.transform(M, p):
				return "at power %s: the step was not taken" % str(w[0])
		elif p.act.formReady:
			return "at power %s: ready with no step to take" % str(w[0])
		if p.form.step != int(w[1]) or p.tier != float(w[2]):
			return "at power %s: step %d at tier %s, not %d at %s" % [str(w[0]), p.form.step, str(p.tier), int(w[1]), str(w[2])]
	var nUp: int = 0
	var nStep: int = 0
	var nRel: int = 0
	for e in M.out.fx:
		nUp += 1 if e.type == "tier_up" else 0
		nStep += 1 if e.type == "form_step" else 0
		nRel += 1 if e.type == "form_release" else 0
	if nUp != 3 or nStep != 5 or nRel != 5:
		return "five steps sent %d tier_up, %d form_step and %d form_release (3, 5 and 5)" % [nUp, nStep, nRel]
	if p.form.formMul != 1.0:
		return "a step taken at once made its form stronger"
	var xs: float = 1.0 + (p.fd.tSpeed if p.form.branch == "trial" else 0.0)   # the branch's extras (the branches' check has them)
	var xd: float = 1.0 + (p.fd.wDamage if p.form.branch == "witness" else 0.0)
	var xl: float = 1.0 + (p.fd.wLaunch if p.form.branch == "witness" else 0.0)
	if SimForms.speedMul(M, p) != (1.0 + p.fd.gSpeed * 5.0 * p.form.formMul) * xs or SimForms.damageMul(M, p) != (1.0 + p.fd.gDamage * 5.0 * p.form.formMul) * xd:
		return "the speed or damage gain at five steps"
	if SimForms.launchMul(M, p) != (1.0 + p.fd.gLaunch * 5.0 * p.form.formMul) * xl or SimForms.recoverAfter(M, p, 0.3) != 0.3 * (1.0 - p.fd.gRecover * 5.0 * p.form.formMul):
		return "the launch or recovery gain at five steps"
	if SimForms.speedMul(M, r) != 1.0 + r.ld.speed * (r.tier - 1.0) or SimForms.damageMul(M, r) != 1.0 + r.ld.damage * (r.tier - 1.0) or SimForms.launchMul(M, r) != 1.0 + r.ld.launch * (r.tier - 1.0) or SimForms.recoverAfter(M, r, 0.3) != 0.3:
		return "a fighter without steps reads other than today's gains"
	if SimForms.taken(M, p, 10.0, "guard") != 10.0 * (1.0 - p.fd.gChip * 5.0 * p.form.formMul):
		return "the guard's step gain"
	SimCore.dispose(M)
	# banked: four steps ready at 65 while he waits, a fifth at 100; one release takes all five
	var B := SimCore.createSim()
	SimCore.newMatch(B, 5, {"p1": false, "p2": false}, {"forms": true})
	p = B.fighters[0]
	r = B.fighters[1]
	B.out.fx.clear()
	p.power = 65.0
	var coil: float = 0.0
	for t in range(120):
		SimForms.readyTick(B, p, dt)
		SimForms.holdTick(B, p)
		coil = SimMathx.jmin(100.0, coil + p.fd.coilPerSec * 1.0 * dt)
	if p.form.ready != 4 or not p.act.formReady or p.form.step != 0 or p.form.coil != coil:
		return "at power 65, waiting: ready %d, step %d, coil %s (want 4, 0, %s)" % [p.form.ready, p.form.step, str(p.form.coil), str(coil)]
	r.tier = 3.0   # the rival two tiers above: the coil runs at double, and patience holds
	for t in range(60):
		SimForms.readyTick(B, p, dt)
		SimForms.holdTick(B, p)
		coil = SimMathx.jmin(100.0, coil + p.fd.coilPerSec * 2.0 * dt)
	if p.form.coil != coil:
		return "the coil two tiers behind: %s, not %s" % [str(p.form.coil), str(coil)]
	var m2: float = 1.0 - SimMathx.jmin(0.12, 0.04 * 2.0)
	if SimForms.taken(B, p, 10.0, "spread") != 10.0 * m2:
		return "patience two tiers behind: %s of 10" % str(SimForms.taken(B, p, 10.0, "spread"))
	SimDamage.hurt(B, p, 20.0, r)
	coil = SimMathx.jmin(100.0, coil + (20.0 * m2) * p.fd.coilPerDamage * 2.0)
	if p.form.coil != coil:
		return "the coil from damage traded: %s, not %s" % [str(p.form.coil), str(coil)]
	p.power = 100.0
	SimForms.readyTick(B, p, dt)
	SimForms.holdTick(B, p)
	coil = SimMathx.jmin(100.0, coil + p.fd.coilPerSec * 2.0 * dt)
	var holds: Array = []
	for e in B.out.fx:
		if e.type == "form_hold":
			holds.append(int(e.n))
	if holds != [4, 5] or p.form.ready != 5 or p.form.coil != coil:
		return "the hold was told %s, with %d ready (want [4, 5] and 5)" % [str(holds), p.form.ready]
	var c: float = p.form.coil
	B.out.fx.clear()
	# one step a transformation: the release takes step I only, and the four others stay ready
	if not SimFighter.transform(B, p) or p.form.step != 1 or p.tier != 1.0 or not p.act.formReady or p.form.ready != 4:
		return "a release took step %d at tier %s with %d still ready (want step 1, 4 ready)" % [p.form.step, str(p.tier), p.form.ready]
	var rel = null
	var stepE = null
	var ups: int = 0
	for e in B.out.fx:
		if e.type == "form_release":
			rel = e
		elif e.type == "form_step":
			stepE = e
		elif e.type == "tier_up":
			ups += 1
	if rel == null or int(rel.n) != 1 or rel.amount != c or int(rel.k) != 1 or rel.tier != 1.0 or ups != 0 or stepE == null or stepE.amount != c or int(stepE.k) != 1:
		return "the release's events: a form_release of 1 with the coil, a form_step at 1, and no tier_up"
	var fm: float = SimMathx.jmin(p.fd.maxMul, 1.0 + c * p.fd.perPoint)
	if p.form.coil != 0.0 or p.form.coiling or p.form.formMul != fm or fm <= 1.0:
		return "the coil not spent, or the form's factor %s (want %s at a coil of %s)" % [str(p.form.formMul), str(fm), str(c)]
	if SimForms.speedMul(B, p) != (1.0 + p.fd.gSpeed * 1.0 * fm) * (1.0 + (p.fd.tSpeed if p.form.branch == "trial" else 0.0)):
		return "the coiled form's speed"
	# the next step at once: no coil, so that form is plain
	if not SimFighter.transform(B, p) or p.form.step != 2 or p.form.formMul != 1.0:
		return "the next release at once: step %d, factor %s (want 2 and 1)" % [p.form.step, str(p.form.formMul)]
	# a full coil makes the next form twice as strong, and no more
	p.form.coil = p.fd.coilMax
	if not SimFighter.transform(B, p) or p.form.step != 3 or p.form.formMul != p.fd.maxMul:
		return "a full coil's form: factor %s (want %s)" % [str(p.form.formMul), str(p.fd.maxMul)]
	p.form.coiling = true
	SimForms.traded(B, p, null, 100000.0)
	if p.form.coil != 100.0:
		return "the coil passed its max: %s" % str(p.form.coil)
	SimCore.dispose(B)
	# the coil starts at the first break after the step came ready: inside an exchange it coils nothing
	var X := SimCore.createSim()
	SimCore.newMatch(X, 5, {"p1": false, "p2": false}, {"forms": true})
	p = X.fighters[0]
	X.dirS.ex = SimState.Exchange.new()
	p.power = 20.0
	for t in range(30):
		SimForms.readyTick(X, p, dt)
	if not p.act.formReady or p.form.coiling or p.form.coil != 0.0:
		return "a step that came ready inside an exchange coiled %s (coiling %s)" % [str(p.form.coil), str(p.form.coiling)]
	X.dirS.ex = null
	SimForms.readyTick(X, p, dt)
	if not p.form.coiling or p.form.coil != p.fd.coilPerSec * 1.0 * dt:
		return "at the break after it came ready the coil did not start: %s" % str(p.form.coil)
	SimCore.dispose(X)
	# a release of live steps never pauses the fight
	var L := SimCore.createSim()
	SimCore.newMatch(L, 5, {"p1": false, "p2": false}, {"forms": true})
	p = L.fighters[0]
	p.power = 20.0
	SimForms.readyTick(L, p, dt)
	if not SimForms.releaseLive(p) or int(SimPause.request(L, SimPause.TRANSFORM, 0).version) != SimPause.LIVE:
		return "a release of step I alone is not live"
	p.act.breakIn = -1
	p.power = 35.0
	SimForms.readyTick(L, p, dt)
	if not SimForms.releaseLive(p) or p.form.ready != 2:
		return "with I and II ready, the release (I alone) is not live"
	if not SimFighter.transform(L, p) or p.form.step != 1 or SimForms.releaseLive(p):
		return "after step I, a release of step II is live"
	SimCore.dispose(L)
	# a fighter without steps: his hold and his one-step take are told
	var N := SimCore.createSim()
	SimCore.newMatch(N, 5, {"p1": false, "p2": false}, {"forms": true})
	r = N.fighters[1]
	r.power = 40.0
	r.act.formReady = true
	N.out.fx.clear()
	for t in range(60):
		SimForms.holdTick(N, r)
	if not SimFighter.transform(N, r) or r.tier != 2.0:
		return "the rival's one step with forms on"
	var told: Array = []
	for e in N.out.fx:
		if e.type == "form_hold" or e.type == "form_release":
			told.append([e.type, int(e.n)])
	if told != [["form_hold", 1], ["form_release", 1]]:
		return "a fighter without steps: told %s" % str(told)
	SimCore.dispose(N)
	# a forms match replays, and carries the forms data
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 11, {}, {"forms": true})
	for t in range(3000):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != SimReplay.dataHash({"forms": true}) or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a forms match does not carry the forms data, or does not play back"
	return ""


## Forms' branches (hero-forms.md section 3; docs/architecture/forms-core.md section 7), with forms on: Witness fills by
## the opponent's kills near him and never by his own, which take from it; his anguish no longer takes the opponent's
## kills; Trial fills by the opponent's forms (more when his own was held), the deficit seconds, his blows of a medium or
## more a tier down, the opponent's commitments and the coil; a release picks once, the higher fill, a tie to his branch
## and the first tie to Trial, and empties it; a cross is told; the branch's extras reach the gains, his care and the
## director's two reads; the fills are hashed.
func _formBranches() -> String:
	var dt: float = SimConst.DT
	var M := SimCore.createSim()
	SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"forms": true})
	var p = M.fighters[0]
	var r = M.fighters[1]
	if p.fd == null or p.fd.branchAt != [2, 4]:
		return "the branch steps are not II and IV"
	var norm: float = WorldCollateral.POP_REF / WorldCollateral.normPeople(M)
	# Witness
	SimForms.casualty(M, 3.0, r, SimWrap.wrap(p.x + 100.0))
	var w1: float = 3.0 * p.fd.wPerPerson * norm
	if p.form.witness != w1:
		return "three people the rival killed near him gave Witness %s, not %s" % [str(p.form.witness), str(w1)]
	SimForms.casualty(M, 3.0, r, SimWrap.wrap(p.x + p.fd.wRange + 500.0))
	SimForms.casualty(M, 3.0, null, p.x)
	if p.form.witness != w1:
		return "a kill beyond the range, or with no killer, filled Witness"
	SimForms.casualty(M, 1.0, p, p.x)
	var w2: float = SimMathx.jmax(0.0, w1 - 1.0 * p.fd.wOwnKill * norm)
	if p.form.witness != w2 or r.form.witness != 0.0 or p.form.trial != 0.0:
		return "his own kill: Witness %s (want %s); the rival's %s; Trial %s" % [str(p.form.witness), str(w2), str(r.form.witness), str(p.form.trial)]
	if SimForms.anguishOther(M, p) != 0.0 or SimForms.anguishOther(M, r) != r.md.anguishCasOther:
		return "his anguish still takes the opponent's kills, or the rival's no longer does"
	# Trial: the opponent's form while his tier is no higher; then held
	M.out.fx.clear()
	r.power = 40.0
	r.act.formReady = true
	SimFighter.transform(M, r)
	SimForms.events(M)
	if r.tier != 2.0 or p.form.trial != p.fd.tForm:
		return "the rival's form with his tier no higher gave Trial %s (want %s)" % [str(p.form.trial), str(p.fd.tForm)]
	p.power = 20.0
	var t0: float = p.form.trial
	var c0: float = p.form.coil
	SimForms.readyTick(M, p, dt)
	if not p.act.formReady or p.form.trial != t0 + p.fd.tPerSec * dt + (p.form.coil - c0) or p.form.coil <= c0:
		return "a deficit tick with his step ready: Trial %s (want %s, the second and the coil)" % [str(p.form.trial), str(t0 + p.fd.tPerSec * dt + (p.form.coil - c0))]
	M.out.fx.clear()
	t0 = p.form.trial
	r.power = 70.0
	r.act.formReady = true
	SimFighter.transform(M, r)
	SimForms.events(M)
	if r.tier != 3.0 or p.form.trial != t0 + p.fd.tFormHeld:
		return "the rival's form while his own was held gave %s (want %s)" % [str(p.form.trial - t0), str(p.fd.tFormHeld)]
	# Trial: his blows a tier down, the opponent's commitments
	M.out.fx.clear()
	t0 = p.form.trial
	SimFx.damage(M, r, p, 10.0, "core", "medium", "#ffffff", true, "brawl", "medium")
	SimFx.damage(M, r, p, 10.0, "core", "heavy", "#ffffff", true, "brawl", "heavy")
	SimFx.damage(M, r, p, 10.0, "core", "light", "#ffffff", true, "brawl", "light")
	SimFx.damage(M, r, p, 10.0, "arms", "guard", "#ffffff", true, "", "medium")
	SimFx.damage(M, p, r, 10.0, "core", "heavy", "#ffffff", true, "brawl", "heavy")
	SimFx.finisherStart(M, r, p)
	SimFx.brinkEnter(M, r)
	SimFx.beamOutcome(M, r, p, "CLASH")
	SimFx.beamOutcome(M, r, p, "HIT")
	SimFx.finisherStart(M, p, r)
	SimForms.events(M)
	var want: float = t0 + p.fd.tBlow + p.fd.tBlow + p.fd.tCommit + p.fd.tCommit + p.fd.tCommit
	if p.form.trial != want:
		return "two landed blows a tier down and three commitments gave %s (want %s)" % [str(p.form.trial - t0), str(want - t0)]
	M.out.fx.clear()
	var hb: String = SimHash.stateHash(M).gameplay
	p.form.witness += 1.0
	if SimHash.stateHash(M).gameplay == hb:
		return "the Witness fill is not in the hash"
	p.form.witness -= 1.0
	# the pick at II: Witness the higher; then Trial the higher at IV, a cross
	p.power = 35.0
	SimForms.readyTick(M, p, dt)
	SimFighter.transform(M, p)   # one step a transformation: I first
	p.form.witness = 30.0
	p.form.trial = 10.0
	M.out.fx.clear()
	SimFighter.transform(M, p)
	var st = null
	for e in M.out.fx:
		if e.type == "form_step":
			st = e
	if p.form.step != 2 or p.form.branch != "witness" or p.form.witness != 0.0 or p.form.trial != 10.0 or p.care != 0.5 or st == null or st.text != "witness" or st.source != "":
		return "the pick at II with Witness the higher: step %d, %s, fills %s and %s, care %s" % [p.form.step, p.form.branch, str(p.form.witness), str(p.form.trial), str(p.care)]
	if SimForms.damageMul(M, p) != (1.0 + p.fd.gDamage * 2.0 * p.form.formMul) * (1.0 + p.fd.wDamage) or SimForms.launchMul(M, p) != (1.0 + p.fd.gLaunch * 2.0 * p.form.formMul) * (1.0 + p.fd.wLaunch) or SimForms.blockWiden(M, p) != 0 or SimForms.followBonus(M, p) != 0:
		return "a Witness form's extras"
	p.power = 65.0
	SimForms.readyTick(M, p, dt)
	SimFighter.transform(M, p)   # III first
	p.form.witness = 5.0
	p.form.trial = 50.0
	M.out.fx.clear()
	SimFighter.transform(M, p)
	st = null
	for e in M.out.fx:
		if e.type == "form_step":
			st = e
	if p.form.step != 4 or p.form.branch != "trial" or not p.form.crossed or p.form.trial != 0.0 or p.form.witness != 5.0 or p.care != 0.0 or st == null or st.text != "trial" or st.source != "cross":
		return "the cross at IV to Trial: step %d, %s, crossed %s, fills %s and %s, care %s" % [p.form.step, p.form.branch, str(p.form.crossed), str(p.form.witness), str(p.form.trial), str(p.care)]
	if SimForms.speedMul(M, p) != (1.0 + p.fd.gSpeed * 4.0 * p.form.formMul) * (1.0 + p.fd.tSpeed) or SimForms.blockWiden(M, p) != int(p.fd.tBlock[1]) or SimForms.followBonus(M, p) != p.fd.tFollow:
		return "a Trial form's extras at IV"
	SimCore.dispose(M)
	# ties: the first to Trial, then to the branch he is on; one pick for a release that passes II and IV
	var T := SimCore.createSim()
	SimCore.newMatch(T, 6, {"p1": false, "p2": false}, {"forms": true})
	p = T.fighters[0]
	p.power = 35.0
	SimForms.readyTick(T, p, dt)
	SimFighter.transform(T, p)
	p.form.witness = 7.0
	p.form.trial = 7.0
	SimFighter.transform(T, p)
	if p.form.branch != "trial" or p.form.crossed:
		return "the first tie went to %s" % p.form.branch
	p.power = 65.0
	SimForms.readyTick(T, p, dt)
	SimFighter.transform(T, p)
	p.form.witness = 3.0
	p.form.trial = 3.0
	SimFighter.transform(T, p)
	if p.form.branch != "trial" or p.form.crossed:
		return "a tie on Trial went to %s" % p.form.branch
	SimCore.dispose(T)
	var U := SimCore.createSim()
	SimCore.newMatch(U, 7, {"p1": false, "p2": false}, {"forms": true})
	p = U.fighters[0]
	p.power = 65.0
	SimForms.readyTick(U, p, dt)
	p.form.witness = 20.0
	p.form.trial = 10.0
	SimFighter.transform(U, p)
	if p.form.step != 1 or p.form.branch != "" or p.form.witness != 20.0 or p.form.ready != 3 or not p.act.formReady:
		return "a release from base at 65 took more than step I, or picked: step %d, %s, %d still ready" % [p.form.step, p.form.branch, p.form.ready]
	SimFighter.transform(U, p)
	if p.form.step != 2 or p.form.branch != "witness" or p.form.witness != 0.0 or p.form.trial != 10.0:
		return "the next release, at II, picked %s (fills %s and %s)" % [p.form.branch, str(p.form.witness), str(p.form.trial)]
	SimCore.dispose(U)
	return ""


## The air brake (buildings.md section 7.2; docs/architecture/brake-core.md). Off (the committed switch), a match has no
## brake state and a replay carries no brake data. On: the start window runs straight-line from 8 to 20 ticks by the
## send's power, 25% sooner a mark; a sent fighter who holds the brake starts on the window's tick and not before, slows
## at the rate and pays ki, and under a third of the send's speed has control back in the air (World's journey_end, kind
## brake); with no ki the brake is half as fast; letting go ends it; a set piece's send never brakes; the events say so;
## a brake match replays.
func _brake() -> String:
	if not SimBrake.errors().is_empty():
		return "the brake data: " + "; ".join(SimBrake.errors())
	if SimBrake.enabled():
		return "the brake is on in the committed data"
	var d0: String = SimReplay.dataHash()
	if SimReplay.dataHash({"brake": false}) != d0 or SimReplay.dataHash({"brake": true}) == d0:
		return "the brake data is not in a replay's data hash exactly when it is on"
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 5, {"p1": false, "p2": false})
	if S0.brakeOn or S0.fighters[1].brk != null:
		return "a match without the brake has brake state"
	SimCore.dispose(S0)
	var fs: float = SimBrake.fullSpeed
	var w: Array = [SimBrake.window(0.3, 0), SimBrake.window(0.55, 0), SimBrake.window(0.775, 0), SimBrake.window(1.0, 0), SimBrake.window(2.0, 0), SimBrake.window(1.0, 1)]
	if w != [8, 8, 14, 20, 20, 18]:
		return "the start window by power: %s (want [8, 8, 14, 20, 20, 18])" % str(w)
	var pf := SimState.Fighter.new()
	if SimBrake.power(pf, 0.5 * fs) != 0.5 or SimBrake.power(pf, 3.0 * fs) != 1.0:
		return "a send with no launcher's power: its speed over a full launch's, at most 1"
	pf.launchPower = 0.62
	if SimBrake.power(pf, 3.0 * fs) != 0.62:
		return "a launch's own power is not the window's"
	var runs: Dictionary = {}
	for mode in ["full", "noKi", "release", "special"]:
		var M := SimCore.createSim()
		SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"brake": true})
		var A = M.fighters[0]
		var D = M.fighters[1]
		D.y = WorldTerrain.groundY(M, D.x) + 400.0
		if mode == "noKi":
			D.ki = 0.0
		M.out.fx.clear()
		DirLaunch.doLaunch(M, A, D, {"ux": 0.6, "uy": 0.8}, 2400.0, mode == "special")
		var v0: float = SimBrake.speed(D)
		var held := SimIntent.new()
		held.stanceMask = SimBrake.BIT
		var r := {"v0": v0, "start": -1, "end": -1, "why": "", "free": -1, "je": "", "ki0": D.ki, "kiEnd": -1.0, "vEnd": -1.0, "slowing": true, "at": -1, "ready": -1, "readies": 0}
		var last: float = v0
		for t in range(1, 120):
			var it = held
			if mode == "release" and r.start >= 0 and t >= r.start + 3:
				it = null
			SimCore.step(M, [null, it])
			if t == 1:
				r.at = D.brk.at
			for e in M.out.fx:
				if e.type == "air_brake" and e.text == "ready":
					r.ready = t
					r.readies += 1
				elif e.type == "air_brake" and e.text == "start":
					r.start = t
				elif e.type == "air_brake" and e.text == "end" and r.end < 0:
					r.end = t
					r.why = e.kind
					r.vEnd = e.amount
				elif e.type == "journey_end":
					r.je = e.kind
			if D.brk.on:
				var v: float = SimBrake.speed(D)
				r.slowing = r.slowing and v < last
				last = v
			if r.end >= 0 and r.kiEnd < 0.0:
				r.kiEnd = D.ki
			if D.state == "free" and r.free < 0:
				r.free = t
			M.out.fx.clear()
			M.out.feed.clear()
			if r.end >= 0 and t > r.end + 2:
				break
		runs[mode] = r
		SimCore.dispose(M)
	var f: Dictionary = runs.full
	if f.start != f.at or f.at != SimBrake.window(SimMathx.jmin(1.0, f.v0 / SimBrake.fullSpeed), 0) or f.at < 8 or f.at > 20:
		return "the brake started at tick %d after the send, its window %d (by the send's speed %.0f)" % [f.start, f.at, f.v0]
	if f.why != "speed" or f.free != f.end or f.je != "brake" or not f.slowing or f.vEnd >= f.v0 / 3.0:
		return "the full brake: it ended '%s' at tick %d (free at %d, journey_end '%s', slowing %s, speed %.0f of %.0f)" % [f.why, f.end, f.free, f.je, str(f.slowing), f.vEnd, f.v0]
	var ticks: int = f.end - f.start
	if float(ticks) * SimConst.DT > SimBrake.maxBrakeS + 0.05:
		return "the full brake took %d ticks, past %.1f s" % [ticks, SimBrake.maxBrakeS]
	if absf((f.ki0 - f.kiEnd) - SimBrake.kiPerSec * SimConst.DT * float(ticks)) > SimBrake.kiPerSec * SimConst.DT * 1.01:
		return "the brake's ki: %.2f paid over %d ticks (want %.2f a second)" % [f.ki0 - f.kiEnd, ticks, SimBrake.kiPerSec]
	var n: Dictionary = runs.noKi
	var nt: int = n.end - n.start
	if n.why != "speed" or nt < 2 * ticks - 2 or nt > 2 * ticks + 2:
		return "with no ki the brake took %d ticks, the full one %d (want about twice)" % [nt, ticks]
	var rl: Dictionary = runs.release
	if rl.why != "released" or rl.free >= 0 and rl.free <= rl.end:
		return "letting go: it ended '%s' (free at %d, end at %d)" % [rl.why, rl.free, rl.end]
	if runs.special.start >= 0:
		return "a set piece's send was braked"
	if f.ready != f.at or f.readies != 1 or runs.special.readies != 0:
		return "the brake's ready: told at tick %d (want %d), %d times; %d for a set piece's send (want 0)" % [f.ready, f.at, f.readies, runs.special.readies]
	var K := SimCore.createSim()
	SimCore.newMatch(K, 5, {"p1": false, "p2": false}, {"brake": true})
	var KD = K.fighters[1]
	KD.y = WorldTerrain.groundY(K, KD.x) + 400.0
	KD.brk.marks = 2
	KD.launchPower = 0.9
	DirLaunch.doLaunch(K, K.fighters[0], KD, {"ux": 0.6, "uy": 0.8}, 2400.0, false)
	SimCore.step(K, [null, null])
	if KD.brk.at != SimBrake.window(0.9, 2) or KD.brk.marks != 0:
		return "a send with power 0.9 and two marks: window %d (want %d), marks %d left" % [KD.brk.at, SimBrake.window(0.9, 2), KD.brk.marks]
	SimCore.dispose(K)
	# a brake match replays
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 13, {}, {"brake": true})
	for t in range(2400):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != SimReplay.dataHash({"brake": true}) or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a brake match does not carry the brake data, or does not play back"
	return ""


## A launch's flight on a curve (sim/core/flight.gd; docs/architecture/feel-core.md). Off: no flight state, and a replay
## carries no flight data. On: the curve's shape; a shallow send shows the kick's ramp (no one-tick jump), the peak, the
## glide at 0.4 and the arrival's rise, and lands where the same send lands with the curve off; a steep send lands
## where it does off (sooner or later: the curve carries him through its slow apex); the cue tells kick, glide,
## arrive and end once each; the brake takes over.
func _flight() -> String:
	if not SimFlight.errors().is_empty():
		return "the flight's data: " + "; ".join(SimFlight.errors())
	if SimReplay.dataHash({"flight": true}) == SimReplay.dataHash({"flight": false}):
		return "a replay with the curve on does not carry its data"
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 5, {"p1": false, "p2": false})
	if S0.flightOn != SimFlight.enabled() or (not S0.flightOn and S0.fighters[1].flt != null):
		return "the switch, or flight state with it off"
	SimCore.dispose(S0)
	var c: Array = [SimFlight.curve(1), SimFlight.curve(5), SimFlight.curve(8), SimFlight.curve(19), SimFlight.curve(30), SimFlight.curve(90)]
	if c[0] != 1.0 / float(SimFlight.ramp) or c[1] != 1.0 or c[2] != 1.0 or c[3] <= SimFlight.glide or c[3] >= 1.0 or c[4] != SimFlight.glide or c[5] != SimFlight.glide:
		return "the curve's shape: %s" % str(c)
	var runs := {}
	for key in [["flat", false], ["flat", true], ["steep", false], ["steep", true], ["brake", true]]:
		var M := SimCore.createSim()
		SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"flight": key[1], "brake": key[0] == "brake"})
		var A = M.fighters[0]
		var D = M.fighters[1]
		D.y = WorldTerrain.groundY(M, D.x) + 400.0
		var dir: Dictionary = {"ux": 0.6, "uy": 0.8} if key[0] == "steep" else {"ux": 0.95, "uy": 0.3}
		DirLaunch.doLaunch(M, A, D, dir, 2400.0, false)
		var r := {"peak": SimDetMath.hypot(D.vx, D.vy), "v": [], "land": -1, "dx": 0.0, "cues": [], "jump": 0.0, "brakeAt": -1}
		var x0: float = D.x
		var px: float = D.x
		var py: float = D.y
		var last: float = 0.0
		var held := SimIntent.new()
		held.stanceMask = SimBrake.BIT
		for t in range(1, 900):
			SimCore.step(M, [null, held if key[0] == "brake" else null])
			for e in M.out.fx:
				if e.type == "flight":
					r.cues.append([t, e.text, e.kind])
				elif e.type == "air_brake" and e.text == "start":
					r.brakeAt = t
			M.out.fx.clear()
			M.out.feed.clear()
			if r.land >= 0:
				if t >= r.land + 2:   # the flight's end is told on the tick after the contact
					break
				continue
			if D.state != "launched" or D.jContacts > 0 or D.slide > 0.0 or D.flightHits > 0 or D.wet:
				r.land = t
				r.dx = SimWrap.sdx(x0, D.x)
				continue
			var v: float = SimDetMath.hypot(SimWrap.sdx(px, D.x), D.y - py) / SimConst.DT
			r.v.append(v)
			r.jump = maxf(r.jump, absf(v - last))
			last = v
			px = D.x
			py = D.y
			if key[0] == "brake" and r.brakeAt >= 0 and t > r.brakeAt + 2:
				break
		runs[key[0] + ("_on" if key[1] else "_off")] = r
		SimCore.dispose(M)
	var off: Dictionary = runs.flat_off
	var on: Dictionary = runs.flat_on
	var P: float = on.peak
	if off.land < 0 or on.land < 0:
		return "a flat send did not come down (off %d, on %d)" % [off.land, on.land]
	var tol: float = 0.07
	var pts: Array = [[1, 1.0 / float(SimFlight.ramp)], [SimFlight.ramp, 1.0], [SimFlight.ramp + SimFlight.hold, 1.0], [SimFlight.easeTo + 1, SimFlight.glide]]
	for pt in pts:
		var got: float = on.v[pt[0] - 1] / P
		if absf(got - pt[1]) > tol:
			return "the flat send's speed at tick %d: %.3f of the peak (want %.3f); speeds %s" % [pt[0], got, pt[1], str(on.v.slice(0, 12))]
	var arr: int = -1
	for cue in on.cues:
		if cue[1] == "arrive":
			arr = cue[0]
	if arr < 0 or on.land - arr > SimFlight.arriveTicks + 3 or on.land - arr < SimFlight.arriveTicks - 4:
		return "the arrival was told at tick %d, the contact at %d (want about %d before)" % [arr, on.land, SimFlight.arriveTicks]
	var lastV: float = on.v[on.v.size() - 1] / P
	if lastV < SimFlight.arrive - tol - 0.05:
		return "the arrival's speed: %.3f of the peak (want about %.2f)" % [lastV, SimFlight.arrive]
	if on.jump > P * (1.0 / float(SimFlight.ramp) + tol) or off.jump < 0.9 * off.peak:
		return "the largest change in a tick: %.0f with the curve (want at most a ramp's step of %.0f), %.0f without it" % [on.jump, P / float(SimFlight.ramp), off.jump]
	if on.land <= off.land or absf(on.dx - off.dx) > 0.05 * absf(off.dx) + 20.0:
		return "the flat send: it lands at %.0f in %d ticks with the curve, at %.0f in %d without (want the same place, later)" % [on.dx, on.land, off.dx, off.land]
	var texts: Array = []
	for cue in on.cues:
		texts.append(cue[1])
	if texts.count("kick") != 1 or texts.count("arrive") != 1 or texts.count("end") != 1 or texts[0] != "kick" or texts[texts.size() - 1] != "end" or on.cues[0][0] != 1:
		return "the flight's cues: %s" % str(on.cues)
	var so: Dictionary = runs.steep_off
	var sn: Dictionary = runs.steep_on
	if so.land < 0 or sn.land < 0 or absf(sn.dx - so.dx) > 0.05 * absf(so.dx) + 20.0:
		return "the steep send: it lands at %.0f in %d ticks with the curve, at %.0f in %d without" % [sn.dx, sn.land, so.dx, so.land]
	var br: Dictionary = runs.brake_on
	var be: Array = []
	for cue in br.cues:
		if cue[1] == "end":
			be = cue
	if br.brakeAt < 0 or be.is_empty() or be[0] != br.brakeAt or be[2] != "brake":
		return "the brake: it started at tick %d; the flight's end %s" % [br.brakeAt, str(be)]
	# a match with the curve and hit-stop by weight on replays
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 11, {}, {"flight": true, "hitstop": true})
	var kicks: int = 0
	var tk: int = 0
	while tk < 10800 and (kicks == 0 or tk < 3600):
		tk += 1
		rec.step([null, null])
		for e in R.out.fx:
			if e.type == "flight" and e.text == "kick":
				kicks += 1
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if kicks == 0 or rp.data != SimReplay.dataHash({"flight": true, "hitstop": true}) or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a match with both on (%d launches paced) does not carry their data, or does not play back" % kicks
	return ""


## Hit-stop by weight (sim/core/hitstop.gd). Off: a hit's stop is the one passed, and a stop's count-down is today's.
## On: each weight's ticks; a hit that names none keeps the one passed; stops merge; over the budget every stop under
## a decisive blow is x0.75 (rounded, at least 2) and decisive blows are not, and 10 s of fight later the budget is
## back; a stop of n ticks freezes n; a broken region's decisive and the KO's cap (in ko).
func _hitstop() -> String:
	if not SimHitstop.errors().is_empty():
		return "the hit-stop's data: " + "; ".join(SimHitstop.errors())
	if SimReplay.dataHash({"hitstop": true}) == SimReplay.dataHash({"hitstop": false}):
		return "a replay with hit-stop by weight on does not carry its data"
	var O := SimCore.createSim()
	SimCore.newMatch(O, 5, {"p1": false, "p2": false}, {"hitstop": false})
	O.dirS.stop = 0.0
	SimDamage.hit(O, null, O.fighters[0], O.fighters[1], 1.0, {"weight": "heavy", "stop": 0.2})
	if O.hs != null or O.dirS.stop != 0.2:
		return "off: a hit naming a weight held %s (want the 0.2 it passed)" % str(O.dirS.stop)
	SimCore.dispose(O)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"hitstop": true})
	var A = S.fighters[0]
	var D = S.fighters[1]
	var want: Dictionary = {"light_flow": 0, "light_mash": 2, "light": 3, "medium": 5, "heavy": 8, "launch": 12, "launch_full": 14, "decisive": 20, "ko": 24}
	for w in want:
		S.dirS.stop = 0.0
		SimDamage.hit(S, null, A, D, 1.0, {"weight": w, "stop": 0.5})
		if S.dirS.stop != float(want[w]) * SimConst.DT or SimHitstop.ticks(S, w) != want[w]:
			return "%s held %s (want %d ticks)" % [w, str(S.dirS.stop / SimConst.DT), want[w]]
	S.dirS.stop = 0.0
	SimDamage.hit(S, null, A, D, 1.0, {"stop": 0.2})
	if S.dirS.stop != 0.2:
		return "a hit naming no weight held %s (want the 0.2 it passed)" % str(S.dirS.stop)
	S.dirS.stop = 0.0
	SimDamage.hit(S, null, A, D, 1.0, {"weight": "heavy"})
	SimDamage.hit(S, null, A, D, 1.0, {"weight": "light"})
	if S.dirS.stop != 8.0 * SimConst.DT:
		return "a heavy and a light in one tick held %s ticks (want the heavy's 8: they merge)" % str(S.dirS.stop / SimConst.DT)
	if SimHitstop.budgetTicks != 108 or SimHitstop.windowS != 10:
		return "the budget is %d ticks of %d s (want 18%% of 10 s, 108)" % [SimHitstop.budgetTicks, SimHitstop.windowS]
	S.dirS.stop = 0.0
	for i in range(SimHitstop.budgetTicks):
		SimHitstop.frozen(S)
	var cut: Dictionary = {"light_flow": 0, "light_mash": 2, "light": 2, "medium": 4, "heavy": 6, "launch": 9, "launch_full": 11, "decisive": 20, "ko": 24}
	for w in cut:
		if SimHitstop.ticks(S, w) != cut[w]:
			return "over the budget, %s holds %d (want %d: x0.75, rounded, at least 2; decisive and the KO never cut)" % [w, SimHitstop.ticks(S, w), cut[w]]
	# the deep step (Game Design's 7d): over 40% of the window, x0.5, rounded, at least 2
	if SimHitstop.deepTicks != 240:
		return "the deep line is %d ticks (want 40%% of 10 s, 240)" % SimHitstop.deepTicks
	for i in range(SimHitstop.deepTicks - SimHitstop.budgetTicks - 1):
		SimHitstop.frozen(S)
	if SimHitstop.ticks(S, "heavy") != 6:
		return "a tick under the deep line, a heavy holds %d (want 6: x0.75)" % SimHitstop.ticks(S, "heavy")
	SimHitstop.frozen(S)
	var deep: Dictionary = {"light_flow": 0, "light_mash": 2, "light": 2, "medium": 3, "heavy": 4, "launch": 6, "launch_full": 7, "decisive": 20, "ko": 24}
	for w in deep:
		if SimHitstop.ticks(S, w) != deep[w]:
			return "over the deep line, %s holds %d (want %d: x0.5, rounded, at least 2; decisive and the KO never cut)" % [w, SimHitstop.ticks(S, w), deep[w]]
	var h0: String = SimHash.stateHash(S).gameplay
	for i in range(SimHitstop.windowS * 60 - 1):
		SimHitstop.live(S)
	if SimHitstop.ticks(S, "heavy") != 4:
		return "the budget came back before 10 s of fight"
	SimHitstop.live(S)
	if SimHitstop.ticks(S, "heavy") != 8 or S.hs.sum != 0 or SimHash.stateHash(S).gameplay == h0:
		return "10 s of fight later: a heavy %d (want 8), %d frozen ticks counted; the budget's state not hashed" % [SimHitstop.ticks(S, "heavy"), S.hs.sum]
	# a mash flows (Game Design's 6): a flowing blow holds no stop, and the clock runs on
	S.dirS.stop = 0.0
	var tf: float = S.T
	SimDamage.hit(S, null, A, D, 1.0, {"weight": "light_flow", "stop": 0.5})
	SimCore.step(S, [null, null])
	if S.dirS.stop != 0.0 or S.T == tf:
		return "a mash's flowing blow held %s ticks, the clock %s" % [str(S.dirS.stop / SimConst.DT), "ran" if S.T != tf else "froze"]
	# whole ticks: a stop of n ticks freezes n (the count-down's residue gave n + 1 for n of 3 or more), and the damage
	# event's view field says so; with the switch off, today's count stands
	for n in [2, 3, 4, 5, 6, 8, 12, 14, 20, 24]:
		S.dirS.stop = float(n) * SimConst.DT
		var s0: int = S.hs.sum
		var steps: int = 0
		while S.dirS.stop > 0.0 and steps < 100:
			SimCore.step(S, [null, null])
			steps += 1
		if S.hs.sum - s0 != n or steps != n:
			return "a stop of %d ticks froze %d" % [n, S.hs.sum - s0]
		for i in range(SimHitstop.windowS * 60):
			SimHitstop.live(S)   # the budget empty again
	if SimFx.stopTicks(6.0 * SimConst.DT, true) != 6 or SimFx.stopTicks(6.0 * SimConst.DT) != 7:
		return "the event's stop: %d whole (want 6), %d today's (want 7)" % [SimFx.stopTicks(6.0 * SimConst.DT, true), SimFx.stopTicks(6.0 * SimConst.DT)]
	S.dirS.stop = 0.0
	SimHitstop.afterHit(S, D, [0, 2, 0, 0])
	if S.dirS.stop != 0.0:
		return "no region broke, yet a stop was held"
	var st: Array = D.stage.duplicate()
	D.stage[1] = 3
	SimHitstop.afterHit(S, D, st)
	if S.dirS.stop != 20.0 * SimConst.DT:
		return "a broken region held %s ticks (want decisive's 20)" % str(S.dirS.stop / SimConst.DT)
	D.stage = st
	S.dirS.stop = 4.0 * SimConst.DT   # the finisher's last blow, then the KO in the same tick
	SimDamage.ko(S, D, A)
	if S.game.ko != D or S.dirS.stop != 24.0 * SimConst.DT:
		return "the KO held %s ticks (want the cap's 24), KO %s" % [str(S.dirS.stop / SimConst.DT), str(S.game.ko == D)]
	SimCore.dispose(S)
	return ""


## The catastrophe's sky (sim/core/cata.gd): a blast cloud sends its cue (x, y, amount, n) and raises the ash by
## perCloud over riseTicks, evenly, at most max; a second raises it again to its cap; S.cata is null and unhashed until
## the first, and a match that has none is as before.
func _cata() -> String:
	if not SimCata.errors().is_empty():
		return "the catastrophe's data: " + "; ".join(SimCata.errors())
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false})
	if S.cata != null or SimCata.ash(S) != 0.0:
		return "a match starts with a catastrophe's state"
	var h0: String = SimHash.stateHash(S).gameplay
	S.out.fx.clear()
	SimCata.blastCloud(S, S.fighters[1], 1234.0, 50.0, S.tick + 8)
	var e = S.out.fx[S.out.fx.size() - 1]
	if e.type != "blast_cloud" or e.actor != 1.0 or e.x != 1234.0 or e.y != 50.0 or e.amount != SimCata.radius or int(e.n) != S.tick + 8:
		return "the blast_cloud cue's fields"
	if S.cata == null or S.cata.ash != 0 or S.cata.ashTo != SimCata.perCloud or SimHash.stateHash(S).gameplay == h0:
		return "the cloud's ash is not set, or not in the hash"
	var last: int = 0
	for t in range(SimCata.riseTicks):
		SimCata.tick(S)
		var want: int = int(SimMathx.jround(float(SimCata.perCloud) * float(t + 1) / float(SimCata.riseTicks)))
		if S.cata.ash < last or absi(S.cata.ash - want) > 1:
			return "tick %d of the rise: the ash is %d (want %d, never falling)" % [t + 1, S.cata.ash, want]
		last = S.cata.ash
	if S.cata.ash != SimCata.perCloud or S.cata.ashLeft != 0 or SimCata.ash(S) != float(SimCata.perCloud) / 1000.0:
		return "after its rise the ash is %d (want %d)" % [S.cata.ash, SimCata.perCloud]
	SimCata.blastCloud(S, null, 0.0, 0.0, S.tick)
	if S.out.fx[S.out.fx.size() - 1].actor != -1.0:
		return "a cloud by no one"
	while S.cata.ashLeft > 0:
		SimCata.tick(S)
	if S.cata.ash != mini(SimCata.ashMax, 2 * SimCata.perCloud):
		return "two clouds' ash is %d" % S.cata.ash
	# the rise runs in the step, and a cloud's match replays from its state
	var a0: int = S.cata.ash
	SimCata.blastCloud(S, null, 0.0, 0.0, S.tick)
	SimCore.step(S, [null, null])
	if S.cata.ashLeft != SimCata.riseTicks - 1 or S.cata.ash != a0:
		return "the step does not run the rise (left %d)" % S.cata.ashLeft
	SimCore.dispose(S)
	return ""


## The curve's shared functions (sim/core/flight.gd; docs/architecture/feel-core.md section 6), the brake's public control
## back, and the camera feed outside the light digest. share and kOf by their rule; a predictor's track steps as the live
## flight does, to the bit, for a shallow and a steep send, and predict() names the flight's touchdown tick;
## SimBrake.controlBack ends a flight; a cam_intent cue leaves hashFx as it was, and any other cue moves it; out of the
## digest, one AI match twice with the feed on gives the same cues.
func _shared() -> String:
	if SimFlight.share(5, -1, 0.0) != SimFlight.curve(5) or SimFlight.share(40, 30, 0.4) != 0.4 + (SimFlight.arrive - 0.4) * minf(1.0, 10.0 / float(SimFlight.arriveTicks)):
		return "share: the curve before the arrival, its ramp after"
	if SimFlight.kOf(0.4, 1000.0, 300.0, 400.0) != 0.8 or SimFlight.kOf(1.0, 1000.0, 0.0, 0.0) != SimFlight.kMax or SimFlight.kOf(0.1, 1000.0, 3000.0, 4000.0) != SimFlight.kMin:
		return "kOf: the pace and its two clamps"
	for dir in [{"ux": 0.95, "uy": 0.3}, {"ux": 0.6, "uy": 0.8}]:
		var M := SimCore.createSim()
		SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"flight": true})
		var A = M.fighters[0]
		var D = M.fighters[1]
		D.y = WorldTerrain.groundY(M, D.x) + 400.0
		DirLaunch.doLaunch(M, A, D, dir, 2400.0, false)
		var tr = SimFlight.track(D.x, D.y, D.vx, D.vy, D.aimB)
		var pr: PackedFloat64Array = SimFlight.predict(M, D.x, D.y, D.vx, D.vy, D.aimB)
		var land: int = -1
		var arrived: bool = false
		for t in range(1, 900):
			SimCore.step(M, [null, null])
			M.out.fx.clear()
			M.out.feed.clear()
			if D.state != "launched" or D.jContacts > 0 or D.slide > 0.0 or D.wet or D.flightHits > 0:
				land = t
				break
			SimFlight.tick(M, tr)
			if tr.x != D.x or tr.y != D.y or tr.vx != D.vx or tr.vy != D.vy or tr.t != D.flt.t or tr.arr != D.flt.arr or tr.k != D.flt.k:
				return "tick %d of the send %s: the track (%.3f, %.3f, k %.4f, arr %d) and the flight (%.3f, %.3f, k %.4f, arr %d) part" % [t, str(dir), tr.x, tr.y, tr.k, tr.arr, D.x, D.y, D.flt.k, D.flt.arr]
			arrived = arrived or tr.arr >= 0
		SimCore.dispose(M)
		if land < 0 or not arrived or int(pr[0]) != land:
			return "the send %s: predict() touches down on tick %d, the flight on %d (arrival told: %s)" % [str(dir), int(pr[0]), land, str(arrived)]
	var B := SimCore.createSim()
	SimCore.newMatch(B, 5, {"p1": false, "p2": false})
	var BD = B.fighters[1]
	BD.y = WorldTerrain.groundY(B, BD.x) + 400.0
	DirLaunch.doLaunch(B, B.fighters[0], BD, {"ux": 0.6, "uy": 0.8}, 2400.0, false)
	for t in range(3):
		SimCore.step(B, [null, null])
	SimBrake.controlBack(B, BD)
	if BD.state == "launched" or BD.launchT != 1.0:
		return "SimBrake.controlBack: he is still %s (traversal %s)" % [BD.state, str(BD.launchT)]
	SimCore.dispose(B)
	var C := SimCore.createSim()
	SimCore.newMatch(C, 5, {"p1": false, "p2": false})
	var h0 := SimHash.Hasher.new()
	SimHash.hashFx(h0, [])
	C.out.fx.clear()
	SimFx.cue(C, C.fighters[0], "cam_intent", "plan", "launch")
	var h1 := SimHash.Hasher.new()
	SimHash.hashFx(h1, C.out.fx)
	C.out.fx.clear()
	SimFx.cue(C, C.fighters[0], "slide_brace", "", "")
	var h2 := SimHash.Hasher.new()
	SimHash.hashFx(h2, C.out.fx)
	SimCore.dispose(C)
	if h1.hex() != h0.hex() or h2.hex() == h0.hex():
		return "the light digest: a cam_intent cue %s it, another cue %s it (want: leaves it, moves it)" % ["moves" if h1.hex() != h0.hex() else "leaves", "moves" if h2.hex() != h0.hex() else "leaves"]
	# out of the digest, the feed's own determinism is held here: one AI match twice with the feed on, the same cues
	var ci = DirInterrupt.data().get("cameraIntent", null)
	if not (ci is Dictionary):
		return "the camera feed's data block is missing"
	var was = ci.get("enabled", false)
	ci["enabled"] = true
	var runs: Array = []
	for run in range(2):
		var R := SimCore.createSim()
		SimCore.newMatch(R, 13, {})
		var hc := SimHash.Hasher.new()
		var n: int = 0
		for t in range(2400):
			SimCore.step(R, null)
			for e in R.out.fx:
				if e.type == "cue" and e.kind == "cam_intent":
					hc.num(float(R.tick))
					hc.num(e.actor)
					hc.text(String(e.text))
					hc.text(String(e.source))
					n += 1
			R.out.fx.clear()
			R.out.feed.clear()
		runs.append([n, hc.hex(), SimHash.stateHash(R).gameplay])
		SimCore.dispose(R)
	ci["enabled"] = was
	if int(runs[0][0]) == 0 or runs[0] != runs[1]:
		return "the camera feed on: %d and %d cues, the same stream %s, the same play %s" % [int(runs[0][0]), int(runs[1][0]), str(runs[0][1] == runs[1][1]), str(runs[0][2] == runs[1][2])]
	return ""


## The planet's golden keys (SimGolden.planetGolden): World's slice hashes, the tick-0 state of planet matches on the
## Whole ring and the Half, and one AI match on a planet with every per-tick digest and full-state checkpoint.
func _planetGolden(g: Dictionary) -> String:
	var want = g.get("planet", null)
	if not (want is Dictionary):
		return "the golden has no planet keys"
	var sl: Dictionary = SimGolden.planetSlices()
	for k in want.slices:
		if sl.get(k, "") != want.slices[k]:
			return "slice %s: %s, golden %s" % [k, sl.get(k, ""), want.slices[k]]
	var t0: Dictionary = SimGolden.planetTick0()
	for k in want.tick0:
		if t0.get(k, "") != want.tick0[k]:
			return "tick-0 state of the planet match %s: %s, golden %s" % [k, t0.get(k, ""), want.tick0[k]]
	var m: Dictionary = want.match
	var pm: Dictionary = SimGolden.PLANET_MATCH
	if int(m.seed) != int(pm.seed) or int(m.cap) != int(pm.cap) or JSON.stringify(m.get("setup", {})) != JSON.stringify(JSON.parse_string(JSON.stringify(pm.setup))):
		return "the planet match's recipe (%s) is not the golden's (%s): regenerate" % [JSON.stringify(pm), JSON.stringify(m.get("setup", {}))]
	var got: Dictionary = SimGolden.goldenRun("default", int(pm.seed), null, int(pm.cap), pm.setup.duplicate(true))
	var e: String = SimGolden.compareRun(got, m, "the planet match %s seed %d" % [JSON.stringify(pm.setup), int(pm.seed)])
	if e != "":
		return e
	print("      %d slices, %d tick-0 states, a planet match of %d ticks: identical" % [want.slices.size(), want.tick0.size(), got.ticks])
	return ""


## The run's rare boons (rulings-2026-10-18b.md section 4; docs/architecture/boons-core.md). A match that names none has
## none, and a replay's data hash takes boons.json only when its setup names one. Each starts its fighter in his boon's
## form at its floor, without forms (tiers 2, 3 and 4) and with them (steps I, II and V, the branch the first tie's);
## second skin on the rival fills the Protagonist's Trial at once; the borrowed form's wear runs 1 / (1 - share) as fast
## until a region breaks; the collateral reads the higher tier from the start; a boon match replays.
## Our own pi and tau: from their bits, tau twice pi exactly, and both the engine's doubles, so a swap moves nothing.
func _piTau() -> String:
	if SimMathx.bits(SimMathx.PI) != "400921fb54442d18" or SimMathx.bits(SimMathx.TAU) != "401921fb54442d18" or SimMathx.TAU != 2.0 * SimMathx.PI:
		return "pi %s, tau %s (want 400921fb54442d18 and twice it)" % [SimMathx.bits(SimMathx.PI), SimMathx.bits(SimMathx.TAU)]
	if SimMathx.PI != PI or SimMathx.TAU != TAU:
		return "the engine's PI or TAU is another double on this build: the swaps would move a result"
	return ""


func _boons() -> String:
	if not SimBoons.errors().is_empty():
		return "the boons' data: " + "; ".join(SimBoons.errors())
	var d0: String = SimReplay.dataHash()
	if SimReplay.dataHash({"boons": {"0": "born_ready"}}) == d0:
		return "a replay that names a boon does not carry the boons' data"
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 5, {"p1": false, "p2": false})
	if S0.fighters[0].boon != "" or S0.fighters[0].tier != 1.0:
		return "a match that names no boon has one"
	SimCore.dispose(S0)
	for w in [["born_ready", 2.0, 35.0], ["second_skin", 3.0, 65.0], ["borrowed", 4.0, 100.0]]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"boons": {"0": w[0]}})
		var p = S.fighters[0]
		if p.boon != w[0] or p.tier != w[1] or p.power != w[2] or S.world.maxTier < w[1] or S.fighters[1].tier != 1.0:
			return "%s without forms: tier %s at power %s (want %s at %s), the world's top tier %s" % [w[0], str(p.tier), str(p.power), str(w[1]), str(w[2]), str(S.world.maxTier)]
		SimCore.dispose(S)
	for w in [["born_ready", 1, 1.0, 20.0, ""], ["second_skin", 2, 2.0, 35.0, "trial"], ["borrowed", 5, 4.0, 100.0, "trial"]]:
		var F := SimCore.createSim()
		SimCore.newMatch(F, 5, {"p1": false, "p2": false}, {"forms": true, "boons": {"0": w[0]}})
		var p = F.fighters[0]
		if p.form.step != w[1] or p.tier != w[2] or p.power != w[3] or p.form.branch != w[4]:
			return "%s with forms: step %d, tier %s, power %s, branch '%s'" % [w[0], p.form.step, str(p.tier), str(p.power), p.form.branch]
		SimCore.dispose(F)
	var R2 := SimCore.createSim()
	SimCore.newMatch(R2, 5, {"p1": false, "p2": false}, {"forms": true, "boons": {"1": "second_skin"}})
	if R2.fighters[1].tier != 3.0 or R2.fighters[0].form.trial != R2.fighters[0].fd.tForm:
		return "second skin on the rival: his tier %s, the Protagonist's Trial %s (want %s)" % [str(R2.fighters[1].tier), str(R2.fighters[0].form.trial), str(R2.fighters[0].fd.tForm)]
	SimCore.dispose(R2)
	# the borrowed form's price
	var B := SimCore.createSim()
	SimCore.newMatch(B, 5, {"p1": false, "p2": false}, {"boons": {"0": "borrowed"}})
	var p = B.fighters[0]
	var q = B.fighters[1]
	var want: int = int(SimMathx.jround(10.0 * (SimWounds.wearK(B, p) * (1.0 / (1.0 - SimBoons.sooner)))))
	var wq: int = int(SimMathx.jround(10.0 * SimWounds.wearK(B, q)))
	var p0: int = int(p.wear[SimWounds.CORE])
	var q0: int = int(q.wear[SimWounds.CORE])
	SimWounds.addWear(B, p, SimWounds.CORE, 10.0)
	SimWounds.addWear(B, q, SimWounds.CORE, 10.0)
	if int(p.wear[SimWounds.CORE]) - p0 != want or int(q.wear[SimWounds.CORE]) - q0 != wq or want <= wq:
		return "the borrowed form's wear: %d (want %d), the rival's %d (want %d)" % [int(p.wear[SimWounds.CORE]) - p0, want, int(q.wear[SimWounds.CORE]) - q0, wq]
	p.stage[SimWounds.ARMS] = 3
	if SimBoons.wearMul(p) != 1.0 or SimBoons.wearMul(q) != 1.0:
		return "the borrowed form's wear runs fast after his first broken region"
	SimCore.dispose(B)
	# a boon match replays
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 9, {}, {"boons": {"0": "born_ready"}})
	for t in range(1200):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != SimReplay.dataHash({"boons": {"0": "born_ready"}}) or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a boon match does not carry the boons' data, or does not play back"
	return ""


## The ricochet's glance (sim/core/ricochet.gd; docs/architecture/ricochet-core.md). Off: a replay carries no ricochet
## data, and a contact is World's as before. The rule by its cases (the line on his whole speed), the slope's scope and
## predict() in any frame. On, on the test world's steep uphill (49 degrees): a fast send 20 degrees into the slope
## glances (keep of the speed, mirrored, flying on, told once; World's bounce event with its keep); a full row, a slow
## send and one 60 degrees into the slope do not; on level ground the same fast shallow send skids (Orb's skid stands); a
## building's face glances a steep send and not a level one; with the curve on the glance ends its paced leg; a
## ricochet match replays.
func _ricochet() -> String:
	if not SimRicochet.errors().is_empty():
		return "the ricochet's data: " + "; ".join(SimRicochet.errors())
	if SimReplay.dataHash({"ricochet": true}) == SimReplay.dataHash({"ricochet": false}):
		return "a replay with ricochets on does not carry their data"
	var K: float = SimRicochet.keep
	var r: PackedFloat64Array = SimRicochet.rule(-1600.0, 3000.0, 0)
	if r[0] != 1.0 or r[1] != K * 1600.0 or r[2] != K * 3000.0:
		return "rule: a shallow contact at 3,400 glances (got %s)" % str(r)
	if SimRicochet.rule(-1000.0, 3000.0, 0)[0] != 1.0:
		return "rule: the line is on the whole speed (3,162, only 1,000 into the surface: a glance)"
	if SimRicochet.rule(-400.0, 1000.0, 0)[0] != 2.0 or SimRicochet.rule(-3000.0, 1000.0, 0)[0] != 0.0 or SimRicochet.rule(-1600.0, 3000.0, SimRicochet.maxInRow)[0] != 0.0 or SimRicochet.rule(500.0, 3000.0, 0)[0] != 0.0:
		return "rule: under the line, steeper, a full row, moving away"
	if SimRicochet.steepGround(0.0) or SimRicochet.steepGround(0.5) or not SimRicochet.steepGround(0.6) or not SimRicochet.steepGround(-0.7):
		return "the slope's scope: ground of slope 0 and 0.5 (27 degrees) is not a ricochet's, 0.6 and -0.7 are"
	var pv: PackedFloat64Array = SimRicochet.predict(3000.0, -1600.0, 0.0, 1.0, 0)
	if pv[0] != 1.0 or absf(pv[1] - K * 3000.0) > 1e-9 or absf(pv[2] - K * 1600.0) > 1e-9:
		return "predict on a level surface: %s" % str(pv)
	var pw: PackedFloat64Array = SimRicochet.predict(1600.0, 3000.0, -1.0, 0.0, 0)
	if pw[0] != 1.0 or absf(pw[1] + K * 1600.0) > 1e-9 or absf(pw[2] - K * 3000.0) > 1e-9:
		return "predict on a face toward -x: %s" % str(pw)
	# steep ground: sends at the test world's 49-degree uphill, a given angle into the slope; and the same fast shallow
	# send on level ground. [name, degrees into the slope (or -1: level ground, 30 down), force, on, full row, curve]
	var cases: Array = [["glance", 20.0, 3000.0, true, false, false],
		["off", 20.0, 3000.0, false, false, false],
		["full row", 20.0, 3000.0, true, true, false],
		["slow", 20.0, 1200.0, true, false, false],
		["steep", 60.0, 3000.0, true, false, false],
		["curve", 20.0, 3000.0, true, false, true],
		["level", -1.0, 5000.0, true, false, false]]
	var got: Dictionary = {}
	var rad: float = SimMathx.f64("400921fb54442d18") / 180.0
	for c in cases:
		var M := SimCore.createSim()
		SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"ricochet": c[3], "flight": c[5]})
		var A = M.fighters[0]
		var D = M.fighters[1]
		var dir: Dictionary = {"ux": 0.866, "uy": -0.5}
		if c[1] >= 0.0:
			D.x = _steepX(M)
			if D.x < 0.0:
				return "the test world has no steep uphill of 480 units"
			var s: float = (WorldTerrain.groundY(M, SimWrap.wrap(D.x + 8.0)) - WorldTerrain.groundY(M, D.x)) / 8.0
			var q: float = sqrt(1.0 + s * s)
			var ca: float = SimDetMath.cos(float(c[1]) * rad)
			var sa: float = SimDetMath.sin(float(c[1]) * rad)
			dir = {"ux": (ca + sa * s) / q, "uy": (ca * s - sa) / q}   # the slope's tangent turned c[1] degrees into it
			D.y = WorldTerrain.groundY(M, D.x) + 25.0
		else:
			D.x = _flatX(M, D.x)
			D.y = WorldTerrain.groundY(M, D.x) + 40.0
		DirLaunch.doLaunch(M, A, D, dir, c[2], false)
		if c[4]:
			D.ricN = D.launchN
			D.rics = SimRicochet.maxInRow
		var res := {"ric": [], "bounce": [], "land": "", "contact": false, "before": 0.0, "state": "", "vy": 0.0, "end": ""}
		var prev: float = 0.0
		for t in range(1, 60):
			prev = SimDetMath.hypot(D.vx / D.launchT, D.vy)
			SimCore.step(M, [null, null])
			for e in M.out.fx:
				if e.type == "ricochet":
					res.ric.append(e)
					res.before = prev
					res.state = D.state
					res.vy = D.vy
				elif e.type == "bounce":
					res.contact = true
					if res.bounce.is_empty():
						res.bounce.append(e.keep)
				elif e.type == "land":
					res.contact = true
					if res.land == "":
						res.land = String(e.kind)
				elif e.type == "flight" and e.text == "end":
					res.end = String(e.kind)
			M.out.fx.clear()
			M.out.feed.clear()
			if not res.ric.is_empty() or res.contact:
				break
		got[c[0]] = res
		SimCore.dispose(M)
	var g: Dictionary = got["glance"]
	if g.ric.size() != 1 or String(g.ric[0].kind) != "glance" or g.state != "launched" or g.vy <= 0.0 or int(g.ric[0].n) != 1:
		return "a fast send 20 degrees into a steep slope: %d glances told, he is %s going %s" % [g.ric.size(), g.state, "up" if g.vy > 0.0 else "down"]
	if absf(g.ric[0].amount - K * g.before) > 0.04 * g.before or g.bounce.is_empty() or g.bounce[0] != K:
		return "the glance kept %.0f of %.0f (want about %.0f), World's bounce keep %s" % [g.ric[0].amount, g.before, K * g.before, str(g.bounce)]
	for k in ["off", "full row", "slow", "steep", "level"]:
		if not got[k].ric.is_empty() or not got[k].contact:
			return "%s: %d glances, a contact %s (want none, and World's contact)" % [k, got[k].ric.size(), str(got[k].contact)]
	if got["level"].land != "skid":
		return "a fast shallow send on level ground landed '%s' (want Orb's skid)" % got["level"].land
	var cv: Dictionary = got["curve"]
	if cv.ric.size() != 1 or cv.end != "glance":
		return "with the curve on: %d glances, its paced leg ended '%s' (want glance)" % [cv.ric.size(), cv.end]
	# a building's face: a steep send glances, a level one does not
	var B := SimCore.createSim()
	SimCore.newMatch(B, 5, {"p1": false, "p2": false}, {"ricochet": true})
	var BD = B.fighters[1]
	var bb = B.buildings[0]
	BD.state = "launched"
	BD.launchT = 1.0
	BD.vx = 400.0
	BD.vy = 1000.0
	BD.aimB = bb.idx
	B.out.fx.clear()
	if SimRicochet.offFace(B, BD, bb, BD.y, bb.x - bb.w * 0.5, 1.0) or BD.aimB != bb.idx:
		return "a face met at a whole 1,077 glanced (under the line)"
	BD.vx = 2000.0
	BD.vy = 3000.0
	if not SimRicochet.offFace(B, BD, bb, BD.y + 10.0, bb.x - bb.w * 0.5, 1.0):
		return "a steep send at 2,000 into a face did not glance"
	if BD.vx != -K * 2000.0 or BD.vy != K * 3000.0 or BD.aimB != -1 or B.out.fx.is_empty() or B.out.fx[B.out.fx.size() - 1].type != "ricochet" or BD.rics != 1:
		return "the face's glance: velocity (%s, %s), aim %d, rics %d" % [str(BD.vx), str(BD.vy), BD.aimB, BD.rics]
	BD.vx = 5000.0
	BD.vy = 500.0
	BD.aimB = bb.idx
	if SimRicochet.offFace(B, BD, bb, BD.y, bb.x - bb.w * 0.5, 1.0):
		return "a level send into a face glanced (it is the wall slam's)"
	SimCore.dispose(B)
	# a ricochet match replays
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 11, {}, {"ricochet": true})
	for t in range(3600):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != SimReplay.dataHash({"ricochet": true}) or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a ricochet match does not carry its data, or does not play back"
	return ""


## The first x from `from` (in steps of 160) with 640 units of dry ground ahead within 3 units of level.
## The run's stage ground (run-core.md section 11): the run's keyed hash pinned; the first stage Close round the
## player's home, and turned toward land, holding it, for a coastal home (Game Design's 2026-10-23 6); a stage between picked from its opponent's claim, the same stepped a candidate a frame as at once,
## and its setup (read back from JSON, as a header is) building the match on that ring; with that arena in `used`,
## another ring and no repeat; the boss on the Whole circle through his home, under Game Design's waiver when it
## misses Whole's minimum, and on his claim when no other place stands. The data ships off.
func _runGround() -> String:
	SimRun.reload()
	if not SimRun.errors().is_empty():
		return "the run's data: %s" % str(SimRun.errors())
	if SimRun.groundOn():
		return "the run's ground is on in the data (it ships off)"
	var run: String = "00c0ffee0badf00d"
	var pins: Array = [SimRun.planetSeed(run), SimRun.stageSeed(run, 1, 0), SimRun.stageSeed(run, 2, 0)]
	if pins != [2634364773, 2944602543, 4034252320]:
		return "H: the planet and two stage seeds are %s (want [2634364773, 2944602543, 4034252320]: a port gives the same)" % str(pins)
	if SimRun.H(run, "ground", 2, 0) == SimRun.H(run, "ground", 2, 1) or SimRun.H(run, "ground", 2, 0) == SimRun.H(run, "ground", 3, 0):
		return "H: the chapter and the offer don't part the streams"
	var P: WorldPlanet.Planet = WorldPlanet.make(SimRun.planetSeed(run))
	var hm: Dictionary = SimRun.homes(P)
	var g1: SimRun.GroundJob = SimRun.beginGround(run, 1, "RIVAL")
	g1.finishNow()
	if g1.rule != "first" or int(g1.result.spec.cols) != WorldRingPick.sizeCols("close") or not _ringHolds(g1.result.ev, int(hm.PROTAGONIST)):
		return "the first stage: rule %s, %d columns, the player's home held %s (want first, Close, held)" % [g1.rule, int(g1.result.spec.cols), str(_ringHolds(g1.result.ev, int(hm.PROTAGONIST)))]
	if g1.result.get("turned", true):
		return "the first stage turned a ring that meets Close's minimum"
	var coast: String = "0123456789abcdef"   # its stand-in home is a coastal city: the ring round it is 70% ocean
	WorldPlanet.make(SimRun.planetSeed(coast))   # made already, as in a run's later stages: a cold planet is made over the first reads (host_check), which are not candidates
	var gc: SimRun.GroundJob = SimRun.beginGround(coast, 1, "RIVAL")
	var fc: int = 1
	while not gc.frame():
		fc += 1
	var hc: Dictionary = SimRun.homes(WorldPlanet.make(SimRun.planetSeed(coast)))
	if not gc.result.get("turned", false) or not gc.result.ok or not _ringHolds(gc.result.ev, int(hc.PROTAGONIST)) or gc.reads != fc:
		return "a coastal home's first ring: turned %s, ok %s, home held %s, %d reads in %d frames (want turned, ok, held, a read a frame)" % [str(gc.result.get("turned")), str(gc.result.ok),
			str(_ringHolds(gc.result.ev, int(hc.PROTAGONIST))), gc.reads, fc]
	var g2: SimRun.GroundJob = SimRun.beginGround(run, 2, "EMPRESS")
	var frames: int = 1
	while not g2.frame():
		frames += 1
	var g2b: SimRun.GroundJob = SimRun.beginGround(run, 2, "EMPRESS")
	g2b.finishNow()
	var want: int = int(WorldRingPick.cfg().candidates.half)
	if g2.rule != "claim" or g2.size != "half" or g2.reads != want or frames != want or JSON.stringify(g2.setup()) != JSON.stringify(g2b.setup()) or not g2.result.ok:
		return "a stage between: rule %s, size %s, %d reads in %d frames (want claim, half, %d in %d), the same at once %s, ok %s" % [g2.rule, g2.size, g2.reads, frames, want, want,
			str(JSON.stringify(g2.setup()) == JSON.stringify(g2b.setup())), str(g2.result.ok)]
	var S := SimCore.createSim()
	SimCore.newMatch(S, g2.matchSeed(), {}, JSON.parse_string(JSON.stringify(g2.setup())))
	var cols: int = S.arenaCols
	SimCore.dispose(S)
	if cols != WorldRingPick.sizeCols("half"):
		return "a stage's setup built a match of %d columns, not its ring's %d" % [cols, WorldRingPick.sizeCols("half")]
	var g3: SimRun.GroundJob = SimRun.beginGround(run, 2, "EMPRESS", {"used": [JSON.parse_string(JSON.stringify(g2.setup().arena))]})
	g3.finishNow()
	if JSON.stringify(g3.setup()) == JSON.stringify(g2.setup()) or g3.result.get("repeat", true) or g2.result.get("repeat", true):
		return "with the stage's arena as fought (through JSON): the same ring %s, repeat %s (want another ring and no repeat)" % [str(JSON.stringify(g3.setup()) == JSON.stringify(g2.setup())), str(g3.result.get("repeat"))]
	var g4: SimRun.GroundJob = SimRun.beginGround(run, SimRun.stages + 1, "RIVAL")
	g4.finishNow()
	if g4.rule != "boss" or int(g4.result.spec.cols) != SimConst.PLANET_NC or not _ringHolds(g4.result.ev, int(hm.RIVAL)):
		return "the boss: rule %s, %d columns, his home held %s (want boss, the Whole circle, held)" % [g4.rule, int(g4.result.spec.cols), str(_ringHolds(g4.result.ev, int(hm.RIVAL)))]
	if not g4.result.ok and not (g4.result.waived and SimRun.bossWaived(g4.result.ev, int(hm.RIVAL))):
		return "the boss's ring is under Whole's minimum without Game Design's waiver (his home and a standing city held)"
	var st := PackedByteArray()
	st.resize(P.n)
	st.fill(0)
	st[int(hm.RIVAL)] = 1
	var g5: SimRun.GroundJob = SimRun.beginGround(run, SimRun.stages + 1, "RIVAL", {"standing": st})
	if g5.rule != "boss_claim" or g5.size != "whole":
		return "the boss with no other place standing: rule %s, size %s (want his claim at Whole)" % [g5.rule, g5.size]
	return ""


## The run state and its carry (run-core.md section 12): a scripted run through the carry's rules (place statuses at
## their lines, wounds, fills, lives, the ceiling, Dread and its cap, a retry, a run ended, the Endless assist), the carry
## pure, the hash the same through JSON, the chain, and beginGround's inputs from the history.
func _runState() -> String:
	SimRun.reload()
	if not SimRun.errors().is_empty():
		return "the run's data: %s" % str(SimRun.errors())
	var run: String = "00c0ffee0badf00d"
	var s0: Dictionary = SimRun.newRun(run, "story", "PROTAGONIST", 100000)
	if int(s0.player.lives) != 2 or int(s0.chapter) != 1 or SimRun.checkState(s0) != "" or int(SimRun.newRun(run, "hard", "PROTAGONIST", 1).player.lives) != 0:
		return "a new run: lives %d, chapter %d, check '%s' (want 2 lives on Story, 0 on Hard, chapter 1)" % [int(s0.player.lives), int(s0.chapter), SimRun.checkState(s0)]
	# a won first fight: place 3 loses 2 of its 40 buildings (5%: damaged); place 7 keeps 3 of 10 standing (fallen: its
	# 100 fled are gone for good); place 12 keeps 4 of 10 (40% is not under 40%: damaged); the villain kills 50; a
	# region broken at the end, so no life for a clean win, and a lifeline taken
	var a1: Dictionary = {"cols": 1200, "c": ["3ff0000000000000", "0", "0"], "t": ["0", "3ff0000000000000", "0"]}
	var e1: Dictionary = {"result": "won", "opponent": "RIVAL", "villain": true, "offer": "first", "ticks": 9000, "how": "ko", "finisher": "", "arena": a1,
		"wounds": [0, 2, 3, 0], "fills": {"witness": 801, "trial": 333}, "branches": ["witness"], "ash": 0, "boon": {"kind": "lifeline", "id": "lifeline"},
		"places": {"3": {"buildings": 40, "people": 2000, "down": 2, "dead": {"player": 0, "opponent": 10, "other": 0}, "fled": 30, "wear": [1, 2, 3]},
			"7": {"buildings": 10, "people": 1000, "down": 7, "dead": {"player": 5, "opponent": 40, "other": 0}, "fled": 100},
			"12": {"buildings": 10, "people": 1000, "down": 6, "dead": {"player": 0, "opponent": 0, "other": 0}, "fled": 0}}}
	var h0: String = SimRun.stateHash(s0)
	var s1: Dictionary = SimRun.carry(s0, e1)
	if SimRun.stateHash(s0) != h0:
		return "carry changed the state it was given"
	var st: Array = [s1.places["3"].status, s1.places["7"].status, s1.places["12"].status, int(s1.places["7"].gone), s1.places["3"].wear]
	if st != ["damaged", "fallen", "damaged", 100, [1, 2, 3]]:
		return "the places after a won fight: %s (want damaged at 5%% down, fallen under 40%% standing with its fled gone, damaged at exactly 40%%, the wear kept)" % str(st)
	var p1: Array = [s1.player.wounds, int(s1.player.lives), s1.player.fills, int(s1.chapter), int(s1.villainKills), int(s1.dread), s1.ledger[0].fell, s1.ledger[0].dead]
	if str(p1) != str([[0, 1, 2, 0], 3, {"witness": 400, "trial": 166}, 2, 50, 1, [7], {"player": 5, "opponent": 50, "other": 0}]):
		return "the carry after a won fight: %s (want wounds a stage healed, 3 lives, fills at half, chapter 2, 50 kills, Dread 1, place 7 fell)" % str(p1)
	# a lost fight: a life spent, the state otherwise the one the fight began with
	var s2: Dictionary = SimRun.carry(s1, {"result": "lost", "opponent": "EMPRESS", "villain": true, "offer": "rampage"})
	var s1b: Dictionary = s1.duplicate(true)
	s1b.player.lives = 2
	s1b.player.livesSpent = 1
	if SimRun.stateHash(s2) != SimRun.stateHash(s1b):
		return "a lost fight changed more than a life (lives %d, spent %d, chapter %d)" % [int(s2.player.lives), int(s2.player.livesSpent), int(s2.chapter)]
	# the retry won clean on a Crossing (a rest) with a form; the villain kills 60,000 of place 20 (fallen on people
	# present; Dread at its cap); place 7's 20 fled are gone, as it has fallen
	var a3: Dictionary = {"cols": 2400, "c": ["0", "0", "3ff0000000000000"], "t": ["3ff0000000000000", "0", "0"]}
	var e3: Dictionary = {"result": "won", "opponent": "EMPRESS", "villain": true, "offer": "crossing", "ticks": 8000, "how": "ko", "arena": a3,
		"wounds": [1, 1, 1, 1], "fills": {"witness": 0, "trial": 1000}, "branches": ["witness", "trial"], "ash": 120, "boon": {"kind": "form", "id": "form"},
		"places": {"7": {"buildings": 10, "people": 1000, "down": 7, "dead": {}, "fled": 20},
			"20": {"buildings": 50, "people": 70000, "down": 1, "dead": {"opponent": 60000}, "fled": 0}}}
	var s3: Dictionary = SimRun.carry(s2, e3)
	var p3: Array = [s3.player.wounds, int(s3.player.lives), int(s3.player.ceiling), int(s3.dread), s3.places["20"].status, int(s3.places["7"].gone), int(s3.sky), int(s3.chapter)]
	if str(p3) != str([[0, 0, 0, 0], 3, 1, 1000, "fallen", 120, 120, 3]):
		return "the retry won: %s (want all healed on a Crossing, 3 lives at most, ceiling 1, Dread at 1000, place 20 fallen, 120 gone from 7, sky 120, chapter 3)" % str(p3)
	# through JSON: the same hash, a valid header state, and the same next state
	var sj = JSON.parse_string(JSON.stringify(s3))
	var e4: Dictionary = {"result": "won", "opponent": "CYBORG", "villain": true, "offer": "proving", "wounds": [3, 0, 0, 0], "places": {"3": {"buildings": 40, "people": 2000, "down": 20, "dead": {"other": 5}, "fled": 1}}}
	if SimRun.stateHash(sj) != SimRun.stateHash(s3) or SimRun.checkState(sj) != "" or SimRun.stateHash(SimRun.carry(sj, e4)) != SimRun.stateHash(SimRun.carry(s3, e4)):
		return "a run state through JSON hashes or carries differently"
	# beginGround's inputs from the history
	var P: WorldPlanet.Planet = WorldPlanet.make(SimRun.planetSeed(run))
	var go: Dictionary = SimRun.groundOpts(s3, P)
	if P.n <= 20 or go.standing[7] != 0 or go.standing[20] != 0 or go.standing[3] != 1 or go.damaged != [3, 7, 12, 20] or str(go.used) != str([a1, a3]):
		return "the ground's inputs: standing 3/7/20 %d/%d/%d, damaged %s, used %d (want 1/0/0, [3, 7, 12, 20], the two rings won on)" % [go.standing[3], go.standing[7], go.standing[20], str(go.damaged), go.used.size()]
	# the end of a run: with no life left a loss ends it, and an ended run carries no further; Endless spends none
	var sh: Dictionary = SimRun.carry(SimRun.newRun(run, "hard", "PROTAGONIST", 1000), {"result": "lost", "opponent": "RIVAL"})
	var se: Dictionary = SimRun.carry(SimRun.newRun(run, "hard", "PROTAGONIST", 1000, {"endless": true}), {"result": "lost", "opponent": "RIVAL"})
	if sh.over != "lost" or sh.ledger.size() != 1 or SimRun.stateHash(SimRun.carry(sh, e1)) != SimRun.stateHash(sh) or se.over != "" or int(se.player.livesSpent) != 1:
		return "the run's end: over '%s', ledger %d, Endless over '%s' spent %d (want lost, 1, none, 1)" % [sh.over, sh.ledger.size(), se.over, int(se.player.livesSpent)]
	# the chain, and the scripted run's hashes pinned (a port gives the same)
	var l1: String = SimRun.nextLink(SimRun.link0(run), h0, "f00d", SimRun.stateHash(s1))
	var pins: Array = [SimRun.link0(run), SimRun.stateHash(s3), l1]
	if pins != ["d5c064e0", "188282d20a745852", "5801d92edd95f0f2"] or l1 == SimRun.nextLink(SimRun.link0(run), h0, "f00e", SimRun.stateHash(s1)):
		return "the chain and the scripted run: %s (want the pinned three, and a link that moves with the final hash)" % str(pins)
	return ""


## The campaign's arc and episode (campaign-core.md), on World's columns:
## - the data ships off; the seeds are pinned; a filler arc's families and villain;
## - a whole episode, five columns of World's, played twice and the same to the bit;
## - each site flown to is one of its column's; the climax is the villain's home on the whole circle; the sites are kept
##   as whole numbers;
## - the run state through JSON; a site not of its column refused; the wear merged by the worse band and handed to the
##   next stage's setup;
## - a main-story episode's card and the season record (mc02), and its side story's n.5 on a copy of the planet;
## - threads as ids, filler never resolving a main-story one;
## - QA's campaign record from the run state (docs/qa/rally-campaign-rows.md), the same through JSON;
## - no fighter, director or input file names the campaign (Legal mc01, mc06).
func _campaign() -> String:
	SimCampaign.reload()
	if not SimCampaign.errors().is_empty():
		return "the campaign's data: %s" % str(SimCampaign.errors())
	if SimCampaign.enabled():
		return "the campaign is on in the data (it ships off)"
	var arcId: String = "c0ffee00c0ffee00"
	var pins: Array = [SimCampaign.episodeSeed(arcId, 0), SimCampaign.episodeRun(arcId, 0), SimCampaign.arcPlanet(arcId), SimCampaign.mix(7, "column", 2, 1), SimCampaign.arcSeed(arcId)]
	if str(pins) != str([2515801561, "95f415d9fb019b1a", 2172332729, 3808475095, 1643510628]):
		return "the campaign's seeds: %s (want the pinned five: a port gives the same)" % str(pins)
	var arc: Dictionary = SimCampaign.newArc(arcId, "filler_arc")
	if arc.families.size() != 2 or arc.families[0] == arc.families[1] or not SimCampaign.families.has(arc.families[0]) or not SimCampaign.families.has(arc.families[1]) or arc.villain != "RIVAL" or SimCampaign.checkArc(arc) != "" or SimCampaign.cardNumber(arc) != "":
		return "a filler arc: families %s, villain %s, check '%s', card '%s' (want two different filler families, the RIVAL, sound, no number)" % [str(arc.families), arc.villain, SimCampaign.checkArc(arc), SimCampaign.cardNumber(arc)]
	# a whole episode on World's columns, twice
	var e1: Dictionary = SimCampaignRun.play(arcId, "filler_arc", 120)
	var e2: Dictionary = SimCampaignRun.play(arcId, "filler_arc", 120)
	if JSON.stringify(e1.stages) != JSON.stringify(e2.stages) or e1.run != e2.run or JSON.stringify(e1.arc) != JSON.stringify(e2.arc):
		return "an episode played twice differs"
	var a1: Dictionary = e1.arc
	var n: int = SimCampaign.columns
	if not a1.done or a1.taken.size() != n or a1.columns.size() != n or e1.stages.size() != n:
		return "an episode: done %s, %d taken, %d columns, %d stages (want done and %d of each)" % [str(a1.done), a1.taken.size(), a1.columns.size(), e1.stages.size(), n]
	var P: WorldPlanet.Planet = WorldPlanet.make(SimCampaign.arcPlanet(arcId))
	for c in range(n):
		if SimCampaign.siteOf(a1, c, int(a1.taken[c])).is_empty():
			return "column %d: site %d flown to is not one of its %s" % [c + 1, int(a1.taken[c]), str(a1.columns[c])]
	var home: int = int(SimRun.homes(P).get("RIVAL", -1))
	var last: Dictionary = e1.stages[n - 1]
	if a1.columns[n - 1].size() != 1 or int(a1.columns[n - 1][0].place) != home or int(last.cols) != SimConst.PLANET_NC:
		return "the climax: %s on a %d-column ring (want the villain's home, %d, on the whole circle)" % [str(a1.columns[n - 1]), int(last.cols), home]
	for k in range(a1.used.size()):
		for j in range(k):
			if int(a1.used[j]) == int(a1.used[k]):
				return "the episode used place %d twice" % int(a1.used[k])
	# the cross-back (campaign.md 2.2): none asked when column 2 left no named place untaken; a seeded filler arc whose rise
	# left one has it asked at column 4 and offered there, leading the sites (World's prefer)
	if int(a1.back) != SimCampaign.crossBackPlace(a1) or (int(a1.back) >= 0 and not a1.columns[SimCampaign.crossTo - 1].any(func(x): return int(x.place) == int(a1.back))):
		return "the cross-back of %s: asked %d, column 2's untaken place %d" % [arcId, int(a1.back), SimCampaign.crossBackPlace(a1)]
	var backArc: String = "0bac000000017334"   # its rise leaves place 12 untaken; World offers it again at column 4
	var ab: Dictionary = SimCampaignRun.play(backArc, "filler_arc", 60).arc
	var lead: Dictionary = ab.columns[SimCampaign.crossTo - 1][0] if ab.columns.size() >= SimCampaign.crossTo and not ab.columns[SimCampaign.crossTo - 1].is_empty() else {}
	if SimCampaign.crossFrom != 2 or SimCampaign.crossTo != 4 or int(ab.back) < 0 or int(ab.back) != SimCampaign.crossBackPlace(ab) or lead.is_empty() or int(lead.place) != int(ab.back) or int(lead.preferred) != 1:
		return "the cross-back of %s: from %d to %d, asked %d, column 4 led by %s (want 2 to 4, column 2's untaken place asked, leading and preferred)" % [backArc, SimCampaign.crossFrom, SimCampaign.crossTo, int(ab.back), str(lead)]
	var sj = JSON.parse_string(JSON.stringify(e1.state))
	if SimRun.stateHash(sj) != e1.run or SimRun.checkState(sj) != "":
		return "an episode's run state through JSON: hash %s, check '%s'" % [SimRun.stateHash(sj), SimRun.checkState(sj)]
	# QA's record: the fights' seconds from the ledger, each column's ring by World's size name, its turn and its places from the pair
	var qr: Dictionary = e1.campaign
	var ledTicks: int = 0
	for rec in e1.state.ledger:
		ledTicks += int(rec.ticks)
	var qrOk: bool = qr.arc == arcId and qr.columns.size() == n and int(qr.episodeSec) == int(round(float(ledTicks) * SimConst.DT)) and ledTicks > 0
	for c in range(mini(n, qr.columns.size())):
		var qc: Dictionary = qr.columns[c]
		qrOk = qrOk and int(qc.n) == c + 1 and qc.turned == (int(a1.turns[c]) != 0) and qc.places.size() == a1.columns[c].size() and int(qc.places[0].fromPair) == int(a1.columns[c][0].dir) * int(a1.columns[c][0].entry)
	qrOk = qrOk and String(qr.columns[n - 1].ring) == "Whole" and (int(a1.rings[0]) != 2400 or String(qr.columns[0].ring) == "Half")
	qrOk = qrOk and int(qr.rescues.n) == 0 and int(qr.rematches.n) == 0 and int(qr.partner.stages) == 0 and qr.templates.is_empty() and qr.arcTemplates.is_empty()
	if not qrOk or JSON.stringify(SimCampaign.qaRecord(sj)) != JSON.stringify(qr):
		return "QA's campaign record: %s (want the arc, %d columns with rings, turns and places from the pair, the ledger's seconds; the same through JSON)" % [JSON.stringify(qr), n]
	# a site not of the column is refused; the wear is merged by the worse band and handed to the next stage's setup
	var quiet: bool = FighterData.quiet
	FighterData.quiet = true
	var s0: Dictionary = SimCampaign.newEpisode(arc, 0, P, {"people": 100000})
	var job: WorldCampaign.ColumnJob = SimCampaign.beginColumn(s0, P)
	job.step(1 << 30)
	s0 = SimCampaign.columnDone(s0, job.result)
	var nErr: int = SimCampaign.errors().size()
	var sr: Dictionary = SimCampaign.advance(s0, {"result": "won", "site": 99, "wear": {}}, P)
	var refused: bool = SimRun.stateHash(sr) == SimRun.stateHash(s0) and SimCampaign.errors().size() == nErr + 1
	var site0: Dictionary = s0.arc.columns[0][0]
	var s1: Dictionary = SimCampaign.advance(s0, {"result": "won", "site": int(site0.id), "wear": {"5": 2}}, P)
	var w1: Dictionary = s1.arc.wear.duplicate()
	s1.arc.column = 0   # the same column again, to merge a second stage's wear (a test's shortcut)
	s1.arc.columns = [s1.arc.columns[0]]
	var s2: Dictionary = SimCampaign.advance(s1, {"result": "won", "site": int(site0.id), "wear": {"5": 1, "7": 3}}, P)
	var su: Dictionary = SimCampaign.stageSetup(s2, site0, ["PROTAGONIST", "RIVAL"], P)
	var wearOk: bool = w1 == {"5": 2} and s2.arc.wear == {"5": 2, "7": 3} and su.wear == s2.arc.wear and su.planet == int(s2.planet.seed)
	# threads: ids only; filler never resolves a main-story thread
	var st: Dictionary = SimCampaign.openThread(SimCampaign.openThread(e1.state, "grudge:RIVAL"), "main:the-pier")
	var st2: Dictionary = SimCampaign.openThread(st, "Lost 400 people")
	var threadsOk: bool = st.arc.threads == ["grudge:RIVAL", "main:the-pier"] and st2.arc.threads == st.arc.threads
	threadsOk = threadsOk and SimCampaign.closeThread(st, "main:the-pier").arc.threads == st.arc.threads and SimCampaign.closeThread(st, "grudge:RIVAL").arc.threads == ["main:the-pier"]
	FighterData.quiet = quiet
	if not refused or not wearOk or not threadsOk:
		return "the route: a site not of its column refused %s; the wear %s then %s, in the setup %s; threads %s" % [str(refused), str(w1), str(s2.arc.wear), str(su.wear == s2.arc.wear), str(threadsOk)]
	# a main-story episode: its card is its number, the season moves up when it is won, and a side story reads n.5
	var m: Dictionary = {}
	var mainId: String = ""
	for k in range(24):   # half of the episodes draw one; World places it in the band, widened or turned (rulings-2026-10-26 item 2)
		var id: String = "%016x" % (0x5eed000000000000 + k * 7919)
		if SimRun.H(id, "side", 12, 0) % 1000 >= SimCampaign.sideShare:
			continue
		m = SimCampaignRun.play(id, "main_episode", 60, {"number": 12})
		if m.arc.side.offered:
			mainId = id
			break
	if mainId == "":
		return "no main-story episode of 24 offered a side story (World found no named place on each's last ring, or on it turned)"
	var season: Dictionary = SimCampaign.seasonAfter(SimCampaign.newSeason(), m.state)
	var extra: Dictionary = season.duplicate()
	extra["player"] = "x"
	if SimCampaign.cardNumber(m.arc) != "12" or int(season.lastMain) != 12 or SimCampaign.checkSeason(season) != "" or SimCampaign.checkSeason(extra) == "":
		return "a main-story episode: card '%s', season %s, a season with a name refused %s (want 12, lastMain 12, refused)" % [SimCampaign.cardNumber(m.arc), str(season), str(SimCampaign.checkSeason(extra) != "")]
	var PM: WorldPlanet.Planet = WorldPlanet.make(SimCampaign.arcPlanet(mainId))
	var side: Dictionary = SimCampaign.openSide(m.state, PM)
	if not ["band", "widened", "turned"].has(String(m.arc.side.how)) or side.is_empty() or SimCampaign.cardNumber(side.arc) != "12.5" or side.arc.kind != "filler_episode" or int(side.planet.seed) != int(m.state.planet.seed) or side.arc.wear != m.arc.wear or side.arc.ring != m.arc.side.ring or side.arc.families != [m.arc.side.family]:
		return "the side story: card '%s', kind %s (want World's how, and 12.5, a filler episode, on the main arc's planet and wear, on its own ring)" % [SimCampaign.cardNumber(side.arc) if not side.is_empty() else "", side.get("arc", {}).get("kind", "")]
	# no fighter, director or input file names the campaign (Legal mc01 and mc06: nothing of it reaches a fighter)
	var files: Array = []
	for dir in ["res://sim/core/", "res://sim/director/", "res://sim/input/"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd") and not ["campaign.gd", "run.gd"].has(f):
				files.append(dir + f)
	for path in files:
		var text: String = FileAccess.get_file_as_string(path)
		if text.contains("SimCampaign") or text.contains("state.arc") or text.contains("arc_villain"):
			return "%s names the campaign: no fighter reads it (mc01, mc06)" % path
	return ""


## The planet's load (planet-load.md): a host loads a gen 2 planet, and its match's ring, in steps before a match.
## - with strict on, a match's start refuses a gen 2 planet that is not made, and leaves the state as it was; a gen 1
##   planet is never refused;
## - stepped, the load climbs from 0 to 1 through the plates, the climate grid, the places and the ring, and then the
##   match starts: the same match, to the bit, as one started cold, on a planet that is make's;
## - a ring an arena names, read in slices of columns, gives the same match as one read in one piece, and a second load
##   of it has nothing to do;
## - the campaign's column job refuses a gen 2 planet not made (strict), and takes it once the arc's planet is loaded.
func _planetLoad() -> String:
	var seed: int = 13
	var su: Dictionary = {"planet": seed, "planetGen": 2, "touch": 3, "arena": {"cols": 2400}, "intro": false}
	var quiet: bool = FighterData.quiet
	FighterData.quiet = true
	WorldPlanet.forget()
	SimPlanetLoad.strict = true
	var n0: int = SimPlanetLoad.refused
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {}, {"intro": false})   # a match already running: a refused start leaves it as it was
	var h0: String = str(SimHash.stateHash(S).gameplay)
	SimCore.newMatch(S, 1, {}, su)
	var refusedOk: bool = SimPlanetLoad.refused == n0 + 1 and str(SimHash.stateHash(S).gameplay) == h0 and not SimPlanetLoad.mayStart(su)
	var gen1Ok: bool = SimPlanetLoad.mayStart({"planet": seed, "planetGen": 1}) and SimPlanetLoad.mayStart({})
	var job: SimPlanetLoad.Job = SimPlanetLoad.beginFor(su)
	var phases: Array = [job.phase]
	var last: float = job.progress()
	var climbs: bool = last == 0.0
	while not job.step(SimRun.planetUnitsPerRead * 40):   # 40 reads' worth a step, to keep the check short
		climbs = climbs and job.progress() >= last and job.progress() < 1.0
		last = job.progress()
		if phases[phases.size() - 1] != job.phase:
			phases.append(job.phase)
	phases.append(job.phase)
	climbs = climbs and job.progress() == 1.0
	SimCore.newMatch(S, 1, {}, su)
	var startOk: bool = SimPlanetLoad.mayStart(su) and SimPlanetLoad.refused == n0 + 1 and S.planetGen == 2
	var hLoaded: String = str(SimHash.stateHash(S).gameplay)
	SimCore.dispose(S)
	SimPlanetLoad.strict = false
	var PL: WorldPlanet.Planet = job.P
	WorldPlanet.forget()
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 1, {}, su)   # cold: the planet made inside the start, as tools do
	var sameMatch: bool = str(SimHash.stateHash(S2).gameplay) == hLoaded
	SimCore.dispose(S2)
	WorldClimate.useGen(2)
	var PM: WorldPlanet.Planet = WorldPlanet.make(seed)
	var same: bool = PL != PM and PL.n == PM.n and PL.kind == PM.kind and PL.px == PM.px and PL.py == PM.py and PL.pz == PM.pz and PL.rad == PM.rad and PL.people == PM.people and PL.grid.ht == PM.grid.ht and PL.grid.adv == PM.grid.adv
	# a ring an arena names: read in slices of columns by the load, then the same match as one read in one piece
	var arena: Dictionary = WorldRingPick.arenaOf(WorldRingPick.roundSpec(WorldRingPick.placePoint(PM, 0), 2400, 0.7))
	WorldClimate.useGen(0)
	var sr: Dictionary = {"planet": seed, "planetGen": 2, "arena": arena, "intro": false}
	var jr: SimPlanetLoad.Job = SimPlanetLoad.beginFor(sr)
	var ringPhase: bool = jr.phase == "ring"
	while not jr.step(SimRun.planetUnitsPerRead):
		ringPhase = ringPhase and jr.phase == "ring"
	var S3 := SimCore.createSim()
	SimCore.newMatch(S3, 2, {}, sr)
	var hRing: String = str(SimHash.stateHash(S3).gameplay)
	SimCore.dispose(S3)
	var again: bool = SimPlanetLoad.beginFor(sr).done   # read already: nothing to load
	WorldPlanet.forget()
	var S4 := SimCore.createSim()
	SimCore.newMatch(S4, 2, {}, sr)
	var sameRing: bool = str(SimHash.stateHash(S4).gameplay) == hRing and jr.frames > 1 and again
	SimCore.dispose(S4)
	WorldPlanet.forget()
	WorldClimate.useGen(0)
	# the campaign's host loads the arc's planet first: with strict on, a column's job refuses a gen 2 planet not made
	SimPlanetLoad.strict = true
	WorldClimate.useGen(2)
	var arcId: String = "c0ffee00c0ffee00"
	var nr: int = SimPlanetLoad.refused
	var coldRefused: bool = SimCampaign.beginColumn({"planet": {"seed": SimCampaign.arcPlanet(arcId)}}, null) == null and SimPlanetLoad.refused == nr + 1
	SimCampaign.beginLoad(arcId).finishNow()
	var PA: WorldPlanet.Planet = WorldPlanet.make(SimCampaign.arcPlanet(arcId))
	var sa: Dictionary = SimCampaign.newEpisode(SimCampaign.newArc(arcId, "filler_arc"), 0, PA, {"people": 100000})
	var campOk: bool = coldRefused and SimCampaign.beginColumn(sa, PA) != null and SimPlanetLoad.refused == nr + 1
	SimPlanetLoad.strict = false
	WorldPlanet.forget()
	WorldClimate.useGen(0)
	if not campOk:
		FighterData.quiet = quiet
		return "the planet's load: the campaign's column refuses a cold gen 2 planet %s, and takes it once the arc's planet is loaded %s" % [str(coldRefused), str(campOk)]
	FighterData.quiet = quiet
	if not refusedOk or not gen1Ok or not climbs or phases != ["plates", "climate", "places", "ring", "done"] or not startOk or not sameMatch or not same or not ringPhase or not sameRing:
		return "the planet's load: refused cold %s, gen 1 never %s, progress climbs %s, phases %s (want plates, climate, places, ring, done), the match starts %s and is the cold one's %s, make's planet %s (%d places), a named ring in %d steps %s and its match the same %s" % [str(refusedOk), str(gen1Ok), str(climbs), str(phases), str(startOk), str(sameMatch), str(same), PL.n, jr.frames, str(ringPhase), str(sameRing)]
	return ""


func _ringHolds(ev: Dictionary, id: int) -> bool:
	for h in ev.held:
		if int(h.id) == id:
			return true
	return false


func _flatX(S: SimState, from: float) -> float:
	var x: float = from
	for i in range(600):
		var lo: float = 1.0e9
		var hi: float = -1.0e9
		var wet: bool = false
		for k in range(21):
			var xk: float = SimWrap.wrap(x + 32.0 * float(k))
			var g: float = WorldTerrain.groundY(S, xk)
			lo = minf(lo, g)
			hi = maxf(hi, g)
			wet = wet or WorldTerrain.seaAt(S, xk)
		if hi - lo < 3.0 and not wet:
			return x
		x = SimWrap.wrap(x + 160.0)
	return from


## The first x (in steps of 16 from the world's start) with 480 units of dry ground ahead rising at a slope of 0.75 to 2.5
## (37 to 68 degrees) the whole way, and 120 units into it; -1 when the world has none.
func _steepX(S: SimState) -> float:
	var x: float = 0.0
	var run: float = 0.0
	while x < SimConst.W:
		var s: float = (WorldTerrain.groundY(S, SimWrap.wrap(x + 8.0)) - WorldTerrain.groundY(S, x)) / 8.0
		if s >= 0.75 and s <= 2.5 and not WorldTerrain.seaAt(S, x):
			run += 8.0
			if run >= 480.0:
				return SimWrap.wrap(x - 480.0 + 120.0)
		else:
			run = 0.0
		x += 8.0
	return -1.0
