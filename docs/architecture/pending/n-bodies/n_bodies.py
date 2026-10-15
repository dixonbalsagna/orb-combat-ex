# PARKED BUILD (Simulation): stage 1 of docs/director/one-v-many.md, the core's plumbing for one versus many.
# A match holds 2 to SimRoster.MAX_BODIES (5) fighters. Slots 0 and 1 are the pair, exactly as today; a body past them
# stands beyond the second, a spacing apart, facing the first, idle unless the setup's ai names him (p3 to p5). The step
# controls him after the pair; the replay records every slot and names p3 to p5 in its header only when there are such
# bodies; the hash walks every fighter. With two fighters every match, replay and checkpoint is the same to the bit.
#   edits sim/core/roster.gd, sim.gd, replay.gd, mood.gd, intro.gd, tools/parity.gd
# Usage: python n_bodies.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s=open(p,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(p,a[:80],s.count(a))
        s=s.replace(a,b)
    open(p,'w',encoding='utf-8',newline='\n').write(s)

# ---------------------------------------------------------------- the roster: how many, and where the rest stand
edit('sim/core/roster.gd', [
('''## The other fighter: anything that is not fighters[0] gets fighters[0], as in the prototype.
''','''## One versus many (docs/director/one-v-many.md, stage 1): a match holds 2 to MAX_BODIES fighters. Slots 0 and 1 are
## the pair as in a 1v1, and they are the principals: the two the match is between. A body past them (a guard) stands
## GUARD_SPACING units beyond the second, and the next as far again, on the side away from the first. The director places
## the ring from stage 2 on; until then they stand.
const MAX_BODIES: int = 5
const GUARD_SPACING: float = 150.0   # 2 bh: "her guards stand 2 bh behind her, along the street" (empress-guards.md)


## True when f is one of the two principals (slots 0 and 1), the fighters the match is between; false for a guard.
## Game Design's rulings for more than two bodies read it: only a principal's KO ends a match, a guard has no brink, a
## guard's stance does not set the mood and his blow feeds it at half, and the acts count the principals only.
static func isPrincipal(S: SimState, f) -> bool:
	return S.fighters.find(f) < 2


## True when slots names 2 to MAX_BODIES fighters the data has (the roster's or the bench's). The same id may come more
## than once (a mirror, or two guards of one kind); a setup's names tell them apart in the feed.
static func slotsOk(slots) -> bool:
	if not (slots is Array) or slots.size() < 2 or slots.size() > MAX_BODIES:
		return false
	for id in slots:
		if not (id is String) or not FighterData.has(id):
			return false
	return true


## The other fighter: anything that is not fighters[0] gets fighters[0], as in the prototype. With more than two bodies
## that makes the first the opponent of every other, and the second his: the one versus many.
'''),
])

