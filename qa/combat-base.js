// Tabulates the combat-overhaul baselines (EP 2026-11-28): node qa/combat-base.js <label>=<chunk prefix> ... > table.md
// Reads the CMB lines (one a match) and the ORBS line of orbs_player.gd --combat (combat_core.gd). Side 0 the scripted player, side 1 the computer. Shares carry Wilson 95% intervals; per-minute rates and medians a bootstrap 95% over matches.
const fs = require('fs');
const z = 1.96;
const wil = (k, n) => { if (!n) return [NaN, NaN]; const p = k / n, d = 1 + z * z / n, c = p + z * z / (2 * n), r = z * Math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)); return [100 * (c - r) / d, 100 * (c + r) / d]; };
const pct = (k, n) => (n ? `${(100 * k / n).toFixed(1)}% (${wil(k, n).map((x) => Math.max(0, x).toFixed(1)).join(' to ')}), ${k} of ${n}` : 'none seen');
let seed = 7; const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
const boot = (items, f, n = 1000) => { if (items.length < 2) return [NaN, NaN]; const v = []; for (let i = 0; i < n; i++) { const s = []; for (let j = 0; j < items.length; j++) s.push(items[Math.floor(rnd() * items.length)]); v.push(f(s)); } v.sort((a, b) => a - b); return [v[Math.floor(0.025 * n)], v[Math.floor(0.975 * n)]]; };
const q = (a, p) => { const b = [...a].sort((x, y) => x - y); return b.length ? b[Math.floor((b.length - 1) * p)] : NaN; };
const rate = (ms, count) => { const f = (s) => s.reduce((a, m) => a + count(m), 0) / (s.reduce((a, m) => a + m.len, 0) / 60); const [lo, hi] = boot(ms, f); return `${f(ms).toFixed(2)} (${lo.toFixed(2)} to ${hi.toFixed(2)})`; };

function load(prefix) {
  const ms = []; let hash = '';
  for (let k = 0; ; k++) {
    const f = `${prefix}_${k}.out`;
    if (!fs.existsSync(f)) break;
    const L = fs.readFileSync(f, 'utf8').split('\n').find((l) => l.startsWith('ORBS '));
    if (!L) throw new Error('no ORBS line in ' + f);
    const j = JSON.parse(L.slice(5));
    const mine = fs.readFileSync(f, 'utf8').split('\n').filter((l) => l.startsWith('CMB ')).map((l) => JSON.parse(l.slice(4)));
    if (mine.length !== j.combatMatches) throw new Error(`${f}: ${mine.length} match lines for ${j.combatMatches} matches`);
    ms.push(...mine); hash = j.dataHash;
  }
  return { ms, hash };
}

const cols = process.argv.slice(2).map((a) => { const i = a.indexOf('='); return { name: a.slice(0, i), ...load(a.slice(i + 1)) }; });
const rows = [];
const row = (label, f) => rows.push([label, ...cols.map((c) => { try { return f(c.ms); } catch (e) { return 'n/a ' + e.message; } })]);
const charges = (ms, side) => ms.flatMap((m) => m.charges.filter((c) => c.side === side));
const grabs = (ms, side) => ms.flatMap((m) => m.grabs.filter((g) => g[0] === side));
const spacing = (ms, side) => { const out = []; for (const m of ms) { const t = m.grabs.filter((g) => g[0] === side).map((g) => g[1]).sort((a, b) => a - b); for (let i = 1; i < t.length; i++) out.push(t[i] - t[i - 1]); } return out; };
const causeOf = (c) => (c.cause === 'grab' ? 'a grab' : c.how === 'stopped by a blow' ? `a blow (${c.cause})` : c.how);

