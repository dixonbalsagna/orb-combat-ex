#!/usr/bin/env python3
"""The moveset generator, reference version (docs/combat/moveset-generator.md). PARKED with its data.

Reads parts.json, identity.json, cells.json and lock.json beside it, and Animation's data (the strike and entry
manifests in data/anim/waves, and data/anim/tips.json), and writes one moveset file for each fighter, the lock and
the review sheet, into this folder.

    python docs/combat/pending/movegen/gen_moveset.py              write the files
    python docs/combat/pending/movegen/gen_moveset.py --check      regenerate and compare with the files; test the files
                                                                   on disk and Combat's own strings against Legal's rows
    python docs/combat/pending/movegen/gen_moveset.py --self-test  prove the refusals on made-up moves and strings
    ... --relock                                                   ignore the lock and fill every cell afresh
    ... --recipes PATH                                             the recipes file whose blur patterns are tested
                                                                   (default: ../recipes.brawl.json, else the live file)

Deterministic: there is no generator state and no clock. The only randomness is a hash of the seed, the fighter,
the cell and the candidate. Standard library only.

Legal's rows (parts.json strike.banned, strike.bannedSequences) are never emitted: a candidate that matches a shape
row is dropped before the pick, and --check exits 1 if a move in a file, the links table or a blur pattern matches.
"""
import hashlib, io, itertools, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
VERSION = 4
LEVELS = ["posed", "hand_state", "re_aim", "hand_state_re_aim", "re_aim_edge", "hand_state_re_aim_edge"]
STANCES = ["martial", "manoeuvre", "energy", "defensive", "charging"]


def load(path):
    with io.open(path, encoding="utf-8") as f:
        return json.load(f)


def raw(path):
    with io.open(path, "rb") as f:
        return f.read().replace(b"\r\n", b"\n")


def anim(*rel):
    return os.path.join(ROOT, "data", "anim", *rel)


def jitter(*parts):
    """0.85 to 1.15, in steps of 0.0003, from a hash: integer arithmetic until the last step."""
    h = hashlib.sha256("|".join(str(p) for p in parts).encode("utf-8")).digest()
    return 0.85 + 0.3 * (int.from_bytes(h[:8], "big") % 1000) / 1000.0


def match(flt, m):
    """A filter: every listed part has one of the listed values. `any`: one of a list of filters."""
    if "any" in flt:
        return any(match(f, m) for f in flt["any"])
    for k, vals in flt.items():
        if k.startswith("_"):
            continue
        if m.get(k) not in vals:
            return False
    return True


def fp(m):
    return (m["limb"], m["tip"], m["path"], m["target"], m["weight"])


def shapes(g):
    out = []
    for limb, tips in g["tips"].items():
        for tip, paths in tips.items():
            for path in paths:
                for target in g["targets"][limb][path]:
                    for weight in ("light", "heavy"):
                        m = {"limb": limb, "tip": tip, "path": path, "target": target, "weight": weight}
                        if weight == "light" and any(match(r, m) for r in g["lightNever"]):
                            continue
                        out.append(m)
    return out


# ---------------------------------------------------------------- Legal's rows

def banned_hit(row, m, forms, arms, flags):
    """How a shape row bears on a move: 'match' (refuse), 'ask' (every named part matches and its flags are unknown), or None."""
    mt = row["match"]
    for k, vals in mt.items():
        if k == "flags":
            continue
        if k == "form":
            if not any(f in vals for f in forms):
                return None
        elif k == "arms":
            if arms not in vals:
                return None
        elif m.get(k) not in vals:
            return None
    if "flags" not in mt:
        return "match"
    if any(f in flags["has"] for f in mt["flags"]):
        return "match"
    if all(f in flags["not"] for f in mt["flags"]):
        return None
    return "ask"


def flags_of(g, idn, m, source):
    """Known present, and known absent, pose flags of a move (parts.json strike.flags)."""
    has = set(idn.get("tipFlags", {}).get(m["limb"] + "." + m["tip"], []))
    not_ = set(g["flags"]["byVocabulary"])
    if source:
        has |= set(source.get("flags", []))
        if source.get("measured"):
            not_ |= set(g["flags"]["fromAnimation"])   # Animation's flags are read off the poses: a flag it does not list is absent
        for tag in source["legal"]:
            not_ |= set(g["flags"]["clearedBy"].get(tag, []))
    return {"has": sorted(has), "not": sorted(not_ - has)}


def sequence_breaks(g, seq, airborne=True):
    """The sequence rules a list of blows breaks. A blow is a dict of parts; it may carry `arms` and `event`."""
    out = []
    for r in g["bannedSequences"]:
        if r["kind"] == "run":
            caps = [({}, r["max"])] + [(t["when"], t["max"]) for t in r.get("tighter", [])]
            for flt, cap in caps:
                run = 0
                for i, b in enumerate(seq):
                    same = i > 0 and all(k in b and k in seq[i - 1] and b[k] == seq[i - 1][k] for k in r["same"])
                    run = run + 1 if same else 1
                    if run > cap and match(flt, b):
                        out.append(r["id"]); break
        elif r["kind"] == "after":
            if r.get("state") == "airborne" and not airborne:
                continue
            for i in range(1, len(seq)):
                prev = seq[i - 1]
                if all(prev.get(k) in v for k, v in r["after"].items()) and any(match(n, seq[i]) for n in r["never"]):
                    out.append(r["id"]); break
        elif r["kind"] == "steps":
            if any(s not in r["drawn"] for b in seq for s in b.get("step", [])):
                out.append(r["id"])
    return sorted(set(out))


def group_hits(parts, m, kind):
    """Legal's group rows (parts.json legal) a travel or energy move matches. kind: 'travel' or 'energy'."""
    lg = parts.get("legal", {})
    out = []
    if kind == "travel":
        for r in lg.get("motion", []):
            if r.get("kind") == "travel" and match(r["if"], m) and not match(r["then"], m):
                out.append(r["id"])
    else:
        hand = parts["shot"]["hands"].get(m["hand"])
        for r in lg.get("energy", []):
            if r.get("kind") == "move" and match(r["if"], m) and not match(r["then"], m):
                out.append(r["id"])
            if r.get("kind") == "hand":
                if hand is None:
                    out.append(r["id"])   # a hand Legal has not screened
                elif any(hand.get(k) in v for k, v in r.get("never", {}).items()) or any(hand.get(k) not in v for k, v in r.get("need", {}).items()):
                    out.append(r["id"])
    return sorted(set(out))


# ---------------------------------------------------------------- what is posed (Animation's data)

