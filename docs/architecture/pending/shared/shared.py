# PARKED BUILD (Simulation): Encounter's three asks of 2026-10-22 (the EP's brief), all neutral: no golden moves.
#   (b) the launch curve as shared functions (docs/director/camera-intent.md section 3): SimFlight.share, kOf, the Track
#       on plain numbers stepped by tick() to the bit as the live flight, and predict() to its touchdown; the live step
#       now calls the same functions (pace, toContact). Only read with the curve's switch on.
#   (a) SimBrake.controlBack: a public name for the brake's control back (Encounter's recoil, contact off).
#   (c) a cue of kind cam_intent is left out of hashFx (the light digest), so switching the camera feed on moves no
#       digest: the feed is the view's, read-only (Encounter's camintent.gd draws nothing and writes nothing hashed).
#   edits sim/core/flight.gd, brake.gd, hash.gd, tools/parity.gd (one check), docs/architecture/fx-events.md
# Usage: python shared.py <repo root>
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
def src(name):
    return open(os.path.join(HERE, 'src', name), encoding='utf-8').read()

p = 'sim/core/flight.gd'
s = open(p, encoding='utf-8').read()
assert 'static func kOf(' not in s, 'already in'
# the level function becomes share, level, kOf, the Track, track, tick and predict
i = s.index("## The share of the peak he shows now: the curve, or the arrival's ramp once it has started.\nstatic func level(p) -> float:")
j = s.index("## Each live tick of a launched fighter while the curve is on")
s = s[:i] + src('flight_shared.gd.txt') + s[j:]
# toContact becomes toFloor on plain numbers, with toContact its fighter's call
i = s.index("## Live ticks until his course meets the ground, the water or the building he is aimed at, at the speed he shows:")
j = s.index("static func _floor(S: SimState, x: float) -> float:")
s = s[:i] + src('tofloor.gd.txt') + "\n\n" + s[j:]
open(p, 'w', encoding='utf-8', newline='\n').write(s)
edit(p, [
("\tvar v: float = SimDetMath.hypot(f.vx, f.vy)\n\tp.k = SimMathx.jclamp(c * p.peak / v, kMin, kMax) if v > 0.0 else kMax\n",
 "\tp.k = kOf(c, p.peak, f.vx, f.vy)\n"),
("## The flight cue (SimFx.flight) tells the camera each phase: kick, glide, arrive and end.\n",
 "## The flight cue (SimFx.flight) tells the camera each phase: kick, glide, arrive and end.\n"
 "## The predictors fly the same curve (Encounter's planner, World's flightTo, chainPlan and next): share, kOf, toFloor and\n"
 "## a Track stepped by tick() are the step's own arithmetic on plain numbers, and predict() runs one to its touchdown.\n"),
])

edit('sim/core/brake.gd', [
("## Control back in the air: his flight ends where he is, with his own speed (the traversal factor divided out of it).\n",
 "## The brake's control back, for the director (Encounter's recoil flip with ground contact off): his flight ends where\n"
 "## he is, with his own speed, as the brake ends it.\n"
 "static func controlBack(S: SimState, f) -> void:\n"
 "\t_control(S, f)\n"
 "\n\n"
 "## Control back in the air: his flight ends where he is, with his own speed (the traversal factor divided out of it).\n"),
])

edit('sim/core/hash.gd', [
("static func hashFx(h: Hasher, events: Array) -> void:\n\tfor e in events:\n",
 "static func hashFx(h: Hasher, events: Array) -> void:\n\tfor e in events:\n"
 "\t\tif e.type == \"cue\" and e.kind == \"cam_intent\":\n"
 "\t\t\tcontinue   # the camera feed (Encounter's camintent.gd): a plan for the view, read-only, outside the light digest\n"),
])

edit('docs/architecture/fx-events.md', [
("| `cue` | actor, kind, text, source | a render-only cue from Combat's templates and finishers (the `cue` op, S3b; no state change, no draw): ",
 "| `cue` | actor, kind, text, source | a render-only cue from Combat's templates and finishers (the `cue` op, S3b; no state change, no draw; a cue of kind `cam_intent`, the camera feed, is left out of the light digest): "),
])

p = 'sim/core/tools/parity.gd'
edit(p, [
("\tcheck(\"hit-stop by weight\", _hitstop())\n",
 "\tcheck(\"hit-stop by weight\", _hitstop())\n"
 "\tcheck(\"the curve's shared functions, the brake's control back, the camera feed\", _shared())\n"),
])
s = open(p, encoding='utf-8').read()
assert s.endswith('\n') and '_shared() -> String' not in s
s += src('shared_check.gd')
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("the curve's shared functions, SimBrake.controlBack, and the camera feed out of the light digest")
