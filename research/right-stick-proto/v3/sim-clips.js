
// ---- clips: each a list of takes; a stick gesture is [from, to, screen degrees, magnitude, sweep, rise], a button [side, key,
// from, to, value]; the left stick takes the same gestures as the right ----
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
function cat() { var o = []; for (var i = 0; i < arguments.length; i++) o = o.concat(arguments[i]); return o; }
function inputOf(stickR, buttons, stickL, seed) { return function (w) { var b = ev(buttons, 'P', w.t), s = stickAt(stickR, w.t, seed), l = stickAt(stickL || [], w.t, seed + 3); b.rx = s[0]; b.ry = s[1]; b.lx = l[0]; b.ly = l[1]; return { P: b, V: ev(buttons, 'V', w.t) }; }; }
function take(len, pitch, setup, stickR, buttons, stickL) { return { len: len, pitch: pitch, setup: setup, input: inputOf(stickR, buttons, stickL, 7) }; }
function takeSplit(len, pitch, setup, A, B, extra) { var o = { len: len, pitch: pitch, setup: setup, split: true, input: inputOf(A[0], A[1], A[2], 7), input2: inputOf(B[0], B[1], B[2], 11) }; for (var k in extra) o[k] = extra[k]; return o; }
function at(px, py, vx, vy) { return function (w) { w.P.x = px; w.P.y = py; w.V.x = vx; w.V.y = vy; }; }
var CLIPS = [];

// L1: LT plus a left flick slips that way; LT alone is the plain dodge (pitch section 3)
function slipTake(h, lAng) { return take(100, '4c', at(340, 0, 382, 0), [], cat([['V', 'blow', 34, 35, h]], [['P', 'LT', lAng == null ? 40 : 36, lAng == null ? 43 : 46]]), lAng == null ? [] : [[38, 41, lAng, 1, 0, 1]]); }
CLIPS.push({ n: 'L1', name: 'LT and a flick: the slips', takes: [slipTake('mid', null), slipTake('mid', 180), slipTake('mid', 0), slipTake('low', 90), slipTake('high', 270)],
  steps: [[0, 'The left hand survives. LT alone, the stick at rest, is the plain dodge: his blow goes by.', 46],
    [100, 'LT with a left flick slips that way. Away: a back-step off the line.', 146],
    [200, 'Toward: a slip in, past his fist and inside his arm, where a counter is ready.', 246],
    [300, 'Up: a sway over a low blow.', 346],
    [400, 'Down: a duck under a high blow. No right-hand input is ever part of a defence.', 446]] });
// L2: LB alone guards; LB plus a left flick braces for his next move (v2's read, now on the left thumb)
function braceTake(len, px, vx, lAng, his) { return take(len, '4c', at(px, 0, vx, 0), [], cat([['P', 'LB', 28, 36]], [['V', his, 50, 51]]), [[30, 33, lAng, 1, 0, 1]]); }
CLIPS.push({ n: 'L2', name: 'LB: the guard and the braces', takes: [take(110, '4c', at(340, 0, 382, 0), [], cat([['P', 'LB', 30, 100]], [['V', 'blow', 40, 41, 'mid'], ['V', 'heavy', 64, 65]])),
    braceTake(110, 340, 382, 90, 'heavy'), braceTake(100, 340, 382, 270, 'flurry'), braceTake(100, 300, 460, 0, 'grab'), braceTake(130, 180, 600, 180, 'fire')],
  steps: [[0, 'LB held is the guard: his blow and his heavy are taken on the arms.', 92],
    [110, 'LB with a left flick braces for his next move (3 ki, 90 ticks), and it shows in the stance. Up braces for his heavy: he winds it, you slip under, he is open.', 192],
    [220, 'Down braces for his flurry, crouched: the first blow is ducked and his run is broken.', 273],
    [320, 'Toward braces for his grab, hands wide: the loop breaks as it closes.', 396],
    [420, 'Away braces for his shot, side-on: a sidestep.', 531]] });