def posed(parts, idn, tips):
    """His posed strikes as shapes of the grammar: fingerprint -> the key set it comes from and how."""
    g = parts["strike"]
    rows = {}
    for wave in idn["waves"]:
        for s in load(anim("waves", wave + ".manifest.json"))["strikes"]:
            rows[s["combat"]] = (wave, s)
    cover, unread = {}, []
    for sid in sorted(rows):
        wave, s = rows[sid]
        limb = s["limb"][:-2] if s["limb"].endswith(("_r", "_l")) else s["limb"]
        tip = idn.get("tipOf", {}).get(sid, s.get("tip"))
        path = s.get("path")
        target = "arm" if s["target"].startswith("arm") else s["target"]
        if tip not in g["tips"].get(limb, {}) or path not in g["tips"][limb][tip] or target not in g["targets"][limb].get(path, []):
            unread.append("%s (%s %s %s to the %s)" % (s["id"], limb, tip, path, target))
            continue
        arms = int(s.get("uses", {}).get("arms", 1 if limb in ("hand", "elbow") else 0))
        tips_ = [tip]
        if limb == "hand" and tip in g["swap"]:
            keep = [g["tagTips"][t] for t in s.get("legal", []) if t in g.get("tagTips", {})]
            tips_ += [t for t in g["swap"] if t != tip and path in g["tips"]["hand"][t] and all(t in k for k in keep)]
        aims = [(target, "")]
        ra = tips.get("reaim", {}).get(s["id"], {})
        for grade, sfx in (("ok", ""), ("edge", "_edge")):
            for t in ra.get(grade, []):
                t = "arm" if t.startswith("arm") else t
                if t != target and t in g["targets"][limb][path] and all(t != a for a, _ in aims):
                    aims.append((t, sfx))
        for t in tips_:
            for tg, sfx in aims:
                level = ("posed" if tg == target else "re_aim" + sfx) if t == tip else ("hand_state" if tg == target else "hand_state_re_aim" + sfx)
                key = (limb, t, path, tg, s["weight"])
                rank = (LEVELS.index(level), 0 if arms <= 1 else 1)
                if key not in cover or rank < cover[key]["_rank"]:
                    cover[key] = {"level": level, "from": sid, "set": s["id"], "wave": wave, "legal": list(s.get("legal", [])), "flags": list(s.get("flags", [])),
                                  "measured": "flags" in s, "arms": arms, "ground": s.get("ground", "ok"), "_rank": rank}
    return cover, unread


def entries_of(idn):
    out = {}
    for wave in idn.get("entryWaves", []):
        for e in load(anim("waves", wave + ".entrymap.json"))["entries"]:
            out[e["combat"].split(".", 1)[1]] = e["id"]
    return out


def forms_of(g, m, arms):
    probe = dict(m)
    probe["arms"] = arms
    have = []
    for rule in g["forms"]:
        if rule.get("unless") and rule["unless"] in have:
            continue
        flt = {"any": rule["any"]} if "any" in rule else rule["when"]
        if match(flt, probe):
            have.append(rule["form"])
    return have


def weight_of(idn, m):
    w = idn["weights"]
    tips = dict(w.get("tip", {}))
    for by in idn.get("weightsBy", []):
        if match(by["when"], m):
            tips.update(by.get("tip", {}))
    return w["limb"].get(m["limb"], 1) * w["path"].get(m["path"], 1) * tips.get(m["limb"] + "." + m["tip"], 1)


def quota_ok(q, m):
    if "form" in q:
        return q["form"] in m["_forms"]
    if "sends" in q:
        return m.get("_sends") == q["sends"]
    return match({"any": q["any"]} if "any" in q else q["filter"], m)


def greedy(cand, count, quotas, penalty, locked=()):
    """Pick one at a time: quotas first, then the best score, each pick marking down what resembles it."""
    picked = list(locked)
    cand = [m for m in cand if all(m is not p for p in picked)]
    while cand and len(picked) < count:
        pool = cand
        for q in quotas:
            if sum(1 for p in picked if quota_ok(q, p)) < q["min"] and any(quota_ok(q, m) for m in cand):
                pool = [m for m in cand if quota_ok(q, m)]
                break
        best, bs = None, -1.0
        for m in pool:
            w = m["_w"]
            for p in picked:
                w *= penalty(p, m)
            if w > bs:
                best, bs = m, w
        cand.remove(best)
        picked.append(best)
    return picked


# ---------------------------------------------------------------- the cells, by kind

def strike_cell(ctx, who, cid, cell):
    parts, idn, cover, seed, spread = ctx["parts"], ctx["idn"], ctx["cover"], ctx["seed"], ctx["spread"]
    g = parts["strike"]
    cand, refused = [], []
    for m in shapes(g):
        if not match(cell["filter"], m):
            continue
        if any(match(r["shape"], m) for r in idn["never"]) or list(fp(m)) in ctx["rejected"]:
            continue
        w = weight_of(idn, m)
        if w <= 0:
            continue
        c = cover.get(fp(m))
        m["_arms"] = c["arms"] if c else (1 if m["limb"] in ("hand", "elbow") else 0)
        m["_forms"] = list(cell["readings"]) if "readings" in cell else forms_of(g, m, m["_arms"])
        m["_strike_forms"] = forms_of(g, m, m["_arms"])
        m["_flags"] = flags_of(g, idn, m, c)
        if any(f in m["_flags"]["has"] for f in cell.get("notFlags", [])):
            continue   # a cell can turn away key sets that show a flag (a push is never a leap)
        hits =[(r["id"], banned_hit(r, m, m["_strike_forms"], m["_arms"], m["_flags"])) for r in g["banned"]]
        if any(h == "match" for _, h in hits):
            refused.append({"shape": list(fp(m)), "rows": [i for i, h in hits if h == "match"]})
            continue
        m["_w"] = w * (idn["reuse"][c["level"]] if c else 1.0) * jitter(seed, who, cid, *fp(m))
        m["_sends"] = g["sends"][m["path"]]
        cand.append(m)
    if cell.get("anyWeight"):   # one shape a place: a push has no weight, so keep the better-covered of light and heavy
        best = {}
        for m in cand:
            k = fp(m)[:4]
            r = cover[fp(m)]["_rank"] if fp(m) in cover else (99, 0)
            if k not in best or (r, m["weight"] != "light") < best[k][0]:
                best[k] = ((r, m["weight"] != "light"), m)
        cand = [v[1] for v in best.values()]
    valid = len(cand)
    locked, dropped, reread = [], [], []
    by_fp = {fp(m): m for m in cand}
    for entry in ctx["lock"].get(cid, []):
        mid, shape, kset = entry[0], tuple(entry[1]), (entry[2] if len(entry) > 2 else None)
        m = None
        if kset:   # a move locked on a posed key set follows that key set to the shape Animation reads on it
            real = next((k for k in sorted(cover) if cover[k]["set"] == kset and cover[k]["level"] == "posed"), None)
            if real is not None and real != shape and real in by_fp:
                reread.append({"id": mid, "set": kset, "was": list(shape), "now": list(real)})
                m = by_fp[real]
        if m is None:
            m = by_fp.get(shape)
        if m is None or "_id" in m:
            dropped.append({"id": mid, "shape": list(shape)})
        else:
            m["_id"] = mid
            locked.append(m)
    def penalty(p, m):
        w = 1.0
        if p["path"] == m["path"]:
            w *= spread["path"]
        if p["target"] == m["target"]:
            w *= spread["target"]
        if p["tip"] == m["tip"]:
            w *= spread["tip"]
        if (p["limb"], p["path"], p["target"]) == (m["limb"], m["path"], m["target"]):
            w *= spread["shape"]
        return w
    picked = greedy(cand, cell["count"], cell.get("quotas", []), penalty, locked)
    used = set(m["_id"] for m in picked if "_id" in m)
    free = [n for n in ("mv.%s.%s.%02d" % (who, cid, i + 1) for i in range(len(picked) + len(dropped) + 5)) if n not in used]
    moves = []
    for m in picked:
        c = cover.get(fp(m))
        probe = dict(m); probe["arms"] = m["_arms"]
        asks = [cd["id"] for cd in g["conditions"] if "when" in cd and match(cd["when"], probe)]
        if cell.get("as") == "push":
            asks = ["P1"] + [a for a in asks if a in ("L2", "L7")]
        if c is None:
            keys = {"level": "new"}
        else:
            keys = {"level": c["level"], "from": c["from"], "set": c["set"], "wave": c["wave"]}
            if c["level"].startswith("hand_state"):
                keys["hand"] = m["tip"]
            if "re_aim" in c["level"]:
                keys["aim"] = m["target"]
        if cell.get("layer"):
            keys["layer"] = cell["layer"]
        mv = {"id": m.get("_id") or free.pop(0), "limb": m["limb"], "tip": m["tip"], "path": m["path"], "target": m["target"], "weight": m["weight"], "arms": m["_arms"],
              "forms": m["_forms"], "step": g["step"][m["path"]], "sends": m["_sends"], "links": g["links"][m["path"]], "beat": g["beat"][m["path"]],
              "keys": keys, "ground": (c["ground"] if c else ("plant" if m["limb"] in ("foot", "knee") else "ok")),
              "status": "posed" if (c and c["level"] == "posed") else "derived" if c else "waiting",
              "flags": m["_flags"]["has"], "legal": sorted(c["legal"]) if c else [], "asks": asks, "review": "locked"}
        if cell.get("as"):
            mv["as"] = cell["as"]
        moves.append(mv)
    moves.sort(key=lambda x: x["id"])
    met = {q["name"]: sum(1 for p in picked if quota_ok(q, p)) for q in cell.get("quotas", [])}
    was = set(m["_id"] for m in picked if "_id" in m)
    ctx["changes"][cid] = {"dropped": dropped, "reread": reread, "new": [m["id"] for m in moves if m["id"] not in was]}
    return {"kind": "strikes", "valid": valid, "refused": refused, "quotas": met, "moves": moves}


