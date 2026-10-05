#!/usr/bin/env python3
"""The moveset generator, reference version (docs/combat/moveset-generator.md). PARKED with its data.

Reads parts.json, identity.json and cells.json beside it and Animation's strike manifests (data/anim/waves), and
writes one moveset file for each fighter and the review sheet, into this folder.

    python docs/combat/pending/movegen/gen_moveset.py              write the files
    python docs/combat/pending/movegen/gen_moveset.py --check      regenerate and compare with the files; test the files
                                                                   on disk and Combat's own strings against Legal's rows
    python docs/combat/pending/movegen/gen_moveset.py --self-test  prove the refusals on made-up moves and strings
    ... --recipes PATH                                             the recipes file whose blur patterns are tested
                                                                   (default: ../recipes.brawl.json, else the live file)

Deterministic: there is no generator state and no clock. The only randomness is a hash of the seed, the fighter,
the cell and the shape. Standard library only.

Legal's rows (parts.json strike.banned, strike.bannedSequences) are never emitted: a candidate shape that matches a
shape row is dropped before the pick, and --check exits 1 if a move in a file, a frame, the links table or a blur
pattern matches a row.
"""
import hashlib, io, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
VERSION = 2
LEVELS = ["posed", "hand_state", "re_aim", "hand_state_re_aim"]


def load(path):
    with io.open(path, encoding="utf-8") as f:
        return json.load(f)


def raw(path):
    with io.open(path, "rb") as f:
        return f.read().replace(b"\r\n", b"\n")


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


# ---------------------------------------------------------------- what is posed

def posed(parts, idn):
    """His posed strikes as shapes: fingerprint -> the key set it comes from and how."""
    g = parts["strike"]
    rows = {}
    for wave in idn["waves"]:
        for s in load(os.path.join(ROOT, "data", "anim", "waves", wave + ".manifest.json"))["strikes"]:
            if s["combat"] in parts["strikes"]:
                rows[s["combat"]] = s
    cover = {}
    for sid in sorted(rows):
        st = dict(parts["strikes"][sid])
        tip = idn.get("tipOf", {}).get(sid, st["tip"])
        arms = int(st.get("uses", {}).get("arms", 1 if st["limb"] in ("hand", "elbow") else 0))
        tips = [tip]
        if st["limb"] == "hand" and tip in g["swap"]:
            keep = [g["tagTips"][t] for t in rows[sid].get("legal", []) if t in g.get("tagTips", {})]
            tips += [t for t in g["swap"] if t != tip and st["path"] in g["tips"]["hand"][t] and all(t in k for k in keep)]
        targets = [st["target"]]
        if st["limb"] in g["reaim"]["limbs"]:
            targets += [t for t in g["reaim"]["neighbours"].get(st["target"], []) if t in g["targets"][st["limb"]][st["path"]]]
        for t in tips:
            for tg in targets:
                level = "posed" if (t == tip and tg == st["target"]) else "hand_state" if tg == st["target"] else "re_aim" if t == tip else "hand_state_re_aim"
                key = (st["limb"], t, st["path"], tg, st["weight"])
                rank = (LEVELS.index(level), 0 if arms <= 1 else 1)
                if key not in cover or rank < cover[key]["_rank"]:
                    cover[key] = {"level": level, "from": sid, "set": rows[sid]["id"], "legal": list(rows[sid].get("legal", [])),
                                  "flags": list(rows[sid].get("flags", [])), "arms": arms, "ground": st.get("ground", "ok"), "_rank": rank}
    return cover, sorted(rows)


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
        return m["_sends"] == q["sends"]
    return match({"any": q["any"]} if "any" in q else q["filter"], m)


