#!/bin/bash
# THE ONE WAY a session or a script starts the game (Tools, 2026-11-28; the EP's brief: no game run started by any session may touch Orb's real data folder).
#
#   bash tools/godot-run.sh --path . --script res://render/tools/sky_check.gd          any Godot arguments; --headless is added
#   G="$PWD/tools/godot-run.sh"; "$G" --path . --import                               where a script keeps the engine in a variable
#   bash tools/godot-run.sh --program <exported program> -- --seed=4 --bench           a built program, kept away the same way
#   eval "$(bash tools/godot-run.sh --print-env)"                                     for tools that start the engine themselves: moves user:// for everything this shell starts
#   bash tools/godot-run.sh --where                                                   the data folder this shell's runs use
#   bash tools/godot-run.sh --fresh <anything above>                                  a NEW EMPTY data folder for this run (or ORB_FRESH=1): for gates and shards, below
#
# What it does: every folder the game writes to (APPDATA, LOCALAPPDATA, HOME, USERPROFILE and the XDG folders) is moved inside a scratch folder of this session, then the engine REPLACES this shell
# (exec: a `timeout` or a stop reaches the engine itself, and its output and exit code are its own).
#   ORB_RUN_DATA    the scratch data folder (default: <temp>/orb-run-data/<session id>); kept between runs of a session, so a planet baked once is not baked again. Delete it to start clean.
#   ORB_GODOT_EXE   the engine (default: GODOT when it is not this script, then the usual 4.7.2 console build on this PC, then `godot` on the PATH)
# A reused data folder keeps the game's caches, and those are keyed by DATA, NOT CODE: a gate or a shard that must see what the code does now takes a fresh folder (--fresh), or a moved golden can pass.
# An export needs the engine's export templates, which live under the real APPDATA: that one folder's files are hard-linked into the run's data folder (copied only for an export, when a link cannot be made),
# read there, never written; nothing else of the real folder is touched. They are found even when this shell's environment has been moved already: ORB_TEMPLATES, then this environment's, then the OS's own answer.
set -u
refuse() { echo "godot-run REFUSED: $*" >&2; exit 2; }
self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
win=0; command -v cygpath > /dev/null 2>&1 && win=1
posix() { if [ "$win" = 1 ]; then cygpath -u "$1"; else printf '%s' "$1"; fi; }
native() { if [ "$win" = 1 ]; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
lower() { printf '%s' "$1" | tr 'A-Z\\' 'a-z/'; }

fresh="${ORB_FRESH:-}"
if [ "${1:-}" = "--fresh" ]; then fresh=1; shift; fi
data="${ORB_RUN_DATA:-${TMPDIR:-/tmp}/orb-run-data/${CLAUDE_CODE_SESSION_ID:-shell}}"
data="$(posix "$data")"
case "$data" in /*) ;; *) data="$(pwd)/$data" ;; esac
[ -n "$fresh" ] && [ "$fresh" != 0 ] && data="${data%/}/fresh-$(date +%Y%m%d-%H%M%S)-$$-$RANDOM"

# the folders that hold a person's real game data on this machine, as the environment says NOW (before anything is moved)
real_roaming="${APPDATA:+$(posix "$APPDATA")}"
real_xdg="${XDG_DATA_HOME:-${HOME:-}/.local/share}"; real_xdg="$(posix "$real_xdg")"
for r in "$real_roaming/Godot" "$real_xdg/godot"; do
  [ "$r" = "/Godot" ] && continue
  case "$(lower "$data")/" in "$(lower "$r")"/*) case "$(lower "$r")" in *orb-run-data*) ;; *) refuse "ORB_RUN_DATA is inside a real data folder ($r)" ;; esac ;; esac
done
case "$(lower "$data")" in */app_userdata*) case "$(lower "$data")" in *orb-run-data*) ;; *) refuse "ORB_RUN_DATA is an app_userdata folder" ;; esac ;; esac

if [ "${1:-}" = "--where" ]; then native "$data"; echo; exit 0; fi
mkdir -p "$data/appdata" "$data/localappdata" "$data/home" "$data/xdg" "$data/xdgconfig" "$data/xdgcache" || refuse "the scratch data folder cannot be made: $data"

