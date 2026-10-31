#!/bin/bash
# SCRATCH: the swing test's tree: HEAD plus swing/, its main scene swapped, bake, import, web export. Below normal; one Godot at a time.
LN="$(cd "$(dirname "$0")" && pwd)"
LW="$(cd "${LN:?}" && pwd -W)"
R="C:/Users/itsha/Documents/Claude Proj/Breakers-Like"
GD="C:/Users/itsha/AppData/Local/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"
powershell -NoProfile -Command "(Get-Process -Id $(cat /proc/$$/winpid)).PriorityClass = 'BelowNormal'" 2>/dev/null
if [ ! -d "${LN:?}/sw/render" ]; then
	mkdir -p "${LN:?}/sw" && git -C "$R" archive HEAD | tar -x -C "${LN:?}/sw" || exit 1
	cp -r "${LN:?}/lc2/.godot" "${LN:?}/sw/.godot" 2>/dev/null
	echo "tree at $(git -C "$R" rev-parse --short=8 HEAD)"
fi
mkdir -p "${LN:?}/sw/swing"
cp "${LN:?}"/swing/*.gd "${LN:?}"/swing/*.gdshader "${LN:?}"/swing/*.gdshaderinc "${LN:?}/sw/swing/" || exit 1
cat > "${LN:?}/sw/swing/swing.tscn" <<'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://swing/swing.gd" id="1"]

[node name="Swing" type="Node3D"]
script = ExtResource("1")
EOF
python - "$LW/sw" <<'EOF'
import re, sys
root = sys.argv[1]
p = root + '/project.godot'
s = open(p, encoding='utf-8', newline='').read()
s = re.sub(r'run/main_scene="[^"]*"', 'run/main_scene="res://swing/swing.tscn"', s)
open(p, 'w', encoding='utf-8', newline='').write(s)
p = root + '/export_presets.cfg'
s = open(p, encoding='utf-8', newline='').read()
s = s.replace('include_filter="build_info.json"', 'include_filter="build_info.json,swing/*.bin,swing/*.json"')
open(p, 'w', encoding='utf-8', newline='').write(s)
EOF
timeout 1500 "$GD" --headless --path "$LW/sw" --import > "${LN:?}/sw.import.log" 2>&1
echo "import $? errors $(grep -a -c 'SCRIPT ERROR\|SHADER ERROR\|Parse Error' "${LN:?}/sw.import.log")"
grep -a 'SCRIPT ERROR\|SHADER ERROR\|Parse Error\|res://swing' "${LN:?}/sw.import.log" | head -12 | cut -c1-200
if [ "$1" = "bake" ]; then
	timeout 900 "$GD" --headless --path "$LW/sw" --script res://swing/bake.gd > "${LN:?}/sw.bake.log" 2>&1
	echo "bake $?"; grep -a "^RES\|SCRIPT ERROR\|at: " "${LN:?}/sw.bake.log" | head -8 | cut -c1-220
	timeout 600 "$GD" --headless --path "$LW/sw" --import > "${LN:?}/sw.import.log" 2>&1
fi
mkdir -p "${LN:?}/sw_site/play"
timeout 1500 "$GD" --headless --path "$LW/sw" --export-release Web "$LW/sw_site/play/index.html" > "${LN:?}/sw.export.log" 2>&1
echo "export $? errors $(grep -a -c 'SCRIPT ERROR\|SHADER ERROR\|Parse Error' "${LN:?}/sw.export.log")"
grep -a 'SCRIPT ERROR\|SHADER ERROR\|Parse Error' -A4 "${LN:?}/sw.export.log" | head -12 | cut -c1-200
ls -la "${LN:?}/sw_site/play" | cut -c25-80 | head -8
echo swmkdone