# ---------------------------------------------------------------- a new match with N slots
edit('sim/core/sim.gd', [
('''## ai is {"p1": bool, "p2": bool}; a missing entry keeps the previous fighter's setting, or true with no fighters yet.
''','''## ai is {"p1": bool, "p2": bool}; a missing entry keeps the previous fighter's setting, or true with no fighters yet.
## With more than two slots, "p3" to "p5" say whether those bodies are the AI's; a missing one is false: he stands idle.
'''),
('''## setup (D1a; the replay header's `setup`): {"slots": [id, id]} picks any two fighters the data has, from the roster
## or the bench (default: the roster's first two; slots that are not two such fighters play the default, with an error),''',
'''## setup (D1a; the replay header's `setup`): {"slots": [id, id]} picks any two fighters the data has, from the roster
## or the bench (default: the roster's first two; slots that are not such fighters play the default, with an error). Up
## to SimRoster.MAX_BODIES slots make a match of one versus many: slot 0 is the one, and slots 2 and up stand beyond the
## second (docs/director/one-v-many.md, stage 1),'''),
('''	if slots.size() != 2 or not (slots[0] is String and slots[1] is String) or not FighterData.has(slots[0]) or not FighterData.has(slots[1]):
		# slots that are not two fighters the data has (the roster's or the bench's): the default pairing plays
		if not FighterData.quiet:
			push_error("SimCore.newMatch: the setup's slots %s are not two fighters the data has; the default pairing plays" % str(slots))
		slots = FighterData.order().slice(0, 2)
''','''	if not SimRoster.slotsOk(slots):
		# slots that are not 2 to MAX_BODIES fighters the data has (the roster's or the bench's): the default pairing plays
		if not FighterData.quiet:
			push_error("SimCore.newMatch: the setup's slots %s are not 2 to %d fighters the data has; the default pairing plays" % [str(slots), SimRoster.MAX_BODIES])
		slots = FighterData.order().slice(0, 2)
'''),
('''	S.fighters = [SimRoster.createFighter(FighterData.def(slots[0]), x1 if flip else x0, "p1", p1ai), SimRoster.createFighter(FighterData.def(slots[1]), x0 if flip else x1, "p2", p2ai)]
	if setup.has("names"):
		S.fighters[0].name = setup.names[0]
		S.fighters[1].name = setup.names[1]
	S.fighters[0].y = 60.0
	S.fighters[1].y = 60.0
	S.fighters[0].face = -1.0 if flip else 1.0
	S.fighters[1].face = 1.0 if flip else -1.0
	S.fighters[0].stance = 0.0
	S.fighters[1].stance = 0.0
''','''	S.fighters = [SimRoster.createFighter(FighterData.def(slots[0]), x1 if flip else x0, "p1", p1ai), SimRoster.createFighter(FighterData.def(slots[1]), x0 if flip else x1, "p2", p2ai)]
	# the bodies past the pair (one versus many): beyond the second, away from the first, facing back at him
	var away: float = -1.0 if flip else 1.0
	for k in range(2, slots.size()):
		var gx: float = SimWrap.wrap(S.fighters[1].x + away * SimRoster.GUARD_SPACING * float(k - 1))
		var key: String = "p%d" % (k + 1)
		S.fighters.append(SimRoster.createFighter(FighterData.def(slots[k]), gx, key, ai.get(key, false) == true))
	if setup.has("names"):
		for k in range(mini(setup.names.size(), S.fighters.size())):
			S.fighters[k].name = setup.names[k]
	for k in range(S.fighters.size()):
		S.fighters[k].y = 60.0
		S.fighters[k].face = (-1.0 if flip else 1.0) if k == 0 else (1.0 if flip else -1.0)
		S.fighters[k].stance = 0.0
'''),
('''	var ord: Array = [0, 1] if S.rng.next() < 0.5 else [1, 0]
	for k in ord:
		SimControl.control(S, S.fighters[k], inputs[k] if inputs != null else null)
''','''	var ord: Array = [0, 1] if S.rng.next() < 0.5 else [1, 0]
	for k in range(2, S.fighters.size()):   # the bodies past the pair, after it, in slot order: one draw a tick, as with two
		ord.append(k)
	for k in ord:
		SimControl.control(S, S.fighters[k], inputs[k] if inputs != null and k < inputs.size() else null)
'''),
('''## One fixed step (sim.js step). inputs is [intent or null, intent or null], or null (AI fighters ignore it). Returns''',
 '''## One fixed step (sim.js step). inputs is [intent or null, ...] a slot, or null (AI fighters ignore it; a slot past the
## list's end has none). Returns'''),
])

# ---------------------------------------------------------------- the replay: every slot
edit('sim/core/replay.gd', [
('''##   setup        newMatch's setup (D1a): {"slots", "names", "flip"}, {} for the default match.
''','''##   setup        newMatch's setup (D1a): {"slots", "names", "flip"}, {} for the default match. Up to five slots
##                (one versus many); "ai" then names p3 to p5 too.
'''),
('''var _last: Array = [-1, -1]   # the last packed intent per slot; -1 for none (null)
''','''var _last: Array = []   # the last packed intent per slot; -1 for none (null)
'''),
('''	rec.replay = {"format": FORMAT, "v": V, "intent": SimIntent.VERSION, "data": dataHash(setup), "seed": seed, "setup": setup.duplicate(true),
		"ai": {"p1": S_.fighters[0].ai != null, "p2": S_.fighters[1].ai != null},
		"ticks": 0, "inputs": [], "toggles": [], "checkpoints": [], "final": ""}
	return rec
''','''	rec.replay = {"format": FORMAT, "v": V, "intent": SimIntent.VERSION, "data": dataHash(setup), "seed": seed, "setup": setup.duplicate(true),
		"ai": {"p1": S_.fighters[0].ai != null, "p2": S_.fighters[1].ai != null},
		"ticks": 0, "inputs": [], "toggles": [], "checkpoints": [], "final": ""}
	for k in range(2, S_.fighters.size()):   # one versus many: the bodies past the pair (a 1v1's header is as it was)
		rec.replay.ai["p%d" % (k + 1)] = S_.fighters[k].ai != null
	for k in range(S_.fighters.size()):
		rec._last.append(-1)
	return rec
'''),
('''## One recorded step. inputs: [SimIntent or null, SimIntent or null], or null, as for SimCore.step. The sim is stepped
## with each intent's canonical form.
func step(inputs = null) -> bool:
	var cur: Array = [null, null]
	for k in range(2):
		var i = inputs[k] if inputs != null else null''','''## One recorded step. inputs: [SimIntent or null, ...] a slot, or null, as for SimCore.step. The sim is stepped with
## each intent's canonical form. An AI body's intent is the AI's, and nothing of his is recorded.
func step(inputs = null) -> bool:
	var cur: Array = []
	cur.resize(S.fighters.size())
	for k in range(S.fighters.size()):
		var i = inputs[k] if inputs != null and k < inputs.size() else null'''),
('''	var cur: Array = [null, null]
	var ii: int = 0
''','''	var cur: Array = []
	cur.resize(S_.fighters.size())
	for inp in rp.get("inputs", []):
		if int(inp[1]) < 0 or int(inp[1]) >= S_.fighters.size():   # a slot the match does not have
			SimCore.dispose(S_)
			return refuse
	var ii: int = 0
'''),
])

