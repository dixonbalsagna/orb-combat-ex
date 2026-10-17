// The schema for Art's data/art/city-looks.json (the city's towers up close: palettes, facade types, the base and crown, the districts' weights; docs/art/city-facades.md).
// Run once from the repo root, in the commit that lands the file (after the commit of Tools' batch 2 and VFX's apply, which also touch map.json and cases.json):
//     node docs/tools/pending/apply-art-city-looks.cjs
// It writes tools/schemas/art-city-looks.schema.json, its rule in tools/schemas/map.json (after art/sky.json), the cross-references in tools/lib/xref-art.js and the cases in
// tools/fixtures/cases.json. It refuses until the file is in the tree. Re-runnable (a second run changes nothing). Not run by CI or the validator.
// Policy of the schema: closed except keys starting with an underscore; `note` is Art's one string beside the numbers. Version field: version.
// Cross-references (city-looks-*): a look's ids are unique (id); a district's look is a key of looks (district-look); its facade weights name facades (facade-weight) and its tint weights name
// tints of that look (tint-weight); each set of weights sums to 1 within 0.01 (weights-sum); a tint's measured glass-against-wall luminance gaps are within the file's budget (budget).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const F = 'data/art/city-looks.json';
if (!fs.existsSync(F)) { console.error(`${F} is not in the tree yet: run this in the commit that lands it`); process.exit(1); }
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const HEX = { type: 'string', pattern: '^#[0-9a-f]{6}$' };
const hex = (d) => ({ ...HEX, description: d });
const num = (d, min, max, ex) => ({ type: 'number', ...(ex ? { exclusiveMinimum: min } : { minimum: min }), ...(max === undefined ? {} : { maximum: max }), description: d });
const str = (d) => ({ type: 'string', minLength: 1, description: d });
const obj = (required, properties, description) => ({ type: 'object', required, properties, description, ...closed });
const ID = '^[a-z][a-z0-9_]*$';

