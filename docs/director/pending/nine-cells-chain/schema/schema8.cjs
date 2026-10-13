// schema8.cjs <checkout root>: the schema keys of Game Design's fourth round, as optional properties (for Tools, or
// for Encounter by the EP's grant as before). Text edits.
//   tools/schemas/director-ai.schema.json          digInAfterS            number, 0 or more
//   tools/schemas/director-interrupts.schema.json  brawl.firstMove        object: lockTicks, an integer 0 or more
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
edit('tools/schemas/director-ai.schema.json', rep => {
  rep('    "digInRestS": {\n',
      '    "digInAfterS": {\n      "type": "number",\n      "minimum": 0,\n      "description": "An AI that digs in during a match does not in its first seconds: this many."\n    },\n    "digInRestS": {\n', 1);
});
edit('tools/schemas/director-interrupts.schema.json', rep => {
  rep('        "launcher": {\n          "type": "object",\n          "required": [\n            "minStagger",\n',
      '        "firstMove": {\n          "type": "object",\n          "properties": {\n            "lockTicks": {\n              "type": "integer",\n              "minimum": 0,\n              "description": "A fighter sent by a launch, a wall slam or a knock-back cannot start an approach until this many ticks after he is free (0: no lock)."\n            }\n          },\n          "additionalProperties": false,\n          "patternProperties": {\n            "^_": true\n          }\n        },\n' +
      '        "launcher": {\n          "type": "object",\n          "required": [\n            "minStagger",\n', 1);
});
