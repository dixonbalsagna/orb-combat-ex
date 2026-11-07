extends SceneTree
## Headless checks for the intent bit dodgeHeld (docs/controls/dodge-held.md; timing.json switches.dodgeHeld, off): the second word's bit 26 says the dodge control (LT) is physically down this tick, and Game Design's
## ruling for the flight strike's take-back reads it: a face press within 4 ticks after LT, LT still held at the face press, never button-first, measured on the face edge the sim sees (after the strike law)
## (docs/design/playable-build.md section 1). The word's pack, unpack, canon and width; the layout's reading (hold, tap, a tap that came and went between builds, a key, a toggled dodge, the swapped layout);
## off writes nothing; and the claw check of the ruled rule. From the repo root:
##   godot --headless --path . --script res://sim/input/test/dodge_held_test.gd
## Exit 0 if every check passes.

const W: int = 4
var fails: int = 0
var checks: int = 0


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	_sw(true, true)
	_word()
	_reading()
	_take_back()
	_claw()
	_sw(true, false)
	_off()
	print("dodge_held_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(right: bool, held: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	for k in ["quickRead", "beamAim", "hapticLadder", "hapticIncoming", "hapticRefused", "specialsOff", "signatureRtOnly", "driverOnRb", "stallKeep", "hapticImpact"]:
		sw[k] = false
	sw["rightStick"] = right
	sw["dodgeHeld"] = held
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _pad(swapped: bool = false) -> SimLayout:
	return SimLayout.new(SimInputData.preset(SimSwap.swapped_id("arena") if swapped else "arena"))


func _word() -> void:
	ok(SimIntent.BITS2 == 27, "word: the second word is 27 bits")
	var i := SimIntent.new()
	i.dodgeHeld = true
	var p: int = SimIntent.pack2(i)
	ok(p == (1 << 26), "word: LT held alone is bit 26 (%d)" % p)
	var j := SimIntent.new()
	ok(SimIntent.unpack2(p, j) and j.dodgeHeld and not j.rsHeld and not j.brace, "word: it unpacks to LT held and nothing else")
	ok(SimIntent.pack2(j) == p, "word: and re-packs to the same integer")
	ok(not SimIntent.unpack2(1 << SimIntent.BITS2, SimIntent.new()), "word: a bit above the word is refused")
	# the old fields are where they were
	var k := SimIntent.new()
	k.rsHeld = true
	k.rsDir = 4
	k.rsLevel = 3
	k.rsMask = 15
	k.rsAim = 31
	k.rsLag = 15
	k.brace = true
	k.braceDir = 4
	var old: int = SimIntent.pack2(k)
	k.dodgeHeld = true
	ok(SimIntent.pack2(k) == old | (1 << 26), "word: the strike and brace fields are where they were; LT held adds only bit 26")
	var c: SimIntent = SimIntent.canon(k)
	ok(c.dodgeHeld and c.rsDir == 4 and c.rsAim == 31, "word: canon carries it")
	var d := SimIntent.new()
	SimIntent.applyIntent(d, k)
	ok(d.dodgeHeld, "word: applyIntent copies it")
	SimIntent.clear2(d)
	ok(not d.dodgeHeld and SimIntent.pack2(d) == 0, "word: clear2 clears it")
	# an old record (no bit 26) reads as LT not held
	var o := SimIntent.new()
	o.dodgeHeld = true
	ok(SimIntent.unpack2(old, o) and not o.dodgeHeld, "word: a word recorded before the bit existed reads as LT not held")


## Builds a layout through `evs` ([tick, kind, name, a]): returns per tick [dodge edge, dodgeHeld].
func _stream(l: SimLayout, evs: Array, n: int, swapped: bool = false) -> Array:
	var out: Array = []
	for t in range(n):
		for e in evs:
			if int(e[0]) == t:
				var c: String = "pad:" + str(e[2])
				if swapped:
					c = SimSwap.control(c)
				match str(e[1]):
					"t":
						l.analog(c, float(e[3]))
					"b":
						if bool(e[3]):
							l.press(c)
						else:
							l.release(c)
					"k":
						if bool(e[3]):
							l.press("kb:" + str(e[2]))
						else:
							l.release("kb:" + str(e[2]))
		var i: SimIntent = l.build()
		out.append([i.dodge, i.dodgeHeld, SimIntent.pack2(SimIntent.canon(i))])
		l.consumed()
	return out


func _reading() -> void:
	var s: Array = _stream(_pad(), [[10, "t", "lt", 1.0], [20, "t", "lt", 0.0]], 30)
	ok(not s[9][1] and s[10][0] and s[10][1], "reading: on LT's press tick the dodge edge and dodgeHeld are both on")
	var held: bool = true
	for t in range(10, 20):
		held = held and s[t][1]
	ok(held and not s[11][0], "reading: dodgeHeld stays on every tick LT is down, the edge only on the first")
	ok(not s[20][1] and not s[25][1], "reading: and is off on the tick after the release")
	ok(s[10][2] & (1 << 26) != 0 and s[9][2] == 0 and s[20][2] == 0, "reading: the packed word carries it, and is 0 when LT is up (a clean record)")
	# a tap that came and went between two builds: the edge is there, LT is not held
	var l: SimLayout = _pad()
	for t in range(3):
		l.build()
		l.consumed()
	l.analog("pad:lt", 1.0)
	l.analog("pad:lt", 0.0)
	var i: SimIntent = l.build()
	ok(i.dodge and not i.dodgeHeld, "reading: a tap that came and went before the build is a dodge edge with LT not held")
	# a key
	var k: Array = _stream(SimLayout.new(SimInputData.preset("kb-solo")), [[10, "k", "Space", true], [20, "k", "Space", false]], 30)
	ok(k[10][1] and k[15][1] and not k[20][1], "reading: the keyboard's dodge key reads the same")
	# a toggled dodge: the finger's own state, so the toggle being on with the finger up is not held
	var tl: SimLayout = _pad()
	tl.set_hold_style("dodge", "toggle")
	var t2: Array = _stream(tl, [[10, "t", "lt", 1.0], [14, "t", "lt", 0.0]], 24)
	ok(t2[10][1] and t2[12][1] and not t2[15][1], "reading: a toggled dodge is read by the finger: down while pressed, not once let go though the toggle is on")
	# the swapped layout: the dodge control is on the other hand's trigger
	var sw: Array = _stream(_pad(true), [[10, "t", "lt", 1.0], [20, "t", "lt", 0.0]], 30, true)
	ok(sw[10][1] and sw[15][1] and not sw[20][1], "reading: the swapped layout reads its own dodge control")
	# the rest of the intent is what it was: the same stream with the bit and without it, but for the bit
	_sw(true, false)
	var off: Array = _stream(_pad(), [[10, "t", "lt", 1.0], [20, "t", "lt", 0.0]], 30)
	_sw(true, true)
	var same: bool = true
	for t in range(30):
		if off[t][0] != s[t][0] or (off[t][2] | (1 << 26)) != (s[t][2] | (1 << 26)):
			same = false
	ok(same, "reading: with the switch on the intent differs from the switch-off stream by the bit alone")


## The take-back as Game Design ruled it: the face edge (after the strike law) 0 to 4 ticks after the LT edge, with LT still held at the face press, never button-first.
func _take_back_run(evs: Array, n: int = 80, swapped: bool = false) -> Dictionary:
	var l: SimLayout = _pad(swapped)
	var res: Dictionary = {"lt": -1, "face": -1, "held": false}
	for t in range(n):
		for e in evs:
			if int(e[0]) == t:
				var c: String = "pad:" + ("rs" if str(e[1]) == "rs" else str(e[2]))
				if swapped:
					c = SimSwap.control(c)
				match str(e[1]):
					"t":
						l.analog(c, float(e[3]))
					"b":
						if bool(e[3]):
							l.press(c)
						else:
							l.release(c)
					"rs":
						l.axis(c, float(e[3]), float(e[4]))
		var i: SimIntent = l.build()
		if i.dodge and res["lt"] < 0:
			res["lt"] = t
		if (i.light or i.heavy or i.sig) and res["face"] < 0:
			res["face"] = t
			res["held"] = i.dodgeHeld
		l.consumed()
	return res


func _converted(r: Dictionary) -> bool:
	return r["lt"] >= 0 and r["face"] >= 0 and r["face"] - r["lt"] >= 0 and r["face"] - r["lt"] <= W and bool(r["held"])


func _take_back() -> void:
	for g in range(0, 10):
		var r: Dictionary = _take_back_run([[10, "t", "lt", 1.0], [10 + g, "b", "west", true], [11 + g, "b", "west", false]])
		ok(_converted(r) == (g <= W), "ruled: LT held, the face press %d ticks after is %s" % [g, "a take-back" if g <= W else "too late (past 4)"])
	# LT let go before the face press: not held at the press, so not a take-back, even inside the 4 ticks
	var rel: Dictionary = _take_back_run([[10, "t", "lt", 1.0], [12, "t", "lt", 0.0], [13, "b", "west", true], [14, "b", "west", false]])
	ok(rel["lt"] == 10 and rel["face"] == 13 and not rel["held"] and not _converted(rel), "ruled: LT let go on tick 12 and the face press on 13 (3 after the LT edge) is not a take-back: LT was not held")
	var still: Dictionary = _take_back_run([[10, "t", "lt", 1.0], [11, "b", "west", true], [12, "b", "west", false], [14, "t", "lt", 0.0]])
	ok(_converted(still), "ruled: LT let go after the face press does not matter (it was held at the press)")
	# the face first: never a take-back, whatever the gap
	for g in [1, 2, 3, 4, 8]:
		var fr: Dictionary = _take_back_run([[10, "b", "west", true], [11, "b", "west", false], [10 + g, "t", "lt", 1.0]])
		ok(not _converted(fr) and fr["face"] == 10, "ruled: the face press %d ticks before LT is never a take-back" % g)
	# the same tick: LT held and the face press together
	var same: Dictionary = _take_back_run([[10, "t", "lt", 1.0], [10, "b", "west", true], [11, "b", "west", false]])
	ok(_converted(same) and same["face"] == 10 and same["held"], "ruled: LT and a face press on the same tick are a take-back, LT held on that tick")
	# X, Y, B
	for pair in [["west", "light"], ["north", "heavy"], ["east", "sig"]]:
		var kr: Dictionary = _take_back_run([[10, "t", "lt", 1.0], [12, "b", pair[0], true], [13, "b", pair[0], false]])
		ok(_converted(kr), "ruled: LT then %s (%s) within 4 is a take-back" % [pair[0], pair[1]])
	# a face press held behind a strike stick waits, and is gone by the time LT's 4 ticks are
	var busy: Dictionary = _take_back_run([[4, "rs", "", 1.0, 0.0], [10, "t", "lt", 1.0], [11, "b", "west", true], [12, "b", "west", false], [40, "rs", "", 0.0, 0.0]], 100)
	ok(not _converted(busy), "ruled: a face press behind a held strike stick is not a take-back (it waits, then goes or is dropped)")
	# the swapped layout
	var a: Dictionary = _take_back_run([[10, "t", "lt", 1.0], [12, "b", "west", true], [13, "b", "west", false]], 80, false)
	var b: Dictionary = _take_back_run([[10, "t", "lt", 1.0], [12, "b", "west", true], [13, "b", "west", false]], 80, true)
	ok(_converted(a) and _converted(b) and a["face"] == b["face"], "ruled: the swapped layout takes it back on the same ticks")


func _claw() -> void:
	# The claw gate's three models for the face press after LT (0, 6, 13 ticks) and the take-back under the ruled rule: LT is the left index finger and the face button the right thumb, so there is no thumb
	# transfer to save; what the strike law holds is the same for all three. A flick that ends on tick 12, LT on 14, the face press at 14 + g.
	var out: Dictionary = {}
	for m in [["CLAW", 0], ["FAST", 6], ["SLOW", 13]]:
		var r: Dictionary = _take_back_run([[8, "rs", "", 1.0, 0.0], [12, "rs", "", 0.0, 0.0], [14, "t", "lt", 1.0], [14 + int(m[1]), "b", "west", true], [15 + int(m[1]), "b", "west", false]], 100)
		out[m[0]] = [r["face"], _converted(r)]
	ok(out["CLAW"][0] >= 12 + SimInputData.ti(["strike", "lockout"], 6), "claw: even a claw's face press after a flick waits the lockout L (tick %d)" % out["CLAW"][0])
	ok(out["CLAW"][0] <= out["FAST"][0] and out["FAST"][0] <= out["SLOW"][0], "claw: the faster the thumb the earlier the press, never before the law's floor (%s)" % str(out))
	var free: Dictionary = {}
	for m in [["CLAW", 0], ["FAST", 2], ["SLOW", 6]]:
		free[m[0]] = _converted(_take_back_run([[10, "t", "lt", 1.0], [10 + int(m[1]), "b", "west", true], [11 + int(m[1]), "b", "west", false]]))
	ok(free["CLAW"] and free["FAST"] and not free["SLOW"], "claw: with the stick at rest a 0 or 2 tick bimanual gap is a take-back, a 6 tick one is not (%s): the window, not the grip, decides" % str(free))


func _off() -> void:
	var s: Array = _stream(_pad(), [[10, "t", "lt", 1.0], [20, "t", "lt", 0.0]], 30)
	var any: bool = false
	for t in range(30):
		if s[t][1] or s[t][2] != 0:
			any = true
	ok(not any, "off: with the switch off dodgeHeld is never set and the second word is 0 (a record is what it always was)")
	_sw(false, true)
	var r: Array = _stream(_pad(), [[10, "t", "lt", 1.0], [20, "t", "lt", 0.0]], 30)
	var any2: bool = false
	for t in range(30):
		if r[t][1] or r[t][2] != 0:
			any2 = true
	ok(not any2, "off: and with rightStick off nothing is written even with the switch on")
	_sw(true, false)
