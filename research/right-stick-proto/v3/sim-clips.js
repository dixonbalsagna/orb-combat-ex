
// ---- clips: each a list of takes; a stick gesture is [from, to, screen degrees, magnitude, sweep, rise] (it crosses on at
// `from` with a 1-tick rise and is back under off at `to`), a button [side, key, from, to, value]; the left stick takes the
// same gestures as the right; the Rival's orders are buttons on side V ----
function stickAt(list, t, seed) {
  for (var i = 0; i < list.length; i++) {
    var e = list[i]; if (t < e[0] || t >= e[1] + 2) continue;
    var kin = Math.min(1, (t - e[0] + 1) / (e[5] || 2)), kout = t >= e[1] ? Math.max(0, 1 - (t - e[1] + 1) / 2) : 1, m = (e[3] || 1) * Math.min(kin, kout);
    var a = e[2], span = e[4] || 0; if (span) a += span * clamp((t - e[0]) / Math.max(1, e[1] - e[0]), 0, 1);
    a = deg(a + (hash(t * 31 + seed) - 0.5) * 4); m = Math.min(1, m * (0.98 + hash(t * 17 + seed) * 0.04));
    return [Math.cos(a) * m, -Math.sin(a) * m];
  }
  return [0, 0];
}
function ev(list, side, t) { var o = {}; for (var i = 0; i < list.length; i++) { var e = list[i]; if (e[0] === side && t >= e[2] && t < e[3]) o[e[1]] = e.length > 4 ? e[4] : true; } return o; }
function taps(side, b, at) { return at.map(function (t) { return [side, b, t, t + 3]; }); }
function hold(side, b, from, to) { return [[side, b, from, to]]; }
function cat() { var o = []; for (var i = 0; i < arguments.length; i++) o = o.concat(arguments[i]); return o; }
function fl(t, ang, len) { return [t, t + (len || 3), ang, 1, 0, 1]; }
function inputOf(stickR, buttons, stickL, seed) { return function (w) { var b = ev(buttons, 'P', w.t), s = stickAt(stickR, w.t, seed), l = stickAt(stickL || [], w.t, seed + 3); b.rx = s[0]; b.ry = s[1]; b.lx = l[0]; b.ly = l[1]; return { P: b, V: ev(buttons, 'V', w.t) }; }; }
function take(len, pitch, setup, stickR, buttons, stickL) { return { len: len, pitch: pitch, setup: setup, input: inputOf(stickR, buttons, stickL, 7) }; }
function takeSplit(len, pitch, setup, A, B, extra) { var o = { len: len, pitch: pitch, setup: setup, split: true, input: inputOf(A[0], A[1], A[2], 7), input2: inputOf(B[0], B[1], B[2], 11) }; for (var k in extra) o[k] = extra[k]; return o; }
function at(px, py, vx, vy) { return function (w) { w.P.x = px; w.P.y = py; w.V.x = vx; w.V.y = vy; }; }
var CLIPS = [];
var CLOSE = at(340, 0, 382, 0);

// L1: the dodge starts on LT's press; a left flick in the next 6 ticks makes it a slip that way (Controls section 2)
function slipTake(h, lAng, ltAt) { var lt = ltAt || 38; return take(90, '4c', CLOSE, [], cat([['V', 'blow', 34, 35, h]], hold('P', 'LT', lt, lt + 8)), lAng == null ? [] : [fl(lt + 1, lAng)]); }
CLIPS.push({ n: 'L1', name: 'LT and a flick: the slips', takes: [slipTake('mid', null), slipTake('mid', 180), slipTake('mid', 0), slipTake('low', 90), slipTake('high', 270),
    take(130, '4c', CLOSE, [], cat([['V', 'blow', 24, 25, 'high'], ['V', 'blow', 64, 65, 'high'], ['V', 'blow', 104, 105, 'high']], hold('P', 'LT', 28, 34), hold('P', 'LT', 68, 74), hold('P', 'LT', 108, 114)), [fl(29, 270), fl(69, 270), fl(109, 270)])],
  steps: [[0, 'The left hand survives. LT starts the dodge on its own press tick; with the left stick at rest it is the plain dodge, and his blow goes by.', 48],
    [90, 'A left flick inside the next 6 ticks makes it a slip that way. Away: a back-step off the line.', 140],
    [180, 'Toward: a slip in, past his fist and inside his arm.', 230],
    [270, 'Up: a sway over a low blow.', 320],
    [360, 'Down: a duck under a high blow.', 410],
    [450, 'The third slip of one direction inside 3 seconds keeps its movement but loses its frames: the third duck is hit. No right-hand input is ever part of a defence.', 568]] });
