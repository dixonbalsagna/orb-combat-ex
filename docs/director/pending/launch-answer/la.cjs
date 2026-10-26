// la.cjs: the AI's answer to a launcher it guessed, timed to the blow (the EP's (a), 2026-10-26, after the newcomer's
// trace), with Game Design's rulings-2026-10-26 items 19 to 21. Behind data/director/interrupts.json
// brawl.launcher.anywhere.answer.enabled (false), so the golden doesn't move.
//   The AI answers a launcher that isn't sure only by a guess, made when the rival's blow lands clean on it, at its
//   level's brawl.anywhere.answer (section 8: it never reacts to one it sees). The guess's guard press came its reaction
//   time (reactTicks, 14) after the throw. The launcher winds 14 ticks, so that press came at the contact or after it,
//   and never once landed inside the perfect window: the share did nothing (0.25 and 0.6 read the same to the digit).
//   With answer.enabled the guessed press is timed to the contact instead: answer.leadTicks (3) live ticks before it,
//   inside the perfect window (the blow's 8 and the early 4). The guess and its share are as they were, and:
//   19  on the levels in answer.firstFree (easy, medium) it never guesses at a player's first launcher of a match
//       (LA_LAU1, set at his first throw); ordinary reaction still guards it, as any blow
//   20  easy's answer share 0.1 to 0.2 (it acts from his second launcher, by 19)
//   21  against a mash (his last two light presses within answer.mashTicks, 9, and the last of them as recent), its
//       perfect-block chance in a brawl is at least its level's brawl.perfectVsMash; a perfect-blocked light stays the
//       plain reversal (10-26 item 8)
//   node la.cjs <checkout root> [--check]     (on a main with launch-spike, ../launch-spike/ps.cjs)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node la.cjs <checkout root> [--check]');
const check = opts.includes('--check');
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 90));
    t = t.replace(a, () => b);
  };
  fn(rep);
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
if (!fs.readFileSync(path.join(root, 'sim/director/brawl.gd'), 'utf8').includes('static func _spike(S: SimState, ex, f, o) -> void:')) throw new Error('../launch-spike/ps.cjs first');
edit('sim/director/brawl.gd', rep => {
  rep('const LA_POP_STUN: int = 40    # S.tick his juggle\'s stun ends (the pop and its landing, or the spike and its recovery): no opening before it\nconst LA_N: int = 41\n',
      'const LA_POP_STUN: int = 40    # S.tick his juggle\'s stun ends (the pop and its landing, or the spike and its recovery): no opening before it\n' +
      'const LA_LAU1: int = 41        # 1 once he has thrown a launcher this match (10-26 item 19: the AI never guesses at his first)\n' +
      'const LA_N: int = 42\n');
  rep('\t_s(f, LC_LATE, 1 if (lau and o.stunTicks <= 0) else 0)   # thrown after the stagger: he can answer it\n',
      '\t_s(f, LC_LATE, 1 if (lau and o.stunTicks <= 0) else 0)   # thrown after the stagger: he can answer it\n' +
      '\tif lau and any:\n\t\t_ls(f, LA_LAU1, 1)   # his first launcher of the match is thrown (10-26 item 19)\n');
  rep('\tif o.ai == null:\n\t\treturn   # a player answers for himself\n\tvar share: float = float(DirAI.lv().get("brawl", {}).get("anywhere", {}).get("answer", 0.0))\n',
      '\tif o.ai == null:\n\t\treturn   # a player answers for himself\n' +
      '\tvar an: Dictionary = la().get("answer", {})\n' +
      '\tif bool(an.get("enabled", false)) and f.ai == null and _lg(f, LA_LAU1) == 0 and (an.get("firstFree", []) as Array).has(DirAI.level if DirAI.level != "" else String(DirAI.skill().level)):\n' +
      '\t\treturn   # 10-26 item 19: on easy and medium it never guesses at a player\'s first launcher of a match\n' +
      '\tvar share: float = float(DirAI.lv().get("brawl", {}).get("anywhere", {}).get("answer", 0.0))\n');
  rep('## The AI\'s guess, once a tick: a launcher that isn\'t sure winds on it, thrown while the guess held, and its reaction time\n' +
      '## has passed since it was thrown: it presses guard (never sooner, so it never answers within its reaction time; the\n' +
      '## contact is still inside the perfect window). The guess is spent with the press, or lapses.\n',
      '## The AI\'s guess, once a tick: a launcher that isn\'t sure winds on it, thrown while the guess held, and its reaction time\n' +
      '## has passed since it was thrown: it presses guard (never sooner, so it never answers within its reaction time; the\n' +
      '## contact is still inside the perfect window). The guess is spent with the press, or lapses. With anywhere.answer on,\n' +
      '## the press is timed to the contact (answer.leadTicks before it): the guess was made before the throw, and a press its\n' +
      '## reaction time after the throw came at the contact or later, since the wind-up is as long.\n');
  rep('\t\tif f.stunTicks <= 0 and S.tick - began >= int(DirAI.skill().get("reactTicks", 14)):\n',
      '\t\tvar due: bool = S.tick - began >= int(DirAI.skill().get("reactTicks", 14))\n' +
      '\t\tvar an: Dictionary = la().get("answer", {})\n' +
      '\t\tif bool(an.get("enabled", false)):\n' +
      '\t\t\tdue = _g(o, CONTACT) - _now(S) <= int(an.get("leadTicks", 3))   # inside the perfect window, in live ticks\n' +
      '\t\tif f.stunTicks <= 0 and due:\n');
  rep('## The AI launches in its string at a hard-to-answer moment (section 8)',
      '## True while f mashes (10-26 item 21): his last two light presses came within anywhere.answer.mashTicks of each other,\n' +
      '## and the last of them as recently. A mash is rhythmic and readable: the AI\'s perfect block against it is DirInterrupt\'s.\n' +
      'static func mashing(S: SimState, f) -> bool:\n' +
      '\tvar m: int = int(la().get("answer", {}).get("mashTicks", 9))\n' +
      '\treturn _g(f, TAP_GAP) > 0 and _g(f, TAP_GAP) <= m and S.tick - _g(f, LAST_TAP) <= m\n\n\n' +
      '## The AI launches in its string at a hard-to-answer moment (section 8)');
});
edit('sim/director/interrupt.gd', rep => {
  rep('\t\tif DirBrawl.isBrawl(ex) and int(b.args.get("bk", -1)) == DirBrawl.BIG and lv.get("brawl", {}).has("perfectVsHeavy"):\n\t\t\tchance = float(lv.brawl.perfectVsHeavy)\n',
      '\t\tif DirBrawl.isBrawl(ex) and int(b.args.get("bk", -1)) == DirBrawl.BIG and lv.get("brawl", {}).has("perfectVsHeavy"):\n\t\t\tchance = float(lv.brawl.perfectVsHeavy)\n' +
      '\t\tif DirBrawl.isBrawl(ex) and lv.get("brawl", {}).has("perfectVsMash") and bool(DirBrawl.la().get("answer", {}).get("enabled", false)) and DirBrawl.mashing(S, ex.A if f == ex.D else ex.D):\n' +
      '\t\t\tchance = maxf(chance, float(lv.brawl.perfectVsMash))   # 10-26 item 21: a mash is readable, so its level answers it\n');
});
edit('data/director/interrupts.json', rep => {
  rep('"popAtBh": 8, "popR": 3}\n      }\n    },\n    "energy": {\n',
      '"popAtBh": 8, "popR": 3},\n' +
      '        "answer": {"enabled": false, "leadTicks": 3, "firstFree": ["easy", "medium"], "mashTicks": 9, "_note": "The AI\'s answer to a launcher it guessed (brawl.anywhere.answer in ai.json, drawn when the rival\'s blow lands clean on it): its guard press is timed leadTicks live ticks before the blow\'s contact, inside the perfect window. false: the press comes reactTicks after the throw, which is the wind-up\'s own length, so it never lands in the window. firstFree: the levels that never guess at a player\'s first launcher of a match (Game Design 10-26 item 19). mashTicks: his last two light presses within this many ticks are a mash, which the AI perfect-blocks at least at its level\'s brawl.perfectVsMash (item 21)"}\n' +
      '      }\n    },\n    "energy": {\n');
});
edit('data/director/ai.json', rep => {
  rep('"anywhere": {"launcher": 0.15, "inString": 0.05, "answer": 0.1}', '"anywhere": {"launcher": 0.15, "inString": 0.05, "answer": 0.2}');   // 10-26 item 20
  rep('"perfectVsHeavy": 0.05', '"perfectVsHeavy": 0.05, "perfectVsMash": 0.01');   // 10-26 item 21
  rep('"perfectVsHeavy": 0.15', '"perfectVsHeavy": 0.15, "perfectVsMash": 0.02');
  rep('"perfectVsHeavy": 0.3', '"perfectVsHeavy": 0.3, "perfectVsMash": 0.04');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const any = s.properties.brawl.properties.launcher.properties.anywhere;
  if (!any || !any.properties) throw new Error('director-interrupts schema: no brawl.launcher.anywhere');
  if (any.properties.answer) throw new Error('director-interrupts schema: anywhere.answer exists already');
  any.properties.answer = { type: 'object', additionalProperties: false, required: ['enabled', 'leadTicks', 'firstFree', 'mashTicks'],
    description: 'The AI\'s guessed answer to a launcher, timed to the contact; the levels that never guess at a player\'s first launcher; the mash it perfect-blocks (Encounter, Game Design 2026-10-26 items 19 to 21).',
    properties: { _note: { type: 'string' }, enabled: { type: 'boolean' }, leadTicks: { type: 'integer', minimum: 0 },
      firstFree: { type: 'array', items: { type: 'string', enum: ['easy', 'medium', 'hard'] } }, mashTicks: { type: 'integer', minimum: 1 } } };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: anywhere.answer' + (check ? ' (checked)' : ''));
}
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  let n = 0;
  const walk = (o) => {
    if (!o || typeof o !== 'object') return;
    if (o.properties && o.properties.perfectVsHeavy && !o.properties.perfectVsMash) {
      o.properties.perfectVsMash = { type: 'number', minimum: 0, maximum: 1, description: 'Game Design 10-26 item 21: its perfect-block chance in a brawl against a mash (interrupts.json brawl.launcher.anywhere.answer.mashTicks), at least; read only with answer.enabled.' };
      n += 1;
    }
    for (const v of Object.values(o)) walk(v);
  };
  walk(s);
  if (n !== 3) throw new Error('director-ai schema: expected 3 levels with perfectVsHeavy, found ' + n);
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: perfectVsMash x' + n + (check ? ' (checked)' : ''));
}
