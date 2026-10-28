#!/bin/bash
# Native A/B of an engine patch on the GLES3 (Compatibility) renderer, for a Linux box with Xvfb and Mesa (a cloud session):
# runs the same seeded match on two Linux export templates built from the same source (stock and patched), with Godot's
# and Mesa's shader caches off (the web has neither), and prints, for each, the programs linked, the link wait, the
# gameplay hash and the last frame's hash. Godot's desktop GL and WebGL share the driver code (drivers/gles3), so this
# proves which programs compile and that the picture is the same; the web's own timings stay with the local bench.
#
#   bash tools/engine/check/native-ab.sh <stock template> <patched template> <game.pck> [frames] [seed]
#
# The templates: scons platform=linuxbsd target=template_release in the unpacked 4.7.2 source, once as is and once with
# the patch applied (an incremental rebuild). The pack: "$GODOT" --headless --path . --export-pack "Windows Desktop" game.pck
# (a pack is platform-neutral here). Each run leaves Mesa's shader_test captures, the link log and the shot in $OUT.
set -euo pipefail
stock=$1; patched=$2; pck=$3; frames=${4:-300}; seed=${5:-12345}
here=$(cd "$(dirname "$0")" && pwd)
OUT=${OUT:-$(mktemp -d)}; mkdir -p "$OUT"
gcc -shared -fPIC -O2 -o "$OUT/linkcount.so" "$here/linkcount.c" -ldl
cache="$HOME/.local/share/godot/app_userdata/Orb Combat EX/shader_cache"
for b in stock patched; do
  bin=$([ $b = stock ] && echo "$stock" || echo "$patched")
  d="$OUT/$b"; rm -rf "$d"; mkdir -p "$d"
  cp "$bin" "$d/godot"; cp "$pck" "$d/godot.pck"   # a template loads the pack named after itself
  rm -rf "$cache"
  timeout 1200 xvfb-run -a -s "-screen 0 1280x720x24" env MESA_SHADER_CACHE_DISABLE=true MESA_SHADER_CAPTURE_PATH="$d" \
    LINKCOUNT_OUT="$d/links.txt" LD_PRELOAD="$OUT/linkcount.so" "$d/godot" --rendering-driver opengl3 --resolution 1280x720 \
    --fixed-fps 60 -- --frames="$frames" --seed="$seed" --nointro --shot="$d/shot.png" > "$d/run.log" 2>&1
  echo "$b: links $(wc -l < "$d/links.txt"), link wait $(awk '{s+=$3} END{printf "%.0f", s}' "$d/links.txt") ms," \
    "$(grep -o 'gameplay hash.*' "$d/run.log"), shot $(sha256sum "$d/shot.png" | cut -c1-16)"
  (cd "$d" && for f in *.shader_test; do sed 1,3d "$f" | sha1sum | cut -c1-40; done | sort -u > "$OUT/$b.programs")
done
echo "patched programs that stock never linked: $(comm -23 "$OUT/patched.programs" "$OUT/stock.programs" | wc -l) (0 expected)"
echo "output: $OUT"
