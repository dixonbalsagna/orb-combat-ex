// Builds research/rule-of-cool/feel.html: the two best pitches (pitches.md) on proto v2's planet, one file, for a real pad.
//   node research/rule-of-cool/build.mjs
// It reads research/ring-any-angle/page2.html and changes named lines, so proto v2 stays as it is. A line that has moved stops the build, rather than dropping a feature silently.
import { readFileSync, writeFileSync } from 'node:fs';
const A = 'research/ring-any-angle/', D = 'research/rule-of-cool/';
let s = readFileSync(A + 'page2.html', 'utf8');
function rep(a, b) { const n = s.split(a).length - 1; if (n !== 1) throw new Error('match ' + n + ': ' + a.slice(0, 90)); s = s.split(a).join(b); }

rep('<title>Turntable arena</title>', '<title>Arena Feel Test</title>');
const p0 = s.indexOf('<p><b>The turntable arena</b>'), p1 = s.indexOf('</p>', p0); if (p0 < 0 || p1 < 0) throw new Error('intro');
s = s.slice(0, p0) + '<p><b>Arena feel test</b> (Research; paper: <code>research/rule-of-cool/pitches.md</code>). Plug in a pad and press any button so the browser sees it. <b>Left stick and either trigger: fly flat out.</b> Flip the stick at full speed to turn. <b>View button: the low line, on and off. Menu button: the kick and the coin turn, on and off.</b> On a keyboard: A and D, Shift, then Z and X. RB and Y together, or M, is the meteor. Fly it both ways: the top speed is the same 10,240 in both, and the numbers are in the corner. Sliders below.' + s.slice(p1);

// The switches and their first values
rep("var P = { tier: 5,", "var P = { low: 1, lowAlt: 140, lowWidth: 5200, lowFov: 26, lowLead: 18, kick: 1, kickTop: 1.35, turn: 1, tier: 5,");
rep("['#', 'Flee with a nudge (N toggles)'],", "['#', 'One: the low line (View button or Z)'], ['low', 'Flat out, hug the land', 'c'], ['lowAlt', 'Height over the land', 60, 420, 10], ['lowWidth', 'Width of view, flat out', 2700, 16000, 100], ['lowFov', 'Lens when flat out, degrees (15 is today)', 15, 50, 1], ['lowLead', 'Look ahead, % of the view', 0, 35, 1],\n  ['#', 'Two: the kick and the coin turn (Menu button or X)'], ['kick', 'Kick out of a standing start', 'c'], ['kickTop', 'Kick, share of top speed', 1, 1.8, 0.05], ['turn', 'Coin turn on a stick flip', 'c'],\n  ['#', 'Flee with a nudge (N toggles)'],");

// The pad: either trigger is flat out, as the layout has it; View and Menu switch the two pitches, so Orb can compare without letting go
rep("o.fly = o.fly || bt(7);", "o.fly = o.fly || bt(7) || bt(6); o.togLow = bt(8); o.togKick = bt(9); padG = g;");
rep("o.form = o.form || bt(6);", "");
rep("var inp = { x: 0,", "var padG = null; function rumble(st, wk, ms) { try { if (padG && padG.vibrationActuator) padG.vibrationActuator.playEffect('dual-rumble', { duration: ms, strongMagnitude: st, weakMagnitude: wk }); } catch (e) { } }\nvar inp = { x: 0,");
rep("if (e.code === 'KeyN') {", "if (e.code === 'KeyZ') { SETTERS.low(P.low ? 0 : 1); return; } if (e.code === 'KeyX') { var kk = P.kick ? 0 : 1; SETTERS.kick(kk); SETTERS.turn(kk); return; } if (e.code === 'KeyN') {");
rep("  if (pr('meteor') && !S.met && !S.send && !S.stop) startMeteor(i);", "  if (pr('togLow')) SETTERS.low(P.low ? 0 : 1); if (pr('togKick')) { var k2 = P.kick ? 0 : 1; SETTERS.kick(k2); SETTERS.turn(k2); }\n  if (pr('meteor') && !S.met && !S.send && !S.stop) startMeteor(i);");

// Two: the flight's law. Today it's one lag toward the stick. The kick leaves at once, over top speed, and eases to it; a stick flip plants, then kicks the other way
rep("    S.v += (tv - S.v) * (i.fly ? 0.16 : 0.22); S.airL = S.airR = Math.abs(S.v) > 2500;", `    var flying2 = i.fly && Math.abs(i.x) > 0.5, sg = i.x > 0 ? 1 : -1; if (S.kickK === undefined) S.kickK = -1;
    if (P.turn && !S.coin && flying2 && i.x * S.v < 0 && Math.abs(S.v) > 0.5 * flat) { S.coin = { k: 0, to: sg }; S.kickK = -1; S.hopK = 0; }
    if (S.coin) { var cn = S.coin; cn.k++; if (cn.k <= 5) S.v *= 0.55; else S.v = 0; if (cn.k === 6) { rumble(1, 0.6, 140); spawnDebris(norm(lineDir(0, S.t)), 240, 0.35); } if (cn.k >= 8) { S.coin = null; S.kickK = 0; rumble(0.5, 0.9, 110); } }
    else if (P.kick && S.kickK < 0 && flying2 && (!prev.fly || !prev.xOn) && Math.abs(S.v) < 0.5 * flat) { S.kickK = 0; rumble(0.5, 0.9, 110); }
    if (!S.coin) { var mult = 1, gain = i.fly ? 0.16 : 0.22; if (S.kickK >= 0) { if (!flying2) S.kickK = -1; else { S.kickK++; var kt = S.kickK, top = P.kickTop; mult = kt < 8 ? top : top + (1 - top) * sstep((kt - 8) / 28); gain = kt < 4 ? 0.55 : 0.3; if (kt >= 36) S.kickK = -1; } } S.v += (tv * mult - S.v) * gain; }
    i.xOn = Math.abs(i.x) > 0.5; S.airL = S.airR = Math.abs(S.v) > 2500;`);

