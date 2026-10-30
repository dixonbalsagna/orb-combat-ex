// Checks a built INTERIM playable site (tools/site.json "interim"; Legal's ruling RL-136, docs/legal/photosensitivity-note.md addendum 8) and what it depends on.
// With no "interim" block it says so and passes (the offline check and the full-set release path are other gates). With one, it FAILS if:
//   - the interim has expired (interim.expires is before today, UTC), lacks a Legal ruling id, an approval date or an expiry, or its words are still a draft; or the pass file
//     (tools/flash/release-pass.json) does not record the interim with the same ruling and expiry and the three waivers;
//   - /play/ autoplays: the engine's start is anywhere but inside window.__startGame, window.__startGame is called from anywhere but the gate's button, or the gate is missing, is not
//     before the canvas, or has no button; any <audio> or <video> autoplays;
//   - the click-through can be skipped: any page other than /play/ holds a script, an iframe, a meta refresh, a reference to the game's files, or a link that is not to the gate
//     (/play/ exactly), the About page or the holding page; /, /bench/, /band/ and /404.html are not exactly the holding page (tools/site-notice.json); any other .html file is in the site;
//   - "Not now" on the gate does not go to the holding page;
//   - any page lacks noindex or has a description, keywords, og: or twitter: tag;
//   - "Reduce flashing" is not on by default in the shipped prefs (ui/data/options.json default, ui/data/features.json, and the default in ui/hud/ui_hud.gd);
//   - the gate's words lack what Legal ruled (flashing effects, the finding against three a second, "no independent analyzer has been run", the advice for photosensitive epilepsy,
//     "I understand, start", "Not now", the Reduce flashing line, the AI line) or the About page lacks the AI line, the privacy line of the feedback target in use (ui/data/send.json),
//     the Godot (MIT) line or the Open Sans (OFL) line; or any page uses "safe", "seizure-safe", "tested for photosensitivity", "WCAG compliant", "certified" or "no flashing";
//   - the freeze breadcrumbs are on /play/ without tools/site.json "crumbs": true (or absent with it), or their script has a network call or a URL;
//   - the game's own strings (ui/data/*.json, Legal's RL-192 condition 2): the in-game notice (ui/data/terms.json prompt.menu_notice, photo_title, photo_body_a, photo_body_b, menu_rf_locked), the help of the settings row 'Flashing effects notice' and the label 'Color-blind mode' are not Legal's lines word for word (owner mode), a string promises a fix (owner mode), or any string a player reads has a British spelling (every mode; the still-pending ones are listed in tools/site-ui-spelling.json); on the one pin whose strings predate the swap (tools/site-ui-excuse.json, only in that commit's exported tree, only the listed rule kinds) those failures are printed as notes instead;
//   - the placeholder-name scan finds KAI, VORR, Meridian or Calamity in a page, or in a file of the game's pack that is not on the allowlist (tools/site-name-scan.json).
//   node tools/check-site-interim.mjs --site <site dir> [--config <site.json>] [--root <repo root>] [--record <release-pass.json>] [--ui-allow <site-ui-spelling.json>] [--ui-excuse <site-ui-excuse.json>] [--today YYYY-MM-DD] [--no-pack-scan]
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, resolve, relative, sep } from 'node:path';
import { siteNotice } from './site-notice.mjs';
import { scanHtml, scanPack, unallowed } from './site-name-scan.mjs';
import { INTERIM_WAIVES } from './flash/release-pass.mjs';
import { CRUMBS_PRIVACY, BUILD_LINE } from './site-crumbs.mjs';
import { scanRoutes } from './site-routes.mjs';
import { gateProblems, DEFAULT_FILE as SIGNATURE_GATE } from './flash/signature-gate.mjs';

