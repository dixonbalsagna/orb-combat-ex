#!/usr/bin/env python3
"""The moveset generator, reference version (docs/combat/moveset-generator.md). PARKED with its data.

Reads parts.json, identity.json and cells.json beside it and Animation's strike manifests (data/anim/waves), and
writes one moveset file for each fighter and the review sheet, into this folder.

    python docs/combat/pending/movegen/gen_moveset.py            write the files
    python docs/combat/pending/movegen/gen_moveset.py --check    regenerate in memory and compare with the files

Deterministic: there is no generator state and no clock. The only randomness is a hash of the seed, the fighter,
the cell and the shape. Standard library only.
"""
import hashlib, io, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
VERSION = 1
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


def posed(parts, idn):
    """His posed strikes as shapes: fingerprint -> (level, strike id, key set id, legal tags, arms)."""
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
                    cover[key] = {"level": level, "from": sid, "set": rows[sid]["id"], "legal": list(rows[sid].get("legal", [])), "arms": arms,
                                  "ground": st.get("ground", "ok"), "_rank": rank}
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
    cand = []
    for m in shapes(g):
        if not match(cell["filter"], m):
            continue
        if any(match(r["shape"], m) for r in idn["never"]) or any(match(r["shape"], m) for r in g["banned"]) or list(fp(m)) in rejected:
            continue
        w = weight_of(idn, m)
        if w <= 0:
            continue
        c = cover.get(fp(m))
        m["_w"] = w * (idn["reuse"][c["level"]] if c else 1.0) * jitter(seed, who, cell_id, *fp(m))
        m["_forms"] = forms_of(g, m, c["arms"] if c else (1 if m["limb"] in ("hand", "elbow") else 0))
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
        legal = sorted(set((c["legal"] if c else []) + [r["tag"] for r in g["legalTags"] if match(r["when"], m)]))
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
            "limb": m["limb"], "tip": m["tip"], "path": m["path"], "target": m["target"], "weight": m["weight"],
            "forms": m["_forms"], "step": g["step"][m["path"]], "sends": m["_sends"], "links": g["links"][m["path"]], "beat": g["beat"][m["path"]],
            "keys": keys, "ground": (c["ground"] if c else ("plant" if m["limb"] in ("foot", "knee") else "ok")),
            "status": "posed" if (c and c["level"] == "posed") else "derived" if c else "waiting",
            "legal": legal, "review": "new",
        })
    met = {q["name"]: sum(1 for p in picked if quota_ok(q, p)) for q in cell.get("quotas", [])}
    return moves, valid, met


def build():
    parts = load(os.path.join(HERE, "parts.json"))
    identity = load(os.path.join(HERE, "identity.json"))
    cells = load(os.path.join(HERE, "cells.json"))
    seed, spread = cells["seed"], cells["spread"]
    out, info = {}, {}
    for who in sorted(identity["fighters"]):
        idn = identity["fighters"][who]
        cover, posed_ids = posed(parts, idn)
        h = hashlib.sha256()
        for name in ("parts.json", "identity.json", "cells.json"):
            h.update(raw(os.path.join(HERE, name)))
        for wave in idn["waves"]:
            rows = load(os.path.join(ROOT, "data", "anim", "waves", wave + ".manifest.json"))["strikes"]
            h.update(json.dumps([[s["id"], s["combat"], s.get("legal", [])] for s in rows], sort_keys=True).encode("utf-8"))
        rejected = [r["shape"] for r in identity.get("rejected", []) if r.get("fighter") in (who, "*")]
        doc = {
            "schema": "combat.moveset/1",
            "_target": "data/combat/movesets/%s.json" % who,
            "_about": "GENERATED by gen_moveset.py from parts.json, identity.json, cells.json and Animation's strike manifests. Do not edit by hand: change an input and "
                      "generate again. PARKED: not loaded, not hashed. A move's status is posed (its key set exists), derived (a hand-state swap or a re-aim on a posed key "
                      "set) or waiting (it needs a new key set; the director skips it). review is new until Combat, Animation and Legal have seen the row",
            "fighter": who,
            "generator": {"version": VERSION, "seed": seed, "inputs": h.hexdigest()[:16]},
            "cells": {},
        }
        info[who] = {"posed": posed_ids, "cover": cover}
        for stance in sorted(cells["stances"]):
            for btn in ("x", "y", "a", "b"):
                cell = cells["stances"][stance].get(btn)
                if cell is None:
                    continue
                cid = "%s.%s" % (stance, btn)
                if cell["kind"] == "strikes":
                    moves, valid, met = fill(who, cid, cell, parts, idn, cover, seed, spread, rejected)
                    doc["cells"][cid] = {"kind": "strikes", "valid": valid, "quotas": met, "moves": moves}
                elif cell["kind"] == "context":
                    doc["cells"][cid] = {"kind": "context", "actions": cell["actions"], "held": cell["held"], "_note": "today's actions and their shared poses; nothing generated"}
                else:
                    doc["cells"][cid] = {"kind": "frame", "slots": cell["slots"], "_note": cell["what"]}
        out[who] = doc
    return out, info, parts, identity, cells


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
            lines.append('   "kind": "strikes", "valid": %d, "quotas": %s,' % (c["valid"], json.dumps(c["quotas"])))
            lines.append('   "moves": [')
            for n, m in enumerate(c["moves"]):
                lines.append("    " + json.dumps(m, ensure_ascii=False) + ("," if n < len(c["moves"]) - 1 else ""))
            lines.append("   ]")
            lines.append("  }" + cc)
        lines.append(" }" + comma)
    lines.append("}")
    return "\n".join(lines) + "\n"