def fill(who, cell_id, cell, parts, idn, cover, seed, spread, rejected):
    g = parts["strike"]
    cand, refused = [], []
    for m in shapes(g):
        if not match(cell["filter"], m):
            continue
        if any(match(r["shape"], m) for r in idn["never"]) or list(fp(m)) in rejected:
            continue
        w = weight_of(idn, m)
        if w <= 0:
            continue
        c = cover.get(fp(m))
        m["_arms"] = c["arms"] if c else (1 if m["limb"] in ("hand", "elbow") else 0)
        m["_forms"] = forms_of(g, m, m["_arms"])
        m["_flags"] = flags_of(g, idn, m, c)
        hits = [(r["id"], banned_hit(r, m, m["_forms"], m["_arms"], m["_flags"])) for r in g["banned"]]
        if any(h == "match" for _, h in hits):
            refused.append({"shape": list(fp(m)), "rows": [i for i, h in hits if h == "match"]})
            continue
        m["_w"] = w * (idn["reuse"][c["level"]] if c else 1.0) * jitter(seed, who, cell_id, *fp(m))
        m["_sends"] = g["sends"][m["path"]]
        cand.append(m)
    valid = len(cand)
    picked = []
    while cand and len(picked) < cell["count"]:
        pool = cand
        for q in cell.get("quotas", []):
            if sum(1 for p in picked if quota_ok(q, p)) < q["min"] and any(quota_ok(q, m) for m in cand):
                pool = [m for m in cand if quota_ok(q, m)]
                break
        best, bs = None, -1.0
        for m in pool:
            w = m["_w"]
            for p in picked:
                if p["path"] == m["path"]:
                    w *= spread["path"]
                if p["target"] == m["target"]:
                    w *= spread["target"]
                if p["tip"] == m["tip"]:
                    w *= spread["tip"]
                if (p["limb"], p["path"], p["target"]) == (m["limb"], m["path"], m["target"]):
                    w *= spread["shape"]
            if w > bs:
                best, bs = m, w
        cand.remove(best)
        picked.append(best)
    moves = []
    for i, m in enumerate(picked):
        c = cover.get(fp(m))
        probe = dict(m); probe["arms"] = m["_arms"]
        asks = [cd["id"] for cd in g["conditions"] if match(cd["when"], probe)]
        if c is None:
            keys = {"level": "new"}
        else:
            keys = {"level": c["level"], "from": c["from"], "set": c["set"]}
            if c["level"] in ("hand_state", "hand_state_re_aim"):
                keys["hand"] = m["tip"]
            if c["level"] in ("re_aim", "hand_state_re_aim"):
                keys["aim"] = m["target"]
        moves.append({
            "id": "mv.%s.%s.%02d" % (who, cell_id, i + 1),
            "limb": m["limb"], "tip": m["tip"], "path": m["path"], "target": m["target"], "weight": m["weight"], "arms": m["_arms"],
            "forms": m["_forms"], "step": g["step"][m["path"]], "sends": m["_sends"], "links": g["links"][m["path"]], "beat": g["beat"][m["path"]],
            "keys": keys, "ground": (c["ground"] if c else ("plant" if m["limb"] in ("foot", "knee") else "ok")),
            "status": "posed" if (c and c["level"] == "posed") else "derived" if c else "waiting",
            "flags": m["_flags"]["has"], "legal": sorted(c["legal"]) if c else [], "asks": asks, "review": "new",
        })
    met = {q["name"]: sum(1 for p in picked if quota_ok(q, p)) for q in cell.get("quotas", [])}
    return moves, valid, met, refused


