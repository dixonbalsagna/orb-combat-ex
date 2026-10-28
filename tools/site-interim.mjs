// Renders the INTERIM playable site's own pages from tools/site-interim.json (Legal's ruling RL-136): the click-through gate that goes into /play/ and the About page (licences,
// notices, privacy). The holding page (/, /bench/, /band/, /404.html) is tools/site-notice.mjs's, unchanged. Static HTML, no external request, no tracking, noindex, no description,
// keywords, og: or twitter: tag, system fonts, readable on a phone. Used by tools/build-site.mjs and checked by tools/check-site-interim.mjs. Node built-ins only; deterministic.
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

const CSS = `  html { background: #0e1015; color: #e6e9ef; }
  body { font: 18px/1.55 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; max-width: 36rem; margin: 0 auto; padding: 1.5rem 1.25rem 3rem; }
  h1 { font-size: 1.5rem; line-height: 1.25; margin: 1rem 0 1.5rem; }
  h2 { font-size: 1.15rem; margin: 1.75rem 0 .5rem; }
  p, li { margin: .75rem 0; }
  pre { white-space: pre-wrap; word-wrap: break-word; font: 13px/1.45 ui-monospace, Consolas, monospace; background: #171a22; padding: .75rem; border-radius: 6px; }
  a { color: #8fb8ff; }
  .small { font-size: .85rem; color: #aab1be; }`;

function blocksHtml(blocks) {
  return blocks.map((b) => {
    if (b.h2 !== undefined) return `<h2>${esc(b.h2)}</h2>`;
    if (b.p !== undefined) return `<p>${esc(b.p)}</p>`;
    if (b.small !== undefined) return `<p class="small">${esc(b.small)}</p>`;
    if (b.ul !== undefined) return `<ul>\n${b.ul.map((x) => `<li>${esc(x)}</li>`).join('\n')}\n</ul>`;
    throw new Error(`site-interim.json: unknown block ${JSON.stringify(Object.keys(b))}`);
  }).join('\n');
}

function page(title, bodyHtml) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${esc(title)}</title>
<style>
${CSS}
</style>
</head>
<body>
${bodyHtml}
</body>
</html>
`;
}

/** The About page: this build, the AI line, privacy, flashing effects, the two notices, then the engine's own licence and copyright text (tools/site-licences.json, written by
 *  tools/site_licences.gd). It links to the gate and to the holding page and to nothing else. */
export function aboutPage(text, lic, links) {
  const parts = [];
  parts.push(`<h1>${esc(text.about.heading)}</h1>`);
  // with the freeze breadcrumbs on (tools/site-crumbs.mjs) the Privacy paragraph is Legal's switch-on paragraph; off, the words file's own
  let blocks = text.about.blocks;
  if (links.privacy) { const k = blocks.findIndex((b) => b.h2 === 'Privacy'); if (k < 0 || blocks[k + 1] === undefined || blocks[k + 1].p === undefined) throw new Error('the words file has no Privacy heading with a paragraph after it'); blocks = blocks.map((b, i) => (i === k + 1 ? { p: links.privacy } : b)); }
  parts.push(blocksHtml(blocks));
  parts.push(`<p><a href="${esc(links.play)}">${esc(text.gate.button)}: the game's first screen</a></p>`);
  parts.push('<h2>Godot Engine</h2>');
  parts.push(`<p>This game runs on the Godot Engine ${esc(lic.godot_version)} (godotengine.org), under its MIT License:</p>`);
  parts.push(`<pre>${esc(lic.license_text)}</pre>`);
  parts.push('<h2>Open Sans</h2>');
  for (const c of (lic.copyright || []).filter((x) => /open sans/i.test(x.name))) for (const p of c.parts) {
    parts.push(`<p>${esc(c.name)}: copyright ${esc((p.copyright || []).join('; '))}. Licensed under the SIL Open Font License, Version 1.1 (OFL-1.1):</p>`);
  }
  if (lic.licenses && lic.licenses['OFL-1.1']) parts.push(`<pre>${esc(lic.licenses['OFL-1.1'])}</pre>`);
  parts.push('<h2>Other components in the engine</h2>');
  parts.push('<p class="small">The components the Godot Engine itself lists, with their copyright holders and licenses. The license texts follow.</p>');
  const rows = [];
  for (const c of lic.copyright || []) {
    if (/^godot engine$/i.test(c.name)) continue;
    for (const p of c.parts) rows.push(`<li>${esc(c.name)}: ${esc((p.copyright || []).join('; '))} (${esc(p.license || '')})</li>`);
  }
  parts.push(`<ul class="small">\n${rows.join('\n')}\n</ul>`);
  for (const name of Object.keys(lic.licenses || {}).sort()) {
    if (name === 'OFL-1.1') continue;
    parts.push(`<h2>${esc(name)}</h2>\n<pre>${esc(lic.licenses[name])}</pre>`);
  }
  return page(text.title, parts.join('\n'));
}

