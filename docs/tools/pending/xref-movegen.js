'use strict';
// Cross-reference rules for the generated movesets (docs/combat/moveset-generator.md; docs/combat/pending/movegen/README.md section 4):
// data/combat/parts.json, identity.json, cells.json and data/combat/movesets/<fighter>.json. Called from xref.js with its helpers:
// get(rel), err(file, pointer, rule, message, level), esc, isObj, docsFor(regex).
// Copied to tools/lib/xref-movegen.js by docs/tools/pending/apply-movegen.cjs.
// What a validator cannot do: the generator's own `--check` (that the committed movesets are what the inputs give, and the hash in
// `generator.inputs`) stays the generator's; see docs/tools/movegen-ci.md.

const PARTS = 'data/combat/parts.json';
const IDENT = 'data/combat/identity.json';
const CELLS = 'data/combat/cells.json';
const RECIPES = 'data/combat/recipes.json';

const plain = (o) => Object.keys(o).filter((k) => !k.startsWith('_'));

// A filter: every listed part has one of the listed values; `any`: one of a list of filters must hold.
function match(flt, m) {
  if (!flt || typeof flt !== 'object') return false;
  if (Array.isArray(flt.any)) return flt.any.some((f) => match(f, m));
  for (const [k, vals] of Object.entries(flt)) {
    if (k.startsWith('_')) continue;
    if (!Array.isArray(vals)) return false;
    if (k === 'flags' || k === 'event') return false; // pose flags and run-time events are not known to a validator
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

  // the manifests: wave -> rows, and every row by its combat id
  const manifests = new Map();
  const rowsByCombat = new Map();
  for (const rel of docsFor(/^data\/anim\/waves\/[^/]+\.manifest\.json$/)) {
    const m = get(rel);
    if (!isObj(m) || !Array.isArray(m.strikes)) continue;
    manifests.set(m.wave, m);
    for (const r of m.strikes) if (isObj(r) && typeof r.combat === 'string') { if (!rowsByCombat.has(r.combat)) rowsByCombat.set(r.combat, []); rowsByCombat.get(r.combat).push(Object.assign({ _wave: m.wave }, r)); }
  }
  const sockets = get('data/anim/sockets.json');
  const regions = isObj(sockets) && isObj(sockets.regions) ? plain(sockets.regions) : [];
  // the grammar's `arm` is the near arm's socket
  const targetFits = (grammarTarget, rowTarget) => grammarTarget === rowTarget || (grammarTarget === 'arm' && /^arm_[lr]$/.test(rowTarget));

  // ---- parts: the grammar is closed under itself; the posed strikes are shapes of it and agree with the manifests ----
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
  }
  if (S) {
    const ruleIds = new Set();
    for (const key of ['banned', 'bannedSequences']) if (Array.isArray(S[key])) S[key].forEach((r, i) => {
      if (!isObj(r) || typeof r.id !== 'string') return;
      if (ruleIds.has(r.id)) err(PARTS, `/strike/${key}/${i}/id`, 'parts-grammar', `rule id "${r.id}" is used twice`); else ruleIds.add(r.id);
    });
    if (Array.isArray(S.conditions)) S.conditions.forEach((c, i) => {
      if (!isObj(c) || !Array.isArray(c.rows)) return;
      c.rows.forEach((rid, j) => { if (!ruleIds.has(rid)) err(PARTS, `/strike/conditions/${i}/rows/${j}`, 'parts-grammar', `condition ${c.id} names rule "${rid}", which is no row of banned or bannedSequences`); });
    });
    if (isObj(S.flags) && isObj(S.flags.clearedBy) && Array.isArray(S.legalTags)) {
      const tags = new Set(S.legalTags.filter(isObj).map((l) => l.tag));
      for (const tag of plain(S.flags.clearedBy)) if (!tags.has(tag)) err(PARTS, `/strike/flags/clearedBy/${esc(tag)}`, 'parts-grammar', `flags are cleared by tag "${tag}", which is no tag of strike.legalTags`, 'warning');
    }
    if (isObj(S.flags) && Array.isArray(S.banned)) {
      const known = new Set(['fromAnimation', 'fromVfx', 'byVocabulary'].flatMap((k) => (Array.isArray(S.flags[k]) ? S.flags[k] : [])));
      if (isObj(S.flags.clearedBy)) for (const v of Object.values(S.flags.clearedBy)) if (Array.isArray(v)) v.forEach((x) => known.add(x));
      S.banned.forEach((r, i) => {
        const fl = isObj(r) && isObj(r.match) && Array.isArray(r.match.flags) ? r.match.flags : [];
        fl.forEach((x, j) => { if (known.size && !known.has(x)) err(PARTS, `/strike/banned/${i}/match/flags/${j}`, 'parts-grammar', `row ${r.id} names flag "${x}", which strike.flags does not list`, 'warning'); });
      });
    }
  }
  if (isObj(parts) && isObj(parts.strikes)) {
    for (const id of plain(parts.strikes)) {
      const row = parts.strikes[id];
      if (!isObj(row)) continue;
      const prob = shapeProblem(row);
      if (prob) err(PARTS, `/strikes/${esc(id)}`, 'parts-strike', `${id}: ${prob}`);
      if (manifests.size) {
        const rows = rowsByCombat.get(id);
        if (!rows) err(PARTS, `/strikes/${esc(id)}`, 'parts-strike', `${id} is the combat id of no manifest row`);
        else for (const r of rows) {
          const lb = String(r.limb).replace(/_[lr]$/, '');
          if (lb !== row.limb) err(PARTS, `/strikes/${esc(id)}/limb`, 'parts-strike', `limb "${row.limb}" differs from its manifest row's "${r.limb}" (${r.id}, ${r._wave})`);
          if (!targetFits(row.target, r.target)) err(PARTS, `/strikes/${esc(id)}/target`, 'parts-strike', `target "${row.target}" differs from its manifest row's "${r.target}" (${r.id}, ${r._wave})`);
        }
      }
    }
  }
  if (S && isObj(S.targets) && regions.length) {
    for (const limb of plain(S.targets)) if (isObj(S.targets[limb])) for (const p of plain(S.targets[limb])) if (Array.isArray(S.targets[limb][p])) S.targets[limb][p].forEach((tg, i) => {
      const ok = regions.includes(tg) || (tg === 'arm' && regions.some((r) => /^arm_[lr]$/.test(r)));
      if (!ok) err(PARTS, `/strike/targets/${esc(limb)}/${esc(p)}/${i}`, 'parts-grammar', `target "${tg}" is not a region of sockets.json (${regions.join(', ')})`);
    });
  }

  // ---- identity: the waves have manifests, the tips are tips of the grammar, the fighters are the recipes' ----
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
      if (S && isObj(f.weights) && isObj(f.weights.tip)) for (const k of plain(f.weights.tip)) if (!hasTip(k)) err(IDENT, `${at}/weights/tip/${esc(k)}`, 'identity-ref', `weight for tip "${k}", which is not a tip of parts.json (written limb.tip)`);
      if (S && isObj(f.tipFlags)) for (const k of plain(f.tipFlags)) if (!hasTip(k)) err(IDENT, `${at}/tipFlags/${esc(k)}`, 'identity-ref', `tipFlags for "${k}", which is not a tip of parts.json (written limb.tip)`);
      if (S && Array.isArray(f.weightsBy)) f.weightsBy.forEach((w, i) => { if (isObj(w) && isObj(w.tip)) for (const k of plain(w.tip)) if (!hasTip(k)) err(IDENT, `${at}/weightsBy/${i}/tip/${esc(k)}`, 'identity-ref', `weight for tip "${k}", which is not a tip of parts.json (written limb.tip)`); });
      if (isObj(f.tipOf) && isObj(parts) && isObj(parts.strikes)) for (const id of plain(f.tipOf)) {
        const row = parts.strikes[id];
        if (!isObj(row)) err(IDENT, `${at}/tipOf/${esc(id)}`, 'identity-ref', `tipOf names "${id}", which is no strike of parts.json`);
        else if (S && !(f.tipOf[id] in tipsOf(row.limb))) err(IDENT, `${at}/tipOf/${esc(id)}`, 'identity-ref', `tip "${f.tipOf[id]}" is not a ${row.limb} tip`);
      }
    }
    if (Array.isArray(ident.rejected)) ident.rejected.forEach((r, i) => { if (isObj(r) && typeof r.fighter === 'string' && !plain(ident.fighters).includes(r.fighter)) err(IDENT, `/rejected/${i}/fighter`, 'identity-ref', `rejected shape for "${r.fighter}", who is not a fighter of this file`); });
  }

  // ---- cells: the quotas are well formed and fit in their cell ----
  const formNames = new Set(S && Array.isArray(S.forms) ? S.forms.filter(isObj).map((f) => f.form) : []);
  const sendValues = new Set(S && isObj(S.sends) ? plain(S.sends).map((k) => S.sends[k]) : []);
  const cellOf = (key) => { const [st, btn] = String(key).split('.'); return isObj(cells) && isObj(cells.stances) && isObj(cells.stances[st]) ? cells.stances[st][btn] : undefined; };
  if (isObj(cells) && isObj(cells.stances)) {
    for (const st of plain(cells.stances)) {
      const stance = cells.stances[st];
      if (!isObj(stance)) continue;
      for (const btn of ['x', 'y']) {
        const c = stance[btn];
        if (!isObj(c) || !Array.isArray(c.quotas)) continue;
        const names = new Set();
        c.quotas.forEach((q, i) => {
          if (!isObj(q)) return;
          const at = `/stances/${esc(st)}/${btn}/quotas/${i}`;
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
  const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  const never = (fid) => (isObj(ident) && isObj(ident.fighters) && isObj(ident.fighters[fid]) && Array.isArray(ident.fighters[fid].never) ? ident.fighters[fid].never : []);
  const banned = S && Array.isArray(S.banned) ? S.banned.filter(isObj).map((r) => Object.assign({}, r, { shape: r.match || r.shape })) : [];
  for (const rel of docsFor(/^data\/combat\/movesets\/[^/]+\.json$/)) {
    const ms = get(rel);
    if (!isObj(ms)) continue;
    const fid = ms.fighter;
    if (isObj(ident) && isObj(ident.fighters) && typeof fid === 'string' && !plain(ident.fighters).includes(fid)) err(rel, '/fighter', 'moveset-cell', `fighter "${fid}" is not a fighter of identity.json`);
    if (isObj(ms.generator) && isObj(cells) && Number.isInteger(ms.generator.seed) && Number.isInteger(cells.seed) && ms.generator.seed !== cells.seed) err(rel, '/generator/seed', 'moveset-cell', `seed ${ms.generator.seed} is not cells.json's ${cells.seed}`);
    const waves = isObj(ident) && isObj(ident.fighters) && isObj(ident.fighters[fid]) && Array.isArray(ident.fighters[fid].waves) ? ident.fighters[fid].waves : [];
    if (!isObj(ms.cells)) continue;
    for (const ck of Object.keys(ms.cells)) {
      const cell = ms.cells[ck];
      if (!isObj(cell)) continue;
      const def = cellOf(ck);
      const cat = `/cells/${esc(ck)}`;
      if (isObj(cells) && !isObj(def)) { err(rel, cat, 'moveset-cell', `cell "${ck}" is not in cells.json stances`); continue; }
      if (isObj(def) && def.kind !== cell.kind) err(rel, `${cat}/kind`, 'moveset-cell', `cell "${ck}" is a ${cell.kind} cell here and a ${def.kind} cell in cells.json`);
      if (cell.kind !== 'strikes' || !Array.isArray(cell.moves)) continue;
      if (isObj(def) && typeof def.count === 'number' && cell.moves.length !== def.count) err(rel, `${cat}/moves`, 'moveset-cell', `cell "${ck}" has ${cell.moves.length} moves; cells.json asks for ${def.count}`);
      const seen = new Map();
      cell.moves.forEach((mv, i) => {
        if (!isObj(mv)) return;
        const at = `${cat}/moves/${i}`;
        const want = `mv.${fid}.${ck}.${String(i + 1).padStart(2, '0')}`;
        if (typeof mv.id === 'string' && mv.id !== want) err(rel, `${at}/id`, 'moveset-cell', `move id "${mv.id}" should be "${want}"`);
        if (isObj(def) && isObj(def.filter) && !match(def.filter, mv)) err(rel, at, 'moveset-cell', `move ${mv.id} does not match the cell's filter`);
        const prob = shapeProblem(mv);
        if (prob) err(rel, at, 'moveset-shape', `${mv.id}: ${prob}`);
        const nv = never(fid).find((n) => isObj(n) && match(n.shape, mv));
        if (nv) err(rel, at, 'moveset-shape', `${mv.id} matches a never row of ${fid} (${nv.why})`);
        const bn = banned.find((n) => isObj(n) && match(n.shape, mv)); // a row that names flags is the generator's --check, not a validator's
        if (bn) err(rel, at, 'moveset-shape', `${mv.id} matches a banned shape (${bn.why})`);
        const fp = [mv.limb, mv.tip, mv.path, mv.target, mv.weight].join('|');
        if (seen.has(fp)) err(rel, at, 'moveset-shape', `${mv.id} repeats the shape of move ${seen.get(fp) + 1} in this cell`); else seen.set(fp, i);
        // derived from the grammar
        const keys = isObj(mv.keys) ? mv.keys : {};
        const from = keys.level !== 'new' && typeof keys.from === 'string' && isObj(parts) && isObj(parts.strikes) ? parts.strikes[keys.from] : undefined;
        const arms = isObj(from) && isObj(from.uses) && Number.isInteger(from.uses.arms) ? from.uses.arms : (mv.limb === 'hand' || mv.limb === 'elbow' ? 1 : 0);
        if (S) {
          if (!same(mv.sends, S.sends && S.sends[mv.path])) err(rel, `${at}/sends`, 'moveset-derived', `sends ${JSON.stringify(mv.sends)} is not what the grammar gives for path "${mv.path}"`);
          if (!same(mv.links, S.links && S.links[mv.path])) err(rel, `${at}/links`, 'moveset-derived', `links are not what the grammar gives for path "${mv.path}"`);
          if (!same(mv.step, S.step && S.step[mv.path])) err(rel, `${at}/step`, 'moveset-derived', `step is not what the grammar gives for path "${mv.path}"`);
          if (mv.beat !== (S.beat && S.beat[mv.path])) err(rel, `${at}/beat`, 'moveset-derived', `beat ${mv.beat} is not what the grammar gives for path "${mv.path}"`);
          const forms = deriveForms(mv, arms);
          if (Array.isArray(mv.forms) && !same(mv.forms, forms)) err(rel, `${at}/forms`, 'moveset-derived', `forms ${JSON.stringify(mv.forms)} are not what the grammar gives (${JSON.stringify(forms)})`);
        }
        // Legal's conditions that apply, and the arms
        if (Array.isArray(mv.asks) && S && Array.isArray(S.conditions)) {
          const ids = new Set(S.conditions.filter(isObj).map((c) => c.id));
          mv.asks.forEach((a, j) => { if (!ids.has(a)) err(rel, `${at}/asks/${j}`, 'moveset-keys', `"${a}" is no condition of parts.json strike.conditions`); });
        }
        if (Number.isInteger(mv.arms) && mv.arms !== arms) err(rel, `${at}/arms`, 'moveset-derived', `arms ${mv.arms} is not what the grammar gives (${arms})`);
        // status and keys
        const status = { posed: 'posed', hand_state: 'derived', re_aim: 'derived', hand_state_re_aim: 'derived', new: 'waiting' }[keys.level];
        if (status && mv.status !== status) err(rel, `${at}/status`, 'moveset-keys', `status "${mv.status}" does not follow keys.level "${keys.level}" (${status})`);
        if (keys.level === 'new') {
          if (keys.from !== undefined || keys.set !== undefined) err(rel, `${at}/keys`, 'moveset-keys', 'a new move has no from or set');
        } else if (keys.level !== undefined) {
          if (typeof keys.from !== 'string' || typeof keys.set !== 'string') err(rel, `${at}/keys`, 'moveset-keys', `a ${keys.level} move needs from and set`);
          else if (manifests.size) {
            const row = waves.map((w) => manifests.get(w)).filter(Boolean).flatMap((m) => m.strikes).find((r) => isObj(r) && r.id === keys.set);
            if (!row) err(rel, `${at}/keys/set`, 'moveset-keys', `key set "${keys.set}" is a row of none of ${fid}'s manifests (${waves.join(', ')})`);
            else if (row.combat !== keys.from) err(rel, `${at}/keys/from`, 'moveset-keys', `key set "${keys.set}" is the strike "${row.combat}", not "${keys.from}"`);
            if (isObj(parts) && isObj(parts.strikes) && !isObj(parts.strikes[keys.from])) err(rel, `${at}/keys/from`, 'moveset-keys', `"${keys.from}" is no strike of parts.json`);
          }
        }
      });
      // the quotas the cell asks for are met, and the recorded counts are right
      if (isObj(def) && Array.isArray(def.quotas)) for (const q of def.quotas) {
        if (!isObj(q)) continue;
        const n = cell.moves.filter((mv) => isObj(mv) && (q.filter ? match(q.filter, mv) : q.any ? q.any.some((g) => match(g, mv)) : q.form ? Array.isArray(mv.forms) && mv.forms.includes(q.form) : q.sends ? mv.sends === q.sends : false)).length;
        if (typeof q.min === 'number' && n < q.min) err(rel, `${cat}/moves`, 'moveset-cell', `quota "${q.name}" needs ${q.min} moves and the cell has ${n}`);
        if (isObj(cell.quotas) && cell.quotas[q.name] !== n) err(rel, `${cat}/quotas/${esc(q.name)}`, 'moveset-cell', `the recorded count ${cell.quotas[q.name]} for quota "${q.name}" is ${n} on recount`);
      }
    }
  }
}

module.exports = { xrefMovegen };
