#!/usr/bin/env python3
"""Roster sketches: generated movesets for fighters who are not in the build (docs/combat/roster-rows.md).

Standard library only; no clock, no network. It does not touch ../movegen or the recipes.

    python -B docs/combat/pending/roster/build_roster.py            generate, and write this folder's files
    python -B docs/combat/pending/roster/build_roster.py --check    regenerate and compare with this folder's files; the generator's own three lines
    ... --also FILE      more rows to try, from a file shaped like identity.candidates.json (nothing of theirs is written here)
    ... --keep DIR       leave the assembled folder there (parts, cells, every identity row, every moveset), for the pool builder and the cards
    ... --borrowing all  try the other borrowing policy (identity.candidates.json `borrowing` says which is written here); with it nothing is written here

How: the rows of identity.candidates.json are put beside the rows of ../movegen/identity.json in a temporary folder with that folder's parts.json and
cells.json, and ../movegen/gen_moveset.py runs there. A row's `like` is resolved first. The two fighters of the build are generated too, since the share rule of the
heavy cell needs them; their moves must come out as they are in ../movegen, or this stops. Written here: moveset.<key>.json for each sketch,
lock.candidates.json (their ids and shapes, so an id never changes shape) and review-sheet.md (every row of the sketches and of the two, for Legal).
"""
import copy, importlib.util, io, json, os, shutil, sys, tempfile

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.normpath(os.path.join(HERE, "..", "movegen"))


def load(p):
    with io.open(p, encoding="utf-8") as f:
        return json.load(f)


