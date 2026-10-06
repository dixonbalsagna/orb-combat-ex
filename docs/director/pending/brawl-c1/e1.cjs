// e1.cjs <brawl.gd>: C1's header, state slots and the event helper. Each edit must match exactly once. On HEAD's brawl.gd.
const fs = require('fs');
const p = process.argv[2];
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
function rep(a, b) {
  const n = t.split(a).length - 1;
  if (n !== 1) throw new Error('expected 1 match, got ' + n + ' for: ' + a.slice(0, 70));
  t = t.replace(a, () => b);
}
const L = (...lines) => lines.join('\n') + '\n';

// the header: the trade's rule and the control slice
rep(L(
  "##    staggered fighter adds nothing to the run. A trade (both landing inside the lapse) cannot pass tradeMaxTicks:",
  "##    at the limit it breaks for a lead of more than levelWithin, and a level trade is a seeded draw in which the",
  "##    last closer of this brawl has `momentum` (section 9d); that fighter's next landed blow is the close."),
L(
  "##    staggered fighter adds nothing to the run. A trade (both landing inside the lapse) that reaches tradeMaxTicks",
  "##    breaks for a lead of more than levelWithin, then or on the tick one appears, and that fighter's next landed",
  "##    blow is the close. A trade still level at doubleTicks is the double hit: both land, both are thrown back, and",
  "##    nobody wins (docs/design/brawl-second-pass.md section 7).",
  "##  - Control (slice C1, brawl-second-pass.md section 1): the pair has a centre, and both sticks move it, each at",
  "##    nudgeMul of his free-flight speed. The speed the brawl began with carries on for carryTicks. A building's face",
  "##    stops it and it slides along. Both sticks held away for partTicks is the walk-out."));
rep("## (B3); struggles (B4); the stick's damped walk. Flow is neither earned nor lost by a press inside a brawl until B2.",
    "## (B3); struggles (B4). Flow is neither earned nor lost by a press inside a brawl until B2.");

// the last closer's slot becomes the double hit's
{
  const m = t.match(/^const LAST_CLOSER: int = BASE \+ 32[^\n]*\n/m);
  if (!m) throw new Error('LAST_CLOSER line not found');
  t = t.replace(m[0], () => "const DBL_AT: int = BASE + 32   # on the exchange's attacker, for both: the live tick the double hit's two blows land; 0 none\n");
}
rep("const AI_RIP: int = BASE + 36    # the AI: 1 while it has its riposte to throw\nconst END: int = BASE + 37\n",
  L(
  "const AI_RIP: int = BASE + 36    # the AI: 1 while it has its riposte to throw",
  "const NUDGE_X: int = BASE + 37   # his stick's nudge after Controls' ramp, in 1/127 units, by axis (SimAim.nudge_ramp keeps it)",
  "const NUDGE_Y: int = BASE + 38",
  "const CEN_VX: int = BASE + 39    # on the exchange's attacker, for both: the centre's velocity from the two sticks, in sixteenths of a unit a second",
  "const CEN_VY: int = BASE + 40",
  "const CARRY_X: int = BASE + 41   # ... the speed the brawl began with, in the same units",
  "const CARRY_Y: int = BASE + 42",
  "const CARRY_N: int = BASE + 43   # ... and the live ticks of it left",
  "const PART_N: int = BASE + 44    # ... the live ticks running for which both have held away (the walk-out)",
  "const DBL_N: int = BASE + 45     # ... how many of the double hit's two blows have landed",
  "const AI_NUDGE: int = BASE + 46  # the AI: the nudge it holds: 0 none, 1 toward the rival, 2 away from him, 3 the +x way, 4 the -x way",
  "const AI_PART: int = BASE + 47   # the AI: S.tick until which it holds away to walk out; -1: it weighed a walk-out in this brawl and stays; 0: not weighed yet",
  "const MOVE_X: int = BASE + 48    # on the exchange's attacker, for both: the velocity the pair was given this tick, in sixteenths of a unit a second",
  "const MOVE_Y: int = BASE + 49",
  "const END: int = BASE + 50"));

// the event helper carries the cell (UI reads a press_ack's source)
rep("static func _ev(S: SimState, f, name: String, text: String = \"\"):\n\tSimFx.cue(S, f, name, text, \"\")\n",
    "static func _ev(S: SimState, f, name: String, text: String = \"\", source: String = \"\"):\n\tSimFx.cue(S, f, name, text, source)\n");
rep("## An event for QA, Animation and VFX with no line in the core: a cue named `name`. The caller sets its other fields.",
    "## An event for QA, Animation and VFX with no line in the core: a cue named `name`. The caller sets its other fields.\n## source: for a press_ack, the button's cell (x, y, a or b), which the HUD marks.");
fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log('e1 ok');
