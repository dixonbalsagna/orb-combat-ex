// The node side of tools/godot-run.sh: the environment of a game run whose every written folder is inside `dir`. A node tool that starts the engine or a built program passes this to spawn. Pure.
import { join } from 'node:path';

export function userdataEnv(dir, base = process.env) {
  return {
    ...base,
    APPDATA: join(dir, 'appdata'), LOCALAPPDATA: join(dir, 'localappdata'), HOME: join(dir, 'home'), USERPROFILE: join(dir, 'home'),
    XDG_DATA_HOME: join(dir, 'xdg'), XDG_CONFIG_HOME: join(dir, 'xdgconfig'), XDG_CACHE_HOME: join(dir, 'xdgcache'),
  };
}
export const USERDATA_VARS = ['APPDATA', 'LOCALAPPDATA', 'HOME', 'USERPROFILE', 'XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME'];
