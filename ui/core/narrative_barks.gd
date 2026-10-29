class_name NarrativeBarks
extends RefCounted
## Live barks (Narrative; docs/ep/cloud-briefs/narrative-live-barks.md): the lines a fighter says in a match.
## TARGET: ui/core/narrative_barks.gd (parked in docs/narrative/pending/live-barks/ until the EP grants the path).
##
## PRESENTATION ONLY. It reads the events the sim already put in S.out.fx and returns HUD "bark" events. It never writes
## the sim, never touches S.rng, and draws from its own stream (a hash of the match seed, the tick, the event's place in
## the tick and a purpose), so the gameplay hash, the golden and the determinism run cannot change. A bark is a function of
## (seed, tick, events), so a replay or a rollback re-run says the same line at the same tick.
##
## OFF BY DEFAULT: data/narrative/live_barks.json has "enabled": false, and make() then returns null (no allocation, no
## work). Every line it can say is in that file and is an approved line; nothing is invented here.
##
## Use (render/core/main.gd, three lines; see main_gd.patch):
##   barks = NarrativeBarks.make(host.S, host.setup_used)
##   if barks != null: ui_hud.consume_all(barks.step(host.S, events))

const DATA_PATH: String = "res://data/narrative/live_barks.json"
const TICKS_PER_S: float = 60.0

var cfg: Dictionary = {}
var _limits: Dictionary = {}
var _display: Dictionary = {}
var _beats: Dictionary = {}
var _ids: Array = []              # the fighter id of each slot
var _seed: int = 0
var _salt: int = 0
var _last_slot: Dictionary = {}   # slot -> tick of its last bark
var _recent: Dictionary = {}      # slot -> ticks of its barks in the last minute
var _last_any: int = -1000000
var _line_at: Dictionary = {}     # "<id>|<line id>" -> tick it was last said
var _beat_at: Dictionary = {}     # beat -> tick it last fired
var _done_once: Dictionary = {}
var _hushed: bool = false
var log: Array = []               # what was said: {tick, slot, id, beat, line, text}; the test reads it


## Returns null when the switch is off, so the host does nothing at all. `over` replaces keys of the data file (tests).
static func make(S, setup: Dictionary = {}, over: Dictionary = {}) -> NarrativeBarks:
	var d: Dictionary = _load()
	for k in over:
		d[k] = over[k]
	if not bool(d.get("enabled", false)):
		return null
	var nb := NarrativeBarks.new()
	nb.cfg = d
	nb._limits = d.get("limits", {})
	nb._display = d.get("display", {})
	nb._beats = d.get("beats", {})
	nb._salt = int(d.get("seed_salt", 0))
	nb._seed = int(S.game.seed)
	for f in S.fighters:
		nb._ids.append(str(f.id))
	return nb


static func _load() -> Dictionary:
	var fa := FileAccess.open(DATA_PATH, FileAccess.READ)
	if fa == null:
		return {}
	var v = JSON.parse_string(fa.get_as_text())
	return v if v is Dictionary else {}


## One tick of events in, the barks to show out (HUD "bark" events). Does not change `events`.
func step(S, events: Array) -> Array:
	var out: Array = []
	if _hushed:
		return out
	var i: int = -1
	for e in events:
		i += 1
		# The event's own tick, so a frame that drains several ticks (or a replay that drains them all at once) says the same
		# lines at the same ticks.
		var tick: int = int(e.tick) if int(e.tick) > 0 else int(S.tick)
		var t: String = str(e.type)
		if t == "ko":
			if bool(_limits.get("after_ko_hush", true)):
				_hushed = true
				return out
			continue
		var cands: Array = _candidates(t, e)
		if cands.is_empty():
			continue
		# One bark an event: when two fighters could speak (the one who hit, the one who was hit) the hash picks.
		var pick: int = int(_rand(tick, i, 1) * cands.size()) % cands.size()
		var c: Array = cands[pick]
		var b = _try(tick, i, str(c[0]), int(c[1]))
		if b != null:
			out.append(b)
	return out


