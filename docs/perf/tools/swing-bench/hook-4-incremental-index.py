import sys
R = sys.argv[1]
def sub(path, a, b):
    s = open(R + "/" + path, encoding="utf-8", newline="").read()
    assert s.count(a) == 1, (path, a)
    open(R + "/" + path, "w", encoding="utf-8", newline="").write(s.replace(a, b))
sw = "sim/core/swing.gd"
sub(sw, "static var tus: int = 0", "static var incr: bool = false\nstatic var tus: int = 0")
# replace the crossing test: incremental path
sub(sw, "\t\tif not moved and mini(int(SimWrap.wrap(x0) / bw), buckets - 1) != mini(int(SimWrap.wrap(SimField.sx) / bw), buckets - 1):\n\t\t\tmoved = true\n",
"""\t\tvar k0: int = mini(int(SimWrap.wrap(x0) / bw), buckets - 1)
\t\tvar k1: int = mini(int(SimWrap.wrap(SimField.sx) / bw), buckets - 1)
\t\tif k0 != k1:
\t\t\tif incr:
\t\t\t\tif not moved:
\t\t\t\t\tS.bIdx = S.bIdx.duplicate()   # the outer array only: the index is shared by snapshots, so no bucket is written in place
\t\t\t\t\tmoved = true
\t\t\t\t_rebucket(S, i, k0, k1)
\t\t\telif not moved:
\t\t\t\tmoved = true
""")
sub(sw, "\tif moved:\n\t\tvar _ti: int = Time.get_ticks_usec()", "\tif moved and not incr:\n\t\tvar _ti: int = Time.get_ticks_usec()")
s = open(R + "/" + sw, encoding="utf-8", newline="").read()
s += """

## A building that crossed from bucket k0 to k1: both buckets are copied, then written, so the buckets a snapshot shares are never touched. A bucket stays in ascending index order, as buildIndex makes it.
static func _rebucket(S: SimState, i: int, k0: int, k1: int) -> void:
\tvar a: PackedInt32Array = S.bIdx[k0].duplicate()
\tvar p: int = a.find(i)
\tif p >= 0:
\t\ta.remove_at(p)
\tS.bIdx[k0] = a
\tvar b: PackedInt32Array = S.bIdx[k1].duplicate()
\tb.insert(b.bsearch(i), i)
\tS.bIdx[k1] = b
"""
open(R + "/" + sw, "w", encoding="utf-8", newline="").write(s)
print("ok")
