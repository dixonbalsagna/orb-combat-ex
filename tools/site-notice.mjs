// Renders the offline notice (tools/site-notice.json) as one plain static HTML page: no script, no external request, no tracking, readable on a phone, dark background, system fonts,
// noindex, and no description, keywords, og: or twitter: tag (Legal, RL-121: the working title is in the visible heading and the tab title only). Used by tools/build-site.mjs and
// checked by tools/check-site-offline.mjs.
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

export function siteNotice(notice) {
  const body = notice.blocks.map((b) => {
    if (b.h2 !== undefined) return `<h2>${esc(b.h2)}</h2>`;
    if (b.p !== undefined) return `<p>${esc(b.p)}</p>`;
    if (b.small !== undefined) return `<p class="small">${esc(b.small)}</p>`;
    if (b.ul !== undefined) return `<ul>\n${b.ul.map((x) => `<li>${esc(x)}</li>`).join('\n')}\n</ul>`;
    throw new Error(`site-notice.json: unknown block ${JSON.stringify(Object.keys(b))}`);
  }).join('\n');
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${esc(notice.title)}</title>
<style>
  html { background: #0e1015; color: #e6e9ef; }
  body { font: 18px/1.55 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; max-width: 36rem; margin: 0 auto; padding: 1.5rem 1.25rem 3rem; }
  h1 { font-size: 1.5rem; line-height: 1.25; margin: 1rem 0 1.5rem; }
  h2 { font-size: 1.15rem; margin: 1.75rem 0 .5rem; }
  p, li { margin: .5rem 0; }
  ul { padding-left: 1.25rem; }
  .small { font-size: .85rem; color: #aab1be; }
</style>
</head>
<body>
<h1>${esc(notice.title)}</h1>
${body}
</body>
</html>
`;
}
