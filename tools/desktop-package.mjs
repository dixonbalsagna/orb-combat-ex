// What goes next to the game in a desktop download, and the checks on a packed folder (the Desktop builds workflow, docs/tools/desktop-builds.md).
//
//   node tools/desktop-package.mjs text   --platform windows|linux|macos --out <dir> [--build-info <build_info.json>]
//        writes README.txt and NOTICES.txt into <dir>: the flashing notice and the AI line word for word from the site's active notice file (tools/site.json interim.notice), how to run
//        the package, and the engine's licence text (tools/site-licences.json, the same text the web build's About page carries). A draft notice is refused, as build-site.mjs refuses it.
//   node tools/desktop-package.mjs lock   --root <exported tree>
//        sets lock_reduce_flashing true in <root>/ui/data/features.json, the same one-word edit the site's export makes (tools/site-pin.mjs, Legal RL-156): the interim's terms hold for a
//        download too. It edits a checkout in place, so it runs only on a CI checkout (GITHUB_ACTIONS=true) or on a root that is not this repository.
//   node tools/desktop-package.mjs astc   --root <exported tree>
//        sets textures/vram_compression/import_etc2_astc=true in <root>/project.godot, which Godot requires for a universal macOS export (the Apple silicon half); same guard as `lock`.
//   node tools/desktop-package.mjs verify --platform windows|linux|macos --dir <unpacked package> [--commit <sha>] [--locked | --unlocked]
//        reads the unpacked folder the way a player's machine would find it: the files that must be there, the executable's magic bytes, the pck (appended to the executable, or inside the
//        app), build_info.json with a real commit, README.txt carrying the notice and the AI line, NOTICES.txt carrying the engine's licence, and whether the Reduce flashing lock is
//        compiled in. It cannot RUN a Windows or macOS build on a Linux runner, and says so in its last line.
// Exit 0 when all hold, 1 when one does not, 2 on a usage error.
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { scanRoutes } from './site-routes.mjs';

const HERE = import.meta.dirname;
const REPO = resolve(HERE, '..');
export const PLATFORMS = ['windows', 'linux', 'macos'];
export const NAMES = { windows: 'orb-combat-ex.exe', linux: 'orb-combat-ex.x86_64', macos: 'Orb Combat EX.app' };
export const LOCK_ON = /"lock_reduce_flashing"\s*:\s*true/;
export const LOCK_OFF = /"lock_reduce_flashing"\s*:\s*false/;

/** The notice file the site uses (tools/site.json interim.notice, default site-interim.json), parsed; a draft is an error. */
export function activeNotice(toolsDir = HERE) {
  let notice = 'site-interim.json';
  try { const c = JSON.parse(readFileSync(join(toolsDir, 'site.json'), 'utf8')); if (c.interim && c.interim.notice) notice = c.interim.notice; } catch { /* the default */ }
  const f = join(toolsDir, notice);
  const t = JSON.parse(readFileSync(f, 'utf8'));
  if (t.draft !== false) throw new Error(`${f} is still a draft: Legal's words are not in, so no download is packed with them`);
  if (!t.gate || !t.gate.heading || !Array.isArray(t.gate.blocks) || !t.gate.blocks.length || !t.gate.ai) throw new Error(`${f} has no flashing notice or no AI line in its "gate"`);
  return t;
}

// Legal's RL-204 (docs/legal/page-fixed-lines.md, addendum 2026-10-28): exact public words. A change to any of them is a new ruling; the self-test holds each against that file.
export const WINDOWS_WARN = 'Windows or your antivirus may warn you because the file is not signed with a publisher certificate. If you do not trust the file, do not run it. The commit it was built from is named at the top of this file.';
export const XATTR_LEAD = 'Or, from Terminal, remove the download flag from this app only:';
export const PRIVACY = 'This game has no accounts and does not collect or send any personal data. It saves your settings on your computer. Your operating system or antivirus may check the file on its own.';
export const NO_ASSURANCE = ['safe', 'tested', 'verified', 'virus-free', 'compliant'];

