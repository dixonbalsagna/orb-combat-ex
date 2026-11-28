extends RefCounted
## Combat-overhaul baselines (EP, 2026-11-28; docs/ep/proposals/combat-overhaul-directive.md, briefs 1, 2 and 5). orbs_player.gd --combat feeds it each tick's events; it reads, never writes.
## Per match: grab tries (grapple_catch "tell") with the distance at the try and whether the target was charging; clinches; heavies being wound or charged (a heavy's windup "start" to its "end"; flash: it reached the charge) with how each ended and what
## stopped it; approach charges stopped on the way in (charge_stopped); stick-beam gathers (beam_charge) and fires; beam outcomes (beam_outcome); struggles (beam_struggle, beam_end); ticks each
## fighter spends flying away beyond mid range; match length. Side 0 is the scripted player, side 1 the computer. The director's own feed lines are counted beside them as a cross-check.

const BH: float = 75.0
const MID: float = 12.5 * 75.0          # beyond this is "beyond mid range" (the directive)
const AWAY: float = 200.0               # own velocity away from the rival, units a second, to count as flying away
const CAUSE_WINDOW: int = 3             # ticks before a charge's end in which the rival's act is read as its cause

var matches: Array = []
var trace_every: int = 0   # validation only (orbs_player --trace=N)
var holding: bool = false  # the scripted player is holding a charge button or a stick beam this tick (set by orbs_player)
var _m: Dictionary = {}
var _charge: Array = [null, null]       # the heavy charge each side has up: its record
var _gather: Array = [null, null]       # the stick beam gather each side has up
var _acts: Array = [[], []]             # what each side did to the other of late: [tick, what]
var _prev: Array = [null, null]         # each fighter's last position, for the second count of flying away (from positions, not velocity)


func start() -> void:
	_m = {"len": 0.0, "grabs": [], "clinch": [0, 0], "charges": [], "approachStopped": [0, 0], "gathers": [], "beamFire": [0, 0], "beamOut": [], "struggles": [], "away": [0, 0], "awayByPos": [0, 0], "far": 0, "free": [0, 0], "ticks": 0, "trace": [],
		"feed": {"reaches": 0, "catchStopped": 0, "arrow": {}}}
	_charge = [null, null]
	_gather = [null, null]
	_acts = [[], []]
	_prev = [null, null]


func _gap(S: SimState, a, b) -> Vector3:
	return Vector3(SimWrap.sdx(a.x, b.x), b.y - a.y, b.z - a.z)


