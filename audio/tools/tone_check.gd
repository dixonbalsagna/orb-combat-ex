extends SceneTree
## How bright is each hit? Orb heard the brawl's hits as "tinny", "metallic" and "a little too high pitched" (2026-10-16). A
## hit's raw spectrum is mostly low body, which a laptop or phone speaker does not reproduce; what is HEARD is the part above
## about 180 Hz, weighted by the ear (A-weighting). This prints, for every hit sound, that "heard" spectral centroid and the
## share of the heard energy in five bands over its first 64 ms, and fails if a hit is brighter than the limits below (set
## from the reworked recipes with a little room, so a later recipe that drifts back toward tin is caught). From the repo root:
##   godot --headless --path . --script res://audio/tools/tone_check.gd
## Exit code 1 if a hit is too bright. No sound device is used.

const N: int = 2048
const HP_HZ: float = 180.0                                       # a small speaker's low cut
const BANDS: Array = [250.0, 1000.0, 2000.0, 4000.0]           # edges: under 250, 250-1k, 1-2k, 2-4k, over 4k
## id: [max heard centroid Hz, max heard share over 2 kHz (0-1)]. Set from the reworked recipes with a little room.
const LIMITS: Dictionary = {
	"impact.light": [560.0, 0.06],
	"impact.light.lite": [520.0, 0.06],
	"impact.medium": [650.0, 0.07],
	"impact.medium.grind": [650.0, 0.07],
	"impact.heavy": [850.0, 0.11],
	"impact.guard": [750.0, 0.10],
	"impact.double": [800.0, 0.09],
	"impact.absorbed": [700.0, 0.06],
	"impact.whiff": [1900.0, 0.30],
	"energy.bolt": [1450.0, 0.24],
	"energy.blast": [1400.0, 0.22],
	"ui.launcher": [900.0, 0.03],
	"tug.pulse": [350.0, 0.03],
	"tug.surge": [450.0, 0.03],
	"tug.lock": [900.0, 0.07],
	"tug.fall": [400.0, 0.02],
	"drone.bed.lo": [260.0, 0.01],
	"drone.bed.hi": [400.0, 0.01],
}
var fails: int = 0


func _initialize() -> void:
	_run.call_deferred()


## In-place iterative radix-2 FFT of (re, im), length a power of two.
static func fft(re: PackedFloat32Array, im: PackedFloat32Array) -> void:
	var n: int = re.size()
	var j: int = 0
	for i in range(1, n):
		var bit: int = n >> 1
		while j & bit:
			j ^= bit
			bit >>= 1
		j ^= bit
		if i < j:
			var tr: float = re[i]
			re[i] = re[j]
			re[j] = tr
			var ti: float = im[i]
			im[i] = im[j]
			im[j] = ti
	var length: int = 2
	while length <= n:
		var ang: float = -TAU / float(length)
		var wr: float = cos(ang)
		var wi: float = sin(ang)
		var i: int = 0
		while i < n:
			var cr: float = 1.0
			var ci: float = 0.0
			for k in range(length >> 1):
				var a: int = i + k
				var b: int = a + (length >> 1)
				var xr: float = re[b] * cr - im[b] * ci
				var xi: float = re[b] * ci + im[b] * cr
				re[b] = re[a] - xr
				im[b] = im[a] - xi
				re[a] += xr
				im[a] += xi
				var ncr: float = cr * wr - ci * wi
				ci = cr * wi + ci * wr
				cr = ncr
			i += length
		length <<= 1


## The ear's weight for a power at f: A-weighting (IEC 61672) times a 2nd-order low cut at a small speaker's corner.
static func heard(f: float) -> float:
	var f2: float = f * f
	var ra: float = (12194.0 * 12194.0 * f2 * f2) / ((f2 + 20.6 * 20.6) * sqrt((f2 + 107.7 * 107.7) * (f2 + 737.9 * 737.9)) * (f2 + 12194.0 * 12194.0))
	var r: float = pow(f / HP_HZ, 4.0)
	return ra * ra * (r / (1.0 + r))


## [centroid Hz, shares of the five bands], heard (see above), from the first N samples (Hann window), averaged over the variants.
func spectrum(bank: AudioBank, id: String) -> Array:
	var rate: int = bank.rate_of(id)
	var cen: float = 0.0
	var share: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
	var nv: int = bank.variants(id)
	for v in range(nv):
		var buf: PackedFloat32Array = bank.buffer(id, v)
		var re := PackedFloat32Array()
		var im := PackedFloat32Array()
		re.resize(N)
		im.resize(N)
		for i in range(mini(N, buf.size())):
			re[i] = buf[i] * (0.5 - 0.5 * cos(TAU * float(i) / float(N - 1)))
		fft(re, im)
		var tot: float = 0.0
		var wsum: float = 0.0
		var b: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
		for k in range(1, N >> 1):
			var f: float = float(k) * float(rate) / float(N)
			var p: float = (re[k] * re[k] + im[k] * im[k]) * heard(f)
			tot += p
			wsum += p * f
			var bi: int = 0
			while bi < BANDS.size() and f >= BANDS[bi]:
				bi += 1
			b[bi] += p
		cen += wsum / maxf(tot, 1e-12)
		for i in range(5):
			share[i] += b[i] / maxf(tot, 1e-12)
	for i in range(5):
		share[i] /= float(nv)
	return [cen / float(nv), share]


func _run() -> void:
	var bank := AudioBank.new()
	print("%-22s %9s   %s" % ["sound", "heard", "centroid and share of the heard energy: under 250 | 250-1k | 1-2k | 2-4k | over 4k  (first 64 ms)"])
	var ids: Array = ["impact.light", "impact.light.lite", "impact.medium", "impact.medium.grind", "impact.heavy", "impact.guard", "impact.double", "impact.absorbed", "impact.whiff", "energy.bolt", "energy.blast", "charge.tick.heavy", "charge.tick.light", "charge.hum", "perfect.tok", "ui.launcher", "tug.pulse", "tug.surge", "tug.lock", "tug.fall", "drone.bed.lo", "drone.bed.hi"]
	for id in ids:
		if not bank.has_sound(id):
			continue
		var r: Array = spectrum(bank, id)
		var s: Array = r[1]
		print("%-22s %7.0f Hz   %5.1f | %5.1f | %5.1f | %5.1f | %5.1f" % [id, r[0], s[0] * 100.0, s[1] * 100.0, s[2] * 100.0, s[3] * 100.0, s[4] * 100.0])
		if LIMITS.has(id):
			var over2k: float = s[3] + s[4]
			var lim: Array = LIMITS[id]
			var good: bool = r[0] <= float(lim[0]) and over2k <= float(lim[1])
			if not good:
				fails += 1
				print("  FAIL  %s: centroid %.0f Hz (limit %.0f), %.1f%% over 2 kHz (limit %.0f%%)" % [id, r[0], float(lim[0]), over2k * 100.0, float(lim[1]) * 100.0])
	print("\ntone check %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)