// L2: LB alone guards; LB and a quick left flick from rest set a brace on the flick's return (v2's read, on the left thumb)
function braceTake(len, px, vx, lAng, his, hisAt) { return take(len, '4c', at(px, 0, vx, 0), [], cat(hold('P', 'LB', 26, 60), [['V', his, hisAt || 50, (hisAt || 50) + 1]]), [fl(30, lAng)]); }
CLIPS.push({ n: 'L2', name: 'LB: the guard and the braces', takes: [take(110, '4c', CLOSE, [], cat(hold('P', 'LB', 30, 104), [['V', 'blow', 36, 37, 'mid'], ['V', 'heavy', 60, 61]])),
    take(120, '4c', CLOSE, [fl(86, 0)], cat(hold('P', 'LB', 26, 60), [['V', 'heavy', 50, 51]]), [fl(30, 90)]),
    braceTake(100, 340, 382, 270, 'flurry'), braceTake(100, 300, 460, 0, 'grab'), braceTake(120, 180, 600, 180, 'fire'),
    take(110, '4c', at(360, 0, 420, 0), [], cat(hold('P', 'LB', 20, 104), [['V', 'jab', 66, 67], ['V', 'gx', 30, 90, 330]]), [[30, 80, 180, 1, 0, 8]])],
  steps: [[0, 'LB held is the guard: his blow is taken on the arms. His heavy breaks a set guard, which is what the brace is for.', 50],
    [110, 'LB and a quick left flick from rest set a brace on the flick\'s return (3 ki, 90 ticks), shown in the stance. Up braces for his heavy: he winds it, you slip under, he is open, and a quick strike stuns him.', 208],
    [230, 'Down braces for his flurry, crouched: the first blow is ducked and his run is broken.', 290],
    [330, 'Toward braces for his grab, hands wide: the loop breaks as it closes.', 408],
    [430, 'Away braces for his shot, side-on: a sidestep.', 520],
    [550, 'A slow lean with LB held is walking guarded, never a brace: the guard stays up and takes his light.', 628]] });
// L3: LB and LT within 6 ticks, either order, then a direction: the dodge upgraded to the vanish at its tick 6
function vanishTake(len, py, lAng, extraR, extraB, his) { return take(len, '4c', at(340, py, 382, py), extraR || [], cat(his || [['V', 'heavy', 30, 31]], hold('P', 'LB', 44, 54), hold('P', 'LT', 44, 54), extraB || []), lAng == null ? [] : [fl(45, lAng)]); }
CLIPS.push({ n: 'L3', name: 'LB and LT together: the vanish', takes: [vanishTake(90, 0, 180), vanishTake(100, 0, 0, [fl(54, 180)], [], [['V', 'blow', 40, 41, 'mid']]), vanishTake(90, 0, 90), vanishTake(90, 100, 270),
    take(100, '4c', CLOSE, [], cat(hold('P', 'LB', 20, 70), hold('P', 'LT', 50, 58), [['V', 'blow', 46, 47, 'mid']]), [fl(51, 180)]),
    take(120, '4c', at(300, 0, 420, 0), [], cat(hold('P', 'LB', 30, 40), hold('P', 'LT', 32, 40), hold('P', 'LT', 80, 88), hold('P', 'LB', 81, 88)), [fl(33, 180), fl(82, 0)])],
  steps: [[0, 'LB and LT within 6 ticks, either order, and a direction: the dodge starts on LT\'s press, and at its tick 6 it becomes the vanish, an instant cut with sharp after-images (20 ki). Away is the escape: his heavy finds nothing.', 52],
    [90, 'Toward blinks through to his back. His blow in flight whiffs and leaves him open, and a quick strike stuns him while he is open.', 152],
    [190, 'Up blinks over him.', 243],
    [280, 'Down blinks under him. The vanish replaces the old escape button.', 333],
    [370, 'LB held longer than 6 ticks, then LT: not the chord, but the plain dodge out of guard (here a back-step).', 428],
    [470, 'Each further vanish inside 3 seconds costs 1.5 times as much: 20 ki, then 30. A soft cost, never a cooldown.', 560]] });