const RUN = {
  windows: [
    'HOW TO RUN (Windows 10 or 11, 64-bit)',
    '  1. Unzip the whole folder (right-click the zip, Extract All). Do not run the game from inside the zip.',
    '  2. Double-click orb-combat-ex.exe.',
    '  The file is not code-signed with a publisher certificate. Windows may show "Windows protected your PC" (SmartScreen):',
    `  choose "More info", then "Run anyway". ${WINDOWS_WARN}`,
  ],
  linux: [
    'HOW TO RUN (Linux, x86_64, with a desktop and OpenGL 3.3 or newer)',
    '  1. Unpack it:  tar -xzf orb-combat-ex-linux-x86_64.tar.gz',
    '  2. Run it:     cd orb-combat-ex-linux-x86_64 && ./orb-combat-ex.x86_64',
    '  The tar keeps the executable bit. If a file manager or a copy dropped it, run:  chmod +x orb-combat-ex.x86_64',
    '  On a Steam Deck, add it to Steam as a non-Steam game, or run it from Desktop Mode.',
  ],
  macos: [
    'HOW TO RUN (macOS 11 or newer, Apple silicon or Intel)',
    '  This app is not signed with an Apple developer certificate and is not notarized, so macOS blocks it the first time. It has an ad-hoc',
    '  signature only, which lets it run on Apple silicon once you allow it. To allow it:',
    '  1. Unzip it and drag "Orb Combat EX.app" to your Applications folder (or anywhere you like).',
    '  2. Try to open it. macOS says it cannot be opened, or that Apple cannot check it for malware. Click Done (not Move to Trash).',
    '  3. Open System Settings > Privacy & Security, scroll to the Security section, find the message about "Orb Combat EX", and click "Open Anyway". Enter your password.',
    '     (On macOS 14 and earlier you can instead Control-click the app, choose Open, then Open.)',
    `  4. ${XATTR_LEAD}  xattr -dr com.apple.quarantine "/Applications/Orb Combat EX.app"`,
    '  You only do this once per download. If you do not trust the file, do not run it: the commit it was built from is named at the top of this file.',
  ],
};
const PLATFORM_LABEL = { windows: 'Windows x86_64', linux: 'Linux x86_64', macos: 'macOS (universal: Apple silicon and Intel)' };

/** README.txt for a platform. `info` is build_info.json ({commit, date}). Pure. */
export function readmeText(platform, notice, info) {
  if (!PLATFORMS.includes(platform)) throw new Error(`platform "${platform}" is not one of ${PLATFORMS.join(', ')}`);
  const g = notice.gate;
  const lines = [
    `${notice.title || 'Orb Combat EX (working title)'}`,
    `Development build for ${PLATFORM_LABEL[platform]}`,
    `Commit ${info.commit}, ${info.date}`,
    '',
    g.heading.toUpperCase(),
    ...g.blocks.map((b) => b.p).filter(Boolean),
    ...(g.under ? [g.under] : []),
    '',
    'HOW THIS GAME WAS MADE',
    g.ai,
    '',
    'PRIVACY',
    PRIVACY,
    '',
    ...RUN[platform],
    '',
    'LICENSES',
    '  NOTICES.txt in this folder holds the license and copyright text of the Godot Engine this game runs on, the font it ships and the engine\'s other components.',
    '',
  ];
  return lines.join('\n');
}

/** NOTICES.txt from tools/site-licences.json (the structure build-site.mjs's About page reads). Pure. */
export function noticesText(lic) {
  if (!lic || !lic.license_text || !lic.licenses) throw new Error('tools/site-licences.json has no license_text or licenses (run tools/site_licences.gd)');
  const out = [];
  out.push('GODOT ENGINE', `This game runs on the Godot Engine ${lic.godot_version} (godotengine.org), under its MIT License:`, '', lic.license_text, '');
  const fonts = (lic.copyright || []).filter((x) => /open sans/i.test(x.name));
  out.push('OPEN SANS');
  for (const c of fonts) for (const p of c.parts) out.push(`${c.name}: copyright ${(p.copyright || []).join('; ')}. Licensed under the SIL Open Font License, Version 1.1 (OFL-1.1):`);
  if (lic.licenses['OFL-1.1']) out.push('', lic.licenses['OFL-1.1']);
  out.push('', 'OTHER COMPONENTS IN THE ENGINE', 'The components the Godot Engine itself lists, with their copyright holders and licenses. The license texts follow.', '');
  for (const c of lic.copyright || []) {
    if (/^godot engine$/i.test(c.name)) continue;
    for (const p of c.parts) out.push(`- ${c.name}: ${(p.copyright || []).join('; ')} (${p.license || ''})`);
  }
  for (const name of Object.keys(lic.licenses).sort()) {
    if (name === 'OFL-1.1') continue;
    out.push('', `==== ${name} ====`, lic.licenses[name]);
  }
  out.push('');
  return out.join('\n');
}

