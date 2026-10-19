// The schema for Combat's data/combat/enders.json (combat.enders/1; the launch enders Encounter's launch anywhere reads: docs/combat/launch-enders.md section 5): Combat's draft
// (docs/combat/pending/launch/combat-enders.schema.json) tightened, its map.json rule, the cross-references and the cases. Run once from the repo root, in the commit that lands the file:
//     node docs/tools/pending/apply-combat-enders.cjs
// It refuses until data/combat/enders.json is in the tree (a schema with no document fails the coverage check) and until the draft is readable. Re-runnable. Not run by CI or the validator.
// Tightened over the draft: launchPieces is a map of `strike.<id>` to {limb, path, target, sends} (closed); a path is one of line, rise, drop, arc_in, arc_out, spin; a send one of up, across,
// down, turned; rechamberCells are "<limb> <path> -> <send>" strings; `built` is {from, pieces}; every cell of enders has the four sends. Cross-references (rules enders-*):
//   enders-fighter  every fighter key is a pool of data/combat/recipes.json
//   enders-strike   a step 1 to 4 strike is a piece of that fighter's brawl.launcher pool; a step 5 strike is one of his launcher.bySendLower pieces for that send
//   enders-piece    every launchPieces key is a piece of his brawl.launcher pool or of his bySendLower
//   enders-step     the steps named exist in `steps`; rechamber.fromStep is one of them
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const F = 'data/combat/enders.json', DRAFT = 'docs/combat/pending/launch/combat-enders.schema.json', SF = 'tools/schemas/combat-enders.schema.json';
for (const f of [F, DRAFT]) if (!fs.existsSync(f)) { console.error(`${f} is not in the tree yet: run this in the commit that lands Combat's file`); process.exit(1); }
const data = rj(F);
const PATHS = ['line', 'rise', 'drop', 'arc_in', 'arc_out', 'spin'], SENDS = ['up', 'across', 'down', 'turned'];
const closed = { additionalProperties: false, patternProperties: { '^_': true } };

// ---- the schema
{
  const s = rj(DRAFT);
  s.description = String(s.description).replace(/^DRAFT by Combat for Tools \(([^)]*)\): /, '$1: ').replace(' Cross-references for Tools\' xref (proposed):', ' Cross-references (tools/lib/xref-fight.js, rules enders-fighter, enders-strike, enders-piece, enders-step):') + ' Version field: schema.';
  const fp = s.properties.fighters.patternProperties['^[a-z][a-z0-9_]*$'];
  fp.properties.launchPieces = {
    type: 'object', minProperties: 1, propertyNames: { pattern: '^(_.*|strike[.][a-z0-9_]+)$' },
    additionalProperties: { type: 'object', required: ['limb', 'path', 'target', 'sends'], properties: { limb: { type: 'string', pattern: '^[a-z]+$', description: 'The limb that throws it.' }, path: { enum: PATHS, description: 'The path of the blow.' }, target: { type: 'string', pattern: '^[a-z]+$', description: 'Where it lands.' }, sends: { type: 'array', minItems: 1, uniqueItems: true, items: { enum: SENDS }, description: 'Where it sends.' } }, ...closed },
    patternProperties: { '^_': true }, description: 'The launch pieces of this fighter by strike id: what each is.'
  };
  fp.properties.rechamberCells = { type: 'array', items: { type: 'string', pattern: '^(hands|legs|close) (line|rise|drop|arc_in|arc_out|spin) -> (up|across|down|turned)$' }, description: 'The cells that re-chamber: "<limb> <path> -> <send>".' };
  s.properties.built = { type: 'object', required: ['from', 'pieces'], properties: { from: { type: 'string', minLength: 1, description: 'The recipes file the pieces were built from.' }, pieces: { type: 'string', description: 'Which pools they were taken from.' } }, ...closed, description: 'Where the data was built from.' };
  s.properties.steps.description = 'Step 1 to 5 to its rule in words.';
  if (!same(fs.existsSync(SF) ? rj(SF) : null, s)) { wj(SF, s); console.log('schema: written'); } else console.log('schema: already');
}

// ---- the virtual fixture the self-test reads (its recipes are tools/fixtures/virtual/data/combat/recipes.json: rival and protagonist)
{
  const vr = 'tools/fixtures/virtual/data/combat/recipes.json', vf = 'tools/fixtures/virtual/data/combat/enders.json';
  if (fs.existsSync(vr)) {
    const pools = Object.keys(rj(vr).pools || {});
    const v = JSON.parse(JSON.stringify(data));
    v.fighters = Object.fromEntries(Object.entries(v.fighters).filter(([k]) => pools.includes(k)));
    v._about = 'Validator fixture, not game data: the enders of the fighters the fixture recipes have (' + pools.join(', ') + ').';
    if (!fs.existsSync(vf) || !same(rj(vf), v)) { fs.mkdirSync('tools/fixtures/virtual/data/combat', { recursive: true }); wj(vf, v); console.log('virtual fixture: written'); } else console.log('virtual fixture: already');
  }
}

