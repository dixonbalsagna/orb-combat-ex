// Writes ./web_parity_tpl.mjs, a scratch copy of sim/core/tools/web_parity.mjs (Simulation's) that reads WEB_TEMPLATE=<zip> and writes it into the scratch export's Web preset (the repo's preset is never changed); REPO is fixed to this checkout. Run it in a scratch folder. Owner: Performance and Platform.
const fs=require('fs');
const R='C:/Users/itsha/Documents/Claude Proj/Breakers-Like';
let s=fs.readFileSync(R+'/sim/core/tools/web_parity.mjs','utf8');
const a="const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');";
if(!s.includes(a)) throw new Error('no REPO line');
s=s.replace(a,"const REPO = '"+R+"';");
const b="if (existsSync(ep)) writeFileSync(ep, readFileSync(ep, 'utf8').split(', sim/core/tools/*').join(''));";
if(!s.includes(b)) throw new Error('no preset line');
s=s.replace(b,"if (existsSync(ep)) { let t = readFileSync(ep, 'utf8').split(', sim/core/tools/*').join(''); if (process.env.WEB_TEMPLATE) { if (!t.includes('custom_template/release=\"\"')) throw new Error('preset already has a template'); t = t.replace('custom_template/release=\"\"', 'custom_template/release=\"' + process.env.WEB_TEMPLATE + '\"'); } writeFileSync(ep, t); }");
fs.writeFileSync('web_parity_tpl.mjs',s);
console.log('ok');
