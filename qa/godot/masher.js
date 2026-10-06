// The scripted masher (docs/design/control-rules.md section 6): a v2 human slot pressing light every 8 ticks against the AI at each level.
// masher.gd plays the matches in one Godot process per level; this turns the wins into band rows. Point estimates only, with the sample size in the note:
// at 40 matches the 95% interval is about 30 points wide (the medium row read 60% at 40 matches and 43% at 200), so the default is 100 and a row near a band edge needs more (--masher=N).
const { spawn } = require('child_process');
const { godot, guard, ROOT } = require('./godot');
const MIRROR_N = parseInt(process.env.QA_MIRROR_N || '200', 10);   // matches a mirror plays (the first-slot row is read on 200)

function runLevel(level, n, base, forms = false, gap = 8) {
  const g = godot();
  if (!g) return Promise.reject(new Error('Godot 4.7 not found'));
  return new Promise((resolve, reject) => {
    const p = guard(spawn(g.exe, ['--headless', '--path', ROOT, '--script', 'res://qa/godot/masher.gd', '--', String(n), String(base), `--level=${level}`, `--forms=${forms ? 1 : 0}`, `--gap=${gap}`], { stdio: ['ignore', 'pipe', 'pipe'] }));
    let out = '';
    p.stdout.on('data', d => { out += d; }); p.stderr.on('data', d => { out += d; });
    p.on('error', reject);
    p.on('close', code => {
      const line = out.split('\n').find(l => l.startsWith('{') && l.includes('"masher"'));
      if (code !== 0 || !line) return reject(new Error('masher.gd failed for ' + level + ' (exit ' + code + ')\n' + out.slice(0, 1200)));
      resolve(JSON.parse(line));
    });
  });
}

// Levels run side by side (three Godot processes).
// The lights-only mirror (Game Design, agency pass 13): two mashers who take their forms play each other; at least 95% of the matches must finish before the cap (two beginners on one button must not sit in a stalemate).
function runMirror(n, base, specA = 'masher:forms=1', specB = null, tag = 'live') {
  const g = godot();
  if (!g) return Promise.reject(new Error('Godot 4.7 not found'));
  return new Promise((resolve, reject) => {
    const p = guard(spawn(g.exe, ['--headless', '--path', ROOT, '--script', 'res://qa/godot/players.gd', '--', String(n), String(base), `--a=${specA}`, `--b=${specB || specA}`], { stdio: ['ignore', 'pipe', 'pipe'] }));
    let out = '';
    p.stdout.on('data', d => { out += d; }); p.stderr.on('data', d => { out += d; });
    p.on('error', reject);
    p.on('close', code => {
      const line = out.split(String.fromCharCode(10)).find(l => l.startsWith('{') && l.includes('"players"'));
      if (code !== 0 || !line) return reject(new Error('players.gd failed for the mirror (exit ' + code + ')' + String.fromCharCode(10) + out.slice(0, 1200)));
      const r = JSON.parse(line);
      resolve({ mirror: true, tag, specA, specB: specB || specA, n: r.n, aWins: r.aWins, bWins: r.bWins, finished: r.aWins + r.bWins, timeouts: r.timeouts, medianSec: r.medianSec, brink: r.brinkToKoMedian, brawl: r.brawl, stats: r.stats });
    });
  });
}

// A pair of scripted players (players.gd specs) against each other: the energy rows of agency pass 16 (a bolt-only player finishes at least 95% against a melee masher and wins 20 to 40% against the medium AI; a blast-heavy script against a rush-heavy one 40 to 60%).
function runPair(tag, a, b, n, base, extra = []) {
  const g = godot();
  if (!g) return Promise.reject(new Error('Godot 4.7 not found'));
  return new Promise((resolve, reject) => {
    const p = guard(spawn(g.exe, ['--headless', '--path', ROOT, '--script', 'res://qa/godot/players.gd', '--', String(n), String(base), `--a=${a}`, `--b=${b}`, ...extra], { stdio: ['ignore', 'pipe', 'pipe'] }));
    let out = '';
    p.stdout.on('data', d => { out += d; }); p.stderr.on('data', d => { out += d; });
    p.on('error', reject);
    p.on('close', code => {
      const line = out.split(String.fromCharCode(10)).find(l => l.startsWith('{') && l.includes('"players"'));
      if (code !== 0 || !line) return reject(new Error('players.gd failed for ' + tag + ' (exit ' + code + ')' + String.fromCharCode(10) + out.slice(0, 1200)));
      const r = JSON.parse(line);
      resolve({ pair: tag, brawl: r.brawl, zips: (r.brawl || {}).zips, zipEnds: (r.brawl || {}).zipEnds, n: r.n, aWins: r.aWins, bWins: r.bWins, timeouts: r.timeouts, medianSec: r.medianSec, strings: r.stats[0].blurStrings, locked: r.stats[0].blurLocked });
    });
  });
}

// At most `k` Godot jobs at once (the standing cap is three): the tasks are thunks, run by k workers, results in order.
async function pool(tasks, k = 3) {
  const out = new Array(tasks.length); let next = 0;
  await Promise.all(Array.from({ length: Math.min(k, tasks.length) }, async () => { while (next < tasks.length) { const i = next++; out[i] = await tasks[i](); } }));
  return out;
}

