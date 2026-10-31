# SCRATCH HOOK (a scratch tree only, after hook-11): statement-level timers inside DirLaunch._biomeCandsRead, into DirSwing.pm (B_cliff, B_ice_marsh, B_tree, B_skim, B_downhill).
#   python hook-13-biome-marks.py <tree>
import sys
f = sys.argv[1] + '/sim/director/launch.gd'
s = open(f, encoding='utf8').read()
T = 'Time.get_ticks_usec()'
def sub(a, b):
    global s
    assert s.count(a) == 1, (a[:60], s.count(a))
    s = s.replace(a, b)
def mk(n):
    return '\tDirSwing.pm["' + n + '"] = ' + T + ' - _bt\n\t_bt = ' + T + '\n'
sub('\tvar alt: float = D.y - g\n\tvar q: Dictionary = cd.get("CLIFFSIDE", {})\n', '\tvar alt: float = D.y - g\n\tvar _bt: int = ' + T + '\n\tvar q: Dictionary = cd.get("CLIFFSIDE", {})\n')
sub('\tif longOnly:\n\t\treturn\n\tvar sea: bool = WorldTerrain.seaAt(S, D.x)\n', mk('B_cliff') + '\tif longOnly:\n\t\treturn\n\tvar sea: bool = WorldTerrain.seaAt(S, D.x)\n')
sub('\tq = cd.get("TREE LINE", {})\n', mk('B_ice_marsh') + '\tq = cd.get("TREE LINE", {})\n')
sub('\tq = cd.get("SKIM ASHORE", {})\n', mk('B_tree') + '\tq = cd.get("SKIM ASHORE", {})\n')
sub('\tq = cd.get("DOWNHILL", {})\n', mk('B_skim') + '\tq = cd.get("DOWNHILL", {})\n')
sub('\tvar vq: Dictionary = cd.get("VENT LIFT", {})\n', mk('B_downhill') + '\tvar vq: Dictionary = cd.get("VENT LIFT", {})\n')
open(f, 'w', encoding='utf8').write(s)
print('hook-13 applied')
