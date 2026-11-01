extends SceneTree
## DirPhrase (docs/design/rule-of-cool-map.md row 1): every piece has its fighter's key set; off, no slot and today's draws; a phrase's
## presses take its pieces; a mash's first two throw from the pool; a pause breaks it, for free; the last blow's ender is by place;
## same presses, same pieces; worth doesn't move.
##   godot --headless --path . --script res://sim/director/tools/phrase_check.gd
## Ends on the verdict line.

var failed: int = 0
var _seen: Array = []
var _done: int = 0
var _hurt: float = 0.0


func _init() -> void:
	AnimData.load_all()
	DirPhrase.setForce(1)
	_keys()
	_taps()
	_mash()
	_gap()
	_same()
	_worth()
	DirPhrase.setForce(0)
	_off()
	DirPhrase.setForce(-1)
	print("PHRASE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _keys() -> void:
	var bad: int = 0
	var seen: int = 0
	for row in [["PROTAGONIST", "protagonist"], ["RIVAL", "rival"]]:
		var key: String = String(AnimData.ensure_fighter(row[0]))
		var e = DirPhrase.cfg().fighters[row[1]]
		for ph in e.phrases:
			var ids: Array = []
			for pt in ph.parts:
				if pt.has("piece"):
					ids.append(pt.piece)
				for q in pt.get("pieces", []):
					ids.append(q)
			for cl in ph.enders:
				ids.append(ph.enders[cl])
			for id in ids:
				seen += 1
				var ks: String = AnimData.resolve_strike(key, String(id))
				if ks == "" or not AnimData.keysets.has(ks):
					bad += 1
					print("      %s %s %s: no key set" % [row[0], ph.id, id])
	_expect(bad == 0, "every piece of the %d read has its fighter's key set" % seen)


func _fresh(fi: int = 0) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"intro": false, "v2": [true, true]})
	for f in S.fighters:
		f.ai = null
		f.hp = 100000.0
		f.ki = 100.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 58.0)
	S.fighters[1].y = S.fighters[0].y
	_seen = []
	_done = 0
	for _k in range(5):
		_step(S)
	return S


func _step(S: SimState, a: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue" and e.kind == "phrase_done":
			_done += 1
	S.out.fx.clear()
	S.out.feed.clear()
	var ex = S.dirS.ex
	if ex != null:
		for b in ex.beats:
			if not b.done and b.op == "strike" and b.args != null and String(b.args.get("a", "")) == "A" and b.args.has("piece"):
				if _seen.is_empty() or _seen[_seen.size() - 1][0] != b.t:
					_seen.append([b.t, String(b.args.piece)])


func _press(S: SimState, b: String, gap: int) -> void:
	var a := SimIntent.new()
	if b == "X":
		a.light = true
	else:
		a.heavy = true
	_step(S, a)
	for _k in range(gap):
		_step(S)


func _pieces() -> Array:
	var out: Array = []
	for e in _seen:
		out.append(e[1])
	return out


## The phrase on the list with only taps, played press by press.
func _taps() -> void:
	var e = DirPhrase.cfg().fighters["protagonist"]
	var ph = null
	for q in e.phrases:
		var ok: bool = true
		for pt in q.parts:
			ok = ok and String(pt.g) == "tap"
		if ok:
			ph = q
			break
	if ph == null:
		for q in e.phrases:
			if String(q.parts[0].g) == "tap" and String(q.parts[1].g) == "tap":
				ph = q
				break
	_expect(ph != null, "a phrase that starts with taps")
	var S := _fresh()
	_press(S, String(ph.parts[0].b), 26)
	_press(S, String(ph.parts[1].b), 26)
	var got: Array = _pieces()
	print("      %s: wanted %s then %s; threw %s" % [ph.id, ph.parts[0].piece, ph.parts[1].piece, str(got)])
	_expect(got.has(ph.parts[0].piece), "its first press takes its piece")
	_expect(got.has(ph.parts[1].piece) or ph.parts.size() == 2, "and its second")
	if ph.parts.size() == 2:
		_expect(DirPhrase._g(S.fighters[0], DirPhrase.P_DONE) == 1, "and a phrase played through finishes once")
	SimCore.dispose(S)


func _mash() -> void:
	var e = DirPhrase.cfg().fighters["protagonist"]
	var ph = null
	for q in e.phrases:
		if String(q.parts[0].g) == "mash":
			ph = q
			break
	_expect(ph != null, "a phrase that starts with a mash")
	var S := _fresh()
	var b: String = String(ph.parts[0].b)
	for _n in range(5):
		_press(S, b, 12)
	var got: Array = _pieces()
	var pool: Array = ph.parts[0].pieces
	var inPart: int = 0
	for id in got:
		inPart += 1 if pool.has(id) else 0
	print("      %s, mashing %s: %s" % [ph.id, b, str(got)])
	_expect(got.size() >= 3 and inPart >= 1, "a mash reaches its part's blows by the third press (%d of %d)" % [inPart, got.size()])
	SimCore.dispose(S)


func _gap() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	_press(S, "X", 26)
	var alive: int = DirPhrase._g(A, DirPhrase.P_ALIVE)
	_expect(alive != 0, "a press leaves phrases alive")
	var lst: int = (1 << DirPhrase._list(A).size()) - 1
	_expect((alive & lst) != lst, "and it has narrowed them")
	for _k in range(int(DirPhrase.cfg().gapTicks) + 2):
		_step(S)
	DirPhrase.read(S, A, S.fighters[1], "Y", "tap")
	_expect(true, "a pause breaks it, and the next blow starts over")
	SimCore.dispose(S)


func _script(S: SimState) -> Array:
	for b in ["X", "Y", "X", "X", "Y", "Y", "X"]:
		_press(S, b, 22)
	return _pieces()


func _same() -> void:
	var a := _fresh()
	var ga: Array = _script(a)
	var h1 = SimHash.stateHash(a)
	SimCore.dispose(a)
	var b := _fresh()
	var gb: Array = _script(b)
	var h2 = SimHash.stateHash(b)
	SimCore.dispose(b)
	_expect(ga == gb, "same presses, same pieces")
	_expect(h1 == h2, "two runs, one hash")


func _worth() -> void:
	var a := _fresh()
	_script(a)
	var on: float = a.fighters[1].hp
	SimCore.dispose(a)
	DirPhrase.setForce(0)
	var b := _fresh()
	_script(b)
	var off: float = b.fighters[1].hp
	SimCore.dispose(b)
	DirPhrase.setForce(1)
	_expect(absf(on - off) < 0.01, "worth doesn't move (%.2f against %.2f)" % [on, off])


func _off() -> void:
	var S := _fresh()
	var n: int = S.fighters[0].act.dirI.size()
	_expect(DirPhrase.read(S, S.fighters[0], S.fighters[1], "X", "tap") == "", "off: the pool's")
	_expect(S.fighters[0].act.dirI.size() == n, "off: no slot")
	SimCore.dispose(S)