// One: the low line. A height that looks ahead along his line, so he's over a ridge as it arrives, and falls away slowly behind it
rep("  S.altL += ((S.airL ? 420 : 0) - S.altL) * 0.08; S.altR += ((S.airR ? 420 : 0) - S.altR) * 0.08; S.alt = Math.max(S.altL, S.altR); S.ga = ga; S.gb = gb; S.gm = Math.max(ga, gb); S.y += ((Math.max(g0, S.gm) + S.alt) - S.y) * 0.12;", `  var fastN = Math.abs(S.v) / Math.max(1, FLAT * P.speed / 100), lowK = P.low ? Math.max(0, Math.min(1, (fastN - 0.35) / 0.4)) : 0; S.lowK = (S.lowK || 0) + (lowK - (S.lowK || 0)) * 0.1;
  var dirV = S.v > 0 ? 1 : -1, ahead = 0; for (var la = 0; la <= 2; la++) ahead = Math.max(ahead, Math.max(0, heightAt(lineDir(dirV * Math.abs(S.v) * la * 0.07, S.t), 2)));
  if (S.hugY === undefined) S.hugY = Math.max(ga, gb) + 420; var hugTo = Math.max(ahead, S.gm || 0) + P.lowAlt; S.hugY += (hugTo - S.hugY) * (hugTo > S.hugY ? 0.35 : 0.12);
  if (S.hopK !== undefined && S.hopK < 18) S.hopK++; var hop = S.hopK !== undefined && S.hopK < 18 ? 240 * Math.sin(Math.PI * S.hopK / 18) : 0;
  var airH = 420 + (Math.max(0, S.hugY - Math.max(ga, gb)) - 420) * S.lowK; S.altL += ((S.airL ? airH : 0) - S.altL) * (S.lowK > 0.5 ? 0.3 : 0.08); S.altR += ((S.airR ? airH : 0) - S.altR) * (S.lowK > 0.5 ? 0.3 : 0.08); S.alt = Math.max(S.altL, S.altR) + hop; S.altL += hop * 0.06; S.altR += hop * 0.06; S.ga = ga; S.gb = gb; S.gm = Math.max(ga, gb); S.y += ((Math.max(g0, S.gm) + S.alt) - S.y) * 0.12;
  T_FOV = Math.tan((15 + (P.lowFov - 15) * S.lowK) * RAD); S.lead = (S.lead || 0) + ((P.low ? dirV * Math.min(1, fastN) * P.lowLead / 100 * S.wid : 0) - (S.lead || 0)) * 0.06;`);
rep("var fast = Math.abs(S.v) > 2500, tw = P.width * (fast ? P.wide : 1) + S.gap * 1.3,", "var fast = Math.abs(S.v) > 2500, tw = (fast ? P.width * P.wide + (P.lowWidth - P.width * P.wide) * (S.lowK || 0) : P.width) + S.gap * 1.3,");
// the meteor keeps its own lens
rep("  var m = S.met; m.k++;\n", "  var m = S.met; m.k++; T_FOV = Math.tan(15 * RAD); S.lead = 0; S.lowK = 0;\n");
// the view looks ahead of him
rep("cam = [0, ty + dist * Math.sin(pit), dist * Math.cos(pit)], view = look(cam, [0, ty, 0], [0, 1, 0]),", "cam = [S.lead || 0, ty + dist * Math.sin(pit), dist * Math.cos(pit)], view = look(cam, [S.lead || 0, ty, 0], [0, 1, 0]),");
// the burn stays a thread up close, and comes to a point at his back rather than a square end
rep("var coreW = 86 * wAge * Math.max(air, 0.15) * Math.max(heat, 0.3) * Math.max(cool, 0.3), corePx = coreW * pp, px = heat * cool < 0.02 ? 0 : Math.max(L[0] * corePx, L[1]) * (o.knot ? 1.5 : 1);", "var coreW = 86 * (1 - 0.72 * (S.lowK || 0)) * wAge * Math.max(air, 0.15) * Math.max(heat, 0.3) * Math.max(cool, 0.3), corePx = coreW * pp, px = heat * cool < 0.02 ? 0 : Math.max(L[0] * corePx, L[1]) * (o.knot ? 1.5 : 1) * Math.min(1, 0.1 + e / 0.25);");
// what it does, in numbers
rep("(function () { var N = S.nudge; if (!P.nudge && !N.total)", "'<br><b>one: low line ' + (P.low ? 'ON' : 'off') + ', two: kick and turn ' + (P.kick || P.turn ? 'ON' : 'off') + '</b> (View, Menu; or Z, X)<br>the land under him crosses ' + (Math.abs(S.v) / S.wid).toFixed(2) + ' views a second, ' + Math.round(S.alt) + ' u up' + (function () { var N = S.nudge; if (!P.nudge && !N.total)");

if (!s.includes('/*BUNDLE*/')) throw new Error('no slot');
s = s.replace('/*BUNDLE*/', () => "var GEN2PACK = '" + readFileSync(A + 'gen2-p7.pack').toString('base64') + "';");
writeFileSync(D + 'feel.html', s);
console.log(D + 'feel.html built, ' + Math.round(s.length / 1024) + ' KB');
