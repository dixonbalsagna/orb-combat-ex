// Self-test of the pure parts of tools/desktop-local-build.mjs (Tools, 2026-11-14): the package names and the bench hash reading. The build itself needs Godot and a Windows PC and is checked by running it.
//   node tools/desktop-local-build-selftest.mjs
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { names, hashLine, platformsOf, canPlay } from './desktop-local-build.mjs';
let bad = 0, n = 0;
const check = (name, ok, extra) => { n++; if (!ok) { bad++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const x = names('148f4e16');
const lx = names('148f4e16', 'linux');
check('the file name says it is a private build for the two, and names the commit (Legal RL-262 section 1, point 4)', /ORB-PRIVATE/.test(x.zip) && x.zip.endsWith('-148f4e16.zip') && x.folder === 'orb-combat-ex-ORB-PRIVATE-windows-x86_64');
check('the default folder is under homework/ (git-ignored), named for the commit and ORB-PRIVATE', x.defaultOut.split(String.fromCharCode(92)).join('/').endsWith('/homework/Files/desktop/148f4e16-ORB-PRIVATE'));
check('the Linux package is a .tar.gz named for the platform, the commit and the private line; the Windows one stays a .zip', lx.archive === 'orb-combat-ex-ORB-PRIVATE-linux-x86_64-148f4e16.tar.gz' && lx.folder === 'orb-combat-ex-ORB-PRIVATE-linux-x86_64' && x.archive.endsWith('.zip') && x.zip === x.archive);
check('--platform names windows, linux or both and nothing else', platformsOf('both').join() === 'windows,linux' && platformsOf('linux').join() === 'linux' && platformsOf('windows').join() === 'windows' && platformsOf('mac') === null && platformsOf('') === null);
check('a program is played only on its own kind of machine (a Linux ELF is not started on Windows)', canPlay('windows', 'win32') && canPlay('linux', 'linux') && !canPlay('linux', 'win32') && !canPlay('windows', 'linux') && !canPlay('windows', 'darwin'));
check('the bench hash line is read from the output, and a missing one is null', hashLine('boot\ngameplay hash at tick 2400: 7b8c8aff21d1a5cb\nbye') === 'gameplay hash at tick 2400: 7b8c8aff21d1a5cb' && hashLine('nothing') === null);
check('two different hashes are not equal lines', hashLine('gameplay hash at tick 2400: aa') !== hashLine('gameplay hash at tick 2400: bb'));
const src = readFileSync(join(dirname(fileURLToPath(import.meta.url)), 'desktop-local-build.mjs'), 'utf8');
check('the build reads the commit by git archive, never the working tree, and never runs write-build-info.mjs in the shared folder', /git', \['-C', REPO, 'archive'/.test(src) && /join\(tree, 'tools', 'write-build-info.mjs'\)/.test(src) && !/join\(REPO, 'tools', 'write-build-info/.test(src));
check('the owner notice and the private line are the only notice arguments, and no upload or publish is in it', /OWNER_NOTICE = 'site-interim-owner.json'/.test(src) && !/upload|gh release|butler/i.test(src.replace(/never a public (link|upload)|not made or kept by a CI run/gi, '')));
check("the record is cleaned of this PC's folder paths as it is written, and the Linux archive is written by the tar writer (the mode of each file is named)", /cleanPaths\(rec\.join/.test(src) && /targz\(folderEntries\(pkg, n\.folder, \[program\]\), mtime\)/.test(src));
console.log(`desktop-local-build selftest: ${n} checks, ${bad} failed`);
process.exit(bad ? 1 : 0);
