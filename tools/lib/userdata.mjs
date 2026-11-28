// The node side of tools/godot-run.sh: the environment of a game run whose every written folder is inside `dir`. A node tool that starts the engine or a built program passes this to spawn.
// An export under such an environment finds the engine's templates too: the installed template files are hard-linked into `dir` (read there, never written; nothing else of the real folder is touched).
import { copyFileSync, existsSync, linkSync, mkdirSync, readdirSync, statSync } from 'node:fs';
import { userInfo } from 'node:os';
import { join } from 'node:path';

/** Where the installed export templates are: ORB_TEMPLATES, the folder `base` points at, else (for this process's own environment) the OS's answer, which a moved APPDATA or HOME does not change. null when none. */
export function templatesDir(base = process.env) {
  const home = () => { try { return userInfo().homedir; } catch { return ''; } };
  const places = [
    base.ORB_TEMPLATES,
    base.APPDATA && join(base.APPDATA, 'Godot', 'export_templates'),
    base.XDG_DATA_HOME && join(base.XDG_DATA_HOME, 'godot', 'export_templates'),
    base.HOME && join(base.HOME, '.local', 'share', 'godot', 'export_templates'),
  ];
  if (base === process.env && home()) places.push(process.platform === 'win32' ? join(home(), 'AppData', 'Roaming', 'Godot', 'export_templates') : join(home(), '.local', 'share', 'godot', 'export_templates'));
  const full = (d) => { try { return readdirSync(d, { withFileTypes: true }).some((v) => v.isDirectory() && readdirSync(join(d, v.name)).length > 0); } catch { return false; } };
  return places.find((p) => p && full(p)) || null;
}

/** Puts the installed template files where an engine under userdataEnv(dir) looks. Hard links; with `copy`, a file that cannot be linked is copied. Returns the number placed; null when no templates are installed. */
export function linkTemplates(dir, base = process.env, { copy = true } = {}) {
  const src = templatesDir(base);
  if (!src) return null;
  const dst = process.platform === 'win32' ? join(dir, 'appdata', 'Godot', 'export_templates') : join(dir, 'xdg', 'godot', 'export_templates');
  let n = 0;
  for (const v of readdirSync(src, { withFileTypes: true })) {
    if (!v.isDirectory()) continue;
    mkdirSync(join(dst, v.name), { recursive: true });
    for (const f of readdirSync(join(src, v.name))) {
      const from = join(src, v.name, f), to = join(dst, v.name, f);
      if (existsSync(to) || !statSync(from).isFile()) continue;
      try { linkSync(from, to); n++; } catch { if (copy) { copyFileSync(from, to); n++; } }
    }
  }
  return n;
}

export function userdataEnv(dir, base = process.env) {
  try { linkTemplates(dir, base, { copy: false }); } catch { /* no templates is no reason to stop a run that exports nothing */ }
  return {
    ...base,
    APPDATA: join(dir, 'appdata'), LOCALAPPDATA: join(dir, 'localappdata'), HOME: join(dir, 'home'), USERPROFILE: join(dir, 'home'),
    XDG_DATA_HOME: join(dir, 'xdg'), XDG_CONFIG_HOME: join(dir, 'xdgconfig'), XDG_CACHE_HOME: join(dir, 'xdgcache'),
  };
}
export const USERDATA_VARS = ['APPDATA', 'LOCALAPPDATA', 'HOME', 'USERPROFILE', 'XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME'];
