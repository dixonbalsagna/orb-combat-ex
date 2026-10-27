# GRANT (World's data/biomes/rings.json and sim/world/epoch.gd, on World's gen2-read-speed-b; the EP: "you add the key
# and its schema line when you flip it", and a gen 1 calm turn must not change at all, hash included):
#   - rings.json turn.warmTotal 1: a pick's k is the total a tick across the rings it warms, each reading its share;
#   - WorldEpoch._share shares k only on a gen 2 planet (the step binds the match's generation), so a gen 1 pick's k is
#     each ring's, as always, whatever the switch says.
# Usage: python grant_world.py <repo root>
import json, os, sys
os.chdir(sys.argv[1])
p = 'data/biomes/rings.json'
s = open(p, encoding='utf-8').read()
assert '"warmTotal"' not in s, 'warmTotal is there already'
a = '    "fallbackDeg": 2.5,\n'
assert s.count(a) == 1
s = s.replace(a, a + '    "warmTotal": 1,\n')
open(p, 'w', encoding='utf-8', newline='\n').write(s)
json.loads(s)

p = 'sim/world/epoch.gd'
s = open(p, encoding='utf-8').read()
a = '\tif int(data().get("warmTotal", 0)) == 1 and E.warm.size() > 1:\n'
assert s.count(a) == 1, "World's gen2-read-speed-b first"
s = s.replace(a, '\tif int(data().get("warmTotal", 0)) == 1 and E.warm.size() > 1 and WorldClimate.genNow() >= 2:   # gen 2 only: a gen 1 pick\'s k is each ring\'s, as always\n')
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("World: rings.json turn.warmTotal 1, shared on gen 2 only")