// Two waves of three processes: the masher who takes forms (the banded rows) and the one who never transforms (INFO), per Encounter's finding in docs/director/masher-probes.md.
async function runMasher({ n = 100, base = 1, levels = ['easy', 'medium', 'hard'], jobs = 3 } = {}) {
  const E = ':energy=1:forms=1:stick=1', R = ':forms=1:stick=1', M = ':forms=1:stick=1', ai = 'ai:level=medium';
  const W = 'masher:forms=1:clock=tick', n1 = Math.min(n, 60), nm = Math.min(n, 100), caps = ['--capsec=150'];
  const Y = W + ':btn=Y:gap=12:tap=4', B = W + ':btn=B:gap=30:tap=4', X6 = W + ':btn=X:gap=6';
  const T = [];   // every Godot job of this stage, in the order the rows read them; pool() runs them `jobs` at a time, results in the same order
  // The masher who takes forms (the banded rows) and the one who never transforms (INFO), per Encounter's finding in docs/director/masher-probes.md.
  for (const l of levels) T.push(() => runLevel(l, n, base, true));
  for (const l of levels) T.push(() => runLevel(l, n, base, false));
  // Game Design's ruling 4 (melee-press-feel.md 9d): the masher taps on S.tick; the banded row is the 8-tick script, 6 and 10 are reported beside it.
  for (const g of [6, 10]) T.push(() => runLevel('medium', n, base, true, g));
  // The lights-only mirror: live ticks (every earlier baseline), S.tick with both on the same ticks, S.tick with the second on a seeded offset, a 6-tick against a 12-tick tapper, and (C1) an 8 against a 10.
  T.push(() => runMirror(MIRROR_N, base));
  T.push(() => runMirror(MIRROR_N, base, 'masher:forms=1:clock=tick', null, 'tick'));
  T.push(() => runMirror(MIRROR_N, base, 'masher:forms=1:clock=tick', 'masher:forms=1:clock=tick:off=7', 'tickoff'));
  T.push(() => runMirror(MIRROR_N, base, 'masher:forms=1:clock=tick:gap=6', 'masher:forms=1:clock=tick:gap=12', 'fast-slow'));
  T.push(() => runMirror(MIRROR_N, base, 'masher:forms=1:clock=tick', 'masher:forms=1:clock=tick:gap=10', 'uneven'));
  T.push(() => runPair('bolt-melee', 'masher:energy=1:forms=1', 'masher:forms=1', Math.min(n, 40), base));
  T.push(() => runPair('bolt-medium', 'masher:energy=1:forms=1', ai, nm, base));
  T.push(() => runPair('blast-rush', 'tapper:idle=14:acc=80:win=4:mix=LLLH' + E, 'tapper:acc=80:win=4:mix=LLH' + R, Math.min(n, 40), base));
  T.push(() => runPair('blast-rush-slow', 'tapper:acc=80:win=4:mix=LLH' + E, 'tapper:acc=80:win=4:mix=LLH' + R, Math.min(n, 40), base));
  T.push(() => runPair('zip-medium', 'zipper:forms=1', ai, nm, base));
  T.push(() => runPair('blast-medium', 'tapper:idle=14:acc=80:win=4:mix=LLLH' + E, ai, nm, base));
  T.push(() => runPair('blast-slow-medium', 'tapper:acc=80:win=4:mix=LLH' + E, ai, nm, base));
  // C1 probes (brawl-plan.md section 9; docs/qa/three-strength-qa-plan.md): two lights mashers, one or both with a stick script. On a build with no C1 every row is PENDING.
  T.push(() => runPair('c1-drift-one', W + ':drift=east', W + ':off=7', n1, base, caps));
  T.push(() => runPair('c1-hold-one', W + ':sthold=east', W + ':off=7', n1, base, caps));
  T.push(() => runPair('c1-drift-ai', W + ':drift=east:dat=24:dlen=60', ai, n1, base, caps));
  T.push(() => runPair('c1-drift-both', W + ':drift=east', W + ':off=7:drift=east', n1, base, caps));
  T.push(() => runPair('c1-walk-both', W + ':walk=1', W + ':off=7:walk=1', n1, base, caps));
  T.push(() => runPair('c1-walk-jab', W + ':walk=1:jab=6', W + ':off=7:walk=1', n1, base, caps));
  T.push(() => runPair('c1-walk-guard', W + ':walk=1:wguard=1', W + ':off=7:walk=1:wguard=1', n1, base, caps));
  T.push(() => runPair('c1-walk-held', W + ':walk=1:wheld=1', W + ':off=7:walk=1', n1, base, caps));
  T.push(() => runPair('c1-walk-one', W + ':walk=1', W + ':off=7', n1, base, caps));
  T.push(() => runPair('zip-turret', 'zipper:forms=1', 'turret:energy=1:forms=1:p=25', nm, base, ['--capsec=300']));
  T.push(() => runPair('zip-hook', 'zipper:forms=1', 'turret:forms=1:hook=1', nm, base, ['--capsec=300']));
  // The double hit: a lights-only presser (stick toward) and a mixing presser against the medium AI (0.5 to 2 a match, at least one in 35 to 65%; brawl-second-pass.md section 7).
  T.push(() => runPair('double-lights', W + ':sthold=toward', ai, nm, base));
  T.push(() => runPair('double-mix', 'mix:forms=1:mix=LLH:gap=8:sthold=toward', ai, nm, base));
  // The three strengths (C2a; Encounter's names, brawl-plan.md section 10): a masher on Y, on B, an alternator, the player who only holds X, the 10-tick tapper with B; then each flurry against the one it beats.
  T.push(() => runPair('str-y', Y, ai, nm, base));
  T.push(() => runPair('str-b', B, ai, nm, base));
  T.push(() => runPair('str-alt', 'mix:forms=1:mix=XYB:gap=12:tap=4', ai, nm, base));
  T.push(() => runPair('str-holdx', 'holder:forms=1:kind=L:hold=60:rest=8', ai, nm, base));
  T.push(() => runPair('str-x10b', 'mix:forms=1:mix=XXB:gap=10:tap=4', ai, nm, base));
  T.push(() => runPair('fl-xy', X6, Y + ':off=7', nm, base));
  T.push(() => runPair('fl-yb', Y, B + ':off=7', nm, base));
  T.push(() => runPair('fl-bx', B, X6 + ':off=7', nm, base));
  // The launcher's route (Orb's test 3): mash X every 8 ticks, a B tap when a launcher_open names him.
  for (const lv of ['easy', 'medium', 'hard']) T.push(() => runPair('route-' + lv, 'route:forms=1:clock=tick:gap=8', 'ai:level=' + lv, nm, base));
  // Giving ground (Orb's test 2): a fighter who presses nothing and takes his stick away from a seeded tick of the rival's wind-up, against a B or Y tapper who does not follow and one who does.
  T.push(() => runPair('give-b-free', 'giver:forms=1', W + ':btn=B:gap=40:tap=4:off=7', n1, base, caps));
  T.push(() => runPair('give-b-follow', 'giver:forms=1', W + ':btn=B:gap=40:tap=4:off=7:follow=1', n1, base, caps));
  T.push(() => runPair('give-y-free', 'giver:forms=1', W + ':btn=Y:gap=24:tap=4:off=7', n1, base, caps));
  T.push(() => runPair('give-y-follow', 'giver:forms=1', W + ':btn=Y:gap=24:tap=4:off=7:follow=1', n1, base, caps));
  // Energy in reach (Orb's test 4): RB held with X (bolts) and with Y (blasts), pressing in reach against the medium AI.
  T.push(() => runPair('energy-x', W + ':energy=1:btn=X:gap=6:sthold=toward', ai, n1, base, caps));
  T.push(() => runPair('energy-y', W + ':energy=1:btn=Y:gap=14:tap=4:sthold=toward', ai, n1, base, caps));
  // The burst against a mash over the same time, against a rival who never moves.
  T.push(() => runPair('burst-dummy', 'holder:forms=0:kind=L:hold=55:rest=2', 'masher:forms=0:gap=100000', Math.min(n, 30), base, ['--capsec=120']));
  T.push(() => runPair('mash-dummy', 'masher:forms=0:btn=X:gap=8', 'masher:forms=0:gap=100000', Math.min(n, 30), base, ['--capsec=120']));
  // Agency pass section 20: how often the perfect blur locks, live against the medium AI. A blind 8-tick masher at most 20% of five-blow strings; a script that presses on every contact at least 80%; metronomes at 10, 12 and 14 ticks.
  T.push(() => runPair('blur-blind', 'masher' + M, ai, n, base));
  T.push(() => runPair('blur-contact', 'tapper:acc=100:win=0:jit=0:mix=L' + M, ai, n, base));
  T.push(() => runPair('blur-m10', 'masher:gap=10' + M, ai, n, base));
  T.push(() => runPair('blur-m12', 'masher:gap=12' + M, ai, n, base));
  T.push(() => runPair('blur-m14', 'masher:gap=14' + M, ai, n, base));
  return pool(T, Math.max(1, jobs));
}

const BANDS = { easy: [0.60, 1, 'at least 60%'], medium: [0.35, 0.50, '35 to 50%'], hard: [0, 0.15, 'at most 15%'] };


