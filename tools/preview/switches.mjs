// The switches of the new planet and the scratch changes the private preview build makes (tools/preview/preview.mjs, docs/tools/preview.md). Pure: text in, text out; nothing here touches a file.
//
// A switch is one flag in a data file, flipped by editing the file's TEXT in a scratch copy (the key's value only, so the file keeps its layout and every comment key). The table says what each
// switch is, where it lives, what it was and what it becomes, and which switches it needs: a load error of the game's own (WorldFill.floorProblem) refuses a floor without both halves of the
// surfacing rule, so turning one off turns off what needs it, and the preview says so.
//
// Two scratch code changes ride along, both to render/core/main.gd of the scratch copy only (patchMain): a `?planet=N` entry (the shipped game builds a generated planet only when a match's setup
// names one, and no menu or URL does yet, so without it a gen 2 switch changes nothing a player sees) and a state probe `?preview=1` (window.__preview, read by the smoke check).

import { createHash } from 'node:crypto';

export const SWITCHES = [
  { id: 'gen2', file: 'data/biomes/climate.json', path: ['gen'], from: 1, to: 2, needs: [],
    what: 'planet generation 2 (climate, 15 fine biomes, lakes, sites) for every planet match instead of the stored planet' },
  { id: 'biome', file: 'data/combat/launch_biome.json', path: ['biome', 'enabled'], from: false, to: true, needs: [],
    what: 'the launch planner reads the ground (cliffs, ice, marsh, trees, vents) and its surface (biome.enabled)' },
  { id: 'water', file: 'data/biomes/water.json', path: ['enabled'], from: false, to: true, needs: [],
    what: 'water v2: holes fill from the sea, lakes and the water table; wading; the crater wave; the douse' },
  { id: 'surface', file: 'data/biomes/water.json', path: ['surface', 'enabled'], from: false, to: true, needs: [],
    what: 'surfacing, the world half: a launched body that lands in water is brought up to the surface' },
  { id: 'interrupts', file: 'data/director/interrupts.json', path: ['water', 'enabled'], from: false, to: true, needs: [],
    what: 'surfacing, the director half: a drop (the zip\'s knock-down) under water is brought up and counts as landed' },
  { id: 'floor', file: 'data/biomes/water.json', path: ['floor', 'enabled'], from: false, to: true, needs: ['surface', 'interrupts'],
    what: 'the lake floor: a free fighter\'s floor in the ring\'s own water is its surface less his feet (needs both halves of surfacing)' },
  { id: 'turn', file: 'data/biomes/rings.json', path: ['turn', 'on'], from: 0, to: 1, needs: [],
    what: 'the arena\'s calm turn: at a calm moment after a launch has landed, the ring swaps for a new one turned a few degrees (at most 4 a match, 60 s apart)' },
  { id: 'rightStick', file: 'data/input/timing.json', path: ['switches', 'rightStick'], from: false, to: true, needs: [], optional: true, host: 'right-hand-host',
    probe: '"rightStick": SimInputData.right_stick_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func right_stick_on' },
    what: 'the right-hand attacks (pitch 4a, Controls): the right stick throws directional-charge strikes, the left hand braces and slips; the pad\'s right stick is read. Waits until Controls\' code is in the tree you build (or overlaid)' },
];

export const IDS = SWITCHES.map((s) => s.id);

/** The switches of a build: the table above, and the rows of tools/preview/switches-pending.json that name a file and a key (a row without them is a name waiting for its key and is never a switch). */
export function tableWith(pending = []) {
  const known = new Set(SWITCHES.map((s) => s.id));
  return [...SWITCHES, ...pending.filter((r) => r && r.file && Array.isArray(r.path) && !known.has(r.id)).map((r) => ({ needs: [], optional: true, ...r }))];
}

/** Checks the rows of switches-pending.json (text in). Returns { rows, problems }: every row needs an id and a line saying what it is and who lands it; a row with a file also needs a path, from and to. */
export function loadPending(text) {
  const problems = [];
  let doc = null;
  try { doc = JSON.parse(text); } catch (e) { return { rows: [], problems: [`switches-pending.json is not JSON: ${e.message}`] }; }
  const rows = Array.isArray(doc.rows) ? doc.rows : [];
  const seen = new Set(SWITCHES.map((s) => s.id));
  rows.forEach((r, i) => {
    const at = `row ${i}${r && r.id ? ` (${r.id})` : ''}`;
    if (!r || typeof r.id !== 'string' || !/^[a-zA-Z][a-zA-Z0-9]*$/.test(r.id)) { problems.push(`${at}: needs an id of letters and digits`); return; }
    if (seen.has(r.id)) problems.push(`${at}: the id is already a switch or a row`);
    seen.add(r.id);
    if (typeof r.what !== 'string' || !r.what.trim() || typeof r.owner !== 'string' || !r.owner.trim()) problems.push(`${at}: needs "what" and "owner"`);
    if (r.file !== undefined && !(typeof r.file === 'string' && Array.isArray(r.path) && r.path.length && 'from' in r && 'to' in r)) problems.push(`${at}: a row with a file needs path (an array), from and to`);
    if (r.needs !== undefined && !(Array.isArray(r.needs) && r.needs.every((n) => typeof n === 'string'))) problems.push(`${at}: needs is a list of ids`);
  });
  return { rows, problems };
}

