// schema6.cjs <checkout root>: the three schema keys of the second-round tune, as optional properties (for Tools, or
// for Encounter by the EP's grant as before). Text edits; the level keys are expected three times, once a level.
//   tools/schemas/director-ai.schema.json          levels.<level>.brawl.mediumVsHeavies   number, 0 to 1
//                                                  levels.<level>.brawl.perfectVsHeavy    number, 0 to 1
//   tools/schemas/director-interrupts.schema.json  brawl.flurry.runBy                     object: medium, a number 0 or more
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
const lv = '                "breakGuard": {\n                  "type": "number",\n                  "minimum": 0,\n                  "maximum": 1,\n                  "description": "The AI\'s share for breakGuard."\n                },\n';
edit('tools/schemas/director-ai.schema.json', rep => {
  rep(lv, lv +
    '                "mediumVsHeavies": {\n                  "type": "number",\n                  "minimum": 0,\n                  "maximum": 1,\n                  "description": "Against a rival whose last two blows were heavies, the share of its strings that are mediums."\n                },\n' +
    '                "perfectVsHeavy": {\n                  "type": "number",\n                  "minimum": 0,\n                  "maximum": 1,\n                  "description": "Its perfect block against a heavy it sees wound in a brawl."\n                },\n', 3);
});
const fl = '            "levelWithin": {\n              "type": "integer",\n              "minimum": 0,\n              "description": "Runs within this many blows of each other are a level trade, settled by the momentum."\n            },\n';
edit('tools/schemas/director-interrupts.schema.json', rep => {
  rep(fl, fl +
    '            "runBy": {\n              "type": "object",\n              "properties": {\n                "medium": {\n                  "type": "number",\n                  "minimum": 0,\n                  "description": "What a landed medium adds to his run and takes off the rival\'s, in points."\n                }\n              },\n              "additionalProperties": false,\n              "description": "What a landed blow counts on the run, by strength; a strength not named counts 1."\n            },\n', 1);
});
