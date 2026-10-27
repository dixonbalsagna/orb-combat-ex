class_name AudioSlice
extends RefCounted
## Time-slicing for the audio bank's warm-up (docs/audio/warm-async.md). The synths' long loops are written as coroutines that call
## due() now and then and, when the frame's budget is spent, `await next_frame()`. With `on` false (every ordinary call, headless, the tools,
## a sound played un-warmed) due() is always false, so a coroutine never suspends and the sync wrappers (ImpactSynth.render and the others)
## give the same answer as ever, bit for bit. The warm-up driver (AudioBank) sets `on` while it runs.

static var on: bool = false           # slicing active: a warm-up is running across frames
static var budget_us: int = 6000      # microseconds of synthesis a frame may take (a knob: the warm-up takes about 1.8 s of CPU on a desktop)
static var max_slice_us: int = 0      # the longest single run between two yields seen (for the checks and the probe)
static var yields: int = 0
static var _t0: int = 0


static func due() -> bool:
	return on and Time.get_ticks_usec() - _t0 > budget_us


static func start_frame() -> void:
	_t0 = Time.get_ticks_usec()


## Give the frame back; continue in the next one with a fresh budget.
static func next_frame() -> void:
	max_slice_us = maxi(max_slice_us, Time.get_ticks_usec() - _t0)
	yields += 1
	await Engine.get_main_loop().process_frame
	_t0 = Time.get_ticks_usec()


## Run a coroutine to the end as an ordinary call: slicing is switched off for it, so it never suspends (and any slicing run that is
## suspended elsewhere is untouched and resumes with `on` as it was).
static func run_sync(c: Callable, args: Array):
	var keep: bool = on
	on = false
	var r = c.callv(args)
	on = keep
	return r