// The lights-only mirror's rows (agency pass 13 and 23; melee-press-feel.md sections 3, 9 and 9d), for each variant: 'live' counts live ticks (every earlier baseline), 'tick' counts S.tick
// (the real tap rate; the brawl's flurry counts it), 'fast-slow' is a 6-tick tapper against a 12-tick tapper (reported).
const LATE_OK = 4;   // ticks a trade's break may come after its limit: a hit-stop holds the sim (Encounter measured at most 2)

function mirrorRows(m) {
  const b = m.brawl || {}, sfx = m.tag === 'live' ? '' : '.' + m.tag, lab = m.tag === 'live' ? '' : ` (${m.tag === 'tick' ? 'taps on S.tick, both on the same ticks: the exact tie' : m.tag === 'tickoff' ? 'taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks' : m.tag === 'uneven' ? 'an 8-tick tapper against a 10-tick tapper' : 'a 6-tick tapper against a 12-tick tapper'})`;
  const rows = [];
  const pct = v => (100 * v).toFixed(1) + '%';
  if (m.tag === 'uneven') {
    const dec = m.aWins + m.bWins;
    rows.push({ id: 'masher.uneven.finish', ref: '§6 masher', what: 'An uneven mirror (8 ticks against 10) finishes before the cap' + lab, status: m.finished / m.n >= 0.95 ? 'PASS' : 'FAIL', value: `${pct(m.finished / m.n)} (${m.finished} of ${m.n}; ${m.timeouts} ran to the cap)`, band: 'at least 95%', note: `median ${m.medianSec} s; point estimate` });
    rows.push({ id: 'masher.uneven.faster', ref: '§6 masher', what: 'The faster tapper (8 ticks) wins the uneven mirror' + lab, status: dec ? (m.aWins / dec >= 0.80 ? 'PASS' : 'FAIL') : 'PENDING', value: dec ? `${pct(m.aWins / dec)} (${m.aWins} of ${dec})` : 'no decided match', band: 'at least 80%', note: `${m.n} matches; point estimate` });
    if (m.brink >= 0) rows.push({ id: 'masher.uneven.brink', ref: '§6 masher', what: 'Uneven mirror: brink to KO, median (25 to 50 s)' + lab, status: m.brink >= 25 && m.brink <= 50 ? 'PASS' : 'FAIL', value: m.brink.toFixed(1) + ' s', band: '25 to 50 s', note: `${m.finished} matches that ended in a KO` });
    return rows;
  }
  if (m.tag === 'fast-slow') {
    const [a, c] = m.stats, dec = m.aWins + m.bWins;
    rows.push({ id: 'masher.fastslow', ref: '§9d', what: 'A faster masher against a slower one (6 ticks against 12): closes a minute, and who wins (reported, as the cost of tapping slowly)', status: 'INFO', value: `closes a minute: ${a.closesPerMin} for the 6-tick tapper, ${c.closesPerMin} for the 12-tick tapper; the 6-tick tapper wins ${m.aWins} of ${dec}`, band: 'reported', note: `${m.n} matches; closes are flurry staggers; the clock is S.tick` });
    return rows;
  }
  rows.push({ id: 'masher.mirror' + sfx, ref: '§6 masher', what: 'Two lights-only players (mashers who take their forms) finish the match before the cap' + lab, status: m.finished / m.n >= 0.95 ? 'PASS' : 'FAIL', value: `${pct(m.finished / m.n)} (${m.finished} of ${m.n}; ${m.timeouts} ran to the cap)`, band: 'at least 95%', note: `median ${m.medianSec} s; point estimate` });
  if (m.brink >= 0) rows.push({ id: 'masher.brink' + sfx, ref: '§6 masher', what: 'Lights-only mirror: brink to KO, median (25 to 50 s, re-based at melee-press-feel 9e)' + lab, status: m.brink >= 25 && m.brink <= 50 ? 'PASS' : 'FAIL', value: m.brink.toFixed(1) + ' s', band: '25 to 50 s', note: `${m.finished} matches that ended in a KO; the overall band stays 45 to 90 s` });
  if (b.closes !== undefined) {
    const one = b.closesWhileOneOnBrink || 0;
    rows.push({ id: 'masher.brinkcloses' + sfx, ref: '§9e', what: 'Lights-only mirror: share of closes made by the fighter on the brink, while only one of them is on it (reported, not banded: melee-press-feel 9e)' + lab, status: 'INFO', value: one ? `${pct(b.brinkCloseShare)} (${b.closesByBrinkFighter} of ${one} closes)` : 'no close with one fighter on the brink', band: 'reported', note: `${b.closes} closes in ${m.n} matches` });
    const dec = b.decided || 0, seq = b.firstSlotSeq || [];
    const part = (a, z) => { const x = seq.slice(a, z).filter(v => v >= 0); return x.length ? `${(100 * x.filter(v => v === 1).length / x.length).toFixed(0)}% of ${x.length}` : '-'; };
    rows.push({ id: 'masher.firstslot' + sfx, ref: '§9e', what: 'Lights-only mirror: matches won from the first slot (40 to 60%, read on 200 matches)' + lab, status: m.tag === 'tick' ? 'INFO' : (dec >= 100 ? (b.firstSlotShare >= 0.40 && b.firstSlotShare <= 0.60 ? 'PASS' : 'FAIL') : 'PENDING'), value: dec ? `${pct(b.firstSlotShare)} (${b.firstSlotWins} of ${dec}); first 60 seeds ${part(0, 60)}, the next 140 ${part(60, 200)}` : 'no decided match', band: m.tag === 'tick' ? 'reported (the exact tie; the banded row is the offset mirror)' : '40 to 60%', note: `point estimate; the interval at ${dec} matches is about +-${dec ? Math.round(98 / Math.sqrt(dec)) : '-'} points; the split is Encounter's (35% on the first 60 seeds, 67% on the other 140): a slot effect that moves with the seed range is the thing to look at; PENDING under 100 decided matches` });
    // The level trade's seeded draw and its momentum are gone (C1: a break is always for a lead, and a trade still level at 240 ticks ends in a double hit): the two momentum rows are retired.
    const slack = LATE_OK;
    // Re-based (brawl-second-pass.md section 11, a6d3ed5f): a break is always for a lead and comes at the limit or on the tick a lead of 2 appears after it, with no bound but the double hit at 240; a close follows 85 to 95% of breaks, reported.
    const closedShare = b.tradeBreaks ? 1 - (b.breakToCloseLate || 0) / b.tradeBreaks : null;
    rows.push({ id: 'masher.tradelimit' + sfx, ref: '§9d', what: 'A trade breaks at its limit or on the tick a lead of 2 appears after it (reported; no bound but the double hit at 240 ticks)' + lab, status: 'INFO', value: b.tradeBreaks ? `${b.tradeBreaks} breaks; ${b.breaksEarly} before the limit; lateness in ticks: 95th percentile ${b.breakLateP95}, longest ${b.breakLateMax}` : 'no trade broke', band: 'reported', note: 'the old hard test (never early, at most 4 late) is retired: a lead appears whenever the other fighter stops landing' });
    rows.push({ id: 'masher.breakclose' + sfx, ref: '§9d', what: 'A close follows a trade break within 24 ticks, and 4 more for a hit-stop (reported: 85 to 95% expected)' + lab, status: 'INFO', value: closedShare === null ? 'no trade broke' : `${pct(closedShare)} of ${b.tradeBreaks} breaks (${b.breakToCloseLate} took longer)`, band: 'reported (85 to 95%)', note: 'counted on S.tick from the trade_break event to the next flurry close or brawl_end' });
    rows.push({ id: 'masher.closes' + sfx, ref: '§9d', what: 'Lights-only mirror: brawls, blows and closes (reported)' + lab, status: 'INFO', value: `${b.brawlsPerMin} brawls a minute, ${b.closesPerMin} closes a minute, ${b.heavyStaggers} heavy staggers; blows ${JSON.stringify(b.blows)}; ends ${JSON.stringify(b.ends)}`, band: 'reported', note: `${m.n} matches` });
  }
  return rows;
}

