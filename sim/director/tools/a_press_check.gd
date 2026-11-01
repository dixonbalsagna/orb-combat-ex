extends SceneTree
## A: near, it grabs; anywhere else, it taunts (docs/design/stick-lands.md). Off, the empty-button cue as ever. Ends on the verdict line.
##   godot --headless --path . --script res://sim/director/tools/a_press_check.gd

var failed: int = 0
var _cues: Array = []


func _init() -> void:
	var cfg: Dictionary = DirInterrupt.data().grapple
	var was: bool = bool(cfg.enabled)
	cfg["enabled"] = false
	_row(58.0, "off, close", ["press_ack"], -1)
	cfg["enabled"] = true
	_row(58.0, "close", ["brawl_start", "grapple_catch"], 0)
	_row(1400.0, "the middle band", ["taunt_start"], -1)
	_row(3000.0, "the far band", ["taunt_start"], -1)
	cfg["enabled"] = was
	print("A PRESS: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _row(gap: float, what: String, want: Array, brawl: int) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + gap)
	S.fighters[1].y = S.fighters[0].y
	for _k in range(10):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
	S.out.fx.clear()
	S.out.feed.clear()
	var a := SimIntent.new()
	a.context = true
	SimCore.step(S, [a, SimIntent.new()])
	var seen: Array = []
	for e in S.out.fx:
		if e.type == "cue" and e.actor == 0.0:
			seen.append(String(e.kind))
	S.out.fx.clear()
	var inBrawl: bool = S.dirS.ex != null and DirBrawl.isBrawl(S.dirS.ex)
	print("      %s, band %d: %s, brawl %s" % [what, DirBands.band(S.fighters[0], S.fighters[1]), str(seen).substr(0, 90), str(inBrawl)])
	for w in want:
		_expect(seen.has(w), what + ": " + String(w))
	_expect(inBrawl == (brawl == 0), what + (": a brawl" if brawl == 0 else ": no brawl"))
	SimCore.dispose(S)
