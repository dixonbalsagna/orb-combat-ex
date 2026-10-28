// w1.cjs: biomes W1 (docs/combat/biomes.md section 6, Encounter's first window), on e1521ef5.
// The director reads data/combat/sigvariants.json for the signature's variant: the row picked by the biome under the
// defender (WorldBiomes.biomeAt, or fineNameAt with the file's fineOn), and from it the name, the groove factors
// (scorch), the structure bite (structMul, areaMul), trees and the looks (fx). It retires templates.json
// beam.variants and its schema requirement, crater.gd SCORCH_VARIANT and beam.gd's unused VARIANT, and folds the
// file into DirData.dataHash. With fineOn false (as the file ships) play is bit-identical; only the replay's data
// hash moves. Grants: crater.gd and probe.gd (World), templates.json (Combat), the templates schema (Tools).
//   node w1.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node w1.cjs <checkout root> [--check]');
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

// ---------------------------------------------------------------- Encounter's: sim/director/data.gd
edit('sim/director/data.gd', rep => {
  rep('const FINISHERS_PATH: String = "res://data/combat/finishers.json"\n',
      'const FINISHERS_PATH: String = "res://data/combat/finishers.json"\n' +
      'const SIGVARIANTS_PATH: String = "res://data/combat/sigvariants.json"\n');
  rep('static var _fin = null           # parsed finishers.json\n',
      'static var _fin = null           # parsed finishers.json\n' +
      'static var _sig = null           # parsed sigvariants.json (the signature\'s variant by biome)\n' +
      'static var _sigByName: Dictionary = {}   # a variant\'s name to its row: a beam carries the name (b.variant)\n');
  rep('static var finishersProfile: String = ""\n',
      'static var finishersProfile: String = ""\n' +
      '## Tools and tests only: force sigvariants.json\'s fineOn (1 on, 0 off; -1 keeps the file\'s).\n' +
      'static var sigFine: int = -1\n');
  rep('\t\tpush_error("DirData: could not parse data/combat/templates.json or finishers.json")\n',
      '\t\tpush_error("DirData: could not parse data/combat/templates.json or finishers.json")\n' +
      '\tvar st: String = FileAccess.get_file_as_string(SIGVARIANTS_PATH)\n' +
      '\t_sig = JSON.parse_string(st)\n' +
      '\tif _sig == null:\n' +
      '\t\tpush_error("DirData: could not parse data/combat/sigvariants.json")\n' +
      '\telse:\n' +
      '\t\t_indexSig()\n');
  rep('\t_hash = h.hex()\n',
      '\th.text(st)   # Combat\'s data/combat/sigvariants.json: what the signature carves by biome (biomes W1)\n' +
      '\t_hash = h.hex()\n');
  rep('## Tools only: parse a data file, and swap the parsed data in (returns the previous [templates, finishers]).\n',
      '## The rows by name, as a beam carries it. Rows that share a name must play the same (the city and the village share\n' +
      '## BOULEVARD RAZE until LANE SWEEP is adopted); a second row of the name that plays otherwise is an error, and the\n' +
      '## first is kept.\n' +
      'static func _indexSig() -> void:\n' +
      '\t_sigByName = {}\n' +
      '\tfor k in _sig.variants:\n' +
      '\t\tvar row: Dictionary = _sig.variants[k]\n' +
      '\t\tvar nm: String = String(row.name)\n' +
      '\t\tif not _sigByName.has(nm):\n' +
      '\t\t\t_sigByName[nm] = row\n' +
      '\t\telif _playOf(_sigByName[nm]) != _playOf(row):\n' +
      '\t\t\tpush_error("DirData: sigvariants.json has two rows named %s that play differently" % nm)\n' +
      '\n' +
      '\n' +
      'static func _playOf(row: Dictionary) -> String:\n' +
      '\treturn JSON.stringify([row.get("scorch"), row.get("structMul"), row.get("areaMul", 1.0), row.get("trees"), row.get("fx")])\n' +
      '\n' +
      '\n' +
      '## Tools only: parse a data file, and swap the parsed data in (returns the previous [templates, finishers]).\n');
  rep('\tvar bio: String = WorldBiomes.biomeAt(D.x)\n\tvar variant: String = bm.variants[bio]\n',
      '\tvar bio: String = sigKeyAt(D.x)   # the biome under the defender picks the variant, for the whole beam\n' +
      '\tvar variant: String = String(sigRow(bio).name)\n');
  rep('## True when the active profile decides a beam\'s outcome at the fire beat (beam.outcomeByProfile, decideAt "fire").\n',
      '## The signature\'s variant for the biome at x (data/combat/sigvariants.json; docs/combat/biomes.md section 2): the\n' +
      '## key of its row. WorldBiomes.biomeAt\'s seven names, or fineNameAt\'s with the file\'s fineOn, so that a gen 2 planet\n' +
      '## reads its fine biome\'s row while gen 1 and the hand-made world read the same seven. A name the file has no row\n' +
      '## for reads biomeAt\'s.\n' +
      'static func sigKeyAt(x: float) -> String:\n' +
      '\t_ensure()\n' +
      '\tvar fine: bool = bool(_sig.fineOn) if sigFine < 0 else sigFine == 1\n' +
      '\tvar k: String = WorldBiomes.fineNameAt(x) if fine else WorldBiomes.biomeAt(x)\n' +
      '\treturn k if _sig.variants.has(k) else WorldBiomes.biomeAt(x)\n' +
      '\n' +
      '\n' +
      'static func sigRow(key: String) -> Dictionary:\n' +
      '\t_ensure()\n' +
      '\treturn _sig.variants[key]\n' +
      '\n' +
      '\n' +
      '## A variant\'s row by its name, as a beam carries it: {} for a name the file has none for (a tool\'s own beam), which\n' +
      '## plays the plain groove, grey dust and no sparks or fire.\n' +
      'static func sigByName(name: String) -> Dictionary:\n' +
      '\t_ensure()\n' +
      '\treturn _sigByName.get(name, {})\n' +
      '\n' +
      '\n' +
      '## True when the active profile decides a beam\'s outcome at the fire beat (beam.outcomeByProfile, decideAt "fire").\n');
});