// ---- the schema
{
  const f = 'tools/schemas/art-city-looks.schema.json';
  const look = obj(['id', 'name', 'wall', 'glass', 'trim', 'spandrel', 'fin', 'oklch', 'measured'], {
    id: { type: 'string', pattern: ID, description: 'The tint\'s id (unique within its look: city-looks-id).' },
    name: str('The tint\'s name.'),
    wall: obj(['light', 'mid', 'shadow'], { light: hex('The wall in light.'), mid: hex('The wall\'s mid tone.'), shadow: hex('The wall in shadow.') }, 'The wall\'s three tones.'),
    glass: obj(['dark', 'bright'], { dark: hex('The dark glass.'), bright: hex('The bright glass.') }, 'The glass.'),
    trim: hex('The trim.'), spandrel: hex('The spandrel band.'), fin: hex('The fin colour.'),
    oklch: obj(['wall', 'glass'], {
      wall: { type: 'array', minItems: 2, maxItems: 2, items: { type: 'number', minimum: 0, maximum: 360 }, description: 'Hue (degrees) and chroma of the wall, in OKLCH.' },
      glass: { type: 'array', minItems: 2, maxItems: 2, items: { type: 'number', minimum: 0, maximum: 360 }, description: 'Hue (degrees) and chroma of the glass.' }
    }, 'The tint in OKLCH: hue then chroma.'),
    measured: obj(['glass_dark_vs_wall_mid', 'glass_bright_vs_wall_mid', 'hue_gap_wall_to_glass_deg'], {
      glass_dark_vs_wall_mid: num('Relative luminance gap of the dark glass to the wall\'s mid tone (at most the file\'s budget: city-looks-budget).', 0, 1),
      glass_bright_vs_wall_mid: num('The same for the bright glass.', 0, 1),
      hue_gap_wall_to_glass_deg: num('The hue gap between wall and glass, degrees.', 0, 180)
    }, 'What Art measured.')
  }, 'One tint of a look.');
  const facade = obj(['name', 'what', 'fits'], {
    name: str('The facade type\'s name.'), what: str('What it looks like.'), fits: str('Where it is used.'),
    pane_h: num('A pane\'s height, a share of the floor.', 0, 1), pane_w: num('A pane\'s width, a share of the bay.', 0, 1), pier_w: num('A pier\'s width, a share of the bay.', 0, 1),
    spandrel: obj(['h', 'lum_offset'], { h: num('The spandrel\'s height, a share of the floor.', 0, 1), lum_offset: { type: 'number', minimum: -0.5, maximum: 0.5, description: 'Its luminance offset from the wall.' } }, 'The band under each row.'),
    fin: obj(['w', 'pitch', 'lum_offset', 'sun_side_offset'], { w: num('A fin\'s width, a share of the bay.', 0, 1), pitch: num('The distance between fins, a share of the bay.', 0, 1), lum_offset: { type: 'number', minimum: -0.5, maximum: 0.5, description: 'The fin\'s luminance offset from the wall.' }, sun_side_offset: { type: 'number', minimum: -0.5, maximum: 0.5, description: 'The extra offset on the sun side.' } }, 'The projecting fins.')
  }, 'One facade type.');
  const weights = (d) => ({ type: 'object', minProperties: 1, propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: { type: 'number', minimum: 0, maximum: 1 }, patternProperties: { '^_': true }, description: d });
  const district = obj(['look', 'facade_weights', 'tint_weights', 'rule'], {
    look: { type: 'string', pattern: ID, description: 'The look this district draws its tints from (a key of looks: city-looks-district-look).' },
    facade_weights: weights('Facade id to its share (each a facade of facades; the shares sum to 1: city-looks-facade-weight, city-looks-weights-sum).'),
    tint_weights: weights('Tint id to its share (each a tint of the look; the shares sum to 1: city-looks-tint-weight, city-looks-weights-sum).'),
    rule: str('In words: which facade goes on which tower.')
  }, 'One district of the city.');
  const s = {
    $schema: 'https://json-schema.org/draft/2020-12/schema', $id: 'meridian/art-city-looks', title: 'art city looks (version 1)',
    description: 'data/art/city-looks.json: the city\'s towers up close (docs/art/city-facades.md): the palettes of each look, the facade types, the base and crown and the districts\' weights. Rendering reads it for the towers\' faces; the sim never does. On downtown and mid_rise a pane may differ from its wall by at most `budget` of relative luminance. Version field: version. Policy: closed except keys starting with an underscore; `note` is Art\'s one string beside the numbers. Cross-references in tools/lib/xref-art.js (city-looks-id, city-looks-district-look, city-looks-facade-weight, city-looks-tint-weight, city-looks-weights-sum, city-looks-budget).',
    type: 'object',
    required: ['version', 'budget', 'glass_step', 'looks', 'facades', 'base_and_crown', 'districts'],
    properties: {
      version: { const: 1 },
      note: { type: 'string', description: 'Art\'s note on the file.' },
      budget: num('The most a pane may differ from its wall, relative luminance (render/core/look.gd PATTERN_BUDGET).', 0, 0.5, true),
      glass_step: num('The step between the dark and the bright glass, relative luminance.', 0, 0.5, true),
      looks: { type: 'object', minProperties: 1, propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: { type: 'array', minItems: 1, items: look }, patternProperties: { '^_': true }, description: 'Look id to its tints.' },
      facades: { type: 'object', minProperties: 1, propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: facade, patternProperties: { '^_': true }, description: 'Facade id to its type.' },
      base_and_crown: obj(['base', 'crown'], {
        base: obj(['floors', 'note', 'wall_lum_offset'], { floors: num('The lobby storey\'s height in floors.', 0, 10), note: str('Its look in words.'), wall_lum_offset: { type: 'number', minimum: -0.5, maximum: 0.5, description: 'Its luminance offset from the wall.' } }, 'The tall lobby storey.'),
        crown: obj(['floors', 'note', 'setback', 'cornice_lum_offset'], { floors: num('The crown\'s height in floors.', 0, 10), note: str('Its look in words.'), setback: num('The setback on each side, a share of the width.', 0, 0.5), cornice_lum_offset: { type: 'number', minimum: -0.5, maximum: 0.5, description: 'The cornice\'s luminance offset from the wall.' } }, 'The set-back top storeys.')
      }, 'The base and the crown of a tower.'),
      districts: { type: 'object', minProperties: 1, propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: district, patternProperties: { '^_': true }, description: 'District id to its look and weights.' }
    },
    ...closed
  };
  if (fs.existsSync(f) && same(rj(f), s)) console.log('schema: already');
  else { wj(f, s); console.log('schema: written'); }
}

// ---- the map rule, after art/sky.json
{
  const mf = 'tools/schemas/map.json';
  const m = rj(mf);
  if (m.rules.some((r) => r.match === F)) console.log('map: already');
  else {
    const i = m.rules.findIndex((r) => r.match === 'data/art/sky.json');
    m.rules.splice(i < 0 ? m.rules.length : i + 1, 0, { match: F, schema: 'art-city-looks.schema.json' });
    wj(mf, m);
    console.log('map: rule added');
  }
}

