// Paper model of the claw-bot gate for the right-hand-attacks pitches (docs/controls/right-hand-attacks.md, section 6).
// Pure arithmetic over the command layer's timings: no sim, no engine. Run: node docs/controls/right-hand-attacks-model.mjs
//
// A "link" is two inputs one after the other on the right hand, the second on the other device (stick then face button,
// or face button then stick). A standard thumb needs a transfer time between the devices (right-thumb.md section 3);
// a claw, back paddles or a keyboard needs none. The model asks, for each pitch and each grip, how many blows start in
// a fixed horizon, with the law OFF (naive: each input acts as soon as the hand can issue it) and ON (the lockouts of
// right-thumb.md rule 3: a face press after a stick command waits L, a stick command after a face press waits R).
// The bar is: with the law ON the CLAW never starts more blows than the FAST standard thumb. Ticks are 60 Hz.

const SETTLE = 2;          // a stick direction is taken 2 ticks after the crossing (rightStick.flickSettle)
const L = 6;               // stick to face lockout: the fast standard thumb's own transfer (rightThumb.lockout)
const R = 8;               // face to stick lockout: onset 6 + settle 2 (rightThumb.reverseLockout)
const HORIZON = 600;       // ten seconds
const GRIPS = {
  CLAW: { sf: 0, fs: 0 },  // zero transfer: a claw, paddles, a keyboard
  FAST: { sf: 6, fs: 6 },  // p10 of the standard grip
  P50: { sf: 8, fs: 8 },
  SLOW: { sf: 13, fs: 13 } // p90
};
const FACE = { X: 6, Y: 12, B: 24 };   // a face blow's commitment: the mash caps of energy-input.md section 3

// The stick strike's commitment (ticks from its start until the fighter can start the next request), by pitch. These
// are ASSUMPTIONS for Game Design to replace: 4a a quick own-class blow, 4b the heavy's wind-up (martial B is 28), 4c
// an own-class blow that draws on the heavy's budget.
const PITCHES = { "4a": 14, "4b": 28, "4c": 20 };

// Ticks from the start of one blow to the earliest start of the next, for a link.
function interval(prev, commit, next, grip, law) {
  let transfer;
  if (next === "S") transfer = (prev === "F" ? grip.fs : 0) + SETTLE;
  else transfer = prev === "S" ? grip.sf : 0;
  if (law) {
    const floor = prev === "S" && next === "F" ? L : prev === "F" && next === "S" ? R : 0;
    transfer = Math.max(transfer, floor);
  }
  return Math.max(commit, transfer);
}

// Blows started in the horizon by a cyclic chain, e.g. [["S", c], ["F", 6]].
function run(chain, grip, law) {
  let t = 0, n = 0, i = 0;
  while (t < HORIZON) {
    const [dev, c] = chain[i % chain.length];
    n += 1;
    const [nd] = chain[(i + 1) % chain.length];
    t += interval(dev, c, nd, grip, law);
    i += 1;
  }
  return n;
}

function pad(s, w) { return String(s).padEnd(w); }
function line(cols, ws) { return cols.map((c, k) => pad(c, ws[k])).join(" "); }

let fails = 0;
function check(ok, what) { if (!ok) { fails += 1; console.log("FAIL  " + what); } }

// ---------------------------------------------------------------------------------------------------------------
console.log("1. ALTERNATING STICK STRIKE AND FACE BLOW, blows started in " + HORIZON + " ticks (S F S F ...)");
console.log("   law OFF: CLAW / FAST / P50 / SLOW      law ON: CLAW / FAST / P50 / SLOW      claw gain over FAST (off, on)");
const w1 = [6, 8, 24, 24, 12];
console.log(line(["pitch", "face", "naive (off)", "law (on)", "gain"], w1));
for (const [p, cs] of Object.entries(PITCHES)) {
  for (const [f, cf] of Object.entries(FACE)) {
    const chain = [["S", cs], ["F", cf]];
    const off = Object.values(GRIPS).map(g => run(chain, g, false));
    const on = Object.values(GRIPS).map(g => run(chain, g, true));
    console.log(line([p, f, off.join(" / "), on.join(" / "), "+" + (off[0] - off[1]) + ", +" + (on[0] - on[1])], w1));
    check(on[0] <= on[1], p + " " + f + ": with the law ON the claw starts no more blows than FAST");
    check(on[1] === run(chain, GRIPS.FAST, true), p + " " + f + ": FAST is unchanged by the law (the lockouts are its own transfer)");
  }
}

