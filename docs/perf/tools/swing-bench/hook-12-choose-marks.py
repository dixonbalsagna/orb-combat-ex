# SCRATCH HOOK (a scratch tree only, after hook-11): statement-level timers inside DirLaunch.chooseLaunch, into DirSwing.pm (L1_head ... L5_score, predict).
#   python hook-12-choose-marks.py <tree>
import sys
root = sys.argv[1]
f = f'{root}/sim/director/launch.gd'
s = open(f, encoding='utf8').read()
T = 'Time.get_ticks_usec()'
def sub(a, b):
    global s
    assert s.count(a) == 1, (a[:70], s.count(a))
    s = s.replace(a, b)
mark = lambda name: f'\tDirSwing.pm["{name}"] = {T} - _l0\n\t_l0 = {T}\n'
sub('\tvar g: float = WorldTerrain.groundY(S, D.x)\n\tvar alt: float = D.y - g\n\tvar bio: String', f'\tvar _l0: int = {T}\n\tvar g: float = WorldTerrain.groundY(S, D.x)\n\tvar alt: float = D.y - g\n\tvar bio: String')
sub('\tvar hadBrunt: bool = false\n', mark('L1_head') + '\tvar hadBrunt: bool = false\n')
sub('\tfor sign in [-1.0, 1.0]:\n\t\tif fwdOnly and sign * f < 0.0:\n\t\t\tcontinue\n\t\t# The nearest mountainside', mark('L2_brunt') + '\tfor sign in [-1.0, 1.0]:\n\t\tif fwdOnly and sign * f < 0.0:\n\t\t\tcontinue\n\t\t# The nearest mountainside')
sub('\tif bon:\n\t\t_biomeCands(S, A, D, c, longOnly, fwdOnly,', mark('L3_mount') + '\tif bon:\n\t\t_biomeCands(S, A, D, c, longOnly, fwdOnly,')
sub('\tif not longOnly and not noKnock:\n\t\tc.append({"name": "KNOCK BACK"', mark('L4_biome') + '\tif not longOnly and not noKnock:\n\t\tc.append({"name": "KNOCK BACK"')
sub('\tvar preferW: float', mark('L4b_filters') + '\tvar preferW: float')
sub('\t# Stable sort by score, highest first', mark('L5_score') + '\t# Stable sort by score, highest first')
a = '\t\tvar p: Dictionary = predictFlight(S, D.x, D.y, WorldSlide.launchVX(k.ux, k.uy, force * fm * tierF), k.uy * force * fm * tierF, WorldSlide.launchTravel(k.ux, k.uy))\n\t\tvar street: bool = false\n'
sub(a, f'\t\tvar _pt: int = {T}\n' + a.split('\n\t\tvar street')[0] + f'\n\t\tDirSwing.pm["predict"] = DirSwing.pm.get("predict", 0) + {T} - _pt\n\t\tDirSwing.pm["predictN"] = DirSwing.pm.get("predictN", 0) + 1\n\t\tvar street: bool = false\n')
open(f, 'w', encoding='utf8').write(s)
print('hook-12 applied')
