// schema9.cjs <checkout root>: the schema key of the planner's town rules, as an optional property (for Tools, or for
// Encounter by the EP's grant as before). A text edit.
//   tools/schemas/director-launch.schema.json  town: {biomes, haulTarget, haulMin, distMul, newBiomeEveryS, bruntFromTier, bruntPrefer, stickWins}
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const p = path.join(root, 'tools/schemas/director-launch.schema.json');
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
const a = '    "knockBack": {\n      "type": "object",\n      "required": [\n        "score",\n';
if (t.split(a).length !== 2) throw new Error('anchor');
const num = (d, min) => '{\n          "type": "number",\n          "minimum": ' + min + ',\n          "description": "' + d + '"\n        }';
const town = '    "town": {\n      "type": "object",\n      "properties": {\n' +
  '        "biomes": {\n          "type": "array",\n          "items": {\n            "type": "string"\n          },\n          "description": "The settlement biomes."\n        },\n' +
  '        "haulTarget": ' + num('From a settlement SMASH ACROSS carries him this many units along the street and no further (0: off).', 0) + ',\n' +
  '        "haulMin": ' + num('... kept while he lands inside the settlement and at least this far on.', 0) + ',\n' +
  '        "distMul": ' + num('From a settlement the distance bonus is this share of itself.', 0) + ',\n' +
  '        "newBiomeEveryS": ' + num('The new-biome bonus is paid once in this many seconds of the match (0: every time).', 0) + ',\n' +
  '        "bruntFromTier": {\n          "type": "integer",\n          "minimum": 1,\n          "description": "With no stick held, a building on the line is preferred from this tier."\n        },\n' +
  '        "bruntPrefer": ' + num('... by this much on its score.', 0) + ',\n' +
  '        "stickWins": ' + num('With the stick toward a building that has a plan, it scores this much more.', 0) + '\n' +
  '      },\n      "additionalProperties": false,\n      "patternProperties": {\n        "^_": true\n      }\n    },\n';
t = t.replace(a, () => town + a);
JSON.parse(t);
fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log('tools/schemas/director-launch.schema.json: ok');
