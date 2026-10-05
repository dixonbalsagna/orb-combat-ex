#!/bin/sh
# mk_hv.sh <name> <reach4> <slam>
SP="C:/Users/itsha/AppData/Local/Temp/claude/C--Users-itsha-Documents-Claude-Proj-Breakers-Like/d5f87b8b-81e8-47eb-890c-b2d3fea2905c/scratchpad"
G="/c/Users/itsha/AppData/Local/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"
mkdir -p "$SP/$1" && cp -r "$SP/h0/." "$SP/$1/" && cp "$SP/hy.gd" "$SP/$1/"
for f in KAI VORR; do sed -i "s/\"structure\": \[1.0, 1.0, 1.6, 2.8\]/\"structure\": [1.0, 1.0, 1.6, $2]/" "$SP/$1/data/fighters/$f/ladder.json"; done
sed -i "s/\"slam\": 0.9,/\"slam\": $3,/" "$SP/$1/data/biomes/contact.json"
(cd "$SP/$1" && timeout 300 "$G" --headless --path . --import >/dev/null 2>&1)