def build():
    parts = load(os.path.join(HERE, "parts.json"))
    identity = load(os.path.join(HERE, "identity.json"))
    cells = load(os.path.join(HERE, "cells.json"))
    seed, spread = cells["seed"], cells["spread"]
    out = {}
    for who in sorted(identity["fighters"]):
        idn = identity["fighters"][who]
        cover, _ = posed(parts, idn)
        h = hashlib.sha256()
        for name in ("parts.json", "identity.json", "cells.json"):
            h.update(raw(os.path.join(HERE, name)))
        for wave in idn["waves"]:
            rows = load(os.path.join(ROOT, "data", "anim", "waves", wave + ".manifest.json"))["strikes"]
            h.update(json.dumps([[s["id"], s["combat"], s.get("legal", []), s.get("flags", [])] for s in rows], sort_keys=True).encode("utf-8"))
        rejected = [r["shape"] for r in identity.get("rejected", []) if r.get("fighter") in (who, "*")]
        doc = {
            "schema": "combat.moveset/1",
            "_target": "data/combat/movesets/%s.json" % who,
            "_about": "GENERATED by gen_moveset.py from parts.json, identity.json, cells.json and Animation's strike manifests. Do not edit by hand: change an input and "
                      "generate again. PARKED: not loaded, not hashed. A move's status is posed (its key set exists), derived (a hand-state swap or a re-aim on a posed key "
                      "set) or waiting (it needs a new key set; the director skips it). flags are the pose flags it is known to have; legal are Legal's tags on the key set "
                      "it starts from; asks are Legal's conditions for its pose (parts.json strike.conditions). review is new until Combat, Animation and Legal have seen the row",
            "fighter": who,
            "generator": {"version": VERSION, "seed": seed, "inputs": h.hexdigest()[:16]},
            "cells": {},
        }
        for stance in sorted(cells["stances"]):
            for btn in ("x", "y", "a", "b"):
                cell = cells["stances"][stance].get(btn)
                if cell is None:
                    continue
                cid = "%s.%s" % (stance, btn)
                if cell["kind"] == "strikes":
                    moves, valid, met, refused = fill(who, cid, cell, parts, idn, cover, seed, spread, rejected)
                    doc["cells"][cid] = {"kind": "strikes", "valid": valid, "refused": refused, "quotas": met, "moves": moves}
                elif cell["kind"] == "context":
                    doc["cells"][cid] = {"kind": "context", "actions": cell["actions"], "held": cell["held"], "_note": "today's actions and their shared poses; nothing generated"}
                else:
                    doc["cells"][cid] = {"kind": "frame", "slots": cell["slots"], "_note": cell["what"]}
        out[who] = doc
    return out, parts, identity, cells


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
            if c["kind"] != "strikes":
                lines.append("  %s: %s%s" % (json.dumps(cid), json.dumps(c, ensure_ascii=False), cc))
                continue
            lines.append("  %s: {" % json.dumps(cid))
            lines.append('   "kind": "strikes", "valid": %d, "refused": %s, "quotas": %s,' % (c["valid"], json.dumps(c["refused"]), json.dumps(c["quotas"])))
            lines.append('   "moves": [')
            for n, m in enumerate(c["moves"]):
                lines.append("    " + json.dumps(m, ensure_ascii=False) + ("," if n < len(c["moves"]) - 1 else ""))
            lines.append("   ]")
            lines.append("  }" + cc)
        lines.append(" }" + comma)
    lines.append("}")
    return "\n".join(lines) + "\n"


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
            if c["kind"] != "strikes":
                continue
            for m in c["moves"]:
                flags = {"has": m.get("flags", []), "not": []}
                for r in g["banned"]:
                    if banned_hit(r, m, m["forms"], m.get("arms", 1), flags) == "match":
                        bad.append("%s: %s matches %s" % (who, m["id"], r["id"]))
                if any(match(n["shape"], m) for n in idn["never"]):
                    bad.append("%s: %s matches one of his never rows" % (who, m["id"]))
                br = sequence_breaks(g, [m])
                if br:
                    bad.append("%s: %s breaks %s" % (who, m["id"], ", ".join(br)))
    # the links table: what the grammar lets follow what
    for p, nexts in g["links"].items():
        for q in nexts:
            br = [b for b in sequence_breaks(g, [{"path": p}, {"path": q}]) if b in ("s04", "s05")]
            if br:
                bad.append("links: %s then %s breaks %s" % (p, q, ", ".join(br)))
    # Combat's own strings: the blur patterns, with the wrap from the last step to the first
    rp = recipes_path()
    if os.path.exists(rp):
        for name, steps in load(rp).get("blurPatterns", {}).items():
            seq = [{"limb": s[0], "target": s[1]} for s in steps]
            br = sequence_breaks(g, seq + seq[:2])
            if br:
                bad.append("blur pattern %s (%s) breaks %s" % (name, os.path.relpath(rp, ROOT).replace(os.sep, "/"), ", ".join(br)))
    return bad