// R1: the right stick hurts (4c, GD's split): a quick strike stuns; held past D it is the charged heavy, aimed by the stick
function strikeTake(len, setup, stick, his) { return take(len, '4c', setup, stick, his || []); }
CLIPS.push({ n: 'R1', name: 'The stick strikes (4c)', takes: [strikeTake(90, at(200, 0, 420, 0), [fl(30, 0)]), strikeTake(80, CLOSE, [fl(30, 90)]),
    strikeTake(90, at(340, 70, 382, 70), [fl(30, 270)]), strikeTake(80, CLOSE, [fl(30, 180)]),
    strikeTake(150, CLOSE, [fl(30, 0, 80)], [['V', 'jab', 50, 51]]),
    strikeTake(160, CLOSE, [fl(30, 0), fl(70, 0), fl(110, 0)]), strikeTake(80, CLOSE, [fl(30, 0)], [['V', 'jab', 36, 37]])],
  steps: [[0, 'The right hand hurts. A quick flick toward him (back before tick 12): the quick strike, its own class. From range the lunge closes the gap, then a body blow that stuns him for 20 ticks.', 62],
    [90, 'A flick up: a rising blow. It stuns; it never hands over a launch.', 136],
    [170, 'A flick down on him in the air: a spike into the ground (on the ground it is a low sweep).', 222],
    [260, 'A flick away: a wide turning blow that pushes him a step off.', 306],
    [340, 'Held past tick 12 it is the charged heavy, aimed by the stick: armoured, so his light does half damage and nothing more; level 3 flashes at tick 50; let go and it drives him back.', 458],
    [490, 'The third quick strike of one direction inside 3 seconds still hits but doesn\'t stun.', 616],
    [650, 'The quick strike is bare to lights: his light ends it in its wind-up. That is its price for the stun.', 692]] });
// R2: RB held: the stick is the beam; the face buttons are the blasts, always at him
CLIPS.push({ n: 'R2', name: 'The energy stick (RB)', takes: [take(80, '4c', at(200, 40, 480, 40), [fl(30, 0)], hold('P', 'RB', 20, 70)),
    take(170, '4c', at(200, 40, 520, 40), [fl(30, 0, 70), [108, 160, 40, 1, 0, 1]], hold('P', 'RB', 20, 165)),
    take(120, '4c', at(200, 40, 480, 40), [fl(30, 90, 40)], hold('P', 'RB', 20, 115)),
    take(170, '4c', at(200, 40, 480, 40), [], cat(hold('P', 'RB', 20, 165), taps('P', 'X', [30]), taps('P', 'Y', [44]), taps('P', 'B', [62]), hold('P', 'B', 100, 150))),
    take(150, '4c', at(420, 40, 640, 40), [fl(70, 0, 40)], cat(hold('P', 'LT', 20, 140), hold('P', 'RB', 20, 140), taps('P', 'X', [40, 52])), [[22, 140, 180, 1, 0, 1]])],
  steps: [[0, 'Held, RB makes the right stick the beam. A quick flick toward him: the snap-beam, with the heavy blast\'s wind-up and ki.', 54],
    [80, 'Held past tick 12 the beam charges, a level at 12, 30 and 54. Let go and it fires along the aim latched at the settle, here at him; while it is out the stick steers it.', 196],
    [250, 'The aim is latched four ways at the settle: up fires 45 degrees above him.', 330],
    [370, 'With RB the face buttons are the blasts, always at him: X a bolt, Y a lob, B the heavy blast; B held, a bigger blast in two levels.', 522],
    [540, 'The kite: LT held sprints and RB keeps it, so blasts fire on the move; a charged beam may be built while sprinting, but its release plants him.', 664]] });
// P1: one input, three pitches: a quick strike toward him, then held toward, through his light, and let go
function pitchTake(pitch) { return take(170, pitch, CLOSE, [fl(30, 0), fl(80, 0, 70)], [['V', 'jab', 100, 101]]); }
CLIPS.push({ n: 'P1', name: 'The three pitches', takes: [pitchTake('4c'), pitchTake('4a'), pitchTake('4b'),
    take(140, '4c', at(200, 40, 480, 40), [fl(30, 0), fl(60, 0, 60)], hold('P', 'RT', 20, 130)),
    take(100, '4a', at(200, 40, 480, 40), [fl(30, 0)], cat(hold('P', 'RT', 20, 80), taps('P', 'B', [50])))],
  steps: [[0, '4c, GD\'s split by gesture (the default): the quick strike is its own class (wind-up 12, stuns); held, it is the charged heavy, armoured, so his light changes nothing; levels at 12, 30, 50.', 140],
    [170, 'Pure 4a: its own class all the way: a quicker strike (wind-up 10) and its own ladder (12, 30, 54). This placeholder ladder has no armour, so his light ends the charge.', 272],
    [340, '4b: the stick is B with a direction: B\'s 28-tick wind-up, no stun; held, B held\'s charge.', 482],
    [510, '4c puts the signature on RT and the stick, hold and release only: a graze fires nothing and costs nothing; the hold aims it; the release fires it (45 ki).', 636],
    [650, '4a and 4b keep it on RT and B, at him; RT and the stick do nothing there.', 706]] });