func feed(S: SimState) -> void:
	if S.fighters.size() < 2:
		return
	var t: int = S.tick
	for l in S.out.feed:
		var s: String = str(l.tag) + " | " + str(l.sub)
		if s.contains(" REACHES FOR "):
			_m.feed.reaches += 1
		elif s.contains("CATCH STOPPED"):
			_m.feed.catchStopped += 1
		var at: int = s.find(" → ")
		if at >= 0:
			var k: String = s.substr(at + 3).get_slice(" ", 0)
			_m.feed.arrow[k] = int(_m.feed.arrow.get(k, 0)) + 1
	# what each side did to the other this tick, first: a charge that ends this tick may end because of it
	var ends: Array = []
	for e in S.out.fx:
		if e.type == "damage":
			var at: int = int(e.attacker)
			var vi: int = int(e.victim)
			if at >= 0 and at <= 1 and vi >= 0 and vi <= 1 and at != vi:
				var w: String = str(e.weight)
				_acts[at].append([t, "%s%s" % [str(e.kind), ("/" + w) if w != "" else ""]])
		elif e.type == "cue" and str(e.kind) == "beam_end":
			# the struggle's end (beam_clash_end is off in the data): actor the winner, -1 both beams detonating (a draw)
			if not _m.struggles.is_empty() and _m.struggles[-1].winner == -2:
				_m.struggles[-1].winner = int(e.actor)
				_m.struggles[-1].how = str(e.text)
		elif e.type == "cue":
			var who: int = int(e.actor)
			if who < 0 or who > 1:
				continue
			var k: String = str(e.kind)
			var x: String = str(e.text)
			if k == "grapple_catch" and x == "tell":
				_acts[who].append([t, "grab"])
				var tgt = _charge[1 - who]
				# the distance as the catch itself measures it (sim/director/grapple.gd _land): past contact, in body heights
				var far: float = (DirBands.dist(S.fighters[who], S.fighters[1 - who]) - float(DirData.contact().offset)) / DirInterrupt.BH
				_m.grabs.append([who, t, snappedf(far, 0.01), tgt != null, _gather[1 - who] != null, holding if who == 1 else false])
				if tgt != null:
					tgt.grabTried = true
			elif k == "grapple_clinch" and x == "start":
				_m.clinch[who] += 1
				_acts[who].append([t, "grab"])
			elif k == "charge_stopped":
				_m.approachStopped[who] += 1
			elif k == "windup" and x == "start" and str(e.source) == "b":
				_charge[who] = {"side": who, "t": t, "grabTried": false, "flash": false}
			elif k == "windup" and x == "charge":
				if _charge[who] == null:
					_charge[who] = {"side": who, "t": t, "grabTried": false, "flash": true}
				_charge[who].flash = true
			elif k == "windup" and x == "end" and _charge[who] != null:
				ends.append([who, int(e.k)])
			elif k == "beam_charge" and x == "start":
				_gather[who] = {"side": who, "t": t, "fired": false}
			elif k == "beam_charge" and x == "end" and _gather[who] != null:
				_gather[who].end = t
				_m.gathers.append(_gather[who])
				_gather[who] = null
			elif k == "beam_fire":
				_m.beamFire[who] += 1
				if not _m.gathers.is_empty() and _m.gathers[-1].side == who and t - int(_m.gathers[-1].end) <= 2:
					_m.gathers[-1].fired = true
				elif _gather[who] != null:
					_gather[who].fired = true
			elif k == "beam_struggle" and x == "start":
				_m.struggles.append({"by": who, "t": t, "winner": -2, "how": ""})
		elif e.type == "beam_outcome":
			_m.beamOut.append([int(e.actor), str(e.kind)])
	for en in ends:
		var who: int = en[0]
		var how: int = en[1]
		var c: Dictionary = _charge[who]
		c.end = t
		c.how = ["?", "released", "stopped by a blow", "lost (stagger or brawl end)", "missed"][how] if how >= 0 and how <= 4 else "?"
		var cause: String = ""
		for a in _acts[1 - who]:
			if int(a[0]) >= t - CAUSE_WINDOW:
				cause = a[1]
				if cause == "grab":
					break
		c.cause = cause if cause != "" else "nothing of the rival's seen"
		_m.charges.append(c)
		_charge[who] = null
	for i in range(2):
		while not _acts[i].is_empty() and int(_acts[i][0][0]) < t - 60:
			_acts[i].pop_front()
	# flying away beyond mid range: his own velocity carries him away from the rival while the gap is past mid range
	_m.ticks += 1
	var gg: Vector3 = _gap(S, S.fighters[0], S.fighters[1])
	if Vector2(gg.x, gg.y).length() > MID:
		_m.far += 1
	if trace_every > 0 and t % trace_every == 0:   # validation only: the raw positions the count reads
		var a = S.fighters[0]
		var b = S.fighters[1]
		_m.trace.append([t, snappedf(Vector2(gg.x, gg.y).length() / BH, 0.1), a.state, snappedf(a.vx, 1.0), snappedf(a.vy, 1.0), snappedf(a.x, 1.0), snappedf(b.x, 1.0)])
	for i in range(2):
		var f = S.fighters[i]
		if f.state != "free":
			continue
		_m.free[i] += 1
		var g: Vector3 = _gap(S, f, S.fighters[1 - i])
		var d: float = Vector2(g.x, g.y).length()
		if d > MID and -(f.vx * g.x + f.vy * g.y) / maxf(1.0, d) > AWAY:
			_m.away[i] += 1
		# the same read from where he actually went since the last tick: his own displacement along the line away from the rival
		if d > MID and _prev[i] != null:
			var mx: float = SimWrap.sdx(_prev[i].x, f.x)
			var my: float = f.y - _prev[i].y
			if -(mx * g.x + my * g.y) / maxf(1.0, d) * 60.0 > AWAY:
				_m.awayByPos[i] += 1
	_keep(S)


func _keep(S: SimState) -> void:
	for i in range(2):
		_prev[i] = Vector2(S.fighters[i].x, S.fighters[i].y)


func end(S: SimState, result: int) -> void:
	_m.len = float(S.T)
	_m.result = result
	for i in range(2):
		if _charge[i] != null:
			_charge[i].how = "unfinished at the end"
			_charge[i].cause = ""
			_m.charges.append(_charge[i])
	matches.append(_m)


func result() -> Array:
	return matches
