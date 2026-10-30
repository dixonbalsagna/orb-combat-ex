class_name SimReplay
extends RefCounted
## Replays: a seed, the AI flags and the intents the host passed to step() reproduce a match bit for bit. The GDScript
## twin of replay.js, format v4 (intent version 4). A replay is plain JSON-able data:
##   {format, v, intent, data, seed, setup, ai, ticks, inputs, toggles, checkpoints, final}
##   intent       SimIntent.VERSION: the intent schema the inputs are packed in. Another version is refused.
##   data         dataHash(): the combat data and the roster data the match ran on (S4, D1a). It plays back only on the
##                same data.
##   setup        newMatch's setup (D1a): {"slots", "names", "flip"}, {} for the default match. Up to five slots
##                (one versus many); "ai" then names p3 to p5 too.
##   inputs       [tick, slot, low, high], only where a slot's intent changed from its previous one: SimIntent.pack(), one
##                integer for the whole record, written as two numbers (split: its low 32 bits, and the bits above
##                them), because a JSON number is exact only below 2^53 and the record may grow past that. Both are null
##                for no intent.
##   toggles      [tick, slot]: toggleAI before that tick
##   checkpoints  [tick, gameplay hash] every CHECK_EVERY ticks; final: the gameplay hash at the end
## Intents, not raw keys, are recorded, so a replay does not depend on the key mapping or the layout. The recorder steps
## the sim with the canonical form of each intent (SimIntent.canon: the stick on its 1 / 127 grid), so what it records
## is exactly what was played.
## v1 (replay.js) had a `sim` modes field; v2 stored each intent as a dictionary of eight fields; v3 stored the packed
## intent as one number.

const FORMAT: String = "meridian-replay"
const V: int = 4
const LOW_BITS: int = 32             # a packed intent's low part in a replay's entry ...
const LOW_MASK: int = 0xFFFFFFFF
const HIGH_MAX: int = 0x7FFFFFFF     # ... and the most its high part can be (63 bits in all: a packed intent is never negative)
const CHECK_EVERY: int = 60

var S: SimState
var replay: Dictionary
var _last: Array = []   # the last packed intent per slot; -1 for none (null)


## Start recording a match: runs newMatch(S, seed, ai). Use rec.step and rec.toggle instead of SimCore.step and toggleAI.
static func recorder(S_: SimState, seed: int, ai: Dictionary = {}, setup: Dictionary = {}) -> SimReplay:
	SimCore.newMatch(S_, seed, ai, setup)
	var rec := SimReplay.new()
	rec.S = S_
	rec.replay = {"format": FORMAT, "v": V, "intent": SimIntent.VERSION, "data": dataHash(setup), "seed": seed, "setup": setup.duplicate(true),
		"ai": {"p1": S_.fighters[0].ai != null, "p2": S_.fighters[1].ai != null},
		"ticks": 0, "inputs": [], "toggles": [], "checkpoints": [], "final": ""}
	for k in range(2, S_.fighters.size()):   # one versus many: the bodies past the pair (a 1v1's header is as it was)
		rec.replay.ai["p%d" % (k + 1)] = S_.fighters[k].ai != null
	for k in range(S_.fighters.size()):
		rec._last.append(-1)
	return rec


## One recorded step. inputs: [SimIntent or null, ...] a slot, or null, as for SimCore.step. The sim is stepped with
## each intent's canonical form. An AI body's intent is the AI's, and nothing of his is recorded.
func step(inputs = null) -> bool:
	var cur: Array = []
	cur.resize(S.fighters.size())
	for k in range(S.fighters.size()):
		var i = inputs[k] if inputs != null and k < inputs.size() else null
		var p: int = SimIntent.pack(i) if i != null else -1
		if i != null:
			cur[k] = SimIntent.unpack(p)
		if p != _last[k]:
			_last[k] = p
			replay.inputs.append([replay.ticks, k] + split(p))
	var r: bool = SimCore.step(S, cur if inputs != null else null)
	replay.ticks += 1
	if replay.ticks % CHECK_EVERY == 0:
		replay.checkpoints.append([replay.ticks, SimHash.stateHash(S).gameplay])
	return r