# the installed export templates, wherever this shell's environment points now
os_templates() {
  if [ "$win" = 1 ]; then printf '%s/Godot/export_templates' "$(cygpath -u -F 26 2>/dev/null)"; return; fi
  h="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6)"; [ -n "$h" ] && printf '%s/.local/share/godot/export_templates' "$h"
}
templates() {
  for c in "${ORB_TEMPLATES:-}" "${real_roaming:+$real_roaming/Godot/export_templates}" "$real_xdg/godot/export_templates" "$(os_templates)"; do
    [ -n "$c" ] || continue
    c="$(posix "$c")"
    for v in "$c"/*/; do [ -d "$v" ] && [ -n "$(ls "$v" 2>/dev/null)" ] && { printf '%s' "$c"; return 0; }; done
  done
  return 1
}
# put_templates [copy]: hard-link each installed template file into the run's data folder; with "copy", copy one that cannot be linked
put_templates() {
  src="$(templates)" || return 1
  if [ "$win" = 1 ]; then dst="$data/appdata/Godot/export_templates"; else dst="$data/xdg/godot/export_templates"; fi
  for v in "$src"/*/; do
    v="${v%/}"; [ -d "$v" ] || continue; mkdir -p "$dst/${v##*/}"
    for f in "$v"/*; do
      [ -f "$f" ] || continue; t="$dst/${v##*/}/${f##*/}"; [ -e "$t" ] && continue
      ln "$f" "$t" 2>/dev/null && continue
      [ "${1:-}" = copy ] && cp "$f" "$t"
    done
  done
  return 0
}
put_templates || true   # every run: a tool started under this environment may export, and finds them here
if [ "${1:-}" = "--print-env" ]; then
  # only the two that decide where user:// is: a shell's git, npm and the rest keep their own settings
  printf "export APPDATA='%s' XDG_DATA_HOME='%s'\n" "$(native "$data/appdata")" "$(native "$data/xdg")"
  exit 0
fi

program=""
if [ "${1:-}" = "--program" ]; then [ -n "${2:-}" ] || refuse "--program takes the exported program's path"; program="$2"; shift 2; fi

exe="$program"
if [ -z "$exe" ]; then
  exe="${ORB_GODOT_EXE:-}"
  if [ -z "$exe" ] && [ -n "${GODOT:-}" ]; then case "$(lower "$GODOT")" in *godot-run.sh) ;; *) exe="$GODOT" ;; esac; fi
  if [ -z "$exe" ] && [ -n "${LOCALAPPDATA:-}" ]; then u="$(posix "$LOCALAPPDATA")/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"; [ -f "$u" ] && exe="$u"; fi
  [ -z "$exe" ] && exe="$(command -v godot || true)"
  [ -n "$exe" ] || refuse "no engine: set ORB_GODOT_EXE (or GODOT) to the Godot 4.7.2 console build"
fi
[ "$(lower "$(posix "$exe")")" = "$(lower "$self")" ] && refuse "the engine named is this script"

headless=0 exporting=0 userargs=0
for a in "$@"; do
  [ "$a" = "--" ] && userargs=1
  [ "$userargs" = 1 ] && continue
  case "$a" in
    --headless) headless=1 ;;
    --display-driver|--display-driver=*) refuse "$a: runs are headless only (pictures come from the web build, through tools/machine)" ;;
    --export-release|--export-debug|--export-pack|--export-patch) exporting=1 ;;
  esac
done

if [ "$exporting" = 1 ]; then put_templates copy || refuse "no export templates found (ORB_TEMPLATES, $real_roaming/Godot/export_templates, $real_xdg/godot/export_templates, or the OS's own folder)"; fi

export APPDATA="$(native "$data/appdata")" LOCALAPPDATA="$(native "$data/localappdata")" HOME="$(native "$data/home")" USERPROFILE="$(native "$data/home")"
export XDG_DATA_HOME="$(native "$data/xdg")" XDG_CONFIG_HOME="$(native "$data/xdgconfig")" XDG_CACHE_HOME="$(native "$data/xdgcache")"
if [ "$headless" = 1 ]; then exec "$exe" "$@"; else exec "$exe" --headless "$@"; fi