/** The phone note's words, Legal's RL-201 (docs/legal/page-fixed-lines.md, 2026-10-28; ADR 0011): exact public words, a change to any word is a new ruling. tools/check-site-interim.mjs holds a copy of its own. */
export const PHONE_NOTE = {
  heading: 'Best on a computer',
  body: 'This demo is made for a computer with a keyboard or a controller. It may not run well on a phone.',
  button: 'Continue anyway',
};

/** The phone note's overlay: before the gate in the page and above it (z-index), `hidden` until the script finds a phone. Its button only takes the note away; the gate under it, with the flashing notice, the lock line and its own button, is untouched. */
export function phoneNoteOverlay() {
  return `<div id="phone-note" role="dialog" aria-modal="true" aria-labelledby="phone-note-title" hidden style="position:fixed;left:0;top:0;right:0;bottom:0;z-index:100001;overflow:auto;background:#0e1015;color:#e6e9ef;font:18px/1.55 system-ui,-apple-system,'Segoe UI',Roboto,sans-serif">
<div style="max-width:36rem;margin:0 auto;padding:1.5rem 1.25rem 3rem">
<h1 id="phone-note-title" style="font-size:1.5rem;line-height:1.25;margin:1rem 0 1.5rem">${esc(PHONE_NOTE.heading)}</h1>
<p>${esc(PHONE_NOTE.body)}</p>
<p style="margin:1.25rem 0 .5rem"><button id="phone-note-continue" type="button" style="font:inherit;font-weight:600;padding:.7rem 1.1rem;color:#0e1015;background:#e6e9ef;border:0;border-radius:6px;cursor:pointer">${esc(PHONE_NOTE.button)}</button></p>
</div>
</div>
`;
}

/** The overlay of /play/: the click-through. The engine starts only from its button (see the gate wrapping in tools/build-site.mjs). "Not now" goes to the holding page. */
export function gateOverlay(text, hrefs, opts = {}) {
  const small = 'font-size:.85rem;color:#aab1be';
  return `${phoneNoteOverlay()}<div id="gate" role="dialog" aria-modal="true" aria-labelledby="gate-title" style="position:fixed;left:0;top:0;right:0;bottom:0;z-index:100000;overflow:auto;background:#0e1015;color:#e6e9ef;font:18px/1.55 system-ui,-apple-system,'Segoe UI',Roboto,sans-serif">
<div style="max-width:36rem;margin:0 auto;padding:1.5rem 1.25rem 3rem">
<h1 id="gate-title" style="font-size:1.5rem;line-height:1.25;margin:1rem 0 1.5rem">${esc(text.gate.heading)}</h1>
${blocksHtml(text.gate.blocks)}
<p style="margin:1.25rem 0 .5rem"><button id="gate-start" type="button" style="font:inherit;font-weight:600;padding:.7rem 1.1rem;color:#0e1015;background:#e6e9ef;border:0;border-radius:6px;cursor:pointer">${esc(text.gate.button)}</button>
<a id="gate-notnow" href="${esc(hrefs.holding)}" style="margin-left:1rem;color:#aab1be;font-size:.95rem">${esc(text.gate.not_now)}</a></p>
<p id="gate-under" style="${small}">${esc(text.gate.under)}</p>
<p id="gate-ai" style="${small}">${esc(text.gate.ai)}</p>
<p style="font-size:.85rem"><a style="color:#8fb8ff" href="${esc(hrefs.about)}">${esc(text.gate.about)}</a></p>${opts.noteSlot ? '\n<div id="ocx-note-slot"></div>' : ''}
</div>
</div>`;
}

/** The only script of the gate: the button removes the overlay and calls the engine's start, which build-site.mjs wrapped in window.__startGame. */
export const GATE_SCRIPT = `<script>
(function () {
  var gate = document.getElementById('gate');
  var button = document.getElementById('gate-start');
  var started = false;
  button.addEventListener('click', function () {
    if (started) return;
    started = true;
    gate.parentNode.removeChild(gate);
    if (typeof window.__startGame === 'function') window.__startGame();
  });
  button.focus();
}());
/* phone note */
(function () {
  // A PHONE is a device whose main pointer is coarse (a finger) and whose smaller screen side is 500 CSS pixels or less. A tablet (smaller side 600 or more), a touch laptop (its main pointer is fine)
  // and a desktop window of any size are not phones and never see the note. The note's button takes the note away and nothing else: the gate under it, with the flashing notice, is untouched.
  var note = document.getElementById('phone-note');
  var go = document.getElementById('phone-note-continue');
  var gate = document.getElementById('gate');
  if (!note || !go) return;
  var phone = false;
  try { phone = window.matchMedia('(pointer: coarse)').matches && Math.min(screen.width, screen.height) <= 500; } catch (e) { phone = false; }
  if (!phone) { note.parentNode.removeChild(note); return; }
  note.hidden = false;
  if (gate) gate.setAttribute('inert', '');
  go.addEventListener('click', function () {
    note.parentNode.removeChild(note);
    if (gate) gate.removeAttribute('inert');
    var start = document.getElementById('gate-start');
    if (start) start.focus();
  });
  go.focus();
}());
/* end phone note */
</script>`;