## A packed intent as the two numbers an entry stores: [its low 32 bits, the bits above]; [null, null] for none (p < 0).
static func split(p: int) -> Array:
	if p < 0:
		return [null, null]
	return [p & LOW_MASK, p >> LOW_BITS]


## The packed intent of an entry's two numbers: -1 for none (both null), -2 if they are not the two parts of one (not
## whole numbers, or out of range, or only one of them null).
static func join(lo, hi) -> int:
	if lo == null and hi == null:
		return -1
	if not ((lo is float or lo is int) and (hi is float or hi is int)):
		return -2
	var a: float = float(lo)
	var b: float = float(hi)
	if a != floor(a) or b != floor(b) or a < 0.0 or b < 0.0 or a > float(LOW_MASK) or b > float(HIGH_MAX):
		return -2
	return int(a) | (int(b) << LOW_BITS)


func toggle(idx: int) -> void:
	replay.toggles.append([replay.ticks, idx])
	SimCore.toggleAI(S, idx)


func finish() -> Dictionary:
	replay.final = SimHash.stateHash(S).gameplay
	return replay


## Re-run a replay and verify it. Returns {ok, firstBadTick (-1 if ok), reason, final}. reason is "" when ok; "format" for
## another format, version or intent schema, or an input that is not a valid packed intent (it is not run); "data" when it
## was recorded on other data (not run); "checkpoint" or "final" otherwise.
static func play(rp: Dictionary) -> Dictionary:
	var refuse := {"ok": false, "firstBadTick": -1, "reason": "format", "final": ""}
	if rp.get("format", "") != FORMAT or int(rp.get("v", 0)) != V or int(rp.get("intent", 0)) != SimIntent.VERSION:
		return refuse
	var packed: Array = []
	for inp in rp.get("inputs", []):
		if not (inp is Array) or inp.size() != 4:
			return refuse
		var it = null
		var p: int = join(inp[2], inp[3])
		if p != -1:
			it = SimIntent.unpack(p) if p >= 0 else null
			if it == null:
				return refuse
		packed.append(it)
	if rp.get("data", "") != dataHash(rp.get("setup", {})):
		return {"ok": false, "firstBadTick": -1, "reason": "data", "final": ""}
	var S_ := SimCore.createSim()
	SimCore.newMatch(S_, int(rp.seed), rp.ai, rp.get("setup", {}))
	var checks := {}
	for c in rp.checkpoints:
		checks[int(c[0])] = c[1]
	var cur: Array = []
	cur.resize(S_.fighters.size())
	for inp in rp.get("inputs", []):
		if int(inp[1]) < 0 or int(inp[1]) >= S_.fighters.size():   # a slot the match does not have
			SimCore.dispose(S_)
			return refuse
	var ii: int = 0
	var ti: int = 0
	var out := {"ok": true, "firstBadTick": -1, "reason": "", "final": ""}
	for t in range(int(rp.ticks)):
		while ti < rp.toggles.size() and int(rp.toggles[ti][0]) == t:
			SimCore.toggleAI(S_, int(rp.toggles[ti][1]))
			ti += 1
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		SimCore.step(S_, cur)
		if checks.has(t + 1) and checks[t + 1] != SimHash.stateHash(S_).gameplay:
			out = {"ok": false, "firstBadTick": t + 1, "reason": "checkpoint", "final": ""}
			break
		S_.out.fx.clear()   # playback is its own host: it drains the event and feed lists
		S_.out.feed.clear()
	out.final = SimHash.stateHash(S_).gameplay
	if out.ok and rp.final != "" and out.final != rp.final:
		out = {"ok": false, "firstBadTick": int(rp.ticks), "reason": "final", "final": out.final}
	SimCore.dispose(S_)
	return out


