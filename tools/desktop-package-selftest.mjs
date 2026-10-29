// Self-test of tools/desktop-package.mjs: the README and NOTICES text, the Reduce flashing lock edit and its guard, and the package check, on small synthetic packages (a real Windows, Linux or macOS
// build is 80 to 170 MB; the check takes its size floor as an option here). No Godot, no network. CI runs it.
//   node tools/desktop-package-selftest.mjs
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync, chmodSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { activeNotice, readmeText, noticesText, lockReduceFlashing, lockGuard, enableAstcImport, verifyDir, routeProblems, presetsOf, NAMES, SIX_WORDS, WINDOWS_WARN, XATTR_LEAD, PRIVACY, NO_ASSURANCE } from './desktop-package.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const here = import.meta.dirname;
const lic = JSON.parse(readFileSync(join(here, 'site-licences.json'), 'utf8'));
const notice = activeNotice();
const info = { commit: 'abc1234', date: '2026-10-28' };
const tmp = mkdtempSync(join(tmpdir(), 'desktop-pkg-'));
const MIN = { minBytes: 64 };

try {
  // the words
  check('the active notice is usable (not a draft; flashing notice and AI line present)', !!notice.gate.ai && notice.gate.blocks.length > 0);
  for (const p of ['windows', 'linux', 'macos']) {
    const r = readmeText(p, notice, info);
    check(`${p}: README.txt carries the AI line, every flashing paragraph, the under line and the commit`, r.includes(notice.gate.ai) && notice.gate.blocks.every((b) => !b.p || r.includes(b.p)) && (!notice.gate.under || r.includes(notice.gate.under)) && r.includes('Commit abc1234, 2026-10-28'));
    check(`${p}: README.txt says how to run it and points to NOTICES.txt`, /HOW TO RUN/.test(r) && /NOTICES\.txt/.test(r));
  }
  check('windows: README.txt names the SmartScreen warning and how to get past it', /SmartScreen/.test(readmeText('windows', notice, info)) && /Run anyway/.test(readmeText('windows', notice, info)));
  check('macos: README.txt gives the unsigned-app steps (Open Anyway, the Control-click way, xattr) and says it is not notarized', (() => { const r = readmeText('macos', notice, info); return /Open Anyway/.test(r) && /Control-click/.test(r) && /xattr -dr com\.apple\.quarantine/.test(r) && /not notarized/.test(r) && /ad-hoc/.test(r); })());
  check('linux: README.txt gives the tar line and the chmod fallback', (() => { const r = readmeText('linux', notice, info); return /tar -xzf/.test(r) && /chmod \+x/.test(r); })());
  check('an unknown platform is refused', (() => { try { readmeText('beos', notice, info); return false; } catch { return true; } })());
  check('no README line promises a thing the build does not do (nothing about signing certificates costing money, no "coming soon")', ['windows', 'linux', 'macos'].every((p) => !/costs money|coming soon|will be fixed/i.test(readmeText(p, notice, info))));
  const n = noticesText(lic);
  check('NOTICES.txt carries the Godot licence and copyright, the Open Sans licence and the other components\' licence texts', /Juan Linietsky/.test(n) && /MIT License/.test(n) && /SIL Open Font License/.test(n) && n.includes(lic.licenses['BSD-3-clause'] || '') && n.length > 50000, `${n.length} bytes`);
  check('NOTICES.txt without licence data is refused', (() => { try { noticesText({}); return false; } catch { return true; } })());
  // a draft notice is refused
  {
    const t = join(tmp, 'tools'); mkdirSync(t, { recursive: true });
    writeFileSync(join(t, 'site.json'), JSON.stringify({ interim: { notice: 'n.json' } }));
    writeFileSync(join(t, 'n.json'), JSON.stringify({ draft: true, gate: { heading: 'h', blocks: [{ p: 'x' }], ai: 'a' } }));
    check('a draft notice is refused', (() => { try { activeNotice(t); return false; } catch (e) { return /draft/.test(e.message); } })());
    writeFileSync(join(t, 'n.json'), JSON.stringify({ draft: false, gate: { heading: 'h', blocks: [], ai: '' } }));
    check('a notice with no flashing paragraph or no AI line is refused', (() => { try { activeNotice(t); return false; } catch (e) { return /no flashing notice/.test(e.message); } })());
    writeFileSync(join(t, 'n.json'), JSON.stringify({ draft: false, gate: { heading: 'h', blocks: [{ p: 'x' }], ai: 'a' } }));
    check('the notice file named by tools/site.json is the one read', activeNotice(t).gate.ai === 'a');
  }

  // the lock edit
  {
    const root = join(tmp, 'tree'); mkdirSync(join(root, 'ui', 'data'), { recursive: true });
    const f = join(root, 'ui', 'data', 'features.json');
    writeFileSync(f, '{\n  "lock_reduce_flashing": false,\n  "capture_hook": false\n}\n');
    check('lock: sets lock_reduce_flashing true and nothing else', lockReduceFlashing(root) === true && readFileSync(f, 'utf8') === '{\n  "lock_reduce_flashing": true,\n  "capture_hook": false\n}\n');
    check('lock: a second run changes nothing', lockReduceFlashing(root) === false);
    writeFileSync(f, '{ "capture_hook": false }');
    check('lock: a tree with no lock_reduce_flashing is refused', (() => { try { lockReduceFlashing(root); return false; } catch (e) { return /no lock_reduce_flashing/.test(e.message); } })());
    // the guard looks at the tree it is given: a .git means a working checkout; an export without .git is scratch, wherever this script is run from
    const NLg = String.fromCharCode(10);
    const mkTree = (withGit) => { const d = mkdtempSync(join(tmp, 'tree-')); mkdirSync(join(d, 'ui', 'data'), { recursive: true }); writeFileSync(join(d, 'ui', 'data', 'features.json'), '{"features": {"lock_reduce_flashing": false}}' + NLg); writeFileSync(join(d, 'project.godot'), '[rendering]' + NLg + 'renderer/x=1' + NLg); if (withGit) mkdirSync(join(d, '.git')); return d; };
    const gitTree = mkTree(true), plain = mkTree(false);
    check('guard: a tree with a .git is refused outside CI and allowed on a CI checkout; a tree without one is allowed anywhere', lockGuard(gitTree, {}) !== null && lockGuard(gitTree, { GITHUB_ACTIONS: 'true' }) === null && lockGuard(plain, {}) === null && lockGuard(plain, { GITHUB_ACTIONS: 'true' }) === null);
    check('guard: a linked worktree .git (a file, not a folder) counts as a checkout too', (() => { const d = mkTree(false); writeFileSync(join(d, '.git'), 'gitdir: /elsewhere'); return lockGuard(d, {}) !== null; })());
    const env = { ...process.env }; delete env.GITHUB_ACTIONS;
    const feat = (d) => readFileSync(join(d, 'ui', 'data', 'features.json'), 'utf8');
    const before = feat(gitTree);
    const r = spawnSync(process.execPath, [join(here, 'desktop-package.mjs'), 'lock', '--root', gitTree], { encoding: 'utf8', env });
    check('lock: the command refuses a checkout with a .git outside CI and leaves its features.json as it was', r.status === 1 && /refusing/.test(r.stderr) && feat(gitTree) === before, r.stderr);
    const ok = spawnSync(process.execPath, [join(here, 'desktop-package.mjs'), 'lock', '--root', plain], { encoding: 'utf8', env });
    check('lock: the command locks an export without .git', ok.status === 0 && /"lock_reduce_flashing": true/.test(feat(plain)), ok.stderr);
    // the EP's case: an export that runs its OWN copy of the script on itself (its tools folder is in it)
    const own = mkTree(false); mkdirSync(join(own, 'tools'), { recursive: true });
    for (const n of ['desktop-package.mjs', 'site-routes.mjs']) writeFileSync(join(own, 'tools', n), readFileSync(join(here, n)));
    const self = spawnSync(process.execPath, [join(own, 'tools', 'desktop-package.mjs'), 'lock', '--root', own], { encoding: 'utf8', env });
    check('lock: an export running its own copy of the script on itself is a scratch tree, not refused', self.status === 0 && /"lock_reduce_flashing": true/.test(feat(own)), self.stderr);
  }

  // the ETC2/ASTC import setting (a universal macOS export needs it; set on the CI checkout, never in the repository's project.godot)
  {
    const LF = String.fromCharCode(10), CR = String.fromCharCode(13), K = 'textures/vram_compression/import_etc2_astc';
    const lines = (...l) => l.join(LF) + LF;
    const root = join(tmp, 'proj'); mkdirSync(root, { recursive: true });
    const f = join(root, 'project.godot');
    writeFileSync(f, lines('[application]', '', 'config/name="X"', '', '[rendering]', '', 'renderer/rendering_method="gl_compatibility"'));
    check('astc: the key is added under [rendering] and nothing else changes', enableAstcImport(root) === true && readFileSync(f, 'utf8') === lines('[application]', '', 'config/name="X"', '', '[rendering]', `${K}=true`, '', 'renderer/rendering_method="gl_compatibility"'));
    check('astc: a second run changes nothing', enableAstcImport(root) === false);
    writeFileSync(f, lines('[rendering]', `${K}=false`, 'renderer/x=1'));
    check('astc: a key set to false is turned on, in place', enableAstcImport(root) === true && readFileSync(f, 'utf8') === lines('[rendering]', `${K}=true`, 'renderer/x=1'));
    const crlf = (...l) => l.join(CR + LF) + CR + LF;
    writeFileSync(f, crlf('[application]', '', 'config/name="X"'));
    check('astc: a file with no [rendering] section gets one, with the file\'s own line endings', enableAstcImport(root) === true && readFileSync(f, 'utf8') === crlf('[application]', '', 'config/name="X"', '', '[rendering]', '', `${K}=true`));
    // the repository's own project.godot, copied: exactly one line is added
    const real = readFileSync(join(here, '..', 'project.godot'), 'utf8');
    writeFileSync(f, real);
    enableAstcImport(root);
    const split = (s) => s.split(LF).map((l) => l.replace(CR, ''));
    const after = split(readFileSync(f, 'utf8')), before = split(real);
    const added = after.filter((l) => !before.includes(l));
    check('astc: on the repository\'s project.godot exactly one line is added, and it is that key', added.length === 1 && added[0] === `${K}=true` && after.length === before.length + 1, JSON.stringify(added));
    const env2 = { ...process.env }; delete env2.GITHUB_ACTIONS;
    const gitProj = mkdtempSync(join(tmp, 'proj-git-')); mkdirSync(join(gitProj, '.git')); writeFileSync(join(gitProj, 'project.godot'), real);
    const r = spawnSync(process.execPath, [join(here, 'desktop-package.mjs'), 'astc', '--root', gitProj], { encoding: 'utf8', env: env2 });
    check('astc: the command refuses a checkout with a .git outside CI and leaves project.godot as it was', r.status === 1 && /refusing/.test(r.stderr) && readFileSync(join(gitProj, 'project.godot'), 'utf8') === real, r.stderr);
    const plainProj = mkdtempSync(join(tmp, 'proj-plain-')); writeFileSync(join(plainProj, 'project.godot'), real);
    const r2 = spawnSync(process.execPath, [join(here, 'desktop-package.mjs'), 'astc', '--root', plainProj], { encoding: 'utf8', env: env2 });
    check('astc: the command sets the key in an export without .git', r2.status === 0 && readFileSync(join(plainProj, 'project.godot'), 'utf8').includes(K + '=true'), r2.stderr);
  }

  // the package check, on synthetic packages
  const pad = (n) => Buffer.alloc(n, 0x20);
  // what the check reads inside the executable or pck: the file list (res:// paths), features.json's lock and capture hook; `extra` is a path or text a mutation adds
  const lockText = (on, extra = '', paths = true) => Buffer.from(`${paths ? 'res://ui/core/ui_data.gd res://render/core/main.gd ' : ''}{"lock_reduce_flashing": ${on}, "capture_hook": false} ${extra}`);
  const writeCommon = (dir, platform, over = {}) => {
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, 'README.txt'), over.readme ?? readmeText(platform, notice, info));
    writeFileSync(join(dir, 'NOTICES.txt'), over.notices ?? noticesText(lic));
    if (over.info !== null) writeFileSync(join(dir, 'build_info.json'), JSON.stringify(over.info ?? info));
  };
  const winLike = (platform, over = {}) => {
    const dir = join(tmp, `pkg-${platform}-${Math.random().toString(36).slice(2)}`);
    writeCommon(dir, platform, over);
    const magic = platform === 'windows' ? Buffer.from('MZ') : Buffer.from([0x7f, 0x45, 0x4c, 0x46]);
    const body = Buffer.concat([over.magic ?? magic, pad(20), lockText(over.lock ?? true, over.extra ?? "", over.noPaths !== true), pad(20), Buffer.from(over.footer ?? 'GDPC')]);
    if (over.noGame !== true) writeFileSync(join(dir, NAMES[platform]), body);
    if (platform === 'linux') try { chmodSync(join(dir, NAMES.linux), 0o755); } catch { /* windows */ }
    return dir;
  };
  const mac = (over = {}) => {
    const dir = join(tmp, `pkg-mac-${Math.random().toString(36).slice(2)}`);
    writeCommon(dir, 'macos', over);
    const c = join(dir, 'Orb Combat EX.app', 'Contents');
    mkdirSync(join(c, 'MacOS'), { recursive: true }); mkdirSync(join(c, 'Resources'), { recursive: true }); mkdirSync(join(c, '_CodeSignature'), { recursive: true });
    writeFileSync(join(c, 'Info.plist'), over.plist ?? '<plist><dict><key>CFBundleIdentifier</key>\n<string>io.github.example.game</string><key>LSMinimumSystemVersionByArchitecture</key></dict></plist>');
    const fat = Buffer.alloc(8); fat.writeUInt32BE(0xcafebabe, 0); fat.writeUInt32BE(over.slices ?? 2, 4);
    if (over.noExe !== true) { writeFileSync(join(c, 'MacOS', 'Orb Combat EX'), Buffer.concat([over.fat ?? fat, pad(20)])); try { chmodSync(join(c, 'MacOS', 'Orb Combat EX'), 0o755); } catch { /* windows */ } }
    if (over.noPck !== true) writeFileSync(join(c, 'Resources', 'Orb Combat EX.pck'), Buffer.concat([Buffer.from(over.pckMagic ?? 'GDPC'), pad(20), lockText(over.lock ?? true, over.extra ?? "", over.noPaths !== true)]));
    if (over.noSig !== true) writeFileSync(join(c, '_CodeSignature', 'CodeResources'), 'x');
    return dir;
  };
  const V = (platform, dir, o = {}) => verifyDir(platform, dir, { ...MIN, ...o });
  const has = (p, re) => p.some((m) => re.test(m));
  for (const p of ['windows', 'linux']) {
    check(`${p}: a whole package passes, locked`, V(p, winLike(p), { locked: true, commit: 'abc1234def' }).length === 0, JSON.stringify(V(p, winLike(p), { locked: true })));
    check(`${p}: a missing README.txt is found`, has(V(p, (() => { const d = winLike(p); rmSync(join(d, 'README.txt')); return d; })()), /README\.txt is missing/));
    check(`${p}: a missing game is found`, has(V(p, winLike(p, { noGame: true })), new RegExp(`${NAMES[p].replace('.', '\\.')} is missing`)));
    check(`${p}: wrong magic bytes are found`, has(V(p, winLike(p, { magic: Buffer.from('zz') })), /signature/));
    check(`${p}: an executable with no embedded pck footer is found`, has(V(p, winLike(p, { footer: 'XXXX' })), /GDPC footer/));
    check(`${p}: a size under the floor is found (the default floor is 40 MB)`, has(verifyDir(p, winLike(p), {}), /smaller than any template/));
    check(`${p}: build_info.json naming another commit than the build is found`, has(V(p, winLike(p), { commit: 'fffffff0' }), /names commit abc1234/));
    check(`${p}: a bad build_info.json commit is found`, has(V(p, winLike(p, { info: { commit: 'unknown', date: '2026-10-28' } })), /not a 7-digit commit/));
    check(`${p}: a README without the AI line is found`, has(V(p, winLike(p, { readme: 'Commit abc1234\nnothing else' })), /AI line/));
    check(`${p}: a README without the flashing notice is found`, has(V(p, winLike(p, { readme: `${notice.gate.ai}\nCommit abc1234` })), /flashing notice/));
    check(`${p}: NOTICES.txt without the engine licence is found`, has(V(p, winLike(p, { notices: 'nothing' })), /Godot Engine licence/));
    check(`${p}: a package built with Reduce flashing NOT locked fails the locked check (the README says it cannot be turned off)`, has(V(p, winLike(p, { lock: false }), { locked: true }), /NOT locked on/));
    check(`${p}: a locked package fails the unlocked check`, has(V(p, winLike(p, { lock: true }), { locked: false }), /locked in this package, expected unlocked/));
    check(`${p}: a package with no features.json text cannot be told locked or not, and says so`, has(V(p, (() => { const d = winLike(p); const f = join(d, NAMES[p]); writeFileSync(f, Buffer.concat([Buffer.from(p === 'windows' ? 'MZ' : [0x7f, 0x45, 0x4c, 0x46]), pad(30), Buffer.from('GDPC')])); return d; })(), { locked: true }), /cannot tell/));
    check(`${p}: with the lock state not asked for, it is not read`, V(p, winLike(p, { lock: false }), {}).length === 0);
  }
  check('macos: a whole app passes, locked', V('macos', mac(), { locked: true, commit: 'abc1234def' }).length === 0, JSON.stringify(V('macos', mac(), { locked: true })));
  check('macos: a missing executable is found', has(V('macos', mac({ noExe: true })), /MacOS\/Orb Combat EX is missing/));
  check('macos: a missing pck is found', has(V('macos', mac({ noPck: true })), /\.pck is missing/));
  check('macos: no code signature is found (Apple silicon will not run an unsigned binary)', has(V('macos', mac({ noSig: true })), /_CodeSignature/));
  check('macos: a thin (single-slice) executable is found', has(V('macos', mac({ slices: 1 })), /universal/));
  check('macos: a non-Mach-O executable is found', has(V('macos', mac({ fat: Buffer.from('MZ......') })), /universal/));
  check('macos: a pck that does not start with GDPC is found', has(V('macos', mac({ pckMagic: 'XXXX' })), /GDPC/));
  check('macos: an Info.plist with no bundle identifier is found', has(V('macos', mac({ plist: '<plist/>' })), /bundle identifier/));
  check('macos: a package with Reduce flashing not locked fails the locked check', has(V('macos', mac({ lock: false }), { locked: true }), /NOT locked on/));
  check('a platform that does not exist, and a folder that does not exist, are errors', has(verifyDir('beos', tmp), /not one of/) && has(verifyDir('windows', join(tmp, 'nope')), /does not exist/));
  // Legal's RL-204 words and checks
  {
    const norm = (s) => s.split(/\s+/).join(' ');
    const addendum = norm(readFileSync(join(here, '..', 'docs', 'legal', 'page-fixed-lines.md'), 'utf8'));
    check('the three exact public strings are the words in Legal\'s addendum (docs/legal/page-fixed-lines.md, RL-204)', [WINDOWS_WARN, XATTR_LEAD, PRIVACY].every((s) => addendum.includes(norm(s))));
    check('the no-assurance list is the five words of the addendum', NO_ASSURANCE.join(',') === 'safe,tested,verified,virus-free,compliant' && ['safe', 'tested', 'verified', 'virus-free', 'compliant'].every((w) => addendum.includes(`"${w}"`)));
    for (const p of ['windows', 'linux', 'macos']) {
      const r = readmeText(p, notice, info);
      const NL = String.fromCharCode(10);
      check(`${p}: README.txt has Legal's PRIVACY section after HOW THIS GAME WAS MADE, the heading LICENSES, and none of the British spellings`, r.includes(`PRIVACY${NL}${PRIVACY}${NL}`) && r.indexOf('PRIVACY') > r.indexOf('HOW THIS GAME WAS MADE') && r.includes(`${NL}LICENSES${NL}`) && !/licen[c]e/i.test(r));
      check(`${p}: README.txt has none of the five assurance words`, NO_ASSURANCE.every((w) => !new RegExp(`(^|[^A-Za-z-])${w}($|[^A-Za-z-])`, 'i').test(r)));
      check(`${p}: README.txt no longer says "exactly what the project built"`, !/exactly what the project built/i.test(r));
    }
    check('windows: README.txt carries Legal\'s replacement sentences word for word', readmeText('windows', notice, info).includes(WINDOWS_WARN));
    check('macos: the xattr step opens with Legal\'s lead-in', readmeText('macos', notice, info).includes(`4. ${XATTR_LEAD}  xattr -dr`));
    check('the licence-text bodies may say "compliant" (the MPL does); the words we wrote around them may not', /compliant/i.test(noticesText(lic)) && !verifyDir('linux', winLike('linux'), MIN).some((m) => /NOTICES.txt uses/.test(m)));
    // the package check refuses a README or NOTICES that breaks them
    for (const p of ['windows', 'linux', 'macos']) {
      const mk = (readme) => (p === 'macos' ? mac({ readme }) : winLike(p, { readme }));
      const good = readmeText(p, notice, info);
      check(`${p}: a README without the PRIVACY section is found`, has(V(p, mk(good.replace(PRIVACY, 'x'))), /PRIVACY section/));
      check(`${p}: a README with "exactly what the project built" is found`, has(V(p, mk(good + 'the files are exactly what the project built')), /exactly what the project built/));
      check(`${p}: a README that says "verified" or "safe" is found`, has(V(p, mk(good + ' Verified.')), /"verified"/) && has(V(p, mk(good + ' It is safe.')), /"safe"/));
      check(`${p}: a README with the British heading is found`, has(V(p, mk(good.replace('LICENSES', 'LICENCES'))), /British way/));
    }
    check('windows: a README without Legal\'s Windows sentences is found', has(V('windows', winLike('windows', { readme: readmeText('windows', notice, info).replace(WINDOWS_WARN, 'x') })), /Windows warning sentences/));
    check('macos: a README without Legal\'s xattr lead-in is found', has(V('macos', mac({ readme: readmeText('macos', notice, info).replace(XATTR_LEAD, 'x') })), /lead-in to the xattr step/));
    check('NOTICES.txt that says "tested" in our own words is found', has(V('linux', winLike('linux', { notices: noticesText(lic) + ' It has been tested.' })), /NOTICES.txt uses "tested"/));
    // online play and the capture hook, read out of the packed executable or pck
    for (const [p, build] of [['windows', (x) => winLike('windows', x)], ['linux', (x) => winLike('linux', x)], ['macos', (x) => mac(x)]]) {
      check(`${p}: a package carrying a script from res://net/ is found (the privacy line depends on no online play)`, has(V(p, build({ extra: 'res://net/session.gd' })), /res:\/\/net\//));
      check(`${p}: a package whose features.json has the capture hook on is found (RL-196)`, has(V(p, build({ extra: '"capture_hook": true' })), /capture_hook true/));
      check(`${p}: a package whose file list cannot be read says so instead of passing`, has(V(p, build({ noPaths: true })), /file list could not be read/));
    }
  }
  // the routes check (RL-203 condition 3, RL-204 condition 1): on the real tree with the lock set and the presets as they will be once the macOS patch lands, then one mutation at a time
  {
    const repo = resolve(here, '..');
    const realPresets = readFileSync(join(repo, 'export_presets.cfg'), 'utf8');
    const features = readFileSync(join(repo, 'ui', 'data', 'features.json'), 'utf8');
    const NL = String.fromCharCode(10);
    const withNet = realPresets.split(NL).map((l) => (l.startsWith('exclude_filter="') && !l.includes('net/*') ? l.replace('exclude_filter="', 'exclude_filter="net/*, ') : l)).join(NL);
    const presetsOk = presetsOf(withNet).some((x) => x.name === 'macOS') ? withNet : `${withNet}${NL}[preset.9]${NL}${NL}name="macOS"${NL}platform="macOS"${NL}exclude_filter="net/*, prototype/*"${NL}`;
    const lockedFeatures = features.replace(/"lock_reduce_flashing"\s*:\s*false/, '"lock_reduce_flashing": true');
    const R = (o = {}) => routeProblems(repo, { presets: presetsOk, ...o, files: { 'ui/data/features.json': lockedFeatures, ...(o.files || {}) } });
    const base = R();
    check('routes: the real tree, locked, with net/ excluded and a macOS preset, has no problem', base.length === 0, JSON.stringify(base));
    check('routes: the six words are the reviewed ones', SIX_WORDS.join(',') === 'bench,frames,shot,nonotice,flashcap,study');
    const hud = readFileSync(join(repo, 'ui', 'hud', 'ui_hud.gd'), 'utf8'), main = readFileSync(join(repo, 'render', 'core', 'main.gd'), 'utf8');
    check('routes: the lock not set in features.json is found', R({ files: { 'ui/data/features.json': features } }).some((m) => /lock_reduce_flashing is not true/.test(m)));
    check('routes: the capture hook on in features.json is found', R({ files: { 'ui/data/features.json': lockedFeatures.replace('"capture_hook": false', '"capture_hook": true') } }).some((m) => /capture_hook is not false/.test(m)));
    check('routes: a seventh bypass word is found', R({ files: { 'ui/hud/ui_hud.gd': hud.replace('"flashcap", "study"]', '"flashcap", "study", "nolock"]') } }).some((m) => /BYPASS_WORDS is \[.*nolock/.test(m)));
    check('routes: a bypass word removed is found', R({ files: { 'ui/hud/ui_hud.gd': hud.replace('"nonotice", ', '') } }).some((m) => /BYPASS_WORDS is/.test(m)));
    const GUARD2 = /(static func bypass_allowed\(\) -> bool:\r?\n)[ \t]*if UiData\.rf_locked\(\) and not UiData\.feature\("capture_hook"\):\r?\n[ \t]*return false\r?\n/;
    check('routes: the live ui_hud.gd opens bypass_allowed() with the RL-206 lock test (the control below is meaningful)', GUARD2.test(hud));
    const noGuard = hud.replace(GUARD2, '$1');
    check('routes: bypass_allowed() without the two RL-206 lines is found', noGuard !== hud && R({ files: { 'ui/hud/ui_hud.gd': noGuard } }).some((m) => /bypass_allowed\(\) does not begin/.test(m)));
    check('routes: bypass_allowed() with the test but no `return false` is found', R({ files: { 'ui/hud/ui_hud.gd': hud.replace(GUARD2, '$1\tif UiData.rf_locked() and not UiData.feature("capture_hook"):\n\t\tpass\n') } }).some((m) => /bypass_allowed\(\) does not begin/.test(m)));
    check('routes: the guard moved below the web test (not first) is found', R({ files: { 'ui/hud/ui_hud.gd': hud.replace(GUARD2, '$1\tif not OS.has_feature("web"):\n\t\treturn true\n\tif UiData.rf_locked() and not UiData.feature("capture_hook"):\n\t\treturn false\n') } }).some((m) => /bypass_allowed\(\) does not begin/.test(m)));
    const lift = `${NL}func _evil() -> void:${NL}\tif args.has("normal"):${NL}\t\tUiData.set_feature("lock_reduce_flashing", false)${NL}`;
    const lifted = R({ files: { 'render/core/main.gd': main + lift } });
    check('routes: a flag that switches the lock off is found by the argument check (the route scan reads the disk, not this override; it has its own tests)', lifted.some((m) => /a flag could reach normal mode/.test(m)) && lifted.some((m) => /switches the lock off/.test(m)), JSON.stringify(lifted));
    check('routes: a flag that writes the register is found', R({ files: { 'render/core/main.gd': main + `${NL}func _e2() -> void:${NL}\tif args.has("calm"):${NL}\t\tPaneWorld.flash_calm = false${NL}` } }).some((m) => /a flag could reach normal mode/.test(m)));
    check('routes: a flag that writes the Reduce flashing option is found', R({ files: { 'render/core/main.gd': main + `${NL}func _e3() -> void:${NL}\tif OS.get_cmdline_user_args().has("--rf0"):${NL}\t\tui_hud.settings_set("reduce_flashing", false)${NL}` } }).some((m) => /a flag could reach normal mode/.test(m)));
    check('routes: a packed script that switches the lock off is found', R({ files: { 'ui/demo/hud_demo.gd': readFileSync(join(repo, 'ui', 'demo', 'hud_demo.gd'), 'utf8') + `${NL}func _e4() -> void:${NL}\tUiData.set_feature("lock_reduce_flashing", false)${NL}` } }).some((m) => /switches the lock off/.test(m)));
    check('routes: a network class in a packed script is found', R({ files: { 'render/core/main.gd': main + `${NL}var _h = HTTPRequest.new()${NL}` } }).some((m) => /network class/.test(m)));
    check('routes: a reference to res://net in a packed script is found', R({ files: { 'render/core/main.gd': main + `${NL}var _s = preload("res://net/session.gd")${NL}` } }).some((m) => /network class or res:\/\/net/.test(m)));
    check('routes: a preset that does not exclude net/* is found, each of the three', ['Windows Desktop', 'Linux', 'macOS'].every((name) => {
      const lines = presetsOk.split(NL); let inPreset = false;
      const mutated = lines.map((l) => { if (/^name="/.test(l)) inPreset = l === `name="${name}"`; return inPreset && l.startsWith('exclude_filter="') ? l.replace('net/*, ', '').replace('net/*', '') : l; }).join(NL);
      return R({ presets: mutated }).some((m) => m.includes(`"${name}" preset does not exclude net/*`));
    }));
    check('routes: no macOS preset is found', R({ presets: realPresets.split('[preset.2]')[0] }).some((m) => /no "macOS" preset/.test(m)));
    check('routes: the command exits 1 on the repository as it stands (features.json is unlocked in the repository; the workflow locks its own checkout) and says why', (() => { const r = spawnSync(process.execPath, [join(here, 'desktop-package.mjs'), 'routes', '--root', repo], { encoding: 'utf8' }); return r.status === 1 && /lock_reduce_flashing is not true/.test(r.stderr); })());
  }

  // the command, end to end on a synthetic package
  {
    const d = winLike('windows');
    const ok = spawnSync(process.execPath, [join(here, 'desktop-package.mjs'), 'verify', '--platform', 'windows', '--dir', d, '--locked'], { encoding: 'utf8' });
    check('the command: a synthetic package below the real size floor exits 1 and says why (the floor is the real one)', ok.status === 1 && /smaller than any template/.test(ok.stderr), ok.stderr);
    const out = join(tmp, 'text-out');
    const w = spawnSync(process.execPath, [join(here, 'desktop-package.mjs'), 'text', '--platform', 'macos', '--out', out, '--build-info', join(d, 'build_info.json')], { encoding: 'utf8' });
    check('the command: text writes README.txt, NOTICES.txt and build_info.json', w.status === 0 && /Open Anyway/.test(readFileSync(join(out, 'README.txt'), 'utf8')) && readFileSync(join(out, 'NOTICES.txt'), 'utf8').length > 50000 && JSON.parse(readFileSync(join(out, 'build_info.json'), 'utf8')).commit === 'abc1234', w.stderr);
    check('the command: text without a platform is a usage error (exit 2)', spawnSync(process.execPath, [join(here, 'desktop-package.mjs'), 'text', '--out', out], { encoding: 'utf8' }).status === 2);
  }
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
console.log(failed ? `desktop package self-test FAILED: ${failed} of ${ran}` : `desktop package self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