// C1 rows from the stick-script pairs (players.gd: drift=, walk=, turret) and the drop row. The build has C1 when its DirBrawl has the centre read (centre.ticks > 0 in these runs) or has ended a brawl with the text walk or double.
function c1Rows(r, results) {
  const b = r.brawl || {}, c = b.centre || {}, d = b.drift || {}, w = b.walk || {}, ends = b.ends || {};
  const has = (c.ticks || 0) > 0 || (ends.walk || 0) > 0 || (b.doubleHits || 0) > 0;
  const none = (id, ref, what, band) => ({ id, ref, what, status: 'PENDING', value: 'the build has no C1 (no DirBrawl.centre, no walk end, no double hit in these runs)', band, note: `${r.n} matches` });
  const rows = [];
  if (r.pair === 'c1-hold-one') {
    // Orb's test 1 (brawl-second-pass.md section 13): no live tick of a brawl with a dead stick outside a knock-back and its kind (a hard test). The stick is held on every live tick of a brawl; a tick after the ramp (14 ticks)
    // on which the fighter does not move along it, in a state that is not launched, down, dropped, buried, held, thrown, lifted or carried, is a dead tick. The rival holds no stick, so nothing cancels it.
    const hd = b.hold || {};
    const what = 'No live tick of a brawl with a dead stick, outside a knock-back and its kind (hard test; states reached: striking and mashing, staggered, reeling; the wind-up, charge and guard states come with C2a and C2b)';
    rows.push({ id: 'c1.dead', ref: '§11 second pass', what, status: hd.dead ? 'FAIL' : (hd.ticks ? 'PASS' : 'PENDING'), value: hd.ticks ? `${hd.dead} dead ticks of ${hd.ticks} held ticks; by state ${JSON.stringify(hd.deadStates || {})}` : 'the stick was never held long enough in a brawl', band: 'none', note: `${r.n} matches; before C1 this is the lock itself (every held tick of a locked fighter is dead; 12,369 of 15,323 on 53d13b55 in a 2-match smoke); a fighter against a building face or the ground also stops, which this read cannot tell from a dead stick: look at the states first` });
    return rows;
  }
  if (r.pair === 'c1-drift-ai') {
    // a held stick moves the brawl against the medium AI at least 0.7 as far as against a rival who holds none (the c1-drift-one pair, the same script)
    const ref = (results || []).find(x => x.pair === 'c1-drift-one'), r0 = ref && ref.brawl && ref.brawl.drift ? ref.brawl.drift.rateBhPerSec : -1;
    const what = 'A held stick against the medium AI moves the brawl at least 0.7 as far as against a rival who holds no stick (the AI holds against it on under 25% of the ticks: that read needs the AIs stick on a cue)';
    if (!has || !d.n || !(r0 > 0)) { rows.push({ id: 'c1.aistick', ref: '§11 second pass', what, status: 'PENDING', value: 'the build has no C1, or no drift was measured on one of the two runs', band: 'at least 0.7', note: `${r.n} matches` }); return rows; }
    const ratio = d.rateBhPerSec / r0;
    const ao = d.aiStickTicks ? d.aiOpposeTicks / d.aiStickTicks : null;
    rows.push({ id: 'c1.aihold', ref: '§11 second pass', what: 'The medium AI holds its own stick against a player\'s held stick on under 25% of the ticks he holds it (DirBrawl.stick)', status: ao === null ? 'PENDING' : (ao < 0.25 ? 'PASS' : 'FAIL'), value: ao === null ? 'the build has no DirBrawl.stick read' : `${(100 * ao).toFixed(1)}% (${d.aiOpposeTicks} of ${d.aiStickTicks} ticks)`, band: 'under 25%', note: `${d.n} drifts against the AI` });
    rows.push({ id: 'c1.aistick', ref: '§11 second pass', what, status: ratio >= 0.7 ? 'PASS' : 'FAIL', value: `${ratio.toFixed(2)} (${d.rateBhPerSec} bh a second against the medium AI, ${r0} against a rival with no stick)`, band: 'at least 0.7', note: `${d.n} drifts against the AI and ${ref.brawl.drift.n} against the script; point estimates` });
    return rows;
  }
  if (r.pair === 'c1-drift-one' || r.pair === 'c1-drift-both') {
    const one = r.pair === 'c1-drift-one', rate = d.rateBhPerSec;
    if (!has || !d.n) { rows.push(none('c1.drift.' + (one ? 'one' : 'both'), '§1 second pass', `The centre drift under a held stick: ${one ? 'one fighter' : 'both fighters'} (reported; 0.4 and 0.8 of free-flight speed)`, 'reported')); return rows; }
    rows.push({ id: 'c1.drift.' + (one ? 'one' : 'both'), ref: '§1 second pass', what: `How far a held stick moves a brawl, after its ramp: ${one ? 'one fighter holds east, the other none' : 'both hold east'} (reported, bh a second; the design is 0.4 of free-flight speed for one stick and 0.8 for two)`, status: 'INFO', value: `${rate} bh a second along the stick; ${d.n} drifts`, band: 'reported', note: `largest step ${d.maxStepBh} bh a tick` });
    if (one) rows.push({ id: 'c1.centre.latency', ref: '§1 second pass', what: 'The centre moves at all within 2 live ticks of a stick (hard test; it answers on the tick after the stick is first read, small at first; the striking state, a lights mash)', status: d.latMax <= 2 ? 'PASS' : 'FAIL', value: `the first move came ${d.latMean} ticks after the stick on average, at most ${d.latMax} (999 means it never moved)`, band: 'at most 2 ticks', note: `${d.n} drifts; read from DirBrawl.centre velocity when it has one, else from a step over 0.15 units; the other states (charging, guarding, reeling) are for the C2 slices` });
    rows.push({ id: 'c1.centre.step.' + (one ? 'one' : 'both'), ref: '§1 second pass', what: `The nudge never moves the pair more than 0.3 bh in a tick (hard test, read on the centre's speed, every tick of every brawl in this run: ${one ? 'one stick' : 'two sticks'}; the pair's middle jumping because a strike placed its attacker is reported beside it)`, status: (c.speedTicks || 0) === 0 ? 'PENDING' : (c.over > 0 ? 'FAIL' : 'PASS'), value: (c.speedTicks || 0) === 0 ? 'the build has no DirBrawl.centre speed (vx, vy)' : `${c.over} of ${c.speedTicks} brawl ticks over; the fastest ${c.maxStepBh} bh a tick. Reported: the middle moved over 0.3 bh on ${c.posOver} of ${c.ticks} ticks, the largest ${c.posMaxBh} bh`, band: 'at most 0.3 bh a tick', note: `${r.n} matches` });
    return rows;
  }
  if (r.pair === 'zip-turret' || r.pair === 'zip-hook') {
    const hook = r.pair === 'zip-hook', zid = hook ? 'zip.drop' : 'zip.drop.bolt', dr = b.drop || {}, down = (b.zipEnds || {}).down || 0;
    const what = (hook ? 'A shot reported on the way out (DirZip.shot, the way the module check does) drops the zipper: ' : 'A real bolt that reaches the zipper on the way out drops him: ') + 'zip_end down, then drop_start, drop_land, drop_end, and the state dropped between (hard test)';
    if (!r.zips) { rows.push({ id: zid, ref: '§2c', what, status: 'PENDING', value: 'the build has no zip', band: 'every down is a drop', note: `${r.n} matches` }); return rows; }
    if (!down) { rows.push({ id: zid, ref: '§2c', what, status: 'PENDING', value: `no ${hook ? 'shot' : 'bolt'} reached a zipper on the way out in ${r.n} matches (${r.zips} zips; ends ${JSON.stringify(b.zipEnds)}): a coverage gap, not a pass`, band: 'every down is a drop', note: 'the turret presses a bolt on each tick of the way out and after the blow, with chance 50%' }); return rows; }
    const ok = dr.start === down && dr.end === down && dr.land <= down && !dr.stateBad && !dr.endBad;
    rows.push({ id: zid, ref: '§2c', what, status: ok ? 'PASS' : 'FAIL', value: `${down} zips ended down; ${dr.start} drop_start, ${dr.land} drop_land, ${dr.end} drop_end; the state was not dropped at ${dr.stateBad} starts and still dropped at ${dr.endBad} ends`, band: 'one drop_start and one drop_end for every down, the state dropped between; drop_land at most one each (a drop that began on the ground may have no land: reported)', note: `${r.n} matches, ${r.zips} zips; ends ${JSON.stringify(b.zipEnds)}` });
    return rows;
  }
  // the walk-outs (the mutual walk-out only: the one-sided one is retired)
  const walkBrawls = w.brawls || 0, walkEnds = ends.walk || 0, pair = r.pair;
  const idOf = { 'c1-walk-both': 'c1.walk.both', 'c1-walk-jab': 'c1.walk.jab', 'c1-walk-guard': 'c1.walk.guard', 'c1-walk-held': 'c1.walk.held', 'c1-walk-one': 'c1.walk.one' }[pair];
  const what = { 'c1-walk-both': 'Both fighters hold away within 45 degrees: the brawl ends walk, never sooner than 12 ticks after the later stick (hard test; free, nobody decisive)', 'c1-walk-jab': 'A blow thrown by either fighter in the 12 ticks starts the count again: the end comes at least 12 ticks after the blow press (hard test)', 'c1-walk-guard': 'The 12 ticks count while either guards: both walk with guards held, and the brawl still ends walk, never early (hard test)', 'c1-walk-held': 'The 12 ticks do not count while an attack button is held: one fighter holds the light button while both hold away, and no walk end comes (hard test)', 'c1-walk-one': 'One fighter alone cannot end a brawl by walking: the other keeps mashing, and no walk end comes (hard test)' }[pair];
  if (!has) { rows.push(none(idOf, '§1 second pass', what, 'see the row')); return rows; }
  if (pair === 'c1-walk-held' || pair === 'c1-walk-one') {
    rows.push({ id: idOf, ref: '§1 second pass', what, status: walkEnds ? 'FAIL' : 'PASS', value: `${walkEnds} walk ends in ${r.n} matches (${b.brawls} brawls; ${walkBrawls} with both sticks away)`, band: 'none', note: 'a brawl that ends for any other reason is not counted' });
    return rows;
  }
  const early = w.early || 0;
  rows.push({ id: idOf, ref: '§1 second pass', what, status: early ? 'FAIL' : (walkEnds ? 'PASS' : 'FAIL'), value: `${walkEnds} walk ends in ${walkBrawls} brawls where both sticks were away (${walkBrawls ? (100 * walkEnds / walkBrawls).toFixed(0) : '-'}%); ${early} came under 12 ticks after the later stick or the jab; the shortest was ${w.lagMin} ticks and the longest ${w.lagMax}`, band: 'never under 12 ticks; the walk must happen', note: `${r.n} matches; the other ends of those brawls: ${JSON.stringify(Object.fromEntries(Object.entries(ends).filter(([k]) => k !== 'walk')))}` });
  return rows;
}