## The data a replay depends on: Combat's data (DirData), the roster (FighterData) and the fight's mood and style data
## (SimMood, M1), one hash.
## setup is the match's: the fighters its slots name are folded in, one hash each, and nobody else; its planet's data,
## when it names a planet.
static func dataHash(setup: Dictionary = {}) -> String:
	var h := SimHash.Hasher.new()
	h.text(DirData.dataHash())
	h.text(SimMood.dataHash())
	h.text(SimPause.dataHash())   # Q10: data/fight/pause.json
	h.text(SimIntro.dataHash())   # the intro phase: data/fight/intro.json
	h.text(SimShots.dataHash())   # shots: data/fight/shots.json
	h.text(WorldContact.dataHash())   # World's ground contact: data/biomes/contact.json
	h.text(WorldSettle.dataHash())    # World's settlements and lanes: data/biomes/settlements.json, lanes.json
	h.text(WorldBlast.dataHash())     # World's shot blast: data/biomes/blast.json
	h.text(WorldStructures.stagesHash())   # World's building stages: data/biomes/stages.json
	if SimDepth.enabled():   # fighters in depth: data/combat/depth.json, once its switch is on (a match with depth off reads none of it)
		h.text(SimDepth.dataHash())
	if setup.has("boons"):   # the run's rare boons: data/fight/boons.json, only for a setup that names one
		h.text(SimBoons.dataHash())
	if setup.get("brake", SimBrake.enabled()) == true:   # the air brake: data/fight/brake.json, only for a match with it on
		h.text(SimBrake.dataHash())
	if setup.get("flight", SimFlight.enabled()) == true:   # the launch's curve: data/fight/flight.json, only for a match with it on
		h.text(SimFlight.dataHash())
	if setup.get("ricochet", SimRicochet.enabled()) == true:   # the ricochet's glance: data/fight/ricochet.json, only for a match with it on
		h.text(SimRicochet.dataHash())
	if setup.get("hitstop", SimHitstop.enabled()) == true:   # hit-stop by weight: data/fight/hitstop.json, only for a match with it on
		h.text(SimHitstop.dataHash())
	if setup.get("forms", SimForms.enabled()) == true:   # forms: data/fight/forms.json and each fighter's forms.json, only for a match with them on
		h.text(SimForms.dataHash())
	if setup.has("wear"):   # a campaign stage's place state: World lays it by data/biomes/campaign.json's bands (campaign-core.md)
		h.text(WorldCampaign.dataHash())
	h.text(WorldBrunt.dataHash())          # World's brunt ladder and lodge: data/biomes/brunt.json
	if setup.has("planet"):   # a planet's world: World's planet data, by the generation this setup plays (WorldClimate.genFor: never the one in force, for a header is made before a match)
		var gen: int = WorldClimate.genFor(setup)
		h.text(WorldPlanet.dataHash(gen))
		if gen >= 2 and WorldDensity.enabled():   # a gen 2 ring's buildings follow data/biomes/density.json while its switch is on
			h.text(WorldDensity.dataHash())
		if gen >= 2:   # a gen 2 ring's water, trees and landings: which valleys hold lakes, and the ground's table (World's answer: docs/world/lake-floor.md)
			h.text(WorldLakes.dataHash())
			h.text(WorldGround.dataHash())
		if WorldEpoch.enabled(setup):   # when and how the ring turns, on either generation: only rings.json's turn block, for the rest picks a run's ring before the setup exists
			h.text("rings.turn")
			FighterData._canon(h, WorldRingPick.cfg().turn)
	var lvl: String = DirAI.levelOf(setup)   # the computer's level, a setup key (the start menu's Easy or Hard); nothing for the data's own level, so no earlier replay's hash moves
	if lvl != "":
		h.text("aiLevel")
		h.text(lvl)
	# the fighters in its slots, one hash each (FighterData.hashOf): a change to a fighter who is not in the match, the
	# training dummy's say, leaves the replay alone. The default pairing is the roster's first two.
	for id in setup.get("slots", FighterData.order().slice(0, 2)):
		h.text(String(id))
		h.text(FighterData.hashOf(String(id)))
	return h.hex()
