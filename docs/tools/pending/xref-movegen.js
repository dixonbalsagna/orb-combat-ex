'use strict';
// Cross-reference rules for the generated movesets (docs/combat/moveset-generator.md; docs/combat/pending/movegen/README.md sections 4 and 5):
// data/combat/parts.json, identity.json, cells.json and data/combat/movesets/<fighter>.json and lock.json. Called from xref.js with its
// helpers: get(rel), err(file, pointer, rule, message, level), esc, isObj, docsFor(regex).
// Copied to tools/lib/xref-movegen.js by docs/tools/pending/apply-movegen.cjs.
// What a validator cannot do: the generator's own `--check` (that the committed movesets are what the inputs give, the hash in
// `generator.inputs`, Legal's rows that name pose flags, and that every row of Legal's file is in parts.json) stays the generator's; see
// docs/tools/movegen-ci.md.

const PARTS = 'data/combat/parts.json';
const IDENT = 'data/combat/identity.json';
const CELLS = 'data/combat/cells.json';
const RECIPES = 'data/combat/recipes.json';
const LOCK = 'data/combat/movesets/lock.json';
const LEGAL_GROUPS = ['motion', 'energy', 'grabs', 'held', 'stacking'];

const plain = (o) => Object.keys(o).filter((k) => !k.startsWith('_'));
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// A filter: every listed part has one of the listed values; `any`: one of a list of filters must hold. `form` is any of a move's forms;
// `flags` and `event` are not known to a validator, so a filter that names them never matches here.
function match(flt, m) {
  if (!flt || typeof flt !== 'object') return false;
  if (Array.isArray(flt.any)) return flt.any.some((f) => match(f, m));
  for (const [k, vals] of Object.entries(flt)) {
    if (k.startsWith('_')) continue;
    if (!Array.isArray(vals)) return false;
    if (k === 'flags' || k === 'event') return false;
    if (k === 'form') { if (!Array.isArray(m.forms) || !m.forms.some((x) => vals.includes(x))) return false; continue; }
    if (!vals.includes(m[k])) return false;
  }
  return true;
}