// ---- the cross-references
{
  const f = 'tools/lib/xref-art.js';
  let t = fs.readFileSync(f, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  if (t.includes('city-looks-district-look')) console.log('xref: already');
  else {
    const rep = (a, b) => { if (!t.includes(a)) throw new Error('anchor: ' + a.slice(0, 70)); t = t.replace(a, () => b); };
    rep("function xrefArt({ get, err, esc, isObj }) {\n  xrefUiColour({ get, err, esc, isObj });\n", "function xrefArt({ get, err, esc, isObj }) {\n  xrefUiColour({ get, err, esc, isObj });\n  xrefCityLooks({ get, err, esc, isObj });\n");
    rep("module.exports = { xrefArt, xrefUiColour };",
      "// data/art/city-looks.json: a look's tint ids are unique; a district's look exists, its weights name facades and the look's tints and each set sums to 1; a tint's glass stays within the budget of its wall\n" +
      "function xrefCityLooks({ get, err, esc, isObj }) {\n" +
      "  const CL = 'data/art/city-looks.json';\n" +
      "  const d = get(CL);\n" +
      "  if (!isObj(d)) return;\n" +
      "  const looks = isObj(d.looks) ? d.looks : {};\n" +
      "  const tints = {};\n" +
      "  for (const [lk, arr] of Object.entries(looks)) {\n" +
      "    if (lk.startsWith('_') || !Array.isArray(arr)) continue;\n" +
      "    const ids = new Set();\n" +
      "    arr.forEach((tn, i) => {\n" +
      "      if (!isObj(tn)) return;\n" +
      "      if (typeof tn.id === 'string') { if (ids.has(tn.id)) err(CL, `/looks/${esc(lk)}/${i}/id`, 'city-looks-id', `tint id \"${tn.id}\" is used twice in \"${lk}\"`); ids.add(tn.id); }\n" +
      "      if (isObj(tn.measured) && typeof d.budget === 'number') for (const k of ['glass_dark_vs_wall_mid', 'glass_bright_vs_wall_mid']) {\n" +
      "        if (typeof tn.measured[k] === 'number' && tn.measured[k] > d.budget) err(CL, `/looks/${esc(lk)}/${i}/measured/${k}`, 'city-looks-budget', `${k} ${tn.measured[k]} is above the budget ${d.budget}: a pane may differ from its wall by at most the budget`);\n" +
      "      }\n" +
      "    });\n" +
      "    tints[lk] = ids;\n" +
      "  }\n" +
      "  const facades = isObj(d.facades) ? new Set(Object.keys(d.facades).filter((k) => !k.startsWith('_'))) : new Set();\n" +
      "  const sum = (o) => Object.entries(o).filter(([k, v]) => !k.startsWith('_') && typeof v === 'number').reduce((a, [, v]) => a + v, 0);\n" +
      "  for (const [dn, dist] of Object.entries(isObj(d.districts) ? d.districts : {})) {\n" +
      "    if (dn.startsWith('_') || !isObj(dist)) continue;\n" +
      "    const P = `/districts/${esc(dn)}`;\n" +
      "    const known = typeof dist.look === 'string' ? tints[dist.look] : undefined;\n" +
      "    if (typeof dist.look === 'string' && !known) err(CL, `${P}/look`, 'city-looks-district-look', `look \"${dist.look}\" is not a key of looks (${Object.keys(looks).filter((k) => !k.startsWith('_')).join(', ')})`);\n" +
      "    if (isObj(dist.facade_weights)) {\n" +
      "      for (const k of Object.keys(dist.facade_weights)) if (!k.startsWith('_') && !facades.has(k)) err(CL, `${P}/facade_weights/${esc(k)}`, 'city-looks-facade-weight', `\"${k}\" is not a facade of facades (${[...facades].join(', ')})`);\n" +
      "      if (Math.abs(sum(dist.facade_weights) - 1) > 0.01) err(CL, `${P}/facade_weights`, 'city-looks-weights-sum', `the facade weights sum to ${Math.round(sum(dist.facade_weights) * 1000) / 1000}, not 1`);\n" +
      "    }\n" +
      "    if (isObj(dist.tint_weights)) {\n" +
      "      if (known) for (const k of Object.keys(dist.tint_weights)) if (!k.startsWith('_') && !known.has(k)) err(CL, `${P}/tint_weights/${esc(k)}`, 'city-looks-tint-weight', `\"${k}\" is not a tint of the look \"${dist.look}\" (${[...known].join(', ')})`);\n" +
      "      if (Math.abs(sum(dist.tint_weights) - 1) > 0.01) err(CL, `${P}/tint_weights`, 'city-looks-weights-sum', `the tint weights sum to ${Math.round(sum(dist.tint_weights) * 1000) / 1000}, not 1`);\n" +
      "    }\n" +
      "  }\n" +
      "}\n\n" +
      "module.exports = { xrefArt, xrefUiColour, xrefCityLooks };");
    fs.writeFileSync(f, crlf ? t.replace(/\n/g, '\r\n') : t);
    console.log('xref: city looks added');
  }
}

// ---- the cases
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const data = rj(F);
  const first = Object.keys(data.looks)[0];
  const dist = Object.keys(data.districts)[0];
  const tintKey = Object.keys(data.districts[dist].tint_weights)[0];
  const facKey = Object.keys(data.districts[dist].facade_weights)[0];
  const out = [];
  const cs = (id, mutate, expect) => out.push({ id: 'art-city-looks-' + id, schema: 'art-city-looks.schema.json', mutate: [{ file: F, ...mutate }], expect });
  cs('valid', { set: { '/version': 1 } }, null);
  for (const k of ['version', 'budget', 'glass_step', 'looks', 'facades', 'base_and_crown', 'districts']) cs('key-required-' + k.replace(/_/g, '-'), { del: ['/' + k] }, { rule: 'required', pointer: '' });
  cs('schema-version', { set: { '/version': 2 } }, { rule: 'const', pointer: '/version' });
  cs('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' });
  cs('underscore-key-ok', { set: { '/_why': 'a note' } }, null);
  cs('note-type', { set: { '/note': 5 } }, { rule: 'type', pointer: '/note' });
  cs('budget-zero', { set: { '/budget': 0 } }, { rule: 'exclusiveMinimum', pointer: '/budget' });
  cs('budget-type', { set: { '/budget': 'tight' } }, { rule: 'type', pointer: '/budget' });
  cs('tint-wall-not-hex', { set: { [`/looks/${first}/0/wall/mid`]: 'grey' } }, { rule: 'pattern', pointer: `/looks/${first}/0/wall/mid` });
  cs('tint-glass-required', { del: [`/looks/${first}/0/glass/dark`] }, { rule: 'required', pointer: `/looks/${first}/0/glass` });
  cs('tint-unknown-key', { set: { [`/looks/${first}/0/extra`]: 1 } }, { rule: 'additionalProperties', pointer: `/looks/${first}/0/extra` });
  cs('tint-hue-too-big', { set: { [`/looks/${first}/0/oklch/wall`]: [400, 0.02] } }, { rule: 'maximum', pointer: `/looks/${first}/0/oklch/wall/0` });
  cs('tint-id-twice', { set: { [`/looks/${first}/1/id`]: data.looks[first][0].id } }, { rule: 'xref:city-looks-id', pointer: `/looks/${first}/1/id` });
  cs('tint-over-budget', { set: { [`/looks/${first}/0/measured/glass_dark_vs_wall_mid`]: 0.2 } }, { rule: 'xref:city-looks-budget', pointer: `/looks/${first}/0/measured/glass_dark_vs_wall_mid` });
  cs('facade-required', { del: [`/facades/${facKey}/what`] }, { rule: 'required', pointer: `/facades/${facKey}` });
  cs('facade-unknown-key', { set: { [`/facades/${facKey}/extra`]: 1 } }, { rule: 'additionalProperties', pointer: `/facades/${facKey}/extra` });
  cs('crown-setback-too-big', { set: { '/base_and_crown/crown/setback': 0.9 } }, { rule: 'maximum', pointer: '/base_and_crown/crown/setback' });
  cs('district-look-unknown', { set: { [`/districts/${dist}/look`]: 'suburb' } }, { rule: 'xref:city-looks-district-look', pointer: `/districts/${dist}/look` });
  cs('district-facade-unknown', { set: { [`/districts/${dist}/facade_weights/spire`]: 0.1 } }, { rule: 'xref:city-looks-facade-weight', pointer: `/districts/${dist}/facade_weights/spire` });
  cs('district-tint-unknown', { set: { [`/districts/${dist}/tint_weights/neon`]: 0.1 } }, { rule: 'xref:city-looks-tint-weight', pointer: `/districts/${dist}/tint_weights/neon` });
  cs('district-weights-sum', { set: { [`/districts/${dist}/tint_weights/${tintKey}`]: 0.9 } }, { rule: 'xref:city-looks-weights-sum', pointer: `/districts/${dist}/tint_weights` });
  cs('district-facade-weights-sum', { set: { [`/districts/${dist}/facade_weights/${facKey}`]: 0.9 } }, { rule: 'xref:city-looks-weights-sum', pointer: `/districts/${dist}/facade_weights` });
  cs('district-weight-above-one', { set: { [`/districts/${dist}/tint_weights/${tintKey}`]: 1.5 } }, { rule: 'maximum', pointer: `/districts/${dist}/tint_weights/${tintKey}` });
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  if (n) wj(cf, c);
  console.log(`cases: ${n} new or changed`);
}