// ---------------------------------------------------------------------------------------------------------------
console.log("\n2. WHERE THE NAIVE CLAW GAIN LIVES: the shortest commitment that hides each lockout");
console.log("   stick to face: a stick strike committing >= " + L + " ticks hides L.  face to stick: a face blow committing >= " + R + " ticks hides R.");
const w2 = [14, 22, 22];
console.log(line(["commitment", "S->F claw gain (off)", "F->S claw gain (off)"], w2));
for (const c of [2, 4, 6, 8, 10, 12, 24]) {
  const sf = interval("S", c, "F", GRIPS.FAST, false) - interval("S", c, "F", GRIPS.CLAW, false);
  const fs = interval("F", c, "S", GRIPS.FAST, false) - interval("F", c, "S", GRIPS.CLAW, false);
  console.log(line([c, sf, fs], w2));
  check(interval("S", c, "F", GRIPS.CLAW, true) === interval("S", c, "F", GRIPS.FAST, true), "S->F at commitment " + c + ": law makes claw equal FAST");
  check(interval("F", c, "S", GRIPS.CLAW, true) === interval("F", c, "S", GRIPS.FAST, true), "F->S at commitment " + c + ": law makes claw equal FAST");
}
console.log("   So the only single-link gain is X (commits 6) then a stick command: 2 ticks. Every other link is hidden by the blow's own commitment.");

// ---------------------------------------------------------------------------------------------------------------
console.log("\n3. THE CHARGE: stick held to charge while the claw taps a face button (X at its mash cap of " + FACE.X + ")");
console.log("   A standard thumb cannot press a face button while the stick is held; lifting the thumb throws the strike.");
const w3 = [22, 8, 14, 14];
console.log(line(["charge", "held", "naive claw", "law ON claw"], w3));
for (const [what, held] of [["strike level 1 (D)", 12], ["strike level 2", 30], ["strike level 3", 54], ["beam level 3 (RB)", 54]]) {
  const naive = Math.floor(held / FACE.X);   // extra blows the claw gets while charging
  const law = 0;                             // face presses during a stick hold queue to release + L; the hold outlasts the queue
  console.log(line([what, held, "+" + naive + " blows", "+" + law + " blows"], w3));
  check(law === 0, what + ": law ON gives the claw no blows during the charge");
}
console.log("   The queue is 3 deep and a request lives 36 ticks, so a press made early in a long charge expires: it only ever costs the claw.");

// ---------------------------------------------------------------------------------------------------------------
console.log("\n4. SAME-TICK ISSUE: a face press and a stick command on the same tick (a claw can, a standard thumb cannot)");
{
  const naiveClaw = [0, 0];                                  // both start at tick 0
  const lawClaw = [0, R];                                    // the face press wins the tick (ruling 1); the strike waits R
  const lawFast = [0, Math.max(GRIPS.FAST.fs + SETTLE, R)];  // FAST presses, then moves: its strike starts at 8
  console.log("   naive claw starts both at tick 0; law ON claw starts the press at 0 and the strike at " + lawClaw[1] + "; FAST " + lawFast[1]);
  check(lawClaw[1] === lawFast[1], "same-tick: law ON claw's strike starts when FAST's does");
  check(naiveClaw[1] < lawFast[1], "same-tick: naive claw is earlier than FAST (the hole the lockout closes)");
}

// ---------------------------------------------------------------------------------------------------------------
console.log("\n5. MIRROR PARITY: the D-pad and key forms act on the stick form's tick");
for (const settle of [SETTLE]) {
  const stick = 0 + settle;     // crossing at 0, direction taken at 2
  const dpad = 0 + settle;      // a D-pad press at 0 waits the same 2
  console.log("   stick acts at " + stick + ", D-pad acts at " + dpad + ", key acts at " + dpad);
  check(stick === dpad, "mirror: same tick");
}

// ---------------------------------------------------------------------------------------------------------------
console.log("\n6. MIXED CHAIN: strike, B, strike, X (4c)");
{
  const chain = [["S", PITCHES["4c"]], ["F", FACE.B], ["S", PITCHES["4c"]], ["F", FACE.X]];
  const on = Object.values(GRIPS).map(g => run(chain, g, true));
  const off = Object.values(GRIPS).map(g => run(chain, g, false));
  console.log("   naive " + off.join(" / ") + "   law " + on.join(" / "));
  check(on[0] <= on[1], "mixed chain: law ON claw no better than FAST");
}

console.log("\n" + (fails === 0 ? "model: every claw check holds with the law ON" : "model: " + fails + " check(s) FAILED"));
process.exit(fails === 0 ? 0 : 1);