def travel_cell(ctx, who, cid, cell, done):
    parts, idn, seed = ctx["parts"], ctx["idn"], ctx["seed"]
    t = parts["travel"]
    ents = ctx["entries"]
    blows = [b for b in done[cell["blows"]]["moves"] if b["status"] != "waiting"]
    cand, refused, seen_refused = [], [], set()
    for kind in cell["kinds"]:
        for mv in t["kinds"][kind]["moves"]:
            for e in mv["entries"]:
                if e not in ents or (mv["exit"] and mv["exit"] not in ents):
                    continue
                for b in blows:
                    if b["path"] not in t["arrive"][mv["direction"]]:
                        continue
                    m = {"kind": kind, "direction": mv["direction"], "entry": e, "exit": mv["exit"], "blow": b["id"], "path": b["path"], "target": b["target"], "limb": b["limb"], "_b": b}
                    hits = group_hits(parts, m, "travel")
                    if hits:
                        key = (kind, mv["direction"], mv["exit"])
                        if key not in seen_refused:
                            seen_refused.add(key)
                            refused.append({"move": {"kind": kind, "direction": mv["direction"], "exit": mv["exit"]}, "rows": hits})
                        continue
                    m["_forms"] = list(cell["readings"])
                    m["_w"] = idn["weights"].get("entry", {}).get(e, 1) * weight_of(idn, b) * (1.3 if b["status"] == "posed" else 1.0) * jitter(seed, who, cid, kind, mv["direction"], e, b["id"])
                    cand.append(m)
    valid = len(cand)
    def penalty(p, m):
        w = 1.0
        if p["blow"] == m["blow"]:
            w *= 0.1
        if p["entry"] == m["entry"]:
            w *= 0.5
        if (p["kind"], p["direction"]) == (m["kind"], m["direction"]):
            w *= 0.5
        if p["path"] == m["path"]:
            w *= 0.7
        if p["target"] == m["target"]:
            w *= 0.8
        return w
    picked = greedy(cand, cell["count"], cell.get("quotas", []), penalty)
    moves = []
    for i, m in enumerate(picked):
        b = m["_b"]
        asks = (["Z1"] if m["kind"].startswith("zip") else []) + b["asks"]
        moves.append({"id": "mv.%s.%s.%02d" % (who, cid, i + 1), "kind": m["kind"], "band": t["kinds"][m["kind"]]["band"], "direction": m["direction"],
                      "entry": {"id": "entry." + m["entry"], "set": ents[m["entry"]]}, "exit": ({"id": "entry." + m["exit"], "set": ents[m["exit"]]} if m["exit"] else None),
                      "blow": {"move": b["id"], "limb": b["limb"], "tip": b["tip"], "path": b["path"], "target": b["target"], "weight": b["weight"], "set": b["keys"].get("set")},
                      "forms": m["_forms"], "status": "posed" if b["status"] == "posed" else "derived", "flags": b["flags"], "legal": b["legal"], "asks": asks, "review": "new"})
    met = {q["name"]: sum(1 for p in picked if quota_ok(q, p)) for q in cell.get("quotas", [])}
    return {"kind": "travel", "valid": valid, "refused": refused, "quotas": met, "moves": moves}


def table_cell(ctx, who, cid, cell):
    parts, idn, seed = ctx["parts"], ctx["idn"], ctx["seed"]
    blk, en = parts[cell["block"]], idn["energy"]
    cand, refused = [], []
    for hand, release, body, delivery in itertools.product(sorted(en["hands"]), blk["release"], blk["body"], cell["delivery"]):
        m = {"hand": hand, "release": release, "body": body, "delivery": delivery}
        if delivery == "split" and not en.get("split"):
            continue
        if any(match(r["if"], m) and not match(r["then"], m) for r in blk["rules"]):
            continue
        m["_forms"] = [f["form"] for f in blk["forms"] if match(f["when"], m)]
        if not m["_forms"]:
            continue
        hits = group_hits(parts, m, "energy")
        if hits:
            refused.append({"move": dict(m, _forms=None), "rows": hits})
            continue
        m["_w"] = en["hands"][hand] * en["release"].get(release, 1) * jitter(seed, who, cid, hand, release, body, delivery)
        m["_set"] = next((p["set"] for p in en["posed"] if match(p["when"], m)), None)
        if m["_set"]:
            m["_w"] *= 1.6 if hand in en["posedHands"] else 1.2
        cand.append(m)
    valid = len(cand)
    def penalty(p, m):
        w = 1.0
        for k, f in (("hand", 0.6), ("release", 0.6), ("body", 0.7), ("delivery", 0.8)):
            if p[k] == m[k]:
                w *= f
        return w
    picked = greedy(cand, cell["count"], [q for q in cell.get("quotas", []) if not ("filter" in q and q["filter"].get("delivery") == ["split"] and not en.get("split"))], penalty)
    moves = []
    for i, m in enumerate(picked):
        hand_set = en["posedHands"].get(m["hand"])
        keys = {"set": m["_set"], "hand": hand_set}
        moves.append({"id": "mv.%s.%s.%02d" % (who, cid, i + 1), "hand": m["hand"], "release": m["release"], "body": m["body"], "delivery": m["delivery"], "forms": m["_forms"],
                      "keys": keys, "status": "posed" if (m["_set"] and hand_set) else "derived" if m["_set"] else "waiting", "asks": ["E1"], "review": "new"})
    met = {q["name"]: sum(1 for p in picked if quota_ok(q, p)) for q in cell.get("quotas", [])}
    by = {}
    for r in refused:   # one line a shape of refusal, not one a candidate
        k = (r["move"]["delivery"], r["move"]["release"], tuple(r["rows"]))
        by[k] = by.get(k, 0) + 1
    refused = [{"move": {"delivery": k[0], "release": k[1]}, "rows": list(k[2]), "candidates": n} for k, n in sorted(by.items())]
    return {"kind": "table", "valid": valid, "refused": refused, "quotas": met, "moves": moves}


