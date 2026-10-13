// schema7.cjs <checkout root>: the schema keys of the nine cells, pass 1, as optional properties (for Tools, or for
// Encounter by the EP's grant as before). Text edits.
//   tools/schemas/director-interrupts.schema.json  brawl.burst.floorGap     integer, 0 or more (0: no floor pace)
//                                                  brawl.burst.holdCarries  boolean
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b, times) => {
    const n = t.split(a).length - 1;
    if (n !== times) throw new Error(rel + ': expected ' + times + ' matches, got ' + n + ' for: ' + a.slice(0, 80));
    t = t.split(a).join(b);
  };
  fn(rep);
  JSON.parse(t);
  fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + ': ok');
}
const op = '            "openTicks": {\n              "type": "integer",\n              "minimum": 0,\n              "description": "Ticks the burst stays open."\n            }\n';
edit('tools/schemas/director-interrupts.schema.json', rep => {
  rep(op,
    '            "openTicks": {\n              "type": "integer",\n              "minimum": 0,\n              "description": "Ticks the burst stays open."\n            },\n' +
    '            "floorGap": {\n              "type": "integer",\n              "minimum": 0,\n              "description": "After the burst a held X throws one blow every this many ticks (0: it stops after the burst)."\n            },\n' +
    '            "holdCarries": {\n              "type": "boolean",\n              "description": "Whether a held X outlives the brawl it was pressed in."\n            }\n', 1);
});
