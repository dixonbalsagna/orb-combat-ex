"""Window 16 (cont.): the function that reads a wreck's mass is wreckMass too.   python mk_w16e.py <root>   (after mk_w16d.py)"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def wrecks_gd(s):
    s = rep(s, "static func mass(b) -> float:", "static func wreckMass(b) -> float:")
    n = s.count("mass(b)")
    s = s.replace("var m: float = mass(b)", "var m: float = wreckMass(b)").replace("mass(b) / K_B_REF", "wreckMass(b) / K_B_REF")
    assert "mass(b)" not in s.replace("wreckMass(b)", ""), "a call of mass(b) is left"
    return s


def wrecks_check(s):
    s = s.replace("WorldWrecks.mass(", "WorldWrecks.wreckMass(")
    s = s.replace('print("  houses %d: mass %.2f to %.2f (median %.2f); towers %d: %.2f to %.2f (median %.2f); lifts %s"', 'print("  houses %d: wreckMass %.2f to %.2f (median %.2f); towers %d: %.2f to %.2f (median %.2f); lifts %s"')
    s = s.replace("# the masses of the city's buildings, whole", "# the wreckMass of the city's buildings, whole")
    return s


rw(R, 'sim/world/wrecks.gd', wrecks_gd)
rw(R, 'sim/world/tools/wrecks_check.gd', wrecks_check)
print('w16 wreckMass function applied')
