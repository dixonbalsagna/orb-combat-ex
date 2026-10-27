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
const WORLD_PATH := "res://audio/data/world_cues.json"

var impacts: Dictionary = {}
var grunts: Dictionary = {}
var babble: Dictionary = {}       # babble.json: the babble voice (syllable bank, moods, timeline)
var drones: Dictionary = {}       # tug_cues.json `drones`: seamless loops (ids drone.<name>); not part of ids()
var _tug_on: bool = false       # tug_cues.json `enabled`: the drones are warmed only when the struggle is switched on
var world: Dictionary = {}         # world_cues.json: the ambience beds (ids amb.<name>) and the surface sounds (ids surf.<surface>.hit and .slide)
var flashes: Dictionary = {}      # flash_cues.json: the 12 head-flash cues and the four sound families
var _cache: Dictionary = {}       # "id#variant" -> AudioStreamWAV
var render_ms: Dictionary = {}    # "id#variant" -> milliseconds it took to render
var _queue: Array = []            # [id, variant] pairs still to render for warm_step()
var warming: bool = false         # the async warm-up is running: sounds are being rendered a few at a time across frames (docs/audio/warm-async.md)
var async_ok: bool = false        # a node in the tree gives the warm-up its frames (AudioVoices sets it when it enters the tree)
var skipped: int = 0              # plays dropped (silent) because the sound was not rendered yet while warming
var _wq: Array = []               # [id, variant] pairs still to render for the async warm-up, in the order they are wanted
signal warmed                     # the async warm-up has rendered everything it was given


func _init() -> void:
	impacts = load_json(IMPACTS_PATH)
	grunts = load_json(GRUNTS_PATH)
	flashes = load_json(FLASH_PATH)
	babble = load_json(BABBLE_PATH)
	var tug: Dictionary = load_json(TUG_PATH)
	drones = tug.get("drones", {})
	_tug_on = bool(tug.get("enabled", false))
	drones.merge(load_json(CARRY_PATH).get("drones", {}))
	world = load_json(WORLD_PATH)


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
	if id.begins_with("amb."):
		return AmbienceSynth.render(r)
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
	if id.begins_with("amb."):
		return int(_recipe(id).get("rate", 16000))
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
	if bool(world.get("enabled", false)):
		for k in world.get("sounds", {}):
			out.append(String(k))      # the surfaces; the beds are warmed by the host for the ring (AudioWorld.warm_beds)
	return out


## Render every variant now, so nothing is rendered in the middle of a fight. Returns the milliseconds taken.
func warm(with_extras: bool = true) -> float:
	if async_ok and DisplayServer.get_name() != "headless":
		warm_async_begin(with_extras)      # a game with a node in the tree and a screen: the same work across frames, not one block
		return 0.0
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


## ---- the warm-up across frames (docs/audio/warm-async.md). The same sounds, rendered by the same code in the same order of arithmetic
## (the coroutine twins in the synths), a few milliseconds a frame (AudioSlice.budget_us), most wanted first. A sound asked for before
## it is rendered is dropped (AudioVoices) while the warm-up runs; once it is over, an un-warmed sound renders on its first play as ever.

## The coroutine twin of buffer(): the same dispatch, the long loops yield to AudioSlice.
func buffer_a(id: String, variant: int) -> PackedFloat32Array:
	var r: Dictionary = _recipe(id)
	if r.is_empty():
		return PackedFloat32Array()
	var v: int = posmod(variant, variants(id))
	if id.begins_with("amb."):
		return await AmbienceSynth.render_a(r)
	if id.begins_with("drone."):
		return await DroneSynth.render_a(r)
	if id.begins_with("babble."):
		var bp: PackedStringArray = id.split(".")
		if bp.size() == 3:
			if bp[2] == "blip":
				return await BabbleSynth.blip_a(babble, bp[1])
			return await BabbleSynth.laugh_a(babble, bp[1], v, bp[2] == "laugh_boom")
		return await BabbleSynth.render_a(id, babble)
	if id.begins_with("flash."):
		var p: PackedStringArray = id.split(".")
		return await FlashSynth.render_a(r, flashes.families[p[2]], p[2], int(flashes.rate), int(flashes.bank_seed), p[1])
	if id.begins_with("voice."):
		return await GruntSynth.render_a(r, int(grunts.get("bank_seed", 0)), id, v)
	return await ImpactSynth.render_a(r, int(impacts.get("bank_seed", 0)), id, v)


## The coroutine twin of stream(): the same stream, cached the same way.
func stream_a(id: String, variant: int) -> AudioStreamWAV:
	var v: int = posmod(variant, variants(id))
	var key: String = "%s#%d" % [id, v]
	if _cache.has(key):
		return _cache[key]
	var buf: PackedFloat32Array = await buffer_a(id, v)
	var w: AudioStreamWAV = await AudioDspA.to_wav(buf, rate_of(id))
	if not _cache.has(key):          # a sync play may have rendered it meanwhile: keep that one
		_cache[key] = w
	return _cache[key]


## Is this variant rendered (so a play is free)?
func is_ready(id: String, variant: int) -> bool:
	return _cache.has("%s#%d" % [id, posmod(variant, variants(id))])


## Most wanted first: the babble and the grunts of the intro, then the hits and the rest of the match's sounds, then the head flashes,
## then the optional sets (drones, surfaces). Within a rank, the bank's own order.
func warm_rank(id: String) -> int:
	if id.begins_with("babble."):
		return 0
	if id.begins_with("voice."):
		return 1
	if id.begins_with("flash."):
		return 3
	if id.begins_with("drone.") or id.begins_with("amb.") or id.begins_with("surf."):
		return 4
	return 2


## Everything warm() would render, in the order the async warm-up wants it.
func warm_plan(with_extras: bool = true) -> Array:
	var all: Array = []
	for id in ids():
		all.append(id)
	if with_extras:
		for id in extra_ids():
			all.append(id)
	var order: Array = []
	for k in range(all.size()):
		order.append([warm_rank(String(all[k])), k, String(all[k])])
	order.sort()
	var ids_sorted: Array = []
	for o in order:
		ids_sorted.append(o[2])
	return ids_sorted


## Queue that plan and start the frame-by-frame run.
func warm_async_begin(with_extras: bool = true) -> void:
	warm_ids_async(warm_plan(with_extras))


## Queue these ids (every variant) behind what is already queued: the host's call for the ring's beds (AudioWorld.warm_beds), say.
func warm_ids_async(id_list: Array) -> void:
	for id in id_list:
		for v in range(variants(String(id))):
			if not _cache.has("%s#%d" % [id, v]):
				_wq.append([String(id), v])
	if not warming and not _wq.is_empty():
		Callable(self, "_warm_run").call()        # a coroutine: it runs until its first yield, then a frame at a time


func _warm_run() -> void:
	warming = true
	AudioSlice.on = true
	AudioSlice.start_frame()
	while not _wq.is_empty():
		var q: Array = _wq.pop_front()
		await stream_a(q[0], q[1])
		if AudioSlice.due():
			await AudioSlice.next_frame()
	AudioSlice.on = false
	warming = false
	warmed.emit()


## The recipe for an id, or an empty dictionary.
func _recipe(id: String) -> Dictionary:
	if id.begins_with("amb."):
		return world.get("beds", {}).get(id.substr(4), {})
	if id.begins_with("surf."):
		return world.get("sounds", {}).get(id, {})
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