def dump(p, doc):
    with io.open(p, "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(doc, indent=1, ensure_ascii=False) + "\n")


def arg(name):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else None


def common_ids(base):
    """The lights and mediums that more than one fighter of the build has posed: the common pool as it stands."""
    seen = {}
    for who, d in base.items():
        for w in d["waves"]:
            if w in d.get("tierWaves", []):
                continue
            for s in load(os.path.join(BASE, "..", "..", "..", "..", "data", "anim", "waves", w + ".manifest.json"))["strikes"]:
                seen.setdefault(s["combat"], set()).add(who)
    return sorted(k for k, v in seen.items() if len(v) > 1)


def resolve(key, row, base, file_doc, borrowing="common"):
    """A sketch row as a full identity row: the row it is `like`, with what the sketch says laid over it."""
    out = copy.deepcopy(base[row["like"]])
    for k in ("reaimed", "_reaimed", "_pinned", "_tipOf", "_tipFlags", "_waves", "_tierWaves", "adds", "_adds"):   # adds: places added to his locked cells, his alone
        out.pop(k, None)
    out.update({"pinned": {}, "tipOf": {}, "tipFlags": {}})
    out["armsOf"] = {k: v for b_ in base.values() for k, v in b_.get("armsOf", {}).items()}   # what a fighter of the build says of a key set's arms holds for whoever borrows it
    packs = list(row.get("waves", file_doc["packs"]))
    out["waves"] = packs
    out["tierWaves"] = [w for w in packs if any(w in base[b].get("tierWaves", []) for b in base)]
    out["borrows"] = list(row.get("borrows", packs))
    for k, v in row.items():
        if k in ("like", "energy", "waves", "borrows"):
            continue
        out[k] = copy.deepcopy(v)
    en = row.get("energy", {})
    for k, v in en.items():
        if k != "reach":
            out["energy"][k] = copy.deepcopy(v)
    if "reach" in en:   # energy in reach by name: key sets of the fighters in the build, until his own are drawn
        r = file_doc["reach"][en["reach"]]
        out["energy"]["reach"] = {k: copy.deepcopy(v) for k, v in r.items() if k != "energyWaves"}
        out["energy"]["reach"]["_borrowed"] = "the `%s` set of identity.candidates.json: nothing of his own is drawn" % en["reach"]
        out["energyWaves"] = list(r["energyWaves"])
    if borrowing == "common":   # of a pack he borrows he reads only what more than one fighter of the build already has
        out["borrowIds"] = common_ids(base)
    out["specials"] = copy.deepcopy(base["protagonist"]["specials"])
    out["specials"]["_about"] = "PLACEHOLDERS, taken from the Protagonist's placeholders so that the charging row is not empty: his specials are not designed"
    return out


def main():
    check = "--check" in sys.argv
    base_idn = load(os.path.join(BASE, "identity.json"))
    cand = load(os.path.join(HERE, "identity.candidates.json"))
    rows = dict(cand["fighters"])
    extra = []
    if arg("--also"):
        also = load(arg("--also"))
        for k, v in also["fighters"].items():
            rows[k] = v
            extra.append(k)
    mine = [k for k in rows if k not in extra]
    borrowing = arg("--borrowing") or cand.get("borrowing", "common")
    dry = borrowing != cand.get("borrowing", "common") or "--dry" in sys.argv   # --dry: generate and report, write nothing here
    idn = copy.deepcopy(base_idn)
    for k, row in rows.items():
        assert k not in base_idn["fighters"], "%s is a fighter of the build" % k
        idn["fighters"][k] = resolve(k, row, base_idn["fighters"], cand, borrowing)
    tmp = tempfile.mkdtemp(prefix="roster_")
    try:
        for n in ("parts.json", "cells.json"):
            shutil.copyfile(os.path.join(BASE, n), os.path.join(tmp, n))
        dump(os.path.join(tmp, "identity.json"), idn)
        lock = load(os.path.join(BASE, "lock.json"))
        lp = os.path.join(HERE, "lock.candidates.json")
        if os.path.exists(lp) and not dry:
            for k, v in load(lp)["fighters"].items():
                if k in rows:
                    lock["fighters"][k] = v
        dump(os.path.join(tmp, "lock.json"), lock)
        if check:   # what this folder holds, as the generator would find it
            for k in mine:
                p = os.path.join(HERE, "moveset.%s.json" % k)
                if os.path.exists(p):
                    shutil.copyfile(p, os.path.join(tmp, "moveset.%s.json" % k))
            for k in base_idn["fighters"]:
                shutil.copyfile(os.path.join(BASE, "moveset.%s.json" % k), os.path.join(tmp, "moveset.%s.json" % k))
        spec = importlib.util.spec_from_file_location("gen_moveset", os.path.join(BASE, "gen_moveset.py"))
        gen = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(gen)
        gen.HERE = tmp   # its inputs and outputs; Animation's and Legal's files are still read from the repo
        recipes = os.path.normpath(os.path.join(BASE, "..", "recipes.brawl.json"))
        if check:
            # the generator's own check would call the two fighters' files out of date (their inputs line names this roster), so compare the moves here
            out, parts, identity, cells, notes = gen.build()
            rep = gen.string_report(out, parts, cells)
            dead = gen.string_findings(rep, identity) + gen.share_findings(out, cells, identity)
            gate = gen.gate_shares(out, cells, identity)
            under = gen.gate_findings(gate, cells)
            bad = gen.legal_findings(out, parts, identity)
            stale = [k for k in mine if not os.path.exists(os.path.join(HERE, "moveset.%s.json" % k))
                     or load(os.path.join(HERE, "moveset.%s.json" % k))["cells"] != json.loads(gen.dump(out[k]))["cells"]]
            moved = [k for k in base_idn["fighters"] if any(c.get("moves") != json.loads(gen.dump(out[k]))["cells"][cid].get("moves")
                                                             for cid, c in load(os.path.join(BASE, "moveset.%s.json" % k))["cells"].items())]
            print("sketches: " + ("up to date" if not stale else "OUT OF DATE: " + ", ".join(stale)))
            print("the two in the build: " + ("their moves are as in ../movegen" if not moved else "MOVED: " + ", ".join(moved)))
            print("Legal's rows: " + ("no match" if not bad else "%d MATCH" % len(bad)))
            for b in bad:
                print("  " + b)
            print("strings and shares: " + ("no dead end" if not dead else "%d PROBLEM" % len(dead)))
            for b in dead:
                print("  " + b)
            # Game Design's gate on blows: the part of what he throws that only he has. today: what is posed; planned: with his own that wait drawn; and the draw
            # weight his own would need for a quarter. Each is his worst over the rosters he may be in (one option of every `alt` group)
            print("own blows, of the gate's quarter (today; with his own drawn; the draw weight on his own that reaches a quarter):")
            for k in sorted(gate, key=lambda f: (f not in base_idn["fighters"], f)):
                r = gate[k]
                print("  %-15s %3d%%  %3d%%  %s%s" % (k, round(100 * r["today"]), round(100 * r["planned"]), ("x%g" % r["weight"]) if r["weight"] else "none reaches it",
                                              "" if r["planned"] >= cells["gate"]["quarter"] else ("  short of a quarter" if r["planned"] >= cells["gate"]["fifth"] else "  UNDER a fifth")))
            sys.exit(1 if (stale or moved or bad or dead or under) else 0)
        argv, sys.argv = sys.argv, [os.path.join(BASE, "gen_moveset.py"), "--recipes", recipes]
        try:
            # twice: the first run locks every sketch's moves, and the second counts what each shares with the others now that all of them are locked.
            # A third run would change nothing (--check proves it)
            for again in (False, True):
                try:
                    if again:
                        sys.stdout = io.StringIO()
                    gen.main()
                except SystemExit as e:
                    if e.code not in (0, None):
                        sys.stdout = sys.__stdout__
                        print("the generator stopped: nothing is written here")
                        sys.exit(e.code)
                finally:
                    sys.stdout = sys.__stdout__
        finally:
            sys.argv = argv
        for k in base_idn["fighters"]:   # the two in the build must be untouched by the company they keep
            a, b = load(os.path.join(BASE, "moveset.%s.json" % k))["cells"], load(os.path.join(tmp, "moveset.%s.json" % k))["cells"]
            moved = [cid for cid in a if a[cid].get("moves") != b[cid].get("moves")]
            assert not moved, "%s: his moves differ from ../movegen in %s" % (k, moved)
        keep = arg("--keep")
        if keep:
            if os.path.isdir(keep):
                shutil.rmtree(keep)
            shutil.copytree(tmp, keep)
        if dry:
            print("tried (borrowing %s), and nothing written here" % borrowing)
            return
        for k in mine:
            shutil.copyfile(os.path.join(tmp, "moveset.%s.json" % k), os.path.join(HERE, "moveset.%s.json" % k))
        new_lock = load(os.path.join(tmp, "lock.json"))
        dump(lp, {"schema": new_lock.get("schema", "combat.lock/1"),
                  "_about": "GENERATED by build_roster.py: the ids and shapes of the sketches' strike moves, so an id never changes shape. The two fighters of the build are "
                            "locked in ../movegen/lock.json",
                  "fighters": {k: new_lock["fighters"][k] for k in mine if k in new_lock["fighters"]}})
        shutil.copyfile(os.path.join(tmp, "review-sheet.md"), os.path.join(HERE, "review-sheet.md"))
        keep = arg("--keep")
        if keep:
            if os.path.isdir(keep):
                shutil.rmtree(keep)
            shutil.copytree(tmp, keep)
        print("written here: %s; lock.candidates.json; review-sheet.md%s" % (", ".join("moveset.%s.json" % k for k in mine), ("; tried and not written: " + ", ".join(extra)) if extra else ""))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
