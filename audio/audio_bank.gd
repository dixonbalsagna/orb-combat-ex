class_name AudioBank
extends RefCounted
## The sound bank: renders each sound from its recipe (data/impacts.json, data/grunts.json) the first time it is asked
## for and keeps the AudioStreamWAV. A sound is a pure function of its recipe and the fixed bank seed, so the bank is
## identical on every machine and in every match; which variant plays in a match is the cue mapper's business.
##
## Ids: "impact.light" and the other impact recipes; "voice.<voice>.<gesture>", for example
## "voice.protagonist.effort.heavy".

const IMPACTS_PATH := "res://audio/data/impacts.json"
const GRUNTS_PATH := "res://audio/data/grunts.json"
const FLASH_PATH := "res://audio/data/flash_cues.json"
const BABBLE_PATH := "res://audio/data/babble.json"
const TUG_PATH := "res://audio/data/tug_cues.json"
const CUES_PATH := "res://audio/data/cues.json"
const CARRY_PATH := "res://audio/data/carry_cues.json"

var impacts: Dictionary = {}
var grunts: Dictionary = {}
var babble: Dictionary = {}       # babble.json: the babble voice (syllable bank, moods, timeline)
var drones: Dictionary = {}       # tug_cues.json `drones`: seamless loops (ids drone.<name>); not part of ids()
var _tug_on: bool = false       # tug_cues.json `enabled`: the drones are warmed only when the struggle is switched on
var flashes: Dictionary = {}      # flash_cues.json: the 12 head-flash cues and the four sound families
var _cache: Dictionary = {}       # "id#variant" -> AudioStreamWAV
var render_ms: Dictionary = {}    # "id#variant" -> milliseconds it took to render
var _queue: Array = []            # [id, variant] pairs still to render for warm_step()


func _init() -> void:
	impacts = load_json(IMPACTS_PATH)
	grunts = load_json(GRUNTS_PATH)
	flashes = load_json(FLASH_PATH)
	babble = load_json(BABBLE_PATH)
	var tug: Dictionary = load_json(TUG_PATH)
	drones = tug.get("drones", {})
	_tug_on = bool(tug.get("enabled", false))
	drones.merge(load_json(CARRY_PATH).get("drones", {}))


