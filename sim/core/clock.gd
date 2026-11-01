class_name SimClock
extends RefCounted
## Every hit-stop in the sim goes through here, and says whose it is (docs/design/two-v-two.md: a hit-stop holds only the fighters in that exchange). Today there's one clock, so
## `a` and `b` aren't read: S.dirS.stop holds the whole sim, as ever. With neither, it's everyone's: the KO. SimCore._step runs the clock down, and SimHitstop.frozen rounds it.


## Hold for secs, merged with the stop in force: the longer one holds, they never add. a and b: the fighters it holds.
static func hold(S: SimState, secs: float, _a = null, _b = null) -> void:
	S.dirS.stop = SimMathx.jmax(S.dirS.stop, secs)


## The seconds left of the hold. A view or a planner that asks gets the stop in force.
static func left(S: SimState) -> float:
	return S.dirS.stop