/** Whether `lock` and `astc` may edit `root`: an error message, or null. A git checkout (a `.git` in it, a folder or a worktree's file) only on a CI checkout; an export without .git (git archive HEAD, a copy of it, even one run
 *  with its own copy of this script) is a scratch tree anywhere. The test is the tree it is given, not where this script lives. */
export function lockGuard(root, env = process.env) {
  return existsSync(join(resolve(root), '.git')) && env.GITHUB_ACTIONS !== 'true' ? `refusing to edit ${resolve(root)}: it has a .git, so it is a working checkout, and these commands edit the tree they are given (outside CI, pass an export without .git, such as git archive HEAD, as --root)` : null;
}

/** Sets lock_reduce_flashing true in <root>/ui/data/features.json. Returns true when it changed the file, false when it was already true. */
export function lockReduceFlashing(root) {
  const ff = join(root, 'ui', 'data', 'features.json');
  const txt = readFileSync(ff, 'utf8');
  if (!/"lock_reduce_flashing"\s*:/.test(txt)) throw new Error(`${ff} has no lock_reduce_flashing: this commit is older than UI's rf-lock`);
  if (LOCK_ON.test(txt)) return false;
  writeFileSync(ff, txt.replace(/"lock_reduce_flashing"\s*:\s*false/, '"lock_reduce_flashing": true'));
  return true;
}

