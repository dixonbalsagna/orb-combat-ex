// Self-test of tools/desktop-package.mjs: the README and NOTICES text, the Reduce flashing lock edit and its guard, and the package check, on small synthetic packages (a real Windows, Linux or macOS
// build is 80 to 170 MB; the check takes its size floor as an option here). No Godot, no network. CI runs it.
//   node tools/desktop-package-selftest.mjs
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync, chmodSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { loadSnippets, noticeProblems, noticeSection, MIT_TEXT } from './third-party.mjs';
import { activeNotice, PRIVATE_LINE, readmeText, noticesText, lockReduceFlashing, setTestersPackage, testersMenu, setVersionFields, lockGuard, enableAstcImport, verifyDir, routeProblems, presetsOf, NAMES, SIX_WORDS, PERMISSION_FILE, permissionText, TESTER_NOTICE, REPORT_SLOT, channelProblem, readChannel, testerShapeProblems, fillChannel, WINDOWS_WARN, XATTR_LEAD, PRIVACY, NO_ASSURANCE } from './desktop-package.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const here = import.meta.dirname;
const lic = JSON.parse(readFileSync(join(here, 'site-licences.json'), 'utf8'));
process.env.ORB_PACKAGE_NOTICE = 'site-interim-owner.json';   // the children below inherit it (see activeNotice)
const notice = activeNotice();   // the owner notice by name: the self-test must not depend on whether the site is offline right now
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
  check('private: an owner-private README carries the ORB-PRIVATE line under the commit, and an ordinary one does not (Legal RL-262)', (() => { const a = readmeText('windows', notice, info, { private: true }), b = readmeText('windows', notice, info); const L = a.split(String.fromCharCode(10)); return L[3] === PRIVATE_LINE && /ORB-PRIVATE/.test(a) && !/ORB-PRIVATE/.test(b) && L[2].startsWith('Commit '); })());
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

  // the version into the exports' own fields (A-TOOLS-07)
  {
    const root = join(tmp, 'vtree'); mkdirSync(root, { recursive: true });
    const cfg = join(root, 'export_presets.cfg');
    const base = ['[preset.1]', 'name="Windows Desktop"', 'application/file_version=""', 'application/product_version=""', '[preset.3]', 'name="macOS"', 'application/short_version="0.1"', 'application/version="0.1"', ''].join(String.fromCharCode(10));
    writeFileSync(cfg, base);
    const set = setVersionFields(root, { major: 0, minor: 1, build: 7 });
    const out = readFileSync(cfg, 'utf8');
    check('version: the Windows fields take the four-number form and the macOS version the three-number one, nothing else changes', set.length === 3 && out.includes('application/file_version="0.1.7.0"') && out.includes('application/product_version="0.1.7.0"') && out.includes('application/version="0.1.7"') && out.includes('application/short_version="0.1"') && out.includes('name="macOS"'), out);
    check('version: a second run changes nothing', setVersionFields(root, { major: 0, minor: 1, build: 7 }).length === 0);
    check('version: the next build changes all three', setVersionFields(root, { major: 0, minor: 1, build: 8 }).length === 3 && readFileSync(cfg, 'utf8').includes('0.1.8.0'));
    writeFileSync(cfg, base + 'application/version="x"' + String.fromCharCode(10));
    check('version: a key found twice is refused (the presets moved)', (() => { try { setVersionFields(root, { major: 0, minor: 1, build: 7 }); return false; } catch (e) { return /expected application\/version once, found it 2 times/.test(e.message); } })());
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
    for (const n of ['desktop-package.mjs', 'site-routes.mjs', 'third-party.mjs']) writeFileSync(join(own, 'tools', n), readFileSync(join(here, n)));
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
    // other people's code the program holds (RL-289, RL-292): the notice must be in NOTICES.txt, and code with no known terms keeps a testers' package back
    {
      const snippets = loadSnippets(), mit = snippets.filter((r) => r.license), none = snippets.filter((r) => !r.license);
      const holding = (r) => ` ${r.map((x) => x.marker).join(' ')} `;
      const withNotice = noticesText(lic, null, noticeSection(mit));
      check('NOTICES.txt carries each credit, its copyright line and the MIT words', mit.length >= 1 && mit.every((r) => withNotice.includes(r.author) && withNotice.includes(r.copyright)) && withNotice.includes(MIT_TEXT) && !noticesText(lic).includes(mit[0].author));
      for (const p of ['windows', 'linux', 'macos']) {
        const mk = (over) => (p === 'macos' ? mac(over) : winLike(p, over));
        check(`${p}: a program holding the code, with its notice, passes`, !has(V(p, mk({ extra: holding(mit), notices: withNotice })), /RL-289/));
        check(`${p}: a program holding the code without its notice is refused, each snippet by name`, mit.every((r) => has(V(p, mk({ extra: holding([r]) })), new RegExp(`does not carry the notice for the .* by ${r.author}`))));
        check(`${p}: a program holding none of it needs no notice`, !has(V(p, mk({})), /RL-289/));
        if (none.length) check(`${p}: code with no known terms keeps a testers' package back, and not an owner's`, has(V(p, mk({ extra: holding(none), notices: withNotice }), { testers: true }), /no known terms/) && !has(V(p, mk({ extra: holding(none), notices: withNotice }), { testers: false }), /no known terms/));
      }
      check('a notice that names the code without the licence words is not enough', noticeProblems(mit, mit.map((r) => `${r.title} ${r.author} ${r.copyright}`).join('\n')).length === mit.length);
    }
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
    // the testers' package (path to Alpha 1 job 14): the flag on and the menu hiding the rows testers cannot use; off in Orb's own build
    const testersOn = features.replace(/"testers_package"\s*:\s*false/, '"testers_package": true');
    check('testers: the testers\' package with the flag on has no problem; the flag off in it is named', R({ testers: true, files: { 'ui/data/features.json': lockedFeatures.replace(/"testers_package"\s*:\s*false/, '"testers_package": true') } }).length === 0 && R({ testers: true }).some((p) => /testers_package is not true/.test(p)));
    check('testers: Orb\'s own build (no testers flag) with the flag on is named, with it off has no problem', R({ testers: false, files: { 'ui/data/features.json': lockedFeatures.replace(/"testers_package"\s*:\s*false/, '"testers_package": true') } }).some((p) => /not the testers' package/.test(p)) && R({ testers: false }).length === 0);
    void testersOn;
    const menu = testersMenu({ modes: [{ id: 'solo', testers: true }, { id: 'lan', testers: false }, { id: 'campaign', testers: false }] }, true);
    check('testers: the menu hides the rows whose testers flag is false and keeps the rest; with the flag off it hides none', menu.shown.join() === 'solo' && menu.hidden.join() === 'lan,campaign' && !menu.problems.length && testersMenu({ modes: [{ id: 'solo', testers: true }, { id: 'lan', testers: false }] }, false).shown.length === 2);
    check('testers: a row with no testers flag is named, and so are no rows', testersMenu({ modes: [{ id: 'x' }] }, true).problems.length === 1 && testersMenu({}, true).problems.length === 1);
    {
      const d = mkdtempSync(join(tmpdir(), 'testers-'));
      try {
        mkdirSync(join(d, 'ui', 'data'), { recursive: true });
        const ff = join(d, 'ui', 'data', 'features.json');
        writeFileSync(ff, '{\n  "testers_package": false,\n  "other": false\n}\n');
        check('testers: the setter sets testers_package true and nothing else, and a second run changes nothing', setTestersPackage(d) === true && readFileSync(ff, 'utf8') === '{\n  "testers_package": true,\n  "other": false\n}\n' && setTestersPackage(d) === false);
        writeFileSync(ff, '{ "x": 1 }');
        let threw = false; try { setTestersPackage(d); } catch { threw = true; }
        check('testers: a tree with no testers_package flag is refused, not guessed at', threw);
      } finally { rmSync(d, { recursive: true, force: true }); }
    }
    {
      // the sound proof's argument (--audio-proof): the real entry passes; moved, not returning, read elsewhere, or a proof that loads the picture, is found
      const entry = readFileSync(join(repo, 'render', 'core', 'boot_entry.gd'), 'utf8').split(String.fromCharCode(13)).join('');
      const proof = readFileSync(join(repo, 'audio', 'audio_proof.gd'), 'utf8');
      const NL = String.fromCharCode(10), T = String.fromCharCode(9);
      const withEntry = (text, more = {}) => R({ files: { 'render/core/boot_entry.gd': text, ...more } }).filter((m) => /audio-proof|audio_proof/.test(m));
      const branch = entry.slice(entry.indexOf(T + 'if OS.get_cmdline_user_args().has(' + String.fromCharCode(34) + '--audio-proof'), entry.indexOf(T + 'if _direct():'));
      check('audio proof: the entry in the tree has the branch, and it passes', branch.includes('return') && withEntry(entry).length === 0, JSON.stringify(withEntry(entry)));
      const moved = entry.replace(branch, '').replace(T + 'add_child(RenderBoot.line', branch + T + 'add_child(RenderBoot.line');
      check('audio proof: the branch moved after the scene load is found', moved !== entry && withEntry(moved).some((m) => /not the first thing/.test(m)));
      check('audio proof: a branch that does not return, and a second read of the argument, are found', withEntry(entry.replace(T + T + 'return' + NL, '')).length === 1 && withEntry(entry + NL + 'var again: bool = OS.get_cmdline_user_args().has(' + String.fromCharCode(34) + '--audio-proof' + String.fromCharCode(34) + ')' + NL).length === 1);
      check('audio proof: another script reading it, and a proof that loads the picture, are found', R({ files: { 'ui/hud/ui_hud.gd': readFileSync(join(repo, 'ui', 'hud', 'ui_hud.gd'), 'utf8') + NL + 'var p := ' + String.fromCharCode(34) + '--audio-proof' + String.fromCharCode(34) + NL } }).some((m) => /read outside the game's entry/.test(m)) && withEntry(entry, { 'audio/audio_proof.gd': proof + NL + 'var m := load(' + String.fromCharCode(34) + 'res://render/main.tscn' + String.fromCharCode(34) + ')' + NL }).some((m) => /must reach no match/.test(m)));
      check('audio proof: a tree that reads the argument nowhere has nothing to hold', withEntry(entry.replace(branch, '')).length === 0);
    }
    check('routes: the six words are the reviewed ones', SIX_WORDS.join(',') === 'bench,frames,shot,nonotice,flashcap,study');
    const hud = readFileSync(join(repo, 'ui', 'hud', 'ui_hud.gd'), 'utf8'), main = readFileSync(join(repo, 'render', 'core', 'main.gd'), 'utf8');
    const sendReal = readFileSync(join(repo, 'ui', 'data', 'send.json'), 'utf8');
    check('routes: a feedback target of github (a public issue) is refused (RL-262)', R({ files: { 'ui/data/send.json': sendReal.replace(/"_target":\s*"[a-z]*"/, '"_target": "github"') } }).some((m) => /_target is "github"/.test(m)));
    check('routes: a feedback target of mailto or form is allowed', ['mailto', 'form'].every((t) => !R({ files: { 'ui/data/send.json': sendReal.replace(/"_target":\s*"[a-z]*"/, `"_target": "${t}"`) } }).some((m) => /_target/.test(m))));
    check('routes: a missing send.json is found', R({ files: { 'ui/data/send.json': null } }).some((m) => /send.json is missing/.test(m)));
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

  // the testers' words and the report channel (A2, Legal RL-264)
  {
    const t = JSON.parse(readFileSync(join(here, TESTER_NOTICE), 'utf8'));
    const everyString = [t.gate.heading, ...t.gate.blocks.map((b) => b.p), t.gate.under, t.gate.ai, ...t.tester.flatMap((x) => [x.h, x.p]), t.credits, t.notices_header];
    check("testers' words: git holds the placeholder, once, in the third section, and no other square brackets anywhere (a real channel never goes in git)", testerShapeProblems(t).length === 0 && t.tester[2].p.split(REPORT_SLOT).length === 2 && everyString.join(' ').split('[').length === 2 && typeof t.draft === 'boolean', JSON.stringify(testerShapeProblems(t)));
    const norm = (x) => x.toLowerCase().split(/\s+/).join(' ');
    const page = norm(readFileSync(join(here, '..', 'docs', 'legal', 'tester-folder-notices.md'), 'utf8'));
    const missing = everyString.filter((x) => !page.includes(norm(x)));
    check("testers' words: every string is on Legal's page word for word (docs/legal/tester-folder-notices.md)", missing.length === 0, missing.join(' | '));
    const GOOD = 'the private test channel you were invited to with your key';
    check('report channel: a plain description passes', channelProblem(GOOD) === null);
    const NL = String.fromCharCode(10);
    const bad = [[null, /no report-channel line/], ['   ', /no report-channel line/], [REPORT_SLOT, /placeholder/], ['[the channel, later]', /placeholder/], ['the channel at https://example.org/x', /link/], ['our server discord.gg/abcdef', /link/], ['write to someone@example.invalid', /link|handle/], ['the channel of tester#1234', /handle/], ['two lines' + NL + 'of words here', /more than one line/], ['chat', /8 to 160/]];
    const wrong = bad.filter(([line, re]) => !re.test(channelProblem(line) || '')).map(([line]) => String(line));
    check('report channel: a missing line, a placeholder, a link, an invite, an address, a handle, two lines and a word too short are each refused and said why', wrong.length === 0, wrong.join(' | '));
    const cf = join(tmp, 'report-channel.txt');
    writeFileSync(cf, String.fromCharCode(0xfeff) + GOOD + String.fromCharCode(13, 10));
    check("report channel: the file's line is read (a byte order mark and a Windows line ending dropped); no file reads as none", readChannel(cf) === GOOD && readChannel(join(tmp, 'nope.txt')) === null);
    const filled = fillChannel({ ...t, draft: false }, GOOD);
    check('report channel: filled in once; the committed words are not changed by it', filled.tester[2].p.includes(': ' + GOOD + '.') && !filled.tester[2].p.includes(REPORT_SLOT) && t.tester[2].p.includes(REPORT_SLOT));
    const throwsWith = (fn, re) => { try { fn(); return false; } catch (e) { return re.test(e.message); } };
    check('report channel: the package words are refused with no line, with the placeholder, and when the file in git already holds a real channel', throwsWith(() => fillChannel(t, null), /refused: there is no report-channel line/) && throwsWith(() => fillChannel(t, REPORT_SLOT), /refused: .*placeholder/) && throwsWith(() => fillChannel(filled, GOOD), /git never holds a real channel/));
    const readme = readmeText('windows', filled, info);
    const at = ['BEFORE YOU PLAY: FLASHING EFFECTS', 'HOW THIS GAME WAS MADE', 'WHO THIS BUILD IS FOR', 'WHAT YOU MAY DO', 'PRIVACY', 'WHAT LEAVES YOUR COMPUTER', 'HOW TO RUN', 'CREDITS AND LICENSES'].map((h) => readme.indexOf(NL + h));
    check("testers' README: Legal's sections in Legal's order, with no placeholder left", at.every((v, i) => v > 0 && (i === 0 || v > at[i - 1])) && !readme.includes('[REPORT CHANNEL'), at.join());
    const T = (over = {}) => {
      const d = winLike('windows', { readme, notices: noticesText(lic, t.notices_header), extra: '"testers_package": true "testers": false', ...over });
      if (over.permission !== null) writeFileSync(join(d, PERMISSION_FILE), over.permission ?? permissionText(t));
      return V('windows', d, { testers: true, locked: true, noticeObject: { ...t, draft: false } });
    };
    check("testers' package: a whole one passes the check", T().length === 0, JSON.stringify(T()));
    check("testers' package: the placeholder left in README.txt is refused", has(T({ readme: readme.replace(GOOD, REPORT_SLOT) }), /still holds the report-channel placeholder/));
    check("testers' package: a link in the channel line is refused", has(T({ readme: readme.replace(GOOD, 'https://example.org/invite') }), /holds a link/));
    check("testers' package: a missing section, a changed section and a missing channel paragraph are found", has(T({ readme: readme.replace('WHAT YOU MAY DO', 'WHAT YOU CAN DO') }), /What you may do/) && has(T({ readme: readme.replace('named adult friend', 'friend') }), /Who this build is for/) && has(T({ readme: readme.replace('WHAT LEAVES YOUR COMPUTER', 'SENDING') }), /What leaves your computer/));
    check("testers' package: NOTICES.txt without the header paragraph is found", has(T({ notices: noticesText(lic) }), /header paragraph/));
    check("testers' package: the permission page missing or changed is found", has(T({ permission: null }), /WHAT-YOU-MAY-DO\.txt is missing/) && has(T({ permission: permissionText(t).replace('without asking Orb first', 'freely') }), /not Legal's permission page/));
    {
      const md = readFileSync(join(here, '..', 'docs', 'legal', 'permission-page.md'), 'utf8').split(String.fromCharCode(13)).join('');
      const from = md.indexOf('**What you may do with Orb Combat EX during the Alpha**'), to = md.indexOf(NL + '---', from);
      const page = md.slice(from, to).split('**').join('').split(NL).map((l) => l.trimEnd());
      while (page.length && !page[page.length - 1]) page.pop();
      check("the permission file is Legal's page, line for line, both ways (docs/legal/permission-page.md)", from >= 0 && to > from && JSON.stringify(t.permission) === JSON.stringify(page) && !t.permission.join(' ').includes('['), `${t.permission.length} lines against ${page.length}`);
      check("the permission file is titled as the game's line points to it, with no assurance word", t.permission[0].startsWith('What you may do with Orb Combat EX') && PERMISSION_FILE === 'WHAT-YOU-MAY-DO.txt' && NO_ASSURANCE.every((w) => !new RegExp(`(^|[^A-Za-z-])${w}($|[^A-Za-z-])`, 'i').test(permissionText(t))));
    }
    check("testers' package: a README with the owner's words instead is found", has(T({ readme: readmeText('windows', notice, info) }), /Who this build is for/));
    const out = join(tmp, 'text-testers');
    const bi = join(tmp, 'bi.json');
    writeFileSync(bi, JSON.stringify(info));
    const C = (...more) => spawnSync(process.execPath, [join(here, 'desktop-package.mjs'), 'text', '--platform', 'windows', '--out', out, '--build-info', bi, '--testers', ...more], { encoding: 'utf8' });
    const r = C('--channel-file', join(tmp, 'no-channel.txt'));
    check('the command: text --testers is refused (a draft until Orb has seen the words; after that, no channel line) and writes nothing', r.status === 1 && (t.draft ? /still a draft/ : /no report-channel line/).test(r.stderr) && !existsSync(out), r.stderr);
    check('the command: text --testers takes neither --private nor --notice', C('--private').status === 1 && C('--notice', 'site-interim-owner.json').status === 1 && !existsSync(out));
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