def special_cell(ctx, who, cid, cell):
    idn, seed = ctx["idn"], ctx["seed"]
    sp = idn["specials"][cell["slot"]]
    names = list(sp["parts"])
    cand = []
    for combo in itertools.product(*[sp["parts"][n] for n in names]):
        m = dict(zip(names, combo))
        if any(match(r["if"], m) and not match(r["then"], m) for r in sp.get("rules", [])):
            continue
        m["_forms"] = list(cell["readings"])
        m["_w"] = jitter(seed, who, cid, *combo)
        cand.append(m)
    def penalty(p, m):
        w = 1.0
        for n in names:
            if p[n] == m[n]:
                w *= 0.55
        return w
    picked = greedy(cand, cell["count"], [], penalty)
    moves = [{"id": "mv.%s.%s.%02d" % (who, cid, i + 1), "look": {n: m[n] for n in names}, "forms": m["_forms"], "status": "waiting", "asks": [], "review": "new"} for i, m in enumerate(picked)]
    return {"kind": "special", "special": sp["id"], "what": sp["what"], "state": sp["status"], "valid": len(cand), "quotas": {}, "moves": moves}


def build():
    parts = load(os.path.join(HERE, "parts.json"))
    identity = load(os.path.join(HERE, "identity.json"))
    cells = load(os.path.join(HERE, "cells.json"))
    tips = load(anim("tips.json")) if os.path.exists(anim("tips.json")) else {}
    lock_path = os.path.join(HERE, "lock.json")
    lock = load(lock_path)["fighters"] if (os.path.exists(lock_path) and "--relock" not in sys.argv) else {}
    seed, spread = cells["seed"], cells["spread"]
    out, notes = {}, {}
    for who in sorted(identity["fighters"]):
        idn = identity["fighters"][who]
        cover, unread = posed(parts, idn, tips)
        notes[who] = {"unread": unread}
        h = hashlib.sha256()
        for name in ("parts.json", "identity.json", "cells.json"):
            h.update(raw(os.path.join(HERE, name)))
        for wave in idn["waves"]:
            rows = load(anim("waves", wave + ".manifest.json"))["strikes"]
            h.update(json.dumps([[s["id"], s["combat"], s["limb"], s.get("tip"), s.get("path"), s["target"], s["weight"], s.get("legal", []), s.get("flags", [])] for s in rows], sort_keys=True).encode("utf-8"))
        h.update(json.dumps({k: v for k, v in tips.get("reaim", {}).items() if any(v2["set"] == k for v2 in cover.values())}, sort_keys=True).encode("utf-8"))
        ctx = {"parts": parts, "idn": idn, "cover": cover, "seed": seed, "spread": spread, "entries": entries_of(idn), "lock": lock.get(who, {}),
               "rejected": [r["shape"] for r in identity.get("rejected", []) if r.get("fighter") in (who, "*")], "changes": {}}
        doc = {
            "schema": "combat.moveset/1",
            "_target": "data/combat/movesets/%s.json" % who,
            "_about": "GENERATED by gen_moveset.py from parts.json, identity.json, cells.json, lock.json and Animation's data. Do not edit by hand: change an input and generate "
                      "again. PARKED: not loaded, not hashed. A move's status is posed (its poses exist), derived (a hand-state swap or a re-aim on a posed key set, or a posed "
                      "piece used a new way) or waiting (it needs new poses; the director skips it). flags are the pose flags it is known to have; legal are Legal's tags on the "
                      "key set it starts from; asks are Legal's conditions for its pose (parts.json strike.conditions). review is locked once its id is in lock.json",
            "fighter": who,
            "generator": {"version": VERSION, "seed": seed, "inputs": h.hexdigest()[:16]},
            "cells": {},
        }
        for stance in STANCES:
            if stance not in cells["stances"]:
                continue
            for btn in ("x", "y", "a", "b"):
                cell = cells["stances"][stance].get(btn)
                if cell is None:
                    continue
                cid = "%s.%s" % (stance, btn)
                k = cell["kind"]
                if k == "strikes":
                    doc["cells"][cid] = strike_cell(ctx, who, cid, cell)
                elif k == "travel":
                    doc["cells"][cid] = travel_cell(ctx, who, cid, cell, doc["cells"])
                elif k == "table":
                    doc["cells"][cid] = table_cell(ctx, who, cid, cell)
                elif k == "special":
                    doc["cells"][cid] = special_cell(ctx, who, cid, cell)
                elif k == "context":
                    doc["cells"][cid] = {"kind": "context", "pressed": cell["pressed"], "held": cell["held"], "asks": cell.get("asks", []), "_note": "not generated"}
                else:
                    doc["cells"][cid] = {"kind": "frame", "slots": cell["slots"], "readings": cell.get("readings", {}), "asks": cell.get("asks", []), "_note": cell["what"]}
        notes[who]["changes"] = ctx["changes"]
        doc["generator"]["inputs"] = hashlib.sha256((h.hexdigest() + json.dumps(lock_rows(doc), sort_keys=True)).encode("utf-8")).hexdigest()[:16]
        out[who] = doc
    return out, parts, identity, cells, notes


def dump(doc):
    """indent 1, with each move on one line."""
    lines = ["{"]
    keys = list(doc.keys())
    for i, k in enumerate(keys):
        comma = "," if i < len(keys) - 1 else ""
        if k != "cells":
            lines.append(" %s: %s%s" % (json.dumps(k), json.dumps(doc[k], ensure_ascii=False), comma))
            continue
        lines.append(' "cells": {')
        cids = list(doc["cells"].keys())
        for j, cid in enumerate(cids):
            c = doc["cells"][cid]
            cc = "," if j < len(cids) - 1 else ""
            if "moves" not in c:
                lines.append("  %s: %s%s" % (json.dumps(cid), json.dumps(c, ensure_ascii=False), cc))
                continue
            lines.append("  %s: {" % json.dumps(cid))
            head = {k2: v for k2, v in c.items() if k2 != "moves"}
            lines.append("   " + json.dumps(head, ensure_ascii=False)[1:-1] + ",")
            lines.append('   "moves": [')
            for n, m in enumerate(c["moves"]):
                lines.append("    " + json.dumps(m, ensure_ascii=False) + ("," if n < len(c["moves"]) - 1 else ""))
            lines.append("   ]")
            lines.append("  }" + cc)
        lines.append(" }" + comma)
    lines.append("}")
    return "\n".join(lines) + "\n"


