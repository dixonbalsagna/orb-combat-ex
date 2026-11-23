# The band's depth steps within the contrast budget (the signature clip on Art's tone-on-tone ladders, 2026-10-27: its
# worst second was the desert's mid on the middle step against the front step, 0.52 against 0.62, as a pane's camera
# moved). DEPTH_STEP 1.1 / 0.94 -> 1.07 / 0.97: a step is about 0.06 of relative luminance on the desert, inside
# RenderLook.PATTERN_BUDGET, and the band still reads near and far in three hard steps.   python h112_depthstep.py <tree>
import sys
root = sys.argv[1]


def patch(rel, pairs):
    p = root + '/' + rel
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (rel, a[:70], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print(rel, 'ok')


patch('render/core/look.gd', [
    ("const DEPTH_STEP := Vector2(1.1, 0.94)\n",
     "const DEPTH_STEP := Vector2(1.07, 0.97)   # a step within PATTERN_BUDGET on the brightest ground (1.1 / 0.94 until 2026-10-27: a step on Art's desert was 0.1, and a pane's camera move flipped it)\n"),
])
patch('render/shaders/terrain.gdshaderinc', [
    ("uniform vec2 depth_step = vec2(1.1, 0.94);", "uniform vec2 depth_step = vec2(1.07, 0.97);"),
])
patch('docs/rendering/biomes.md', [
    ("- **Depth.** The band's value steps by depth in three hard steps (`DEPTH_STEP`: 1.1 at the front to 0.94 at the back), so open flat ground (a desert) still reads near and far.",
     "- **Depth.** The band's value steps by depth in three hard steps (`DEPTH_STEP`: 1.07 at the front to 0.97 at the back), so open flat ground (a desert) still reads near and far. Each step stays inside the contrast budget on the brightest ground: at 1.1 to 0.94 (until 2026-10-27) a step on Art's tone-on-tone desert was 0.1 of relative luminance, and a pane's camera move flipped it in the `signature` clip."),
])
print('h112 ok')