// L3: LB and LT with a left flick: the vanish, a blink in that way for 12 ki
function vanishTake(len, py, lAng, extraR, extraB) { return take(len, '4a', at(340, py, 382, py), extraR || [], cat([['V', 'heavy', 30, 31]], [['P', 'LB', 44, 52], ['P', 'LT', 44, 52]], extraB || []), [[46, 49, lAng, 1, 0, 1]]); }
CLIPS.push({ n: 'L3', name: 'LB, LT and a flick: the vanish', takes: [vanishTake(100, 0, 180), vanishTake(110, 0, 0, [[64, 67, 180, 1, 0, 1]]), vanishTake(100, 0, 90), vanishTake(100, 100, 270)],
  steps: [[0, 'Both left shoulders and a flick: the vanish, a blink that way for 12 ki. Away is the escape: his heavy finds nothing.', 52],
    [100, 'Toward blinks through to his back, and the right stick strikes him from behind.', 172],
    [210, 'Up blinks over him.', 263],
    [310, 'Down blinks under. It replaces the old escape button.', 363]] });
// R1: the right stick hurts: a flick strikes that way, and held through the wind-up it charges (pitch 4a)
function strikeTake(len, setup, stick) { return take(len, '4a', setup, stick, []); }
CLIPS.push({ n: 'R1', name: 'The stick strikes', takes: [strikeTake(110, at(200, 0, 420, 0), [[30, 33, 0, 1, 0, 1]]), strikeTake(100, at(340, 0, 382, 0), [[30, 33, 90, 1, 0, 1]]),
    strikeTake(110, at(340, 70, 382, 70), [[30, 33, 270, 1, 0, 1]]), strikeTake(110, at(340, 0, 382, 0), [[30, 33, 180, 1, 0, 1]]), strikeTake(150, at(340, 0, 382, 0), [[30, 90, 0, 1, 0, 1]])],
  steps: [[0, 'The right hand hurts. A flick toward him from range: the rush closes the gap, then a body blow that stuns him.', 66],
    [110, 'A flick up: a rising strike that launches him.', 150],
    [210, 'A flick down on him in the air: a spike into the ground (on the ground it is a sweep).', 262],
    [320, 'A flick away: a turning blow that knocks him off.', 360],
    [430, 'Held through the wind-up, it charges, a level each 22 ticks. Let go to throw it: level 3 here.', 526]] });
// R2: RB held: the stick is the beam, the buttons are blasts
CLIPS.push({ n: 'R2', name: 'The energy stick (RB)', takes: [take(100, '4a', at(200, 40, 480, 40), [[30, 33, 0, 1, 0, 1]], [['P', 'RB', 20, 70]]),
    take(100, '4a', at(200, 40, 470, 160), [[30, 33, 22.5, 1, 0, 1]], [['P', 'RB', 20, 70]]),
    take(150, '4a', at(200, 40, 520, 40), [[30, 120, 12, 1, -24, 1]], [['P', 'RB', 20, 130]]),
    take(120, '4a', at(200, 40, 520, 40), [], cat([['P', 'RB', 20, 100]], taps('P', 'X', [30]), taps('P', 'Y', [50]), taps('P', 'B', [72])))],
  steps: [[0, 'Held, RB makes the right stick the beam. A flick toward him: a snap-beam.', 48],
    [100, 'The beam goes where the stick points: a flick up and right.', 148],
    [200, 'Held, the beam channels: it stays out, follows the stick at his sweep rate and grows a level every 24 ticks, for ki. Let go and it ends.', 296],
    [350, 'With RB, the face buttons are the blasts: X a bolt, Y a lob, B a blast.', 432]] });
