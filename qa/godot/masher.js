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
function runPair(tag, a, b, n, base) {
  const g = godot();
  if (!g) return Promise.reject(new Error('Godot 4.7 not found'));
  return new Promise((resolve, reject) => {
    const p = guard(spawn(g.exe, ['--headless', '--path', ROOT, '--script', 'res://qa/godot/players.gd', '--', String(n), String(base), `--a=${a}`, `--b=${b}`], { stdio: ['ignore', 'pipe', 'pipe'] }));
    let out = '';
    p.stdout.on('data', d => { out += d; }); p.stderr.on('data', d => { out += d; });
    p.on('error', reject);
    p.on('close', code => {
      const line = out.split(String.fromCharCode(10)).find(l => l.startsWith('{') && l.includes('"players"'));
      if (code !== 0 || !line) return reject(new Error('players.gd failed for ' + tag + ' (exit ' + code + ')' + String.fromCharCode(10) + out.slice(0, 1200)));
      const r = JSON.parse(line);
      resolve({ pair: tag, zips: (r.brawl || {}).zips, zipEnds: (r.brawl || {}).zipEnds, n: r.n, aWins: r.aWins, bWins: r.bWins, timeouts: r.timeouts, medianSec: r.medianSec, strings: r.stats[0].blurStrings, locked: r.stats[0].blurLocked });
    });
  });
}

// Two waves of three processes: the masher who takes forms (the banded rows) and the one who never transforms (INFO), per Encounter's finding in docs/director/masher-probes.md.
async function runMasher({ n = 100, base = 1, levels = ['easy', 'medium', 'hard'] } = {}) {
  const withForms = await Promise.all(levels.map(l => runLevel(l, n, base, true)));
  const noForms = await Promise.all(levels.map(l => runLevel(l, n, base, false)));
  // Game Design's ruling 4 (melee-press-feel.md 9d): the masher taps on S.tick; the banded row is the 8-tick script, 6 and 10 are reported beside it.
  const gaps = await Promise.all([6, 10].map(g => runLevel('medium', n, base, true, g)));
  // The lights-only mirror, twice: the first counts live ticks (as every earlier baseline did), the second counts S.tick (the real tap rate); then a 6-tick against a 12-tick tapper (closes a minute).
  const mirror = await runMirror(MIRROR_N, base);   // the mirror's matches are the slow ones (a stalemate runs to the cap), so it gets fewer
  const mirrors = await Promise.all([
    runMirror(MIRROR_N, base, 'masher:forms=1:clock=tick', null, 'tick'),
    runMirror(MIRROR_N, base, 'masher:forms=1:clock=tick', 'masher:forms=1:clock=tick:off=7', 'tickoff'),
    runMirror(MIRROR_N, base, 'masher:forms=1:clock=tick:gap=6', 'masher:forms=1:clock=tick:gap=12', 'fast-slow'),
  ]);
  const E = ':energy=1:forms=1:stick=1', R = ':forms=1:stick=1';
  const pairs = await Promise.all([
    runPair('bolt-melee', 'masher:energy=1:forms=1', 'masher:forms=1', Math.min(n, 40), base),
    runPair('bolt-medium', 'masher:energy=1:forms=1', 'ai:level=medium', Math.min(n, 100), base),
    runPair('blast-rush', 'tapper:idle=14:acc=80:win=4:mix=LLLH' + E, 'tapper:acc=80:win=4:mix=LLH' + R, Math.min(n, 40), base),
    runPair('blast-rush-slow', 'tapper:acc=80:win=4:mix=LLH' + E, 'tapper:acc=80:win=4:mix=LLH' + R, Math.min(n, 40), base),
    runPair('zip-medium', 'zipper:forms=1', 'ai:level=medium', Math.min(n, 100), base),
    runPair('blast-medium', 'tapper:idle=14:acc=80:win=4:mix=LLLH' + E, 'ai:level=medium', Math.min(n, 100), base),
    runPair('blast-slow-medium', 'tapper:acc=80:win=4:mix=LLH' + E, 'ai:level=medium', Math.min(n, 100), base),
  ]);
  // Agency pass section 20: how often the perfect blur locks, live against the medium AI. A blind 8-tick masher at most 20% of five-blow strings; a script that presses on every contact (and follows the chain links) at least 80%; a metronome on the real clock at 10, 12 and 14 ticks (Encounter measured 9, 27 and 26%; the same 20% ceiling is QA's assumption until Game Design rules).
  const M = ':forms=1:stick=1', ai = 'ai:level=medium';
  const blur1 = await Promise.all([
    runPair('blur-blind', 'masher' + M, ai, n, base),
    runPair('blur-contact', 'tapper:acc=100:win=0:jit=0:mix=L' + M, ai, n, base),
    runPair('blur-m10', 'masher:gap=10' + M, ai, n, base),
  ]);
  const blur2 = await Promise.all([
    runPair('blur-m12', 'masher:gap=12' + M, ai, n, base),
    runPair('blur-m14', 'masher:gap=14' + M, ai, n, base),
  ]);
  return [...withForms, ...noForms, ...gaps, mirror, ...mirrors, ...pairs, ...blur1, ...blur2];
}

