// schema10.cjs <checkout root>: the schema key of the nine cells' pass 2, as an optional property (for Tools, or for
// Encounter by the EP's grant as before). A text edit.
//   tools/schemas/director-interrupts.schema.json  brawl.medium.charge: {fromTicks, fullTicks, landTicks, maxTicks, worth [2], ki, reelTicks, staggerTicks}
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const p = path.join(root, 'tools/schemas/director-interrupts.schema.json');
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
const a = '            "guardChipMul": {\n              "type": "number",\n              "minimum": 0,\n              "description": "The share of its damage a guard takes."\n            },\n';
if (t.split(a).length !== 2) throw new Error('anchor');
const int = d => '{\n                  "type": "integer",\n                  "minimum": 0,\n                  "description": "' + d + '"\n                }';
const charge = '            "charge": {\n              "type": "object",\n              "properties": {\n' +
  '                "fromTicks": ' + int('A held medium is charged from this tick of its hold.') + ',\n' +
  '                "fullTicks": ' + int('... and full at this one.') + ',\n' +
  '                "landTicks": ' + int('It lands this many ticks after he lets go.') + ',\n' +
  '                "maxTicks": ' + int('Held this long, it goes by itself.') + ',\n' +
  '                "worth": {\n                  "type": "array",\n                  "minItems": 2,\n                  "maxItems": 2,\n                  "items": {\n                    "type": "number",\n                    "minimum": 0\n                  },\n                  "description": "Its worth in brawl lights, as its charge begins and at full."\n                },\n' +
  '                "ki": {\n                  "type": "number",\n                  "minimum": 0,\n                  "description": "Its price in all, the tap\'s included."\n                },\n' +
  '                "reelTicks": ' + int('Clean, the rival reels this long.') + ',\n' +
  '                "staggerTicks": ' + int('At full it closes: he staggers this long, as from a flurry\'s close.') + '\n' +
  '              },\n              "additionalProperties": false,\n              "patternProperties": {\n                "^_": true\n              },\n              "description": "A held Y: the charged medium."\n            },\n';
t = t.replace(a, () => charge + a);
JSON.parse(t);
fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log('tools/schemas/director-interrupts.schema.json: ok');
