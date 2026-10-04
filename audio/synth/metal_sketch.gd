class_name MetalSketch
extends RefCounted
## Renders a short REFERENCE clip for Suno: the sketch-a-town-band hook re-voiced as a riff-heavy speed-metal arrangement,
## at a chosen tempo (data/metal_ref.json). It exists to steer Suno's model by audio (rhythm, harmony, arrangement and the
## joke), not to be the music: every sound is synthesised (distorted saws for the guitars, our own drum and brass
## instruments from music_sketch.gd), so the tone is a rough stand-in and Suno is expected to do the real guitar sound.
##
## The arrangement, 8 bars: 1-2 the gallop riff alone; 3-4 the hook on twin harmony lead over the riff; 5-6 the hook an
## octave up with brass doubling; 7 the tongue-in-cheek bar, where everything stops and a tuba plays an oompah march with a
## snare cadence; 8 one huge power chord and a crash. The key is E (Mixolydian: E, D, A and B chords), a major sound, with
## no flattened second, no tritone and no slow bells, which is what the earlier sketches had that read as spooky.


static func render(spec: Dictionary, bpm: float) -> PackedFloat32Array:
	var fs: int = int(spec.rate)
	var beat: float = 60.0 / bpm
	var bars: Array = spec.bars
	var total: int = int(float(bars.size()) * 4.0 * beat * float(fs))
	var mix := PackedFloat32Array()
	mix.resize(total)
	var g: Dictionary = spec.gain
	var root: float = float(spec.root_midi)          # the low E, MIDI 40
	var k: int = 0
	for bi in range(bars.size()):
		var bar: Dictionary = bars[bi]
		var t0: float = float(bi) * 4.0 * beat
		var kind: String = String(bar.kind)
		var ch: Array = bar.chords                  # semitones from the root for each half bar
		for half in range(2):
			var r: float = root + float(ch[half])
			var th: float = t0 + float(half) * 2.0 * beat
			match kind:
				"gallop", "hook":
					# the gallop: long-short-short on every beat, palm muted; chords on the first of each half
					for b in range(2):
						var tb: float = th + float(b) * beat
						for pos in [0.0, 0.5, 0.75]:
							_put(mix, _chug(r, 0.1 * beat if pos > 0.0 else 0.22 * beat, fs, k), tb + pos * beat, float(g.rhythm), fs)
							k += 1
				"hit":
					if half == 0:
						_put(mix, _chord(r, 3.2 * beat, fs, k), th, float(g.rhythm) * 1.2, fs)
						_put(mix, MusicSketch._inst("cymbal", 60.0, 1.0, 1.0, fs, k + 1), th, float(g.crash), fs)
						_put(mix, _kick(1.0, fs), th, float(g.kick), fs)
						k += 3
				_:
					pass
		# bass doubles the riff root in eighths under the gallop and the hook
		if kind == "gallop" or kind == "hook":
			for j in range(8):
				var rb: float = root + float(ch[0 if j < 4 else 1]) - 12.0
				_put(mix, _bass(rb, 0.4 * beat, fs), t0 + 0.5 * float(j) * beat, float(g.bass), fs)
			# double kick: the same gallop, a snare on 2 and 4, eighth hats
			for b in range(4):
				for pos in [0.0, 0.5, 0.75]:
					_put(mix, _kick(0.9, fs), t0 + (float(b) + pos) * beat, float(g.kick), fs)
				_put(mix, MusicSketch._inst("tick", 90.0, 0.08, 0.5, fs, k), t0 + float(b) * beat, float(g.hat), fs)
				_put(mix, MusicSketch._inst("tick", 90.0, 0.08, 0.4, fs, k + 1), t0 + (float(b) + 0.5) * beat, float(g.hat), fs)
				k += 2
			for b in [1, 3]:
				_put(mix, MusicSketch._inst("snare", 70.0, 0.15, 1.0, fs, k), t0 + float(b) * beat, float(g.snare), fs)
				k += 1
			_put(mix, MusicSketch._inst("cymbal", 60.0, 1.0, 0.7, fs, k), t0, float(g.crash) * 0.6, fs)
			k += 1
		if kind == "march":
			# the joke: a tuba oompah and a snare cadence, nothing else
			for b in range(4):
				var tb2: float = t0 + float(b) * beat
				if b % 2 == 0:
					_put(mix, MusicSketch._inst("tuba", root + (0.0 if b == 0 else 7.0), 0.45 * beat, 1.0, fs, k), tb2, float(g.tuba), fs)
				else:
					for dm in [4.0, 7.0, 12.0]:
						_put(mix, MusicSketch._inst("trombone", root + 12.0 + dm, 0.35 * beat, 0.8, fs, k), tb2, float(g.stab), fs)
				_put(mix, MusicSketch._inst("snare", 70.0, 0.15, 0.5 + 0.1 * float(b), fs, k + 7), tb2, float(g.snare) * 0.7, fs)
				_put(mix, MusicSketch._inst("snare", 70.0, 0.15, 0.4, fs, k + 8), tb2 + 0.5 * beat, float(g.snare) * 0.5, fs)
				k += 1
	# the hook, in twin harmony lead (bars 3-6) and brass doubling (bars 5-6): [bar, beat, midi, beats, harmony midi]
	for n in spec.hook:
		var t: float = float(n[0]) * 4.0 * beat + float(n[1]) * beat
		var d: float = float(n[3]) * beat
		_put(mix, _lead(float(n[2]), d, fs), t, float(g.lead), fs)
		_put(mix, _lead(float(n[4]), d, fs), t, float(g.lead) * 0.8, fs)
		if int(n[0]) in spec.brass_bars:
			_put(mix, MusicSketch._inst("brass", float(n[2]), d, 0.9, fs, k), t, float(g.brass), fs)
			k += 1
	AudioDsp.saturate(mix, 1.15)
	AudioDsp.dc_block(mix, 25.0, fs)
	AudioDsp.normalize(mix, AudioDsp.db_to_lin(-3.0))
	AudioDsp.fade(mix, 0.004, 0.25, fs)
	return mix