const BANDS = { easy: [0.60, 1, 'at least 60%'], medium: [0.35, 0.50, '35 to 50%'], hard: [0, 0.15, 'at most 15%'] };


// The lights-only mirror's rows (agency pass 13 and 23; melee-press-feel.md sections 3, 9 and 9d), for each variant: 'live' counts live ticks (every earlier baseline), 'tick' counts S.tick
// (the real tap rate; the brawl's flurry counts it), 'fast-slow' is a 6-tick tapper against a 12-tick tapper (reported).
const LATE_OK = 4;   // ticks a trade's break may come after its limit: a hit-stop holds the sim (Encounter measured at most 2)

function mirrorRows(m) {
  const b = m.brawl || {}, sfx = m.tag === 'live' ? '' : '.' + m.tag, lab = m.tag === 'live' ? '' : ` (${m.tag === 'tick' ? 'taps on S.tick, both on the same ticks: the exact tie' : m.tag === 'tickoff' ? 'taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks' : 'a 6-tick tapper against a 12-tick tapper'})`;
  const rows = [];
  const pct = v => (100 * v).toFixed(1) + '%';
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
    if (b.exactTradeFields) {
      // exact (Encounter's trade_break fields): level trades are the breaks settled by the draw after a first close; a break changed hands when the draw went against the last closer (text draw, k 2)
      rows.push({ id: 'masher.momentum' + sfx, ref: '§9d', what: 'An even mash: level trades that change who has the momentum (5 to 15%)' + lab, status: b.levelTrades >= 20 ? (b.levelChangeShare >= 0.05 && b.levelChangeShare <= 0.15 ? 'PASS' : 'FAIL') : 'PENDING', value: b.levelTrades ? `${pct(b.levelChangeShare)} (${b.levelChanges} of ${b.levelTrades} level trades; ${b.breaksByLead} breaks went to a lead of 2)` : 'no level trade after a close', band: '5 to 15%', note: 'exact: the draw breaks after a first close (trade_break text draw, k 1 or 2); PENDING under 20 of them' });
    } else {
      rows.push({ id: 'masher.momentum' + sfx, ref: '§9d', what: 'An even mash: trade breaks that change who has the momentum, as a share of the breaks after a first close (5 to 15%)' + lab, status: b.momentumBreaks >= 20 ? (b.momentumChangeShare >= 0.05 && b.momentumChangeShare <= 0.15 ? 'PASS' : 'FAIL') : 'PENDING', value: b.momentumBreaks ? `${pct(b.momentumChangeShare)} (${b.momentumChanges} of ${b.momentumBreaks})` : 'no trade break after a close', band: '5 to 15%', note: 'an approximation until trade_break carries text and k: it counts every break (a lead of 2 also takes the close), not only level trades' });
    }
    const slack = LATE_OK;
    rows.push({ id: 'masher.tradelimit' + sfx, ref: '§9d', what: 'A trade breaks on the tick of its limit: never before it, and no later than a hit-stop explains (hard test)' + lab, status: b.tradeBreaks ? (b.breaksEarly === 0 && b.breakLateMax <= slack ? 'PASS' : 'FAIL') : 'PENDING', value: b.tradeBreaks ? `${b.breaksEarly} early; lateness in ticks: ${b.tradeBreaks - b.breaksEarly} breaks, 95th percentile ${b.breakLateP95}, longest ${b.breakLateMax} (limit ${b.tradeLimit}; allowed ${slack})` : 'no trade broke', band: `never early, at most ${slack} ticks late`, note: 'the break comes on the first live tick at or after the limit, so a hit-stop makes it late; Encounter is measuring how late it can be, and LATE_OK in masher.js is the allowance until it says' });
    rows.push({ id: 'masher.breakclose' + sfx, ref: '§9d', what: 'From a trade break to its close, or to the brawl end: at most 24 ticks, and 4 more for a hit-stop (hard test)' + lab, status: b.tradeBreaks ? (b.breakToCloseLate === 0 ? 'PASS' : 'FAIL') : 'PENDING', value: b.tradeBreaks ? `${b.breakToCloseLate} of ${b.tradeBreaks} breaks took longer` : 'no trade broke', band: '0 over 28 ticks', note: 'counted on S.tick from the trade_break event to the next flurry close or brawl_end' });
    rows.push({ id: 'masher.closes' + sfx, ref: '§9d', what: 'Lights-only mirror: brawls, blows and closes (reported)' + lab, status: 'INFO', value: `${b.brawlsPerMin} brawls a minute, ${b.closesPerMin} closes a minute, ${b.heavyStaggers} heavy staggers; blows ${JSON.stringify(b.blows)}; ends ${JSON.stringify(b.ends)}`, band: 'reported', note: `${m.n} matches` });
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
    if (r.pair === 'bolt-melee') rows.push({ id: 'masher.bolt.finish', ref: '§6 masher', what: 'A bolt-only player (energy held, a bolt every 8 ticks) finishes the match against a melee masher before the cap (agency pass 16: at least 95%)', status: dec / r.n >= 0.95 ? 'PASS' : 'FAIL', value: `${(100 * dec / r.n).toFixed(1)}% (${dec} of ${r.n}; ${r.timeouts} ran to the cap)`, band: 'at least 95%', note: `median ${r.medianSec} s; point estimate` });
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
