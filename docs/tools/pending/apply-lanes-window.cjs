// The schemas for World's lanes window (docs/world/lanes-schema-proposal.md, 2026-10-11): data/biomes/settlements.json gains enabled, foreground, pop_refs and looks, and a district's
// depth_aspect becomes depth_fill; data/biomes/stages.json gains coreCapShare; data/biomes/lanes.json is new (schema biomes.lanes/1, tools/schemas/biomes-lanes.schema.json, a line in
// map.json); tools/lib/xref-lanes.js (from docs/tools/pending/xref-lanes.js) holds the cross-references; the cases and a README row. NOT run by CI, the validator or the sim. Run once
// from the repo root, in a commit that is not mid-way through another schema script (it edits tools/schemas/*.json, tools/lib/xref-fight.js, tools/fixtures/cases.json and docs/tools/README.md):
//     node docs/tools/pending/apply-lanes-window.cjs
// It does NOT edit data/. Re-runnable (a second run changes nothing). Policy: every schema is closed except keys starting with an underscore.
// Decisions (mine, the proposal left them open): enabled, pop_refs and looks are required in settlements.json (a missing one would silently change what the loader does), foreground is
// optional (default true), coreCapShare is required like leaveFrac, a district's look stays one of Art's 8 and `looks` items are the same 8 (so a new look is a schema line in the
// same commit as the data), depth_fill is ascending (settle-range), and a district's rows must be rows of lanes.json that hold footprints (settle-lane-row).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const closed = { additionalProperties: false, patternProperties: { '^_': true } };

// =============================== settlements schema ===============================
{
  const f = 'tools/schemas/biomes-settlements.schema.json';
  const s = rj(f);
  const LOOKS = s.$defs.district.properties.look.enum;
  const props = {};
  for (const [k, v] of Object.entries(s.properties)) {
    props[k] = v;
    if (k === 'schema') {
      props.enabled = { type: 'boolean', description: 'The re-laid city (lanes, rows in depth) is used when true; false keeps the layout before the lanes window (the generator is not called).' };
      props.foreground = { type: 'boolean', description: 'Default true. false leaves row 0, the foreground row, empty: it stands between the camera and the fight until Camera frames it.' };
      props.pop_refs = Object.assign({
        type: 'object',
        required: ['near_share', 'building_share'],
        properties: {
          near_share: { type: 'number', exclusiveMinimum: 0, maximum: 1, description: 'The share of the planet\'s people within the radius that reads "populated" (the planner and the lure), as a share of the starting population.' },
          building_share: { type: 'number', exclusiveMinimum: 0, maximum: 1, description: 'A building\'s own cap for the planner\'s care term, as a share of the starting population.' },
        },
        description: 'The population references of the planner and the lure, as shares of the starting population.',
      }, closed);
    }
  }
  props.looks = {
    type: 'array',
    minItems: 1,
    uniqueItems: true,
    items: { enum: LOOKS },
    description: 'The look names in index order: every district\'s look is one of them (the cross-reference settle-look) and S.lanes carries the index.',
  };
  s.properties = props;
  const req = ['schema', 'enabled', 'pop_refs', 'pop0', 'pop_height_exp', 'shapes', 'landmarks', 'settlements', 'looks'];
  s.required = req;
  const d = s.$defs.district;
  const dp = {};
  for (const [k, v] of Object.entries(d.properties)) {
    if (k === 'depth_aspect') {
      dp.depth_fill = { type: 'array', minItems: 2, maxItems: 2, items: { type: 'number', minimum: 0.1, maximum: 1 }, description: 'The share of a lane\'s depth a footprint fills, low and high (ascending: settle-range).' };
    } else dp[k] = v;
    if (k === 'pop_density') dp.traffic = { type: 'number', minimum: 0, maximum: 1, description: 'The lane strips\' vehicle density the props will read (unused until P1).' };
  }
  d.properties = dp;
  d.required = d.required.map((k) => (k === 'depth_aspect' ? 'depth_fill' : k));
  if (!/lanes window/.test(s.description)) {
    s.description = s.description.replace(' Version field: schema.', ' The lanes window (2026-10-11): `enabled`, `foreground`, `pop_refs` and `looks` at the top, and a district\'s `depth_fill` (the share of a lane\'s depth a footprint fills) in place of `depth_aspect`; a district\'s look is one of `looks` and its rows are rows of data/biomes/lanes.json (settle-look, settle-lane-row: tools/lib/xref-lanes.js). Version field: schema.');
  }
  wj(f, s);
}

