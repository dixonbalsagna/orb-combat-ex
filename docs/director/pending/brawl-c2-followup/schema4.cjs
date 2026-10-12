// schema4.cjs <checkout root>: the four schema keys of the follow-up tune (the EP's grant, in Tools' absence), as
// optional properties. They are not added to `required`: Tools' cases.json embeds its own copies of the blast block
// (603 of them), and a required key fails 154 of its cases. Text edits, each expected exactly once.
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
  rep('                      "description": "How far it knocks, in body heights."\n                    },\n',
      '                      "description": "How far it knocks, in body heights."\n                    },\n' +
      '                    "enderRun": {\n                      "type": "integer",\n                      "minimum": 0,\n                      "description": "It knocks back only when his run is this or more as it lands."\n                    },\n' +
      '                    "halfSetup": {\n                      "type": "boolean",\n                      "description": "Whether its knock-back counts as half a set-up."\n                    },\n' +
      '                    "reelTicks": {\n                      "type": "integer",\n                      "minimum": 0,\n                      "description": "The reel of one thrown cold."\n                    },\n');
});
edit('tools/schemas/director-ai.schema.json', rep => {
  rep('      "patternProperties": {\n        "^_": true\n      }\n    }\n  },\n  "additionalProperties": false,\n',
      '      "patternProperties": {\n        "^_": true\n      }\n    },\n    "digInBoth": {\n      "type": "boolean",\n      "description": "Whether two AIs may both dig in to one trade."\n    }\n  },\n  "additionalProperties": false,\n');
});
