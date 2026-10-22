// The kill switch: takes the playable site down in ONE command (Legal's RL-136 condition 4).
//   node tools/site-offline.mjs [--config <site.json>] [--check]
// Sets "offline": true, "approved": null and "interim": null in tools/site.json, so the next build is the plain holding page of tools/site-notice-offline.json ("The playable build is
// offline for now.", "... they are not fixed yet.", "There is no date for its return.": Legal's RL-171 words, restored by being offline, not by an edit) and nothing else (the full-set path and the interim both end). Commit and push the file to publish it. --check only reports the state (exit 0 when the site is offline, 1 when it is not). Idempotent.
import { readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const args = process.argv.slice(2);
const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
const file = resolve(opt('--config') || join(import.meta.dirname, 'site.json'));
const raw = readFileSync(file, 'utf8');
const crlf = raw.includes('\r\n');
const c = JSON.parse(raw);
// the words the holding page will say are the offline file's; a kill switch that would publish other words fails before it changes anything
const NOTICE = JSON.parse(readFileSync(join(import.meta.dirname, 'site-notice-offline.json'), 'utf8'));
const said = JSON.stringify(NOTICE);
for (const w of ['The playable build is offline for now.', 'they are not fixed yet.', 'There is no date for its return.']) {
  if (!said.includes(w)) { console.error(`site-offline: tools/site-notice-offline.json does not say "${w}" (Legal's RL-171 words, docs/legal/page-fixed-lines.md): not changing anything`); process.exit(3); }
}
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
console.log(`site: taken OFFLINE (${file}); it was ${was}. The holding page will say "The playable build is offline for now." and "... they are not fixed yet.". Commit and push tools/site.json to publish it.`);
