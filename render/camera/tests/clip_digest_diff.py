"""Compare two clip_digest.gd outputs: for each clip and mode, how many ticks differ and from which to which tick.
   python render/camera/tests/clip_digest_diff.py A.txt B.txt
A clip with no differing tick is the same camera tick for tick (the same picture for a frame comparison)."""
import sys


def load(p):
    d = {}
    for line in open(p, encoding="utf-8"):
        parts = line.rstrip("\n").split("\t")
        if len(parts) == 4:
            d.setdefault((parts[0], parts[1]), {})[int(parts[2])] = parts[3]
    return d


a, b = load(sys.argv[1]), load(sys.argv[2])
for key in sorted(set(a) | set(b)):
    ta, tb = a.get(key, {}), b.get(key, {})
    ticks = sorted(set(ta) | set(tb))
    diff = [t for t in ticks if ta.get(t) != tb.get(t)]
    if not diff:
        print("%-26s %-8s same over %d ticks" % (key[0], key[1], len(ticks)))
    else:
        print("%-26s %-8s DIFFERS on %d of %d ticks, first %d, last %d" % (key[0], key[1], len(diff), len(ticks), diff[0], diff[-1]))