WORDS = {"arc_in": "arc in", "arc_out": "arc out", "hand_state": "hand state", "re_aim": "re-aim", "hand_state_re_aim": "hand state and re-aim"}


def w(s):
    return WORDS.get(s, s)


def sheet(out, info, cells):
    L = []
    L.append("# Review sheet: the martial arts stance, both fighters")
    L.append("")
    L.append("GENERATED by `gen_moveset.py` (version %d, seed %d). Do not edit: change an input and generate again. Inputs: `parts.json`, `identity.json`, `cells.json`, and Animation's strike manifests." % (VERSION, cells["seed"]))
    L.append("")
    L.append("How to read a row: the move's parts; the forms it can take; where it sends as an ender; its beat point in ticks; and its keys. **Posed** plays its own key set. **Derived** is a posed key set with the hand closed, bladed or opened, or landed on a neighbouring place: no new sketch, but it needs a look. **Waiting** needs a new key set, and the director skips it until then. The last column is what Legal's rulings ask of the pose.")
    L.append("")
    fps = {}
    for who, doc in out.items():
        fps[who] = {}
        for cid, c in doc["cells"].items():
            if c["kind"] == "strikes":
                fps[who][cid] = set(fp(m) for m in c["moves"])
    names = sorted(out)
    L.append("## Summary")
    L.append("")
    L.append("| Fighter | Cell | Moves | Of valid shapes | Posed | Derived | Waiting | With a leg broken on the ground |")
    L.append("| :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: |")
    for who in names:
        for cid, c in out[who]["cells"].items():
            if c["kind"] != "strikes":
                continue
            st = [m["status"] for m in c["moves"]]
            legless = sum(1 for m in c["moves"] if m["limb"] not in ("foot", "knee") and m["status"] != "waiting")
            L.append("| %s | %s | %d | %d | %d | %d | %d | %d playable |" % (who, cid, len(st), c["valid"], st.count("posed"), st.count("derived"), st.count("waiting"), legless))
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
        L.append("## %s" % ("The " + who if who == "rival" else "The " + who.capitalize()))
        L.append("")
        for cid, c in doc["cells"].items():
            if c["kind"] != "strikes":
                continue
            L.append("### %s: %d moves" % (cid, len(c["moves"])))
            L.append("")
            L.append("| # | Limb | Tip | Path | Target | Forms | Sends | Beat | Keys | Status | Legal asks |")
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
                L.append("| %s | %s | %s | %s | %s | %s | %s | %d | %s | %s | %s |" % (
                    m["id"].rsplit(".", 1)[1], m["limb"], m["tip"], w(m["path"]), m["target"], ", ".join(m["forms"]), m["sends"], m["beat"], ks, m["status"],
                    ", ".join(t.replace("_", " ") for t in m["legal"]) or "-"))
            L.append("")
        waiting = [(cid, m) for cid, c in doc["cells"].items() if c["kind"] == "strikes" for m in c["moves"] if m["status"] == "waiting"]
        L.append("### New key sets for Animation: %d" % len(waiting))
        L.append("")
        for cid, m in waiting:
            L.append("- `%s`: %s, %s, %s to the %s (%s)" % (m["id"], m["limb"], m["tip"], w(m["path"]), m["target"], m["weight"]))
        L.append("")
    return "\n".join(L) + "\n"


def main():
    out, info, parts, identity, cells = build()
    files = {"moveset.%s.json" % who: dump(doc) for who, doc in out.items()}
    files["review-sheet.md"] = sheet(out, info, cells)
    for name, text in files.items():
        assert name.endswith(".md") or json.loads(text)
    if "--check" in sys.argv:
        bad = [n for n, t in files.items() if not os.path.exists(os.path.join(HERE, n)) or raw(os.path.join(HERE, n)).decode("utf-8") != t]
        print("up to date" if not bad else "OUT OF DATE: " + ", ".join(bad))
        sys.exit(1 if bad else 0)
    for name, text in files.items():
        with io.open(os.path.join(HERE, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    for who, doc in out.items():
        for cid, c in doc["cells"].items():
            if c["kind"] == "strikes":
                st = [m["status"] for m in c["moves"]]
                print("%-12s %-10s %2d moves of %3d valid: posed %2d, derived %2d, waiting %2d | quotas %s" % (who, cid, len(st), c["valid"], st.count("posed"), st.count("derived"), st.count("waiting"), c["quotas"]))
        print("%-12s seed %d, inputs %s" % (who, doc["generator"]["seed"], doc["generator"]["inputs"]))


if __name__ == "__main__":
    main()
