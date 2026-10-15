// s6.cjs <checkout root>: Game Design's sixth round (brawl-second-pass.md section 14, "The sixth round"), its one code
// change and its data steps. On main 3198301f (the nine cells' chain in).
//   node s6.cjs <root>                 the code: a landed heavy counts flurry.runBy.heavy on the run, both ways, as a
//                                      medium counts runBy.medium; a strength not named counts 1, so with no `heavy`
//                                      key nothing changes
//   node s6.cjs <root> data <step>...  the data steps, each a one-line text edit:
//        pursue      brawl.firstMove.pursue true (a.: the launcher's far press flies him in while the first move is his)
//        lworth      brawl.launcher.worth 3 to 6 (a.: the launching blow is worth a full heavy)
//        runbyheavy  brawl.flurry.runBy.heavy 4 (b.)
//        split       brawl.flurry.runOffBy.heavy 1 (the eighth round: a heavy adds 4 to his run, takes 1 off the rival's)
//        runhalves   brawl.burst.runHalves 1 to 2 (c.: every blow of a held X a full point)
//        digin       ai.json medium brawl.digIn 0.55 to 0.45 (d.)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 80));
    t = t.replace(a, () => b);
  };
  fn(rep, () => t, v => { t = v; });
  if (rel.endsWith('.json')) JSON.parse(t);
  fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + ': ok');
}
if (process.argv[3] !== 'data') {
  edit('sim/director/brawl.gd', rep => {
    rep("\t# replyTakes. A landed medium counts flurry.runBy.medium both ways, so a flurry of mediums out-runs slow lights.\n",
        "\t# replyTakes. A landed medium counts flurry.runBy.medium both ways, so a flurry of mediums out-runs slow lights, and a\n\t# landed heavy counts flurry.runBy.heavy (the sixth round). A strength the data doesn't name counts 1.\n");
    rep('\tvar pts: int = int(round(float(c.flurry.runBy.medium) * float(RUN_U))) if (kind == MEDIUM and energy == "") else RUN_U\n',
        '\tvar pts: int = int(round(float(c.flurry.runBy.get(KINDS[kind], 1.0)) * float(RUN_U))) if ((kind == MEDIUM or kind == BIG) and energy == "") else RUN_U\n' +
        '\t# What it takes off the rival\'s run: the same, unless flurry.runOffBy names the strength (the eighth round: a landed\n' +
        '\t# heavy adds 4 to his run and takes 1 off the rival\'s).\n' +
        '\tvar off: int = pts\n' +
        '\tif energy == "" and c.flurry.has("runOffBy") and c.flurry.runOffBy.has(KINDS[kind]):\n' +
        '\t\toff = int(round(float(c.flurry.runOffBy[KINDS[kind]]) * float(RUN_U)))\n');
    rep('\t_s(o, RUN, maxi(0, _g(o, RUN) - pts * int(c.flurry.replyTakes)))\n',
        '\t_s(o, RUN, maxi(0, _g(o, RUN) - off * int(c.flurry.replyTakes)))\n');
  });
  // the schema: runBy may name the heavy (a text-stable edit: the schema round-trips with two spaces)
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const rb = s.properties.brawl.properties.flurry.properties.runBy;
  if (!rb.properties.heavy) {
    rb.properties.heavy = { type: 'number', minimum: 0, description: "What a landed heavy adds to his run and takes off the rival's, in points (the sixth round). Not named, it counts 1." };
    fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  }
  const fl = s.properties.brawl.properties.flurry.properties;
  if (!fl.runOffBy) {
    fl.runOffBy = { type: 'object', properties: { medium: { type: 'number', minimum: 0, description: "What a landed medium takes off the rival's run, in points." }, heavy: { type: 'number', minimum: 0, description: "What a landed heavy takes off the rival's run, in points (the eighth round: 1)." } }, additionalProperties: false, description: "What a landed blow takes off the rival's run, by strength, where it differs from what it adds to his (runBy). Not named: the same as runBy." };
    fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  }
  console.log('tools/schemas/director-interrupts.schema.json: runBy.heavy, runOffBy');
} else {
  for (const step of process.argv.slice(4)) {
    if (step === 'pursue') edit('data/director/interrupts.json', rep => rep('      "pursue": false\n', '      "pursue": true\n'));
    else if (step === 'lworth') edit('data/director/interrupts.json', rep => rep('      "windupTicks": 14,\n      "worth": 3,\n', '      "windupTicks": 14,\n      "worth": 6,\n'));
    else if (step === 'runbyheavy') edit('data/director/interrupts.json', rep => rep('      "runBy": {"medium": 3},\n', '      "runBy": {"medium": 3, "heavy": 4},\n'));
    else if (step === 'split') edit('data/director/interrupts.json', rep => rep('      "runBy": {"medium": 3, "heavy": 4},\n', '      "runBy": {"medium": 3, "heavy": 4},\n      "runOffBy": {"heavy": 1},\n'));
    else if (step === 'runhalves') edit('data/director/interrupts.json', rep => rep('      "runHalves": 1,\n', '      "runHalves": 2,\n'));
    else if (step === 'digin') edit('data/director/ai.json', (rep, get, set) => {
      const lines = get().split('\n');
      const idx = lines.map((l, n) => (l.includes('"brawl": {"tapGap"') ? n : -1)).filter(n => n >= 0);
      if (idx.length !== 3) throw new Error('expected three brawl lines');
      const li = idx[1];
      if (!lines[li].includes('"digIn": 0.55')) throw new Error('medium digIn is not 0.55');
      lines[li] = lines[li].replace('"digIn": 0.55', '"digIn": 0.45');
      set(lines.join('\n'));
    });
    else throw new Error('unknown step ' + step);
    console.log('step ' + step);
  }
}
