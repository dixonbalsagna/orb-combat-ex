// Self-test of tools/record-paths.mjs and tools/lib/targz.mjs (Tools, 2026-11-23). node tools/record-paths-selftest.mjs
import { cleanPaths, leftover } from './record-paths.mjs';
import { targz, readTarGz, readTar, tarBuffer, header } from './lib/targz.mjs';
import { gunzipSync } from 'node:zlib';
let bad = 0, n = 0;
const check = (name, ok, extra) => { n++; if (!ok) { bad++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const B = String.fromCharCode(92);
const win = (...p) => p.join(B);

// the two existing build records' kinds of line
const scratch = win('C:', 'Users', 'someone', 'AppData', 'Local', 'Temp', 'orb-private-build-IQEWNu', 'tree');
let t = cleanPaths(`ok   unpacked: ${scratch}\nok   lock: set true in ${scratch}/ui/data/features.json\nwrote ${scratch}${B}build_info.json: commit b624340`);
check('a scratch folder under the temp folder becomes <scratch>, the rest of the path stays', t.includes(`<scratch>${B}tree`) && t.includes(`<scratch>${B}tree/ui/data/features.json`) && !/someone/.test(t), t);
const repo = win('C:', 'Users', 'someone', 'Documents', 'Claude Proj', 'Breakers-Like');
t = cleanPaths(`log in ${repo}${B}docs${B}tools and ${repo.split(B).join('/')}/tools`);
check('the repository folder becomes <repo> (with a space in the folder name)', t === `log in <repo>${B}docs${B}tools and <repo>/tools`, t);
t = cleanPaths(win('C:', 'Users', 'someone', 'AppData', 'Roaming', 'Godot') + ' and /c/Users/someone/x and /Users/someone/y and /home/someone/z');
check('any other profile folder becomes <user>, in Windows, MSYS and POSIX forms', (t.match(/<user>/g) || []).length === 4 && !/someone/.test(t), t);
check('Windows profile paths read C:\\Users\\<user> style: the name is gone and the rest of the path is kept', cleanPaths(win('C:', 'Users', 'someone', 'AppData', 'Roaming', 'Godot')) === '<user>' + B + 'AppData' + B + 'Roaming' + B + 'Godot');
check('text with no path is untouched', cleanPaths('commit b624340a, 44464417 bytes, sha256 55e8115c') === 'commit b624340a, 44464417 bytes, sha256 55e8115c');
check('cleaning twice is the same as once', cleanPaths(cleanPaths(scratch + ' ' + repo)) === cleanPaths(scratch + ' ' + repo));
check('the checker finds a path and says the line', leftover('a\n' + scratch + '\nb').length === 1 && leftover('a\n' + scratch + '\nb')[0].line === 2);
check('the checker finds none in cleaned text', leftover(cleanPaths(scratch + '\n' + repo + '\n/home/x/y')).length === 0);
check('"splitShare" and other words with letters of a name are not paths', leftover('splitShare ON data/camera/swing.json').length === 0);

// the tar.gz writer
const data = Buffer.from('hello world\n'.repeat(100));
const entries = [{ name: 'pkg', dir: true, mode: 0o755 }, { name: 'pkg/game.x86_64', data, mode: 0o755 }, { name: 'pkg/README.txt', data: Buffer.from('read me\n'), mode: 0o644 }];
const gz = targz(entries, 1700000000);
const got = readTarGz(gz);
check('the archive lists the folder and both files, in order', got.map((e) => e.name).join() === 'pkg/,pkg/game.x86_64,pkg/README.txt', got.map((e) => e.name).join());
check('the program keeps its executable bit (0755) and the text file does not (0644)', got[1].mode === 0o755 && got[2].mode === 0o644 && got[0].dir === true, JSON.stringify(got.map((e) => e.mode.toString(8))));
check('sizes are exact', got[1].size === data.length && got[2].size === 8);
check('the same inputs give the same bytes', targz(entries, 1700000000).equals(gz));
const raw = gunzipSync(gz);
check('the tar is a whole number of 512-byte blocks and ends with two empty ones', raw.length % 512 === 0 && raw.subarray(raw.length - 1024).every((b) => b === 0));
check('the file content is in the archive, padded to a block', raw.indexOf(data) === 512 * 2 && raw.subarray(512 * 2, 512 * 2 + data.length).equals(data));
let threw = false; try { const x = Buffer.from(raw); x[10] ^= 1; readTar(x); } catch { threw = true; }
check('a changed header fails its checksum', threw);
threw = false; try { header({ name: 'x'.repeat(101), size: 1, mode: 0o644, mtime: 0 }); } catch { threw = true; }
check('a name over 100 bytes is refused (the plain form only)', threw);
check('the format is ustar with a magic the system tar reads', raw.toString('ascii', 257, 262) === 'ustar');
check('an empty archive is two empty blocks', tarBuffer([]).length === 1024);
console.log(`record-paths selftest: ${n} checks, ${bad} failed`);
process.exit(bad ? 1 : 0);