def lock_rows(doc):
    return {cid: [[m["id"], [m["limb"], m["tip"], m["path"], m["target"], m["weight"]], (m["keys"]["set"] if m["keys"]["level"] == "posed" else None)] for m in c["moves"]]
            for cid, c in doc["cells"].items() if c["kind"] == "strikes"}


def lock_text(out):
    lock = {"schema": "combat.moveset.lock/1",
            "_about": "The moves that are locked: an id keeps its shape for good, because Animation's key sets and Legal's screen hang on it. The generator keeps every locked "
                      "move that is still allowed, fills only the free places, and writes this file again. To start over, run it with --relock (a deliberate act, with its own sheet)",
            "fighters": {}}
    for who, doc in out.items():
        lock["fighters"][who] = lock_rows(doc)
    return json.dumps(lock, indent=1) + "\n"


# ---------------------------------------------------------------- the checks on what exists

def recipes_path():
    if "--recipes" in sys.argv:
        return sys.argv[sys.argv.index("--recipes") + 1]
    parked = os.path.join(HERE, "..", "recipes.brawl.json")
    return parked if os.path.exists(parked) else os.path.join(ROOT, "data", "combat", "recipes.json")


def legal_findings(docs, parts, identity):
    """Everything on disk or in the grammar that matches one of Legal's rows. An empty list is a pass."""
    g = parts["strike"]
    bad = []
    grammar_targets = set(t for limb in g["targets"].values() for ts in limb.values() for t in ts)
    for r in g["banned"]:
        hit = grammar_targets & set(r["match"].get("target", [])) if set(r["match"]) == {"target"} else set()
        if hit:
            bad.append("%s: the grammar has the target %s" % (r["id"], ", ".join(sorted(hit))))
    for who, doc in docs.items():
        idn = identity["fighters"][who]
        for cid, c in doc["cells"].items():
            for m in c.get("moves", []):
                blows = [m] if c["kind"] == "strikes" else [dict(m["blow"], forms=["light"], arms=1, flags=m["flags"], id=m["id"])] if c["kind"] == "travel" else []
                for b in blows:
                    forms = forms_of(g, b, b.get("arms", 1))
                    for r in g["banned"]:
                        if banned_hit(r, b, forms, b.get("arms", 1), {"has": b.get("flags", []), "not": []}) == "match":
                            bad.append("%s: %s matches %s" % (who, m["id"], r["id"]))
                    if any(match(n["shape"], b) for n in idn["never"]):
                        bad.append("%s: %s matches one of his never rows" % (who, m["id"]))
                    br = sequence_breaks(g, [b])
                    if br:
                        bad.append("%s: %s breaks %s" % (who, m["id"], ", ".join(br)))
    for who, doc in docs.items():
        for cid, c in doc["cells"].items():
            for m in c.get("moves", []):
                if c["kind"] == "travel":
                    hits = group_hits(parts, {"kind": m["kind"], "direction": m["direction"], "exit": (m["exit"]["id"].split(".", 1)[1] if m["exit"] else None)}, "travel")
                elif c["kind"] == "table":
                    hits = group_hits(parts, m, "energy")
                else:
                    hits = []
                if hits:
                    bad.append("%s: %s matches %s" % (who, m["id"], ", ".join(hits)))
    lg = parts.get("legal", {})
    for who, idn in identity["fighters"].items():
        for hand in idn.get("energy", {}).get("hands", {}):
            hits = group_hits(parts, {"hand": hand, "delivery": "bolt", "release": "thrust"}, "energy")
            if hits:
                bad.append("%s: the energy hand %s matches %s" % (who, hand, ", ".join(hits)))
    for r in lg.get("grabs", []):
        if r.get("kind") == "holdPoints":
            hit = set(parts.get("grab", {}).get("holdPoints", [])) & set(r["never"])
            if hit:
                bad.append("%s: a grab may hold the %s" % (r["id"], ", ".join(sorted(hit))))
    lf = os.path.join(ROOT, "docs", "legal", "movegen-banned.json")
    if os.path.exists(lf):   # nothing of Legal's is dropped or loosened in the copy the generator reads
        theirs = load(lf)
        if theirs.get("banned") != g["banned"]:
            bad.append("parts.json strike.banned differs from docs/legal/movegen-banned.json")
        mine_seq = {r["id"]: (r["rule"], r["why"]) for r in g["bannedSequences"]}
        for r in theirs.get("bannedSequences", []):
            if mine_seq.get(r["id"]) != (r["rule"], r["why"]):
                bad.append("sequence rule %s differs from Legal's file" % r["id"])
        for group, rows in theirs.items():
            if group in ("schema", "_about", "banned", "bannedSequences") or not isinstance(rows, list):
                continue
            mine = {r["id"]: (r["rule"], r["why"]) for r in lg.get(group, [])}
            for r in rows:
                if mine.get(r["id"]) != (r["rule"], r["why"]):
                    bad.append("Legal's row %s (%s) is missing from parts.json or differs" % (r["id"], group))
    for p, nexts in g["links"].items():
        for q in nexts:
            br = [b for b in sequence_breaks(g, [{"path": p}, {"path": q}]) if b in ("s04", "s05")]
            if br:
                bad.append("links: %s then %s breaks %s" % (p, q, ", ".join(br)))
    rp = recipes_path()
    if os.path.exists(rp):
        for name, steps in load(rp).get("blurPatterns", {}).items():
            seq = [{"limb": s[0], "target": s[1]} for s in steps]
            br = sequence_breaks(g, seq + seq[:2])
            if br:
                bad.append("blur pattern %s (%s) breaks %s" % (name, os.path.relpath(rp, ROOT).replace(os.sep, "/"), ", ".join(br)))
    return bad


# ---------------------------------------------------------------- the sheet

WORDS = {"martial": "martial arts", "energy": "energy arts", "arc_in": "arc in", "arc_out": "arc out", "hand_state": "hand state", "re_aim": "re-aim", "hand_state_re_aim": "hand state and re-aim", "re_aim_edge": "re-aim at the edge",
         "hand_state_re_aim_edge": "hand state and re-aim at the edge", "zip_away": "zip away", "far_side": "far side", "arc_dive": "arc dive", "kiting_turn": "kiting turn", "short_beam": "short beam"}


def w(s):
    return WORDS.get(s, str(s).replace("_", " "))


def key_text(k):
    if k["level"] == "new":
        return "a new key set"
    ks = "%s: `%s`" % (w(k["level"]), k["set"])
    if "hand" in k:
        ks += ", hand %s" % k["hand"]
    if "aim" in k:
        ks += ", to the %s" % k["aim"]
    if "layer" in k:
        ks += ", over the %s" % k["layer"]
    return ks