WORDS = {"arc_in": "arc in", "arc_out": "arc out", "hand_state": "hand state", "re_aim": "re-aim", "hand_state_re_aim": "hand state and re-aim"}


def w(s):
    return WORDS.get(s, s)


def sheet(out, parts, cells):
    g = parts["strike"]
    L = []
    L.append("# Review sheet: the martial arts stance, both fighters")
    L.append("")
    L.append("GENERATED by `gen_moveset.py` (version %d, seed %d). Do not edit: change an input and generate again. Inputs: `parts.json`, `identity.json`, `cells.json`, and Animation's strike manifests." % (VERSION, cells["seed"]))
    L.append("")
    L.append("How to read a row: the move's parts; the forms it can take; where it sends as an ender; its beat point in ticks; and its keys. **Posed** plays its own key set. **Derived** is a posed key set with the hand closed, bladed or opened, or landed on a neighbouring place: no new sketch, but it needs a look. **Waiting** needs a new key set, and the director skips it until then.")
    L.append("")
    L.append("## Legal's conditions, for Animation")
    L.append("")
    L.append("Legal screened this sheet (`docs/legal/movegen-screen.md`, RL-072): every shape is clear, with conditions that bite when a move is held or strung. The last column of each row lists the ones that apply to it, with the tags its posed key set already carries.")
    L.append("")
    L.append("| Id | Applies to | The pose must keep to | Legal's rows |")
    L.append("| :--- | :--- | :--- | :--- |")
    for cd in g["conditions"]:
        what, ask = cd["ask"].split(": ", 1)
        L.append("| %s | %s | %s | %s |" % (cd["id"], what, ask, ", ".join(cd["rows"])))
    L.append("")
    L.append("**For every move:** no hand cupped at a hip or drawn back to one and thrust (b02); nothing lit, no ball of light, no raised charging pose (b09); no vanish or blink between blows, and no after-image that hides the body (b13). **For every hand:** no two fingers, no pointing finger, no hand to the forehead, no beckon (b10, b11).")
    L.append("")
    names = sorted(out)
    fps = {who: {cid: set(fp(m) for m in c["moves"]) for cid, c in out[who]["cells"].items() if c["kind"] == "strikes"} for who in names}
    L.append("## Summary")
    L.append("")
    L.append("| Fighter | Cell | Moves | Of valid shapes | Refused by Legal's rows | Posed | Derived | Waiting | With a leg broken on the ground |")
    L.append("| :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
    for who in names:
        for cid, c in out[who]["cells"].items():
            if c["kind"] != "strikes":
                continue
            st = [m["status"] for m in c["moves"]]
            legless = sum(1 for m in c["moves"] if m["limb"] not in ("foot", "knee") and m["status"] != "waiting")
            L.append("| %s | %s | %d | %d | %d | %d | %d | %d | %d playable |" % (who, cid, len(st), c["valid"], len(c["refused"]), st.count("posed"), st.count("derived"), st.count("waiting"), legless))
    L.append("")
    L.append("| Fighter | Cell | Quotas met (name: have of least) |")
    L.append("| :--- | :--- | :--- |")
    for who in names:
        for cid, c in out[who]["cells"].items():
            if c["kind"] != "strikes":
                continue
            stance, btn = cid.split(".")
            mins = {q["name"]: q["min"] for q in cells["stances"][stance][btn]["quotas"]}
            L.append("| %s | %s | %s |" % (who, cid, "; ".join("%s: %d of %d" % (k, v, mins[k]) for k, v in c["quotas"].items())))
    L.append("")
    if len(names) == 2:
        a, b = names
        L.append("| Cell | Shapes the two fighters share |")
        L.append("| :--- | ---: |")
        tot_s = tot_n = 0
        for cid in fps[a]:
            s = len(fps[a][cid] & fps[b][cid]); n = len(fps[a][cid])
            tot_s += s; tot_n += n
            L.append("| %s | %d of %d (%d%%) |" % (cid, s, n, round(100.0 * s / n)))
        L.append("| both | %d of %d (%d%%) |" % (tot_s, tot_n, round(100.0 * tot_s / tot_n)))
        L.append("")
    for who in names:
        doc = out[who]
        L.append("## The %s" % (who if who == "rival" else who.capitalize()))
        L.append("")
        for cid, c in doc["cells"].items():
            if c["kind"] != "strikes":
                continue
            L.append("### %s: %d moves" % (cid, len(c["moves"])))
            L.append("")
            L.append("| # | Limb | Tip | Path | Target | Forms | Sends | Beat | Keys | Status | Legal |")
            L.append("| ---: | :--- | :--- | :--- | :--- | :--- | :--- | ---: | :--- | :--- | :--- |")
            for m in c["moves"]:
                k = m["keys"]
                if k["level"] == "new":
                    ks = "a new key set"
                else:
                    ks = "%s: `%s`" % (w(k["level"]), k["set"])
                    if "hand" in k:
                        ks += ", hand %s" % k["hand"]
                    if "aim" in k:
                        ks += ", to the %s" % k["aim"]
                lg = ", ".join(m["asks"])
                if m["legal"]:
                    lg += ("; " if lg else "") + "carries: " + ", ".join(t.replace("_", " ") for t in m["legal"])
                L.append("| %s | %s | %s | %s | %s | %s | %s | %d | %s | %s | %s |" % (
                    m["id"].rsplit(".", 1)[1], m["limb"], m["tip"], w(m["path"]), m["target"], ", ".join(m["forms"]), m["sends"], m["beat"], ks, m["status"], lg or "-"))
            L.append("")
            if c["refused"]:
                L.append("Refused by Legal's rows, so never offered: " + "; ".join("%s (%s)" % (" ".join(w(x) for x in r["shape"]), ", ".join(r["rows"])) for r in c["refused"]) + ".")
                L.append("")
        waiting = [(cid, m) for cid, c in doc["cells"].items() if c["kind"] == "strikes" for m in c["moves"] if m["status"] == "waiting"]
        L.append("### New key sets for Animation: %d" % len(waiting))
        L.append("")
        for cid, m in waiting:
            L.append("- `%s`: %s, %s, %s to the %s (%s); %s" % (m["id"], m["limb"], m["tip"], w(m["path"]), m["target"], m["weight"], ", ".join(m["asks"]) or "no condition"))
        L.append("")
    return "\n".join(L) + "\n"


def self_test(parts, identity):
    g = parts["strike"]
    rival = identity["fighters"]["rival"]
    ok = True
    def expect(name, got, want):
        nonlocal ok
        good = got == want
        ok = ok and good
        print("%s  %s" % ("pass" if good else "FAIL", name) + ("" if good else "  got %r, want %r" % (got, want)))
    palm_head = {"limb": "hand", "tip": "palm", "path": "line", "target": "head", "weight": "light"}
    fl = flags_of(g, rival, palm_head, None)
    expect("the rival's palm to the head is refused (b06)", [r["id"] for r in g["banned"] if banned_hit(r, palm_head, ["light", "flurry"], 1, fl) == "match"], ["b06"])
    proto = identity["fighters"]["protagonist"]
    expect("the Protagonist's open palm to the head is an ask, not a refusal", [banned_hit(r, palm_head, ["light"], 1, flags_of(g, proto, palm_head, None)) for r in g["banned"] if r["id"] == "b06"], ["ask"])
    clasp = {"limb": "hand", "tip": "fist", "path": "drop", "target": "head", "weight": "heavy"}
    expect("two clasped fists dropped is refused (b05)", [r["id"] for r in g["banned"] if banned_hit(r, clasp, ["heavy"], 2, {"has": ["clasped"], "not": []}) == "match"], ["b05"])
    expect("the same blow on a key set tagged wrists apart is cleared", [banned_hit(r, clasp, ["heavy"], 2, flags_of(g, proto, clasp, {"legal": ["wrists_apart", "no_clasp"], "flags": []})) for r in g["banned"] if r["id"] == "b05"], [None])
    expect("a lit move is refused whatever its parts (b09)", [r["id"] for r in g["banned"] if banned_hit(r, clasp, ["heavy"], 1, {"has": ["glow"], "not": []}) == "match"], ["b09"])
    expect("a held heavy chambered at a hip is refused (b02, b12)", [r["id"] for r in g["banned"] if banned_hit(r, clasp, ["heavy", "held"], 1, {"has": ["hip_chamber", "cupped_at_hip"], "not": []}) == "match"], ["b02", "b12"])
    jab = {"limb": "hand", "tip": "blade", "path": "line", "target": "head", "step": ["in", "hold"]}
    gut = {"limb": "hand", "tip": "fist", "path": "line", "target": "gut", "step": ["in", "hold"]}
    spin = {"limb": "foot", "tip": "heel", "path": "spin", "target": "chest", "step": ["around", "out"]}
    rise = {"limb": "hand", "tip": "fist", "path": "rise", "target": "jaw", "step": ["in", "hold"]}
    expect("four of the same blow in a row (s01, s02)", sequence_breaks(g, [jab, jab, jab, jab]), ["s01", "s02"])
    expect("three of the same blow in a row breaks only the target rule (s02)", sequence_breaks(g, [jab, jab, jab]), ["s02"])
    expect("two gut blows running (s02)", sequence_breaks(g, [jab, gut, gut]), ["s02"])
    expect("a spin after a spin (s04)", sequence_breaks(g, [spin, spin]), ["s04"])
    expect("a rise after a rise in the air (s05)", sequence_breaks(g, [rise, dict(rise, target="gut")]), ["s05"])
    expect("the same on the ground is allowed", sequence_breaks(g, [rise, dict(rise, target="gut")], airborne=False), [])
    expect("a two-hand drop after a launch (s06)", sequence_breaks(g, [dict(jab, event="launch"), dict(clasp, arms=2)]), ["s06"])
    expect("a step that is not drawn (s07)", sequence_breaks(g, [dict(jab, step=["blink"])]), ["s07"])
    expect("an ordinary string passes", sequence_breaks(g, [jab, gut, dict(jab, target="chest", path="arc_in"), spin]), [])
    return ok


def main():
    out, parts, identity, cells = build()
    if "--self-test" in sys.argv:
        ok = self_test(parts, identity)
        print("self-test " + ("passed" if ok else "FAILED"))
        sys.exit(0 if ok else 1)
    files = {"moveset.%s.json" % who: dump(doc) for who, doc in out.items()}
    files["review-sheet.md"] = sheet(out, parts, cells)
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
            if c["kind"] == "strikes":
                st = [m["status"] for m in c["moves"]]
                print("%-12s %-10s %2d moves of %3d valid (%d refused): posed %2d, derived %2d, waiting %2d | quotas %s" % (
                    who, cid, len(st), c["valid"], len(c["refused"]), st.count("posed"), st.count("derived"), st.count("waiting"), c["quotas"]))
        print("%-12s seed %d, inputs %s" % (who, doc["generator"]["seed"], doc["generator"]["inputs"]))


if __name__ == "__main__":
    main()
