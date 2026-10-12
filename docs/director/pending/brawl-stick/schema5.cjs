// schema5.cjs <checkout root>: the three schema keys of the stick slice, as optional properties (for Tools, or for
// Encounter by the EP's grant as with schema4.cjs). Text edits, each expected exactly once.
//   tools/schemas/director-interrupts.schema.json  brawl.nudge.floor   number, 0 to 1
//   tools/schemas/director-ai.schema.json          digInMax            integer, -1 or more (-1: no bound)
//                                                  digInRestS          number, 0 or more
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
  fn(rep);
  JSON.parse(t);
  fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + ': ok');
}
edit('tools/schemas/director-interrupts.schema.json', rep => {
  rep('              "description": "The nudge\'s share while the rival is staggered."\n            }\n          },\n',
      '              "description": "The nudge\'s share while the rival is staggered."\n            },\n' +
      '            "floor": {\n              "type": "number",\n              "minimum": 0,\n              "maximum": 1,\n              "description": "A player\'s held stick moves the pair his way by this share of his own nudge at least."\n            }\n          },\n');
});
edit('tools/schemas/director-ai.schema.json', rep => {
  rep('    "digInBoth": {\n      "type": "boolean",\n      "description": "Whether two AIs may both dig in to one trade."\n    }\n  },\n',
      '    "digInBoth": {\n      "type": "boolean",\n      "description": "Whether two AIs may both dig in to one trade."\n    },\n' +
      '    "digInMax": {\n      "type": "integer",\n      "minimum": -1,\n      "description": "The AI digs in only while the match has had fewer double hits than this (-1: no bound)."\n    },\n' +
      '    "digInRestS": {\n      "type": "number",\n      "minimum": 0,\n      "description": "Seconds of fight time after a double hit in which the AI does not dig in."\n    }\n  },\n');
});
