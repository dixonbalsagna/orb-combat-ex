// Makes the private LAN test's folder (docs/net/lan-v1.md): a plain 1v1 between two PCs. It edits a SCRATCH COPY of the project, exports it and writes the shortcuts. It starts no game and opens no port.
// The public desktop builds stay as they are: they exclude net/ (Legal RL-204), and nothing here goes on main. So the two lines the game needs are patched in here, and this stops if they no longer fit.
//   node net/tools/lan_kit.mjs --tree=SCRATCH_COPY --out=FOLDER --godot=PATH\Godot_v4.7.2-stable_win64_console.exe --host-ip=10.0.0.135 --build=NAME [--no-export]
// --tree: a copy of main, or of the tree Tools' stack exported for the kept build (its sim_host steps through the black box's _bb_step).
import { copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { networkInterfaces } from 'node:os';
import { spawnSync } from 'node:child_process';

const a = Object.fromEntries(process.argv.slice(2).map((s) => { const [k, ...v] = s.replace(/^--/, '').split('='); return [k, v.join('=')]; }));
const stop = (m) => { console.error(m); process.exit(2); };
for (const k of ['tree', 'out', 'godot', 'host-ip', 'build']) if (!a[k]) stop(`--${k} is required`);
if (!/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.test(a['host-ip'])) stop('--host-ip: a home-network address');
if (!/^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/.test(a['host-ip'])) stop('--host-ip: private addresses only');
// Legal RL-230: the home network only. The address must be this PC's own, on a real adapter, as Performance's old-PC server refuses (build the folder on the PC that hosts).
{
  const owner = Object.entries(networkInterfaces()).find(([, list]) => list.some((x) => x.address === a['host-ip']));
  if (!owner) stop(`--host-ip: ${a['host-ip']} isn't an address of this PC`);
  if (/zerotier|vpn|tailscale|wireguard|hamachi|tap|tun|virtual|vethernet|loopback/i.test(owner[0])) stop(`--host-ip: ${owner[0]} is a member or virtual network, which RL-230 rules out`);
}
if (!/^[A-Za-z0-9._-]+$/.test(a.build)) stop('--build: letters, digits, dot, dash and underscore only');
const tree = resolve(a.tree);
const out = resolve(a.out);
if (existsSync(join(tree, '.git'))) stop(`${tree} has a .git: give a scratch copy, never the repository`);
if (!existsSync(join(tree, 'project.godot'))) stop(`${tree} is not a project`);
if (existsSync(out) && readdirSync(out).length > 0) stop(`${out} is not empty`);
const subnet = a['host-ip'].split('.').slice(0, 3).join('.') + '.0/24';
const exeName = 'orb-combat-lan.exe';

function patch(rel, edits) {
  const p = join(tree, rel);
  let s = readFileSync(p, 'utf8');
  for (const [from, to] of edits) {
    const n = s.split(from).length - 1;
    if (n !== 1) stop(`${rel}: expected one of: ${from.slice(0, 70)} (found ${n}). The game changed: update lan_kit.mjs`);
    s = s.replace(from, () => to);
  }
  writeFileSync(p, s);
}

const hostText = readFileSync(join(tree, 'render/core/sim_host.gd'), 'utf8');
const stepCall = hostText.includes('\tif _bb_step(inputs):') ? '_bb_step(inputs)' : 'SimCore.step(S, inputs)';   // the kept build records through the black box; on a PC it stays off
patch('render/core/sim_host.gd', [
  ['var read_ahead_cols: int = 0', 'var lan = null   # the private LAN test (net/lan.gd): it steps the sim\nvar read_ahead_cols: int = 0'],
  [`\tif ${stepCall}:`, `\tif (lan.tick(inputs[lan.hubSlot]) if lan != null else ${stepCall}):`],
  ['func advance(frame_dt: float, vw: float, vh: float) -> int:\n\tif paused:\n', 'func advance(frame_dt: float, vw: float, vh: float) -> int:\n\tif paused:\n\t\tif lan != null:\n\t\t\tlan.idle()   # the link and the packets go on through a pause, so the other PC waits instead of losing the link\n'],
  ['func toggle_ai(idx: int) -> void:\n', 'func toggle_ai(idx: int) -> void:\n\tif lan != null:\n\t\treturn   # a pad leaving must not hand one PC\'s fighter to its AI: the PCs would part\n'],
]);
patch('render/core/main.gd', [
  ['func start_match(seed: int, ai: Dictionary = {}, setup = null) -> void:\n', 'func start_match(seed: int, ai: Dictionary = {}, setup = null) -> void:\n\tif host.lan != null:\n\t\treturn   # one match in the private LAN test\n'],
  ['func _on_menu_started(cfg: Dictionary) -> void:\n', 'func _on_menu_started(cfg: Dictionary) -> void:\n\tif host.lan != null:\n\t\treturn\n'],
  ['\tvar ai := {"p1": false, "p2": not two}\n', '\tvar ai := {"p1": false, "p2": not two}\n\tvar lan_on: bool = args.has("lan-host") or args.has("lan-join") or args.has("lan-loop")\n\tif lan_on:\n\t\tai = NetLan.aiFor(args)\n'],
  ['\tif bool(cfg.get("intros", true)):\n\t\tstart_match(sd, ai)\n', '\tif lan_on:\n\t\tstart_match(NetLan.SEED, ai, NetLan.setupFor(args))\n\t\thost.lan = NetLan.new(host, args)\n\t\tsplit_rig.test_human_slot = -2 if host.lan.two else host.lan.hubSlot   # this PC\'s player is the human, for the camera: their pane is the bigger, as against the computer (with two fights, the one with no AI in the fight S holds)\n\telif bool(cfg.get("intros", true)):\n\t\tstart_match(sd, ai)\n'],
  ['\t\thost.hub.claimed[s] = true\n\tstarted = true\n', '\t\thost.hub.claimed[s] = true\n\tif lan_on and host.lan.hubSlot == 1:   # the joiner plays the second fighter, so its pad is the hub\'s second slot: its rumble and its struggle follow that fighter\n\t\tNetLan.moveHub(host.hub, 0, 1)\n\tstarted = true\n'],
  ['\tstart_match(int(args["seed"]) if args.has("seed") else fresh_seed())\n', '\tstart_match(int(args["seed"]) if args.has("seed") else fresh_seed())\n\tif args.has("lan-loop") and DisplayServer.get_name() == "headless":\n\t\t_on_menu_started({})   # no window, no menu, so no warning to show: a test only\n'],
]);
// The kept page's own word for the meteor's trail (?meteor=loud), which a PC can't be given: VFX reads it from the page's address only.
{
  const m = join(tree, 'render/vfx/meteor.gd');
  if (existsSync(m) && readFileSync(m, 'utf8').includes('\t_word = ""\n\tif OS.has_feature("web") and UiHud.bypass_allowed():')) patch('render/vfx/meteor.gd', [['\t_word = ""\n\tif OS.has_feature("web") and UiHud.bypass_allowed():', '\t_word = "loud"\n\tif OS.has_feature("web") and UiHud.bypass_allowed():']]);
}
// "2v2 together" is a co-op match only with Encounter's blows from outside (sim/director/outside.gd: the single blow across, the sends that bring the fights together, the computer's dodge). They're
// behind their own data switch, which a match's setup can't reach, and do nothing unless hits across fights are on, as only the together shortcuts have them. So this copy turns it on.
// Simulation's per-setup key ("outside" in NetLan.SETUP2X) does it once it's in the tree; until then the data switch stands in.
const outsideBySetup = ['sim/core/stage.gd', 'sim/director/outside.gd'].some((p) => existsSync(join(tree, p)) && /setup(\.has\("outside"\)|\.get\("outside"|\["outside"\])/.test(readFileSync(join(tree, p), 'utf8')));
if (!outsideBySetup) {
  const f = join(tree, 'data/director/interrupts.json');
  const s = readFileSync(f, 'utf8');
  const from = /("outside": \{\s*"enabled": )false/;
  if (!from.test(s) && !/"outside": \{\s*"enabled": true/.test(s)) stop('data/director/interrupts.json: no outside.enabled to turn on (Encounter moved it: update lan_kit.mjs)');
  writeFileSync(f, s.replace(from, '$1true'));
  if (JSON.parse(readFileSync(f, 'utf8')).outside.enabled !== true) stop('the blows from outside did not turn on');
}
// 2v2 together: hear and see a brink in either fight (the EP, 2026-11-07). Audio's co-op sounds (audio/audio_coop.gd: the brink's call, and with it the refusal knock, the push and the
// charge stages, which a 1v1 would hear too) go on only in a game started with --lan-2v2-together: sound is the PC's own, never the sim's, so the plain pair stays as it is. UI's brink_mark and
// outside_words act only on the co-op cues, so this copy turns them on for every shortcut.
{
  const af = join(tree, 'audio/audio_coop.gd');
  if (existsSync(af)) patch('audio/audio_coop.gd', [['func enabled() -> bool:\n\treturn bool(cfg.get("enabled", false))\n', 'func enabled() -> bool:\n\treturn bool(cfg.get("enabled", false)) or OS.get_cmdline_user_args().has("--lan-2v2-together")   # the private LAN kit: on for 2v2 together only\n']]);
  else console.log('no audio/audio_coop.gd in this tree: the brink call is not in this build');
  const ff = join(tree, 'ui/data/features.json');
  const fj = JSON.parse(readFileSync(ff, 'utf8'));
  fj.features = fj.features ?? {};
  for (const k of ['brink_mark', 'outside_words']) fj.features[k] = true;
  writeFileSync(ff, JSON.stringify(fj, null, 2) + '\n');
}
// Only this copy's presets: the network code goes in, its tools stay out.
patch('export_presets.cfg', [
  ['name="Windows Desktop"', 'name="Windows Desktop"'],
]);
{
  const p = join(tree, 'export_presets.cfg');
  const s = readFileSync(p, 'utf8');
  const at = s.indexOf('name="Windows Desktop"');
  const line = s.indexOf('exclude_filter="net/*, ', at);
  if (at < 0 || line < 0) stop('export_presets.cfg: the Windows preset no longer excludes net/ in the known way');
  writeFileSync(p, s.slice(0, line) + 'exclude_filter="net/tools/*, ' + s.slice(line + 'exclude_filter="net/*, '.length));
}

function run(cmd, args) {
  console.log(`> ${cmd} ${args.join(' ')}`);
  const r = spawnSync(cmd, args, { stdio: 'inherit', windowsHide: true });
  if (r.status !== 0) stop(`failed: ${cmd} (exit ${r.status})`);
}
// The interim's terms hold here too: Reduce flashing locked on, as the desktop builds.
run(process.execPath, [join(tree, 'tools', 'desktop-package.mjs'), 'lock', '--root', tree]);
{
  const f = JSON.parse(readFileSync(join(tree, 'ui', 'data', 'features.json'), 'utf8')).features ?? {};
  if (f.lock_reduce_flashing !== true) stop('Reduce flashing did not lock on (RL-230)');
  if (f.capture_hook === true) stop('the capture hook is on (RL-230)');
}
mkdirSync(out, { recursive: true });
writeFileSync(join(tree, 'build_info.json'), JSON.stringify({ commit: a.build, lan: true }));
if (a['no-export'] === undefined) {
  run(resolve(a.godot), ['--headless', '--path', tree, '--import']);
  run(resolve(a.godot), ['--headless', '--path', tree, '--export-release', 'Windows Desktop', join(out, exeName)]);
}

const crlf = (l) => l.join('\r\n') + '\r\n';
writeFileSync(join(out, 'Host (main PC).cmd'), crlf([
  '@echo off',
  'cd /d "%~dp0"',
  `start "" "${exeName}" -- --lan-host=${a['host-ip']} --lan-log="%~dp0lan-log-main.txt" --tiles=1`,
]));
writeFileSync(join(out, 'Join (old PC).cmd'), crlf([
  '@echo off',
  'cd /d "%~dp0"',
  `start "" "${exeName}" -- --lan-join=${a['host-ip']} --lan-log="%~dp0lan-log-old.txt" --tiles=1`,
]));
writeFileSync(join(out, 'Host with a longer wait (main PC).cmd'), crlf([
  '@echo off',
  'cd /d "%~dp0"',
  `start "" "${exeName}" -- --lan-host=${a['host-ip']} --lan-delay=3 --lan-log="%~dp0lan-log-main.txt" --tiles=1`,
]));
// Legal RL-241: two fights, one seat each, once its sentence is in the words (checked below)
writeFileSync(join(out, 'Host 2v2 (main PC).cmd'), crlf([
  '@echo off',
  'cd /d "%~dp0"',
  `start "" "${exeName}" -- --lan-host=${a['host-ip']} --lan-2v2 --lan-log="%~dp0lan-log-main.txt" --tiles=1`,
]));
writeFileSync(join(out, 'Join 2v2 (old PC).cmd'), crlf([
  '@echo off',
  'cd /d "%~dp0"',
  `start "" "${exeName}" -- --lan-join=${a['host-ip']} --lan-2v2 --lan-log="%~dp0lan-log-old.txt" --tiles=1`,
]));
writeFileSync(join(out, 'Host 2v2 together (main PC).cmd'), crlf([
  '@echo off',
  'cd /d "%~dp0"',
  `start "" "${exeName}" -- --lan-host=${a['host-ip']} --lan-2v2-together --lan-log="%~dp0lan-log-main.txt" --tiles=1`,
]));
writeFileSync(join(out, 'Join 2v2 together (old PC).cmd'), crlf([
  '@echo off',
  'cd /d "%~dp0"',
  `start "" "${exeName}" -- --lan-join=${a['host-ip']} --lan-2v2-together --lan-log="%~dp0lan-log-old.txt" --tiles=1`,
]));
writeFileSync(join(out, 'Allow through the firewall (main PC, once).cmd'), crlf([
  '@echo off',
  'powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0firewall-allow.ps1"',
  'pause',
]));
writeFileSync(join(out, 'Remove the firewall rule (main PC, afterwards).cmd'), crlf([
  '@echo off',
  'powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0firewall-remove.ps1"',
  'pause',
]));
const elevate = (script) => [
  '$me = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()',
  'if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {',
  `  Start-Process powershell -Verb RunAs -Wait -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + (Join-Path $PSScriptRoot '${script}') + '"'))`,
  '  exit',
  '}',
];
writeFileSync(join(out, 'firewall-allow.ps1'), crlf([
  '# One inbound rule: this folder\'s game only, one UDP port, addresses on the home network only (so not ZeroTier). Run once on the PC that hosts. firewall-remove.ps1 takes it away.',
  ...elevate('firewall-allow.ps1'),
  `$exe = Join-Path $PSScriptRoot '${exeName}'`,
  `netsh advfirewall firewall add rule name="Orb Combat LAN test" dir=in action=allow program="$exe" protocol=UDP localport=47100 remoteip=${subnet} profile=any enable=yes`,
  'Write-Host "Done. You can close this window."',
  'Start-Sleep -Seconds 4',
]));
writeFileSync(join(out, 'firewall-remove.ps1'), crlf([
  '# Takes away the rule firewall-allow.ps1 added, and any rule Windows added for this game if you answered its own box.',
  ...elevate('firewall-remove.ps1'),
  `$exe = Join-Path $PSScriptRoot '${exeName}'`,
  'netsh advfirewall firewall delete rule name="Orb Combat LAN test"',
  'netsh advfirewall firewall delete rule name=all program="$exe"',
  'Write-Host "Done. You can close this window."',
  'Start-Sleep -Seconds 4',
]));
const words = readFileSync(join(tree, 'net', 'tools', 'lan_words.txt'), 'utf8').replaceAll('{HOST_IP}', a['host-ip']);
// Legal RL-230's words, checked: its WHO PLAYS line as it stands, a plain word that a link opens, and the public build's privacy line nowhere.
if (!words.includes("WHO PLAYS: Only Orb plays and watches, on both PCs, with nobody else in the room. This build has a flashing-effects warning; read it first. Don't copy, record, share or post this folder, the screens or the main PC's address.")) stop('lan_words.txt: the WHO PLAYS line is not RL-230\'s');
if (!words.includes("Two fights share one globe, so craters and damage from the other fight can appear in the world.")) stop('lan_words.txt: RL-241\'s sentence must be in the words before the 2v2 shortcuts go in');
if (!words.includes("Fighters in the other fight can hit you, and your partner's fight isn't shown on your screen.")) stop('lan_words.txt: RL-249\'s sentence must be in the words before the together shortcuts go in');
if (!/opens a network link between the two PCs/.test(words)) stop('lan_words.txt: it must say a link opens');
if (/collects|sends nothing|no accounts/i.test(words)) stop('lan_words.txt: RL-204\'s privacy line stays out of the kit');
writeFileSync(join(out, 'READ ME FIRST.txt'), words.replace(/\r?\n/g, '\r\n'));
console.log(`kit in ${out}, build ${a.build}, host ${a['host-ip']}, rule for ${subnet}`);
