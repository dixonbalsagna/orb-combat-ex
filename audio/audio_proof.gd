extends Node
## Does this program make sound? (docs/audio/desktop-sound.md; A-AUDIO-04.) Plays a fixed list of the game's own sounds through
## the game's own voices and buses, records what the engine's mixer puts out (an AudioEffectCapture at the end of the Master
## bus, so after the limiter), and checks each: not silent, not clipped, about the right length. It also drives test tones
## through the master limiter: a quiet one must be lifted cleanly, a very loud one held under the ceiling without being squared.
## It works with no sound card (the engine's dummy driver mixes all the same), so it proves the program, its data and the mixer;
## it does NOT prove that a given machine's speakers play it. Kept out of audio/tools/ so that it is in an exported program.
##   from the project:      godot --headless --path . --script res://audio/audio_proof_main.gd
##   the shipped program:   <the program> --headless -- --audio-proof
## (The second needs render/core/boot_entry.gd to add this node for that argument: an official release program takes no
## --script and no scene path.) It quits by itself, with exit code 1 on a failure, in about 15 seconds.

const LIST: Array = ["impact.light", "impact.heavy", "impact.crater", "energy.blast", "voice.protagonist.effort.heavy", "build.hit", "build.fall", "ui.confirm"]
const FLOOR: float = 0.02              # a sound is "there" while it is within 34 dB of its own peak
const SILENT_DB: float = -45.0         # a peak under this is silence

var bank: AudioBank
var voices: AudioVoices
var cap: AudioEffectCapture
var ceiling_db: float = -1.0
var fails: int = 0


func _ready() -> void:
	_run.call_deferred()


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


