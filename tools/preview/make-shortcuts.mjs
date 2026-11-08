// Writes the two "Open" shortcuts (the plain page and the full-power page) for a kept build, into homework/1 Urgent and docs/tools/shortcuts (Tools, 2026-11-07: this was a scratch script
// for the morning build; the Sunday build needs it again, so it is a tool). CRLF, the flashing warning, the server started in its own window on its own port.
//   node tools/preview/make-shortcuts.mjs --kept orb-first-play-<commit8>-<key8> [--port 8768] [--label "morning build"] [--words "travel=1.5"] [--no-homework]
// It refuses a port that is already listening, a kept folder that is not in homework/Files/builds, and never overwrites a shortcut of another label (it overwrites its own label's pair).
// Node built-ins only.
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:net';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO = resolve(fileURLToPath(new URL('../..', import.meta.url)));

/** The text of one shortcut (CRLF). `kept` is the folder name under homework/Files/builds. */
export function shortcutText({ kept, port, title, peak, words = '' }) {
  if (words && !/^[A-Za-z0-9=._&-]+$/.test(words)) throw new Error('--words may hold letters, digits and = . _ & - only');
  const addr = `http://127.0.0.1:${port}/index.html?planet=7&meteor=loud&tiles=1&go=1&blackbox=1&audiolog=1${peak ? '&peak=1' : ''}${words ? '&' + words.replace(/^&/, '') : ''}`;
  const L = [
    '@echo off',
    `title ${title}`,
    `rem The KEPT folder is a build made by tools\\preview\\stack-preview.mjs and copied by tools\\preview\\handover.mjs into the repository's homework\\Files\\builds (git-ignored), never rebuilt. It is served on its own port, ${port}, so it never meets the builds before it.`,
    `set "KEPT=%~dp0..\\Files\\builds\\${kept}"`,
    'for %%I in ("%KEPT%") do set "KEPT=%%~fI"',
    `set "ADDR=${addr}"`,
    'echo.',
    'echo Warning: this build has a camera move (the launch swing and the meteor shot) that flashes',
    'echo far more than the safe limit, and Reduce flashing does not lower it. For your own screen only.',
    'echo Do not share the build, clips, recordings or screenshots, and keep anyone sensitive to flashing',
    'echo away from it. If you feel unwell, stop.',
    'echo.',
    'echo If you play in Opera GX: its limiter (GX Control) can slow a tab. Turn it off for this.',
    ...(peak ? ['echo.', 'echo This one starts both fighters at full power (tier 4): the meteor, the beams and the forms from the first second.'] : []),
    'echo.',
    'pause',
    `powershell -NoProfile -Command "try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 'http://127.0.0.1:${port}/index.html').StatusCode | Out-Null; exit 0 } catch { exit 1 }"`,
    'if %errorlevel%==0 (',
    '  start "" "%ADDR%"',
    '  exit /b',
    ')',
    'if not exist "%KEPT%\\serve.mjs" (',
    '  echo The kept build is not where this shortcut expects it:',
    '  echo   %KEPT%',
    '  echo Nothing was built or changed. Tell Tools.',
    '  pause',
    '  exit /b 1',
    ')',
    'echo The page is not running, so its server is started in a new window that stays open.',
    `start "Orb Combat EX - the game server (port ${port})" node "%KEPT%\\serve.mjs" ${port}`,
    `powershell -NoProfile -Command "$ok=$false; for ($i=0; $i -lt 30 -and -not $ok; $i++) { try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 'http://127.0.0.1:${port}/index.html').StatusCode | Out-Null; $ok=$true } catch { Start-Sleep 1 } }; if ($ok) { exit 0 } else { exit 1 }"`,
    'if %errorlevel%==0 (',
    '  start "" "%ADDR%"',
    '  exit /b',
    ')',
    'echo The server did not answer in 30 seconds. Look at the server window for why.',
    'pause',
    '',
  ];
  return L.join('\r\n');
}

const listening = (port) => new Promise((res) => { const s = createServer(); s.once('error', () => res(true)); s.once('listening', () => s.close(() => res(false))); s.listen(port, '127.0.0.1'); });

async function main() {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const kept = opt('--kept');
  const port = Number(opt('--port', 8768));
  const label = opt('--label', 'morning build');
  const words = opt('--words', '');
  if (!kept || !/^orb-first-play-[0-9a-f]{8}-[0-9a-zA-Z]{8}$/.test(kept)) { console.error('usage: node tools/preview/make-shortcuts.mjs --kept orb-first-play-<commit8>-<key8> [--port 8768] [--label "morning build"] [--no-homework]'); process.exit(2); }
  if (!existsSync(join(REPO, 'homework', 'Files', 'builds', kept, 'serve.mjs'))) { console.error(`refused: homework/Files/builds/${kept}/serve.mjs is not there (hand the build over first: node tools/preview/handover.mjs --dir <web>)`); process.exit(2); }
  if (!/^[A-Za-z0-9 ,'-]+$/.test(label)) { console.error('refused: the label may hold letters, digits, spaces, commas, apostrophes and hyphens only'); process.exit(2); }
  if (await listening(port)) console.error(`note: port ${port} is listening right now (a server of another build?); the shortcut would open that one. Pick another port with --port.`);
  const dirs = [join(REPO, 'docs', 'tools', 'shortcuts'), ...(a.includes('--no-homework') ? [] : [join(REPO, 'homework', '1 Urgent')])];
  const files = [[`Open - ${label}.cmd`, false], [`Open - ${label}, full power.cmd`, true]];
  for (const d of dirs) {
    if (!existsSync(d)) { console.error(`skipped: ${d} is not there`); continue; }
    for (const [name, peak] of files) { writeFileSync(join(d, name), shortcutText({ kept, port, title: `Orb Combat EX - ${label}${peak ? ', START AT FULL POWER' : ''}`, peak, words })); console.log(`wrote ${join(d, name)}`); }
  }
  console.log(`kept ${kept}, port ${port}`);
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