// Orb's four tests and the three strengths (docs/qa/three-strength-qa-plan.md H; brawl-plan.md section 10.3 has the names). Every row is PENDING while the build has none of the cue it reads.
function c2Rows(r, results) {
  const b = r.brawl || {}, rows = [], dec = r.aWins + r.bWins, pct = v => (100 * v).toFixed(1) + '%', blows = b.blows || {};
  const has3 = (b.windupN || 0) > 0 || (blows.medium || 0) > 0 || (blows.heavy || 0) > 0;
  const pend = (id, ref, what, band, why) => ({ id, ref, what, status: 'PENDING', value: why, band, note: `${r.n} matches` });
  const per = b.doublePer || [], mean = a => a.length ? a.reduce((x, y) => x + y, 0) / a.length : 0;
  if (r.pair === 'double-lights' || r.pair === 'double-mix') {
    const lights = r.pair === 'double-lights', n = per.length, withOne = per.filter(x => x > 0).length, m = mean(per);
    const what = `Double hits against the medium AI by ${lights ? 'a lights-only presser (stick toward)' : 'a mixing presser (L L H, stick toward)'}: a match, and matches with at least one (0.5 to 2; 35 to 65%)`;
    if (!n) return [pend('double.presser.' + (lights ? 'lights' : 'mix'), '§7 second pass', what, '0.5 to 2; 35 to 65%', 'no match recorded')];
    const ok = m >= 0.5 && m <= 2 && withOne / n >= 0.35 && withOne / n <= 0.65;
    rows.push({ id: 'double.presser.' + (lights ? 'lights' : 'mix'), ref: '§7 second pass', what, status: (b.doubleHits || 0) === 0 && !(b.ends || {}).double ? 'PENDING' : (ok ? 'PASS' : 'FAIL'), value: `${m.toFixed(2)} a match; ${pct(withOne / n)} of matches (${withOne} of ${n}); ${b.doubleHits} double hits`, band: '0.5 to 2; 35 to 65%', note: `${n} matches; measured on C1 at 0.3 and 0.2, tuned on C2a by the AI's digIn; the trade length on the cue is the double.trade240 row` });
    return rows;
  }
  if (r.pair === 'str-alt') {   // the closing rule rows ride on the alternator: every strength is pressed, from every gap
    const cl = b.closing || {}, sm = cl.samples || [], bad = sm.filter(x => x[1] - x[0] < 0 || x[1] - x[0] > 4);
    rows.push({ id: 'closing.d', ref: '§1 second pass', what: 'A blow lands d ticks later than its own time, d from 0 to 4 (2 ticks a bh of gap, at most 4): the cue\'s landing tick less the press tick, less the wind-up (hard test; the exact formula is checked when the gap\'s definition is confirmed)', status: !has3 || !sm.length ? 'PENDING' : (bad.length ? 'FAIL' : 'PASS'), value: !sm.length ? 'the build has no windup cue' : `${bad.length} of ${sm.length} outside 0 to 4; the largest d ${Math.max(...sm.map(x => x[1] - x[0]))}`, band: '0 to 4 ticks', note: `samples [wind-up, ticks to landing, gap bh]: ${JSON.stringify(sm.slice(0, 6))}` });
    rows.push({ id: 'closing.step', ref: '§1 second pass', what: 'No blow moves its attacker more than 0.6 bh in a tick (hard test from C2t; reported before it)', status: cl.blowMoveN ? (has3 ? (cl.blowMoveOver > 0 ? 'FAIL' : 'PASS') : 'INFO') : 'PENDING', value: cl.blowMoveN ? `${cl.blowMoveOver} of ${cl.blowMoveN} blows moved their attacker over 0.6 bh in the tick; the most ${cl.blowMoveMaxBh} bh` : 'no blow cue', band: 'at most 0.6 bh a tick', note: `${r.n} matches` });
  }
  if (/^str-/.test(r.pair)) {
    const label = { 'str-y': 'a Y masher (a medium every 12 ticks)', 'str-b': 'a B masher (a heavy every 30 ticks)', 'str-alt': 'the alternator (X, Y, B in turn, a press every 12 ticks)', 'str-holdx': 'the player who only holds X (60 ticks down, 8 up)', 'str-x10b': 'the 10-tick tapper with B (X X B)' }[r.pair];
    rows.push({ id: 'masher.' + r.pair, ref: '§11 second pass', what: `${label} against the medium AI (reported; the X masher's 35 to 50% is kept)`, status: has3 || r.pair === 'str-holdx' ? 'INFO' : 'PENDING', value: has3 || r.pair === 'str-holdx' ? `${dec ? pct(r.aWins / dec) : '-'} (${r.aWins} of ${dec}); ${r.timeouts} ran to the cap` : 'the build has no three strengths: Y and B are the old heavy and the beam', band: 'reported', note: `${r.n} matches; blows ${JSON.stringify(blows)}` });
    return rows;
  }
  if (/^fl-/.test(r.pair)) {
    const [what, id] = { 'fl-xy': ['The X flurry beats the Y flurry (it lands twice as many blows)', 'flurry.xy'], 'fl-yb': ['The Y flurry beats the B flurry (a medium lands inside the 20 ticks in which a heavy can be stopped)', 'flurry.yb'], 'fl-bx': ['The B flurry beats the X flurry (lights do not stop a heavy)', 'flurry.bx'] }[r.pair];
    rows.push({ id, ref: '§11 second pass', what: what + ' (55 to 75%)', status: !has3 ? 'PENDING' : (dec ? (r.aWins / dec >= 0.55 && r.aWins / dec <= 0.75 ? 'PASS' : 'FAIL') : 'PENDING'), value: !has3 ? 'the build has no three strengths' : (dec ? `${pct(r.aWins / dec)} (${r.aWins} of ${dec})` : 'no decided match'), band: '55 to 75%', note: `${r.n} matches, the second player on a seeded offset of 0 to 7 ticks; point estimate (about ±10 points)` });
    return rows;
  }
  if (/^route-/.test(r.pair)) {
    const lv = r.pair.slice(6), lc = b.launcher || {}, by = lc.routeBy || [], on = lc.routeOn || [], fl = (lc.firstLaunchSec || []).filter(x => x >= 0);
    const band = { easy: [0.70, 0.90], medium: [0.50, 0.75], hard: [0.30, 0.55] }[lv];
    if (!(lc.open > 0)) { rows.push(pend('route.' + lv, '§13 second pass', `The launcher's route (X every 8 ticks, a B tap when the stagger opens) launches in ${band[0] * 100} to ${band[1] * 100}% of the brawls it is tried in against ${lv}`, `${band[0] * 100} to ${band[1] * 100}%`, 'the build has no launcher_open cue (C2t)')); return rows; }
    const tried = b.brawls || 0, launches = by.reduce((x, y) => x + y, 0), share = tried ? launches / tried : 0;
    rows.push({ id: 'route.' + lv, ref: '§13 second pass', what: `The launcher's route launches in ${band[0] * 100} to ${band[1] * 100}% of the brawls it is tried in against the ${lv} AI (launches by the route's player over brawls)`, status: share >= band[0] && share <= band[1] ? 'PASS' : 'FAIL', value: `${pct(share)} (${launches} launches in ${tried} brawls); route player wins ${dec ? pct(r.aWins / dec) : '-'}`, band: `${band[0] * 100} to ${band[1] * 100}%`, note: `${r.n} matches; an approximation: launches, not brawls with a launch` });
    rows.push({ id: 'route.every.' + lv, ref: '§13 second pass', what: `From a stagger of 12 ticks or more a tapped B lands and launches, every time (hard test), against the ${lv} AI`, status: lc.lapsed === 0 && lc.used > 0 && launches >= 0.98 * lc.used ? 'PASS' : 'FAIL', value: `${lc.used} launchers used and ${lc.lapsed} lapsed by the route's player; ${launches} launches by him`, band: 'none lapsed, a launch for each', note: `${lc.open} launcher_open cues in ${r.n} matches` });
    if (lv === 'medium') {
      rows.push({ id: 'route.first30', ref: '§13 second pass', what: 'A first launch inside 30 s of the first brawl, in at least 80% of matches at medium', status: fl.length ? (fl.filter(x => x <= 30).length / by.length >= 0.80 ? 'PASS' : 'FAIL') : 'FAIL', value: `${by.length ? pct(fl.filter(x => x <= 30).length / by.length) : '-'} of ${by.length} matches (${fl.length} had a launch at all)`, band: 'at least 80%', note: 'a launch by the route\'s player' });
      const mb = mean(by), mo = mean(on);
      rows.push({ id: 'route.perMatch', ref: '§13 second pass', what: 'Launches a match at medium: by the route\'s player (4 to 10), and on him (4 to 8); collateral is reported beside it (the arms\' rows)', status: mb >= 4 && mb <= 10 && mo >= 4 && mo <= 8 ? 'PASS' : 'FAIL', value: `${mb.toFixed(2)} by him, ${mo.toFixed(2)} on him`, band: '4 to 10; 4 to 8', note: `${by.length} matches; point estimates` });
    }
    return rows;
  }
  if (/^give-/.test(r.pair)) {
    const g = b.give || {}, followed = /follow/.test(r.pair), heavy = /-b-/.test(r.pair), cls = heavy ? g.heavy : g.medium;
    const tag = r.pair.replace('give-', '');
    if (!(g.n > 0)) { rows.push(pend('give.' + tag, '§1 second pass', `Giving ground against a ${heavy ? 'tapped heavy' : 'tapped medium'} that ${followed ? 'is followed' : 'is not followed'}`, 'see the row', 'the build has no windup cue (C2a) or the giver saw no wind-up')); return rows; }
    rows.push({ id: 'give.lat.' + tag, ref: '§1 second pass', what: 'A fighter with his hands down moves within 2 ticks of his stick while the rival winds up (hard test)', status: g.latMax >= 0 && g.latMax <= 2 ? 'PASS' : 'FAIL', value: `the slowest first step came ${g.latMax} ticks after the stick (${g.n} wind-ups; -1 means he never moved)`, band: 'at most 2 ticks', note: `${r.n} matches` });
    if (heavy && !followed) rows.push({ id: 'give.out.b', ref: '§1 second pass', what: 'Out of a tapped heavy that is not followed, every time, when he starts by tick 16 (hard test: the blow ends as a miss with the text gave_ground)', status: cls.n16 > 0 && cls.m16 === cls.n16 ? 'PASS' : (cls.n16 > 0 ? 'FAIL' : 'PENDING'), value: `${cls.m16} of ${cls.n16} gave ground when he started by tick 16; later starts: ${cls.ml} of ${cls.nl} (reported)`, band: 'every time', note: `miss texts ${JSON.stringify(g.missTexts)}` });
    if (heavy && followed) rows.push({ id: 'give.followed.b', ref: '§1 second pass', what: 'Out of a tapped heavy that is followed from its first tick: never (hard test)', status: cls.m16 + cls.ml === 0 && cls.n16 + cls.nl > 0 ? 'PASS' : (cls.n16 + cls.nl > 0 ? 'FAIL' : 'PENDING'), value: `${cls.m16 + cls.ml} of ${cls.n16 + cls.nl} gave ground`, band: 'none', note: `miss texts ${JSON.stringify(g.missTexts)}` });
    if (!heavy) rows.push({ id: 'give.medium.' + (followed ? 'followed' : 'free'), ref: '§1 second pass', what: `Out of a tapped medium${followed ? ' that is followed' : ''}: only from its first 6 ticks, and never when followed (reported)`, status: 'INFO', value: `${cls.m6} of ${cls.n6} gave ground when he started in the first 6 ticks; later starts ${cls.ml} of ${cls.nl}`, band: 'reported', note: `miss texts ${JSON.stringify(g.missTexts)}` });
    return rows;
  }
  if (/^energy-/.test(r.pair)) {
    const en = b.energy || {}, bolt = r.pair === 'energy-x', n = bolt ? en.bolt : en.blast;
    if (!n) { rows.push(pend('energy.' + (bolt ? 'bolt' : 'blast'), '§5b second pass', bolt ? 'A point-blank bolt lands 2 ticks after its press (hard test)' : 'A clean blast knocks him back 4 bh (hard test)', bolt ? 'exactly 2' : '4 bh', 'the build has no energy_reach cue (C2t)')); return rows; }
    if (bolt) {
      const ann = en.announce || {}, two = ann['bolt:2'] || 0;
      rows.push({ id: 'energy.bolt', ref: '§5b second pass', what: 'A point-blank bolt lands 2 ticks after its press (hard test: the announced contact tick less the press tick)', status: two === en.bolt ? 'PASS' : 'FAIL', value: `${two} of ${en.bolt} announced at 2 ticks (${JSON.stringify(ann)})`, band: 'exactly 2', note: `${r.n} matches` });
      const fl = en.flashes || 0;
      rows.push({ id: 'energy.flash', ref: '§5b second pass', what: 'No more than three full flashes in any second, and one blow in 20 ticks at most may take one (hard test; a mashed RB + X)', status: fl ? (en.flashMax60 <= 3 && en.flashMinGap >= 20 ? 'PASS' : 'FAIL') : 'PENDING', value: fl ? `${fl} full flashes; the most in 60 ticks ${en.flashMax60}; the shortest gap ${en.flashMinGap} ticks` : 'no energy_land carried k 1', band: 'at most 3 in 60 ticks, 20 ticks apart', note: `${r.n} matches; sources ${JSON.stringify(en.src)}` });
    } else {
      const kb = en.kb || [], bad = kb.filter(x => Math.abs(x - 4) > 0.25);
      rows.push({ id: 'energy.blast', ref: '§5b second pass', what: 'A clean blast knocks him back 4 bh (hard test: the knock-back after a blast that landed with the source hit)', status: kb.length ? (bad.length ? 'FAIL' : 'PASS') : 'PENDING', value: kb.length ? `${kb.length} knock-backs, ${bad.length} off 4 bh by more than 0.25 (range ${Math.min(...kb)} to ${Math.max(...kb)})` : 'no knock-back followed a clean blast', band: '4 bh, within 0.25', note: `${en.blast} blasts pressed; sources ${JSON.stringify(en.src)}` });
    }
    return rows;
  }
  if (r.pair === 'burst-dummy') {
    const mash = results.find(x => x.pair === 'mash-dummy');
    const dps = x => { const st = (x.stats || [])[0]; return st && x.medianSec > 0 ? st.damagePerMatch / x.medianSec : 0; };
    if (!((b.burst || {}).n > 0) || !mash) { rows.push(pend('burst.share', '§11 second pass', 'The burst against a mash over the same time: 70 to 80% of the mash\'s damage, never over', '70 to 80%', 'the build has no burst cue')); return rows; }
    const ratio = dps(r) / Math.max(1e-9, dps(mash));
    rows.push({ id: 'burst.share', ref: '§11 second pass', what: 'The burst (a held X) against a mash (X every 8 ticks), damage a second against a rival who never moves: 70 to 80%, never over', status: ratio >= 0.70 && ratio <= 0.80 ? 'PASS' : 'FAIL', value: `${pct(ratio)} (${dps(r).toFixed(1)} against ${dps(mash).toFixed(1)} damage a second; ${b.burst.n} bursts, ${(b.burst.blows || []).filter(k => k === 8).length} of eight blows)`, band: '70 to 80%', note: `${r.n} matches each; damage per match over the match's median length, a rough read` });
  }
  return rows;
}

