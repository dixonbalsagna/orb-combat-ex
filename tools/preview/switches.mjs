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
  { id: 'calmTurn', file: 'data/director/interrupts.json', path: ['calmTurn', 'enabled'], from: false, to: true, needs: [],
    what: 'the calm turn, the director\'s half (DirCalm.on): without it the director never asks and the turn never happens, whatever rings.json says. Found by QA, 2026-10-31: `turn` alone gave 0 turns in 200 matches' },
  { id: 'turn', file: 'data/biomes/rings.json', path: ['turn', 'on'], from: 0, to: 1, needs: ['calmTurn'],
    what: 'the arena\'s calm turn (World\'s half, rings.json turn.on; it needs calmTurn, the director\'s half): at a calm moment after a launch has landed, the ring swaps for a new one turned a few degrees (at most 4 a match, 60 s apart)' },
  { id: 'rightStick', file: 'data/input/timing.json', path: ['switches', 'rightStick'], from: false, to: true, needs: [], optional: true, host: 'right-hand-host',
    probe: '"rightStick": SimInputData.right_stick_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func right_stick_on' },
    what: 'the right-hand attacks (pitch 4a, Controls): the right stick throws directional-charge strikes, the left hand braces and slips; the pad\'s right stick is read. Waits until Controls\' code is in the tree you build (or overlaid)' },
  { id: 'quickRead', file: 'data/input/timing.json', path: ['switches', 'quickRead'], from: false, to: true, needs: [], optional: true,
    probe: '"quickRead": SimInputData.quick_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func quick_on' },
    what: 'the quick read (Controls, responsiveness): the strike and the brace read one tick sooner, the vanish resolves on the second press, and the layout publishes the stick\'s pre-read for the pose. timing.json switches.quickRead. Waits until Controls\' code and keys are in the tree (docs/controls/pending/quick-read)' },
  { id: 'hapticLadder', file: 'data/input/timing.json', path: ['switches', 'hapticLadder'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"hapticLadder": SimInputData.haptic_ladder_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func haptic_ladder_on' },
    what: 'the strike charge\'s ladder on the pad (Controls, pitch 1): a held stick strike pulses once as each rung is reached, 12 / 30 / 50 live ticks from the request; none for a quick flick. Needs the right hand. timing.json switches.hapticLadder. Waits for docs/controls/pending/stick-feel' },
  { id: 'hapticIncoming', file: 'data/input/timing.json', path: ['switches', 'hapticIncoming'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"hapticIncoming": SimInputData.haptic_incoming_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func haptic_incoming_on' },
    what: 'the incoming cue on the defender\'s pad (Controls, pitch 3): one cue when a rival\'s stick strike starts, high for toward and up, low for away and down; the striker feels nothing. Needs the right hand. timing.json switches.hapticIncoming. Waits for docs/controls/pending/stick-feel' },
  { id: 'gen3', setup: { planetGen: 3 }, presentIf: { file: 'sim/world/field.gd' }, needs: [], optional: true,
    what: 'planet generation 3 (World\'s field world): the match\'s setup says planetGen 3 on a whole ring (no arena key), not a data flag. Waits until the tree has World\'s code (sim/world/field.gd)' },
  { id: 'go', url: 'go=1', presentIf: { file: 'ui/core/ui_prefs.gd' }, needs: [], optional: true,
    what: 'the private page for a person with a pad (the EP, 2026-11-01): ?go=1 on a local page sets, before the start menu loads, Player 1 = Controller and Intros off if the player has not chosen otherwise, and counts the How to play card as seen. The notice card and its "I understand, start" stay, a deliberate click. Nothing already chosen is overwritten.' },
  { id: 'meteor', url: 'meteor=loud', alt: { word: 'meteor=quiet', label: 'the quiet trail' }, presentIf: { file: 'data/vfx/meteor.json' }, needs: [], optional: true,
    probe: '"meteor": host.vfx.meteor_enabled', probeIf: { file: 'render/vfx/vfx_hub.gd', text: 'meteor_enabled' },
    what: 'VFX\'s meteor trail: a fighter\'s own burn laid along his path and cooling in the world. A page word on a local page (?meteor=loud, the default here, or ?meteor=quiet: two sets of numbers for Orb to pick between); no word, the trail is off and byte-identical off. The printed address carries the loud word and the quiet one is printed beside it. Waits until the tree has VFX\'s data/vfx/meteor.json' },
  { id: 'tiles', url: 'tiles=1', cmd: '--tiles', alt: { add: 'nofore=1', label: 'the fore tone OFF, to compare (Rendering\'s page word; on by default)' }, presentIf: { file: 'render/core/tile_ground.gd' }, needs: ['gen3'], optional: true,
    what: 'Rendering\'s tile ground (stage 4 of the ring-at-any-angle work): the fight on planet-keyed tiles on a true globe, through Simulation\'s frame. A page word for now (?tiles=1, local pages only): the printed address carries it. Needs gen3 and waits until the tree has render/core/tile_ground.gd' },
  { id: 'swing', file: 'data/director/swing.json', path: ['enabled'], from: false, to: true, needs: ['gen3'], optional: true,
    probe: '"swings": (st.swing.n if st.swing != null else -1), "swing": ({"on": st.swing.active, "rate": snappedf(st.swing.rate, 0.1), "left": snappedf(st.swing.left, 0.1), "cause": st.swing.cause, "kind": st.swing.kind} if st.swing != null else {}), "fst": [st.fighters[0].state, st.fighters[1].state], "ln": [st.fighters[0].launchN, st.fighters[1].launchN], "pz": [st.pause.left, snappedf(st.dirS.stop, 0.01)]',
    probeMore: [{ line: '"mv": SimSwing.movingNow(st)', probeIf: { file: 'sim/core/swing.gd', text: 'func movingNow' } },
      { line: '"swingOn": DirSwing.on(st)', probeIf: { file: 'sim/director/swing.gd', text: 'static func on(S: SimState)' } },
      { line: '"stickOn": DirStick.on()', probeIf: { file: 'sim/director/stick.gd', text: 'static func on() -> bool' } }], probeIf: { file: 'sim/core/state.gd', text: 'var swing = null' },
    what: 'DirSwing (Encounter): the choreographer\'s swing: a launch, a chase, a form\'s pause, an AI\'s flight and a brawl each offer the line a turn, which the core\'s SimSwing runs. data/director/swing.json `enabled`; it does nothing but on a field world, so it needs gen3 (setup planet, touch, planetGen 3). Waits until the tree has Encounter\'s code' },
  { id: 'everywhere', file: 'data/biomes/field.json', path: ['plans', 'everywhere'], from: false, to: true, needs: ['gen3'], optional: true,
    probe: '"everywhere": WorldPlan.everywhere()', probeIf: { file: 'sim/world/plan.gd', text: 'static func everywhere' },
    what: 'buildings at every place (World, docs/world/places-everywhere.md): each place the first ring does not hold is laid as the whole of its plan, planet-fixed, with no people, so a swing or a launch onto any town finds real buildings. data/biomes/field.json plans.everywhere. Gen 3 only. Waits until the tree has World\'s park (docs/world/pending/places-everywhere)' },
  { id: 'arc', file: 'data/director/launch.json', path: ['arc', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"arc": DirArc.on()', probeIf: { file: 'sim/director/arc.gd', text: 'static func on' },
    what: 'the meteor launch, one curve, with ignition (Encounter, docs/director/pending/meteor and meteor-2; row 5 of rule-of-cool-map.md): a heavy charged to full at tier 4 with two forms each goes up one authored curve, the meteor on a stunned or weak foe. data/director/launch.json arc.enabled. Try it from a training start: ?tier=4. Waits until the tree has Encounter\'s park' },
  { id: 'beamFront', file: 'data/director/interrupts.json', path: ['beamPlays', 'front', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"beamFront": DirBeamPlay.frontOn()', probeIf: { file: 'sim/director/beamplay.gd', text: 'static func frontOn' },
    what: 'beams that travel, and the window to answer (Encounter, docs/director/pending/beam-front; row 40 of rule-of-cool-map.md): the beam takes ticks from hand to him, the hit is decided at arrival, and he can fire back, dodge in the last 14 ticks or block. data/director/interrupts.json beamPlays.front.enabled. Waits until the tree has Encounter\'s park' },
  { id: 'kick', file: 'data/fight/kick.json', path: ['enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"kick": SimKick.enabled()', probeIf: { file: 'sim/core/kick.gd', text: 'static func enabled' },
    what: 'the kick and the coin turn (Simulation, docs/architecture/kick.md; rule-of-cool-map.md row 23): flat out from under half of top speed leaves at `instant` of top speed on the first tick (default 0.8) and reaches top speed over `climbTicks` (default 8) (Orb: instant, or at least instant to about 80%); a stick flip above half of top speed brakes, plants and kicks the other way. The overspeed is its own switch and off. Page words to try values: ?instant=0.9&climbTicks=4 (the printed sample addresses). data/fight/kick.json enabled. A setup\'s "kick" overrides it for a match: the page word ?kick=1 puts true in the setup, ?kick=off puts false (to compare). Waits until the tree has Simulation\'s park (docs/architecture/pending/kick)' },
  { id: 'mixed', file: 'data/combat/mixed.json', path: ['enabled'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"mixed": DirMixed.on()', probeIf: { file: 'sim/director/mixed.gd', text: 'static func on' },
    what: 'the mixed string (Combat, Orb\'s clip C9; docs/design/energy-overhaul.md section 21): a send or a knock opens a string across any range, and in it a tapped far heavy is a lob aimed where he is going, timed to land as he does. data/combat/mixed.json enabled. Needs the right hand. A prototype nobody has played. Waits until the tree has Combat\'s park (docs/combat/pending/mixed-string)' },
  { id: 'struggle', file: 'data/director/interrupts.json', path: ['beamStruggle', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"struggle": DirBeam.struggleOn()', probeIf: { file: 'sim/director/beam.gd', text: 'static func struggleOn' },
    alt: { add: 'struggle=off', label: 'the beam struggle OFF (Encounter\'s page word; on by default here)' },
    what: 'the beam struggle on the pulse: surges, strays and letting go (Encounter; Game Design\'s redesign after Orb\'s playtest of 2026-10-16: what you press during the clash moves the outcome). data/director/interrupts.json beamStruggle.enabled. On by default on the private page; ?struggle=off on a local page turns it off. Waits until the tree has Encounter\'s park (docs/director/pending/beam-struggle)' },
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

/** Whether a switch's key is in a file's text: its path in JSON, or (a switch that is a constant in a script) its text, as it is off or on. */
export function present(text, sw) {
  if (sw.replace) return text.includes(sw.replace.from) || text.includes(sw.replace.to);
  return !!locate(text, sw.path);
}

/** The text with a switch turned on. Returns { text, was }: was is the old literal. Throws, naming the file and key, when the key is not there or holds neither the old nor the new value (the table is stale). */
export function flip(text, sw) {
  if (sw.replace) {   // a constant in a script: its text appears exactly once, off or on
    const { from, to } = sw.replace;
    const nFrom = text.split(from).length - 1, nTo = text.split(to).length - 1;
    if (nFrom === 1 && nTo === 0) return { text: text.replace(from, () => to), was: from };
    if (nTo === 1 && nFrom === 0) return { text, was: to };
    throw new Error(`${sw.file}: the text "${from}" is there ${nFrom} times and "${to}" ${nTo} (exactly one of them once was expected: the switch table in tools/preview/switches.mjs is out of date)`);
  }
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
  if (/meteor/i.test(t)) return 'meteor';
  if (/WorldField|SimField|field world|planetGen 3/i.test(t)) return 'gen3';
  if (/launch_biome|DirLaunch|biome\.enabled/i.test(t)) return 'biome';
  if (/climate\.json|WorldClimate|WorldPlanet|planet gen|lakes\.json|sites\.json/i.test(t)) return 'gen2';
  return null;
}

// ---- the scratch changes to render/core/main.gd ----

/** The probe and the planet entry, as GDScript (tab-indented). `planetFunc(extra)` adds probe fields (a switch's `probe` line) when the tree has what they read. */
export const PLANET_FUNC = [
  '',
  '',
  '## Scratch (tools/preview): ?go=1 on a LOCAL page: before the HUD loads its start menu, Player 1 is a controller and Intros are off unless the player saved other choices, and the How to play card counts as seen.',
  'func _preview_go() -> void:',
  '\tif not args.has("go"):',
  '\t\treturn',
  '\tif not (OS.has_feature("web") and bool(JavaScriptBridge.eval("location.hostname === \'127.0.0.1\' || location.hostname === \'localhost\'", true))):',
  '\t\treturn',
  '\tvar m = UiPrefs.get_value("menu", {})',
  '\tvar d: Dictionary = m if m is Dictionary else {}',
  '\tif not d.has("p1"):',
  '\t\td["p1"] = "pad"',
  '\tif not d.has("intros"):',
  '\t\td["intros"] = false',
  '\tUiPrefs.set_value("menu", d)',
  '\tUiPrefs.set_bool("howto_seen", true)',
  '\tprint("[preview] go: menu prefs now ", UiPrefs.get_value("menu", {}), " howto_seen ", UiPrefs.get_bool("howto_seen"))',
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
  '## Scratch (tools/preview): ?preview=1 publishes window.__preview twice a second (every frame with ?reel=1), for the smoke check: the tick, the planet\'s generation, what each switch reads as in the running game, and the fighters\' hit points.',
  'func _preview_probe() -> void:',
  '\tif frames % 20 != 0 and not args.has("reel"):',
  '\t\treturn',
  '\tvar st = host.S',
  '\tvar hp: Array = []',
  '\tfor f in st.fighters:',
  '\t\thp.append(snappedf(f.hp, 0.1))',
  '\tvar probe: Dictionary = {"tick": host.ticks, "planetGen": WorldClimate.genNow(), "fine": st.fineCols.size(), "planet": not st.planetRing.is_empty(), "dataGen": int(WorldClimate.data().get("gen", 1)),',
  '\t\t"biome": DirLaunch.biomeOn(), "water": WorldFill.on(), "surface": WorldFill.surfaceOn(), "floor": WorldFill.floorOn(), "interrupts": DirWater.on(st), "turn": (WorldEpoch.enabled({}) and bool(DirCalm.cfg().get("enabled", false))), "turns": (st.epoch.n if st.epoch != null else -1),',
  '\t\t"errors": WorldFill.dataErrors(), "hp": hp}',
  '\tJavaScriptBridge.eval("window.__preview = %s;" % JSON.stringify(probe), true)',
  '',
].join('\n');

export function planetFunc(extra = [], setup = {}, opts = {}) {
  const line = '\t\t"errors": WorldFill.dataErrors(), "hp": hp}';
  if (!PLANET_FUNC.includes(line)) throw new Error('tools/preview/switches.mjs: the probe line moved (planetFunc is out of date)');
  const swingsOff = [
    '## Scratch (tools/preview): ?swings=off on a LOCAL page turns DirSwing off before a match starts (Encounter\'s page word; DirSwing.setForce(0)).',
    'func _preview_swings_off() -> void:',
    '\tif OS.has_feature("web") and bool(JavaScriptBridge.eval("(location.hostname === \'127.0.0.1\' || location.hostname === \'localhost\') && location.search.indexOf(\'swings=off\') >= 0", true)):',
    '\t\tDirSwing.setForce(0)',
    '',
    '',
  ].join('\n');
  const sticks = [
    '## Scratch (tools/preview): ?sticks=1 on a LOCAL page: player 1 is claimed by a scripted pad and its right stick is driven every tick: a quick flick at phase 30 and a held charge at 120 to 170 of every 240 ticks, the direction turning each 240; the stick cues are counted (stk).',
    'var _pv_claimed: bool = false',
    'var _pv_stick_n: int = 0',
    'var _pv_stick_kinds: Dictionary = {}',
    'var _pv_conn: bool = false',
    'func _preview_sticks() -> void:',
    '\tif not args.has("sticks") or host == null or host.S == null:',
    '\t\treturn',
    '\tif not (OS.has_feature("web") and bool(JavaScriptBridge.eval("location.hostname === \'127.0.0.1\' || location.hostname === \'localhost\'", true))):',
    '\t\treturn',
    '\tif not _pv_claimed:',
    '\t\t_pv_claimed = true',
    '\t\thost.hub.pad_button(0, "back", true)',
    '\t\thost.hub.pad_button(0, "back", false)',
    '\t\thost.take_players()',
    '\tif host.S.fighters[0].ai != null:',
    '\t\thost.toggle_ai(0)',
    '\tvar t: int = host.ticks',
    '\tvar ph: int = t % 240',
    '\tvar dirs: Array = [Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(-1.0, 0.0), Vector2(0.0, -1.0)]',
    '\tvar d: Vector2 = dirs[(t / 240) % 4]',
    '\tif (ph >= 30 and ph < 34) or (ph >= 120 and ph < 170):',
    '\t\thost.hub.pad_stick_right(0, d.x, d.y)',
    '\telse:',
    '\t\thost.hub.pad_stick_right(0, 0.0, 0.0)',
    '\t# the signature (the arena pad\'s east button): a tap at phase 200 to 203 of every 240 ticks, so a beam goes out whenever there is the ki for it, and a clash can follow',
    '\thost.hub.pad_button(0, "east", ph >= 200 and ph < 204)',
    '\tif not _pv_conn:',
    '\t\t_pv_conn = true',
    '\t\thost.drained.connect(_pv_on_drained)',
    '',
    '',
    '## The sim\'s events are cleared at the end of host.advance (S.out.fx.clear()), so they are counted where the host hands them out, on its drained signal.',
    'func _pv_on_drained(events: Array, _lines: Array) -> void:',
    '\tfor e in events:',
    '\t\tif str(e.type) == "cue" and str(e.kind).begins_with("stick_"):',
    '\t\t\t_pv_stick_n += 1',
    '\t\t\t_pv_stick_kinds[str(e.kind)] = int(_pv_stick_kinds.get(str(e.kind), 0)) + 1',
    '',
    '',
  ].join('\n');
  const struggleOff = [
    '## Scratch (tools/preview): ?struggle=off on a LOCAL page turns the beam struggle off before a match starts (Encounter\'s page word): beamStruggle.enabled false in DirInterrupt\'s loaded data.',
    'func _preview_struggle_off() -> void:',
    '\tif OS.has_feature("web") and bool(JavaScriptBridge.eval("(location.hostname === \'127.0.0.1\' || location.hostname === \'localhost\') && location.search.indexOf(\'struggle=off\') >= 0", true)):',
    '\t\tvar bs = DirInterrupt.data().get("beamStruggle", {})',
    '\t\tbs["enabled"] = false',
    '',
    '',
  ].join('\n');
  const kickLines = [
    '\tif args.has("kick"):',
    '\t\td["kick"] = str(args["kick"]) != "off" and str(args["kick"]) != "0"',
    '\t# the takeoff, for Orb to try (Simulation\'s kick: the share of top speed on the first tick, and the ticks from there to top speed): the same names as the setup keys',
    '\tif args.has("instant"):',
    '\t\td["instant"] = clampf(float(args["instant"]), 0.0, 1.0)',
    '\tif args.has("climbTicks"):',
    '\t\td["climbTicks"] = clampi(int(args["climbTicks"]), 0, 120)',
  ];
  const tierLines = [
    '\t# a training start (Encounter\'s meteor-2: both fighters on the ladder\'s own start at this tier), e.g. ?tier=4',
    '\tif args.has("tier"):',
    '\t\td["startTier"] = clampi(int(args["tier"]), 1, 4)',
  ];
  const kickWord = [
    '## Scratch (tools/preview): page words that become setup keys on a LOCAL page: ?kick=1 puts "kick": true (Simulation\'s kick and coin turn on for the match whatever kick.json says; ?kick=off puts false), ?instant= and ?climbTicks= the kick\'s takeoff, ?tier=4 a training start (startTier).',
    'func _preview_planet() -> Dictionary:',
    '\tvar d: Dictionary = _preview_planet_base()',
    ...(opts.kickWord ? kickLines : []),
    ...(opts.tierWord ? tierLines : []),
    '\treturn d',
    '',
    '',
  ].join('\n');
  let out = extra.length ? PLANET_FUNC.replace(line, () => `\t\t${extra.join(', ')},\n${line}`) : PLANET_FUNC;
  if (opts.sticks) {
    const callAt = "\tif frames % 20 != 0 and not args.has(\"reel\"):";
    if (!out.includes(callAt)) throw new Error('tools/preview/switches.mjs: the probe cadence line moved (planetFunc is out of date)');
    const head = 'func _preview_probe() -> void:\n';
    out = out.replace(head, () => sticks + head + '\t_preview_sticks()\n');
  }
  if (opts.struggleOff) {
    const head = "func _preview_planet() -> Dictionary:\n";
    if (!out.includes(head)) throw new Error('tools/preview/switches.mjs: the planet entry moved (planetFunc is out of date)');
    out = out.replace(head, () => struggleOff + head + '\t_preview_struggle_off()\n');
  }
  if (opts.swingsOff) {
    const head = "func _preview_planet() -> Dictionary:\n";
    if (!out.includes(head)) throw new Error('tools/preview/switches.mjs: the planet entry moved (planetFunc is out of date)');
    out = out.replace(head, () => swingsOff + head + '\t_preview_swings_off()\n');
  }
  if (opts.kickWord || opts.tierWord) {
    const head = 'func _preview_planet() -> Dictionary:\n';
    if (!out.includes(head)) throw new Error('tools/preview/switches.mjs: the planet entry moved (planetFunc is out of date)');
    out = out.replace(head, () => kickWord + 'func _preview_planet_base() -> Dictionary:\n');
  }
  const keys = Object.entries(setup);
  if (keys.length) {
    const ret = '\t\treturn {"planet": int(args["planet"]), "touch": int(args.get("touch", 3))}';
    if (!out.includes(ret)) throw new Error('tools/preview/switches.mjs: the planet entry moved (planetFunc is out of date)');
    out = out.replace(ret, () => ret.replace('}', () => `${keys.map(([k, v]) => `, "${k}": ${JSON.stringify(v)}`).join('')}}`));
  }
  return out;
}

const EDITS = [
  { name: 'the match setup\'s planet part (no-intro and hook starts)', from: '\t\treturn _planet_next.duplicate()\n', to: '\t\treturn _preview_planet()\n' },
  { name: 'the match setup\'s planet part (the intro start)', from: '\tsu.merge(_planet_next)\n', to: '\tsu.merge(_preview_planet())\n' },
  { name: 'the menu start without intros', from: '\t\tvar su: Dictionary = _planet_next.duplicate()\n', to: '\t\tvar su: Dictionary = _preview_planet()\n' },
  { name: 'the options the URL may set', from: 'const URL_ARGS: Array = [', to: 'const URL_ARGS: Array = ["planet", "touch", "preview", "reel", "sticks", "kick", "instant", "climbTicks", "go", "tier", ' },
  { name: 'the menu choices before the HUD loads them', from: '\tui_hud.menu_changed.connect(_on_menu_changed)\n', to: '\t_preview_go()\n\tui_hud.menu_changed.connect(_on_menu_changed)\n' },
  { name: 'the per-frame hook', from: '\tvar n: int = host.advance(delta, vp.x, vp.y)\n', to: '\tvar n: int = host.advance(delta, vp.x, vp.y)\n\tif args.has("preview"):\n\t\t_preview_probe()\n' },
];

/** A short fingerprint of the scratch patch and the switch table: a cached build is reused only for the same patch. */
export const EDITS_FINGERPRINT = createHash('sha1').update(JSON.stringify([EDITS, PLANET_FUNC, SWITCHES])).digest('hex').slice(0, 6);

/** main.gd with the planet entry and the probe. Each anchor must be there exactly once, or this throws and says which (Rendering's main.gd changed: update EDITS). Keeps the file's line endings. */
export function patchMain(text, extra = [], setup = {}, opts = {}) {
  const crlf = text.includes('\r\n');
  const nl = (s) => (crlf ? s.replace(/\n/g, '\r\n') : s);
  let out = text;
  for (const e of EDITS) {
    const from = nl(e.from);
    const n = out.split(from).length - 1;
    if (n !== 1) throw new Error(`render/core/main.gd: ${e.name}: expected the line once, found it ${n} times (tools/preview/switches.mjs EDITS is out of date)`);
    out = out.replace(from, () => nl(e.to));
  }
  return out.replace(/\s*$/, '') + nl(planetFunc(extra, setup, opts));
}

/** The kick's takeoff values for Orb to try (Simulation's data/fight/kick.json: the default is 0.8 and 8). Printed as addresses beside the page's own, each one the page's address plus these words. */
export const KICK_SAMPLES = [
  { id: 'kick', add: 'instant=0.9&climbTicks=4', label: 'the kick, quicker: 90% of top speed on the first tick, top speed in 4 more' },
  { id: 'kick', add: 'instant=0.8&climbTicks=12', label: 'the kick, a longer climb: 80% on the first tick, a fifth of a second to top speed' },
  { id: 'kick', add: 'instant=1&climbTicks=0', label: 'the kick, truly instant: top speed on the first tick' },
  { id: 'kick', add: 'kick=off', label: 'the kick OFF, to compare' },
];