static func load_json(path: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("AudioBank: cannot read %s" % path)
		return {}
	return parsed


## The sound family (circles, blades, wedges, steps) of a fighter's voice id, or "".
func family_of_voice(voice: String) -> String:
	for k in flashes.get("families", {}):
		if flashes.families[k].voice == voice:
			return k
	return ""


## The babble bank ids for the given voices (all voices if empty): every syllable in the voice's lexicon in every
## timbre, and the laugh. About 60 short clips per voice.
func babble_ids(voices: Array = []) -> Array:
	var out: Array = []
	for v in babble.get("voices", {}):
		if not voices.is_empty() and not (v in voices):
			continue
		for tm in babble.timbres:
			for syl in babble.voices[v].lexicon:
				out.append("babble.%s.%s.%s" % [v, tm, syl])
		out.append("babble.%s.laugh" % v)
		if babble.voices[v].has("laugh_boom"):
			out.append("babble.%s.laugh_boom" % v)
		if babble.voices[v].has("blip"):
			out.append("babble.%s.blip" % v)
	return out


## "flash.<flash>.<family>" for every flash and family (or just the families of the given voices). Not part of ids()
## or warm(): the surge is 4.4 s long, so render these only for the fighters in the match.
func flash_ids(voices: Array = []) -> Array:
	var out: Array = []
	for fam in flashes.get("families", {}):
		if not voices.is_empty() and not (flashes.families[fam].voice in voices):
			continue
		for fl in flashes.get("flashes", {}):
			if not bool(flashes.flashes[fl].get("held", false)):
				out.append("flash.%s.%s" % [fl, fam])
	return out


## Every sound id the bank can render.
func ids() -> Array:
	var out: Array = []
	for k in impacts.get("sounds", {}):
		out.append(k)
	for v in grunts.get("voices", {}):
		for g in grunts.voices[v].gestures:
			out.append("voice.%s.%s" % [v, g])
	return out


func has_sound(id: String) -> bool:
	return _recipe(id).size() > 0


func variants(id: String) -> int:
	return maxi(1, int(_recipe(id).get("variants", 1)))


## The mono samples of one variant (rendered fresh each call; stream() caches the wrapped stream).
func buffer(id: String, variant: int) -> PackedFloat32Array:
	var r: Dictionary = _recipe(id)
	if r.is_empty():
		return PackedFloat32Array()
	var v: int = posmod(variant, variants(id))
	if id.begins_with("drone."):
		return DroneSynth.render(r)
	if id.begins_with("babble."):
		var bp: PackedStringArray = id.split(".")
		if bp.size() == 3:
			if bp[2] == "blip":
				return BabbleSynth.blip(babble, bp[1])
			return BabbleSynth.laugh(babble, bp[1], v, bp[2] == "laugh_boom")
		return BabbleSynth.render(id, babble)
	if id.begins_with("flash."):
		var p: PackedStringArray = id.split(".")
		return FlashSynth.render(r, flashes.families[p[2]], p[2], int(flashes.rate), int(flashes.bank_seed), p[1])
	if id.begins_with("voice."):
		return GruntSynth.render(r, int(grunts.get("bank_seed", 0)), id, v)
	return ImpactSynth.render(r, int(impacts.get("bank_seed", 0)), id, v)


func rate_of(id: String) -> int:
	if id.begins_with("drone."):
		return int(_recipe(id).get("rate", 32000))
	if id.begins_with("babble."):
		return int(babble.get("rate", 12000))
	if id.begins_with("flash."):
		return int(flashes.get("rate", 16000))
	return int(_recipe(id).get("rate", 32000))


## How long a variant plays at normal pitch, in seconds (UI times a line's text to its grunt with this).
func duration(id: String, variant: int) -> float:
	return stream(id, variant).get_length()


func stream(id: String, variant: int) -> AudioStreamWAV:
	var v: int = posmod(variant, variants(id))
	var key: String = "%s#%d" % [id, v]
	if _cache.has(key):
		return _cache[key]
	var t0: int = Time.get_ticks_usec()
	var w: AudioStreamWAV = AudioDsp.to_wav(buffer(id, v), rate_of(id))
	render_ms[key] = (Time.get_ticks_usec() - t0) / 1000.0
	_cache[key] = w
	return w


## The voices of the roster (cues.json `fighters`): the head-flash families and the babble are warmed for these.
func roster_voices() -> Array:
	var out: Array = []
	var f: Dictionary = load_json(CUES_PATH).get("fighters", {})
	for k in f:
		if not (String(f[k]) in out):
			out.append(String(f[k]))
	return out


## The sounds a match can play that are not in ids(): the head flashes of the roster's voices (one family each), every
## voice's babble, and the beam struggle's drones when it is switched on. First play of any of these used to render it
## in the middle of a fight (7 to 23 ms).
func extra_ids() -> Array:
	var out: Array = []
	out.append_array(flash_ids(roster_voices()))
	out.append_array(babble_ids())
	if _tug_on:
		for k in drones:
			out.append("drone." + String(k))
	return out


## Render every variant now, so nothing is rendered in the middle of a fight. Returns the milliseconds taken.
func warm(with_extras: bool = true) -> float:
	var t0: int = Time.get_ticks_usec()
	for id in ids():
		for v in range(variants(id)):
			stream(id, v)
	if with_extras:
		for id in extra_ids():
			for v in range(variants(id)):
				stream(id, v)
	return (Time.get_ticks_usec() - t0) / 1000.0


## The same work in slices, for a loading screen or the first frames of a match: call warm_begin() once, then
## warm_step() each frame until it returns false. One call renders one variant (2 to 60 ms on a desktop).
func warm_begin(only_voices: Array = [], with_flash: bool = false, with_babble: bool = false) -> void:
	_queue.clear()
	if with_babble:
		for id in babble_ids(only_voices):
			for v in range(variants(id)):
				_queue.append([id, v])
	if with_flash:
		for id in flash_ids(only_voices):
			_queue.append([id, 0])
	for id in ids():
		if id.begins_with("voice.") and not only_voices.is_empty() and not (id.split(".")[1] in only_voices):
			continue
		for v in range(variants(id)):
			_queue.append([id, v])


## Render the next queued variant. Returns true while more remain.
func warm_step() -> bool:
	if _queue.is_empty():
		return false
	var q: Array = _queue.pop_front()
	stream(q[0], q[1])
	return not _queue.is_empty()


## The recipe for an id, or an empty dictionary.
func _recipe(id: String) -> Dictionary:
	if id.begins_with("drone."):
		return drones.get(id.substr(6), {})
	if id.begins_with("babble."):
		var b: PackedStringArray = id.split(".")
		if b.size() < 3 or not babble.get("voices", {}).has(b[1]):
			return {}
		if b.size() == 3:
			var bv: Dictionary = babble.voices[b[1]]
			if b[2] == "laugh":
				return {"variants": int(bv.laugh.variants)}
			if b[2] == "laugh_boom" and bv.has("laugh_boom"):
				return {"variants": int(bv.laugh_boom.variants)}
			if b[2] == "blip" and bv.has("blip"):
				return {"variants": 1}
			return {}
		if b.size() == 4 and babble.timbres.has(b[2]) and babble.syllables.has(b[3]):
			return {"variants": 1}
		return {}
	if id.begins_with("flash."):
		var p: PackedStringArray = id.split(".")
		if p.size() != 3 or not flashes.get("families", {}).has(p[2]):
			return {}
		return flashes.get("flashes", {}).get(p[1], {})
	if id.begins_with("voice."):
		var parts: PackedStringArray = id.split(".")
		if parts.size() < 3:
			return {}
		var voice: String = parts[1]
		var gesture: String = ".".join(parts.slice(2))
		return grunts.get("voices", {}).get(voice, {}).get("gestures", {}).get(gesture, {})
	return impacts.get("sounds", {}).get(id, {})