/** Where a key's value is in a JSON text: { start, end } of the value, or null. Walks the text (strings, nesting) without parsing the whole file, so the edit keeps everything else as it was. */
export function locate(text, path) {
  let i = text.charCodeAt(0) === 0xfeff ? 1 : 0;
  const ws = () => { while (i < text.length && /\s/.test(text[i])) i++; };
  const str = () => { const s0 = i; i++; while (i < text.length && text[i] !== '"') { if (text[i] === '\\') i++; i++; } i++; return JSON.parse(text.slice(s0, i)); };
  const skip = () => {
    ws();
    const c = text[i];
    if (c === '"') { str(); return; }
    if (c === '{' || c === '[') {
      const close = c === '{' ? '}' : ']';
      i++; ws();
      if (text[i] === close) { i++; return; }
      for (;;) {
        ws();
        if (c === '{') { str(); ws(); i++; }
        skip(); ws();
        if (text[i] === ',') { i++; continue; }
        i++; return;
      }
    }
    while (i < text.length && !/[,}\]\s]/.test(text[i])) i++;
  };
  const walk = (depth) => {
    ws();
    if (text[i] !== '{') return null;
    i++;
    for (;;) {
      ws();
      if (i >= text.length) return null;
      if (text[i] === '}') { i++; return null; }
      const key = str(); ws(); i++; ws();
      if (key === path[depth]) {
        if (depth === path.length - 1) { const start = i; skip(); return { start, end: i }; }
        const at = i;
        const r = walk(depth + 1);
        if (r) return r;
        if (i === at) skip();   // the value was not an object: step over it
      } else skip();
      ws();
      if (text[i] === ',') i++;
    }
  };
  return walk(0);
}

/** The text with a switch turned on. Returns { text, was }: was is the old literal. Throws, naming the file and key, when the key is not there or holds neither the old nor the new value (the table is stale). */
export function flip(text, sw) {
  const loc = locate(text, sw.path);
  if (!loc) throw new Error(`${sw.file}: no key ${sw.path.join('.')} (the switch table in tools/preview/switches.mjs is out of date)`);
  const was = text.slice(loc.start, loc.end);
  const from = JSON.stringify(sw.from), to = JSON.stringify(sw.to);
  if (was !== from && was !== to) throw new Error(`${sw.file}: ${sw.path.join('.')} is ${was}, not ${from} or ${to} (the switch table in tools/preview/switches.mjs is out of date)`);
  const out = text.slice(0, loc.start) + to + text.slice(loc.end);
  let v = JSON.parse(out.charCodeAt(0) === 0xfeff ? out.slice(1) : out);
  for (const k of sw.path) v = v == null ? undefined : v[k];
  if (v !== sw.to) throw new Error(`${sw.file}: after the edit ${sw.path.join('.')} reads ${JSON.stringify(v)}, not ${to}`);
  return { text: out, was };
}

/** Which switches are on, given the ids turned off ("all" turns every one off). Turning one off turns off what needs it. Returns { active, cascaded: [{ id, because }], unknown }. */
export function resolve(off = [], table = SWITCHES) {
  const IDS = table.map((s) => s.id);
  const want = new Set(off.flatMap((o) => String(o).split(',')).map((s) => s.trim()).filter(Boolean));
  const unknown = [...want].filter((id) => id !== 'all' && !IDS.includes(id));
  const active = new Set(want.has('all') ? [] : IDS.filter((id) => !want.has(id)));
  const cascaded = [];
  for (let again = true; again;) {
    again = false;
    for (const sw of table) {
      if (!active.has(sw.id)) continue;
      const missing = sw.needs.filter((n) => !active.has(n));
      if (missing.length) { active.delete(sw.id); cascaded.push({ id: sw.id, because: missing }); again = true; }
    }
  }
  return { active: IDS.filter((id) => active.has(id)), cascaded, unknown };
}

/** Which switch a load error or console line is about, by the file or module it names. A hint for the report, not a proof. */
export function errorSwitch(line) {
  const t = String(line);
  if (/water\.json[^\n]*floor|floor needs/i.test(t)) return 'floor';
  if (/water\.json[^\n]*surface|surfacing/i.test(t)) return 'surface';
  if (/interrupts\.json|DirWater|DirInterrupt/i.test(t)) return 'interrupts';
  if (/water\.json|WorldFill|water v2/i.test(t)) return 'water';
  if (/rings\.json|WorldEpoch/i.test(t)) return 'turn';
  if (/right_stick|rightStick|strike_read|SimStrike|left_hand/i.test(t)) return 'rightStick';
  if (/launch_biome|DirLaunch|biome\.enabled/i.test(t)) return 'biome';
  if (/climate\.json|WorldClimate|WorldPlanet|planet gen|lakes\.json|sites\.json/i.test(t)) return 'gen2';
  return null;
}