row('matches', (ms) => String(ms.length));
row('match length, sim s: median (95%)', (ms) => { const f = (s) => q(s.map((m) => m.len), 0.5); const [a, b] = boot(ms, f); return `${f(ms).toFixed(0)} (${a.toFixed(0)} to ${b.toFixed(0)})`; });
row('match length p10 / p90, sim s', (ms) => `${q(ms.map((m) => m.len), 0.1).toFixed(0)} / ${q(ms.map((m) => m.len), 0.9).toFixed(0)}`);
row('scripted player wins', (ms) => pct(ms.filter((m) => m.result === 0).length, ms.length));
row('**GRABS** computer grab tries a minute', (ms) => rate(ms, (m) => m.grabs.filter((g) => g[0] === 1).length));
row('... computer grabs landed (clinches) a minute', (ms) => rate(ms, (m) => m.clinch[1]));
row('... player grab tries a minute', (ms) => rate(ms, (m) => m.grabs.filter((g) => g[0] === 0).length));
row('computer grab tries begun while the player was winding or charging a heavy', (ms) => pct(grabs(ms, 1).filter((g) => g[3]).length, grabs(ms, 1).length));
row('... while the player was gathering a stick beam', (ms) => pct(grabs(ms, 1).filter((g) => g[4]).length, grabs(ms, 1).length));
row('grab tries begun farther than 0.6 BH past contact (as the catch measures), both sides', (ms) => { const all = ms.flatMap((m) => m.grabs); return pct(all.filter((g) => g[2] > 0.6).length, all.length); });
row('two tries by one fighter inside 180 ticks: computer', (ms) => { const s = spacing(ms, 1); return pct(s.filter((d) => d < 180).length, s.length) + (s.length ? `; shortest ${Math.min(...s)}` : ''); });
row('**CHARGES** player heavies wound (a match)', (ms) => `${charges(ms, 0).length} (${(charges(ms, 0).length / ms.length).toFixed(1)})`);
row('... reached the charge flash', (ms) => pct(charges(ms, 0).filter((c) => c.flash).length, charges(ms, 0).length));
row('... released', (ms) => pct(charges(ms, 0).filter((c) => c.how === 'released').length, charges(ms, 0).length));
row('... interrupted (stopped by a blow or a grab, or lost)', (ms) => pct(charges(ms, 0).filter((c) => c.how === 'stopped by a blow' || c.how.startsWith('lost')).length, charges(ms, 0).length));
row('... interrupted by what (count)', (ms) => { const o = {}; for (const c of charges(ms, 0).filter((x) => x.how === 'stopped by a blow' || x.how.startsWith('lost'))) o[causeOf(c)] = (o[causeOf(c)] || 0) + 1; return Object.entries(o).sort((a, b) => b[1] - a[1]).slice(0, 7).map(([k, v]) => `${k} ${v}`).join('; ') || 'none'; });
row('... interrupted before the flash', (ms) => { const i = charges(ms, 0).filter((x) => x.how === 'stopped by a blow' || x.how.startsWith('lost')); return pct(i.filter((c) => !c.flash).length, i.length); });
row('player lunges with a wound blow stopped on the way in (charge_stopped)', (ms) => String(ms.reduce((a, m) => a + m.approachStopped[0], 0)));
row('computer heavies wound; interrupted', (ms) => { const c = charges(ms, 1); return `${c.length}; ${pct(c.filter((x) => x.how === 'stopped by a blow' || x.how.startsWith('lost')).length, c.length)}`; });
row('three heavies in a row, grabbed at least once (player; non-overlapping triples)', (ms) => { let k = 0, n = 0; for (const m of ms) { const c = m.charges.filter((x) => x.side === 0).sort((a, b) => a.t - b.t); for (let i = 0; i + 2 < c.length; i += 3) { n++; if (c.slice(i, i + 3).some((x) => x.cause === 'grab')) k++; } } return pct(k, n); });
row('player stick-beam gathers; ended without firing', (ms) => { const g = ms.flatMap((m) => m.gathers.filter((x) => x.side === 0)); return `${g.length}; ${pct(g.filter((x) => !x.fired).length, g.length)}`; });
for (const [side, who] of [[0, 'player'], [1, 'computer']]) {
  row(`**BEAMS** ${who}'s beams: outcomes`, (ms) => { const o = ms.flatMap((m) => m.beamOut.filter((b) => b[0] === side).map((b) => b[1])); return o.length ? ['HIT', 'GUARD', 'DODGE', 'ESCAPE', 'CLASH', 'DEFLECT'].map((k) => `${k} ${(100 * o.filter((x) => x === k).length / o.length).toFixed(1)}%`).join(', ') + ` (of ${o.length}; ±${(100 * z * Math.sqrt(0.25 / o.length)).toFixed(1)} at most)` : 'none'; });
}
row('struggles a match', (ms) => (ms.reduce((a, m) => a + m.struggles.length, 0) / ms.length).toFixed(2));
row('struggles won by the scripted player', (ms) => { const s = ms.flatMap((m) => m.struggles).filter((x) => x.winner !== -2); return pct(s.filter((x) => x.winner === 0).length, s.length); });
row('struggles won by the computer; drawn', (ms) => { const s = ms.flatMap((m) => m.struggles).filter((x) => x.winner !== -2); return `${pct(s.filter((x) => x.winner === 1).length, s.length)}; drawn ${s.filter((x) => x.winner === -1).length}`; });
row('... player wins when the player\'s beam opened it / the computer\'s did', (ms) => { const s = ms.flatMap((m) => m.struggles).filter((x) => x.winner !== -2); const a = s.filter((x) => x.by === 0), b = s.filter((x) => x.by === 1); return `${pct(a.filter((x) => x.winner === 0).length, a.length)} / ${pct(b.filter((x) => x.winner === 0).length, b.length)}`; });
for (const [side, who] of [[0, 'scripted player'], [1, 'computer']]) {
  row(`**FLEEING** share of match time the ${who} flies away beyond 12.5 BH (from positions)`, (ms) => { const f = (s) => 100 * s.reduce((a, m) => a + m.awayByPos[side], 0) / s.reduce((a, m) => a + m.ticks, 0); const [lo, hi] = boot(ms, f); return `${f(ms).toFixed(2)}% (${lo.toFixed(2)} to ${hi.toFixed(2)})`; });
}
row('share of match time the pair is beyond 12.5 BH', (ms) => { const f = (s) => 100 * s.reduce((a, m) => a + m.far, 0) / s.reduce((a, m) => a + m.ticks, 0); const [lo, hi] = boot(ms, f); return `${f(ms).toFixed(1)}% (${lo.toFixed(1)} to ${hi.toFixed(1)})`; });
row("cross-check: director's feed lines against the events (reaches vs grab tries; beam outcome lines vs outcomes)", (ms) => { const tries = ms.reduce((a, m) => a + m.grabs.length, 0), reaches = ms.reduce((a, m) => a + m.feed.reaches, 0); const ev = ms.reduce((a, m) => a + m.beamOut.length, 0), lines = ms.reduce((a, m) => a + Object.values(m.feed.arrow).reduce((x, y) => x + y, 0), 0); return `${reaches} vs ${tries}; ${lines} vs ${ev}`; });
row('data hash', () => '');
rows[rows.length - 1] = ['data hash', ...cols.map((c) => c.hash)];
const L = ['| Measure | ' + cols.map((c) => c.name).join(' | ') + ' |', '| :--- |' + cols.map(() => ' :--- |').join('')];
for (const r of rows) L.push('| ' + r.join(' | ') + ' |');
console.log(L.join('\n'));
