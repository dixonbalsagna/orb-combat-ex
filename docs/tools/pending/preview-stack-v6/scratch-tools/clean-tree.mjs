// A clean landing tree: parks only (the overlay parks of the working tree skipped), no page switch flips, in the manifest's order. Usage: node clean-tree.mjs <out> <skip,ids>
import { runStack } from '../dev3/tools/preview/stack.mjs';
const [out, skip] = process.argv.slice(2);
const s = await runStack({ repo: 'C:/Users/<user>/Documents/Claude Proj/Breakers-Like', rev: '10d8b8cf', manifest: new URL('../dev3/tools/preview/stack.json', import.meta.url).pathname.replace(/^\//, ''), skip: skip.split(',').filter(Boolean), noGodot: true, force: true, keepTree: true, out, state: out + '.json', switches: [], log: (m) => console.error(m) });
const r = s.report || s;
console.log('key', r.key, 'parks', (r.parks || []).length, 'non-applied', JSON.stringify((r.parks || []).filter((p) => p.status !== 'applied').map((p) => [p.id, p.status, ((p.steps || []).find((x) => x.state !== 'applied') || {}).detail || ''])), 'conflict', JSON.stringify(r.firstConflict), 'flips on', JSON.stringify((r.switches && r.switches.on) || r.switches));