// ---- the map rule
{
  const mf = 'tools/schemas/map.json';
  const m = rj(mf);
  if (m.rules.some((r) => r.match === F)) console.log('map: already');
  else { const i = m.rules.findIndex((r) => r.match === 'data/combat/recipes.json'); m.rules.splice(i < 0 ? m.rules.length : i + 1, 0, { match: F, schema: 'combat-enders.schema.json' }); wj(mf, m); console.log('map: rule added'); }
}

// ---- the cross-references
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.split('\r\n').join('\n');
  if (t.includes('enders-strike')) console.log('xref: already');
  else {
    const a = '  // ---- fight shots: a lobbed kind has both its numbers';
    if (!t.includes(a)) throw new Error('xref anchor');
    const block = [
      "  // ---- combat enders: the fighters, the strikes and the steps they name exist",
      "  {",
      "    const en = get('data/combat/enders.json');",
      "    const rc = get('data/combat/recipes.json');",
      "    if (isObj(en) && isObj(en.fighters) && isObj(rc) && isObj(rc.pools)) {",
      "      const EN = 'data/combat/enders.json';",
      "      const hasLower = isObj(rc.launcher) && isObj(rc.launcher.bySendLower);",
      "      const lower = hasLower ? rc.launcher.bySendLower : {};",
      "      const stepNames = isObj(en.steps) ? Object.keys(en.steps) : [];",
      "      if (isObj(en.rechamber) && typeof en.rechamber.fromStep === 'number' && stepNames.length && !stepNames.includes(String(en.rechamber.fromStep))) err(EN, '/rechamber/fromStep', 'enders-step', `rechamber.fromStep ${en.rechamber.fromStep} is not a step of steps (${stepNames.join(', ')})`);",
      "      for (const [fk, fv] of Object.entries(en.fighters)) {",
      "        if (fk.startsWith('_') || !isObj(fv)) continue;",
      "        const pool = rc.pools[fk];",
      "        if (!isObj(pool)) { err(EN, `/fighters/${esc(fk)}`, 'enders-fighter', `\"${fk}\" is not a pool of data/combat/recipes.json (${Object.keys(rc.pools).join(', ')})`); continue; }",
      "        const launcher = new Set((Array.isArray(pool['brawl.launcher']) ? pool['brawl.launcher'] : []).map((p) => p && p.id));",
      "        const low = isObj(lower[fk]) ? lower[fk] : {};",
      "        if (isObj(fv.enders)) for (const [cell, sends] of Object.entries(fv.enders)) {",
      "          if (!isObj(sends)) continue;",
      "          for (const [send, arr] of Object.entries(sends)) {",
      "            if (!Array.isArray(arr)) continue;",
      "            arr.forEach((it, i) => {",
      "              if (!isObj(it) || typeof it.strike !== 'string' || typeof it.step !== 'number') return;",
      "              const at = `/fighters/${esc(fk)}/enders/${esc(cell)}/${send}/${i}`;",
      "              if (it.step <= 4 && launcher.size && !launcher.has(it.strike)) err(EN, `${at}/strike`, 'enders-strike', `step ${it.step} strike \"${it.strike}\" is not a piece of ${fk}'s brawl.launcher pool`);",
      "              if (it.step === 5 && hasLower && !(Array.isArray(low[send]) && low[send].includes(it.strike))) err(EN, `${at}/strike`, 'enders-strike', `step 5 strike \"${it.strike}\" is not one of ${fk}'s launcher.bySendLower pieces for the send \"${send}\"`);",
      "              if (stepNames.length && !stepNames.includes(String(it.step))) err(EN, `${at}/step`, 'enders-step', `step ${it.step} is not a step of steps (${stepNames.join(', ')})`);",
      "            });",
      "          }",
      "        }",
      "        if (isObj(fv.launchPieces)) for (const pk of Object.keys(fv.launchPieces)) if (!pk.startsWith('_') && launcher.size && hasLower && !launcher.has(pk) && !Object.values(low).some((a) => Array.isArray(a) && a.includes(pk))) err(EN, `/fighters/${esc(fk)}/launchPieces/${esc(pk)}`, 'enders-piece', `\"${pk}\" is not a piece of ${fk}'s brawl.launcher pool nor of his bySendLower`);",
      "      }",
      "    }",
      "  }",
      "",
      "",
    ].join('\n');
    t = t.replace(a, () => block + a);
    fs.writeFileSync(f, crlf ? t.split('\n').join('\r\n') : t);
    console.log('xref: enders rules added');
  }
}