// ---- the routes check (Legal RL-203 condition 3 and RL-204 condition 1): what a desktop build has no hostname test to rely on -------------------------------------------------------------------
/** The six words that start a run with no flashing notice (ui/hud/ui_hud.gd BYPASS_WORDS), as reviewed. A seventh is a new rule. They are honoured off the web on purpose (a bench, a scripted shot); none writes the lock. */
export const SIX_WORDS = ['bench', 'frames', 'shot', 'nonotice', 'flashcap', 'study'];
// what could lift the lock or the reduced register: a write of the lock flag, of the debug key, of the option to anything, or of the register
const LIFT = /"lock_reduce_flashing"|flash_legacy\s*=(?!=)|set_option\(\s*"reduce_flashing"|settings_set\(\s*"reduce_flashing"|\[\s*"reduce_flashing"\s*\]\s*=(?!=)|\b(reduced_flashing|force_reduced|flash_calm)\s*=(?!=)/;
const ARG_READS = /\b(args\.has\(|args\[|args\.get\(|OS\.get_cmdline|get_cmdline_user_args|notice_args_text|arg_names)/;
const NET_TOKENS = /\b(HTTPRequest|HTTPClient|ENet[A-Za-z]*|PacketPeer[A-Za-z]*|UDPServer|TCPServer|StreamPeer(TCP|TLS)|WebSocket[A-Za-z]*|WebRTC[A-Za-z]*|MultiplayerAPI|MultiplayerPeer|Net(Session|Host|Transport|Bot|Delay|Desync|Handshake|Loopback|Snapshot|Spectator|TimeSync|AiDriver|LinkTransport|EnetTransport))\b|res:\/\/net\b/;

/** The presets of an export_presets.cfg text as { name, exclude: [globs] }. */
export function presetsOf(text) {
  const out = [];
  let cur = null;
  for (const line of text.split(String.fromCharCode(10))) {
    const sec = /^\[preset\.(\d+)\]\s*$/.exec(line);
    if (sec) { cur = { name: '', exclude: [] }; out.push(cur); continue; }
    if (/^\[/.test(line)) { cur = null; continue; }
    if (!cur) continue;
    const n = /^name="(.*)"\s*$/.exec(line);
    if (n) cur.name = n[1];
    const x = /^exclude_filter="(.*)"\s*$/.exec(line);
    if (x) cur.exclude = x[1].split(',').map((s) => s.trim()).filter(Boolean);
  }
  return out;
}

const globToRegex = (g) => new RegExp('^' + g.replace(/[.+^${}()|[\]\\]/g, String.fromCharCode(92) + '$&').replace(/\*/g, '.*'));

/** Problems that would make a desktop test build refuse to run (an array of strings; empty when every check holds). `o.files` overrides file texts by relative path (a test). */
export function routeProblems(root, o = {}) {
  const out = [];
  const read = (rel) => (o.files && rel in o.files ? o.files[rel] : (existsSync(join(root, rel)) ? readFileSync(join(root, rel), 'utf8') : null));
  // 1. the standing route scan (tools/site-routes.mjs, Legal's RL-195 condition (b) and RL-196): no flag, option, register, debug key, capture hook or word lifts the lock
  for (const m of scanRoutes(root)) out.push(`route scan: ${m}`);
  // 2. the lock is on and the capture hook is off in the tree being exported (RL-196's build-time fix)
  let feat = null;
  try { feat = JSON.parse(read('ui/data/features.json')).features; } catch { out.push('ui/data/features.json could not be read'); }
  if (feat) {
    if (feat.lock_reduce_flashing !== true) out.push('ui/data/features.json lock_reduce_flashing is not true: the desktop build must be locked (run `node tools/desktop-package.mjs lock` first; RL-203)');
    if (feat.capture_hook !== false) out.push('ui/data/features.json capture_hook is not false: the build-time capture hook must be off in a build players get (RL-196, RL-203)');
  }
  // 3. the six words
  const hud = read('ui/hud/ui_hud.gd');
  const words = hud ? /^const BYPASS_WORDS: Array = \[([^\]]*)\]/m.exec(hud) : null;
  const got = words ? [...words[1].matchAll(/"([^"]+)"/g)].map((x) => x[1]) : null;
  if (!got) out.push('ui/hud/ui_hud.gd: BYPASS_WORDS could not be read (the six words that start a run with no notice are not where the check looks for them)');
  else if (got.join(',') !== SIX_WORDS.join(',')) out.push(`ui/hud/ui_hud.gd BYPASS_WORDS is [${got.join(', ')}], the reviewed six are [${SIX_WORDS.join(', ')}]: a changed word is a new review (RL-203)`);
  // 4. the capture hook can never attach off the web, and the six words and every other argument reach no write of the lock, the option, the register or the debug key:
  //    the only statement that reads an argument and also names a flash word is the hook's own guarded line
  const files = packedScripts(root, o);
  for (const rel of files) {
    const text = read(rel);
    if (text === null) continue;
    const lines = text.split(String.fromCharCode(10));
    for (let i = 0; i < lines.length; i++) {
      if (!ARG_READS.test(lines[i]) || /^\s*#/.test(lines[i])) continue;
      const ind = /^\t*/.exec(lines[i])[0].length;
      let block = lines[i];
      if (/:\s*(#.*)?$/.test(lines[i])) for (let j = i + 1; j < lines.length; j++) { const l = lines[j]; if (l.trim() === '') continue; if (/^\t*/.exec(l)[0].length <= ind) break; block += String.fromCharCode(10) + l; }
      if (!LIFT.test(block)) continue;
      out.push(`${rel}:${i + 1} reads a command-line or page argument in a statement whose block writes the lock, the option, the register or a debug key (${lines[i].trim().slice(0, 70)}): a flag could reach normal mode`);
    }
  }
  //    and no packed script (a demo or a test scene a player could name on the command line) switches the lock off
  for (const rel of files) {
    const text = read(rel);
    if (text === null) continue;
    text.split(String.fromCharCode(10)).forEach((l, i) => { if (/set_feature\(\s*"lock_reduce_flashing"\s*,\s*(false|null)/.test(l)) out.push(`${rel}:${i + 1} switches the lock off (${l.trim().slice(0, 70)}) in a script that is packed`); });
  }
  // 5. no network, no online play in what is packed (RL-204 condition 1): no network class in any packed script, nothing from res://net, net/ excluded from every desktop preset
  for (const rel of files) { const t = read(rel); if (t === null) continue; t.split(String.fromCharCode(10)).forEach((l, i) => { if (!/^\s*#/.test(l) && NET_TOKENS.test(l)) out.push(`${rel}:${i + 1} names a network class or res://net (${l.trim().slice(0, 60)}): the privacy line says the game makes no network connection`); }); }
  const proj = read('project.godot');
  if (proj && /res:\/\/net\b/.test(proj)) out.push('project.godot names res://net (an autoload or a setting): online play would be loaded at start');
  const presets = presetsOf(o.presets ?? read('export_presets.cfg') ?? '');
  for (const name of ['Windows Desktop', 'Linux', 'macOS']) {
    const p = presets.find((x) => x.name === name);
    if (!p) out.push(`export_presets.cfg has no "${name}" preset`);
    else if (!p.exclude.includes('net/*')) out.push(`export_presets.cfg: the "${name}" preset does not exclude net/* (online play stays out of the package: RL-204 condition 1)`);
  }
  return out;
}

/** The scripts a desktop preset packs: every .gd under the root except the preset's own exclude globs and net/ (checked apart). */
function packedScripts(root, o = {}) {
  const presets = presetsOf(o.presets ?? (existsSync(join(root, 'export_presets.cfg')) ? readFileSync(join(root, 'export_presets.cfg'), 'utf8') : ''));
  const globs = [...(presets.find((x) => x.name === 'Windows Desktop')?.exclude ?? []), '.godot/*', '.git/*', 'net/*'];
  const rx = globs.map(globToRegex);
  const files = [];
  const walkDir = (d) => {
    for (const e of readdirSync(join(root, d), { withFileTypes: true })) {
      const rel = d ? `${d}/${e.name}` : e.name;
      if (rx.some((r) => r.test(rel + (e.isDirectory() ? '/' : '')))) continue;
      if (e.isDirectory()) walkDir(rel); else if (e.name.endsWith('.gd')) files.push(rel);
    }
  };
  walkDir('');
  return files;
}

const ASTC_KEY = 'textures/vram_compression/import_etc2_astc';
/** Sets textures/vram_compression/import_etc2_astc=true under [rendering] in <root>/project.godot: Godot refuses a universal or arm64 macOS export without it. The game imports no textures, so
 *  nothing else changes. Done to the CI checkout only, so project.godot in the repository (a flash-set trigger, RL-128) stays as it is. Returns true when it changed the file. */
export function enableAstcImport(root) {
  const f = join(root, 'project.godot');
  const txt = readFileSync(f, 'utf8');
  if (new RegExp(`^${ASTC_KEY}\\s*=\\s*true\\s*$`, 'm').test(txt)) return false;
  const nl = txt.includes('\r\n') ? '\r\n' : '\n';
  const line = `${ASTC_KEY}=true`;
  const existing = new RegExp(`^${ASTC_KEY}\\s*=.*$`, 'm');
  if (existing.test(txt)) { writeFileSync(f, txt.replace(existing, line)); return true; }
  const head = /^\[rendering\][ \t]*$/m.exec(txt);
  if (!head) { writeFileSync(f, txt.replace(/\s*$/, '') + `${nl}${nl}[rendering]${nl}${nl}${line}${nl}`); return true; }
  const at = head.index + head[0].length;
  writeFileSync(f, txt.slice(0, at) + nl + line + txt.slice(at));
  return true;
}

const walk = (dir, base = dir, out = []) => { for (const e of readdirSync(dir, { withFileTypes: true })) { const p = join(dir, e.name); if (e.isDirectory()) walk(p, base, out); else out.push(p.slice(base.length + 1).split(sep).join('/')); } return out; };
const head = (file, n) => { const b = readFileSync(file); return b.subarray(0, n); };
const tail = (file, n) => { const b = readFileSync(file); return b.subarray(Math.max(0, b.length - n)); };

/** Problems with an unpacked package folder (an array; empty when it holds). `o.commit` demands that commit; `o.locked` true/false demands the lock state; undefined does not check it. */
export function verifyDir(platform, dir, o = {}) {
  const out = [];
  if (!PLATFORMS.includes(platform)) return [`platform "${platform}" is not one of ${PLATFORMS.join(', ')}`];
  if (!existsSync(dir)) return [`${dir} does not exist`];
  const files = walk(dir);
  const has = (f) => files.includes(f);
  for (const f of ['README.txt', 'NOTICES.txt', 'build_info.json']) if (!has(f)) out.push(`${f} is missing from the package`);
  let info = null;
  if (has('build_info.json')) {
    try { info = JSON.parse(readFileSync(join(dir, 'build_info.json'), 'utf8')); } catch { out.push('build_info.json is not valid JSON'); }
    if (info && !/^[0-9a-f]{7}$/.test(String(info.commit))) out.push(`build_info.json holds commit "${info.commit}", not a 7-digit commit`);
    if (info && !/^\d{4}-\d{2}-\d{2}$/.test(String(info.date))) out.push(`build_info.json holds date "${info.date}", not a date`);
    if (info && o.commit && !String(o.commit).toLowerCase().startsWith(String(info.commit))) out.push(`build_info.json names commit ${info.commit}, the build is of ${o.commit}`);
  }
  let notice = null;
  try { notice = activeNotice(); } catch (e) { out.push(e.message); }
  if (has('README.txt') && notice) {
    const r = readFileSync(join(dir, 'README.txt'), 'utf8');
    if (!r.includes(notice.gate.ai)) out.push('README.txt does not carry the AI line word for word');
    if (!notice.gate.blocks.every((b) => !b.p || r.includes(b.p))) out.push('README.txt does not carry the flashing notice word for word');
    if (info && !r.includes(`Commit ${info.commit}`)) out.push('README.txt does not name the commit of build_info.json');
    // Legal's RL-204 words, word for word, and the one sentence that must be gone
    const NL = String.fromCharCode(10);
    if (!r.includes(`PRIVACY${NL}${PRIVACY}${NL}`) || r.indexOf(`PRIVACY${NL}`) < r.indexOf('HOW THIS GAME WAS MADE')) out.push("README.txt does not carry Legal's PRIVACY section word for word after HOW THIS GAME WAS MADE (RL-204)");
    if (platform === 'windows' && !r.includes(WINDOWS_WARN)) out.push("README.txt does not carry Legal's Windows warning sentences word for word (RL-204)");
    if (/exactly what the project built/i.test(r)) out.push('README.txt still says "exactly what the project built", an assurance Legal removed (RL-204)');
    if (platform === 'macos' && !r.includes(XATTR_LEAD)) out.push(`README.txt does not carry Legal's lead-in to the xattr step: "${XATTR_LEAD}" (RL-204)`);
    if (!r.includes(`${NL}LICENSES${NL}`) || /LICENCES|licence/i.test(r)) out.push('README.txt spells license the British way: the heading is LICENSES and the text "license" (RL-204, public strings are American)');
    const bad = NO_ASSURANCE.filter((w) => new RegExp(`(^|[^A-Za-z-])${w}($|[^A-Za-z-])`, 'i').test(r));
    if (bad.length) out.push(`README.txt uses ${bad.map((w) => '"' + w + '"').join(', ')}: no assurance word may appear in the package (RL-204)`);
  }
  if (has('NOTICES.txt')) {
    const n = readFileSync(join(dir, 'NOTICES.txt'), 'utf8');
    if (!/Godot Engine/.test(n) || !/MIT License/.test(n) || !/Juan Linietsky/.test(n)) out.push('NOTICES.txt does not carry the Godot Engine licence and copyright');
    if (!/SIL Open Font License/.test(n)) out.push('NOTICES.txt does not carry the Open Sans licence');
    // the assurance words are scanned in the text we wrote around the licences; the licence texts themselves are other people's and stay as published (the MPL says "compliant" once)
    let own = n;
    try {
      const lic = JSON.parse(readFileSync(join(HERE, 'site-licences.json'), 'utf8'));
      for (const body of [lic.license_text, ...Object.values(lic.licenses || {})]) if (typeof body === 'string' && body) own = own.split(body).join('');
    } catch { /* the framing check below then runs on the whole file */ }
    const badN = NO_ASSURANCE.filter((w) => new RegExp(`(^|[^A-Za-z-])${w}($|[^A-Za-z-])`, 'i').test(own));
    if (badN.length) out.push(`NOTICES.txt uses ${badN.map((w) => '"' + w + '"').join(', ')} outside the licence texts (RL-204)`);
  }
  // the game: where it is, its magic, and the pck
  let lockHolder = null;
  if (platform === 'windows' || platform === 'linux') {
    const f = NAMES[platform];
    if (!has(f)) out.push(`${f} is missing from the package`);
    else {
      const p = join(dir, f), size = statSync(p).size;
      const magic = head(p, 4);
      if (platform === 'windows' && !(magic[0] === 0x4d && magic[1] === 0x5a)) out.push(`${f} does not start with the PE signature "MZ"`);
      if (platform === 'linux' && !(magic[0] === 0x7f && magic.toString('latin1', 1, 4) === 'ELF')) out.push(`${f} does not start with the ELF signature`);
      if (tail(p, 4).toString('latin1') !== 'GDPC') out.push(`${f} does not end with the embedded pck's GDPC footer: the game's data is not inside it`);
      if (size < (o.minBytes ?? 40e6)) out.push(`${f} is only ${size} bytes: smaller than any template plus the game`);
      if (platform === 'linux' && (statSync(p).mode & 0o111) === 0 && process.platform !== 'win32') out.push(`${f} has no executable bit in the unpacked folder`);
      lockHolder = p;
    }
  } else {
    const app = NAMES.macos, base = `${app}/Contents`;
    for (const f of [`${base}/Info.plist`, `${base}/MacOS/Orb Combat EX`, `${base}/Resources/Orb Combat EX.pck`]) if (!has(f)) out.push(`${f} is missing from the package`);
    if (!files.some((f) => f.startsWith(`${base}/_CodeSignature/`))) out.push('the app has no _CodeSignature (an Apple silicon Mac will not run an unsigned binary at all; the ad-hoc signature is what lets "Open Anyway" work)');
    if (has(`${base}/MacOS/Orb Combat EX`)) {
      const p = join(dir, `${base}/MacOS/Orb Combat EX`), m = head(p, 8);
      const fat = m.readUInt32BE(0) === 0xcafebabe;
      if (!fat || m.readUInt32BE(4) < 2) out.push('the executable is not a universal (fat) Mach-O with both an Intel and an Apple silicon slice');
      if ((statSync(p).mode & 0o111) === 0 && process.platform !== 'win32') out.push('the app executable has no executable bit in the unpacked folder');
    }
    if (has(`${base}/Resources/Orb Combat EX.pck`)) {
      const p = join(dir, `${base}/Resources/Orb Combat EX.pck`);
      if (head(p, 4).toString('latin1') !== 'GDPC') out.push('the app\'s pck does not start with GDPC');
      lockHolder = p;
    }
    if (has(`${base}/Info.plist`)) {
      const plist = readFileSync(join(dir, `${base}/Info.plist`), 'utf8');
      if (!/CFBundleIdentifier<\/key>\s*<string>[A-Za-z0-9.-]+<\/string>/.test(plist)) out.push('Info.plist has no bundle identifier');
      if (!/<key>LSMinimumSystemVersionByArchitecture/.test(plist)) out.push('Info.plist has no minimum macOS version per architecture');
    }
  }
  if (lockHolder) {
    const b = readFileSync(lockHolder).toString('latin1');
    // the privacy line is true only while the build makes no network connection (RL-204 condition 1): no net/ script is in the package, so no host, join or spectate path exists in it
    if (!/res:[/][/](ui|render|sim)[/]/.test(b)) out.push("the package's file list could not be read (no res://ui, render or sim path in it), so the check that no online-play script is packed proves nothing");
    else if (b.includes('res://net/')) out.push('the package carries scripts from res://net/ (online play): the privacy line says the game makes no network connection, so net/ must stay out of the export (exclude_filter "net/*")');
    // RL-196's build-time fix: the capture hook is a feature of the measurement export only
    if (/"capture_hook"\s*:\s*true/.test(b)) out.push('the package carries features.capture_hook true: the capture hook (and window.__flashcap) would be attachable in it (RL-196)');
  }
  if (lockHolder && o.locked !== undefined) {
    const b = readFileSync(lockHolder).toString('latin1');
    const on = LOCK_ON.test(b), off = LOCK_OFF.test(b);
    if (!on && !off) out.push('the package holds no ui/data/features.json lock_reduce_flashing: cannot tell whether Reduce flashing is locked');
    else if (o.locked && !on) out.push('Reduce flashing is NOT locked on in this package (features.json says lock_reduce_flashing false), but the notice in README.txt says it cannot be turned off');
    else if (!o.locked && !off) out.push('Reduce flashing is locked in this package, expected unlocked');
  }
  return out;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const cmd = args[0];
  const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
  const usage = () => { console.error('usage: node tools/desktop-package.mjs text --platform <windows|linux|macos> --out <dir> [--build-info <file>]  |  lock --root <tree>  |  astc --root <tree>  |  routes --root <tree>  |  verify --platform <p> --dir <dir> [--commit <sha>] [--locked|--unlocked]'); process.exit(2); };
  const platform = opt('--platform');
  try {
    if (cmd === 'text') {
      if (!PLATFORMS.includes(platform) || !opt('--out')) usage();
      const out = resolve(opt('--out'));
      const infoFile = opt('--build-info') ? resolve(opt('--build-info')) : join(REPO, 'build_info.json');
      let info;
      try { info = JSON.parse(readFileSync(infoFile, 'utf8')); } catch (e) { throw new Error(`${infoFile} could not be read (node tools/write-build-info.mjs first): ${e.message}`); }
      const lic = JSON.parse(readFileSync(join(HERE, 'site-licences.json'), 'utf8'));
      mkdirSync(out, { recursive: true });
      writeFileSync(join(out, 'README.txt'), readmeText(platform, activeNotice(), info));
      writeFileSync(join(out, 'NOTICES.txt'), noticesText(lic));
      writeFileSync(join(out, 'build_info.json'), JSON.stringify(info) + '\n');
      console.log(`desktop package: README.txt, NOTICES.txt and build_info.json (${info.commit}, ${info.date}) written to ${out} for ${platform}`);
    } else if (cmd === 'routes') {
      const root = opt('--root') ? resolve(opt('--root')) : null;
      if (!root) usage();
      const problems = routeProblems(root);
      if (problems.length) { for (const p of problems) console.error(`desktop routes check FAILED: ${p}`); process.exit(1); }
      console.log('desktop routes check ok: the route scan is clean; the lock is true and the capture hook false in features.json; the six bypass words are the reviewed ones and reach no write of the lock; no command-line or page argument reaches the option, the register or a debug key; no network class is packed and net/ is excluded from the three desktop presets.');
    } else if (cmd === 'astc') {
      const root = opt('--root') ? resolve(opt('--root')) : null;
      if (!root) usage();
      const refused = lockGuard(root);
      if (refused) throw new Error(refused.replace('ui/data/features.json', 'project.godot'));
      console.log(enableAstcImport(root) ? `${ASTC_KEY}=true set in ${root}/project.godot` : 'ETC2/ASTC import was already on');
    } else if (cmd === 'lock') {
      const root = opt('--root') ? resolve(opt('--root')) : null;
      if (!root) usage();
      const refused = lockGuard(root);
      if (refused) throw new Error(refused);
      console.log(lockReduceFlashing(root) ? `lock_reduce_flashing set true in ${root}/ui/data/features.json` : 'lock_reduce_flashing was already true');
    } else if (cmd === 'verify') {
      if (!PLATFORMS.includes(platform) || !opt('--dir')) usage();
      const problems = verifyDir(platform, resolve(opt('--dir')), { commit: opt('--commit'), locked: args.includes('--locked') ? true : args.includes('--unlocked') ? false : undefined });
      if (problems.length) { for (const p of problems) console.error(`desktop package FAILED (${platform}): ${p}`); process.exit(1); }
      console.log(`desktop package ok (${platform}): the files, the executable's magic bytes, the embedded pck, build_info.json, README.txt and NOTICES.txt hold.${platform === 'linux' ? '' : ` This was read, not run: a ${platform === 'windows' ? 'Windows' : 'macOS'} build cannot be started on this machine.`}`);
    } else usage();
  } catch (e) {
    console.error(`desktop package: ${e.message}`);
    process.exit(1);
  }
}