const args = process.argv.slice(2);
const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
const site = opt('--site');
if (!site) { console.error('usage: node tools/check-site-interim.mjs --site <site dir> [--config <site.json>] [--root <repo root>] [--record <release-pass.json>] [--today YYYY-MM-DD] [--no-pack-scan]'); process.exit(2); }
const here = import.meta.dirname;
const root = resolve(opt('--root') || join(here, '..'));
const config = JSON.parse(readFileSync(resolve(opt('--config') || join(here, 'site.json')), 'utf8'));
if (!config.interim) { console.log('interim site check: tools/site.json has no "interim"; nothing to check here'); process.exit(0); }
const I = config.interim;
const today = opt('--today') || new Date().toISOString().slice(0, 10);
const problems = [];
const bad = (m) => problems.push(m);
const FORBIDDEN = [/\bsafe\b/i, /seizure-safe/i, /tested for photosensitivity/i, /WCAG compliant/i, /\bcertified\b/i, /no flashing/i];   // Legal's never-words (addendum 1)
// the gate's first sentence, Legal's RL-137 (photosensitivity-note.md addendum 9); the rest of the paragraph is checked by the patterns below
const LEGAL_FIRST = "This game contains flashing effects, and our own automated check found scenes that reach the recommended limit of three flashes a second, and a few that go over it on stricter readings.";
// The phone note, Legal's RL-201 (docs/legal/page-fixed-lines.md, 2026-10-28; ADR 0011), word for word, written out here on purpose: a drift in tools/site-interim.mjs must show. A change to any word is a new ruling.
const PHONE_HEADING = 'Best on a computer';
const PHONE_BODY = 'This demo is made for a computer with a keyboard or a controller. It may not run well on a phone.';
const PHONE_BUTTON = 'Continue anyway';
const LEGAL_AI = 'Orb Combat EX is a one-person project. Orb directs it, and AI tools write the code and draft the art, animation, dialogue and design documents. Nothing in the game is generated by AI while you play: the fight director and the world are ordinary game code.';
const PRIVACY = {
  none: 'This game collects and sends no personal data. The web version is hosted on GitHub Pages, which keeps its own server logs. The feedback button copies a report to your clipboard for you to paste to Orb; nothing is sent by the game.',
};
const GODOT_LINE = 'Made with Godot Engine. Copyright (c) 2014-present Godot Engine contributors; copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur. Released under the MIT License.';
const SANS_LINE = 'Open Sans: Copyright 2020 The Open Sans Project Authors. Released under the SIL Open Font License 1.1.';
// Legal's fixed lines for the owner-approved page, word for word (docs/legal/page-fixed-lines.md, RL-166, 2026-10-22): the flash notice (the gate and the About page carry the same words) and the lock line
const OWNER_FLASH = 'This game contains flashing effects. Our own automated check found some scenes that go over the recommended limit of three flashes a second, and they are not fixed yet. No independent analyzer has been run. If you or someone in your family has photosensitive epilepsy, please do not play this version.';
const OWNER_LOCK = 'Reduce flashing is on and cannot be turned off in this version. It lowers some effects but does not remove the flagged scenes.';
// British spellings Legal lists; the public text is American English (Orb's rule p03). Internal setting ids may keep them: only text a visitor can read is scanned.
const BRITISH = /\b(colour|behaviour|grey|centre|artefact|programme|catalogue|neighbour|organis|recognis|licence|analyser)/i;
// The game's own notice strings (ui/data/terms.json, UI's file), Legal's RL-192 addendum in docs/legal/page-fixed-lines.md: the in-game notice carries the same words as the gate. Word for word, in owner mode.
const GAME_STRINGS = {
  menu_notice: OWNER_FLASH,
  photo_title: 'This game contains flashing effects.',
  photo_body_a: 'Our own automated check has found some scenes, such as a camera fly-past of collapsing buildings and some beam impacts, that flash more often than the recommended limit of three times a second, and they are not fixed yet.',
  photo_body_b: 'No independent photosensitivity analyzer has been run. If you or someone in your family has photosensitive epilepsy, please do not play this version.',
  menu_rf_locked: OWNER_LOCK,
};
const SETTINGS_FLASH_END = 'and that no independent photosensitivity analyzer has been run.';   // the end of the help of the settings row "Flashing effects notice" (ui/data/settings.json)
const COLOR_BLIND_LABEL = 'Color-blind mode';   // ui/data/options.json options.colour_vision.label (the id stays)
const PROMISES_FIX = /working to fix them|we are fixing them|while we fix them/i;
const visibleText = (html) => textOf(html.replace(/<ul class="small">[\s\S]*?<\/ul>/g, ' '));   // not the engine's own component list (third-party names); <pre> texts are dropped by textOf
const decode = (s) => s.replace(/&quot;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
const textOf = (html) => decode(html.replace(/<pre>[\s\S]*?<\/pre>/g, ' ').replace(/<style>[\s\S]*?<\/style>/g, ' ').replace(/<script>[\s\S]*?<\/script>/g, ' ').replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ');

// ---- the interim itself
// OWNER-APPROVED (Orb's order, 2026-10-18): interim.owner names who decided; then there is no Legal ruling id, the expiry is optional and the pass file is read for the report only.
const OWNER = typeof I.owner === 'string' && I.owner.trim() ? I.owner.trim() : null;
if (OWNER && (I.expires === undefined || I.expires === null)) { /* no expiry set: the owner decides when it comes down */ }
else if (!/^\d{4}-\d{2}-\d{2}$/.test(String(I.expires))) bad('interim.expires is not a date');
else if (today > I.expires) bad(`the interim expired on ${I.expires} (today is ${today}): take the playable site down (node tools/site-offline.mjs) or have Legal renew it`);
if (!OWNER && !/^RL-\d+/.test(String(I.legal))) bad('interim.legal is not a Legal ruling id (or interim.owner naming the owner who decided)');
if (!/^\d{4}-\d{2}-\d{2}$/.test(String(config.approved))) bad('tools/site.json has no "approved" date');
const noticePath = resolve(here, I.notice || 'site-interim.json');
let words = null;
try { words = JSON.parse(readFileSync(noticePath, 'utf8')); } catch (e) { bad(`the interim words could not be read: ${e.message}`); }
if (words && words.draft !== false) bad('the interim words are still a draft (tools/site-interim.json "draft" is not false)');

// the pass file records the interim, its waivers and its expiry
if (!OWNER) {
  const rf = resolve(opt('--record') || join(here, 'flash', 'release-pass.json'));
  let rec = null;
  try { rec = JSON.parse(readFileSync(rf, 'utf8')).interim || null; } catch { /* reported below */ }
  if (!rec) bad(`${rf} does not record the interim (an "interim" block with the ruling, the dates and the waivers)`);
  else {
    if (rec.legal !== I.legal) bad(`the pass file records the interim as ${rec.legal}, tools/site.json as ${I.legal}`);
    if (rec.expires !== I.expires) bad(`the pass file's interim expires ${rec.expires}, tools/site.json's ${I.expires}`);
    for (const w of INTERIM_WAIVES) if (!Array.isArray(rec.waives) || !rec.waives.includes(w)) bad(`the pass file does not record the waiver ${w}`);
  }
}

// ---- the site
const siteRoot = resolve(site);
const walk = (d) => readdirSync(d, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(join(d, e.name)) : [join(d, e.name)]));
const files = existsSync(siteRoot) ? walk(siteRoot).map((f) => relative(siteRoot, f).split(sep).join('/')) : [];
const htmls = files.filter((f) => /\.html?$/i.test(f));
const ALLOWED = ['index.html', 'play/index.html', 'bench/index.html', 'band/index.html', '404.html', 'about/index.html'];
const HOLDING = ['index.html', 'bench/index.html', 'band/index.html', '404.html'];
for (const h of htmls) if (!ALLOWED.includes(h)) bad(`${h} is a page the interim site does not have: an ungated copy of the game could hide in it`);
for (const p of ALLOWED) if (!files.includes(p)) bad(`${p} is missing from the interim site`);
if (files.some((f) => /^(bench|band)\/.*\.(wasm|pck)$/i.test(f))) bad('/bench/ or /band/ holds a game file: only /play/ may');
const read = (p) => (files.includes(p) ? readFileSync(join(siteRoot, p), 'utf8') : '');

// the holding page: exactly the plain notice, wherever the old links land
let holdingHtml = null;
try { holdingHtml = siteNotice(JSON.parse(readFileSync(join(here, 'site-notice.json'), 'utf8'))); } catch (e) { bad(`tools/site-notice.json could not be read: ${e.message}`); }
for (const p of HOLDING) if (holdingHtml && files.includes(p) && read(p) !== holdingHtml) bad(`${p} is not the holding page of tools/site-notice.json`);

// /play/: the gate
const play = read('play/index.html');
if (play) {
  const starts = [...play.matchAll(/engine\.startGame\(/g)].map((m) => m.index);
  const wrapAt = play.indexOf('window.__startGame = function');
  const wrapEnd = play.indexOf('};', play.indexOf('displayFailureNotice);', wrapAt) + 1);
  if (starts.length !== 1) bad(`/play/ calls engine.startGame ${starts.length} times (it must be once, inside window.__startGame)`);
  if (wrapAt < 0 || (starts[0] !== undefined && !(starts[0] > wrapAt && starts[0] < wrapEnd))) bad('/play/: the engine starts outside window.__startGame (it would autoplay)');
  const calls = [...play.matchAll(/__startGame\s*\(/g)].length;
  if (calls !== 1) bad(`/play/: window.__startGame is called ${calls} times (it must be called once, from the gate's button)`);
  const bodyAt = play.indexOf('<body>');
  const gateAt = play.indexOf('id="gate"');
  const canvasAt = play.indexOf('<canvas');
  if (gateAt < 0 || !(gateAt > bodyAt && gateAt < canvasAt)) bad('/play/: the gate is missing or is not before the game canvas in the body');
  if (!/id="gate-start"/.test(play)) bad('/play/: the gate has no button');
  const clickAt = play.indexOf("addEventListener('click'", Math.max(0, gateAt));   // the gate's own script, after its overlay: a head script that listens for clicks (the breadcrumbs) comes before it
  if (clickAt < 0 || !/__startGame\s*\(\)/.test(play.slice(clickAt, clickAt + 400))) bad("/play/: the gate's button does not call window.__startGame");
  if (/<(audio|video)\b[^>]*\bautoplay\b/i.test(play)) bad('/play/: an audio or video element autoplays');
  if (!play.includes('<meta name="robots" content="noindex">')) bad('/play/ is not noindex');
  if (/<meta[^>]+(name|property)="(description|keywords|og:[^"]*|twitter:[^"]*)"/i.test(play)) bad('/play/ has a description, keywords or social-card tag');
  if (!/<meta name="viewport"/.test(play)) bad('/play/ has no viewport meta (small screens)');
  // the gate's own words and its two controls
  const gateHtml = play.slice(Math.max(0, play.indexOf('id="gate"')), play.indexOf('id="gate-start"') + 1200);
  const notNow = /<a id="gate-notnow" href="([^"]*)"[^>]*>([^<]*)<\/a>/.exec(gateHtml);
  if (!notNow) bad('/play/: the gate has no "Not now" control');
  else {
    if (decode(notNow[2]).trim() !== 'Not now') bad('/play/: the second control of the gate does not read "Not now"');
    if (notNow[1] !== '../') bad(`/play/: "Not now" goes to ${notNow[1]}, not the holding page (../)`);
  }
  const gateText = textOf(gateHtml);
  const need = [
    [/This game contains flashing effects/, 'the gate does not say the game contains flashing effects'],
    [/three flashes a second/, 'the gate does not state the finding against the recommended three flashes a second'],
    [/[Nn]o independent analyzer has been run/, 'the gate does not say no independent analyzer has been run'],
    [/photosensitive epilepsy, please do not play this version/, 'the gate does not carry the advice for people with photosensitive epilepsy'],
    [/I understand, start/, 'the gate has no "I understand, start" button'],
    OWNER ? [/Reduce flashing is on and cannot be turned off in this version\. It lowers some effects but does not remove the flagged scenes\./, "the gate's line that Reduce flashing is on and cannot be turned off (Legal's addendum 11 wording) is missing"] : [/Reduce flashing is on\. It lowers some effects but does not remove the flagged scenes\./, "the gate's small line about Reduce flashing is missing"],
  ];
  for (const [re, msg] of need) if (!re.test(gateText)) bad(`/play/: ${msg}`);
  if (!gateText.includes(LEGAL_AI)) bad("/play/: the gate does not carry Legal's AI line");
  if (!OWNER && !gateText.includes(LEGAL_FIRST)) bad("/play/: the gate's first sentence is not Legal's (RL-137)");
  if (OWNER && words && words.gate && words.gate.blocks && words.gate.blocks[0] && !gateText.includes(words.gate.blocks[0].p)) bad("/play/: the gate does not carry the owner-approved paragraph of the interim words");
  if (OWNER && !/some scenes that go over the recommended limit/.test(gateText)) bad('/play/: the owner-approved gate does not say that some scenes go over the recommended limit');
  if (OWNER && !gateText.includes(OWNER_FLASH)) bad("/play/: the gate's flash notice is not Legal's fixed line word for word (docs/legal/page-fixed-lines.md; it ends 'and they are not fixed yet')");
  if (OWNER && !gateText.includes(OWNER_LOCK)) bad("/play/: the gate's lock line is not Legal's fixed line word for word");
  if (OWNER && /working to fix them|we are fixing them/i.test(gateText)) bad('/play/: the gate promises a fix ("working to fix them"): flash work is paused, so the notice must say "not fixed yet"');
  for (const re of FORBIDDEN) if (re.test(gateText)) bad(`/play/'s gate uses a word Legal forbids: ${re}`);

  // ---- the phone note (Legal's RL-201, ADR 0011): shown on a phone before the flashing notice, never in its place
  const noteAt = play.indexOf('id="phone-note"');
  if (noteAt < 0) bad('/play/ has no phone note (Legal RL-201: a phone sees "Best on a computer" before the flashing notice)');
  else {
    const noteTagAt = play.lastIndexOf('<div', noteAt);
    const noteEnd = gateAt > noteAt ? play.lastIndexOf('</div>', gateAt) + 6 : -1;   // the note is closed before the gate opens
    if (!(noteAt > bodyAt && gateAt > noteAt)) bad('/play/: the phone note is not before the gate in the page (RL-201 condition 1: the note comes before the flashing notice)');
    else {
      const noteHtml = play.slice(noteTagAt, noteEnd);
      const nt = textOf(noteHtml).trim();
      if (nt !== `${PHONE_HEADING} ${PHONE_BODY} ${PHONE_BUTTON}`) bad(`/play/: the phone note's words are not Legal's RL-201 lines word for word, and nothing else (heading "${PHONE_HEADING}", body, button "${PHONE_BUTTON}"): ${JSON.stringify(nt.length > 160 ? nt.slice(0, 160) + '...' : nt)}`);
      if (!new RegExp(`<h1 id="phone-note-title"[^>]*>${PHONE_HEADING}</h1>`).test(noteHtml)) bad('/play/: the heading of the phone note is not "Best on a computer" in its heading element');
      if (!noteHtml.includes(`<p>${PHONE_BODY}</p>`)) bad('/play/: the body of the phone note is not Legal one string');
      if (!new RegExp(`<button id="phone-note-continue"[^>]*>${PHONE_BUTTON}</button>`).test(noteHtml)) bad('/play/: the button of the phone note is not "Continue anyway" (id phone-note-continue)');
      if (!/^<div id="phone-note"[^>]*\shidden[\s>]/.test(noteHtml.trim())) bad('/play/: the phone note is not hidden in the markup (phones only: the script shows it on a phone, a computer never sees it)');
      if (/id="gate|gate-start|gate-notnow|<a\s|<form|<input/i.test(noteHtml)) bad('/play/: the phone note holds a gate control, a link or a form (its one button must only take the note away: RL-201 condition 1)');
      if (/href=|src=|<img|<iframe|<video|<audio/i.test(noteHtml)) bad('/play/: the phone note holds a reference or a media element');
      if (gateHtml.includes('phone-note')) bad('/play/: the phone note is inside the gate, so it would replace or shorten the notice');
    }
    // the note's script: phones only, and its button never starts the game, clicks the gate's button, removes the gate or leaves the page
    const s0 = play.indexOf('/* phone note */'), s1 = play.indexOf('/* end phone note */');
    if (s0 < 0 || s1 < s0) bad('/play/: the phone note has no script between its /* phone note */ markers (the button would do nothing)');
    else {
      const ns = play.slice(s0, s1);
      if (!/matchMedia\('\(pointer: coarse\)'\)\.matches\s*&&\s*Math\.min\(screen\.width,\s*screen\.height\)\s*<=\s*500/.test(ns)) bad("/play/: the phone note's script does not test for a phone (a coarse main pointer and a smaller screen side of 500 CSS pixels or less): a computer must never see the note");
      if (/__startGame|\.click\s*\(|dispatchEvent|\.submit\s*\(|\blocation\b|\.open\s*\(|history\./.test(ns)) bad("/play/: the phone note's script starts the game, clicks something, opens a page or moves the visitor (RL-201 condition 1: its button is not the notice's button and does not count as seeing the notice)");
      if (/removeChild\(\s*gate\b|\bgate\.(remove\(|style|hidden|innerHTML|outerHTML|textContent)|getElementById\('gate'\)\.(remove|style)|(set|remove)Attribute\('(?!inert')/.test(ns)) bad("/play/: the phone note's script removes or changes the gate (the notice must still be there, unchanged, after the note's button)");
      for (const m of ns.matchAll(/getElementById\('([^']*)'\)/g)) if (!/^(phone-note|phone-note-continue|gate|gate-start)$/.test(m[1])) bad(`/play/: the phone note's script looks up #${m[1]}: it may touch only its own two elements, the gate (to hold it aside while the note shows) and the gate's button (to focus it)`);
      if ((ns.match(/removeChild/g) || []).length !== 2 || (ns.match(/removeChild\(note\)/g) || []).length !== 2) bad("/play/: the phone note's script removes something other than the note");
    }
    // the gate's own script still starts the game, from the gate's button only, and comes after the note's overlay
    const gateScriptAt = play.indexOf("addEventListener('click'", gateAt);
    if (gateScriptAt >= 0 && s0 >= 0 && !(s0 > gateScriptAt)) bad("/play/: the phone note's script comes before the gate's own (the gate's button must stay the first click handler after the gate)");
  }
}

// The freeze breadcrumbs (tools/site-crumbs.mjs; docs/perf/phone-freeze-2026-10-26.md): local-only, and only while tools/site.json says "crumbs": true. The page must carry them exactly when the switch is on,
// and their script must make no network call (nothing may be sent off the device).
{
  const marker = 'ocx.crumbs.v1';
  const carries = !!play && play.includes(marker);
  if (config.crumbs === true && play && !carries) bad('tools/site.json says "crumbs": true, but /play/ does not carry the freeze breadcrumbs (they are folded into the Web preset by tools/site-crumbs.mjs --apply before the export)');
  if (config.crumbs !== true && carries) bad('/play/ carries the freeze breadcrumbs but tools/site.json does not say "crumbs": true: the breadcrumbs are a switched park, and the preset in the repository must not hold them');
  if (carries) {
    const script = (play.match(/<script>[\s\S]*?<\/script>/g) || []).find((s) => s.includes(marker)) || '';
    for (const [re, what] of [[/\bfetch\s*\(/, 'fetch'], [/XMLHttpRequest/, 'XMLHttpRequest'], [/sendBeacon/, 'sendBeacon'], [/WebSocket/, 'WebSocket'], [/EventSource/, 'EventSource'], [/importScripts|import\s*\(/, 'an import'], [/new\s+Image\b|new\s+Worker\b|\.src\s*=/, 'an image, worker or src'], [/https?:\/\//, 'a URL'], [/document\.cookie/, 'a cookie'], [/navigator\.serviceWorker/, 'a service worker']])
      if (re.test(script)) bad(`the freeze breadcrumbs' script uses ${what}: nothing may be sent off the device`);
    if (!script) bad('the freeze breadcrumbs marker is on /play/ but not inside one of its inline scripts');
    // the report's build line: the pin's short hash and its commit date (never "unknown", never the unfilled token), and the same as the tree's own build_info.json
    const bm = /BUILD = '([^']*)'/.exec(script);
    if (!bm) bad('the freeze breadcrumbs script has no build line (var BUILD)');
    else if (!BUILD_LINE.test(bm[1])) bad(`the freeze breadcrumbs' build line reads "${bm[1]}": it must be "<short hash> <YYYY-MM-DD>" (tools/site-crumbs.mjs --apply and the pinned export pass it), so a report never reads "build: unknown"`);
    else { try { const bi = JSON.parse(readFileSync(join(root, 'build_info.json'), 'utf8')); if (`${bi.commit} ${bi.date}` !== bm[1]) bad(`the freeze breadcrumbs' build line "${bm[1]}" is not the exported tree's own (${bi.commit} ${bi.date})`); } catch { /* no build_info.json in this root */ } }
    // the note goes inside the click-through, in the slot the gate provides, so it never moves or covers the gate's buttons; over the game only when there is no gate
    if (!/id="ocx-note-slot"/.test(play.slice(play.indexOf('id="gate"')))) bad('the freeze breadcrumbs are on, but the gate has no note slot (id ocx-note-slot, below its words and buttons)');
    if (!script.includes('ocx-note-slot')) bad("the freeze breadcrumbs' script does not use the gate's note slot (id ocx-note-slot): its note would sit over the gate's buttons on a small phone");
    // Legal's four conditions for the note inside the click-through (RL-190, 1f6b42dc)
    // (1) it sits OUTSIDE the notice's own words: one empty slot, a child of the gate's own box after the About paragraph, so the word-for-word checks above still compare the notice untouched, and the script puts nothing into any other part of the gate
    const gateTail = play.slice(play.indexOf('id="gate"'));
    if ((gateTail.match(/id="ocx-note-slot"/g) || []).length !== 1) bad('the gate must have exactly one note slot (id ocx-note-slot)');
    if (!/href="[^"]*about[^"]*"[^>]*>[^<]*<\/a><\/p>\n<div id="ocx-note-slot"><\/div>\n<\/div>/.test(gateTail)) bad("the gate's note slot must be an empty div of the gate's own box, straight after the About paragraph (outside every paragraph, heading, button and link of the notice)");
    if (/slot\.(style|parentNode|parentElement|innerHTML|outerHTML|textContent|className|classList|setAttribute|remove)\b/.test(script)) bad("the freeze breadcrumbs' script does more to the gate's slot than append its note to it");
    // (2) never above the warning or the buttons, and never pushing them off a small screen: the slot comes after the heading, both controls and the About link; the gate stays a fixed, scrolling, topmost box; and the note's own style in the slot is plain flow (no position, layer, offset, order, transform, float or negative margin)
    const at = (s) => gateTail.indexOf(s);
    const order = [at('id="gate-title"'), at('id="gate-start"'), at('id="gate-notnow"'), gateTail.search(/href="[^"]*about[^"]*"/), at('id="ocx-note-slot"')];
    if (order.some((v, i) => v < 0 || (i > 0 && v <= order[i - 1]))) bad('the note slot is not after the gate\'s heading, its "I understand, start" button, "Not now" and the About link: the note would sit above the warning or the buttons');
    const gateStyle = (/^id="gate"[^>]*style="([^"]*)"/.exec(gateTail) || [])[1] || '';
    const gateZ = Number((/z-index:\s*(\d+)/.exec(gateStyle) || [])[1] || 0);
    if (!/position:fixed/.test(gateStyle) || !/overflow:auto/.test(gateStyle) || gateZ < 1000) bad('the gate is no longer a fixed, scrolling, topmost box (position:fixed, overflow:auto, a high z-index): a note under its buttons could push them off a small screen or sit above them');
    const slotStyle = (/slot\s*\?\s*'([^']*)'/.exec(script) || [])[1];
    if (slotStyle === undefined) bad("the freeze breadcrumbs' script has no note style for when the slot is used");
    else if (/(^|;)\s*(position|z-index|top|bottom|left|right|inset|order|transform|float|translate)\s*:|margin[a-z-]*\s*:[^;]*-\s*\d|display\s*:\s*none/.test(slotStyle)) bad("the note's style inside the gate is not plain flow (a position, layer, offset, order, transform, float, negative margin or display:none would let it cover or move the gate's buttons)");
    // (3) Dismiss and Copy never change the gate's state or let anything skip it: the script never names the gate or the start function, never clicks or dispatches an event, looks up only its own elements (and the engine's status ones to read), and the gate's start is bound to its own button
    if (/__startGame|\bgate\b|dispatchEvent|\.click\s*\(|\.submit\s*\(|location\s*=[^=]|location\.(href|assign|replace)\b/.test(script)) bad("the freeze breadcrumbs' script names the gate or its start function, clicks, dispatches an event or navigates: Dismiss and Copy must never change the gate's state");
    for (const m of script.matchAll(/getElementById\('([^']*)'\)/g)) if (!/^(ocx-[a-z-]+|status|status-progress)$/.test(m[1])) bad(`the freeze breadcrumbs' script looks up #${m[1]}: it may touch only its own ocx- elements (and read the engine's status ones)`);
    if (/querySelector|getElementsBy|\.closest\s*\(|\b(document|window|d|w)\.addEventListener\('(click|pointerdown|pointerup|mousedown|mouseup|touchstart|touchend)'/.test(script)) bad("the freeze breadcrumbs' script reaches elements by a query or listens for clicks on the whole page, where it could catch the gate's controls");
    if (!/var (\w+) = document\.getElementById\('gate-start'\);[\s\S]{0,120}?\1\.addEventListener\('click'/.test(gateTail)) bad("the gate's start is not bound to its own button (a click listener on the gate or the page could be reached by the note's buttons)");
    for (const claim of ['prepared once', 'it is still working']) if (script.includes(claim)) bad(`the freeze breadcrumbs' start line still says "${claim}": Legal (docs/legal/crumbs-screen.md section 2) took that claim out (a real hang looks the same; nothing promises once)`);
    if (script.includes('PLACEHOLDER')) bad('the freeze breadcrumbs still carry PLACEHOLDER words (the start line, the note, the buttons): the visitor must never read them; the words come from Community and Marketing and pass Legal first (docs/legal/crumbs-screen.md section 2)');
  }
}

// every other page: static, no game, only links to the gate, About or the holding page; the words; the scan
for (const p of ALLOWED.filter((x) => x !== 'play/index.html')) {
  const html = read(p);
  if (!html) continue;
  if (/<script/i.test(html)) bad(`${p} has a script`);
  if (/<iframe|<embed|<object/i.test(html)) bad(`${p} embeds something`);
  if (/<meta[^>]+http-equiv="?refresh/i.test(html)) bad(`${p} redirects (a meta refresh)`);
  if (!html.includes('<meta name="robots" content="noindex">')) bad(`${p} is not noindex`);
  if (/<meta[^>]+(name|property)="(description|keywords|og:[^"]*|twitter:[^"]*)"/i.test(html)) bad(`${p} has a description, keywords or social-card tag`);
  if (/\.(wasm|pck|js)\b/i.test(html.replace(/<pre>[\s\S]*?<\/pre>/g, ''))) bad(`${p} names a game file`);
  if (/<(link|img|form|source|base)\b|\bsrc=|\baction=|url\(/i.test(html)) bad(`${p} loads or submits to something (a link element, image, form, src or url())`);
  const shown = html.replace(/<pre>[\s\S]*?<\/pre>/g, '').replace(/<style>[\s\S]*?<\/style>/g, '');
  for (const re of FORBIDDEN) if (re.test(shown)) bad(`${p} uses a word Legal forbids: ${re}`);
  const where = p.split('/').slice(0, -1);
  for (const m of html.matchAll(/<a\b[^>]*\bhref="([^"]*)"/gi)) {
    const href = m[1];
    if (href.startsWith('#')) continue;
    if (/^[a-z]+:/i.test(href) || href.startsWith('//')) { bad(`${p} links away: ${href}`); continue; }
    if (/[?#]/.test(href)) { bad(`${p} links with a query or fragment: ${href}`); continue; }
    const parts = where.slice();
    for (const seg of href.split('/')) { if (seg === '..') parts.pop(); else if (seg !== '.' && seg !== '') parts.push(seg); }
    const target = parts.join('/');
    if (!['play', 'about', ''].includes(target)) bad(`${p} links to ${href} (${target || '/'}): only the gate (/play/), /about/ and the holding page may be linked`);
  }
  for (const w of scanHtml(html)) bad(`the placeholder-name scan: "${w}" is on ${p}`);
}

// About: the words
{
  const about = read('about/index.html');
  if (about) {
    const t = textOf(about);
    if (!t.includes(LEGAL_AI)) bad("/about/ does not carry Legal's AI line");
    if (!OWNER && !t.includes(LEGAL_FIRST)) bad("/about/'s flashing-effects paragraph does not start with Legal's first sentence (RL-137)");
    if (OWNER && words && words.gate && words.gate.blocks && words.gate.blocks[0] && !t.includes(words.gate.blocks[0].p)) bad("/about/'s flashing-effects paragraph does not carry the owner-approved paragraph");
    if (OWNER && !t.includes(OWNER_FLASH)) bad("/about/'s flash notice is not Legal's fixed line word for word (docs/legal/page-fixed-lines.md)");
    if (OWNER && !t.includes(OWNER_LOCK)) bad("/about/'s lock line is not Legal's fixed line word for word");
    if (OWNER && /working to fix them|we are fixing them/i.test(t)) bad('/about/ promises a fix ("working to fix them"): flash work is paused');
    if (!t.includes(GODOT_LINE)) bad('/about/ does not carry the Godot (MIT) notice line');
    if (!t.includes(SANS_LINE)) bad('/about/ does not carry the Open Sans (OFL) notice line');
    if (!/MIT License|Permission is hereby granted/.test(about)) bad("/about/ does not carry Godot's licence text");
    if (!/SIL OPEN FONT LICENSE|SIL Open Font License|OFL/i.test(about)) bad("/about/ does not carry Open Sans' licence text");
    let target = null;
    try { target = JSON.parse(readFileSync(join(root, 'ui/data/send.json'), 'utf8'))._target; } catch (e) { bad(`ui/data/send.json could not be read: ${e.message}`); }
    if (target !== null) {
      const pt = words && words.privacy_target;
      if (pt !== target) bad(`the privacy line was written for the feedback target "${pt}", but ui/data/send.json _target is "${target}": Legal's matching variant (ui/data/howto.json) must be used`);
      else if (PRIVACY[target]) {
        // keyed to the freeze-breadcrumbs switch (Legal, docs/legal/crumbs-screen.md Q1): ON, Legal's new paragraph and not today's line; OFF, today's line exactly and not the new one
        if (config.crumbs === true) {
          if (target !== 'none') bad('the freeze breadcrumbs are on, but Legal wrote the switch-on privacy paragraph for the feedback target none only');
          if (!t.includes(CRUMBS_PRIVACY)) bad("the freeze breadcrumbs are on, but /about/ does not carry Legal's switch-on privacy paragraph word for word (docs/legal/crumbs-screen.md, Q1)");
          if (t.includes('This game collects and sends no personal data')) bad('the freeze breadcrumbs are on, but /about/ still says "collects and sends no personal data": Legal replaced that line while they are on');
        } else {
          if (!t.includes(PRIVACY[target])) bad("/about/ does not carry Legal's privacy line for the feedback target in use");
          if (t.includes('does not use trackers') || t.includes(CRUMBS_PRIVACY.slice(0, 60))) bad('the freeze breadcrumbs are off, but /about/ carries the switch-on privacy paragraph');
        }
      }
      else bad(`there is no Legal privacy line recorded for the feedback target "${target}" in tools/check-site-interim.mjs`);
    }
  }
}

// The game's own About line (ui/data/howto.json, the "none" variant) says what the page says: Legal's switch-on paragraph while the breadcrumbs are on, today's line while they are off.
{
  const hf = join(root, 'ui/data/howto.json');
  if (existsSync(hf)) {
    let found = null;
    const walkJ = (n) => { if (found !== null || !n || typeof n !== 'object') return; if (n.icon === 'about_privacy_none' && typeof n.text === 'string') { found = n.text; return; } for (const v of Object.values(n)) walkJ(v); };
    try { walkJ(JSON.parse(readFileSync(hf, 'utf8'))); } catch (e) { bad(`ui/data/howto.json could not be read: ${e.message}`); }
    const want = config.crumbs === true ? CRUMBS_PRIVACY : PRIVACY.none;
    if (found === null) bad('ui/data/howto.json has no about_privacy_none line');
    else if (found !== want) bad(config.crumbs === true ? "the freeze breadcrumbs are on, but the game's own About line (ui/data/howto.json about_privacy_none) is not Legal's switch-on paragraph (tools/site-crumbs.mjs --apply sets it in the tree that is exported)" : "the game's own About line (ui/data/howto.json about_privacy_none) is not today's privacy line, which must stay exactly as it is while the freeze breadcrumbs are off");
  }
}

// No cookie: Legal's switch-on words say the page "does not use trackers", so nothing on the site may set a cookie: no assignment to document.cookie, no Cookie Store write, no Set-Cookie text in any script or page of
// the site (the engine's own glue and the audio worklets included). A request header cannot be checked here: GitHub Pages sets none, and the breadcrumbs make no request.
for (const p of files.filter((f) => /\.(js|mjs|html?)$/i.test(f))) {
  const body = read(p);
  for (const [re, what] of [[/document\s*\.\s*cookie\s*=(?!=)/, 'an assignment to document.cookie'], [/cookieStore\s*\.\s*(set|delete)\s*\(/, 'a Cookie Store write'], [/Set-Cookie/i, 'Set-Cookie']])
    if (re.test(body)) bad(`${p} sets a cookie (${what}): the page says it does not use trackers`);
}

// American spelling: every page's visible text (and, below, the words file) is scanned for the British spellings Legal lists
for (const p of htmls) { const m = BRITISH.exec(visibleText(read(p))); if (m) bad(`${p} uses the British spelling "${m[0]}" (the public text is American English: docs/legal/page-fixed-lines.md)`); }

// the game's pack: the placeholder-name scan
if (!args.includes('--no-pack-scan') && files.includes('play/index.pck')) {
  try {
    const allow = JSON.parse(readFileSync(join(here, 'site-name-scan.json'), 'utf8'));
    // the exported tree is the pack's own commit only when its build_info.json names the pin: then a name found in compressed bytecode counts only when the script's source holds it too
    let treeCommit = '';
    try { treeCommit = String(JSON.parse(readFileSync(join(root, 'build_info.json'), 'utf8')).commit || ''); } catch { /* not an exported tree */ }
    const treeIsPin = treeCommit.length >= 7 && /^[0-9a-f]{40}$/.test(String(config.pin)) && config.pin.startsWith(treeCommit);
    const r = scanPack(readFileSync(join(siteRoot, 'play/index.pck')), treeIsPin ? { source: (p) => { const f = join(root, p.replace(/^res:\/\//, '')); return existsSync(f) ? readFileSync(f, 'utf8') : null; } } : {});
    if (r.chance.length) console.log(`interim site check note: ${r.chance.length} placeholder-name hit${r.chance.length === 1 ? '' : 's'} in compiled scripts (${r.chance.map((h) => `${h.word} in ${h.path}`).join(', ')}) are chance matches in compressed bytecode: the scripts' own source has no such word`);
    for (const h of unallowed(r.hits, allow)) bad(`the placeholder-name scan: "${h.word}" is in ${h.path} of the game's pack, which is not on the allowlist (tools/site-name-scan.json)`);
  } catch (e) { bad(`the game's pack could not be scanned: ${e.message}`); }
}

// ---- shipped prefs: Reduce flashing on by default
const rf = (() => { try { return JSON.parse(readFileSync(join(root, 'ui/data/options.json'), 'utf8')); } catch { return null; } })();
const wrap = rf && Object.keys(rf).find((k) => rf[k] && typeof rf[k] === 'object' && rf[k].reduce_flashing);
const optDefault = rf && (wrap ? rf[wrap].reduce_flashing : rf.reduce_flashing);
if (!optDefault || optDefault.default !== true) bad(`"Reduce flashing" is not on by default: ui/data/options.json reduce_flashing.default is ${JSON.stringify(optDefault && optDefault.default)}`);
try {
  const feat = JSON.parse(readFileSync(join(root, 'ui/data/features.json'), 'utf8'));
  if (!(feat.features && feat.features.reduce_flashing === true)) bad('"Reduce flashing" has no row: ui/data/features.json features.reduce_flashing is not true');
  // Legal's addendum 10 (RL-156): until full effects have a recorded pass, the interim build must not offer them: UI's lock (docs/ui/reduce-flashing-lock.md) hides the row and ignores an Off. One word in the
  // export's features.json; if it is forgotten the toggle shows, so the build fails here.
  if (!(feat.features && feat.features.lock_reduce_flashing === true)) bad('the interim build offers full effects: ui/data/features.json features.lock_reduce_flashing is not true (Legal RL-156, docs/ui/reduce-flashing-lock.md)');
} catch (e) { bad(`ui/data/features.json could not be read: ${e.message}`); }
try {
  const hud = readFileSync(join(root, 'ui/hud/ui_hud.gd'), 'utf8');
  const m = /"reduce_flashing":\s*(true|false)/.exec(hud);
  if (m && m[1] !== 'true') bad('"Reduce flashing" is off in ui/hud/ui_hud.gd (opts default)');
} catch { /* the file is UI's; the data default above is the gate */ }

// ---- the game's own strings (ui/data/*.json): the in-game notice word for word (owner mode) and the American-spelling scan (every mode). Legal's RL-192 condition 2.
{
  const dir = join(root, 'ui/data');
  const ui = {};
  let names = [];
  try { names = readdirSync(dir).filter((f) => f.endsWith('.json')).sort(); } catch (e) { bad(`ui/data could not be listed: ${e.message}`); }
  for (const f of names) { try { ui[f] = JSON.parse(readFileSync(join(dir, f), 'utf8')); } catch (e) { bad(`ui/data/${f} could not be read: ${e.message}`); } }
  // the text a player reads: every string value, not the keys (the ids that contain "colour" are internal), not an _underscore note, not a file's own top-level "note" (its description for the team), not an id
  const ID_LIKE = /^[a-z0-9]+(_[a-z0-9]+)+$/;
  const strings = (v, at, out, top) => {
    if (Array.isArray(v)) v.forEach((x, i) => strings(x, `${at}/${i}`, out, false));
    else if (v && typeof v === 'object') { for (const [k, x] of Object.entries(v)) { if (k.startsWith('_') || (top && k === 'note')) continue; if (k === 'id' && typeof x === 'string') continue; strings(x, `${at}/${k}`, out, false); } }
    else if (typeof v === 'string' && !ID_LIKE.test(v)) out.push([at, v]);
    return out;
  };
  // British spellings still in the game's text that RL-192 does not name, pending Legal's ruling and UI's swap: tools/site-ui-spelling.json (file + pointer, with the reason); anything else fails
  let allowFile = resolve(opt('--ui-allow') || join(here, 'site-ui-spelling.json'));
  let allow = [];
  try { allow = JSON.parse(readFileSync(allowFile, 'utf8')).allow || []; } catch (e) { bad(`the in-game spelling allowlist could not be read (${allowFile}): ${e.message}`); }
  const used = new Set();
  // the content rules below (spelling, a fix promise, the notice word for word) collect into uiProblems, kind by kind, so a per-pin excuse can name the kinds it covers (tools/site-ui-excuse.json); a file that cannot be read, or a line that is missing altogether, stays a plain failure (only text that is there and is wrong can be excused)
  const uiProblems = [];
  const ubad = (kind, m) => uiProblems.push({ kind, m });
  for (const f of names) for (const [at, s] of strings(ui[f], '', [], true)) {
    const m = BRITISH.exec(s);
    if (!m) continue;
    const i = allow.findIndex((a) => a && a.file === `ui/data/${f}` && a.pointer === at);
    if (i >= 0) { used.add(i); continue; }
    ubad('spelling', `ui/data/${f} ${at} uses the British spelling "${m[0]}" in text a player reads (the game's text is American English: docs/legal/page-fixed-lines.md, RL-192 condition 2): ${JSON.stringify(s.length > 80 ? s.slice(0, 80) + '...' : s)}`);
  }
  allow.forEach((a, i) => { if (!used.has(i)) console.log(`interim site check note: tools/site-ui-spelling.json lists ${a && a.file} ${a && a.pointer}, which no longer holds a British spelling: remove the entry`); });
  if (OWNER) {
    for (const f of names) for (const [at, s] of strings(ui[f], '', [], true)) if (PROMISES_FIX.test(s)) ubad('fix-promise', `ui/data/${f} ${at} promises a fix ("we are fixing them" and its kin are untrue since flash work paused, 2026-10-18: docs/legal/page-fixed-lines.md, RL-192)`);
    const prompt = ui['terms.json'] && ui['terms.json'].prompt;
    for (const [k, want] of Object.entries(GAME_STRINGS)) if (!prompt || prompt[k] !== want) (prompt && typeof prompt[k] === 'string' ? ubad : (kind, m) => bad(m))('notice-lines', `ui/data/terms.json prompt.${k} is not Legal's line word for word (docs/legal/page-fixed-lines.md, RL-192 addendum): ${JSON.stringify(prompt && typeof prompt[k] === 'string' ? (prompt[k].length > 80 ? prompt[k].slice(0, 80) + '...' : prompt[k]) : prompt && prompt[k])}`);
    const row = ui['settings.json'] && Array.isArray(ui['settings.json'].sections) ? ui['settings.json'].sections.flatMap((s) => (Array.isArray(s.items) ? s.items : [])).find((it) => it && typeof it === 'object' && it.action === 'photo_notice') : null;
    if (!row || typeof row.help !== 'string' || !row.help.endsWith(SETTINGS_FLASH_END) || /\btested\b/i.test(row.help)) (row && typeof row.help === 'string' ? ubad : (kind, m) => bad(m))('notice-lines', `ui/data/settings.json: the help of the "Flashing effects notice" row does not end "${SETTINGS_FLASH_END}" (and must not say "tested"): docs/legal/page-fixed-lines.md, RL-192 addendum`);
    const cv = ui['options.json'] && ui['options.json'].options && ui['options.json'].options.colour_vision;
    if (!cv || cv.label !== COLOR_BLIND_LABEL) (cv && typeof cv.label === 'string' ? ubad : (kind, m) => bad(m))('notice-lines', `ui/data/options.json options.colour_vision.label is not "${COLOR_BLIND_LABEL}" (docs/legal/page-fixed-lines.md, RL-192 addendum)`);
  }
  // The one pin whose strings predate RL-192's swap may stay up while the swap lands (tools/site-ui-excuse.json, a ruling named in the file; same shape as the routes grandfather). The excuse holds only when the pin in site.json AND the tree being checked are that commit
  // (the exported tree's build_info.json says which commit it is), and only for the rule kinds the file lists; HEAD's own strings, and every other pin's, are checked in full.
  let ex = null;
  try { ex = JSON.parse(readFileSync(resolve(opt('--ui-excuse') || join(here, 'site-ui-excuse.json')), 'utf8')); } catch { /* none: no pin is excused */ }
  let rootCommit = null;
  try { rootCommit = String(JSON.parse(readFileSync(join(root, 'build_info.json'), 'utf8')).commit || ''); } catch { /* not an exported tree: nothing is excused */ }
  const exKinds = ex && Array.isArray(ex.rules) ? ex.rules : [];
  // The excuse ends at the next pin move or on its "until" date, whichever comes first (Legal RL-200): the file present after either is itself a failure, so it is removed in the same commit as a pin move.
  let exLive = false;
  if (ex) {
    const ok = /^\d{4}-\d{2}-\d{2}$/.test(String(ex.until));
    if (!ok) bad('tools/site-ui-excuse.json has no valid "until" date (YYYY-MM-DD): the excuse ends on a date, so the file must say which');
    else if (today > ex.until) bad(`the excuse in tools/site-ui-excuse.json (${ex.ruling}) ended on ${ex.until}: remove the file; the game's strings are checked in full from here`);
    if (ex.commit !== config.pin) bad(`the pin moved off ${String(ex.commit).slice(0, 8)}, the commit tools/site-ui-excuse.json (${ex.ruling}) excuses: remove the file in the same commit as the pin move (the new pin's strings are checked in full)`);
    exLive = ok && today <= ex.until;
  }
  const excused = exLive && /^[0-9a-f]{40}$/.test(String(ex.commit)) && ex.commit === config.pin && rootCommit !== null && rootCommit.length >= 7 && ex.commit.startsWith(rootCommit);
  const covered = uiProblems.filter((p) => excused && exKinds.includes(p.kind));
  for (const p of uiProblems) if (!covered.includes(p)) bad(p.m);
  if (covered.length) {
    const kinds = [...new Set(covered.map((p) => p.kind))].join(', ');
    console.log(`interim site check note: ${covered.length} of RL-192 condition 2's string rules (${kinds}) are not met by the strings of the pin ${ex.commit.slice(0, 8)}, which ${ex.ruling} lets stay up while the swap lands (tools/site-ui-excuse.json); a new pin must pass in full`);
    for (const p of covered) console.log(`interim site check note (excused on ${ex.commit.slice(0, 8)}): ${p.m}`);
  }
}

// ---- the lock cannot be lifted by a route (Legal's RL-195 condition (b)): a URL word, a saved setting, a debug key, the capture hook (tools/site-routes.mjs)
{
  const routeProblems = scanRoutes(root);
  // the one pin Legal ruled may stay up while the fix lands (RL-196): tools/site-routes-grandfather.json, for that commit only; every new pin passes the scan in full
  let gf = null;
  try { gf = JSON.parse(readFileSync(resolve(opt('--routes-grandfather') || join(here, 'site-routes-grandfather.json')), 'utf8')); } catch { /* none: no pin is excused */ }
  if (routeProblems.length && gf && /^[0-9a-f]{40}$/.test(String(gf.commit)) && gf.commit === config.pin) {
    console.log(`interim site check note: the routes scan finds ${routeProblems.length} open route${routeProblems.length === 1 ? '' : 's'} on the pin ${gf.commit.slice(0, 8)}, which ${gf.ruling} lets stay up while the fix lands (tools/site-routes-grandfather.json); a new pin must pass in full`);
  } else for (const m of routeProblems) bad(`normal mode is reachable: ${m} (Legal RL-195 condition (b), docs/tools/site-interim.md)`);
}

// ---- the pin only moves to a commit whose signature clip, reduced, reads no worse than 2.5 / 3 / 2 (Legal's RL-195 condition (a); tools/flash/signature-gate.mjs)
if (OWNER) {
  let rec = null;
  try { rec = JSON.parse(readFileSync(resolve(opt('--signature-gate') || SIGNATURE_GATE), 'utf8')); } catch { /* reported by gateProblems */ }
  for (const m of gateProblems(rec, config.pin)) bad(`the signature gate: ${m}`);
}

// ---- the words file itself
if (words) {
  const strip = (v) => (Array.isArray(v) ? v.map(strip) : v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).filter(([k]) => !k.startsWith('_')).map(([k, x]) => [k, strip(x)])) : v);
  const all = JSON.stringify(strip(words));
  for (const re of FORBIDDEN) if (re.test(all)) bad(`the interim words use a word Legal forbids: ${re}`);
  const br = BRITISH.exec(all); if (br) bad(`the interim words use the British spelling "${br[0]}"`);
}

if (problems.length) { for (const p of problems) console.error(`interim site check FAILED: ${p}`); process.exit(1); }
console.log(`interim site check ok: ${files.length} files; /play/ starts the engine only from the gate's button and "Not now" goes to the holding page; every other page leads only to the gate, About or the holding page; noindex everywhere; Reduce flashing is on by default; the name scan is clean; interim ${OWNER ? 'owner-approved (' + OWNER + ')' : I.legal} runs until ${I.expires} (today ${today})`);