## [[beat, slot], ...] the event could start.
func _candidates(t: String, e) -> Array:
	var c: Array = []
	if t == "damage":
		var kind: String = str(e.kind)
		if not (kind == "light" or kind == "medium" or kind == "heavy"):
			return c   # guards, blasts, beams, impacts and landings carry no line
		var a: int = int(e.attacker)
		var v: int = int(e.victim)
		if not _done_once.has("first_blow") and a >= 0:
			_done_once["first_blow"] = true   # the match's first landed blow is the first, whether or not its hitter has a line
			c.append(["first_blow", a])
		if kind == "heavy":
			if a >= 0:
				c.append(["heavy_landed", a])
			if v >= 0:
				c.append(["heavy_taken", v])
	elif t == "cue":
		var k: String = str(e.kind)
		if k == "perfect_block":
			c.append(["guard_caught", int(e.actor)])
		elif k == "miss":
			c.append(["missed", int(e.actor)])
		elif k == "stagger" and str(e.text) == "flurry":
			c.append(["flurry_taken", int(e.actor)])
	elif t == "launch":
		c.append(["launch_given", int(e.target)])   # actor is the body sent, target the launcher
	elif t == "lodge":
		c.append(["stuck", int(e.actor)])
	return c


func _try(tick: int, i: int, beat: String, slot: int):
	var bd: Dictionary = _beats.get(beat, {})
	if bd.is_empty() or slot < 0 or slot >= _ids.size():
		return null
	var fid: String = _ids[slot]
	var pool: Array = bd.get("lines", {}).get(fid, [])
	if pool.is_empty():
		return null
	# Silence is a feature: the gaps, the minute cap and the beat's own hold-off.
	var gap_any: int = int(float(_limits.get("global_gap_s", 3.0)) * TICKS_PER_S)
	var gap_slot: int = int(float(_limits.get("per_fighter_gap_s", 8.0)) * TICKS_PER_S)
	var gap_beat: int = int(float(_limits.get("beat_cooldown_s", 12.0)) * TICKS_PER_S)
	var gap_line: int = int(float(_limits.get("line_cooldown_s", 180.0)) * TICKS_PER_S)
	if tick - _last_any < gap_any:
		return null
	if tick - int(_last_slot.get(slot, -1000000)) < gap_slot:
		return null
	if tick - int(_beat_at.get(beat, -1000000)) < gap_beat:
		return null
	var mins: Array = _recent.get(slot, [])
	var keep: Array = []
	for tt in mins:
		if tick - int(tt) < int(60.0 * TICKS_PER_S):
			keep.append(tt)
	_recent[slot] = keep
	if keep.size() >= int(_limits.get("max_per_fighter_per_minute", 4)):
		return null
	if _rand(tick, i, 2) >= float(bd.get("chance", 1.0)):
		return null
	var free: Array = []
	for l in pool:
		if tick - int(_line_at.get(fid + "|" + str(l.id), -1000000)) >= gap_line:
			free.append(l)
	if free.is_empty():
		return null
	var line: Dictionary = free[int(_rand(tick, i, 3) * free.size()) % free.size()]
	_last_any = tick
	_last_slot[slot] = tick
	keep.append(tick)
	_beat_at[beat] = tick
	_line_at[fid + "|" + str(line.id)] = tick
	var text: String = str(line.text)
	var dur: float = clampf(float(_display.get("base_s", 0.9)) + float(_display.get("per_char_s", 0.035)) * text.length(),
		float(_display.get("min_dur_s", 1.6)), float(_display.get("max_dur_s", 2.6)))
	log.append({"tick": tick, "slot": slot, "id": fid, "beat": beat, "line": str(line.id), "text": text})
	return {
		"type": "bark", "speaker": slot, "text": text, "kind": "line",
		"cues": line.get("cues", []), "priority": int(bd.get("priority", 2)), "setpiece": false,
		"display": {"style": str(_display.get("style", "caption")), "dur_s": dur},
		"source": str(line.get("source", "")), "line_id": str(line.id), "beat": beat,
	}


## A float in [0, 1) from (match seed, salt, tick, the event's place in the tick, a purpose). Own hash; no RNG state.
func _rand(tick: int, i: int, purpose: int) -> float:
	var h: int = (_seed * 73856093) ^ (_salt * 19349663) ^ (tick * 83492791) ^ ((i + 1) * 2654435761) ^ (purpose * 40503)
	h &= 0xFFFFFFFF
	h = ((h >> 16) ^ h) * 0x45d9f3b
	h &= 0xFFFFFFFF
	h = ((h >> 16) ^ h) * 0x45d9f3b
	h &= 0xFFFFFFFF
	h = (h >> 16) ^ h
	return float(h & 0xFFFFFF) / 16777216.0
