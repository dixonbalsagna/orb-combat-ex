import sys
R = sys.argv[1]
def sub(path, a, b):
    s = open(R + "/" + path, encoding="utf-8", newline="").read()
    assert s.count(a) == 1, (path, a)
    open(R + "/" + path, "w", encoding="utf-8", newline="").write(s.replace(a, b))
sub("sim/core/swing.gd", "static var tus: int = 0", "static var tus: int = 0\nstatic var tpo: int = 0\nstatic var npo: int = 0\nstatic var nidx: int = 0\nstatic var tidx: int = 0\nstatic var tlim: int = 0\nstatic var trise: int = 0")
sub("sim/core/swing.gd", "\tvar list = range(n) if all else WorldStructures.near(S, px, POSE_REACH)\n", "\tvar _tp: int = Time.get_ticks_usec()\n\tvar list = range(n) if all else WorldStructures.near(S, px, POSE_REACH)\n\tnpo += list.size()\n")
sub("sim/core/swing.gd", "\tif moved:\n\t\tWorldStructures.buildIndex(S)", "\ttpo += Time.get_ticks_usec() - _tp\n\tif moved:\n\t\tvar _ti: int = Time.get_ticks_usec()\n\t\tnidx += 1\n\t\tWorldStructures.buildIndex(S)\n\t\ttidx += Time.get_ticks_usec() - _ti\n\t\treturn")
sub("sim/core/swing.gd", "\tvar lim: float = _limit(S, px)\n\tvar k: float = 1.0\n", "\tvar _tl: int = Time.get_ticks_usec()\n\tvar lim: float = _limit(S, px)\n\ttlim += Time.get_ticks_usec() - _tl\n\tvar k: float = 1.0\n")
sub("sim/core/swing.gd", "\tk = _riseBackstop(S, px, deg1, k)\n", "\tvar _tr: int = Time.get_ticks_usec()\n\tk = _riseBackstop(S, px, deg1, k)\n\ttrise += Time.get_ticks_usec() - _tr\n")
print("ok")
