"""The anchored edits for audio_bank.gd and audio_voices.gd of the warm-async park. Used by the park's apply.py and, here, by the dev tree.
Usage: python bank_async_edits.py <root>"""
import sys, os

BANK_STATE = '''var warming: bool = false         # the async warm-up is running: sounds are being rendered a few at a time across frames (docs/audio/warm-async.md)
var async_ok: bool = false        # a node in the tree gives the warm-up its frames (AudioVoices sets it when it enters the tree)
var skipped: int = 0              # plays dropped (silent) because the sound was not rendered yet while warming
var _wq: Array = []               # [id, variant] pairs still to render for the async warm-up, in the order they are wanted
signal warmed                     # the async warm-up has rendered everything it was given
'''

BANK_WARM_HEAD = '''	if async_ok and DisplayServer.get_name() != "headless":
		warm_async_begin(with_extras)      # a game with a node in the tree and a screen: the same work across frames, not one block
		return 0.0
'''

BANK_FUNCS = '''## ---- the warm-up across frames (docs/audio/warm-async.md). The same sounds, rendered by the same code in the same order of arithmetic
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


'''

VOICES_READY = "	bank.async_ok = true             # the warm-up may use this node's frames (AudioBank.warm)\n"
VOICES_PLAY = '''	if bank.warming and not bank.is_ready(cue.sound, cue.variant):
		bank.skipped += 1      # not rendered yet: dropped, silently, while the warm-up runs (the most wanted sounds are first)
		return false
'''


def edit(path, pairs):
    raw = open(path, encoding="utf-8", newline="").read()
    crlf = "\r\n" in raw
    t = raw.replace("\r\n", "\n")
    for old, new in pairs:
        assert t.count(old) == 1, (path, t.count(old), old[:70])
        t = t.replace(old, new)
    open(path, "w", encoding="utf-8", newline="").write(t.replace("\n", "\r\n") if crlf else t)


root = sys.argv[1]
edit(os.path.join(root, "audio/audio_bank.gd"), [
    ("var _queue: Array = []            # [id, variant] pairs still to render for warm_step()\n", "var _queue: Array = []            # [id, variant] pairs still to render for warm_step()\n" + BANK_STATE),
    ("func warm(with_extras: bool = true) -> float:\n", "func warm(with_extras: bool = true) -> float:\n" + BANK_WARM_HEAD),
    ("## The recipe for an id, or an empty dictionary.\nfunc _recipe(id: String) -> Dictionary:\n", BANK_FUNCS + "## The recipe for an id, or an empty dictionary.\nfunc _recipe(id: String) -> Dictionary:\n"),
])
edit(os.path.join(root, "audio/audio_voices.gd"), [
    ("func _ready() -> void:\n\tsetup_buses(mix)\n", "func _ready() -> void:\n\tsetup_buses(mix)\n" + VOICES_READY),
    ("\tvar slot: int = _take(cue)\n", VOICES_PLAY + "\tvar slot: int = _take(cue)\n"),
])
print("bank and voices edited")
