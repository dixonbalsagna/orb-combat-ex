// SCRATCH HOOK (scratch export only): folds the freeze breadcrumbs (docs/perf/web-shell/ocx-crumbs.js) into the scratch tree's export_presets.cfg head_include, through web-head.mjs --crumbs --cfg,
// so a scratch export carries them without the repo's export preset changing. Apply before the export (it edits the scratch tree only).
import { spawnSync } from 'node:child_process';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(process.argv[2]);
const r = spawnSync(process.execPath, [join(here, '..', 'web-head.mjs'), '--write', '--crumbs', '--cfg', join(root, 'export_presets.cfg')], { encoding: 'utf8' });
if (r.status) throw new Error('web-head.mjs: ' + (r.stderr || r.stdout));
console.log('crumbs folded into the scratch export preset:', r.stdout.trim());