// ---- the cases
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const fk = Object.keys(data.fighters)[0];
  const fv = data.fighters[fk];
  const cell = Object.keys(fv.enders)[0];
  const arr = fv.enders[cell].up;
  const pieceKey = Object.keys(fv.launchPieces)[0];
  const out = [];
  const cs = (id, mutate, expect) => out.push({ id: 'combat-enders-' + id, schema: 'combat-enders.schema.json', mutate: [{ file: F, ...mutate }], expect });
  cs('valid', { set: { '/schema': 'combat.enders/1' } }, null);
  for (const k of ['schema', 'fighters']) cs('key-required-' + k, { del: ['/' + k] }, { rule: 'required', pointer: '' });
  cs('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' });
  cs('underscore-key-ok', { set: { '/_why': 'a note' } }, null);
  cs('schema-version', { set: { '/schema': 'combat.enders/2' } }, { rule: 'const', pointer: '/schema' });
  cs('step-zero', { set: { [`/fighters/${fk}/enders/${cell}/up/0/step`]: 0 } }, { rule: 'minimum', pointer: `/fighters/${fk}/enders/${cell}/up/0/step` });
  cs('step-six', { set: { [`/fighters/${fk}/enders/${cell}/up/0/step`]: 6 } }, { rule: 'maximum', pointer: `/fighters/${fk}/enders/${cell}/up/0/step` });
  cs('strike-shape', { set: { [`/fighters/${fk}/enders/${cell}/up/0/strike`]: 'Uppercut' } }, { rule: 'pattern', pointer: `/fighters/${fk}/enders/${cell}/up/0/strike` });
  cs('send-missing', { del: [`/fighters/${fk}/enders/${cell}/turned`] }, { rule: 'required', pointer: `/fighters/${fk}/enders/${cell}` });
  cs('cell-unknown', { set: { [`/fighters/${fk}/enders/feet.line`]: fv.enders[cell] } }, { rule: 'additionalProperties', pointer: `/fighters/${fk}/enders/feet.line` });
  cs('fighter-not-a-pool', { set: { '/fighters/nobody': fv } }, { rule: 'xref:enders-fighter', pointer: '/fighters/nobody' });
  cs('strike-not-in-launcher', { set: { [`/fighters/${fk}/enders/${cell}/up/0`]: { strike: 'strike.no_such_blow', step: 1 } } }, { rule: 'xref:enders-strike', pointer: `/fighters/${fk}/enders/${cell}/up/0/strike` });
  cs('step5-not-lower', { set: { [`/fighters/${fk}/enders/${cell}/up/0`]: { strike: 'strike.no_such_blow', step: 5 } } }, { rule: 'xref:enders-strike', pointer: `/fighters/${fk}/enders/${cell}/up/0/strike` });
  cs('piece-unknown', { set: { [`/fighters/${fk}/launchPieces/strike.no_such_blow`]: fv.launchPieces[pieceKey] } }, { rule: 'xref:enders-piece', pointer: `/fighters/${fk}/launchPieces/strike.no_such_blow` });
  cs('piece-path-unknown', { set: { [`/fighters/${fk}/launchPieces/${pieceKey}/path`]: 'wiggle' } }, { rule: 'enum', pointer: `/fighters/${fk}/launchPieces/${pieceKey}/path` });
  cs('piece-sends-empty', { set: { [`/fighters/${fk}/launchPieces/${pieceKey}/sends`]: [] } }, { rule: 'minItems', pointer: `/fighters/${fk}/launchPieces/${pieceKey}/sends` });
  cs('rechamber-cell-shape', { set: { [`/fighters/${fk}/rechamberCells/0`]: 'hands rise up' } }, { rule: 'pattern', pointer: `/fighters/${fk}/rechamberCells/0` });
  cs('rechamber-step-unknown', { set: { '/rechamber/fromStep': 9 } }, { rule: 'maximum', pointer: '/rechamber/fromStep' });
  cs('rechamber-ticks-negative', { set: { '/rechamber/ticks': -1 } }, { rule: 'minimum', pointer: '/rechamber/ticks' });
  cs('built-needs-from', { del: ['/built/from'] }, { rule: 'required', pointer: '/built' });
  void arr;
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i >= 0) { if (!same(c.cases[i], k)) { c.cases[i] = k; n++; } } else { c.cases.splice(Math.max(0, c.cases.length - 1), 0, k); n++; }
  }
  if (n) wj(cf, c);
  console.log(`cases: ${n} new or changed`);
}