// C1: the claw against one thumb, on one clock (Controls section 6): no tick gained on any link
CLIPS.push({ n: 'C1', name: 'The claw, side by side', takes: [
    takeSplit(90, '4c', CLOSE, [[fl(30, 0)], taps('P', 'X', [33])], [[fl(30, 0)], taps('P', 'X', [39])], { labels: ['CLAW: X A TICK AFTER THE STRIKE', 'ONE THUMB: X 6 AFTER LETTING GO'], tl0: 30, key: 'P', nth: 1, keyText: 'THE X STARTS ON +', slow: 2 }),
    takeSplit(80, '4c', CLOSE, [[fl(30, 0)], taps('P', 'X', [30])], [[fl(36, 0)], taps('P', 'X', [30])], { labels: ['CLAW: X AND THE STICK AT ONCE', 'ONE THUMB: THE STICK 6 LATER'], tl0: 30, key: 'F', keyText: 'THE STRIKE STARTS ON +', slow: 2 }),
    takeSplit(140, '4c', CLOSE, [[fl(30, 0, 60)], taps('P', 'X', [50, 82])], [[fl(30, 0, 60)], taps('P', 'X', [96])], { labels: ['CLAW: X TWICE DURING THE CHARGE', 'ONE THUMB: X 6 AFTER LETTING GO'], tl0: 30, key: 'P', nth: 1, keyText: 'THE X STARTS ON +', slow: 2 })],
  steps: [[0, 'The claw against one thumb, on one clock. A quick strike, then X: the claw presses a tick after the strike starts, one thumb 6 ticks after letting go, and X starts on the same tick in both (the strike\'s commitment, 16).', 82],
    [90, 'X and the stick together: the press goes first and the strike waits 8 ticks (the thumb\'s 6 to the stick and the 2 of the settle), the tick one thumb\'s strike starts.', 128],
    [170, 'The charge: while the stick is held the face buttons are inert. The claw\'s X counts from the release plus 6 (the first one, pressed too early, lapses), as one thumb\'s press 6 after letting go does; both start on the same tick, 24 after the release (the charged heavy\'s commitment).', 290]] });

function clipLen(c) { return c.takes.reduce(function (a, t) { return a + t.len; }, 0); }
function newRun(ci, mode, pitch, mirror) {
  if (mode === 'play') { var w = newWorld(null, 0, 'play', false, pitch); w.mirror = !!mirror; w.P.x = 260; w.V.x = 460; return { clip: null, w: w, t: 0, take: 0, off: 0 }; }
  var c = CLIPS[ci], T0 = c.takes[0]; return { clip: c, w: newWorld(c, 0, 'demo'), w2: T0.split ? newWorld(c, 0, 'demo', true) : null, t: 0, take: 0, off: 0 };
}
// keys (Play): { lx, ly, rx, ry, LT, LB, RB, RT, X, Y, B, A, du, dd, dl, dr } from the pad or the keyboard
function stepRun(run, keys) {
  var c = run.clip, w = run.w, ip;
  if (c) {
    var T = c.takes[run.take];
    if (w.t >= T.len) { run.off += T.len; run.take++; if (run.take >= c.takes.length) { run.take = 0; run.off = 0; } run.w = w = newWorld(c, run.take, 'demo'); T = c.takes[run.take]; run.w2 = T.split ? newWorld(c, run.take, 'demo', true) : null; }
    ip = T.input(w);
    if (run.w2) stepWorld(run.w2, T.input2(run.w2));
  } else ip = { P: keys || {}, V: {} };
  stepWorld(w, ip);
  run.t = run.off + w.t;
}
function stepOf(c, t) { var k = 0; for (var i = 0; i < c.steps.length; i++) if (t >= c.steps[i][0]) k = i; return k; }
return { W: W, H: H, CLIPS: CLIPS, LAW: LAW, PITCH: PITCH, PITCHES: PITCHES, RS: RS, LEFT: LEFT, CHARGE: CHARGE, EN: EN, BTN: BTN, newRun: newRun, stepRun: stepRun,
  draw: function (run, R) { if (run.w2) drawSplit(run, R); else draw(run.w, R); }, stepOf: stepOf, clipLen: clipLen };
})();
// ==== PAGE (DOM) ====