## Everything the Master put out over `secs` of real time (both channels, the louder of the two per frame).
func record(secs: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(secs * 1000.0):
		await get_tree().process_frame
		var n: int = cap.get_frames_available()
		if n > 0:
			for v in cap.get_buffer(n):
				out.append(v.x if absf(v.x) >= absf(v.y) else v.y)
	return out


## Wait for the last sound to end, then start the recording clean.
func quiet() -> void:
	var t0: int = Time.get_ticks_msec()
	while voices.active() > 0 and Time.get_ticks_msec() - t0 < 4000:
		await get_tree().process_frame
	await record(0.2)
	cap.clear_buffer()


static func peak_of(b: PackedFloat32Array) -> float:
	var p: float = 0.0
	for v in b:
		p = maxf(p, absf(v))
	return p


## Seconds from the first to the last sample within 34 dB of the peak.
static func span(b: PackedFloat32Array, rate: float) -> float:
	var p: float = peak_of(b) * FLOOR
	var first: int = -1
	var last: int = -1
	for i in range(b.size()):
		if absf(b[i]) > p:
			if first < 0:
				first = i
			last = i
	return 0.0 if first < 0 else float(last - first + 1) / rate


static func clipped(b: PackedFloat32Array) -> int:
	var n: int = 0
	for v in b:
		if absf(v) >= 0.999:
			n += 1
	return n


func cue(id: String, gain_db: float, group: String = "") -> AudioCues.Cue:
	var c := AudioCues.Cue.new()
	c.sound = id
	c.gain_db = gain_db
	c.priority = 90
	c.bus = "Sfx"
	c.group = group
	return c


func tone(secs: float, amp: float) -> AudioStreamWAV:
	var rate: int = 44100
	var n: int = int(rate * secs)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		bytes.encode_s16(i * 2, int(amp * sin(TAU * 220.0 * float(i) / rate) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = bytes
	return w


func _run() -> void:
	bank = AudioBank.new()
	voices = AudioVoices.new(bank)
	add_child(voices)
	await get_tree().process_frame
	var mix_rate: float = AudioServer.get_mix_rate()
	var build: String = "?"
	if FileAccess.file_exists("res://build_info.json"):
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://build_info.json"))
		if j is Dictionary:
			build = str(j.get("commit", j.get("sha", "?")))
	ceiling_db = float(voices.mix.master_limiter.ceiling_db)
	print("audio proof: %s | %s | %s | Godot %s | driver %s %d Hz | build %s" % [OS.get_name(), "exported program" if OS.has_feature("template") else "editor build", Engine.get_architecture_name(),
		Engine.get_version_info().string, AudioServer.get_driver_name(), int(mix_rate), build])
	cap = AudioEffectCapture.new()
	cap.buffer_length = 6.0
	AudioServer.add_bus_effect(0, cap)
	var sfx: int = AudioServer.get_bus_index("Sfx")

	print("1. the master limiter")
	var p := AudioStreamPlayer.new()
	p.bus = "Sfx"
	add_child(p)
	var lift: float = float(voices.mix.master_limiter.ceiling_db) - float(voices.mix.master_limiter.threshold_db)
	for row in [[-18.0, 0.0], [-1.0, 8.0]]:
		await quiet()
		p.stream = tone(0.5, db_to_linear(float(row[0])))
		p.volume_db = float(row[1])
		p.play()
		var rec: PackedFloat32Array = await record(0.8)
		var pk: float = linear_to_db(maxf(peak_of(rec), 1e-6))
		var sq: float = 0.0
		var cnt: int = 0
		for v in rec:
			if absf(v) > peak_of(rec) * FLOOR:
				sq += v * v
				cnt += 1
		var crest: float = pk - linear_to_db(maxf(sqrt(sq / maxf(cnt, 1)), 1e-6))      # 3 dB for a sine, 0 for a square
		var into: float = float(row[0]) + float(row[1])
		var want: float = minf(into + lift, ceiling_db)
		ok(absf(pk - want) <= 0.6 and crest >= 2.5, "a tone at %+.0f dB comes out at %+.1f dB (wanted %+.1f) and keeps its shape (crest %.1f dB; a squared wave is 0)" % [into, pk, want, crest])
	p.queue_free()

	print("2. the sounds")
	print("     %-34s %8s %8s %8s" % ["sound", "peak dB", "length", "expected"])
	for id in LIST:
		if not bank.has_sound(id):
			ok(false, "no such sound " + id)
			continue
		var src: PackedFloat32Array = bank.buffer(id, 0)
		bank.stream(id, 0)
		var expect: float = span(src, float(bank.rate_of(id)))
		await quiet()
		var took: bool = voices.play(cue(id, 0.0), 0.0, 1.0)
		var rec: PackedFloat32Array = await record(expect + 0.5)
		var pk: float = linear_to_db(maxf(peak_of(rec), 1e-6))
		var got: float = span(rec, mix_rate)
		var line: String = "%-34s %8.1f %7.2fs %7.2fs" % [id, pk, got, expect]
		ok(took and pk > SILENT_DB and pk <= ceiling_db + 0.1 and clipped(rec) == 0 and absf(got - expect) <= maxf(0.3 * expect, 0.08), line)

	await quiet()
	for i in range(8):
		voices.play(cue("impact.heavy", 6.0), 0.0, 1.0)
	voices.play(cue("impact.crater", 6.0), 0.0, 1.0)
	var pile: PackedFloat32Array = await record(1.2)
	var pile_db: float = linear_to_db(maxf(peak_of(pile), 1e-6))
	ok(pile_db > -6.0 and pile_db <= ceiling_db + 0.1 and clipped(pile) == 0, "nine loud sounds at once come out at %+.1f dB, under the ceiling, nothing clipped" % pile_db)

	await quiet()
	var wind: AudioCues.Cue = cue("amb.wind", -8.0, "wind")
	wind.bus = "Ambience"
	wind.loop = true
	wind.ambient = true
	var took_wind: bool = voices.play(wind, 0.0, 1.0)
	var rec2: PackedFloat32Array = await record(2.0)
	var wdb: float = linear_to_db(maxf(peak_of(rec2), 1e-6))
	ok(took_wind and wdb > -60.0 and wdb < -10.0, "the wind loop is there and quiet (%+.1f dB)" % wdb)
	voices.stop_group("wind", 0)

	await quiet()
	var rest: PackedFloat32Array = await record(0.4)
	ok(linear_to_db(maxf(peak_of(rest), 1e-6)) < SILENT_DB, "and silence when nothing is asked for")
	print("\naudio proof %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	get_tree().quit(1 if fails > 0 else 0)