function masherRows(results) {
  const rows = results.filter(r => !r.mirror && !r.pair).map(r => {
    const [lo, hi, text] = BANDS[r.level], decided = r.wins + r.losses, v = decided ? r.wins / decided : NaN, ok = decided && v >= lo && v <= hi, forms = !!r.forms;
    const odd = r.gap !== 8;   // 6 and 10 are reported beside the banded 8-tick script (Game Design's ruling 4)
    return { id: 'masher.' + (forms ? '' : 'noforms.') + r.level + (odd ? '.g' + r.gap : ''), ref: '§6 masher', what: `A scripted masher (light every ${r.gap} ${r.clock === 'live' ? 'live ' : 'S.'}ticks, ${forms ? 'takes forms' : 'no forms'}) wins against the ${r.level} AI`, status: decided ? (forms && !odd ? (ok ? 'PASS' : 'FAIL') : 'INFO') : 'PENDING', value: decided ? `${(v * 100).toFixed(1)}% (${r.wins} of ${decided})` : 'no decided matches', band: forms ? text : `(${text} if forms are taken)`, note: `${r.n} matches, ${r.timeouts} timed out, median ${r.medianSec} s; point estimate only${forms ? '' : '; a beginner who never transforms fights at tier 1 (Game Design to rule)'}; per match: launches by the masher ${r.launchesByMasher}, of which air catches ${r.airCatchesOfAI}; launches on the masher ${r.launchesOnMasher}, air catches ${r.airCatchesOfMasher}` };
  });
  for (const r of results.filter(x => x.pair)) {
    const dec = r.aWins + r.bWins;
    if (r.pair.startsWith('blur-')) {
      const share = r.strings ? r.locked / r.strings : NaN, pct = (100 * share).toFixed(1) + '%';
      const defs = { 'blur-blind': ['a blind 8-tick masher', 0, 0.20, 'at most 20%'], 'blur-contact': ['a script that presses on every contact and follows the links', 0.80, 1, 'at least 80%'], 'blur-m10': ['a blind metronome every 10 ticks', 0, 0.20, 'at most 20% (assumed ceiling)'], 'blur-m12': ['a blind metronome every 12 ticks', 0, 0.20, 'at most 20% (assumed ceiling)'], 'blur-m14': ['a blind metronome every 14 ticks', 0, 0.20, 'at most 20% (assumed ceiling)'] }[r.pair];
      rows.push({ id: 'masher.' + r.pair.replace('-', '.'), ref: '§20', what: `The perfect blur locks on ${defs[0]}: share of five-blow strings against the medium AI (agency pass 20)`, status: r.strings >= 30 ? (r.pair.startsWith('blur-m') && !(share >= defs[1] && share <= defs[2]) ? 'INFO' : (share >= defs[1] && share <= defs[2] ? 'PASS' : 'FAIL')) : 'PENDING', value: `${pct} (${r.locked} of ${r.strings} strings)`, band: defs[3], note: `${r.n} matches; the script wins ${dec ? (100 * r.aWins / dec).toFixed(0) : '-'}%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes` });
      continue;
    }
    if (r.pair && (r.pair.startsWith('c1-') || r.pair === 'zip-turret' || r.pair === 'zip-hook')) rows.push(...c1Rows(r, results));
    else if (r.pair && /^(double-|str-|fl-|route-|give-|energy-|burst-|mash-dummy)/.test(r.pair)) rows.push(...c2Rows(r, results));
    else if (r.pair === 'bolt-melee') rows.push({ id: 'masher.bolt.finish', ref: '§6 masher', what: 'A bolt-only player (energy held, a bolt every 8 ticks) finishes the match against a melee masher before the cap (agency pass 16: at least 95%)', status: dec / r.n >= 0.95 ? 'PASS' : 'FAIL', value: `${(100 * dec / r.n).toFixed(1)}% (${dec} of ${r.n}; ${r.timeouts} ran to the cap)`, band: 'at least 95%', note: `median ${r.medianSec} s; point estimate` });
    else if (r.pair === 'bolt-medium') rows.push({ id: 'masher.bolt.medium', ref: '§6 masher', what: 'A bolt-only player wins against the medium AI (agency pass 16: 20 to 40%)', status: dec ? (r.aWins / dec >= 0.20 && r.aWins / dec <= 0.40 ? 'PASS' : 'FAIL') : 'PENDING', value: dec ? `${(100 * r.aWins / dec).toFixed(1)}% (${r.aWins} of ${dec})` : 'no decided matches', band: '20 to 40%', note: `${r.n} matches, ${r.timeouts} ran to the cap; point estimate` });
    else if (r.pair === 'blast-rush-slow') rows.push({ id: 'masher.blast.rushslow', ref: '§6 masher', what: 'The slow blaster (L L and a tapped H, one press every 24 ticks) against a rush-heavy timed script: at least 95% of matches finish before the cap (slice 12 is meant to fix this; 40 to 60% for the win share)', status: dec ? (r.aWins / dec >= 0.40 && r.aWins / dec <= 0.60 && dec / r.n >= 0.95 ? 'PASS' : 'FAIL') : 'FAIL', value: dec ? `${(100 * r.aWins / dec).toFixed(1)}% (${r.aWins} of ${dec}); ${(100 * dec / r.n).toFixed(0)}% finished` : 'no decided matches', band: '40 to 60%, finish at least 95%', note: `${r.n} matches, ${r.timeouts} ran to the cap; point estimate` });
    else if (r.pair === 'blast-rush') rows.push({ id: 'masher.blast.rush', ref: '§6 masher', what: 'A blast-heavy timed script (a bolt about every 14 ticks) against a rush-heavy timed script (agency pass 15.6: 40 to 60%, and at least 95% of matches finish)', status: dec ? (r.aWins / dec >= 0.40 && r.aWins / dec <= 0.60 && dec / r.n >= 0.95 ? 'PASS' : 'FAIL') : 'FAIL', value: dec ? `${(100 * r.aWins / dec).toFixed(1)}% (${r.aWins} of ${dec}); ${(100 * dec / r.n).toFixed(0)}% finished` : 'no decided matches', band: '40 to 60%, finish at least 95%', note: `${r.n} matches, ${r.timeouts} ran to the cap; point estimate` });
    else if (r.pair === 'zip-medium') rows.push({ id: 'masher.zip.medium', ref: '§2c', what: 'A player who only zip strikes (LT then a light, in the mid band) against the medium AI (reported)', status: r.zips ? 'INFO' : 'PENDING', value: r.zips ? `${dec ? (100 * r.aWins / dec).toFixed(1) : '-'}% (${r.aWins} of ${dec}); ${r.zips} zips in ${r.n} matches, ends ${JSON.stringify(r.zipEnds)}` : 'the build has no zip: no zip_light cue in these matches', band: 'reported', note: `${r.n} matches, ${r.timeouts} ran to the cap` });
    else if (r.pair === 'blast-slow-medium') rows.push({ id: 'masher.blast.slowmedium', ref: '§6 masher', what: 'The slow blaster (L L and a tapped H, one press every 24 ticks) wins against the medium AI (reported; the band of the mixed blaster, 30 to 50%, is the reference)', status: 'INFO', value: dec ? `${(100 * r.aWins / dec).toFixed(1)}% (${r.aWins} of ${dec})` : 'no decided matches', band: '(25 to 45%)', note: `${r.n} matches, ${r.timeouts} ran to the cap; point estimate` });
    else if (r.pair === 'blast-medium') rows.push({ id: 'masher.blast.medium', ref: '§6 masher', what: 'A mixed blaster (a bolt about every 14 ticks, a tapped heavy now and then) wins against the medium AI (agency pass section 22: 30 to 50%)', status: dec ? (r.aWins / dec >= 0.30 && r.aWins / dec <= 0.50 ? 'PASS' : 'FAIL') : 'PENDING', value: dec ? `${(100 * r.aWins / dec).toFixed(1)}% (${r.aWins} of ${dec})` : 'no decided matches', band: '30 to 50%', note: `${r.n} matches, ${r.timeouts} ran to the cap; point estimate` });
  }
  for (const m of results.filter(r => r.mirror)) rows.push(...mirrorRows(m));
  rows.push({ id: 'masher.expert', ref: '§6 masher', what: 'An expert script (guards, punishes with a heavy, perfect-blocks heavies and enders) wins against the medium AI (at most 15%)', status: 'PENDING', value: '', band: 'at most 15%', note: 'needs the expert script: it reads the rival tells (Encounter scratch build has one, not in the tree)' });
  return rows;
}

module.exports = { runMasher, masherRows };