function xrefMovegen({ get, err, esc, isObj, docsFor }) {
  const parts = get(PARTS);
  const ident = get(IDENT);
  const cells = get(CELLS);
  const S = isObj(parts) && isObj(parts.strike) ? parts.strike : null;
  const SH = isObj(parts) && isObj(parts.shot) ? parts.shot : null;
  const TR = isObj(parts) && isObj(parts.travel) ? parts.travel : null;
  const LG = isObj(parts) && isObj(parts.legal) ? parts.legal : null;

  // the manifests, the entry maps and the pose and sequence files
  const manifests = new Map();
  for (const rel of docsFor(/^data\/anim\/waves\/[^/]+\.manifest\.json$/)) {
    const m = get(rel);
    if (isObj(m) && Array.isArray(m.strikes)) manifests.set(m.wave, m);
  }
  const entrymaps = new Map();
  const entryNames = new Set();
  for (const rel of docsFor(/^data\/anim\/waves\/[^/]+\.entrymap\.json$/)) {
    const m = get(rel);
    if (!isObj(m) || !Array.isArray(m.entries)) continue;
    entrymaps.set(m.wave, m);
    for (const r of m.entries) if (isObj(r) && typeof r.name === 'string') entryNames.add(r.name);
  }
  const posesAll = new Set();
  const seqsAll = new Set();
  const mainPoses = get('data/anim/poses.json');
  if (isObj(mainPoses) && isObj(mainPoses.poses)) for (const k of Object.keys(mainPoses.poses)) posesAll.add(k);
  for (const rel of docsFor(/^data\/anim\/waves\/[^/]+\.poses\.json$/)) { const d = get(rel); if (isObj(d) && isObj(d.poses)) for (const k of Object.keys(d.poses)) posesAll.add(k); }
  for (const rel of docsFor(/^data\/anim\/waves\/[^/]+\.sequences\.json$/)) { const d = get(rel); if (isObj(d) && isObj(d.sequences)) for (const k of Object.keys(d.sequences)) seqsAll.add(k); }
  const sockets = get('data/anim/sockets.json');
  const regions = isObj(sockets) && isObj(sockets.regions) ? plain(sockets.regions) : [];
  const poseOrSeq = (id) => (!posesAll.size && !seqsAll.size) || posesAll.has(id) || seqsAll.has(id);

  const tipsOf = (limb) => (S && isObj(S.tips) && isObj(S.tips[limb]) ? S.tips[limb] : {});
  const shapeProblem = (m) => {
    if (!S) return null;
    const paths = tipsOf(m.limb)[m.tip];
    if (!Array.isArray(paths) || !paths.includes(m.path)) return `tip ${m.limb}.${m.tip} cannot travel path "${m.path}"`;
    const tgs = isObj(S.targets) && isObj(S.targets[m.limb]) ? S.targets[m.limb][m.path] : undefined;
    if (!Array.isArray(tgs) || !tgs.includes(m.target)) return `${m.limb} on path "${m.path}" cannot reach "${m.target}"`;
    if (m.weight === 'light' && Array.isArray(S.lightNever) && S.lightNever.some((f) => match(f, m))) return 'a shape that is never light';
    return null;
  };

  // ---- parts: the strike grammar is closed under itself ----
  const allPaths = new Set();
  if (S && isObj(S.tips)) {
    for (const limb of plain(S.tips)) {
      if (!isObj(S.tips[limb])) continue;
      for (const tip of plain(S.tips[limb])) {
        const paths = S.tips[limb][tip];
        if (!Array.isArray(paths)) continue;
        paths.forEach((p, i) => {
          allPaths.add(p);
          const tg = isObj(S.targets) && isObj(S.targets[limb]) ? S.targets[limb][p] : undefined;
          if (!Array.isArray(tg) || !tg.length) err(PARTS, `/strike/tips/${esc(limb)}/${esc(tip)}/${i}`, 'parts-grammar', `tip ${limb}.${tip} travels path "${p}", but strike.targets has no targets for ${limb} on "${p}"`);
        });
      }
    }
    for (const key of ['sends', 'links', 'step', 'beat']) {
      const tbl = S[key];
      if (!isObj(tbl)) continue;
      for (const p of allPaths) if (!(p in tbl)) err(PARTS, `/strike/${key}`, 'parts-grammar', `path "${p}" has no entry in strike.${key}`);
      for (const p of plain(tbl)) if (!allPaths.has(p)) err(PARTS, `/strike/${key}/${esc(p)}`, 'parts-grammar', `strike.${key} names path "${p}", which no tip travels`, 'warning');
    }
    if (isObj(S.links)) for (const p of plain(S.links)) if (Array.isArray(S.links[p])) S.links[p].forEach((q, i) => { if (!allPaths.has(q)) err(PARTS, `/strike/links/${esc(p)}/${i}`, 'parts-grammar', `links name path "${q}", which no tip travels`); });
    if (isObj(S.tagTips)) for (const tag of plain(S.tagTips)) if (Array.isArray(S.tagTips[tag])) S.tagTips[tag].forEach((tp, i) => { if (!(tp in tipsOf('hand'))) err(PARTS, `/strike/tagTips/${esc(tag)}/${i}`, 'parts-grammar', `tag "${tag}" keeps to tip "${tp}", which is not a hand tip`, 'warning'); });
    if (Array.isArray(S.swap)) S.swap.forEach((tp, i) => { if (!(tp in tipsOf('hand'))) err(PARTS, `/strike/swap/${i}`, 'parts-grammar', `swap names tip "${tp}", which is not a hand tip`); });
    if (Array.isArray(S.forms)) {
      const names = new Set();
      S.forms.forEach((f, i) => {
        if (!isObj(f)) return;
        if (names.has(f.form)) err(PARTS, `/strike/forms/${i}/form`, 'parts-grammar', `form "${f.form}" is listed twice`);
        if (f.unless !== undefined && !names.has(f.unless)) err(PARTS, `/strike/forms/${i}/unless`, 'parts-grammar', `form "${f.form}" is ruled out by "${f.unless}", which is not a form listed before it`);
        names.add(f.form);
      });
    }
    if (isObj(S.targets) && regions.length) for (const limb of plain(S.targets)) if (isObj(S.targets[limb])) for (const p of plain(S.targets[limb])) if (Array.isArray(S.targets[limb][p])) S.targets[limb][p].forEach((tg, i) => {
      const ok = regions.includes(tg) || (tg === 'arm' && regions.some((r) => /^arm_[lr]$/.test(r)));
      if (!ok) err(PARTS, `/strike/targets/${esc(limb)}/${esc(p)}/${i}`, 'parts-grammar', `target "${tg}" is not a region of sockets.json (${regions.join(', ')})`);
    });
  }

  // ids: Legal's rows and the sequence rules are unique; a condition names real rows
  const ruleIds = new Set();
  const dupe = (id, at) => { if (typeof id !== 'string') return; if (ruleIds.has(id)) err(PARTS, at, 'parts-grammar', `rule id "${id}" is used twice`); else ruleIds.add(id); };
  if (S) for (const key of ['banned', 'bannedSequences']) if (Array.isArray(S[key])) S[key].forEach((r, i) => { if (isObj(r)) dupe(r.id, `/strike/${key}/${i}/id`); });
  if (LG) for (const g of LEGAL_GROUPS) if (Array.isArray(LG[g])) LG[g].forEach((r, i) => { if (isObj(r)) dupe(r.id, `/legal/${g}/${i}/id`); });
  const conditionIds = new Set();
  if (S && Array.isArray(S.conditions)) S.conditions.forEach((c, i) => {
    if (!isObj(c)) return;
    if (typeof c.id === 'string') { if (conditionIds.has(c.id)) err(PARTS, `/strike/conditions/${i}/id`, 'parts-grammar', `condition id "${c.id}" is used twice`); else conditionIds.add(c.id); }
    if (Array.isArray(c.rows)) c.rows.forEach((rid, j) => { if (!ruleIds.has(rid)) err(PARTS, `/strike/conditions/${i}/rows/${j}`, 'parts-grammar', `condition ${c.id} names rule "${rid}", which is no row of banned, bannedSequences or legal`); });
  });
  if (S && isObj(S.flags) && Array.isArray(S.banned)) {
    const known = new Set(['fromAnimation', 'fromVfx', 'byVocabulary'].flatMap((k) => (Array.isArray(S.flags[k]) ? S.flags[k] : [])));
    if (isObj(S.flags.clearedBy)) for (const v of Object.values(S.flags.clearedBy)) if (Array.isArray(v)) v.forEach((x) => known.add(x));
    S.banned.forEach((r, i) => {
      const fl = isObj(r) && isObj(r.match) && Array.isArray(r.match.flags) ? r.match.flags : [];
      fl.forEach((x, j) => { if (known.size && !known.has(x)) err(PARTS, `/strike/banned/${i}/match/flags/${j}`, 'parts-grammar', `row ${r.id} names flag "${x}", which strike.flags does not list`, 'warning'); });
    });
  }

  // ---- parts: shot, travel, grab and Legal's rows ----
  const shotHands = SH && isObj(SH.hands) ? plain(SH.hands) : [];
  if (SH) {
    const rel = new Set(Array.isArray(SH.release) ? SH.release : []);
    const body = new Set(Array.isArray(SH.body) ? SH.body : []);
    const chk = (flt, at) => {
      if (!isObj(flt)) return;
      if (Array.isArray(flt.release)) flt.release.forEach((v, i) => { if (rel.size && !rel.has(v)) err(PARTS, `${at}/release/${i}`, 'parts-shot', `release "${v}" is not in shot.release (${[...rel].join(', ')})`); });
      if (Array.isArray(flt.body)) flt.body.forEach((v, i) => { if (body.size && !body.has(v)) err(PARTS, `${at}/body/${i}`, 'parts-shot', `body "${v}" is not in shot.body (${[...body].join(', ')})`); });
    };
    if (Array.isArray(SH.rules)) SH.rules.forEach((r, i) => { if (isObj(r)) { chk(r.if, `/shot/rules/${i}/if`); chk(r.then, `/shot/rules/${i}/then`); } });
    if (Array.isArray(SH.forms)) SH.forms.forEach((f, i) => { if (isObj(f)) chk(f.when, `/shot/forms/${i}/when`); });
    // Legal's rows may name releases the grammar has none of (a sweep), so only their `if` is held to shot.release
    if (LG && Array.isArray(LG.energy)) LG.energy.forEach((r, i) => { if (isObj(r)) chk(r.if, `/legal/energy/${i}/if`); });
    // a hand property a Legal row needs is a property of the hands
    const props = new Set(shotHands.flatMap((h) => (isObj(SH.hands[h]) ? plain(SH.hands[h]) : [])));
    if (LG) for (const g of LEGAL_GROUPS) if (Array.isArray(LG[g])) LG[g].forEach((r, i) => {
      if (!isObj(r)) return;
      for (const [label, nd] of [['need', r.need], ['hand/need', isObj(r.hand) ? r.hand.need : undefined]]) if (isObj(nd) && props.size) for (const k of plain(nd)) if (!props.has(k)) err(PARTS, `/legal/${g}/${i}/${label}/${esc(k)}`, 'parts-shot', `row ${r.id} needs hand property "${k}", which no shot.hands row has (${[...props].join(', ')})`);
    });
  }
  if (TR) {
    const dirs = isObj(TR.arrive) ? plain(TR.arrive) : [];
    if (isObj(TR.arrive)) for (const d of dirs) if (Array.isArray(TR.arrive[d])) TR.arrive[d].forEach((p, i) => { if (allPaths.size && !allPaths.has(p)) err(PARTS, `/travel/arrive/${esc(d)}/${i}`, 'parts-travel', `arrive path "${p}" is not a path of the grammar`); });
    if (isObj(TR.kinds)) for (const kn of plain(TR.kinds)) {
      const k = TR.kinds[kn];
      if (!isObj(k) || !Array.isArray(k.moves)) continue;
      k.moves.forEach((m, i) => {
        if (!isObj(m)) return;
        const at = `/travel/kinds/${esc(kn)}/moves/${i}`;
        if (dirs.length && typeof m.direction === 'string' && !dirs.includes(m.direction)) err(PARTS, `${at}/direction`, 'parts-travel', `direction "${m.direction}" has no entry in travel.arrive`);
        if (entryNames.size) {
          if (Array.isArray(m.entries)) m.entries.forEach((en, j) => { if (!entryNames.has(en)) err(PARTS, `${at}/entries/${j}`, 'parts-travel', `entry "${en}" is the name of no entrymap row`); });
          if (typeof m.exit === 'string' && !entryNames.has(m.exit)) err(PARTS, `${at}/exit`, 'parts-travel', `exit "${m.exit}" is the name of no entrymap row`);
        }
      });
    }
  }
  if (isObj(parts) && isObj(parts.grab) && Array.isArray(parts.grab.holdPoints) && LG && Array.isArray(LG.grabs)) {
    const never = new Set(LG.grabs.filter((r) => isObj(r) && r.kind === 'holdPoints' && Array.isArray(r.never)).flatMap((r) => r.never));
    parts.grab.holdPoints.forEach((h, i) => { if (never.has(h)) err(PARTS, `/grab/holdPoints/${i}`, 'parts-legal', `hold point "${h}" is one of the grab rule's never list`); });
  }
  if (isObj(parts) && isObj(parts.readings) && isObj(cells) && isObj(cells.stances)) for (const st of plain(parts.readings)) if (!(st in cells.stances)) err(PARTS, `/readings/${esc(st)}`, 'parts-grammar', `readings for stance "${st}", which is not in cells.json stances`, 'warning');

  // ---- identity: waves, entries, tips, energy and specials ----
  const recipes = get(RECIPES);
  const poolFighters = isObj(recipes) && isObj(recipes.pools) ? plain(recipes.pools) : null;
  const hasTip = (key) => { const [limb, tip] = String(key).split('.'); return Boolean(limb && tip && tip in tipsOf(limb)); };
  if (isObj(ident) && isObj(ident.fighters)) {
    for (const fid of plain(ident.fighters)) {
      const f = ident.fighters[fid];
      if (!isObj(f)) continue;
      const at = `/fighters/${esc(fid)}`;
      if (poolFighters && !poolFighters.includes(fid)) err(IDENT, at, 'identity-ref', `fighter "${fid}" is not a key of data/combat/recipes.json pools (${poolFighters.join(', ')})`);
      if (Array.isArray(f.waves) && manifests.size) f.waves.forEach((w, i) => { if (!manifests.has(w)) err(IDENT, `${at}/waves/${i}`, 'identity-ref', `wave "${w}" has no manifest in data/anim/waves`); });
      if (Array.isArray(f.entryWaves) && entrymaps.size) f.entryWaves.forEach((w, i) => { if (!entrymaps.has(w)) err(IDENT, `${at}/entryWaves/${i}`, 'identity-ref', `entry wave "${w}" has no entry map in data/anim/waves`); });
      if (isObj(f.weights) && isObj(f.weights.entry) && entryNames.size) for (const k of plain(f.weights.entry)) if (!entryNames.has(k)) err(IDENT, `${at}/weights/entry/${esc(k)}`, 'identity-ref', `weight for entry "${k}", which is the name of no entrymap row`);
      if (S && isObj(f.weights) && isObj(f.weights.tip)) for (const k of plain(f.weights.tip)) if (!hasTip(k)) err(IDENT, `${at}/weights/tip/${esc(k)}`, 'identity-ref', `weight for tip "${k}", which is not a tip of parts.json (written limb.tip)`);
      if (S && isObj(f.tipFlags)) for (const k of plain(f.tipFlags)) if (!hasTip(k)) err(IDENT, `${at}/tipFlags/${esc(k)}`, 'identity-ref', `tipFlags for "${k}", which is not a tip of parts.json (written limb.tip)`);
      if (S && Array.isArray(f.weightsBy)) f.weightsBy.forEach((w, i) => { if (isObj(w) && isObj(w.tip)) for (const k of plain(w.tip)) if (!hasTip(k)) err(IDENT, `${at}/weightsBy/${i}/tip/${esc(k)}`, 'identity-ref', `weight for tip "${k}", which is not a tip of parts.json (written limb.tip)`); });
      if (isObj(f.energy)) {
        const en = f.energy;
        if (shotHands.length) for (const key of ['hands', 'posedHands']) if (isObj(en[key])) for (const h of plain(en[key])) if (!shotHands.includes(h)) err(IDENT, `${at}/energy/${key}/${esc(h)}`, 'identity-ref', `energy hand "${h}" is not in parts.json shot.hands (${shotHands.join(', ')})`);
        if (SH && Array.isArray(SH.release) && isObj(en.release)) for (const r of plain(en.release)) if (!SH.release.includes(r)) err(IDENT, `${at}/energy/release/${esc(r)}`, 'identity-ref', `release "${r}" is not in parts.json shot.release (${SH.release.join(', ')})`);
        if (isObj(en.posedHands) && posesAll.size) for (const [h, pid] of Object.entries(en.posedHands)) if (!h.startsWith('_') && typeof pid === 'string' && !posesAll.has(pid)) err(IDENT, `${at}/energy/posedHands/${esc(h)}`, 'identity-ref', `posed hand "${pid}" is not a pose`);
        if (Array.isArray(en.posed)) en.posed.forEach((p, i) => { if (isObj(p) && typeof p.set === 'string' && !poseOrSeq(p.set)) err(IDENT, `${at}/energy/posed/${i}/set`, 'identity-ref', `posed set "${p.set}" is neither a pose nor a sequence`); });
      }
    }
    if (Array.isArray(ident.rejected)) ident.rejected.forEach((r, i) => { if (isObj(r) && typeof r.fighter === 'string' && !plain(ident.fighters).includes(r.fighter)) err(IDENT, `/rejected/${i}/fighter`, 'identity-ref', `rejected shape for "${r.fighter}", who is not a fighter of this file`); });
  }

  // ---- cells ----
  const formNames = new Set([].concat(S && Array.isArray(S.forms) ? S.forms.filter(isObj).map((f) => f.form) : [], SH && Array.isArray(SH.forms) ? SH.forms.filter(isObj).map((f) => f.form) : [], isObj(parts) && isObj(parts.readings) ? plain(parts.readings).flatMap((st) => (isObj(parts.readings[st]) ? plain(parts.readings[st]) : [])) : []));
  const sendValues = new Set(S && isObj(S.sends) ? plain(S.sends).map((k) => S.sends[k]) : []);
  const cellOf = (key) => { const [st, btn] = String(key).split('.'); return isObj(cells) && isObj(cells.stances) && isObj(cells.stances[st]) ? cells.stances[st][btn] : undefined; };
  if (isObj(cells) && isObj(cells.stances)) {
    for (const st of plain(cells.stances)) {
      const stance = cells.stances[st];
      if (!isObj(stance)) continue;
      for (const btn of ['x', 'y', 'a', 'b']) {
        const c = stance[btn];
        if (!isObj(c)) continue;
        const cat = `/stances/${esc(st)}/${btn}`;
        if (Array.isArray(c.asks) && conditionIds.size) c.asks.forEach((a, i) => { if (!conditionIds.has(a)) err(CELLS, `${cat}/asks/${i}`, 'cells-asks', `"${a}" is no condition of parts.json strike.conditions`); });
        if (c.kind === 'travel') {
          if (typeof c.blows === 'string' && !isObj(cellOf(c.blows))) err(CELLS, `${cat}/blows`, 'cells-quota', `blows names cell "${c.blows}", which is not in cells.json`);
          if (Array.isArray(c.kinds) && TR && isObj(TR.kinds)) c.kinds.forEach((k, i) => { if (!(k in TR.kinds)) err(CELLS, `${cat}/kinds/${i}`, 'cells-quota', `travel kind "${k}" is not in parts.json travel.kinds (${plain(TR.kinds).join(', ')})`); });
        }
        if (c.kind === 'table' && typeof c.block === 'string' && isObj(parts) && !isObj(parts[c.block])) err(CELLS, `${cat}/block`, 'cells-quota', `block "${c.block}" is not a block of parts.json`);
        if (!Array.isArray(c.quotas)) continue;
        const names = new Set();
        c.quotas.forEach((q, i) => {
          if (!isObj(q)) return;
          const at = `${cat}/quotas/${i}`;
          const kinds = ['filter', 'any', 'form', 'sends'].filter((k) => q[k] !== undefined);
          if (kinds.length !== 1) err(CELLS, at, 'cells-quota', `quota "${q.name}" has ${kinds.length ? kinds.join(', ') : 'none of filter, any, form or sends'}; it needs exactly one`);
          if (names.has(q.name)) err(CELLS, `${at}/name`, 'cells-quota', `quota name "${q.name}" is used twice in this cell`);
          names.add(q.name);
          if (typeof q.min === 'number' && typeof c.count === 'number' && q.min > c.count) err(CELLS, `${at}/min`, 'cells-quota', `quota "${q.name}" asks for ${q.min} moves in a cell of ${c.count}`);
          if (typeof q.form === 'string' && formNames.size && !formNames.has(q.form)) err(CELLS, `${at}/form`, 'cells-quota', `quota form "${q.form}" is not a form of parts.json (${[...formNames].join(', ')})`);
          if (typeof q.sends === 'string' && sendValues.size && !sendValues.has(q.sends)) err(CELLS, `${at}/sends`, 'cells-quota', `quota sends "${q.sends}" is not a direction of strike.sends (${[...sendValues].join(', ')})`);
        });
      }
    }
  }

  // ---- movesets ----
  const deriveForms = (m, arms) => {
    const out = [];
    const mm = Object.assign({}, m, { arms });
    for (const f of S && Array.isArray(S.forms) ? S.forms : []) {
      if (!isObj(f)) continue;
      const ok = Array.isArray(f.any) ? f.any.some((g) => match(g, mm)) : match(f.when, mm);
      if (ok && !(f.unless && out.includes(f.unless))) out.push(f.form);
    }
    return out;
  };
  const shotForms = (m) => (SH && Array.isArray(SH.forms) ? SH.forms.filter((f) => isObj(f) && match(f.when, m)).map((f) => f.form) : []);
  const never = (fid) => (isObj(ident) && isObj(ident.fighters) && isObj(ident.fighters[fid]) && Array.isArray(ident.fighters[fid].never) ? ident.fighters[fid].never : []);
  const banned = S && Array.isArray(S.banned) ? S.banned.filter(isObj).map((r) => Object.assign({}, r, { shape: r.match || r.shape })) : [];
  const movesets = new Map();
  for (const rel of docsFor(/^data\/combat\/movesets\/[^/]+\.json$/)) {
    if (rel === LOCK) continue;
    const ms = get(rel);
    if (isObj(ms) && typeof ms.fighter === 'string') movesets.set(ms.fighter, { rel, ms });
  }
  const quotaCount = (q, mv) => (q.filter ? match(q.filter, mv) : q.any ? q.any.some((g) => match(g, mv)) : q.form ? Array.isArray(mv.forms) && mv.forms.includes(q.form) : q.sends ? mv.sends === q.sends : false);
  const STATUS = { posed: 'posed', hand_state: 'derived', re_aim: 'derived', re_aim_edge: 'derived', hand_state_re_aim: 'derived', hand_state_re_aim_edge: 'derived', new: 'waiting' };

  for (const [fid, { rel, ms }] of movesets) {
    const idf = isObj(ident) && isObj(ident.fighters) && isObj(ident.fighters[fid]) ? ident.fighters[fid] : null;
    if (isObj(ident) && isObj(ident.fighters) && !idf) err(rel, '/fighter', 'moveset-cell', `fighter "${fid}" is not a fighter of identity.json`);
    if (isObj(ms.generator) && isObj(cells) && Number.isInteger(ms.generator.seed) && Number.isInteger(cells.seed) && ms.generator.seed !== cells.seed) err(rel, '/generator/seed', 'moveset-cell', `seed ${ms.generator.seed} is not cells.json's ${cells.seed}`);
    const waves = idf && Array.isArray(idf.waves) ? idf.waves : [];
    const entryWaves = idf && Array.isArray(idf.entryWaves) ? idf.entryWaves : [];
    if (!isObj(ms.cells)) continue;
    const rowOfSet = (wave, id) => { const m = manifests.get(wave); return m ? m.strikes.find((r) => isObj(r) && r.id === id) : undefined; };
    for (const ck of Object.keys(ms.cells)) {
      const cell = ms.cells[ck];
      if (!isObj(cell)) continue;
      const def = cellOf(ck);
      const cat = `/cells/${esc(ck)}`;
      const btn = ck.split('.')[1];
      if (isObj(cells) && !isObj(def)) { err(rel, cat, 'moveset-cell', `cell "${ck}" is not in cells.json stances`); continue; }
      if (isObj(def) && def.kind !== cell.kind) err(rel, `${cat}/kind`, 'moveset-cell', `cell "${ck}" is a ${cell.kind} cell here and a ${def.kind} cell in cells.json`);
      if (Array.isArray(cell.asks) && conditionIds.size) cell.asks.forEach((a, i) => { if (!conditionIds.has(a)) err(rel, `${cat}/asks/${i}`, 'moveset-keys', `"${a}" is no condition of parts.json strike.conditions`); });
      if (cell.kind === 'context' && isObj(def)) for (const k of ['pressed', 'held']) if (Array.isArray(def[k]) && Array.isArray(cell[k]) && !same(def[k], cell[k])) err(rel, `${cat}/${k}`, 'moveset-cell', `the ${k} list differs from cells.json's`);
      if (cell.kind === 'special') {
        const sp = idf && isObj(idf.specials) ? idf.specials[btn] : undefined;
        if (isObj(sp) && cell.special !== sp.id) err(rel, `${cat}/special`, 'moveset-special', `the special "${cell.special}" is not ${fid}'s "${sp.id}" for button ${btn}`);
      }
      if (!Array.isArray(cell.moves)) continue;
      if (isObj(def) && typeof def.count === 'number' && cell.kind !== 'special' && cell.moves.length !== def.count) err(rel, `${cat}/moves`, 'moveset-cell', `cell "${ck}" has ${cell.moves.length} moves; cells.json asks for ${def.count}`);
      const seen = new Map();
      cell.moves.forEach((mv, i) => {
        if (!isObj(mv)) return;
        const at = `${cat}/moves/${i}`;
        const want = `mv.${fid}.${ck}.${String(i + 1).padStart(2, '0')}`;
        if (typeof mv.id === 'string' && mv.id !== want) err(rel, `${at}/id`, 'moveset-cell', `move id "${mv.id}" should be "${want}"`);
        if (Array.isArray(mv.asks) && conditionIds.size) mv.asks.forEach((a, j) => { if (!conditionIds.has(a)) err(rel, `${at}/asks/${j}`, 'moveset-keys', `"${a}" is no condition of parts.json strike.conditions`); });
        if (cell.kind === 'strikes') {
          if (isObj(def) && isObj(def.filter) && !def.anyWeight && !match(def.filter, mv)) err(rel, at, 'moveset-cell', `move ${mv.id} does not match the cell's filter`);
          if (isObj(def) && Array.isArray(def.notFlags) && Array.isArray(mv.flags) && mv.flags.some((x) => def.notFlags.includes(x))) err(rel, `${at}/flags`, 'moveset-shape', `${mv.id} has a flag the cell rules out (${def.notFlags.join(', ')})`);
          const prob = shapeProblem(mv);
          if (prob) err(rel, at, 'moveset-shape', `${mv.id}: ${prob}`);
          const nv = never(fid).find((n) => isObj(n) && match(n.shape, mv));
          if (nv) err(rel, at, 'moveset-shape', `${mv.id} matches a never row of ${fid} (${nv.why})`);
          const bn = banned.find((n) => isObj(n) && match(n.shape, mv)); // a row that names flags is the generator's --check, not a validator's
          if (bn) err(rel, at, 'moveset-shape', `${mv.id} matches a banned shape (${bn.why})`);
          const fp = [mv.limb, mv.tip, mv.path, mv.target, mv.weight].join('|');
          if (seen.has(fp)) err(rel, at, 'moveset-shape', `${mv.id} repeats the shape of move ${seen.get(fp) + 1} in this cell`); else seen.set(fp, i);
          const keys = isObj(mv.keys) ? mv.keys : {};
          const from = typeof keys.from === 'string' ? waves.map((w) => manifests.get(w)).filter(Boolean).flatMap((m) => m.strikes).find((r) => isObj(r) && r.combat === keys.from) : undefined;
          const arms = isObj(from) && isObj(from.uses) && Number.isInteger(from.uses.arms) ? from.uses.arms : (mv.limb === 'hand' || mv.limb === 'elbow' ? 1 : 0);
          if (S) {
            if (!same(mv.sends, S.sends && S.sends[mv.path])) err(rel, `${at}/sends`, 'moveset-derived', `sends ${JSON.stringify(mv.sends)} is not what the grammar gives for path "${mv.path}"`);
            if (!same(mv.links, S.links && S.links[mv.path])) err(rel, `${at}/links`, 'moveset-derived', `links are not what the grammar gives for path "${mv.path}"`);
            if (!same(mv.step, S.step && S.step[mv.path])) err(rel, `${at}/step`, 'moveset-derived', `step is not what the grammar gives for path "${mv.path}"`);
            if (mv.beat !== (S.beat && S.beat[mv.path])) err(rel, `${at}/beat`, 'moveset-derived', `beat ${mv.beat} is not what the grammar gives for path "${mv.path}"`);
            const forms = isObj(def) && Array.isArray(def.readings) ? def.readings : deriveForms(mv, arms);
            if (Array.isArray(mv.forms) && !same(mv.forms, forms)) err(rel, `${at}/forms`, 'moveset-derived', `forms ${JSON.stringify(mv.forms)} are not what the grammar gives (${JSON.stringify(forms)})`);
          }
          if (Number.isInteger(mv.arms) && mv.arms !== arms) err(rel, `${at}/arms`, 'moveset-derived', `arms ${mv.arms} is not what the grammar gives (${arms})`);
          const status = STATUS[keys.level];
          if (status && mv.status !== status) err(rel, `${at}/status`, 'moveset-keys', `status "${mv.status}" does not follow keys.level "${keys.level}" (${status})`);
          if (keys.level === 'new') {
            if (keys.from !== undefined || keys.set !== undefined) err(rel, `${at}/keys`, 'moveset-keys', 'a new move has no from or set');
          } else if (keys.level !== undefined) {
            if (typeof keys.from !== 'string' || typeof keys.set !== 'string') err(rel, `${at}/keys`, 'moveset-keys', `a ${keys.level} move needs from and set`);
            else if (manifests.size) {
              const row = typeof keys.wave === 'string' ? rowOfSet(keys.wave, keys.set) : waves.map((w) => rowOfSet(w, keys.set)).find(Boolean);
              if (typeof keys.wave === 'string' && !waves.includes(keys.wave)) err(rel, `${at}/keys/wave`, 'moveset-keys', `wave "${keys.wave}" is not one of ${fid}'s waves (${waves.join(', ')})`);
              else if (!row) err(rel, `${at}/keys/set`, 'moveset-keys', `key set "${keys.set}" is a row of none of ${fid}'s manifests (${waves.join(', ')})`);
              else if (row.combat !== keys.from) err(rel, `${at}/keys/from`, 'moveset-keys', `key set "${keys.set}" is the strike "${row.combat}", not "${keys.from}"`);
            }
          }
        } else if (cell.kind === 'travel') {
          const kd = TR && isObj(TR.kinds) ? TR.kinds[mv.kind] : undefined;
          if (isObj(def) && Array.isArray(def.kinds) && !def.kinds.includes(mv.kind)) err(rel, `${at}/kind`, 'moveset-travel', `kind "${mv.kind}" is not one of the cell's kinds (${def.kinds.join(', ')})`);
          if (isObj(kd)) {
            if (kd.band !== mv.band) err(rel, `${at}/band`, 'moveset-travel', `band "${mv.band}" is not the ${mv.kind}'s band "${kd.band}"`);
            const entryName = isObj(mv.entry) && typeof mv.entry.id === 'string' ? mv.entry.id.replace(/^entry\./, '') : undefined;
            const exitName = isObj(mv.exit) && typeof mv.exit.id === 'string' ? mv.exit.id.replace(/^entry\./, '') : null;
            const ok = Array.isArray(kd.moves) && kd.moves.some((m) => isObj(m) && m.direction === mv.direction && Array.isArray(m.entries) && m.entries.includes(entryName) && (m.exit === null || m.exit === undefined ? exitName === null : m.exit === exitName));
            if (!ok) err(rel, at, 'moveset-travel', `${mv.kind} ${mv.direction} with entry "${entryName}" and exit "${exitName}" is not one of parts.json travel.kinds.${mv.kind}.moves`);
          }
          if (LG && Array.isArray(LG.motion)) {
            const tmv = { kind: mv.kind, direction: mv.direction, exit: isObj(mv.exit) && typeof mv.exit.id === 'string' ? mv.exit.id.replace(/^entry\./, '') : null };
            for (const r of LG.motion) if (isObj(r) && r.kind === 'travel' && isObj(r.if) && isObj(r.then) && match(r.if, tmv) && !match(r.then, tmv)) err(rel, at, 'moveset-travel', `${mv.id} breaks Legal's row ${r.id}${r.why ? ': ' + r.why : ''}`);
          }
          for (const k of ['entry', 'exit']) if (isObj(mv[k]) && typeof mv[k].set === 'string' && entrymaps.size && !entryWaves.some((w) => isObj(entrymaps.get(w)) && entrymaps.get(w).entries.some((r) => isObj(r) && r.id === mv[k].set))) err(rel, `${at}/${k}/set`, 'moveset-travel', `${k} set "${mv[k].set}" is a row of none of ${fid}'s entry maps (${entryWaves.join(', ')})`);
          if (isObj(mv.blow)) {
            const bc = isObj(def) && typeof def.blows === 'string' ? ms.cells[def.blows] : undefined;
            const target = isObj(bc) && Array.isArray(bc.moves) ? bc.moves.find((m) => isObj(m) && m.id === mv.blow.move) : undefined;
            if (isObj(bc) && !target) err(rel, `${at}/blow/move`, 'moveset-travel', `blow "${mv.blow.move}" is a move of no ${def.blows} cell`);
            else if (target) {
              if (!['limb', 'tip', 'path', 'target', 'weight'].every((k) => mv.blow[k] === target[k])) err(rel, `${at}/blow`, 'moveset-travel', `the blow's shape is not that of ${mv.blow.move}`);
              if (isObj(target.keys) && mv.blow.set !== target.keys.set) err(rel, `${at}/blow/set`, 'moveset-travel', `the blow's key set "${mv.blow.set}" is not ${mv.blow.move}'s "${target.keys.set}"`);
            }
            if (TR && isObj(TR.arrive) && Array.isArray(TR.arrive[mv.direction]) && !TR.arrive[mv.direction].includes(mv.blow.path)) err(rel, `${at}/blow/path`, 'moveset-travel', `path "${mv.blow.path}" is not in travel.arrive for "${mv.direction}" (${TR.arrive[mv.direction].join(', ')})`);
          }
          if (isObj(def) && Array.isArray(def.readings) && Array.isArray(mv.forms) && !same(mv.forms, def.readings)) err(rel, `${at}/forms`, 'moveset-derived', `forms ${JSON.stringify(mv.forms)} are not the cell's readings (${JSON.stringify(def.readings)})`);
        } else if (cell.kind === 'table') {
          if (isObj(def) && Array.isArray(def.delivery) && !def.delivery.includes(mv.delivery)) err(rel, `${at}/delivery`, 'moveset-table', `delivery "${mv.delivery}" is not one of the cell's (${def.delivery.join(', ')})`);
          if (SH) {
            if (Array.isArray(SH.release) && !SH.release.includes(mv.release)) err(rel, `${at}/release`, 'moveset-table', `release "${mv.release}" is not in shot.release`);
            if (Array.isArray(SH.body) && !SH.body.includes(mv.body)) err(rel, `${at}/body`, 'moveset-table', `body "${mv.body}" is not in shot.body`);
            if (shotHands.length && !shotHands.includes(mv.hand)) err(rel, `${at}/hand`, 'moveset-table', `hand "${mv.hand}" is not in shot.hands`);
            if (idf && isObj(idf.energy) && isObj(idf.energy.hands) && !(mv.hand in idf.energy.hands)) err(rel, `${at}/hand`, 'moveset-table', `${fid} has no energy hand "${mv.hand}"`);
            const rows = [].concat(Array.isArray(SH.rules) ? SH.rules.filter(isObj) : [], LG && Array.isArray(LG.energy) ? LG.energy.filter((r) => isObj(r) && r.kind === 'move' && isObj(r.if) && isObj(r.then)) : []);
            for (const r of rows) if (match(r.if, mv) && !match(r.then, mv)) err(rel, at, 'moveset-table', `${mv.id} breaks a rule of its block${r.id ? ' (' + r.id + ')' : ''}${r.why ? ': ' + r.why : ''}`);
            const hr = LG && Array.isArray(LG.energy) ? LG.energy.filter((r) => isObj(r) && r.kind === 'hand' && isObj(r.never)) : [];
            const hp = isObj(SH.hands) && isObj(SH.hands[mv.hand]) ? SH.hands[mv.hand] : null;
            if (hp) for (const r of hr) if (match(r.never, hp)) err(rel, `${at}/hand`, 'moveset-table', `hand "${mv.hand}" matches the never of ${r.id}`);
            const forms = shotForms(mv);
            if (Array.isArray(mv.forms) && !same(mv.forms, forms)) err(rel, `${at}/forms`, 'moveset-derived', `forms ${JSON.stringify(mv.forms)} are not what shot.forms gives (${JSON.stringify(forms)})`);
          }
          if (isObj(mv.keys) && idf && isObj(idf.energy)) {
            if (typeof mv.keys.hand === 'string' && isObj(idf.energy.posedHands) && idf.energy.posedHands[mv.hand] !== mv.keys.hand) err(rel, `${at}/keys/hand`, 'moveset-keys', `keys.hand "${mv.keys.hand}" is not ${fid}'s posed pose for "${mv.hand}"`);
            if (typeof mv.keys.set === 'string' && Array.isArray(idf.energy.posed) && !idf.energy.posed.some((p) => isObj(p) && p.set === mv.keys.set)) err(rel, `${at}/keys/set`, 'moveset-keys', `keys.set "${mv.keys.set}" is a posed set of none of ${fid}'s energy rows`);
          }
        } else if (cell.kind === 'special') {
          const sp = idf && isObj(idf.specials) ? idf.specials[btn] : undefined;
          if (isObj(sp) && isObj(sp.parts) && isObj(mv.look)) for (const [k, v] of Object.entries(mv.look)) {
            if (!(k in sp.parts)) err(rel, `${at}/look/${esc(k)}`, 'moveset-special', `look part "${k}" is not a part of ${sp.id}`);
            else if (Array.isArray(sp.parts[k]) && !sp.parts[k].includes(v)) err(rel, `${at}/look/${esc(k)}`, 'moveset-special', `"${v}" is not a value of ${sp.id}'s part "${k}"`);
          }
          if (isObj(def) && Array.isArray(def.readings) && Array.isArray(mv.forms) && !same(mv.forms, def.readings)) err(rel, `${at}/forms`, 'moveset-derived', `forms ${JSON.stringify(mv.forms)} are not the cell's readings (${JSON.stringify(def.readings)})`);
        }
      });
      // the quotas the cell asks for are met, and the recorded counts are right
      if (isObj(def) && Array.isArray(def.quotas)) for (const q of def.quotas) {
        if (!isObj(q)) continue;
        const n = cell.moves.filter((mv) => isObj(mv) && quotaCount(q, mv)).length;
        const splitQuota = isObj(q.filter) && Array.isArray(q.filter.delivery) && q.filter.delivery.includes('split') && !(idf && isObj(idf.energy) && idf.energy.split === true); // a split is only asked of a fighter who can split
        if (typeof q.min === 'number' && !splitQuota && n < q.min) err(rel, `${cat}/moves`, 'moveset-cell', `quota "${q.name}" needs ${q.min} moves and the cell has ${n}`);
        if (isObj(cell.quotas) && cell.quotas[q.name] !== n) err(rel, `${cat}/quotas/${esc(q.name)}`, 'moveset-cell', `the recorded count ${cell.quotas[q.name]} for quota "${q.name}" is ${n} on recount`);
      }
    }
  }

  // ---- the lock: every locked id is a move of the same shape, and every strike move is locked ----
  const lock = get(LOCK);
  if (isObj(lock) && isObj(lock.fighters)) {
    for (const fid of plain(lock.fighters)) {
      const fl = lock.fighters[fid];
      const got = movesets.get(fid);
      if (!isObj(fl)) continue;
      if (!got) { err(LOCK, `/fighters/${esc(fid)}`, 'lock-ref', `the lock has fighter "${fid}", who has no moveset`); continue; }
      for (const [ck, list] of Object.entries(fl)) {
        const cell = isObj(got.ms.cells) ? got.ms.cells[ck] : undefined;
        if (!isObj(cell) || !Array.isArray(cell.moves)) { err(LOCK, `/fighters/${esc(fid)}/${esc(ck)}`, 'lock-ref', `the lock has cell "${ck}", which ${fid}'s moveset has no strike cell for`); continue; }
        if (!Array.isArray(list)) continue;
        list.forEach((row, i) => {
          if (!Array.isArray(row)) return;
          const [id, shape, set] = row;
          const mv = cell.moves.find((m) => isObj(m) && m.id === id);
          const at = `/fighters/${esc(fid)}/${esc(ck)}/${i}`;
          if (!mv) err(LOCK, at, 'lock-ref', `locked move "${id}" is not a move of ${fid}'s ${ck}`);
          else {
            if (Array.isArray(shape) && !same(shape, [mv.limb, mv.tip, mv.path, mv.target, mv.weight])) err(LOCK, `${at}/1`, 'lock-ref', `locked move "${id}" has a different shape in the moveset`);
            const ks = isObj(mv.keys) && mv.keys.level === 'posed' && typeof mv.keys.set === 'string' ? mv.keys.set : null; // only a posed move locks on its key set
            if ((set === undefined ? null : set) !== ks) err(LOCK, `${at}/2`, 'lock-ref', `locked move "${id}" has key set ${JSON.stringify(set === undefined ? null : set)}; its moveset row says ${JSON.stringify(ks)} (a posed move's set, null for any other level)`);
          }
        });
      }
      for (const [ck, cell] of Object.entries(isObj(got.ms.cells) ? got.ms.cells : {})) {
        if (!isObj(cell) || cell.kind !== 'strikes' || !Array.isArray(cell.moves)) continue;
        const locked = new Set((Array.isArray(fl[ck]) ? fl[ck] : []).filter(Array.isArray).map((r) => r[0]));
        cell.moves.forEach((m, i) => { if (isObj(m) && !locked.has(m.id)) err(got.rel, `/cells/${esc(ck)}/moves/${i}/id`, 'lock-ref', `strike move "${m.id}" is not in the lock`); });
      }
    }
  }
}

module.exports = { xrefMovegen };
