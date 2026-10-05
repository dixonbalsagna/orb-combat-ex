# Dynamic intros, the first cut (docs/architecture/pending/dynamic-intros.md): the intro phase plays a composed timeline.
# Usage: python dynintro.py <repo root> code|hash      (run from anywhere; the three files in src/ sit beside this script)
#   code  sim/core/intro.gd (the playback, rewritten), sim/director/intro.gd (new: the composer, DirIntro),
#         data/fight/intro.json (the three scenarios as templates and parts), the new events and their view names, the
#         intro's new state fields (not hashed yet), the checks. Run Godot's --import after it: DirIntro is a new class.
#         A match that does not play an intro is untouched. "intro": true still plays the opening it played, tick for tick,
#         with new voice-slot events and new event fields, so the goldens' intro vector moves (and the fight data hash).
#   hash  the intro's new state fields join the hash. Regenerate the goldens once: light digests must not move.
import os, sys, hashlib, shutil
here=os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
part=sys.argv[2]
assert part in ('code','hash')
def edit(p, pairs):
    s=open(p,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(p,a[:80],s.count(a))
        s=s.replace(a,b)
    open(p,'w',encoding='utf-8',newline='\n').write(s)
def sha(p):
    return hashlib.sha256(open(p,'rb').read().replace(b'\r\n',b'\n')).hexdigest()

if part=='code':
    # ---- the three whole files: each replaces a file that must be as it was when this was built, or creates a new one
    OLD={'sim/core/intro.gd':'8473e55c35a0219e407f390a198b0a43d6d9fcf98da53a7086971c8272786b1d','data/fight/intro.json':'f5c65509f4baf890d93b1161f8150bbc93e98bd62d7e5866ab2b28359c742886'}
    for p,want in OLD.items():
        assert sha(p)==want,(p,'has changed since this slice was built: rebase it')
    assert not os.path.exists('sim/director/intro.gd'),'sim/director/intro.gd exists already'
    shutil.copyfile(os.path.join(here,'src','intro_core.gd.txt'),'sim/core/intro.gd')
    shutil.copyfile(os.path.join(here,'src','intro_dir.gd.txt'),'sim/director/intro.gd')
    shutil.copyfile(os.path.join(here,'src','intro.json'),'data/fight/intro.json')

    # ---- state
    edit('sim/core/state.gd', [
    ('''	var landed: int = 0       # a bit per slot: he has touched down
''','''	var landed: int = 0       # a bit per slot: he has touched down
	var scenario: int = -1    # the composed intro: the template's index in data/fight/intro.json (-1: none is played) ...
	var first: int = 0        # ... the slot that arrives first ...
	var gap: int = 0          # ... the ticks between the first landing and the second fall ...
	var picks: int = 0        # ... and the part in each slot (SimIntro.flatten)
	var clock: int = 0        # ... and its length in ticks (the template's, bent by the facts)
	var dug: int = 0          # a bit per slot: his entrance crater is dug
	var notes: Array = []     # the composer's reasons, waiting for the first pre-clock tick's feed (output only, not hashed)
	var gestures: Array = []  # the facts' gestures, [tick, slot, intent, point] (events only: they touch no state; not hashed)
	var facts: Dictionary = {}   # the setup's facts as given (in the replay header): read for the events' tags only, not hashed
'''),
    ('''	var gather: float = 0.0      # transform: seconds from this event to the break, where the tier_up comes
''','''	var gather: float = 0.0      # transform: seconds from this event to the break, where the tier_up comes
	var stance: String = ""      # intro_line: the mood the facts ask for (Narrative's; the sim reads none of these four)
	var angle: String = ""       # intro_line: what the line is about
	var event: String = ""       # intro_line: the past event a `then` line refers to
	var p: float = 0.0           # intro_line: the chance the line is spoken (the line system's to use)
'''),
    ])

    # ---- events
    edit('sim/core/fx.gd', [
    ('''## The intro phase (sim/core/intro.gd). intro_start: the pre-clock window opens, dur seconds long; a press skips it after
## delay seconds. entrance_fall: actor starts to fall toward x, y (the ground), from height y1, for dur seconds.
## entrance_land: he touches down; r is the crater's bowl radius (0 if none was dug). staredown_start: both stand, for
## dur seconds. clock_start: the fight starts with the next tick; kind is full, or skip when a press ended the intro.
static func introStart(S: SimState, dur: float, skipAfter: float) -> void:
	var e := _ev(S, "intro_start")
	e.dur = dur; e.delay = skipAfter
''','''## The intro phase (sim/core/intro.gd). intro_start: the pre-clock window opens, dur seconds long; a press skips it after
## delay seconds; kind is the scenario (the template's id), actor the slot that arrives first, n the gap in ticks (the
## whole timeline is SimIntro.timeline(S)); text is the facts' plot id. entrance_fall: actor starts to fall toward x, y
## (the ground), from height y1, for dur seconds; mode is his arrival mode (drop). entrance_land: he touches down; r is
## the crater's bowl radius (0 if none was dug). intro_beat: a beat that is neither a fall nor a landing: kind wait (actor
## stands waiting for the other, for dur seconds, until the staredown). intro_line: a voice slot: actor may speak now;
## kind is the intent (arrive_remark, wait_remark, late_reply, staredown_pair) and variant his role by arrival (first or
## second); stance, angle, event and p are the facts' tags for it, passed through (p is 1 and the rest empty with no
## facts). The line is optional and the words are the line system's: the sim holds none. intro_gesture: a small
## non-verbal beat for actor: kind is the gesture's intent (a meaning, not a pose) and text the point it plays at
## (land_first, land_second, wait, look_start, look_end, or part for one a template wrote). staredown_start: both stand,
## for dur seconds. clock_start: the fight starts with the next tick; kind is full, or skip when a press ended the intro.
static func introStart(S: SimState, dur: float, skipAfter: float, scenario: String = "", first: int = -1, gap: int = 0, plot: String = "") -> void:
	var e := _ev(S, "intro_start")
	e.dur = dur; e.delay = skipAfter; e.kind = scenario; e.actor = float(first); e.n = gap; e.text = plot


static func introBeat(S: SimState, slot: int, kind: String, dur: float) -> void:
	var e := _ev(S, "intro_beat")
	e.actor = float(slot); e.kind = kind; e.dur = dur


static func introLine(S: SimState, slot: int, intent: String, role: String, tags: Dictionary = {}) -> void:
	var e := _ev(S, "intro_line")
	e.actor = float(slot); e.kind = intent; e.variant = role
	e.stance = String(tags.get("stance", "")); e.angle = String(tags.get("angle", "")); e.event = String(tags.get("event", "")); e.p = float(tags.get("p", 1.0))


static func introGesture(S: SimState, slot: int, intent: String, at: String) -> void:
	var e := _ev(S, "intro_gesture")
	e.actor = float(slot); e.kind = intent; e.text = at
'''),
    ('''static func entranceFall(S: SimState, f, ground: float, top: float, dur: float) -> void:
	var e := _ev(S, "entrance_fall")
	e.actor = float(S.fighters.find(f)); e.x = f.x; e.y = ground; e.z = f.z; e.y1 = top; e.dur = dur
''','''static func entranceFall(S: SimState, f, ground: float, top: float, dur: float, mode: String = "drop") -> void:
	var e := _ev(S, "entrance_fall")
	e.actor = float(S.fighters.find(f)); e.x = f.x; e.y = ground; e.z = f.z; e.y1 = top; e.dur = dur; e.mode = mode
'''),
    ])
    edit('sim/core/hash.gd', [
    ('''"intro_start": ["dur", "delay"], "entrance_fall": ["actor", "x", "y", "z", "y1", "dur"]''','''"intro_start": ["dur", "delay", "kind", "actor", "n", "text"], "intro_beat": ["actor", "kind", "dur"], "intro_line": ["actor", "kind", "variant", "stance", "angle", "event", "p"], "intro_gesture": ["actor", "kind", "text"], "entrance_fall": ["actor", "x", "y", "z", "y1", "dur", "mode"]'''),
    ])
    edit('sim/core/view/fx.gd', [
    ('''"intro_start", "entrance_fall",''','''"intro_start", "intro_beat", "intro_line", "intro_gesture", "entrance_fall",'''),
    ])

    # ---- a golden vector for composed intros (it pins the composer's keyed draws and the timelines)
    edit('sim/core/tools/golden_recipes.gd', [
    ('''	h.text(SimHash.stateHash(S).gameplay)
	SimCore.dispose(S)
	return h.hex()


## Every golden vector, as the JSON the generator writes.''','''	h.text(SimHash.stateHash(S).gameplay)
	SimCore.dispose(S)
	return h.hex()


## Composed intros: AI matches whose setup asks the composer for an intro (seeds 7 and up): two free draws, two with a
## no-repeat list, every template by name with its order and gap drawn, then two with the host's facts. Every tick's fighters and events through
## the pre-clock ticks and the first two seconds of the fight, with what was composed.
static func introComposedHash() -> String:
	var h := SimHash.Hasher.new()
	SimIntro.errors()   # (the data is loaded on first use)
	var classic: String = SimIntro.templates[SimIntro.classicI].id
	var recs: Array = [{"play": true}, {"play": true}, {"play": true, "avoid": [classic, classic]}, {"play": true, "avoid": [classic, classic]}]
	for tp in SimIntro.templates:
		recs.append({"play": true, "scenario": tp.id})
	# two with the host's facts (Narrative's example, docs/narrative/dynamic-intros.md section 11.5), drawn and by name
	var facts := {"tones": ["neutral", "grave"], "plot": "rivalry.simmering.record", "weights": {"double_drop": 0.9, "latecomer": 1.0, "long_look": 1.8},
		"gap": -0.6, "look": "long", "clock": 24, "gestures": [{"at": "land_first", "who": "second", "intent": "check"}, {"at": "look_start", "who": "first", "intent": "harden"}],
		"intents": {"arrive_remark": {"who": "first", "stance": "guarded", "angle": "then", "p": 0.9, "event": "last_ko"},
			"staredown_pair": {"lines": [{"who": "left", "stance": "guarded", "angle": "then", "event": "last_ko", "p": 0.9}, {"who": "right", "stance": "smug", "angle": "us", "p": 0.9}]}}}
	recs.append({"play": true, "facts": facts})
	recs.append({"play": true, "scenario": classic, "facts": facts})
	for i in range(recs.size()):
		var S := SimCore.createSim()
		SimCore.newMatch(S, 7 + i, {}, {"intro": recs[i]})
		h.num(float(S.intro.scenario)); h.num(float(S.intro.first)); h.num(float(S.intro.gap)); h.num(float(S.intro.picks)); h.num(float(S.intro.clock))
		for t in range(S.intro.left + 120):
			SimCore.step(S)
			h.num(S.T)
			for f in S.fighters:
				h.num(f.x); h.num(f.y); h.text(f.state)
			SimHash.hashFx(h, S.out.fx)
			S.out.fx.clear()
			S.out.feed.clear()
		h.text(SimHash.stateHash(S).gameplay)
		SimCore.dispose(S)
	return h.hex()


## Every golden vector, as the JSON the generator writes.'''),
    ('''	g.intro = introHash()
''','''	g.intro = introHash()
	g.introComposed = introComposedHash()
'''),
    ])

    # ---- the checks
    p='sim/core/tools/parity.gd'
    edit(p, [
    ('''	check("the intro phase", _intro())
''','''	check("the intro phase", _intro())
	check("composed intros", _introComposed())
'''),
    ('''	check("the intro phase (golden)", "" if SimGolden.introHash() == g.get("intro", "") else "differs")
''','''	check("the intro phase (golden)", "" if SimGolden.introHash() == g.get("intro", "") else "differs")
	check("composed intros (golden)", "" if SimGolden.introComposedHash() == g.get("introComposed", "") else "differs")
'''),
    ('''				at["%s%s" % [e.type, ("" if e.actor < 0.0 else str(int(e.actor)))]] = t''','''				at["%s%s" % [e.type, ("" if e.actor < 0.0 or e.type == "intro_start" else str(int(e.actor)))]] = t'''),
    ('''	var clockState := func(S0: SimState) -> String:   # the state at the clock, without the tick counters
		S0.tick = 0
		S0.intro.t = 0
		return SimHash.stateHash(S0).gameplay
	# the full intro, two human slots that press nothing''','''	var clockState := func(S0: SimState) -> String:   # the state at the clock, without the tick counters and the intro's own record
		S0.tick = 0
		S0.intro.t = 0
		S0.intro.scenario = -1
		S0.intro.first = 0
		S0.intro.gap = 0
		S0.intro.picks = 0
		S0.intro.clock = 0
		return SimHash.stateHash(S0).gameplay
	# the full intro, two human slots that press nothing'''),
    ('''## Fight lanes, L0 and L2 (docs/architecture/fight-lanes.md). The player never steers depth: the intent has no depth field''','''## Composed intros (docs/architecture/intro-phase.md): every template, with either fighter first, at its shortest, default
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
				var rec := {"play": true, "scenario": tp.id, "order": first, "gap": gap}
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
		var setup := {"intro": {"play": true, "avoid": [T[heavy].id], "facts": {"tones": ["light", "neutral", "grave"]}}}
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
		if not (back.setup.intro is Dictionary) or back.setup.intro.avoid[0] != T[heavy].id:
			return "the replay's header lost the intro record"
		var res: Dictionary = SimReplay.play(back)
		if not res.ok:
			return "a replay of a composed intro (%s): %s at tick %d" % [T[sc].id, res.reason, res.firstBadTick]
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


## Fight lanes, L0 and L2 (docs/architecture/fight-lanes.md). The player never steers depth: the intent has no depth field'''),
    ])

if part=='hash':
    edit('sim/core/hash.gd', [
    ('''_obj(out, S.intro, ["left", "t", "landed"])''','''_obj(out, S.intro, ["left", "t", "landed", "scenario", "first", "gap", "picks", "clock", "dug"])'''),
    ])
print("dynamic intros applied:", part)
