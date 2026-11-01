extends SceneTree
## RL-219's conditions that a script can hold (docs/legal/review-log.md): off, no slot and factor 1; the trigger reads a count of sends
## only; one factor, under the floor never; the AI only; and the lint names RL-219's list. Conditions 3, 4 and 5 are QA's batch.
##   godot --headless --path . --script res://sim/director/tools/relief_check.gd
## Ends on the verdict line.

const BANNED := ["casualt", "toll", "popAlive", "popNear", "popHist", "pop_mult", "crowd", "menace", "anguish"]

var failed: int = 0


func _init() -> void:
	_rows()
	DirRelief.setForce(-1)
	print("RELIEF: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _rows() -> void:
	var src: String = FileAccess.get_file_as_string("res://sim/director/relief.gd")
	var body: String = src.substr(src.find("const R_SENDS"))
	for w in BANNED:
		_expect(not body.contains(w), "the relief doesn't read " + w)
	var c: Dictionary = DirRelief.cfg()
	_expect(float(c.floor) >= 0.5, "the data's floor is at least half (%.2f)" % float(c.floor))
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": true, "p2": true}, {"intro": false})
	var H = S.fighters[0]
	var V = S.fighters[1]
	H.care = 0.5
	V.care = 0.0
	DirRelief.setForce(0)
	var n0: int = H.act.dirI.size()
	DirRelief.sent(V)
	_expect(H.act.dirI.size() == n0 and V.act.dirI.size() == n0, "off: no slot is sized")
	_expect(DirRelief.factor(S, H) == 1.0, "off: the factor is 1")
	DirRelief.setForce(1)
	for _k in range(int(c.minSends) - 1):
		DirRelief.sent(V)
	_expect(DirRelief.factor(S, H) == 1.0, "under minSends: the factor is 1")
	DirRelief.sent(V)
	var fac: float = DirRelief.factor(S, H)
	_expect(fac == maxf(float(c.scale), float(c.floor)) and fac >= 0.5 and fac < 1.0, "short of his share: one factor (%.2f)" % fac)
	_expect(DirRelief.fired(H) == 1, "it fired once")
	DirRelief.factor(S, H)
	_expect(DirRelief.fired(H) == 1, "and asking again doesn't fire it again")
	_expect(DirRelief.factor(S, V) == 1.0, "a fighter with no care: the factor is 1")
	var ai = H.ai
	H.ai = null
	_expect(DirRelief.factor(S, H) == 1.0, "a player: the factor is 1")
	H.ai = ai
	for _k in range(4):
		DirRelief.sent(H)
	_expect(DirRelief.factor(S, H) == 1.0, "at his share: it goes off")
	# the same with and without people: a count is all it reads
	var before: float = DirRelief.factor(S, H)
	for b in S.buildings:
		b.popAlive = 0.0
	_expect(DirRelief.factor(S, H) == before, "no people anywhere: the factor is the same")
	SimCore.dispose(S)
