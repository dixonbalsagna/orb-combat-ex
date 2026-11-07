// Audio's web shell snippet in the head of EVERY web build (the EP, 2026-11-07: Orb's morning file had both audio contexts suspended for 178 s of pad play,
// because a pad press is never a browser's user gesture). The snippet (docs/audio/pending/audio-resume/shell-snippet.js, or docs/audio/shell-snippet.js once it lands)
// wakes the engine's own AudioContext on a pad press. It goes in its own <script data-orb-shell> right after <head>, before the engine script, in preview pages,
// kept builds and the public site's /play/ and /bench/ pages. Idempotent: a page that has it is returned as it was. Node built-ins only.
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

export const SHELL_PATHS = ['docs/audio/shell-snippet.js', 'docs/audio/pending/audio-resume/shell-snippet.js'];

/** The snippet's text from a repository checkout, or '' when it is not there. */
export function shellSnippet(repo) {
  for (const p of SHELL_PATHS) { const f = join(repo, ...p.split('/')); if (existsSync(f)) return readFileSync(f, 'utf8'); }
  return '';
}

/** The page with the snippet as the first thing in <head>. An empty snippet or a page that has it is returned unchanged. */
export function injectShell(html, snippet) {
  if (!snippet || html.includes('data-orb-shell')) return html;
  const tag = `<script data-orb-shell>\n${snippet.split('</script').join('<\\/script')}\n</script>\n`;
  return html.includes('<head>') ? html.replace('<head>', () => `<head>\n${tag}`) : tag + html;
}
