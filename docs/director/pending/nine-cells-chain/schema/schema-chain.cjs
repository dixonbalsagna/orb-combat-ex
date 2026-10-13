// schema-chain.cjs <checkout root>: every optional schema key of the nine cells' chain in one run (for Tools, or for
// Encounter by the EP's grant as before): pass 1 (brawl.burst.floorGap, holdCarries) and the fourth round
// (digInAfterS; brawl.firstMove: lockTicks, pursue). It runs schema7.cjs and schema8.cjs beside it, then adds pursue.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const root = process.argv[2];
for (const s of ['schema7.cjs', 'schema8.cjs']) process.stdout.write(execFileSync(process.execPath, [path.join(__dirname, s), root]));
const p = path.join(root, 'tools/schemas/director-interrupts.schema.json');
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
const a = '              "description": "A fighter sent by a launch, a wall slam or a knock-back cannot start an approach until this many ticks after he is free (0: no lock)."\n            }\n';
if (t.split(a).length !== 2) throw new Error('anchor');
t = t.replace(a, () => a.replace(/\}\n$/, '},\n') + '            "pursue": {\n              "type": "boolean",\n              "description": "While the first move is his, the launcher\'s press from the far band flies in, where a tap there opens a taunt."\n            }\n');
JSON.parse(t);
fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log('pursue: ok');