// =============================== stages schema ===============================
{
  const f = 'tools/schemas/biomes-stages.schema.json';
  const s = rj(f);
  s.properties.coreCapShare = { type: 'number', minimum: 0.05, maximum: 1, description: 'One floors hit (a brunt or a shot through a skyscraper) wears a building\'s core by at most this share of its hit points. 1 is off; the loader clamps to 0.05..1.' };
  if (!s.required.includes('coreCapShare')) s.required.push('coreCapShare');
  if (!/coreCapShare/.test(s.description)) s.description = s.description.replace(' Version field: schema.', ' coreCapShare: one floors hit wears a building\'s core by at most this share of its hit points (1 is off). Version field: schema.');
  wj(f, s);
  // the validator's fixture copy of the file (the self-test uses it in place of the live one)
  const vf = 'tools/fixtures/virtual/data/biomes/stages.json';
  if (fs.existsSync(vf)) { const v = rj(vf); if (v.coreCapShare === undefined) { v.coreCapShare = 0.5; wj(vf, v); } }
}

// =============================== lanes schema, map, xref ===============================
{
  const f = 'tools/schemas/biomes-lanes.schema.json';
  const num = (d, o = {}) => Object.assign({ type: 'number', description: d }, o);
  const schema = Object.assign({
    $schema: 'https://json-schema.org/draft/2020-12/schema',
    $id: 'meridian/biomes-lanes',
    title: 'lanes (World, the fight lanes: docs/world/fight-lanes-world.md)',
    description: 'data/biomes/lanes.json: the fight lanes of the re-laid city, in fighter heights (bh = 75 units), z positive toward the camera. The band is z_front to z_back; the lanes of kind block carry the footprints (rows 1 and 2), the scenery lanes rows 0 and 3, a street has row -1 and holds none; the strips split a street into sidewalk, kerb and carriageway. Ordering and containment are checked by tools/lib/xref-lanes.js (lanes-name, lanes-order, lanes-overlap, lanes-row, lanes-band, strip-lane, strip-order, strip-inside, strip-overlap). Version field: schema. Policy: closed except keys starting with an underscore.',
    type: 'object',
    required: ['schema', 'z_front', 'z_back', 'd_min_bh', 'lanes', 'strips'],
    properties: {
      schema: { const: 'biomes.lanes/1' },
      _about: { type: 'string' },
      z_front: num('The front of the band (above z_back: lanes-order).'),
      z_back: num('The back of the band.'),
      d_min_bh: num('The least depth, in fighter heights, a footprint may have.', { exclusiveMinimum: 0 }),
      lanes: {
        type: 'array',
        minItems: 2,
        items: Object.assign({
          type: 'object',
          required: ['name', 'kind', 'top', 'bottom', 'row'],
          properties: {
            name: { type: 'string', pattern: '^[a-z][a-z0-9_]*$', description: 'The lane\'s name (unique: lanes-name).' },
            kind: { enum: ['street', 'block', 'scenery', 'ridge'], description: 'street (no footprints, row -1), block (rows 1 and 2), scenery or ridge (rows 0 and 3).' },
            top: num('The lane\'s front edge (above bottom: lanes-order).'),
            bottom: num('The lane\'s back edge.'),
            row: { type: 'integer', minimum: -1, maximum: 3, description: '-1 for a street, else the row of footprints the lane holds (lanes-row).' },
          },
        }, closed),
        description: 'The lanes, front to back (they may not overlap: lanes-overlap).',
      },
      strips: {
        type: 'array',
        items: Object.assign({
          type: 'object',
          required: ['lane', 'kind', 'top', 'bottom'],
          properties: {
            lane: { type: 'string', pattern: '^[a-z][a-z0-9_]*$', description: 'The street lane this strip is in (strip-lane).' },
            kind: { enum: ['sidewalk', 'kerb', 'carriageway'] },
            top: num('The strip\'s front edge (above bottom, inside its lane: strip-order, strip-inside).'),
            bottom: num('The strip\'s back edge.'),
          },
        }, closed),
        description: 'The strips of the streets (the strips of one lane do not overlap: strip-overlap).',
      },
    },
  }, closed);
  wj(f, schema);
  const mf = 'tools/schemas/map.json';
  const m = rj(mf);
  if (!m.rules.some((r) => r.match === 'data/biomes/lanes.json')) {
    const i = m.rules.findIndex((r) => r.match === 'data/biomes/settlements.json');
    m.rules.splice(i < 0 ? m.rules.length : i + 1, 0, { match: 'data/biomes/lanes.json', schema: 'biomes-lanes.schema.json' });
    wj(mf, m);
  }
  fs.copyFileSync('docs/tools/pending/xref-lanes.js', 'tools/lib/xref-lanes.js');
  const xf = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(xf, 'utf8');
  if (!t.includes("require('./xref-lanes')")) {
    const a = "  require('./xref-brawl-cues').xrefBrawlCues({ get, err, esc, isObj });\n";
    if (!t.includes(a)) throw new Error('lanes xref anchor');
    t = t.replace(a, () => a + "  require('./xref-lanes').xrefLanes({ get, err, esc, isObj });\n");
  }
  if (t.includes("['width_bh', 'depth_aspect', 'gap_bh', 'block_bh', 'avenue_bh']")) t = t.replace("['width_bh', 'depth_aspect', 'gap_bh', 'block_bh', 'avenue_bh']", "['width_bh', 'depth_fill', 'gap_bh', 'block_bh', 'avenue_bh']");
  fs.writeFileSync(xf, t);
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const out = [];
  const add = (schema, file, id, mutate, expect) => out.push({ id, schema, mutate: [Object.assign({ file }, mutate)], expect });
  // ---- settlements.json
  const SS = 'biomes-settlements.schema.json', SF = 'data/biomes/settlements.json';
  const sc = (id, mutate, expect) => add(SS, SF, 'settle-lanes-' + id, mutate, expect);
  const D0 = '/settlements/0/districts/0';
  sc('enabled-required', { del: ['/enabled'] }, { rule: 'required', pointer: '' });
  sc('enabled-type', { set: { '/enabled': 'yes' } }, { rule: 'type', pointer: '/enabled' });
  sc('enabled-false-ok', { set: { '/enabled': false } }, null);
  sc('foreground-type', { set: { '/foreground': 1 } }, { rule: 'type', pointer: '/foreground' });
  sc('foreground-absent-ok', { del: ['/foreground'] }, null);
  sc('foreground-true-ok', { set: { '/foreground': true } }, null);
  sc('pop-refs-required', { del: ['/pop_refs'] }, { rule: 'required', pointer: '' });
  sc('pop-refs-type', { set: { '/pop_refs': 0.09 } }, { rule: 'type', pointer: '/pop_refs' });
  sc('pop-refs-unknown-key', { set: { '/pop_refs/far_share': 0.5 } }, { rule: 'additionalProperties', pointer: '/pop_refs/far_share' });
  sc('pop-refs-near-required', { del: ['/pop_refs/near_share'] }, { rule: 'required', pointer: '/pop_refs' });
  sc('pop-refs-building-required', { del: ['/pop_refs/building_share'] }, { rule: 'required', pointer: '/pop_refs' });
  sc('pop-refs-near-zero', { set: { '/pop_refs/near_share': 0 } }, { rule: 'exclusiveMinimum', pointer: '/pop_refs/near_share' });
  sc('pop-refs-near-above-one', { set: { '/pop_refs/near_share': 1.01 } }, { rule: 'maximum', pointer: '/pop_refs/near_share' });
  sc('pop-refs-near-one-ok', { set: { '/pop_refs/near_share': 1 } }, null);
  sc('pop-refs-near-type', { set: { '/pop_refs/near_share': 'some' } }, { rule: 'type', pointer: '/pop_refs/near_share' });
  sc('pop-refs-building-zero', { set: { '/pop_refs/building_share': 0 } }, { rule: 'exclusiveMinimum', pointer: '/pop_refs/building_share' });
  sc('pop-refs-building-above-one', { set: { '/pop_refs/building_share': 2 } }, { rule: 'maximum', pointer: '/pop_refs/building_share' });
  sc('pop-refs-building-type', { set: { '/pop_refs/building_share': [0.02] } }, { rule: 'type', pointer: '/pop_refs/building_share' });
  sc('looks-required', { del: ['/looks'] }, { rule: 'required', pointer: '' });
  sc('looks-type', { set: { '/looks': 'harbour' } }, { rule: 'type', pointer: '/looks' });
  sc('looks-empty', { set: { '/looks': [] } }, { rule: 'minItems', pointer: '/looks' });
  sc('looks-duplicate', { set: { '/looks': ['harbour', 'harbour'] } }, { rule: 'uniqueItems', pointer: '/looks/1' });
  sc('looks-unknown-look', { set: { '/looks/0': 'slums' } }, { rule: 'enum', pointer: '/looks/0' });
  sc('looks-empty-string', { set: { '/looks/0': '' } }, { rule: 'enum', pointer: '/looks/0' });
  sc('looks-one-leaves-the-others', { set: { '/looks': ['harbour'] } }, { rule: 'xref:settle-look', pointer: '/settlements/0/districts/1/look' });
  sc('district-look-not-in-looks', { set: { '/looks': ['harbour', 'village_harbour', 'suburb', 'industrial', 'mid_rise', 'downtown', 'village_workshop'] } }, { rule: 'xref:settle-look', pointer: '/settlements/3/districts/0/look' });
  sc('looks-reordered-ok', { set: { '/looks': ['downtown', 'mid_rise', 'industrial', 'suburb', 'village_hill', 'village_workshop', 'village_harbour', 'harbour'] } }, null);
  sc('depth-fill-required', { del: [D0 + '/depth_fill'] }, { rule: 'required', pointer: D0 });
  sc('depth-fill-type', { set: { [D0 + '/depth_fill']: 0.5 } }, { rule: 'type', pointer: D0 + '/depth_fill' });
  sc('depth-fill-too-short', { set: { [D0 + '/depth_fill']: [0.5] } }, { rule: 'minItems', pointer: D0 + '/depth_fill' });
  sc('depth-fill-too-long', { set: { [D0 + '/depth_fill']: [0.4, 0.6, 0.8] } }, { rule: 'maxItems', pointer: D0 + '/depth_fill' });
  sc('depth-fill-item-type', { set: { [D0 + '/depth_fill/0']: 'half' } }, { rule: 'type', pointer: D0 + '/depth_fill/0' });
  sc('depth-fill-below-min', { set: { [D0 + '/depth_fill']: [0.05, 0.6] } }, { rule: 'minimum', pointer: D0 + '/depth_fill/0' });
  sc('depth-fill-above-one', { set: { [D0 + '/depth_fill']: [0.5, 1.2] } }, { rule: 'maximum', pointer: D0 + '/depth_fill/1' });
  sc('depth-fill-descending', { set: { [D0 + '/depth_fill']: [0.8, 0.4] } }, { rule: 'xref:settle-range', pointer: D0 + '/depth_fill' });
  sc('depth-fill-equal-ok', { set: { [D0 + '/depth_fill']: [0.6, 0.6] } }, null);
  sc('depth-fill-edges-ok', { set: { [D0 + '/depth_fill']: [0.1, 1] } }, null);
  sc('depth-aspect-gone', { set: { [D0 + '/depth_aspect']: [1, 1.5] } }, { rule: 'additionalProperties', pointer: D0 + '/depth_aspect' });
  sc('traffic-type', { set: { [D0 + '/traffic']: 'busy' } }, { rule: 'type', pointer: D0 + '/traffic' });
  sc('traffic-negative', { set: { [D0 + '/traffic']: -0.1 } }, { rule: 'minimum', pointer: D0 + '/traffic' });
  sc('traffic-above-one', { set: { [D0 + '/traffic']: 1.5 } }, { rule: 'maximum', pointer: D0 + '/traffic' });
  sc('traffic-edges-ok', { set: { [D0 + '/traffic']: 0 } }, null);
  sc('traffic-one-ok', { set: { [D0 + '/traffic']: 1 } }, null);
  out.push({
    id: 'settle-lanes-row-without-a-lane', schema: SS,
    mutate: [{ file: 'data/biomes/lanes.json', del: ['/lanes/5'] }],
    expect: { rule: 'xref:settle-lane-row', pointer: '/settlements/1/districts/0/rows', file: SF },
  });
  out.push({
    id: 'settle-lanes-row-without-a-lane-foreground', schema: SS,
    mutate: [{ file: 'data/biomes/lanes.json', del: ['/lanes/0'] }],
    expect: { rule: 'xref:settle-lane-row', pointer: D0 + '/rows', file: SF },
  });
  // ---- stages.json
  const TS = 'biomes-stages.schema.json', TF = 'data/biomes/stages.json';
  const tc = (id, mutate, expect) => add(TS, TF, 'biomes-stages-core-cap-' + id, mutate, expect);
  tc('required', { del: ['/coreCapShare'] }, { rule: 'required', pointer: '' });
  tc('type', { set: { '/coreCapShare': 'half' } }, { rule: 'type', pointer: '/coreCapShare' });
  tc('below-limit', { set: { '/coreCapShare': 0.04 } }, { rule: 'minimum', pointer: '/coreCapShare' });
  tc('zero', { set: { '/coreCapShare': 0 } }, { rule: 'minimum', pointer: '/coreCapShare' });
  tc('above-one', { set: { '/coreCapShare': 1.1 } }, { rule: 'maximum', pointer: '/coreCapShare' });
  tc('limit-ok', { set: { '/coreCapShare': 0.05 } }, null);
  tc('off-ok', { set: { '/coreCapShare': 1 } }, null);
  tc('first-value-ok', { set: { '/coreCapShare': 0.5 } }, null);
  // ---- lanes.json
  const LS = 'biomes-lanes.schema.json', LF = 'data/biomes/lanes.json';
  const lc = (id, mutate, expect) => add(LS, LF, 'lanes-' + id, mutate, expect);
  lc('valid', { set: { '/z_front': 5 } }, null);
  for (const k of ['schema', 'z_front', 'z_back', 'd_min_bh', 'lanes', 'strips']) lc('key-required-' + k.replace(/_/g, '-'), { del: ['/' + k] }, { rule: 'required', pointer: '' });
  lc('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' });
  lc('underscore-key-ok', { set: { '/_why': 'a note' } }, null);
  lc('about-type', { set: { '/_about': 5 } }, { rule: 'type', pointer: '/_about' });
  lc('schema-version', { set: { '/schema': 'biomes.lanes/2' } }, { rule: 'const', pointer: '/schema' });
  lc('z-front-type', { set: { '/z_front': 'near' } }, { rule: 'type', pointer: '/z_front' });
  lc('z-back-type', { set: { '/z_back': 'far' } }, { rule: 'type', pointer: '/z_back' });
  lc('d-min-zero', { set: { '/d_min_bh': 0 } }, { rule: 'exclusiveMinimum', pointer: '/d_min_bh' });
  lc('d-min-negative', { set: { '/d_min_bh': -1 } }, { rule: 'exclusiveMinimum', pointer: '/d_min_bh' });
  lc('d-min-type', { set: { '/d_min_bh': 'small' } }, { rule: 'type', pointer: '/d_min_bh' });
  lc('lanes-type', { set: { '/lanes': 'many' } }, { rule: 'type', pointer: '/lanes' });
  lc('lanes-too-few', { set: { '/lanes': [{ name: 'only', kind: 'street', top: 5, bottom: -4, row: -1 }], '/strips': [] } }, { rule: 'minItems', pointer: '/lanes' });
  lc('lane-type', { set: { '/lanes/1': 'street' } }, { rule: 'type', pointer: '/lanes/1' });
  lc('lane-unknown-key', { set: { '/lanes/1/width': 9 } }, { rule: 'additionalProperties', pointer: '/lanes/1/width' });
  lc('lane-underscore-key-ok', { set: { '/lanes/1/_note': 'the front street' } }, null);
  for (const k of ['name', 'kind', 'top', 'bottom', 'row']) lc('lane-' + k + '-required', { del: ['/lanes/1/' + k] }, { rule: 'required', pointer: '/lanes/1' });
  lc('lane-name-type', { set: { '/lanes/1/name': 5 } }, { rule: 'type', pointer: '/lanes/1/name' });
  lc('lane-name-shape', { set: { '/lanes/1/name': 'Front Street' } }, { rule: 'pattern', pointer: '/lanes/1/name' });
  lc('lane-name-empty', { set: { '/lanes/1/name': '' } }, { rule: 'pattern', pointer: '/lanes/1/name' });
  lc('lane-kind-unknown', { set: { '/lanes/1/kind': 'plaza' } }, { rule: 'enum', pointer: '/lanes/1/kind' });
  lc('lane-top-type', { set: { '/lanes/1/top': 'high' } }, { rule: 'type', pointer: '/lanes/1/top' });
  lc('lane-bottom-type', { set: { '/lanes/1/bottom': 'low' } }, { rule: 'type', pointer: '/lanes/1/bottom' });
  lc('lane-row-below', { set: { '/lanes/1/row': -2 } }, { rule: 'minimum', pointer: '/lanes/1/row' });
  lc('lane-row-above', { set: { '/lanes/2/row': 4 } }, { rule: 'maximum', pointer: '/lanes/2/row' });
  lc('lane-row-integer', { set: { '/lanes/2/row': 1.5 } }, { rule: 'type', pointer: '/lanes/2/row' });
  lc('lane-kind-ridge-ok', { set: { '/lanes/5/kind': 'ridge' } }, null);
  lc('strips-type', { set: { '/strips': {} } }, { rule: 'type', pointer: '/strips' });
  lc('strips-empty-ok', { set: { '/strips': [] } }, null);
  lc('strip-type', { set: { '/strips/0': 'sidewalk' } }, { rule: 'type', pointer: '/strips/0' });
  lc('strip-unknown-key', { set: { '/strips/0/width': 1 } }, { rule: 'additionalProperties', pointer: '/strips/0/width' });
  for (const k of ['lane', 'kind', 'top', 'bottom']) lc('strip-' + k + '-required', { del: ['/strips/0/' + k] }, { rule: 'required', pointer: '/strips/0' });
  lc('strip-lane-shape', { set: { '/strips/0/lane': 'Front Street' } }, { rule: 'pattern', pointer: '/strips/0/lane' });
  lc('strip-kind-unknown', { set: { '/strips/0/kind': 'gutter' } }, { rule: 'enum', pointer: '/strips/0/kind' });
  lc('strip-top-type', { set: { '/strips/0/top': 'high' } }, { rule: 'type', pointer: '/strips/0/top' });
  lc('strip-bottom-type', { set: { '/strips/0/bottom': 'low' } }, { rule: 'type', pointer: '/strips/0/bottom' });
  lc('z-front-below-back', { set: { '/z_front': -30 } }, { rule: 'xref:lanes-order', pointer: '/z_front' });
  lc('z-front-equals-back', { set: { '/z_front': -27 } }, { rule: 'xref:lanes-order', pointer: '/z_front' });
  lc('lane-top-below-bottom', { set: { '/lanes/2/top': -12, '/lanes/2/bottom': -4 } }, { rule: 'xref:lanes-order', pointer: '/lanes/2/top' });
  lc('lane-top-equals-bottom', { set: { '/lanes/2/top': -8, '/lanes/2/bottom': -8 } }, { rule: 'xref:lanes-order', pointer: '/lanes/2/top' });
  lc('lane-name-duplicate', { set: { '/lanes/2/name': 'front_street' } }, { rule: 'xref:lanes-name', pointer: '/lanes/2/name' });
  lc('lanes-overlap', { set: { '/lanes/2/top': -2 } }, { rule: 'xref:lanes-overlap', pointer: '/lanes/2/top' });
  lc('lanes-touching-ok', { set: { '/lanes/2/top': -4 } }, null);
  lc('lanes-gap-ok', { set: { '/lanes/0/bottom': 8 } }, null);
  lc('lanes-out-of-order', { set: { '/lanes/0/top': 3, '/lanes/0/bottom': 2 } }, { rule: 'xref:lanes-overlap', pointer: '/lanes/1/top' });
  lc('street-row', { set: { '/lanes/1/row': 0 } }, { rule: 'xref:lanes-row', pointer: '/lanes/1/row' });
  lc('block-row', { set: { '/lanes/2/row': 3 } }, { rule: 'xref:lanes-row', pointer: '/lanes/2/row' });
  lc('block-street-row', { set: { '/lanes/2/row': -1 } }, { rule: 'xref:lanes-row', pointer: '/lanes/2/row' });
  lc('scenery-row', { set: { '/lanes/0/row': 2 } }, { rule: 'xref:lanes-row', pointer: '/lanes/0/row' });
  lc('row-duplicate', { set: { '/lanes/4/row': 1 } }, { rule: 'xref:lanes-row', pointer: '/lanes/4/row' });
  lc('block-rows-swapped-ok', { set: { '/lanes/2/row': 2, '/lanes/4/row': 1 } }, null);
  lc('band-street-outside', { set: { '/lanes/1/top': 6 } }, { rule: 'xref:lanes-band', pointer: '/lanes/1' });
  lc('band-block-outside', { set: { '/lanes/4/bottom': -28 } }, { rule: 'xref:lanes-band', pointer: '/lanes/4' });
  lc('band-scenery-outside-ok', { set: { '/lanes/5/bottom': -60 } }, null);
  lc('strip-lane-unknown', { set: { '/strips/0/lane': 'nowhere' } }, { rule: 'xref:strip-lane', pointer: '/strips/0/lane' });
  lc('strip-lane-not-street', { set: { '/strips/0/lane': 'block_1' } }, { rule: 'xref:strip-lane', pointer: '/strips/0/lane' });
  lc('strip-order', { set: { '/strips/0/top': 4, '/strips/0/bottom': 5 } }, { rule: 'xref:strip-order', pointer: '/strips/0/top' });
  lc('strip-outside-lane', { set: { '/strips/0/top': 6 } }, { rule: 'xref:strip-inside', pointer: '/strips/0/top' });
  lc('strip-below-lane', { set: { '/strips/4/bottom': -5 } }, { rule: 'xref:strip-inside', pointer: '/strips/4/top' });
  lc('strip-overlap', { set: { '/strips/1/top': 4.5 } }, { rule: 'xref:strip-overlap', pointer: '/strips/1/top' });
  lc('strip-touching-ok', { set: { '/strips/1/top': 4 } }, null);
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`lanes window schemas applied (${n} new or changed cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`lanes-overlap`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`stages-order`'));
    if (i < 0) throw new Error('lanes README anchor');
    lines.splice(i + 1, 0, '| `lanes-name`, `lanes-order`, `lanes-overlap`, `lanes-row`, `lanes-band`, `strip-lane`, `strip-order`, `strip-inside`, `strip-overlap`, `settle-look`, `settle-lane-row` | data/biomes/lanes.json: lane names are unique, z_front is above z_back and each top above its bottom, lanes run front to back without overlapping (a gap is fine), a street has row -1, a block row 1 or 2, scenery and ridge row 0 or 3 and no row is used twice, street and block lanes are inside the band, a strip names a street lane and lies inside it without overlapping its neighbours. data/biomes/settlements.json: every district look is one of `looks`, every district row is the row of a lane that holds footprints |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}
