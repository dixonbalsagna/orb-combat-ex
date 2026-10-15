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
  parts.push(blocksHtml(text.about.blocks));
  parts.push(`<p><a href="${esc(links.play)}">${esc(text.gate.button)}: the game's first screen</a></p>`);
  parts.push('<h2>Godot Engine</h2>');
  parts.push(`<p>This game runs on the Godot Engine ${esc(lic.godot_version)} (godotengine.org), under its MIT licence:</p>`);
  parts.push(`<pre>${esc(lic.license_text)}</pre>`);
  parts.push('<h2>Open Sans</h2>');
  for (const c of (lic.copyright || []).filter((x) => /open sans/i.test(x.name))) for (const p of c.parts) {
    parts.push(`<p>${esc(c.name)}: copyright ${esc((p.copyright || []).join('; '))}. Licensed under the SIL Open Font License, Version 1.1 (OFL-1.1):</p>`);
  }
  if (lic.licenses && lic.licenses['OFL-1.1']) parts.push(`<pre>${esc(lic.licenses['OFL-1.1'])}</pre>`);
  parts.push('<h2>Other components in the engine</h2>');
  parts.push('<p class="small">The components the Godot Engine itself lists, with their copyright holders and licences. The licence texts follow.</p>');
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

/** The overlay of /play/: the click-through. The engine starts only from its button (see the gate wrapping in tools/build-site.mjs). "Not now" goes to the holding page. */
export function gateOverlay(text, hrefs) {
  const small = 'font-size:.85rem;color:#aab1be';
  return `<div id="gate" role="dialog" aria-modal="true" aria-labelledby="gate-title" style="position:fixed;left:0;top:0;right:0;bottom:0;z-index:100000;overflow:auto;background:#0e1015;color:#e6e9ef;font:18px/1.55 system-ui,-apple-system,'Segoe UI',Roboto,sans-serif">
<div style="max-width:36rem;margin:0 auto;padding:1.5rem 1.25rem 3rem">
<h1 id="gate-title" style="font-size:1.5rem;line-height:1.25;margin:1rem 0 1.5rem">${esc(text.gate.heading)}</h1>
${blocksHtml(text.gate.blocks)}
<p style="margin:1.25rem 0 .5rem"><button id="gate-start" type="button" style="font:inherit;font-weight:600;padding:.7rem 1.1rem;color:#0e1015;background:#e6e9ef;border:0;border-radius:6px;cursor:pointer">${esc(text.gate.button)}</button>
<a id="gate-notnow" href="${esc(hrefs.holding)}" style="margin-left:1rem;color:#aab1be;font-size:.95rem">${esc(text.gate.not_now)}</a></p>
<p id="gate-under" style="${small}">${esc(text.gate.under)}</p>
<p id="gate-ai" style="${small}">${esc(text.gate.ai)}</p>
<p style="font-size:.85rem"><a style="color:#8fb8ff" href="${esc(hrefs.about)}">${esc(text.gate.about)}</a></p>
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
</script>`;
