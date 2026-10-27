// The switch for the page's freeze breadcrumbs (docs/perf/phone-freeze-2026-10-26.md; the park docs/perf/web-shell/ocx-crumbs.js): OFF unless tools/site.json says "crumbs": true.
// What they are: local-only. One record in the visitor's own localStorage (stage, a heartbeat, stalls of 3 s or more, device facts), a dismissable note on the next visit with a Copy-a-report button,
// and a page notice with a reload button in place of the engine's alert when the graphics context is lost. Nothing is sent anywhere: tools/check-site-interim.mjs refuses a page whose breadcrumbs
// script has a network call, and refuses breadcrumbs in a page while this switch is off (or no breadcrumbs while it is on).
//
// The block lives in the Web preset's html/head_include (export_presets.cfg), written by docs/perf/tools/web-head.mjs --write --crumbs. The committed preset stays WITHOUT it; the switch folds the
// block into the preset of an export's own checkout, never into the repository:
//   node tools/site-crumbs.mjs --status [--config tools/site.json]            prints "on" or "off"
//   node tools/site-crumbs.mjs --apply  [--config tools/site.json] [--cfg export_presets.cfg]   when on, folds the block into that preset file (CI's checkout, a pinned export's tree)
// The pinned export (tools/site-pin.mjs) does the same to its scratch tree when the switch is on. It also sets the in-game privacy line (ui/data/howto.json, the "none" variant) to Legal's switch-on paragraph,
// and the About page is built with it (tools/build-site.mjs); with the switch off nothing of that changes.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(HERE, '..');
export const WEB_HEAD = join(REPO, 'docs', 'perf', 'tools', 'web-head.mjs');

/** Legal's privacy paragraph for the page WHILE THE SWITCH IS ON, word for word from docs/legal/crumbs-screen.md, Q1 (RL-188, p04). With the switch off, today's line stays exactly as it is. The self-test holds this constant equal to Legal's document. */
export const CRUMBS_PRIVACY = "This game sends no personal data and does not use trackers. To help with freezes, the page keeps one small technical record in your browser's storage on this device: the stage it reached, how long it stopped, and basic facts about your browser and screen. The game sends nothing. If it froze and you choose \"Copy a report\", the text goes only where you paste it. The web version is hosted on GitHub Pages, which keeps its own server logs. The feedback button copies a report to your clipboard for you to paste to Orb; nothing is sent by the game. Clearing this site's data in your browser removes the record.";

/** The in-game About line for the feedback target "none" (ui/data/howto.json, icon about_privacy_none) in a tree: with the switch on it is Legal's paragraph, so the game's own panel agrees with the page. Returns true when it changed. */
export function applyPrivacy(root) {
  const f = join(root, 'ui', 'data', 'howto.json');
  if (!existsSync(f)) throw new Error(`${f} does not exist: the in-game privacy line cannot be set`);
  const raw = readFileSync(f, 'utf8');
  const re = /("icon":\s*"about_privacy_none"[^{}]*?"text":\s*)("(?:[^"\\]|\\.)*")/;
  const hit = re.exec(raw);
  if (!hit) throw new Error('ui/data/howto.json has no about_privacy_none line');
  const next = raw.replace(re, (all, a) => a + JSON.stringify(CRUMBS_PRIVACY));
  if (next === raw) return false;
  writeFileSync(f, next);
  return true;
}


/** Is the switch on in a site config? Only the value true counts. Pure. */
export function crumbsOn(config) { return !!config && config.crumbs === true; }

/** Folds the breadcrumbs into a preset file with web-head.mjs (the repository's own copy). Throws when it cannot. */
export function applyCrumbs(cfgPath) {
  if (!existsSync(cfgPath)) throw new Error(`${cfgPath} does not exist: nothing to fold the breadcrumbs into`);
  const r = spawnSync(process.execPath, [WEB_HEAD, '--write', '--crumbs', '--cfg', cfgPath], { encoding: 'utf8' });
  if (r.status !== 0) throw new Error(`web-head.mjs --write --crumbs failed (exit ${r.status}): ${(r.stderr || r.stdout || '').trim().slice(0, 300)}`);
  return r.stdout.trim();
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
  const config = JSON.parse(readFileSync(resolve(opt('--config') || join(HERE, 'site.json')), 'utf8'));
  const on = crumbsOn(config);
  if (args.includes('--status')) { console.log(on ? 'on' : 'off'); process.exit(0); }
  if (args.includes('--apply')) {
    if (!on) { console.log('site crumbs: off (tools/site.json has no "crumbs": true); the preset is left as it is'); process.exit(0); }
    try {
      const cfgPath = resolve(opt('--cfg') || join(REPO, 'export_presets.cfg'));
      console.log(`site crumbs: on; ${applyCrumbs(cfgPath)}`);
      console.log(`site crumbs: the in-game privacy line ${applyPrivacy(opt('--root') ? resolve(opt('--root')) : dirname(cfgPath)) ? 'set to Legal\'s paragraph' : 'already is Legal\'s paragraph'}`);
    } catch (e) { console.error(`site crumbs: ${e.message}`); process.exit(1); }
    process.exit(0);
  }
  console.error('usage: node tools/site-crumbs.mjs --status | --apply [--config <site.json>] [--cfg <export_presets.cfg>]');
  process.exit(2);
}
