"""Modelled misreads of the left stick's direction at LT's dodge edge (R34). Synthetic thumbs; the capture tool's measure replaces it."""
import math, random

DZ = 0.20           # the left stick's dead zone
MAG = 0.60          # a lean must reach this (rescaled) to pick a direction
VERT = 1.5          # vertical wins only when |y| >= VERT * |x|
DIRS = {"toward": 0.0, "up": math.pi / 2, "away": math.pi, "down": -math.pi / 2}  # screen frame, facing right


def pol(a, r):
    return (math.cos(a) * r, math.sin(a) * r)


def rescale(x, y):
    m = math.hypot(x, y)
    if m < DZ:
        return 0.0, 0.0
    k = (m - DZ) / (1 - DZ) / m
    return x * k, y * k


def classify(x, y):
    x, y = rescale(x, y)
    if math.hypot(x, y) < MAG:
        return "neutral"
    if abs(y) >= VERT * abs(x):
        return "up" if y > 0 else "down"
    return "toward" if x > 0 else "away"


def lerp(a, b, t):
    return a + (b - a) * t


def smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def read(samples, e, mode):
    """samples: per-tick (x, y); e: the press tick. mode: edge | post3 | pre4post3"""
    if mode == "edge":
        return classify(*samples[e])
    lo = e - (4 if mode == "pre4post3" else 0)
    win = samples[max(0, lo):e + 4]
    last = classify(*win[-1])
    if last != "neutral":
        return last
    best = max(win, key=lambda p: math.hypot(*rescale(*p)))
    return classify(*best)


def prior_move(r):
    u = r.random()
    if u < 0.40:
        return (0.0, 0.0), "neutral"
    if u < 0.70:
        return pol(0.0 + r.gauss(0, 0.25), r.uniform(0.5, 1.0)), "toward"
    if u < 0.85:
        return pol(math.pi + r.gauss(0, 0.25), r.uniform(0.5, 1.0)), "away"
    d = r.choice(["up", "down"])
    return pol(DIRS[d] + r.gauss(0, 0.25), r.uniform(0.5, 1.0)), d


def run(N=20000, skill="casual", seed=1):
    r = random.Random(seed)
    sd = math.radians(10 if skill == "skilled" else 18)
    res = {m: {"steady": 0, "simul": 0, "plain_dir": 0} for m in ("edge", "post3", "pre4post3")}
    n_st = n_si = n_pl = 0
    for i in range(N):
        D = r.choice(list(DIRS))
        # S1: a lean held steady, then the tap
        a = DIRS[D] + r.gauss(0, sd)
        tr = [pol(a, r.uniform(0.75, 1.0))] * 12
        n_st += 1
        for m in res:
            res[m]["steady"] += 1 if read(tr, 6, m) == D else 0
        # S2: simultaneous: the thumb moves from its movement lean to D around the press
        p0, _ = prior_move(r)
        tau = r.gauss(0, 3.0 if skill == "casual" else 1.5)
        rise = max(2.0, r.gauss(4.5, 1.5))
        tgt = pol(DIRS[D] + r.gauss(0, sd), r.uniform(0.75, 1.0))
        tr = []
        for t in range(14):
            s = smooth((t - 6 - tau) / rise)
            tr.append((lerp(p0[0], tgt[0], s), lerp(p0[1], tgt[1], s)))
        n_si += 1
        for m in res:
            res[m]["simul"] += 1 if read(tr, 6, m) == D else 0
        # S3: a plain dodge while moving: the player does not intend a direction
        p0, _ = prior_move(r)
        tr = [(p0[0] + r.gauss(0, 0.02), p0[1] + r.gauss(0, 0.02))] * 12
        n_pl += 1
        for m in res:
            res[m]["plain_dir"] += 1 if read(tr, 6, m) != "neutral" else 0
    out = {}
    for m in res:
        out[m] = {"steady_ok": round(100.0 * res[m]["steady"] / n_st, 1), "simul_ok": round(100.0 * res[m]["simul"] / n_si, 1), "plain_gets_dir": round(100.0 * res[m]["plain_dir"] / n_pl, 1)}
    return out


if __name__ == "__main__":
    for skill in ("skilled", "casual"):
        print(skill, run(20000, skill))
