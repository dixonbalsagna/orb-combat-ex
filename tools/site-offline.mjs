// The kill switch: takes the playable site down in ONE command (Legal's RL-136 condition 4).
//   node tools/site-offline.mjs [--config <site.json>] [--check]
// Sets "offline": true, "approved": null and "interim": null in tools/site.json, so the next build is the plain holding page of tools/site-notice.json and nothing else (the full-set
// path and the interim both end). Commit and push the file to publish it. --check only reports the state (exit 0 when the site is offline, 1 when it is not). Idempotent.
import { readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const args = process.argv.slice(2);
const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
const file = resolve(opt('--config') || join(import.meta.dirname, 'site.json'));
const raw = readFileSync(file, 'utf8');
const crlf = raw.includes('\r\n');
const c = JSON.parse(raw);
const offline = c.offline === true && (c.approved === null || c.approved === undefined) && !c.interim;
if (args.includes('--check')) {
  console.log(offline ? `site: offline (${file})` : `site: ONLINE (${file}): offline ${c.offline}, approved ${c.approved}, interim ${c.interim ? c.interim.legal + ' until ' + c.interim.expires : 'none'}`);
  process.exit(offline ? 0 : 1);
}
if (offline) { console.log(`site: already offline (${file}); nothing changed`); process.exit(0); }
const was = `offline ${c.offline}, approved ${c.approved}, interim ${c.interim ? c.interim.legal + ' until ' + c.interim.expires : 'none'}`;
c.offline = true;
c.approved = null;
c.interim = null;
const out = JSON.stringify(c, null, 2) + '\n';
writeFileSync(file, crlf ? out.replace(/\n/g, '\r\n') : out);
console.log(`site: taken OFFLINE (${file}); it was ${was}. Commit and push tools/site.json to publish the holding page.`);