// ---------------------------------------------------------------- Encounter's: sim/director/beam.gd
edit('sim/director/beam.gd', rep => {
  rep('\n\nconst VARIANT: Dictionary = {"ocean": "HORIZON CLEAVE", "city": "BOULEVARD RAZE", "village": "BOULEVARD RAZE", "forest": "FIRESTORM", "mountains": "RIDGE BORE", "desert": "GLASS TRENCH", "plains": "FIELD SCAR"}\n\n\n',
      '\n\n\n');
  rep('\t# structures, and how many buildings it may level (a share of all of them, at least one).\n' +
      '\tb.sf = float(A.ld.beamStructure[_tierIx(A)])\n',
      '\t# structures, and how many buildings it may level (a share of all of them, at least one). The bite is times the\n' +
      '\t# variant\'s structMul (data/combat/sigvariants.json), for the whole beam.\n' +
      '\tb.sf = float(A.ld.beamStructure[_tierIx(A)]) * float(DirData.sigByName(variant).get("structMul", 1.0))\n');
  rep('\tvar g: float = WorldTerrain.groundY(S, x)\n' +
      '\tif y < g + WorldCrater.beamReach(P):\n' +
      '\t\t# Scorch: a groove carved to a target depth along the ground, not a crater per sample (sim quirk 7 is gone).\n' +
      '\t\tWorldCrater.scorch(S, x, P, b.variant, A)\n',
      '\tvar g: float = WorldTerrain.groundY(S, x)\n' +
      '\t# The variant\'s row (data/combat/sigvariants.json): its groove factors, structure radius and looks. Its trees are\n' +
      '\t# read as area (today\'s damageArea) whatever the row says, until World builds burn, fell, snap and none.\n' +
      '\tvar vr: Dictionary = DirData.sigByName(b.variant)\n' +
      '\tvar fx: Dictionary = vr.get("fx", {})\n' +
      '\tif y < g + WorldCrater.beamReach(P):\n' +
      '\t\t# Scorch: a groove carved to a target depth along the ground, not a crater per sample (sim quirk 7 is gone).\n' +
      '\t\tWorldCrater.scorch(S, x, P, b.variant, A, NAN, vr.get("scorch", [1.0, 1.0]))\n');
  rep('\t\tSimFx.dust(S, x, g + 8.0, 1, "#e6c47a" if b.variant == "GLASS TRENCH" else "#9b8f7e")\n' +
      '\t\tif b.variant == "GLASS TRENCH":\n' +
      '\t\t\tSimFx.spark(S, x, g + 6.0, 2, "#ffd98a", 300.0)\n' +
      '\tb.levelled += WorldStructures.damageArea(S, x, y, (26.0 + P * 8.0) * SimConst.WS, ',
      '\t\tSimFx.dust(S, x, g + 8.0, 1, String(fx.get("dust", "#9b8f7e")))\n' +
      '\t\tif fx.has("sparks"):\n' +
      '\t\t\tSimFx.spark(S, x, g + 6.0, int(fx.sparks.n), String(fx.sparks.col), float(fx.sparks.speed))\n' +
      '\tb.levelled += WorldStructures.damageArea(S, x, y, (26.0 + P * 8.0) * SimConst.WS * float(vr.get("areaMul", 1.0)), ');
  rep('\tif b.variant == "FIRESTORM" and y < g + 140.0 * SimConst.WS:\n',
      '\tif fx.has("fire") and y < g + float(fx.fire.withinAbove) * SimConst.WS:\n');
});

