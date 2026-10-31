import sys
R = sys.argv[1]
def sub(path, a, b):
    s = open(R + "/" + path, encoding="utf-8", newline="").read()
    assert s.count(a) == 1, (path, a)
    open(R + "/" + path, "w", encoding="utf-8", newline="").write(s.replace(a, b))
sub("sim/core/sim.gd", "\t\tSimSwing.tick(S)   # the turntable: the line turns before anyone reads it this tick", "\t\tvar _t0: int = Time.get_ticks_usec()\n\t\tSimSwing.tick(S)\n\t\tSimSwing.tus += Time.get_ticks_usec() - _t0")
sub("sim/core/swing.gd", "static var ticks: int = 0", "static var tus: int = 0\nstatic var ticks: int = 0")
sub("sim/core/field.gd", "static var _far: int = 0", "static var reads: int = 0\nstatic var _far: int = 0")
sub("sim/core/field.gd", "\tvar qx: float = ox\n\tvar qy: float = oy\n\tvar qz: float = oz\n\tWorldField.sample(_F, qx, qy, qz, step)", "\treads += 1\n\tvar qx: float = ox\n\tvar qy: float = oy\n\tvar qz: float = oz\n\tWorldField.sample(_F, qx, qy, qz, step)")
print("patched")
