// Origin: the simulated-vision check for any set of colours (deterministic, no external code or data).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-06. Human direction: Orb, via the EP.
// Usage:  node art/concepts/colour-vision/check.mjs "#8fd6ff" "#9a80d8" ["#...", ...]
// Prints each colour as seen under protan, deutan and tritan, and the CIEDE2000 distance between every pair under each (and by default), against the rule for fighters:
// 25 or more by default, 20 or more under each simulation.
import { simulate, dE00 } from '../sky/colour.mjs';
const cols = process.argv.slice(2);
if (cols.length < 2) { console.log('usage: node check.mjs "#aaaaaa" "#bbbbbb" ...'); process.exit(1); }
const kinds = ['default', 'protan', 'deutan', 'tritan'];
for (const k of kinds) console.log(k.padEnd(7), cols.map(c => `${c}->${simulate(c, k)}`).join('  '));
let ok = true;
for (let i = 0; i < cols.length; i++) for (let j = i + 1; j < cols.length; j++) {
  const row = kinds.map(k => dE00(simulate(cols[i], k), simulate(cols[j], k)));
  const pass = row[0] >= 25 && row.slice(1).every(v => v >= 20); if (!pass) ok = false;
  console.log(`${cols[i]} vs ${cols[j]}: ${kinds.map((k, n) => `${k} ${row[n].toFixed(1)}`).join(', ')}  ${pass ? 'PASS' : 'below the rule'}`);
}
process.exit(ok ? 0 : 2);