// ---- the scratch changes to render/core/main.gd ----

/** The probe and the planet entry, as GDScript (tab-indented). `planetFunc(extra)` adds probe fields (a switch's `probe` line) when the tree has what they read. */
export const PLANET_FUNC = [
  '',
  '',
  '## Scratch (tools/preview): the planet part of a match\'s setup. The next menu-started match\'s own (planet_part) when it has one, else ?planet=N from the URL (a generated planet; touch 3 as the golden planet matches use).',
  'func _preview_planet() -> Dictionary:',
  '\tif not _planet_next.is_empty():',
  '\t\treturn _planet_next.duplicate()',
  '\tif args.has("planet"):',
  '\t\treturn {"planet": int(args["planet"]), "touch": int(args.get("touch", 3))}',
  '\treturn {}',
  '',
  '',
  '## Scratch (tools/preview): ?preview=1 publishes window.__preview twice a second, for the smoke check: the tick, the planet\'s generation, what each switch reads as in the running game, and the fighters\' hit points.',
  'func _preview_probe() -> void:',
  '\tif frames % 20 != 0:',
  '\t\treturn',
  '\tvar st = host.S',
  '\tvar hp: Array = []',
  '\tfor f in st.fighters:',
  '\t\thp.append(snappedf(f.hp, 0.1))',
  '\tvar probe: Dictionary = {"tick": host.ticks, "planetGen": WorldClimate.genNow(), "fine": st.fineCols.size(), "planet": not st.planetRing.is_empty(), "dataGen": int(WorldClimate.data().get("gen", 1)),',
  '\t\t"biome": DirLaunch.biomeOn(), "water": WorldFill.on(), "surface": WorldFill.surfaceOn(), "floor": WorldFill.floorOn(), "interrupts": DirWater.on(st), "turn": WorldEpoch.enabled({}), "turns": (st.epoch.n if st.epoch != null else -1),',
  '\t\t"errors": WorldFill.dataErrors(), "hp": hp}',
  '\tJavaScriptBridge.eval("window.__preview = %s;" % JSON.stringify(probe), true)',
  '',
].join('\n');

export function planetFunc(extra = []) {
  const line = '\t\t"errors": WorldFill.dataErrors(), "hp": hp}';
  if (!PLANET_FUNC.includes(line)) throw new Error('tools/preview/switches.mjs: the probe line moved (planetFunc is out of date)');
  return extra.length ? PLANET_FUNC.replace(line, () => `\t\t${extra.join(', ')},\n${line}`) : PLANET_FUNC;
}

const EDITS = [
  { name: 'the match setup\'s planet part (no-intro and hook starts)', from: '\t\treturn _planet_next.duplicate()\n', to: '\t\treturn _preview_planet()\n' },
  { name: 'the match setup\'s planet part (the intro start)', from: '\tsu.merge(_planet_next)\n', to: '\tsu.merge(_preview_planet())\n' },
  { name: 'the menu start without intros', from: '\t\tvar su: Dictionary = _planet_next.duplicate()\n', to: '\t\tvar su: Dictionary = _preview_planet()\n' },
  { name: 'the options the URL may set', from: 'const URL_ARGS: Array = ["nointro", ', to: 'const URL_ARGS: Array = ["planet", "touch", "preview", "nointro", ' },
  { name: 'the per-frame hook', from: '\tvar n: int = host.advance(delta, vp.x, vp.y)\n', to: '\tvar n: int = host.advance(delta, vp.x, vp.y)\n\tif args.has("preview"):\n\t\t_preview_probe()\n' },
];

/** A short fingerprint of the scratch patch and the switch table: a cached build is reused only for the same patch. */
export const EDITS_FINGERPRINT = createHash('sha1').update(JSON.stringify([EDITS, PLANET_FUNC, SWITCHES])).digest('hex').slice(0, 6);

/** main.gd with the planet entry and the probe. Each anchor must be there exactly once, or this throws and says which (Rendering's main.gd changed: update EDITS). Keeps the file's line endings. */
export function patchMain(text, extra = []) {
  const crlf = text.includes('\r\n');
  const nl = (s) => (crlf ? s.replace(/\n/g, '\r\n') : s);
  let out = text;
  for (const e of EDITS) {
    const from = nl(e.from);
    const n = out.split(from).length - 1;
    if (n !== 1) throw new Error(`render/core/main.gd: ${e.name}: expected the line once, found it ${n} times (tools/preview/switches.mjs EDITS is out of date)`);
    out = out.replace(from, () => nl(e.to));
  }
  return out.replace(/\s*$/, '') + nl(planetFunc(extra));
}