# ---------------------------------------------------------------- the mood: "the other one" is the opponent
edit('sim/core/mood.gd', [
('''		var o = fs[1 - k]
''','''		var o = SimRoster.opp(S, f)   # his opponent (with two, the other one; with more, the one for every other)
'''),
])

# ---------------------------------------------------------------- the intro: the pair arrives; the bodies past it stand
edit('sim/core/intro.gd', [
('''		it.left = it.clock
		for f in S.fighters:
			f.state = "intro"
			f.vx = 0.0
			f.vy = 0.0
			f.y = WorldTerrain.groundY(S, f.x) + fallHeight
''','''		it.left = it.clock
		for k in range(2):   # the pair arrives; a body past it (one versus many) stands where the setup put him
			var f = S.fighters[k]
			f.state = "intro"
			f.vx = 0.0
			f.vy = 0.0
			f.y = WorldTerrain.groundY(S, f.x) + fallHeight
		for k in range(2, S.fighters.size()):
			S.fighters[k].y = WorldTerrain.groundY(S, S.fighters[k].x)
'''),
('''## The slots in the order of the start spots: the left one, then the other.
static func _order(S: SimState) -> Array:
	if S.fighters.size() == 2 and S.fighters[1].x < S.fighters[0].x:
		return [1, 0]
	return range(S.fighters.size())
''','''## The pair's slots in the order of the start spots: the left one, then the other. The bodies past the pair (one versus
## many) are not in it: they take no entrance and dig no crater.
static func _order(S: SimState) -> Array:
	if S.fighters[1].x < S.fighters[0].x:
		return [1, 0]
	return [0, 1]
'''),
])

# ---------------------------------------------------------------- the checks
edit('sim/core/tools/parity.gd', [
('''## A match's setup names any two fighters the data has. Slots that are not two such fighters (an id nobody has, one id,
## three, a number) play the default pairing: the match is the default match to the hash.''',
 '''## A match's setup names the fighters the data has. Slots that are not 2 to 5 such fighters (an id nobody has, one id,
## six, a number) play the default pairing: the match is the default match to the hash.'''),
('''	for bad in [["NOBODY", "RIVAL"], ["PROTAGONIST"], ["PROTAGONIST", "RIVAL", "REFERENCE"], [1, 2], []]:''',
 '''	for bad in [["NOBODY", "RIVAL"], ["PROTAGONIST"], ["PROTAGONIST", "RIVAL", "REFERENCE", "REFERENCE", "REFERENCE", "REFERENCE"], [1, 2], []]:'''),
('''	check("a match's slots name two fighters the data has", _slotGuard())
''','''	check("a match's slots name two fighters the data has", _slotGuard())
	check("one versus many: a match of three to five bodies", _nBodies())
'''),
('''## A match's setup names the fighters the data has.''','''## One versus many, stage 1 (docs/director/one-v-many.md): a match holds 2 to SimRoster.MAX_BODIES fighters. Slots 0
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


## A match's setup names the fighters the data has.'''),
])

