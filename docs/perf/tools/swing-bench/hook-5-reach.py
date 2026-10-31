import sys
R = sys.argv[1]
def sub(path, a, b):
    s = open(R + "/" + path, encoding="utf-8", newline="").read()
    assert s.count(a) == 1, (path, a[:60])
    open(R + "/" + path, "w", encoding="utf-8", newline="").write(s.replace(a, b))
sub("sim/core/swing.gd", "const POSE_REACH: float = 15000.0", "static var POSE_REACH: float = 15000.0")
print("ok")