def legal_text(m):
    lg = ", ".join(m.get("asks", []))
    if m.get("legal"):
        lg += ("; " if lg else "") + "carries: " + ", ".join(t.replace("_", " ") for t in m["legal"])
    return lg or "-"


def blow_text(b):
    return "%s %s, %s to the %s" % (b["limb"], b["tip"], w(b["path"]), b["target"])


def sheet(out, parts, cells, notes):
    g = parts["strike"]
    names = sorted(out)
    L = []
    L.append("# Review sheet: the five stances, both fighters")
    L.append("")
    L.append("GENERATED by `gen_moveset.py` (version %d, seed %d). Do not edit: change an input and generate again. Inputs: `parts.json`, `identity.json`, `cells.json`, `lock.json`, and Animation's data (the strike and entry manifests, `data/anim/tips.json`)." % (VERSION, cells["seed"]))
    L.append("")
    L.append("**Status.** *Posed*: its poses exist. *Derived*: a posed key set with the hand closed, bladed or opened, or landed on another place (a re-aim Animation measured as ok needs no look; one at the edge does), or posed pieces put together a new way. *Waiting*: it needs new poses, and the director skips it until then. Every strike move is locked: its id keeps its shape (`lock.json`).")
    L.append("")
    L.append("## Legal's conditions, for Animation")
    L.append("")
    L.append("Legal screened the martial arts stance (`docs/legal/movegen-screen.md`, RL-072): every shape is clear, with conditions that bite when a move is held or strung. The Legal column of each row lists the ones that apply, with the tags its posed key set already carries. **The other four stances have not had Legal's screen:** see the last section.")
    L.append("")
    L.append("| Id | Applies to | The pose must keep to | Legal's rows |")
    L.append("| :--- | :--- | :--- | :--- |")
    for cd in g["conditions"]:
        what, ask = cd["ask"].split(": ", 1)
        L.append("| %s | %s | %s | %s |" % (cd["id"], what, ask, ", ".join(cd["rows"])))
    L.append("")
    lgl = parts.get("legal", {})
    L.append("**Legal's other rows** (RL-076, RL-081 to RL-086; `docs/legal/stances-and-gestures-screen.md`). The strike rows above judge strike pieces only; an energy piece is judged by the energy rows, so a lit fist is allowed where its light sits on the plate and knuckle edges and never as a ball at the hand (e01, not b09).")
    L.append("")
    L.append("| Group | Rows | The generator refuses a match | Conditions for the owner |")
    L.append("| :--- | :--- | :--- | :--- |")
    for group in ("motion", "energy", "grabs", "held", "stacking"):
        rows = lgl.get(group, [])
        auto = [r["id"] for r in rows if r.get("kind") in ("travel", "move", "hand", "holdPoints")]
        rest = [r["id"] for r in rows if r["id"] not in auto]
        owner = sorted(set(r.get("owner", "") for r in rows if r["id"] in rest))
        L.append("| %s | %s to %s | %s | %s%s |" % (group, rows[0]["id"], rows[-1]["id"], ", ".join(auto) or "-", ", ".join(rest) or "-", (" (" + "; ".join(o for o in owner if o) + ")") if rest else ""))
    L.append("")
    L.append("**For every move:** no hand cupped at a hip or drawn back to one and thrust (b02); nothing lit on a melee piece, no ball of light, no raised charging pose (b09); no vanish or blink between blows, and no after-image that hides the body (b13). **For every hand:** no two fingers, no pointing finger, no hand to the forehead, no beckon (b10, b11).")
    L.append("")
    L.append("## Summary")
    L.append("")
    L.append("| Stance | Cell | What it holds | " + " | ".join("%s: moves, posed, derived, waiting" % n for n in names) + " |")
    L.append("| :--- | :--- | :--- | " + " | ".join(":---" for _ in names) + " |")
    tot = {n: [0, 0, 0, 0] for n in names}
    for stance in STANCES:
        for btn in ("x", "y", "a", "b"):
            cid = "%s.%s" % (stance, btn)
            cell = cells["stances"].get(stance, {}).get(btn)
            if cell is None:
                continue
            cols = []
            for n in names:
                c = out[n]["cells"][cid]
                if "moves" in c:
                    st = [m["status"] for m in c["moves"]]
                    v = [len(st), st.count("posed"), st.count("derived"), st.count("waiting")]
                    tot[n] = [a + b for a, b in zip(tot[n], v)]
                    cols.append("%d, %d, %d, %d" % tuple(v))
                else:
                    cols.append("not generated" if c["kind"] == "context" else "a frame")
            L.append("| %s | %s | %s | %s |" % (stance, btn.upper(), cell["what"].split(":")[0].split(";")[0], " | ".join(cols)))
    L.append("| **all** | | | " + " | ".join("**%d, %d, %d, %d**" % tuple(tot[n]) for n in names) + " |")
    L.append("")
    if len(names) == 2:
        a, b = names
        rows = []
        for cid, c in out[a]["cells"].items():
            if c["kind"] == "strikes":
                fa = set(fp(m) for m in c["moves"]); fb = set(fp(m) for m in out[b]["cells"][cid]["moves"])
                rows.append((cid, len(fa & fb), len(fa)))
        L.append("**Shapes the two fighters share:** " + "; ".join("%s %d of %d (%d%%)" % (cid, s, n, round(100.0 * s / n)) for cid, s, n in rows) + ".")
        L.append("")
    for who in names:
        if notes[who]["unread"]:
            L.append("**Posed strikes of the %s that the grammar cannot read** (so they give no move): %s." % (who, "; ".join(notes[who]["unread"])))
            L.append("")
    for stance in STANCES:
        if stance not in cells["stances"]:
            continue
        L.append("## The %s stance" % w(stance))
        L.append("")
        for btn in ("x", "y", "a", "b"):
            cell = cells["stances"][stance].get(btn)
            if cell is None:
                continue
            cid = "%s.%s" % (stance, btn)
            L.append("### %s: %s" % (cid, cell["what"]))
            L.append("")
            if cell["kind"] == "context":
                L.append("Pressed: %s. Held: %s. Not generated.%s" % ("; ".join(cell["pressed"]), "; ".join(cell["held"]), (" Legal: " + ", ".join(cell["asks"]) + ".") if cell.get("asks") else ""))
                L.append("")
            elif cell["kind"] == "frame":
                L.append("A frame, the same for both fighters until the kinds are final: " + "; then ".join("%s%s" % (s["slot"], (" (%s)" % ", ".join("%s %s" % (k, v) for k, v in s.items() if k != "slot")) if len(s) > 1 else "") for s in cell["slots"]) + ".")
                L.append("")
                if cell.get("readings"):
                    L.append("Readings: " + "; ".join("%s: %s" % (k, v) for k, v in cell["readings"].items()) + "." + ((" Legal: " + ", ".join(cell["asks"]) + ", and a person's screen.") if cell.get("asks") else ""))
                    L.append("")
            for who in names:
                c = out[who]["cells"][cid]
                if "moves" not in c:
                    continue
                st = [m["status"] for m in c["moves"]]
                mins = {q["name"]: q["min"] for q in cell.get("quotas", [])}
                qt = "; ".join("%s %d of %d" % (k, v, mins[k]) for k, v in c["quotas"].items())
                L.append("**The %s:** %d moves from %d candidates; %d posed, %d derived, %d waiting.%s" % (who if who == "rival" else who.capitalize(), len(st), c["valid"], st.count("posed"), st.count("derived"), st.count("waiting"), (" Quotas: " + qt + ".") if qt else ""))
                if c["kind"] == "special":
                    L.append("%s (`%s`; %s)." % (c["what"].capitalize(), c["special"], c["state"]))
                L.append("")
                if c["kind"] == "strikes":
                    L.append("| # | Limb | Tip | Path | Target | Readings | Sends | Beat | Keys | Status | Legal |")
                    L.append("| ---: | :--- | :--- | :--- | :--- | :--- | :--- | ---: | :--- | :--- | :--- |")
                    for m in c["moves"]:
                        L.append("| %s | %s | %s | %s | %s | %s | %s | %d | %s | %s%s | %s |" % (m["id"].rsplit(".", 1)[1], m["limb"], m["tip"], w(m["path"]), m["target"], ", ".join(m["forms"]), m["sends"], m["beat"],
                                                                                              key_text(m["keys"]), m["status"], "", legal_text(m)))
                    L.append("")
                    if c["refused"]:
                        L.append("Refused by Legal's rows, so never offered: " + "; ".join("%s (%s)" % (" ".join(w(x) for x in r["shape"]), ", ".join(r["rows"])) for r in c["refused"]) + ".")
                        L.append("")
                elif c["kind"] == "travel":
                    if c.get("refused"):
                        L.append("Refused by Legal's rows, so never offered: " + "; ".join("a %s to the %s leaving on the %s (%s)" % (w(r["move"]["kind"]), w(r["move"]["direction"]), w(r["move"]["exit"]), ", ".join(r["rows"])) for r in c["refused"]) + ".")
                        L.append("")
                    L.append("| # | Kind | Band | Direction | Entry | Way out | Blow on arrival | Status | Legal |")
                    L.append("| ---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |")
                    for m in c["moves"]:
                        L.append("| %s | %s | %s | %s | `%s` | %s | %s (`%s`) | %s | %s |" % (m["id"].rsplit(".", 1)[1], w(m["kind"]), m["band"], w(m["direction"]), m["entry"]["set"],
                                                                                           ("`%s`" % m["exit"]["set"]) if m["exit"] else "stays", blow_text(m["blow"]), m["blow"]["set"] or "new", m["status"], legal_text(m)))
                    L.append("")
                elif c["kind"] == "table":
                    if c.get("refused"):
                        L.append("Refused by Legal's rows, so never offered: " + "; ".join("a %s on a %s (%s; %d candidates)" % (w(r["move"]["delivery"]), r["move"]["release"], ", ".join(r["rows"]), r["candidates"]) for r in c["refused"]) + ".")
                        L.append("")
                    L.append("| # | Hand | Release | Body | Delivery | Readings | Keys | Status | Legal |")
                    L.append("| ---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |")
                    for m in c["moves"]:
                        ks = ", ".join("`%s`" % x for x in (m["keys"]["set"], m["keys"]["hand"]) if x) or "new poses"
                        L.append("| %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (m["id"].rsplit(".", 1)[1], w(m["hand"]), m["release"], w(m["body"]), w(m["delivery"]), ", ".join(m["forms"]), ks, m["status"], legal_text(m)))
                    L.append("")
                elif c["kind"] == "special":
                    cols = list(c["moves"][0]["look"].keys())
                    L.append("| # | " + " | ".join(x.capitalize() for x in cols) + " | Readings | Status |")
                    L.append("| ---: | " + " | ".join(":---" for _ in cols) + " | :--- | :--- |")
                    for m in c["moves"]:
                        L.append("| %s | %s | %s | %s |" % (m["id"].rsplit(".", 1)[1], " | ".join(m["look"][x] for x in cols), ", ".join(m["forms"]), m["status"]))
                    L.append("")
        needs = []
        for btn in ("x", "y", "a", "b"):
            for n in cells["stances"][stance].get(btn, {}).get("needs", []):
                if n["what"]:
                    needs.append("%s (%s): %s" % (n["who"], btn.upper(), n["what"]))
        if needs:
            L.append("### What the %s stance needs that does not exist" % w(stance))
            L.append("")
            for n in needs:
                L.append("- " + n)
            L.append("")
    L.append("## For Legal's person screen")
    L.append("")
    L.append("Legal's banned rows and sequence rules are applied to every strike on this sheet: the martial cells, the checks, the pushes, and the blow of every zip, step and charge. They cannot judge what follows, which is new vocabulary or a set piece (`docs/legal/movegen-screen.md` section 3).")
    L.append("")
    for stance in STANCES:
        for btn in ("x", "y", "a", "b"):
            lg = cells["stances"].get(stance, {}).get(btn, {}).get("legal")
            if lg:
                L.append("- **%s %s, the signature:** %s." % (w(stance), btn.upper(), lg))
    L.append("- **New vocabulary:** the travel kinds (zip, zip away, step, charge, pursuit) and their directions; the energy hands, releases, bodies and deliveries; the push; the guard layer; every special's frame, and the Protagonist's three placeholder specials.")
    L.append("- **New grabs:** the aimed throw, the guard throw, the zip tackle and the snatch (condition G1).")
    L.append("")
    return "\n".join(L) + "\n"


def self_test(parts, identity):
    g = parts["strike"]
    rival = identity["fighters"]["rival"]
    proto = identity["fighters"]["protagonist"]
    ok = True
    def expect(name, got, want):
        nonlocal ok
        good = got == want
        ok = ok and good
        print("%s  %s" % ("pass" if good else "FAIL", name) + ("" if good else "  got %r, want %r" % (got, want)))
    palm_head = {"limb": "hand", "tip": "palm", "path": "line", "target": "head", "weight": "light"}
    fl = flags_of(g, rival, palm_head, None)
    expect("the rival's palm to the head is refused (b06)", [r["id"] for r in g["banned"] if banned_hit(r, palm_head, ["light", "flurry"], 1, fl) == "match"], ["b06"])
    expect("the Protagonist's open palm to the head is an ask, not a refusal", [banned_hit(r, palm_head, ["light"], 1, flags_of(g, proto, palm_head, None)) for r in g["banned"] if r["id"] == "b06"], ["ask"])
    clasp = {"limb": "hand", "tip": "fist", "path": "drop", "target": "head", "weight": "heavy"}
    expect("two clasped fists dropped is refused (b05)", [r["id"] for r in g["banned"] if banned_hit(r, clasp, ["heavy"], 2, {"has": ["clasped"], "not": []}) == "match"], ["b05"])
    expect("the same blow on a key set tagged wrists apart is cleared", [banned_hit(r, clasp, ["heavy"], 2, flags_of(g, proto, clasp, {"legal": ["wrists_apart", "no_clasp"], "flags": []})) for r in g["banned"] if r["id"] == "b05"], [None])
    expect("the same blow on a key set Animation measured with no flag is cleared", [banned_hit(r, clasp, ["heavy"], 2, flags_of(g, proto, clasp, {"legal": [], "flags": [], "measured": True})) for r in g["banned"] if r["id"] == "b05"], [None])
    rise = {"limb": "hand", "tip": "fist", "path": "rise", "target": "jaw", "weight": "heavy"}
    expect("a rising fist on a key set Animation flags with a leap is refused (b03)", [r["id"] for r in g["banned"] if banned_hit(r, rise, ["heavy"], 1, flags_of(g, rival, rise, {"legal": [], "flags": ["leap"], "measured": True})) == "match"], ["b03"])
    expect("a lit move is refused whatever its parts (b09)", [r["id"] for r in g["banned"] if banned_hit(r, clasp, ["heavy"], 1, {"has": ["glow"], "not": []}) == "match"], ["b09"])
    expect("a held heavy chambered at a hip is refused (b02, b12)", [r["id"] for r in g["banned"] if banned_hit(r, clasp, ["heavy", "held"], 1, {"has": ["hip_chamber", "cupped_at_hip"], "not": []}) == "match"], ["b02", "b12"])
    parts_ = parts
    expect("a volley thrown on a thrust is refused (e05)", group_hits(parts_, {"hand": "blade_hand", "release": "thrust", "body": "planted", "delivery": "volley"}, "energy"), ["e05"])
    expect("a volley from one flick passes", group_hits(parts_, {"hand": "blade_hand", "release": "flick", "body": "planted", "delivery": "volley"}, "energy"), [])
    expect("the rival's lit fist is not refused: b09 is for strikes, e01 for energy", group_hits(parts_, {"hand": "fist_glow", "release": "thrust", "body": "planted", "delivery": "bolt"}, "energy"), [])
    expect("a hand Legal has not screened is refused (e01, e02, e03)", group_hits(parts_, {"hand": "cupped_pair", "release": "thrust", "body": "planted", "delivery": "bolt"}, "energy"), ["e01", "e02", "e03"])
    expect("a charged shot that is lobbed is refused (e04)", group_hits(parts_, {"hand": "open_palm", "release": "lob", "body": "planted", "delivery": "charged"}, "energy"), ["e04"])
    expect("a far-side zip that leaves on a fade is refused (m04)", group_hits(parts_, {"kind": "zip", "direction": "far_side", "exit": "fade"}, "travel"), ["m04"])
    expect("a far-side zip that leaves round him passes", group_hits(parts_, {"kind": "zip", "direction": "far_side", "exit": "pivot"}, "travel"), [])
    jab = {"limb": "hand", "tip": "blade", "path": "line", "target": "head", "step": ["in", "hold"]}
    gut = {"limb": "hand", "tip": "fist", "path": "line", "target": "gut", "step": ["in", "hold"]}
    spin = {"limb": "foot", "tip": "heel", "path": "spin", "target": "chest", "step": ["around", "out"]}
    rs = {"limb": "hand", "tip": "fist", "path": "rise", "target": "jaw", "step": ["in", "hold"]}
    expect("four of the same blow in a row (s01, s02)", sequence_breaks(g, [jab, jab, jab, jab]), ["s01", "s02"])
    expect("three of the same blow in a row breaks only the target rule (s02)", sequence_breaks(g, [jab, jab, jab]), ["s02"])
    expect("two gut blows running (s02)", sequence_breaks(g, [jab, gut, gut]), ["s02"])
    expect("a spin after a spin (s04)", sequence_breaks(g, [spin, spin]), ["s04"])
    expect("a rise after a rise in the air (s05)", sequence_breaks(g, [rs, dict(rs, target="gut")]), ["s05"])
    expect("the same on the ground is allowed", sequence_breaks(g, [rs, dict(rs, target="gut")], airborne=False), [])
    expect("a two-hand drop after a launch (s06)", sequence_breaks(g, [dict(jab, event="launch"), dict(clasp, arms=2)]), ["s06"])
    expect("a step that is not drawn (s07)", sequence_breaks(g, [dict(jab, step=["blink"])]), ["s07"])
    expect("an ordinary string passes", sequence_breaks(g, [jab, gut, dict(jab, target="chest", path="arc_in"), spin]), [])
    return ok


def main():
    out, parts, identity, cells, notes = build()
    if "--self-test" in sys.argv:
        ok = self_test(parts, identity)
        print("self-test " + ("passed" if ok else "FAILED"))
        sys.exit(0 if ok else 1)
    files = {"moveset.%s.json" % who: dump(doc) for who, doc in out.items()}
    files["lock.json"] = lock_text(out)
    files["review-sheet.md"] = sheet(out, parts, cells, notes)
    for name, text in files.items():
        assert name.endswith(".md") or json.loads(text)
    fresh = legal_findings(out, parts, identity)
    if "--check" in sys.argv:
        stale = [n for n, t in files.items() if not os.path.exists(os.path.join(HERE, n)) or raw(os.path.join(HERE, n)).decode("utf-8") != t]
        on_disk = {who: load(os.path.join(HERE, "moveset.%s.json" % who)) for who in out if os.path.exists(os.path.join(HERE, "moveset.%s.json" % who))}
        bad = sorted(set(fresh + legal_findings(on_disk, parts, identity)))
        print("files: " + ("up to date" if not stale else "OUT OF DATE: " + ", ".join(stale)))
        print("Legal's rows: " + ("no match" if not bad else "%d MATCH" % len(bad)))
        for b in bad:
            print("  " + b)
        sys.exit(1 if (stale or bad) else 0)
    if fresh:
        print("REFUSED TO WRITE: Legal's rows match")
        for b in fresh:
            print("  " + b)
        sys.exit(1)
    for name, text in files.items():
        with io.open(os.path.join(HERE, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    for who, doc in out.items():
        for cid, c in doc["cells"].items():
            if "moves" in c:
                st = [m["status"] for m in c["moves"]]
                ch = notes[who]["changes"].get(cid, {})
                extra = (" | refused %d, dropped %d, re-read %d, new since the lock %d" % (len(c["refused"]), len(ch["dropped"]), len(ch["reread"]), len(ch["new"]))) if c["kind"] == "strikes" else ""
                print("%-12s %-12s %2d of %4d: posed %2d, derived %2d, waiting %2d%s | %s" % (who, cid, len(st), c["valid"], st.count("posed"), st.count("derived"), st.count("waiting"), extra, c["quotas"]))
        for cid, ch in notes[who]["changes"].items():
            for d in ch["dropped"]:
                print("   dropped  %s %s" % (d["id"], d["shape"]))
            for d in ch["reread"]:
                print("   re-read  %s %s: %s -> %s" % (d["id"], d["set"], d["was"], d["now"]))
        print("%-12s seed %d, inputs %s; unread: %s" % (who, doc["generator"]["seed"], doc["generator"]["inputs"], notes[who]["unread"] or "none"))


if __name__ == "__main__":
    main()
