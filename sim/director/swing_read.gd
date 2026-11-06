class_name DirSwingRead
## The camera's model of itself, for the swing's one score (docs/world/ring-any-angle/camera.md section 5; Game Design weighs it, section
## 11): how good a moment this is for the world to turn, from -1 to +1. Camera's numbers are the `read` block of data/director/swing.json. A pure function of
## the sim's state and data: it reads the state, writes nothing, holds nothing, and imports nothing from render/, so rollback and the
## digest see nothing new and the sim never reads a camera. No term reads people (RL-213). DirSwing asks it when it scores; nothing
## else does.

const PATH: String = "res://data/director/swing.json"
static var _d = null


static func data() -> Dictionary:
	if _d == null:
		var j = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if not (j is Dictionary):
			push_error("DirSwingRead: could not parse " + PATH)
			j = {}
		_d = j
	return _d


## The read. `quietS`: seconds since the last peak, launch or swing, which DirSwing keeps (negative: unknown, no term). `swingS`: how long the
## swing being scored lasts. `turn`: +1 or -1 the way it would turn, 0 unknown; what lies behind x as it turns comes round in front.
## Returns {value, terms: [[name, amount], ...]}: every term that counted, for the debug feed.
static func read(S: SimState, quietS: float = -1.0, swingS: float = 1.0, turn: int = 0) -> Dictionary:
	var R: Dictionary = data().read
	var W: Dictionary = R.terms
	var terms: Array = []
	var pair: Array = S.fighters.slice(0, 2)   # the swing's read is of the pair: the roster's first two
	var A = pair.front()
	var B = pair.back()
	var hitstop: bool = S.dirS.stop > 0.0
	var gap: float = absf(SimWrap.sdx(A.x, B.x))
	var air: Array = [_air(S, A, R), _air(S, B, R)]

	var released: bool = false
	var left: float = 1.0e9
	for f in [A, B]:
		if f.state == "launched":
			if not hitstop and float(f.stateT) <= float(R.releaseS):
				released = true
			left = minf(left, _flightLeft(S, f))
		if f.state == "down" and float(f.stateT) <= float(R.landedS):
			_add(terms, "just_landed", W)
	if released:
		_add(terms, "launch_release", W)
	elif not hitstop and _beatDone(S, R):
		_add(terms, "heavy_release", W)
	if bool(air[0]) and bool(air[1]) and gap < float(R.onePaneGap):
		_add(terms, "both_airborne", W)
	if left < 1.0e9:
		if left >= swingS:
			_add(terms, "flight_room", W)
		elif left < float(R.flightShortS):
			_add(terms, "flight_short", W)
	if S.pause.left > 0:
		_add(terms, "form_pause", W)
	if quietS >= float(R.quietS):
		_add(terms, "quiet", W)
	if _anticipating(S, R):
		_add(terms, "anticipation", W)
	if turn != 0 and _tallForward(S, A, B, gap, turn, R):
		_add(terms, "tall_forward", W)
	if absf(gap - float(R.splitGap)) < float(R.splitBand) and absf(_closing(A, B)) > float(R.splitMoving):
		_add(terms, "near_split", W)
	if not bool(air[0]) and not bool(air[1]) and gap > float(R.standingGap) and gap < float(R.splitGap):
		_add(terms, "both_standing", W)
	var v: float = 0.0
	for t in terms:
		v += float(t[1])
	return {"value": SimMathx.jclamp(v, -1.0, 1.0), "terms": terms}


## One line for the debug feed: the value, then each term's name and amount.
static func text(r: Dictionary) -> String:
	var parts: Array = []
	for t in r.terms:
		parts.append("%s %+.1f" % [t[0], t[1]])
	return "%+.2f %s" % [r.value, ", ".join(parts)]


static func _add(terms: Array, name: String, W: Dictionary) -> void:
	terms.append([name, float(W[name])])


static func _air(S: SimState, f, R: Dictionary) -> bool:
	return f.state == "launched" or float(f.y) - WorldTerrain.groundY(S, f.x) > float(R.airborneH)


## The flight's time left, by its law, to the ground under him now (a forecast, one read).
static func _flightLeft(S: SimState, f) -> float:
	var g: float = float(data().read.gravity)
	var h: float = maxf(0.0, float(f.y) - WorldTerrain.groundY(S, f.x))
	var vy: float = float(f.vy)
	return (vy + sqrt(vy * vy + 2.0 * g * h)) / g


static func _heavy(b) -> bool:
	if b.op == "launch" or b.op == "knockBack" or b.op == "guardBreak":
		return true
	if b.op != "strike" and b.op != "chainStrike":
		return false
	var o2 = b.args.get("o") if b.args is Dictionary else null
	return o2 is Dictionary and (String(o2.get("class", "")) == "heavy" or String(o2.get("class", "")) == "ender" or bool(o2.get("big", false)))


## A heavy blow just landed: the exchange's clock is just past a heavy strike's beat.
static func _beatDone(S: SimState, R: Dictionary) -> bool:
	var ex = DirBrawl.exOf(S)
	if ex == null:
		return false
	for b in ex.beats:
		if b.done and _heavy(b) and float(ex.t) - float(b.t) <= float(R.releaseS):
			return true
	return false


## A heavy or a launch is about to land: the view is tightening on it.
static func _anticipating(S: SimState, R: Dictionary) -> bool:
	var ex = DirBrawl.exOf(S)
	if ex == null:
		return false
	for b in ex.beats:
		if not b.done and _heavy(b) and float(b.t) - float(ex.t) <= float(R.anticipationS):
			return true
	return false


## Tall land on the side the turn brings forward: Game Design's fixed test, height only, on the line until the field's read reaches off it.
static func _tallForward(S: SimState, A, B, gap: float, turn: int, R: Dictionary) -> bool:
	var mid: float = SimWrap.wrap(A.x + SimWrap.sdx(A.x, B.x) * 0.5)
	var low: float = minf(WorldTerrain.groundY(S, A.x), WorldTerrain.groundY(S, B.x))
	var n: int = int(R.tallSamples)
	for i in range(1, n + 1):
		var d: float = float(R.tallReach) * float(i) / float(n)
		if WorldTerrain.groundY(S, SimWrap.wrap(mid - float(turn) * d)) - low > float(R.tallH):
			return true
	return false


static func _closing(A, B) -> float:
	return float(A.vx) / maxf(float(A.launchT), 0.001) - float(B.vx) / maxf(float(B.launchT), 0.001)
