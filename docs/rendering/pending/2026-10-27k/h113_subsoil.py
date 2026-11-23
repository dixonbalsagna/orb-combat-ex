# Art's second pass for the signature clip (docs/art/ground-ladders.md; data/art/biomes.json palette.subsoil_faces):
# (a) Art's grant into biome_look.gd (docs/art/pending/biome-look-subsoil-faces.patch, accepted as written): a crater's
#     inside takes Art's three authored faces where the data gives them;
# (b) the strata lines darken a face by STRATA_DARK of its value, per biome (the palette's strata row, blue): the
#     desert's 0.9 on Art's terracotta rock at sand value (0.62 drew a step of about 0.35 there); the others 0.62 as before;
# (c) a crater's inside steps by depth as the ground does (Art cut its faces within about 0.1 of the sand at each step).
#   python h113_subsoil.py <tree> <repo>   (main 9d367592)
import subprocess, sys
root, repo = sys.argv[1], sys.argv[2]
r = subprocess.run(['git', '-c', 'core.autocrlf=false', 'apply', repo + '/docs/art/pending/biome-look-subsoil-faces.patch'], cwd=root, capture_output=True, text=True)
assert r.returncode == 0, r.stderr
print("Art's patch ok")


def patch(rel, pairs):
    p = root + '/' + rel
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (rel, a[:70], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print(rel, 'ok')


patch('render/core/biome_look.gd', [
    ("""const STRATA: Array = ["desert", "mountains", "volcanic", "highland"]
""", """const STRATA: Array = ["desert", "mountains", "volcanic", "highland"]
## A strata line's value against its face (the palette's strata row, blue; terrain.gdshaderinc): STRATA_LINE unless the
## biome is named. The desert's rock is Art's terracotta at the sand's value (docs/art/ground-ladders.md), where 0.62 drew
## a line a step of about 0.35 under its face; at 0.9 the line stays a thin hard line, a tenth or so under it.
const STRATA_LINE: float = 0.62
const STRATA_DARK: Dictionary = {"desert": 0.9}
"""),
    ("""	out.append(Color(1.0 if STRATA.has(name) else 0.0, float(ROCK_ABOVE.get(name, 0.0)) / 10000.0, 0.0, 1.0))
""", """	out.append(Color(1.0 if STRATA.has(name) else 0.0, float(ROCK_ABOVE.get(name, 0.0)) / 10000.0, float(STRATA_DARK.get(name, STRATA_LINE)), 1.0))
"""),
])
patch('render/shaders/terrain.gdshaderinc', [
    ("""	vec3 rk = biome_tone(zf < 0.5 ? v_ba : v_bb, 11);   // r: the rock has strata; g: a rocky biome's height (/ 10,000) from which rock starts at gentler slopes
""", """	vec3 rk = biome_tone(zf < 0.5 ? v_ba : v_bb, 11);   // r: the rock has strata; g: a rocky biome's height (/ 10,000) from which rock starts at gentler slopes; b: a strata line's value against its face (RenderBiomeLook.STRATA_DARK)
"""),
    ("""		c = mix(c, c * 0.62, ln);
""", """		c = mix(c, c * rk.b, ln);
"""),
    ("""		vec3 earth = mix(biome_tone(v_ba, 6 + tone), biome_tone(v_bb, 6 + tone), zf);   // a crater's inside: the subsoil (Art), not the surface
""", """		vec3 earth = mix(biome_tone(v_ba, 6 + tone), biome_tone(v_bb, 6 + tone), zf);   // a crater's inside: the subsoil (Art), not the surface
		earth *= mix(depth_step.x, depth_step.y, floor(clamp(v_back, 0.0, 0.999) * 3.0) * 0.5);   // ... stepped by depth as the ground is (Art cut its faces against the sand at each step)
"""),
])
patch('docs/rendering/biomes.md', [
    ("""- **Strata.** Thin dark lines every `STRATA_H` (220) units of height run on rock that carries them (desert, mountains, volcanic, highland), where the rock's bands dominate. They leave out where they would crowd closer than a few pixels.
""", """- **Strata.** Thin dark lines every `STRATA_H` (220) units of height run on rock that carries them (desert, mountains, volcanic, highland), where the rock's bands dominate. They leave out where they would crowd closer than a few pixels. A line darkens its face to `STRATA_LINE` (0.62) of its value, the desert's to 0.9 (`STRATA_DARK`): Art's desert rock is terracotta at the sand's value (2026-10-27), and 0.62 drew a step of about 0.35 there.
"""),
    ("""**Damage** (Art's grammar):
- **A crater's inside** is the subsoil's tone, not the surface's.""", """**Damage** (Art's grammar):
- **A crater's inside** is the subsoil's tone, not the surface's. Where Art's data gives a biome `palette.subsoil_faces`, its lit, mid and shade are those three (the desert and the beach, 2026-10-27, cut within about 0.1 of the sand). Otherwise they are the subsoil toward Art's lite and dark. The inside steps by depth as the ground does."""),
])
print('h113 ok')