// ---------------------------------------------------------------- World's (grant): sim/world/crater.gd
edit('sim/world/crater.gd', rep => {
  rep('## Per beam variant: [depth factor, width factor]. Ridge bore drills, glass trench fuses a wide shallow strip.\n' +
      'const SCORCH_VARIANT: Dictionary = {"RIDGE BORE": [1.6, 0.8], "GLASS TRENCH": [0.8, 1.3], "FIRESTORM": [1.0, 1.1], "BOULEVARD RAZE": [0.8, 1.0], "FIELD SCAR": [1.0, 1.0], "HORIZON CLEAVE": [1.0, 1.0]}\n',
      '');
  rep('## many samples cross it), raise the permanent burn mark, and emit the scorch event. Half width and depth grow with P.\n' +
      'static func scorch(S: SimState, x: float, P: float, variant: String, cause, z: float = NAN) -> void:\n' +
      '\tif not S.depthOn:\n' +
      '\t\t_scorch(S, x, P, variant, cause)\n',
      '## many samples cross it), raise the permanent burn mark, and emit the scorch event. Half width and depth grow with P.\n' +
      '## vk is the variant\'s [depth factor, width factor]: its row\'s scorch in data/combat/sigvariants.json, which the\n' +
      '## director passes; [1, 1] is the plain groove. variant is the name the scorch event carries.\n' +
      'static func scorch(S: SimState, x: float, P: float, variant: String, cause, z: float = NAN, vk: Array = [1.0, 1.0]) -> void:\n' +
      '\tif not S.depthOn:\n' +
      '\t\t_scorch(S, x, P, variant, cause, vk)\n');
  rep('\tvar k: int = WorldTerrain.enterRow(S, WorldTerrain.rowOfZ(zz))\n' +
      '\t_scorch(S, x, P, variant, cause)\n',
      '\tvar k: int = WorldTerrain.enterRow(S, WorldTerrain.rowOfZ(zz))\n' +
      '\t_scorch(S, x, P, variant, cause, vk)\n');
  rep('static func _scorch(S: SimState, x: float, P: float, variant: String, cause) -> void:\n' +
      '\tvar NC: int = SimConst.NC\n' +
      '\tvar COL: float = SimConst.COL\n' +
      '\tvar vk: Array = SCORCH_VARIANT.get(variant, [1.0, 1.0])\n',
      'static func _scorch(S: SimState, x: float, P: float, variant: String, cause, vk: Array) -> void:\n' +
      '\tvar NC: int = SimConst.NC\n' +
      '\tvar COL: float = SimConst.COL\n');
});

// ---------------------------------------------------------------- World's (grant): sim/world/tools/probe.gd
edit('sim/world/tools/probe.gd', rep => {
  rep('WorldCrater.scorch(S9, x + 30.0 * float(k), rg.range_(0.5, 4.5), "GLASS TRENCH", null)',
      'WorldCrater.scorch(S9, x + 30.0 * float(k), rg.range_(0.5, 4.5), "GLASS TRENCH", null, NAN, [0.8, 1.3])');
});

// ---------------------------------------------------------------- Combat's (grant): data/combat/templates.json
edit('data/combat/templates.json', rep => {
  rep('    "variants": {\n' +
      '      "ocean": "HORIZON CLEAVE",\n' +
      '      "city": "BOULEVARD RAZE",\n' +
      '      "village": "BOULEVARD RAZE",\n' +
      '      "forest": "FIRESTORM",\n' +
      '      "mountains": "RIDGE BORE",\n' +
      '      "desert": "GLASS TRENCH",\n' +
      '      "plains": "FIELD SCAR"\n' +
      '    },\n',
      '    "_variants": "the variant by biome is data/combat/sigvariants.json (biomes W1)",\n');
});

// ---------------------------------------------------------------- Tools' (grant): tools/schemas/combat-templates.schema.json
edit('tools/schemas/combat-templates.schema.json', rep => {
  rep('        "spacedTiming",\n        "variants",\n        "tagFormat",\n',
      '        "spacedTiming",\n        "tagFormat",\n');
  rep('        "variants": {\n' +
      '          "type": "object",\n' +
      '          "required": [\n' +
      '            "ocean",\n' +
      '            "city",\n' +
      '            "village",\n' +
      '            "forest",\n' +
      '            "mountains",\n' +
      '            "desert",\n' +
      '            "plains"\n' +
      '          ],\n' +
      '          "additionalProperties": {\n' +
      '            "type": "string",\n' +
      '            "minLength": 1\n' +
      '          },\n' +
      '          "patternProperties": {\n' +
      '            "^_": true\n' +
      '          }\n' +
      '        },\n',
      '');
});

// ---------------------------------------------------------------- Encounter's: the probe (a new file)
{
  const rel = 'sim/director/tools/sigvariants_check.gd';
  const src = path.join(__dirname, 'files', rel);
  const dst = path.join(root, rel);
  const t = fs.readFileSync(src, 'utf8');
  if (fs.existsSync(dst) && fs.readFileSync(dst, 'utf8') !== t) throw new Error(rel + ' already exists and differs');
  if (!check) fs.writeFileSync(dst, t);
  console.log(rel + (check ? ': new file, ok' : ': written'));
}
