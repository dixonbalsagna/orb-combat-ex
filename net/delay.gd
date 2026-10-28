class_name NetDelay
extends RefCounted
## Adaptive input delay (docs/net/rollback.md section 9): the delay a match starts with, from the measured round trip
## and the device's speed. A pure function of its arguments: no clock, no state, so both peers (or a test) get the same
## answer from the same numbers. Each peer chooses for itself; a session takes the larger of the two in the handshake.
##
## The rule. More delay means fewer predicted ticks and shorter rollbacks, but a later response to the stick. So the
## delay is the smallest one whose worst usual rollback frame still fits the device's frame budget:
##   - the link: a high percentile of the round-trip samples (`pct`, 75 by default: the usual bad case, so that one
##     spike does not set the delay). The one-way time is half. A rollback reaches back about (one-way ticks - delay)
##     ticks;
##   - the device: the ms a sim tick, a snapshot take and a restore cost on it. A rollback frame of depth D costs
##     restore + (D + 1) x (tick + save): every re-simulated tick is still a prediction, so it saves, and the new tick
##     saves too;
##   - the budget: `share` of a 60 Hz frame (75% by default: the rest is drawing and the host).
## Against the bench (rollback.md section 5) the rule keeps the tested default of 2 ticks on a desktop up to a 120 ms
## ping, and on a device four times slower asks for about the one-way time, which the bench says it needs.
## The delay never goes below `minDelay` (2 ticks: the project's tested default) and never above `maxDelay` (8 ticks,
## 133 ms, past which the stick feels late), nor above the delay that removes rollback entirely on that link. If even
## that does not fit, the answer is the most it may be, with fits = false: the host should warn, or refuse ranked play.

const FRAME_MS: float = 1000.0 / 60.0
## The reference device: the cloud container's Xeon at 2.1 GHz (docs/net/rollback.md section 5), mean costs in ms.
const REF_TICK: float = 0.60
const REF_SAVE: float = 1.57
const REF_RESTORE: float = 2.45
const DEFAULTS: Dictionary = {"minDelay": 2, "maxDelay": 8, "share": 0.75, "pct": 75.0, "noSamples": 2}


## The device's costs for a speed factor: 1 is the reference, 4 a device four times slower (a phone, an old laptop).
static func device(slowdown: float) -> Dictionary:
	var k: float = maxf(0.25, slowdown) if is_finite(slowdown) else 1.0
	return {"tick": REF_TICK * k, "save": REF_SAVE * k, "restore": REF_RESTORE * k}


## The delay for round-trip samples in ms (any order; negative, NaN and infinite ones are ignored) on a device
## ({tick, save, restore} in ms, as device() gives). opts overrides DEFAULTS. Returns {delay, fits, depth (the usual
## worst rollback, ticks), frameMs (its cost), medianMs, highMs, reason}.
static func choose(rttMs: Array, dev: Dictionary, opts: Dictionary = {}) -> Dictionary:
	var o: Dictionary = DEFAULTS.duplicate()
	o.merge(opts, true)
	var lo: int = maxi(1, int(o.minDelay))
	var hi: int = maxi(lo, int(o.maxDelay))
	var xs: Array = []
	for v in rttMs:
		if (v is float or v is int) and is_finite(float(v)) and float(v) >= 0.0:
			xs.append(float(v))
	if xs.is_empty():
		return {"delay": clampi(int(o.noSamples), lo, hi), "fits": true, "depth": -1, "frameMs": 0.0, "medianMs": -1.0, "highMs": -1.0, "reason": "no samples"}
	xs.sort()
	var med: float = _pct(xs, 50.0)
	var high: float = _pct(xs, float(o.pct))
	var tick: float = float(dev.get("tick", REF_TICK))
	var save: float = float(dev.get("save", REF_SAVE))
	var restore: float = float(dev.get("restore", REF_RESTORE))
	var budget: float = FRAME_MS * float(o.share)
	var oneWayTicks: int = int(ceil(high * 0.5 / FRAME_MS))
	var none: int = clampi(oneWayTicks, lo, hi)   # the delay at which nothing is predicted on this link
	for d in range(lo, none + 1):
		var depth: int = maxi(0, oneWayTicks - d)
		var cost: float = 0.0 if depth == 0 else restore + float(depth + 1) * (tick + save)
		if cost <= budget:
			return {"delay": d, "fits": true, "depth": depth, "frameMs": cost, "medianMs": med, "highMs": high,
				"reason": "smallest delay whose rollback frame fits %.1f ms" % budget}
	var dMax: int = none
	var depthMax: int = maxi(0, oneWayTicks - dMax)
	return {"delay": dMax, "fits": false, "depth": depthMax, "frameMs": restore + float(depthMax + 1) * (tick + save) if depthMax > 0 else 0.0,
		"medianMs": med, "highMs": high, "reason": "no delay up to %d fits %.1f ms" % [hi, budget]}


## The p-th percentile of sorted values, nearest rank.
static func _pct(sorted: Array, p: float) -> float:
	var i: int = clampi(int(ceil(p / 100.0 * float(sorted.size()))) - 1, 0, sorted.size() - 1)
	return sorted[i]