// P1: one input, three pitches: a stick strike toward him, B, then a stick strike up
function pitchTake(pitch) { return take(130, pitch, at(330, 0, 375, 0), [[30, 33, 0, 1, 0, 1], [70, 73, 90, 1, 0, 1]], taps('P', 'B', [46])); }
CLIPS.push({ n: 'P1', name: 'The three pitches', takes: [pitchTake('4a'), pitchTake('4b'), pitchTake('4c'),
    take(100, '4c', at(200, 40, 480, 40), [[30, 33, 0, 1, 0, 1]], [['P', 'RT', 24, 60]]), take(100, '4a', at(200, 40, 480, 40), [[30, 33, 0, 1, 0, 1]], cat([['P', 'RT', 24, 60]], taps('P', 'B', [40])))],
  steps: [[0, 'One input, three pitches: a stick strike toward him, B, then a stick strike up. 4a, strikes are their own class: quick, they stun, and B follows freely.', 60],
    [130, '4b, the stick is the heavy: the same slow wind-up as B and no stun. The two share one pace, so each waits for the other.', 178],
    [260, '4c, the big move of the mode: a quick strike that stuns but is costed like the heavy (6 ki, the heavy\'s pace), so B must wait.', 326],
    [390, '4c puts the signature on RT and the stick, aimed where the stick points (45 ki).', 432],
    [490, '4a and 4b keep it on RT and B, aimed at him.', 540]] });
// C1: the claw against one thumb, on one clock: no tick gained on a stick-to-button link
CLIPS.push({ n: 'C1', name: 'The claw, side by side', takes: [
    takeSplit(110, '4a', at(330, 0, 375, 0), [[[30, 33, 0, 1, 0, 1]], taps('P', 'X', [32])], [[[30, 33, 0, 1, 0, 1]], taps('P', 'X', [38])], { labels: ['CLAW: X ON THE STRIKE\'S TICK', 'ONE THUMB: X 6 TICKS LATER'], tl0: 30, key: 'P', nth: 1, keyText: 'THE X STARTS ON +', slow: 2 }),
    takeSplit(100, '4a', at(200, 40, 480, 40), [[[30, 33, 0, 1, 0, 1]], cat([['P', 'RB', 20, 80]], taps('P', 'X', [30]))], [[[36, 39, 0, 1, 0, 1]], cat([['P', 'RB', 20, 80]], taps('P', 'X', [30]))], { labels: ['CLAW: BOLT AND FLICK AT ONCE', 'ONE THUMB: FLICK 6 LATER'], tl0: 30, key: 'F', keyText: 'THE BEAM STARTS ON +', slow: 2 }),
    takeSplit(100, '4a', at(330, 0, 375, 0), [[[30, 33, 0, 1, 0, 1]], taps('P', 'X', [30])], [[[36, 39, 0, 1, 0, 1]], taps('P', 'X', [30])], { labels: ['CLAW: X AND FLICK AT ONCE', 'ONE THUMB: FLICK 6 LATER'], tl0: 30, key: 'F', keyText: 'THE STRIKE STARTS ON +', slow: 2 })],
  steps: [[0, 'The claw against one thumb, on one clock. A stick strike, then X: the claw presses on the strike\'s own tick, one thumb 6 ticks later, and X starts on the same tick in both.', 58],
    [110, 'RB held: a bolt, then a flick for the beam. The claw flicks on the press\'s own tick and waits 8 ticks (the thumb\'s 6 to the stick, the flick\'s 2 to settle), the same tick as one thumb\'s flick.', 160],
    [210, 'X, then a stick strike: the strike waits for the light blow and the 8 ticks, the same in both lanes. No grip is ever faster.', 262]] });

function clipLen(c) { return c.takes.reduce(function (a, t) { return a + t.len; }, 0); }
function newRun(ci, mode, pitch) {
  if (mode === 'play') { var w = newWorld(null, 0, 'play', false, pitch); w.P.x = 260; w.V.x = 460; return { clip: null, w: w, t: 0, take: 0, off: 0 }; }
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
return { W: W, H: H, CLIPS: CLIPS, LAW: LAW, PITCH: PITCH, RS: RS, newRun: newRun, stepRun: stepRun, draw: function (run, R) { if (run.w2) drawSplit(run, R); else draw(run.w, R); }, stepOf: stepOf, clipLen: clipLen };
})();
// ==== PAGE (DOM) ====