static func _put(mix: PackedFloat32Array, buf: PackedFloat32Array, t: float, g: float, fs: int) -> void:
	var at: int = int(t * fs)
	var n: int = mini(buf.size(), mix.size() - at)
	for i in range(n):
		mix[at + i] += buf[i] * g


static func _hz(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


## A distorted power chord (root, fifth, octave, each as a detuned pair of saws): palm-muted chug if dur is short.
static func _chord(m: float, dur: float, fs: int, sd: int) -> PackedFloat32Array:
	var rel: float = 0.06
	var n: int = int((dur + rel) * fs)
	var out := PackedFloat32Array()
	out.resize(n)
	var fsf: float = float(fs)
	var fr: Array = [_hz(m), _hz(m + 7.0), _hz(m + 12.0)]
	var ph := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	for i in range(n):
		var t: float = float(i) / fsf
		var x: float = 0.0
		for v in range(3):
			var f: float = fr[v]
			ph[v * 2] += f * 1.003 / fsf
			ph[v * 2 + 1] += f * 0.997 / fsf
			ph[v * 2] -= floor(ph[v * 2])
			ph[v * 2 + 1] -= floor(ph[v * 2 + 1])
			x += (ph[v * 2] * 2.0 - 1.0) + (ph[v * 2 + 1] * 2.0 - 1.0)
		var e: float = 1.0
		if t < 0.003:
			e = t / 0.003
		elif t > dur:
			e = maxf(0.0, 1.0 - (t - dur) / rel)
		out[i] = x * e
	return _amp(out, fs, 14.0)


## A palm-muted chug: a short chord with a fast decay.
static func _chug(m: float, dur: float, fs: int, sd: int) -> PackedFloat32Array:
	var b: PackedFloat32Array = _chord(m, dur, fs, sd)
	var dec: float = exp(-AudioDsp.LN60 / (float(fs) * (dur * 1.6 + 0.02)))
	var amp: float = 1.0
	for i in range(b.size()):
		b[i] *= amp
		amp *= dec
	return b


## High-gain amp and cabinet: tighten (high-pass), two stages of clipping, then roll the top off.
static func _amp(buf: PackedFloat32Array, fs: int, gain: float) -> PackedFloat32Array:
	AudioDsp.normalize(buf, 1.0)
	AudioDsp.filter(buf, "hp", 140.0, 140.0, 0.0, 0.7, fs)
	for i in range(buf.size()):
		buf[i] = tanh(buf[i] * gain)
	for i in range(buf.size()):
		buf[i] = tanh(buf[i] * 2.5 + 0.1)
	AudioDsp.filter(buf, "lp", 4200.0, 4200.0, 0.0, 0.8, fs)
	AudioDsp.filter(buf, "lp", 4200.0, 4200.0, 0.0, 0.6, fs)
	AudioDsp.filter(buf, "hp", 85.0, 85.0, 0.0, 0.7, fs)
	AudioDsp.normalize(buf, 0.8)
	return buf


## A singing lead guitar note: a saw with a late vibrato through a lighter amp.
static func _lead(m: float, dur: float, fs: int) -> PackedFloat32Array:
	var rel: float = 0.08
	var n: int = int((dur + rel) * fs)
	var out := PackedFloat32Array()
	out.resize(n)
	var fsf: float = float(fs)
	var f: float = _hz(m)
	var ph: float = 0.0
	for i in range(n):
		var t: float = float(i) / fsf
		ph += f * (1.0 + 0.008 * sin(TAU * 5.5 * t) * minf(1.0, maxf(0.0, (t - 0.12) / 0.2))) / fsf
		ph -= floor(ph)
		var e: float = minf(1.0, t / 0.01)
		if t > dur:
			e = maxf(0.0, 1.0 - (t - dur) / rel)
		out[i] = (ph * 2.0 - 1.0) * e
	AudioDsp.filter(out, "hp", 200.0, 200.0, 0.0, 0.7, fs)
	for i in range(out.size()):
		out[i] = tanh(out[i] * 4.0)
	AudioDsp.filter(out, "lp", 5200.0, 5200.0, 0.0, 0.7, fs)
	AudioDsp.normalize(out, 0.8)
	return out


static func _bass(m: float, dur: float, fs: int) -> PackedFloat32Array:
	var rel: float = 0.04
	var n: int = int((dur + rel) * fs)
	var out := PackedFloat32Array()
	out.resize(n)
	var fsf: float = float(fs)
	var f: float = _hz(m)
	var ph: float = 0.0
	for i in range(n):
		var t: float = float(i) / fsf
		ph += f / fsf
		ph -= floor(ph)
		var e: float = minf(1.0, t / 0.004)
		if t > dur:
			e = maxf(0.0, 1.0 - (t - dur) / rel)
		out[i] = (ph * 2.0 - 1.0) * e
	AudioDsp.filter(out, "lp", 650.0, 650.0, 0.0, 0.8, fs)
	for i in range(out.size()):
		out[i] = tanh(out[i] * 3.0)
	AudioDsp.normalize(out, 0.8)
	return out


## A tight double-kick hit: a short pitch drop and a click.
static func _kick(vel: float, fs: int) -> PackedFloat32Array:
	var t60: float = 0.09
	var n: int = int(t60 * 1.05 * fs)
	var out := PackedFloat32Array()
	out.resize(n)
	var fsf: float = float(fs)
	var ph: float = 0.0
	var dec: float = exp(-AudioDsp.LN60 / (fsf * t60))
	var gl: float = exp(-1.0 / (fsf * 0.02))
	var gg: float = 1.0
	var amp: float = vel
	for i in range(n):
		ph += TAU * (52.0 + 70.0 * gg) / fsf
		gg *= gl
		var click: float = 0.35 * exp(-float(i) / (fsf * 0.0015)) * sin(TAU * 2400.0 * float(i) / fsf)
		out[i] = (sin(ph) + click) * amp
		amp *= dec
	AudioDsp.saturate(out, 1.8)
	return out
