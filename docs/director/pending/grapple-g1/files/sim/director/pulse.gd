class_name DirPulse
## One rule for every timed contest (docs/director/grapple-director.md section 1; Game Design's rule-of-cool.md
## section 2): a pulse every `every` ticks from t0, `n` of them at most. A press inside `window` ticks of a pulse claims
## it, and is sharp inside `sharp`. Anything else is a stray. The callers keep who claimed what, and what a stray voids.
## Pure functions of ticks: no state, no draws.


## The pulse a press at tick p falls in (1 to n), or 0 when it is inside no pulse's window.
static func of(t0: int, every: int, n: int, window: int, p: int) -> int:
	if every <= 0:
		return 0
	var k: int = int(floor((float(p - t0) + float(every) * 0.5) / float(every)))   # the nearest pulse
	if k < 1 or k > n:
		return 0
	return k if absi(p - (t0 + k * every)) <= window else 0


## How far off pulse k a press at tick p is, in ticks.
static func off(t0: int, every: int, k: int, p: int) -> int:
	return absi(p - (t0 + k * every))


## The tick after pulse k's window: from then on, it can be judged.
static func closes(t0: int, every: int, k: int, window: int) -> int:
	return t0 + k * every + window + 1