# ---------------------------------------------------------------- Game Design's rulings for more than two bodies
# (docs/design/empress-guards.md, "What the core counts, with more than two bodies"). With two fighters both are
# principals, so every rule below is today's rule.
edit('sim/core/damage.gd', [
('''static func ko(S: SimState, D, A) -> void:
	if S.game.ko != null:
		return
''','''static func ko(S: SimState, D, A) -> void:
	if S.game.ko != null:
		return
	# One versus many: only a principal's KO ends the match. A guard's fall is the director's (he leaves the field, and
	# his place reopens after its cooldown). A principal felled by a guard's blow loses to the principal that guard
	# fights for.
	if not SimRoster.isPrincipal(S, D):
		return
	if not SimRoster.isPrincipal(S, A):
		A = S.fighters[1] if D == S.fighters[0] else S.fighters[0]
'''),
])
edit('sim/core/wounds.gd', [
('''	var brink: bool = false
	for r in range(4):
		if f.wd.brinkRegion[r] and f.stage[r] == 3:
			brink = true
''','''	var brink: bool = false
	for r in range(4):
		if f.wd.brinkRegion[r] and f.stage[r] == 3:
			brink = true
	if brink and not SimRoster.isPrincipal(S, f):   # a guard has no brink and no finisher (empress-guards.md)
		brink = false
'''),
])
s_mood = open('sim/core/mood.gd', encoding='utf-8').read()
i = s_mood.index('\t\t\t"damage":')
j = s_mood.index('\t\t\t"cue":', i)
blk = s_mood[i:j]
assert blk.count('_imp(fs, ') == 5, blk.count('_imp(fs, ')
s_mood = s_mood[:i] + blk.replace('_imp(fs, ', '_impBlow(fs, ') + s_mood[j:]
open('sim/core/mood.gd', 'w', encoding='utf-8', newline='\n').write(s_mood)
edit('sim/core/mood.gd', [
('''static func _imp(fs: Array, name: String, slot: int) -> int:
	return imp[name][1] if slot >= 0 and fs[slot].stance == 0.0 else imp[name][0]
''','''static func _imp(fs: Array, name: String, slot: int) -> int:
	# a guard's stance is his order, not a choice: it never sets the AGGRESSIVE column (empress-guards.md)
	return imp[name][1] if slot >= 0 and slot < 2 and fs[slot].stance == 0.0 else imp[name][0]


## A blow's impulse: a guard's landed blow feeds the mood at half its units, as it is worth half (empress-guards.md).
static func _impBlow(fs: Array, name: String, slot: int) -> int:
	var u: int = _imp(fs, name, slot)
	return u if slot < 2 else int(SimMathx.jround(float(u) * 0.5))
'''),
('''	var steps: int = 0
	for f in S.fighters:
		steps = maxi(steps, int(f.tier) - 1)
''','''	var steps: int = 0
	for k in range(mini(2, S.fighters.size())):   # the principals' form steps only: a guard has no forms (empress-guards.md)
		steps = maxi(steps, int(S.fighters[k].tier) - 1)
'''),
('''static func onForm(S: SimState, f = null) -> void:
	_ensure()
''','''static func onForm(S: SimState, f = null) -> void:
	_ensure()
	if f != null and not SimRoster.isPrincipal(S, f):   # the acts and the mood count the principals' forms only
		return
'''),
('''static func onStage(S: SimState, f, r: int, st: int, prev: int) -> void:
	_ensure()
''','''static func onStage(S: SimState, f, r: int, st: int, prev: int) -> void:
	_ensure()
	if not SimRoster.isPrincipal(S, f):   # the acts count the principals' wounds only (empress-guards.md)
		return
'''),
('''	if fs[0].stance == 0.0 and fs[1].stance == 0.0:
		v += mood.bothAggressive
''','''	if fs[0].stance == 0.0 and fs[1].stance == 0.0:   # the principals' stances: a guard's never sets the mood
		v += mood.bothAggressive
'''),
])
edit('sim/core/tools/parity.gd', [
('''	check("one versus many: a match of three to five bodies", _nBodies())
''','''	check("one versus many: a match of three to five bodies", _nBodies())
	check("one versus many: what the core counts of a guard", _guardRules())
'''),
('''## One versus many, stage 1 (docs/director/one-v-many.md): a match holds''','''## One versus many: Game Design's rulings on what the core counts of a guard (docs/design/empress-guards.md). Only a
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


## One versus many, stage 1 (docs/director/one-v-many.md): a match holds'''),
])

print("one versus many, stage 1: N bodies in the core, with Game Design's rulings")
