// fh.cjs: the AI's holds of a ready step (Game Design, docs/design/hero-forms.md section 4b, edd7dcd8), behind
// Simulation's forms switch (data/fight/forms.json enabled, off): with forms off, play is the same to the bit.
//   node fh.cjs <checkout root> [--check]
// The AI takes a ready step at its first break unless it holds on purpose: at medium for up to 10 s while its rival's
// tier is above its own, at hard for up to 30 s while its coil is under 60, so players see the slingshot thrown at them.
// Then it releases at the next break. Numbers: the level's "forms" block in data/director/ai.json.
//   sim/director/ai.gd: the press of Transform waits on DirAI._formHold.
//   data/director/ai.json: forms by level; tools/schemas/director-ai.schema.json (Tools'): the same keys.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node fh.cjs <checkout root> [--check]');
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
  fn(rep, t);
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
if (!fs.existsSync(path.join(root, 'sim/core/forms.gd'))) throw new Error("Simulation's forms first (sim/core/forms.gd)");

edit('sim/director/ai.gd', rep => {
  rep('\t# director reads the AI\'s stance through the same path as a player\'s (SimAct.stance). A ready form is taken at once.\n',
      '\t# director reads the AI\'s stance through the same path as a player\'s (SimAct.stance). A ready form is taken at once,\n' +
      '\t# unless it holds one on purpose (forms: _formHold).\n');
  rep('\tif f.act.formReady:\n\t\ti.transform = true\n',
      '\tif f.act.formReady and not _formHold(S, f, o):\n\t\ti.transform = true\n');
  rep('static func aiInput(S: SimState, f) -> void:\n',
`## The AI's holds of a ready step (hero-forms.md section 4b): with forms on and steps of its own, it takes a ready step
## at its first break unless it holds on purpose, for its level's forms.holdS seconds at most of the step held: while
## its rival's tier is above its own (forms.whenAbove), or while its coil is under forms.coilUnder. Then it releases at
## the next break. Off with forms off, and for a fighter without steps.
static func _formHold(S: SimState, f, o) -> bool:
	if not S.formsOn or f.form == null or not SimForms.has(S, f):
		return false
	var fh: Dictionary = lv().get("forms", {})
	var most: float = float(fh.get("holdS", 0.0)) * DirData.TICKS_PER_SEC
	if most <= 0.0 or float(f.form.holdT) >= most:
		return false
	if bool(fh.get("whenAbove", false)) and o.tier > f.tier:
		return true
	return fh.has("coilUnder") and f.form.coil < float(fh.coilUnder)


static func aiInput(S: SimState, f) -> void:
`);
});

edit('data/director/ai.json', rep => {
  rep('"brawl": {"tapGap": 12, "tapGapMax": 12,', '"forms": {"holdS": 0}, "brawl": {"tapGap": 12, "tapGapMax": 12,');
  rep('"brawl": {"tapGap": 8, "tapGapMax": 11,', '"forms": {"holdS": 10, "whenAbove": true}, "brawl": {"tapGap": 8, "tapGapMax": 11,');
  rep('"brawl": {"tapGap": 6, "tapGapMax": 6,', '"forms": {"holdS": 30, "coilUnder": 60}, "brawl": {"tapGap": 6, "tapGapMax": 6,');
});

{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  for (const k of ['easy', 'medium', 'hard']) {
    const lvl = s.properties.levels.properties[k];
    if (!lvl || !lvl.properties) throw new Error('director-ai schema: no level ' + k);
    if (lvl.properties.forms) throw new Error('director-ai schema: forms exists already for ' + k);
    lvl.properties.forms = { type: 'object', description: "The AI's holds of a ready step (hero-forms.md section 4b), with forms on.", properties: {
      holdS: { type: 'number', minimum: 0, description: 'It holds a ready step this many seconds at most (0: never).' },
      whenAbove: { type: 'boolean', description: "... while its rival's tier is above its own." },
      coilUnder: { type: 'number', minimum: 0, description: '... while its coil is under this.' } },
      required: ['holdS'], additionalProperties: false };
  }
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: forms by level' + (check ? ' (checked)' : ''));
}
