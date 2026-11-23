// Self-test of tools/report-scan.mjs (Tools, 2026-11-23). node tools/report-scan-selftest.mjs
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { CONFIG, scanText, scanSizes, scanPaths } from './report-scan.mjs';
let bad = 0, n = 0;
const check = (name, ok, extra) => { n++; if (!ok) { bad++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const B = String.fromCharCode(92);
const rules = (t, names) => scanText(t, names).map((x) => x.rule).join();
check('a Windows user folder is found', /windowsUserFolder/.test(rules(`ERROR at C:${B}Users${B}someone${B}AppData${B}Roaming${B}Godot`)));
check('a forward-slash drive path and an MSYS one are found', /windowsUserFolder/.test(rules('open C:/Users/someone/x')) && /posixHome/.test(rules('open /c/Users/someone/x')));
check('a Linux home and a Mac home are found', /posixHome/.test(rules('/home/someone/.local/share')) && /posixHome/.test(rules('/Users/someone/Library')));
check('a drive path of this PC and a network share are found', /driveRoot/.test(rules(`D:${B}games${B}orb${B}x.log`)) && /uncShare/.test(rules(`${B}${B}HOMEPC${B}share`)));
check('an email, an IPv4 address and a network card address are found; 127.0.0.1 is not', /email/.test(rules('mail me at a.b@example.com')) && /ipv4/.test(rules('peer 192.168.1.20')) && !/ipv4/.test(rules('listen 127.0.0.1')) && /mac/.test(rules('aa:bb:cc:dd:ee:ff')));
check('the engine banner and a GPU driver version are not hits', rules('Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org') === '' && rules('driver 32.0.101.6881 NVIDIA GeForce RTX') === '');
check('a name of an account, a PC or a tester is found as a whole word, in any case', /name/.test(rules('hello Someone there', ['someone'])) && rules('somebody', ['someone']) === '' && rules('xsomeonex', ['someone']) === '');
check('a name under three letters is not searched (it would hit everything)', rules('an xy here', ['xy']) === '');
check('the match file the game writes has no hit', rules('{"kind": "orb-solo-match", "pc": "main", "slot": 0, "mode": "solo", "build": "66d4e460 (2026-11-23)", "reason": "report", "savedAt": "2026-11-23T10:00:00", "tick": 4200}') === '');
const f = (size) => ({ file: 'a', size });
check('a file over the per-file limit and a folder over the total are found', scanSizes([f(CONFIG.perFileBytes + 1)]).length === 1 && scanSizes([f(CONFIG.perFileBytes), f(CONFIG.perFileBytes), f(CONFIG.perFileBytes)]).some((x) => x.file === '(all)') && scanSizes([f(1000)]).length === 0);
check('the limits sit under Discord\'s free limit with room (the note names the source)', CONFIG.totalBytes < CONFIG.discordFreeUploadBytes / 2 && /neowin/i.test(CONFIG.discordNote));
const d = mkdtempSync(join(tmpdir(), 'report-scan-'));
try {
  writeFileSync(join(d, 'ok.json'), '{"kind":"orb-solo-match"}');
  writeFileSync(join(d, 'bad.log'), `line one\nat C:${B}Users${B}someone${B}x\n`);
  writeFileSync(join(d, 'replay.bin'), Buffer.alloc(10));
  const r = scanPaths([d]);
  check('a folder scan reads text files, sizes the binary one, and names the file and line of a hit without the text', r.files.length === 3 && r.binary.length === 1 && r.findings.length === 2 && r.findings.every((x) => x.line === 2) && !JSON.stringify(r.findings).includes('someone'));
} finally { rmSync(d, { recursive: true, force: true }); }
console.log(`report-scan selftest: ${n} checks, ${bad} failed`);
process.exit(bad ? 1 : 0);
