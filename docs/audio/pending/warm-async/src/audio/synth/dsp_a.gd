class_name AudioDspA
extends RefCounted
## The coroutine twins of AudioDsp's loops (docs/audio/warm-async.md): the same arithmetic, in the same order, with a yield check in every
## long loop (AudioSlice). Only the synths' async paths call these; AudioDsp itself is unchanged for every other caller.


static func noise(n: int, sd: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	var s: int = AudioDsp.state_of(sd)
	var _c1: int = 0
	var _e1: int = n
	while _c1 < _e1:
		for i in range(_c1, mini(_c1 + 1024, _e1)):
			s ^= (s << 13) & 0xFFFFFFFF
			s ^= s >> 17
			s ^= (s << 5) & 0xFFFFFFFF
			out[i] = float(s) * (1.0 / 2147483648.0) - 1.0
		_c1 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	return out


static func filter(buf: PackedFloat32Array, kind: String, f0: float, f1: float, tau: float, q: float, rate: int) -> void:
	var n: int = buf.size()
	var fs: float = float(rate)
	var glide: bool = tau > 0.0 and absf(f1 - f0) > 0.001
	var ceiling: float = fs * 0.45
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	var start: int = 0
	while start < n:
		if AudioSlice.due():
			await AudioSlice.next_frame()
		var stop: int = mini(start + AudioDsp.BLOCK, n) if glide else n
		var fc: float = f0
		if glide:
			fc = f1 + (f0 - f1) * exp(-(float(start) / fs) / tau)
		fc = clampf(fc, 15.0, ceiling)
		var w0: float = TAU * fc / fs
		var cw: float = cos(w0)
		var alpha: float = sin(w0) / (2.0 * maxf(q, 0.05))
		var a0: float = 1.0 + alpha
		var a1: float = -2.0 * cw / a0
		var a2: float = (1.0 - alpha) / a0
		var b0: float
		var b1: float
		var b2: float
		match kind:
			"hp":
				b0 = (1.0 + cw) * 0.5 / a0
				b1 = -(1.0 + cw) / a0
				b2 = b0
			"bp":
				b0 = alpha / a0
				b1 = 0.0
				b2 = -b0
			_:
				b0 = (1.0 - cw) * 0.5 / a0
				b1 = (1.0 - cw) / a0
				b2 = b0
		var _c2: int = start
		var _e2: int = stop
		while _c2 < _e2:
			for i in range(_c2, mini(_c2 + 1024, _e2)):
				var x0: float = buf[i]
				var y0: float = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
				x2 = x1
				x1 = x0
				y2 = y1
				y1 = y0
				buf[i] = y0
			_c2 += 1024
			if AudioSlice.due():
				await AudioSlice.next_frame()
		start = stop


## Soft saturation, in place: tanh(drive x) / tanh(drive). drive <= 0 leaves the buffer alone.


static func saturate(buf: PackedFloat32Array, drive: float) -> void:
	if drive <= 0.0:
		return
	var norm: float = 1.0 / tanh(drive)
	var _c3: int = 0
	var _e3: int = buf.size()
	while _c3 < _e3:
		for i in range(_c3, mini(_c3 + 1024, _e3)):
			buf[i] = tanh(drive * buf[i]) * norm
		_c3 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()


static func peak(buf: PackedFloat32Array) -> float:
	var p: float = 0.0
	var _c4: int = 0
	var _e4: int = buf.size()
	while _c4 < _e4:
		for i in range(_c4, mini(_c4 + 1024, _e4)):
			var a: float = absf(buf[i])
			if a > p:
				p = a
		_c4 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	return p


static func rms(buf: PackedFloat32Array) -> float:
	if buf.is_empty():
		return 0.0
	var s: float = 0.0
	var _c5: int = 0
	var _e5: int = buf.size()
	while _c5 < _e5:
		for i in range(_c5, mini(_c5 + 1024, _e5)):
			s += buf[i] * buf[i]
		_c5 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	return sqrt(s / float(buf.size()))


## Scale so the largest sample is target (linear). A silent buffer stays silent.


static func normalize(buf: PackedFloat32Array, target: float) -> void:
	var p: float = await peak(buf)
	if p < 1e-9:
		return
	var k: float = target / p
	var _c6: int = 0
	var _e6: int = buf.size()
	while _c6 < _e6:
		for i in range(_c6, mini(_c6 + 1024, _e6)):
			buf[i] *= k
		_c6 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()


## Remove DC with a one-pole high-pass at fc Hz (in place).


static func dc_block(buf: PackedFloat32Array, fc: float, rate: int) -> void:
	var r: float = exp(-TAU * fc / float(rate))
	var x1: float = 0.0
	var y1: float = 0.0
	var _c7: int = 0
	var _e7: int = buf.size()
	while _c7 < _e7:
		for i in range(_c7, mini(_c7 + 1024, _e7)):
			var x0: float = buf[i]
			var y0: float = x0 - x1 + r * y1
			x1 = x0
			y1 = y0
			buf[i] = y0
		_c7 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()


## Short linear fades at both ends so a sound never starts or stops on a click.


static func fade(buf: PackedFloat32Array, fade_in: float, fade_out: float, rate: int) -> void:
	var n: int = buf.size()
	var ni: int = mini(int(fade_in * rate), n)
	var no: int = mini(int(fade_out * rate), n)
	var _c8: int = 0
	var _e8: int = ni
	while _c8 < _e8:
		for i in range(_c8, mini(_c8 + 1024, _e8)):
			buf[i] *= float(i) / float(ni)
		_c8 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	var _c9: int = 0
	var _e9: int = no
	while _c9 < _e9:
		for i in range(_c9, mini(_c9 + 1024, _e9)):
			buf[n - 1 - i] *= float(i) / float(no)
		_c9 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()


## Add src into dst starting at sample offset at (dst grows if needed), scaled by gain.


static func mix_into(dst: PackedFloat32Array, src: PackedFloat32Array, at: int, gain: float) -> void:
	var need: int = at + src.size()
	if dst.size() < need:
		dst.resize(need)
	var _c10: int = 0
	var _e10: int = src.size()
	while _c10 < _e10:
		for i in range(_c10, mini(_c10 + 1024, _e10)):
			dst[at + i] += src[i] * gain
		_c10 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()


## Wrap a mono buffer as a 16-bit AudioStreamWAV (a runtime stream, or saveable with save_to_wav).


static func to_wav(buf: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	var _c11: int = 0
	var _e11: int = buf.size()
	while _c11 < _e11:
		for i in range(_c11, mini(_c11 + 1024, _e11)):
			data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
		_c11 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	w.data = data
	return w
