// Tightens World's schema for data/biomes/brunt.json (added by the EP's grant with window A, f9db2478; tools/schemas/biomes-brunt.schema.json and ten cases):
//   - every key the file carries is required (the loader has a default for each, but a validator that lets a key vanish hides the number: the file shows them all);
//   - cross-references (tools/lib/xref-brunt.js, from docs/tools/pending/xref-brunt.js), rule `brunt-order`: the ladder never falls with the tier (tierFactor, chainMax, towerPunches and
//     lodgeSeconds do not decrease from tier 1 to 4), a finisher's links and hold are at least tier 4's (chainSpecial, lodgeSpecialSeconds), and the speed kept rises from a punched
//     floor's least to its most to a free floor's (keepMin at most keepHi at most keepFree);
//   - a case for every key's absence and type, and for each rule (and its equal-is-fine edge).
// NOT run by CI, the validator or the sim: node docs/tools/pending/apply-biomes-brunt.cjs. Re-runnable. It does NOT edit data/.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const F = 'data/biomes/brunt.json';
const SCH = 'tools/schemas/biomes-brunt.schema.json';
const live = rj(F);
{
  const s = rj(SCH);
  const keys = Object.keys(live).filter((k) => !k.startsWith('_'));
  for (const k of keys) if (s.properties[k] && !s.required.includes(k)) s.required.push(k);
  s.description = s.description.replace('Every key is optional in the loader (a default stands); the file carries them all.', 'Every key has a default in the loader and the file carries them all, so every key is required here (a number cannot vanish unseen); the order rules are tools/lib/xref-brunt.js (brunt-order).');
  wj(SCH, s);
}
{
  fs.copyFileSync('docs/tools/pending/xref-brunt.js', 'tools/lib/xref-brunt.js');
  const xf = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(xf, 'utf8');
  if (!t.includes("require('./xref-brunt')")) {
    const a = "  require('./xref-brawl-keys').xrefBrawlKeys({ get, err, esc, isObj });\n";
    if (!t.includes(a)) throw new Error('brunt xref anchor');
    t = t.replace(a, () => a + "  require('./xref-brunt').xrefBrunt({ get, err, esc, isObj });\n");
    fs.writeFileSync(xf, t);
  }
}
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const out = [];
  const cs = (id, mutate, expect) => out.push({ id: 'brunt-' + id, schema: 'biomes-brunt.schema.json', mutate: [{ file: F, ...mutate }], expect });
  const s = rj(SCH);
  for (const k of Object.keys(live).filter((x) => !x.startsWith('_'))) {
    if (k === 'schema') continue;
    cs('key-required-' + k.replace(/([A-Z])/g, '-$1').toLowerCase(), { del: ['/' + k] }, { rule: 'required', pointer: '' });
    const p = s.properties[k];
    if (p && p.type === 'array') cs('key-type-' + k.replace(/([A-Z])/g, '-$1').toLowerCase(), { set: { ['/' + k]: 'many' } }, { rule: 'type', pointer: '/' + k });
    else if (p && (p.type === 'number' || p.type === 'integer')) cs('key-type-' + k.replace(/([A-Z])/g, '-$1').toLowerCase(), { set: { ['/' + k]: 'much' } }, { rule: 'type', pointer: '/' + k });
  }
  cs('tier-factor-falls', { set: { '/tierFactor': [0.5, 0.4, 0.6, 0.7] } }, { rule: 'xref:brunt-order', pointer: '/tierFactor/1' });
  cs('tier-factor-equal-ok', { set: { '/tierFactor': [0.5, 0.5, 0.6, 0.7] } }, null);
  cs('chain-max-falls', { set: { '/chainMax': [2, 1, 3, 4], '/chainSpecial': 5 } }, { rule: 'xref:brunt-order', pointer: '/chainMax/1' });
  cs('chain-max-equal-ok', { set: { '/chainMax': [2, 2, 2, 2], '/chainSpecial': 2 } }, null);
  cs('chain-special-below-tier-4', { set: { '/chainMax': [1, 2, 3, 4], '/chainSpecial': 3 } }, { rule: 'xref:brunt-order', pointer: '/chainSpecial' });
  cs('tower-punches-fall', { set: { '/towerPunches': [0, 2, 1, 99] } }, { rule: 'xref:brunt-order', pointer: '/towerPunches/2' });
  cs('tower-punches-equal-ok', { set: { '/towerPunches': [1, 1, 1, 1] } }, null);
  cs('lodge-seconds-fall', { set: { '/lodgeSeconds': [0.9, 0.5, 0.7, 0.9] } }, { rule: 'xref:brunt-order', pointer: '/lodgeSeconds/1' });
  cs('lodge-special-below-tier-4', { set: { '/lodgeSeconds': [0.5, 0.5, 0.7, 0.9], '/lodgeSpecialSeconds': 0.4 } }, { rule: 'xref:brunt-order', pointer: '/lodgeSpecialSeconds' });
  cs('lodge-special-equal-ok', { set: { '/lodgeSeconds': [0.5, 0.5, 0.7, 0.9], '/lodgeSpecialSeconds': 0.9 } }, null);
  cs('keep-min-above-hi', { set: { '/keepMin': 0.9, '/keepHi': 0.8, '/keepFree': 0.95 } }, { rule: 'xref:brunt-order', pointer: '/keepMin' });
  cs('keep-hi-above-free', { set: { '/keepMin': 0.35, '/keepHi': 0.99, '/keepFree': 0.95 } }, { rule: 'xref:brunt-order', pointer: '/keepHi' });
  cs('keep-equal-ok', { set: { '/keepMin': 0.8, '/keepHi': 0.8, '/keepFree': 0.8 } }, null);
  cs('house-link-zero', { set: { '/houseLink': 0 } }, { rule: 'exclusiveMinimum', pointer: '/houseLink' });
  cs('house-link-one-ok', { set: { '/houseLink': 1 } }, null);
  cs('tower-punches-length', { set: { '/towerPunches': [0, 1, 99] } }, { rule: 'minItems', pointer: '/towerPunches' });
  cs('chain-max-length', { set: { '/chainMax': [1, 2, 3, 4, 5] } }, { rule: 'maxItems', pointer: '/chainMax' });
  cs('lodge-seconds-above-limit', { set: { '/lodgeSeconds': [0.5, 0.5, 0.7, 3.5], '/lodgeSpecialSeconds': 3.5 } }, { rule: 'maximum', pointer: '/lodgeSeconds/3' });
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`biomes brunt tightened (${n} new or changed cases)`);
}
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`brunt-order`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`stages-order`'));
    if (i < 0) throw new Error('README anchor');
    lines.splice(i + 1, 0, '| `brunt-order` | data/biomes/brunt.json: tierFactor, chainMax, towerPunches and lodgeSeconds do not fall from tier 1 to 4; chainSpecial and lodgeSpecialSeconds are at least tier 4\'s; keepMin is at most keepHi is at most keepFree |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}
