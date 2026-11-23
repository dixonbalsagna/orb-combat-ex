# The docs line for h109 (the ground's faces within the contrast budget).   python h109_doc.py <tree>
import sys
root = sys.argv[1]
p = root + '/docs/rendering/biomes.md'
s = open(p, encoding='utf-8').read()
a = """- **Depth.** The band's value steps by depth in three hard steps (`DEPTH_STEP`: 1.1 at the front to 0.94 at the back), so open flat ground (a desert) still reads near and far. The tones themselves are the light. The far land keeps its own colour and shading until window 3 makes it Art's ladder.
"""
b = a + """- **The contrast budget on the faces** (2026-10-27; Tools' bisect of the `signature` clip, `docs/tools/signature-bisect-2026-10-27.md`).
  - **Why.** Open ground fills most of a frame, so a face whose tone turns as the camera pans or cuts flips every pixel it covers. Art's desert shade drew 0.29 of relative luminance under its mid at the front step (0.33 against 0.62), and the split view's pan across the dunes failed the clip in normal mode (3.5).
  - **The rule.** Each biome's lit and shade ground faces are held within `PATTERN_BUDGET` (0.085) of its mid face on the screen, where the band is lightest (the front step). That is the facades' tone-on-tone rule.
  - **How.** `RenderBiomeLook.held` scales a face along its own colour, once, in the palette, so it keeps Art's hue and costs the shader nothing. The facets stay, tone on tone: the desert's shade is a deeper ochre of nearly the mid's value, not a dark band.
  - **Not held:** the ices (`HOLD_SKIP`). Their ground is white over slate by Art's design, 0.72 apart, and scaling the slate would turn it bright blue. That is Art's call.
  - The rock, the subsoil and the depth steps are as they were.
  - `--nofacethold` draws Art's tones as written, for the A/B.
"""
assert s.count(a) == 1
s = s.replace(a, b)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('h109_doc ok')
