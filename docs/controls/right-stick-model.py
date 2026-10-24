"""Modelled misreads of a right-stick recognizer (docs/controls/right-stick.md). Synthetic thumb traces, not measured humans:
the numbers say how the thresholds behave under stated assumptions, and QA's real traces replace them. Deterministic (seeded)."""
import math, random, sys, json

DZ = 0.25          # radial dead zone (rescaled out)
ON, OFF = 0.60, 0.35
FLICK_RISE = 5     # ticks from <=0.2 to >=ON
HOLD_T = 10        # ticks deflected to count as a hold
GAP = 12           # ticks without a new token closes a pattern
REST_CLOSE = 5     # ticks at rest (inside the dead zone) that close a pattern
MIN_DWELL = 2


def sector(a):  # a in radians, 8 sectors, 0 = right
    return int(((a + math.pi / 8) % (2 * math.pi)) // (math.pi / 4)) % 8


def quant(v):
    return round(v * 16) / 16.0


def lerp(a, b, t):
    return a + (b - a) * t


PATHMODE = True
CIRCLE_SPEED_GATE = True
MIN_DEG_PER_TICK = 3.0   # a drawn half circle is 140 degrees in 36 ticks or fewer; a slow sweep is 1 to 2
STROKE_MAX_TICKS = 16   # a zig-zag stroke is a flick-speed move: slower sweeps are aiming, not a pattern
STROKE_MIN_SPEED = 0.07  # mean radius per tick over the stroke (0.6 radius in 16 ticks is 0.0375; a flick-speed stroke is 0.1 or more)


def STROKE_GATE(strokes):
    return all(st[2] <= STROKE_MAX_TICKS and st[1] / max(1, st[2]) >= STROKE_MIN_SPEED for st in strokes)


class Rec:
    """The recognizer. Feed one (x, y) per tick; events come back as (name, detail)."""

    def __init__(self, patterns=True):
        self.patterns = patterns
        self.dz = False
        self.last_low = 0     # last tick magnitude <= 0.2
        self.t = 0
        self.on_t = None
        self.tokens = []      # (sector, tick)
        self.cur_sector = None
        self.sec_t = 0
        self.last_tok_t = -999
        self.hold_fired = False
        self.events = []
        self.flick_pending = None
        self.rest_ticks = 0
        self.flick_rise = FLICK_RISE
        self.buf = []

    def step(self, x, y):
        self.t += 1
        t = self.t
        m = math.hypot(x, y)
        if m < DZ:
            x = y = 0.0
            m = 0.0
        else:
            k = (m - DZ) / (1 - DZ) / m
            x, y, m = x * k, y * k, (m - DZ) / (1 - DZ)
        a = math.atan2(y, x)
        out = []
        if self.tokens or m >= ON:
            self.buf.append((x, y))
        if m <= 0.2:
            self.last_low = t
            self.rest_ticks += 1
        else:
            self.rest_ticks = 0
        if self.flick_pending is not None and t >= self.flick_pending[0]:
            out.append(("flick", sector(a if m >= OFF else self.flick_pending[1])))
            self.flick_pending = None
        if not self.dz and m >= ON:
            self.dz = True
            self.on_t = t
            self.hold_fired = False
            if t - self.last_low <= self.flick_rise:
                self.flick_pending = (t + 2, a)   # direction settled two ticks later
            self.cur_sector = sector(a)
            self.sec_t = t
            self.tokens.append((self.cur_sector, t))
            self.last_tok_t = t
        elif self.dz and m < OFF:
            self.dz = False
            self.cur_sector = None
        elif self.dz:
            s = sector(a)
            if s != self.cur_sector:
                d = min((s - self.cur_sector) % 8, (self.cur_sector - s) % 8)
                if t - self.sec_t >= MIN_DWELL or d >= 2:
                    self.cur_sector = s
                    self.sec_t = t
                    self.tokens.append((s, t))
                    self.last_tok_t = t
            if not self.hold_fired and t - self.on_t >= HOLD_T:
                self.hold_fired = True
                out.append(("hold", self.cur_sector))
        if self.tokens and (self.rest_ticks >= REST_CLOSE or t - self.last_tok_t >= GAP):
            if self.patterns:
                cls = classify_path(self.buf) if PATHMODE else classify(self.tokens)
                if cls:
                    out.append(("pattern", cls))
            self.tokens = []
            self.buf = []
        return out


def classify(tokens):
    if len(tokens) < 2:
        return None
    secs = [s for s, _ in tokens]
    times = [t for _, t in tokens]
    total = times[-1] - times[0]
    ds = []
    for i in range(1, len(secs)):
        d = (secs[i] - secs[i - 1]) % 8
        ds.append(d if d <= 4 else d - 8)
    # zig-zag: >= 3 tokens, successive moves near-opposite (|d| 3 or 4)
    if len(secs) >= 3 and all(abs(d) >= 3 for d in ds) and total <= 48 and all(times[i] - times[i - 1] <= 14 for i in range(1, len(times))):
        return "pump" if (min(secs) in (2, 6) and all(s in (2, 6) for s in secs)) else "zigzag"
    # circles: same-signed small steps
    if all(0 < abs(d) <= 2 for d in ds) and (all(d > 0 for d in ds) or all(d < 0 for d in ds)):
        steps = sum(abs(d) for d in ds)
        if steps >= 7 and total <= 56:
            return "full"
        if steps >= 4 and total <= 36:
            return "half"
        if steps >= 2 and total <= 24:
            return "quarter"
    return None



def classify_path(buf):
    """buf: list of (x, y) rescaled samples from the first deflection to the close. Angle accumulation for circles, stroke reversals for zig-zags."""
    n = len(buf)
    if n < 6:
        return None
    # circles: unwrapped angle while the stick is well off centre
    cum = 0.0
    tot = 0.0
    last = None
    ticks_in = 0
    for x, y in buf:
        m = math.hypot(x, y)
        if m < 0.5:
            last = None
            continue
        a = math.atan2(y, x)
        ticks_in += 1
        if last is not None:
            d = (a - last + math.pi) % (2 * math.pi) - math.pi
            cum += d
            tot += abs(d)
        last = a
    deg = abs(math.degrees(cum))
    mono = (abs(cum) / tot) if tot > 1e-6 else 0.0
    # zig-zag: strokes between turning points
    strokes = []
    s0 = buf[0]
    ext = buf[0]
    d = None
    t0 = 0
    for i in range(1, n):
        p = buf[i]
        if d is None:
            if math.hypot(p[0] - s0[0], p[1] - s0[1]) > 0.3:
                L = math.hypot(p[0] - s0[0], p[1] - s0[1])
                d = ((p[0] - s0[0]) / L, (p[1] - s0[1]) / L)
                ext = p
            continue
        proj = (p[0] - s0[0]) * d[0] + (p[1] - s0[1]) * d[1]
        proj_ext = (ext[0] - s0[0]) * d[0] + (ext[1] - s0[1]) * d[1]
        if proj >= proj_ext:
            ext = p
        elif proj_ext - proj > 0.35 and math.hypot(ext[0] - s0[0], ext[1] - s0[1]) >= 0.5:
            L = math.hypot(ext[0] - s0[0], ext[1] - s0[1])
            strokes.append((d, L, i - t0))
            s0 = ext
            t0 = i
            L2 = math.hypot(p[0] - s0[0], p[1] - s0[1])
            d = ((p[0] - s0[0]) / L2, (p[1] - s0[1]) / L2) if L2 > 1e-6 else None
            ext = p
    if d is not None:
        L = math.hypot(ext[0] - s0[0], ext[1] - s0[1])
        if L >= 0.5:
            strokes.append((d, L, n - t0))
    zz = False
    if len(strokes) >= 3:
        zz = STROKE_GATE(strokes[:3]) and all(strokes[i][0][0] * strokes[i - 1][0][0] + strokes[i][0][1] * strokes[i - 1][0][1] < -0.5 for i in range(1, len(strokes))) and all(st[1] >= 0.6 for st in strokes[:3]) and n <= 60
    # a circle is a drawn move, not a slow sweep: the swept angle must arrive inside the class's window (ticks spent off centre)
    WINDOW = {"quarter": 24, "half": 36, "full": 48}
    cls = "full" if deg >= 300 else "half" if deg >= 140 else "quarter" if deg >= 65 else None
    circle = mono >= 0.8 and cls is not None and ticks_in <= WINDOW[cls] and (not CIRCLE_SPEED_GATE or deg / max(1, ticks_in) >= MIN_DEG_PER_TICK)
    if zz and not circle:
        vertical = all(abs(st[0][1]) > 0.8 for st in strokes)
        return "pump" if vertical else "zigzag"
    if circle:
        return cls
    return None

# ------------------------------------------------------------------ synthetic thumbs

def make_rng(seed):
    return random.Random(seed)


def smooth(t):
    return t * t * (3 - 2 * t)


def ang_noise(r, sd):
    return r.gauss(0, math.radians(sd))


def trace_from_waypoints(r, pts, durs, skill, extra_tail=8):
    """pts: list of (x, y) targets; durs: ticks to move to each. Returns per-tick samples with noise, drift."""
    out = []
    cur = (0.0, 0.0)
    for p, d in zip(pts, durs):
        d = max(1, int(round(d)))
        for i in range(1, d + 1):
            s = smooth(i / d)
            out.append((lerp(cur[0], p[0], s), lerp(cur[1], p[1], s)))
        cur = p
    for _ in range(extra_tail):
        out.append(cur)
    return out


def noisy(r, tr, skill, drift):
    sd = 0.015 if skill == "skilled" else 0.03
    res = []
    for x, y in tr:
        res.append((quant(max(-1, min(1, x + drift[0] + r.gauss(0, sd)))), quant(max(-1, min(1, y + drift[1] + r.gauss(0, sd))))))
    return res


def sk(skill):
    return (8.0, 1.0) if skill == "skilled" else (18.0, 1.5)


def pol(a, rad):
    return (math.cos(a) * rad, math.sin(a) * rad)


def gen(kind, r, skill):
    angsd, slow = sk(skill)
    drift = (r.uniform(-0.08, 0.08), r.uniform(-0.08, 0.08)) if skill == "casual" else (r.uniform(-0.04, 0.04), r.uniform(-0.04, 0.04))
    base = r.choice([i * math.pi / 4 for i in range(8)])
    rad = lambda: r.uniform(0.82, 1.0) if skill == "skilled" else r.uniform(0.7, 1.0)
    pts, durs, intent = [], [], None
    if kind == "flick":
        a = base + ang_noise(r, angsd)
        rise = max(1, r.lognormvariate(math.log(2.5 * slow), 0.3))
        rise = rise if skill == "skilled" else rise * 1.0
        pts = [pol(a, rad()), pol(a, rad()), (0, 0)]
        durs = [rise, r.randint(1, 3), r.uniform(3, 9)]
        if r.random() < 0.5:   # recentring overshoot into the opposite side
            pts = [pts[0], pts[1], pol(a + math.pi, r.uniform(0.1, 0.45)), (0, 0)]
            durs = [rise, r.randint(1, 3), r.uniform(2, 5), r.uniform(2, 6)]
        intent = ("flick", sector(base))
    elif kind == "hold":
        a = base + ang_noise(r, angsd)
        rise = r.uniform(7, 16) * slow
        pts = [pol(a, rad()), pol(a, rad()), (0, 0)]
        durs = [rise, r.uniform(30, 50), r.uniform(5, 12)]
        intent = ("hold", sector(base))
    elif kind == "snap_hold":      # thumb snaps to a direction and stays: flick then hold is the right answer
        a = base + ang_noise(r, angsd)
        pts = [pol(a, rad()), pol(a, rad()), (0, 0)]
        durs = [r.uniform(2, 4), r.uniform(30, 50), r.uniform(5, 12)]
        intent = ("flick+hold", sector(base))
    elif kind in ("zigzag", "pump"):
        a = base if kind == "zigzag" else math.pi / 2
        a += ang_noise(r, angsd)
        n = 3 if kind == "zigzag" else 4
        sgn = 1
        for i in range(n):
            pts.append(pol(a + (0 if sgn > 0 else math.pi) + ang_noise(r, angsd * 0.5), rad()))
            durs.append(r.uniform(5, 9) * slow)
            sgn = -sgn
        pts.append((0, 0)); durs.append(r.uniform(4, 9))
        intent = (kind, None)
    elif kind in ("quarter", "half", "full"):
        sweep = {"quarter": 90, "half": 180, "full": 360}[kind]
        total_t = {"quarter": r.uniform(9, 18), "half": r.uniform(15, 28), "full": r.uniform(22, 44)}[kind] * slow
        sign = r.choice([1, -1])
        steps = max(6, int(sweep / 15))
        a0 = base
        rr = rad()
        for i in range(steps + 1):
            a = a0 + sign * math.radians(sweep) * i / steps + ang_noise(r, angsd * 0.4)
            pts.append(pol(a, max(0.55, rr + r.gauss(0, 0.07))))
            durs.append(total_t / steps if i else r.uniform(2, 4))
        pts.append((0, 0)); durs.append(r.uniform(4, 9))
        intent = (kind, None)
    elif kind == "aimwander":      # sloppy continuous aim: no gesture intended
        a = r.uniform(0, 2 * math.pi)
        w = 0.0
        tr = []
        for i in range(60):
            w += r.gauss(0, math.radians(14))
            w = max(-math.radians(22), min(math.radians(22), w))
            a += w
            tr.append(pol(a, r.uniform(0.6, 1.0)))
        return noisy(r, tr + [(0, 0)] * 8, skill, drift), (None, None)
    elif kind == "idle":
        return noisy(r, [(0, 0)] * 90, skill, drift), (None, None)
    tr = trace_from_waypoints(r, pts, durs, skill)
    return noisy(r, tr, skill, drift), intent


def run(trace, patterns=True):
    rec = Rec(patterns)
    ev = []
    for x, y in trace:
        ev += rec.step(x, y)
    for _ in range(14):
        ev += rec.step(0.0, 0.0)
    return ev


def summarise(N, rise):
    kinds = ["flick", "hold", "snap_hold", "zigzag", "pump", "quarter", "half", "full", "aimwander", "idle"]
    out = {}
    for skill in ("skilled", "casual"):
        out[skill] = {}
        for kind in kinds:
            r = random.Random(f"{skill}-{kind}")
            c = {"flick": 0, "hold": 0, "pat_ok": 0, "pat_other": 0, "none": 0, "dir8": 0, "dir4": 0, "dn": 0}
            for i in range(N):
                tr, intent = gen(kind, r, skill)
                rec = Rec(True)
                rec.flick_rise = rise
                ev = []
                for x, y in tr:
                    ev += rec.step(x, y)
                for _ in range(14):
                    ev += rec.step(0.0, 0.0)
                pats = [e[1] for e in ev if e[0] == "pattern"]
                fl = [e for e in ev if e[0] == "flick"]
                ho = [e for e in ev if e[0] == "hold"]
                c["flick"] += 1 if fl else 0
                c["hold"] += 1 if ho else 0
                if kind in ("zigzag", "pump", "quarter", "half", "full"):
                    if pats and pats[-1] == kind or (kind == "zigzag" and pats and pats[-1] == "pump"):
                        c["pat_ok"] += 1
                    elif pats:
                        c["pat_other"] += 1
                    else:
                        c["none"] += 1
                elif pats:
                    c["pat_other"] += 1
                if kind in ("flick", "snap_hold") and fl and intent[1] is not None:
                    c["dn"] += 1
                    d = min((fl[0][1] - intent[1]) % 8, (intent[1] - fl[0][1]) % 8)
                    c["dir8"] += 1 if d == 0 else 0
                    c["dir4"] += 1 if d <= 1 and (intent[1] % 2 == 0 or True) and (fl[0][1] % 2 == 0 if intent[1] % 2 == 0 else d == 0) else 0
            out[skill][kind] = {k: round(100.0 * v / N, 1) for k, v in c.items() if k not in ("dn", "dir8", "dir4")}
            if c["dn"]:
                out[skill][kind]["dir8%"] = round(100.0 * c["dir8"] / c["dn"], 1)
                out[skill][kind]["dir4%"] = round(100.0 * c["dir4"] / c["dn"], 1)
    return out


def main(N=800):
    for rise in (2, 3, 4):
        print("FLICK_RISE", rise)
        res = summarise(N, rise)
        for skill in res:
            print(" ", skill)
            for k, v in res[skill].items():
                print("   %-10s %s" % (k, v))


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 800)
