#!/usr/bin/env python3
"""Check the beat-template library against Legal's ln04 and ln05 (docs/legal/beat-templates-screen.md).

Usage: python docs/narrative/beat-check.py [docs/narrative/pending/beat_templates.json]

What it checks (exit 1 on any failure):
  1. No template reads a slot the Cyborg may never read (toll_band, or a name matching the forbidden patterns),
     unless it is marked as never usable for him.
  2. Every template that reads home_wear carries the Cyborg's rule: own breaking yard only.
  3. `wrecked` is a structure or terrain event only.
  4. Every Cyborg sample line passes the voice lint (waiter words, people, toll and casualty words).
  5. The place-and-wear-only templates (fronts and homes) have no toll, count, body, school, hospital, worship or child word in their sample lines.
  6. usable(template, opponent, context) is the filter the picker must apply; it is exercised here on every template.
Standard library only.
"""
import importlib.util, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("ll", os.path.join(HERE, "line-lint.py"))
ll = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ll)

FRONT_BAN = ["toll", "count", "casualt", "body", "bodies", "dead", "died", "killed", "victim", "child", "children", "kid", "kids", "school", "hospital", "church", "mosque", "temple", "chapel", "cathedral", "synagogue"]


def usable(tpl, opponent, ctx, rules):
    """The picker's filter for one template. ctx may carry: home_is_own_yard (bool). Returns (ok, why)."""
    if opponent != "CYBORG":
        return True, ""
    for s in tpl["reads"]:
        if s in rules["cyborg_forbidden_slots"] or any(p in s for p in rules["cyborg_forbidden_slot_patterns"]):
            return False, f"reads '{s}', which the Cyborg may never read"
    if "home_wear" in tpl["reads"] and not ctx.get("home_is_own_yard", False):
        return False, "reads home_wear, valid only for his own breaking yard"
    return True, ""


def main(path):
    d = json.load(open(path, encoding="utf-8"))
    rules = d["picker_rules"]
    bad = 0

    def fail(msg):
        nonlocal bad
        bad += 1
        print("FAIL", msg)

    ids = {t["id"]: t for t in d["templates"]}
    for t in d["templates"]:
        for s in t["reads"]:
            if (s in rules["cyborg_forbidden_slots"] or any(p in s for p in rules["cyborg_forbidden_slot_patterns"])):
                ok, _ = usable(t, "CYBORG", {"home_is_own_yard": True}, rules)
                if ok:
                    fail(f"{t['id']}: reads a forbidden slot but is usable for the Cyborg")
        if "home_wear" in t["reads"]:
            if t.get("cyborg", {}).get("home_wear") != "own_yard_only":
                fail(f"{t['id']}: reads home_wear without the Cyborg's own-yard rule")
            if usable(t, "CYBORG", {"home_is_own_yard": False}, rules)[0]:
                fail(f"{t['id']}: usable for the Cyborg on a claimed town")
            if not usable(t, "CYBORG", {"home_is_own_yard": True}, rules)[0]:
                fail(f"{t['id']}: not usable on his own yard")
        if usable(t, "RIVAL", {}, rules)[0] is not True:
            fail(f"{t['id']}: the filter blocks a non-Cyborg opponent")
    if "tower" not in d["slots"]["wrecked"] or "casualty" not in d["slots"]["wrecked"]:
        fail("the wrecked slot text must say: structure or terrain only, never from a casualty event")
    for s in d["samples"]:
        tpl = ids.get(s["template"])
        if tpl is None:
            fail(f"sample uses an unknown template {s['template']}")
            continue
        for ln in s["lines"]:
            head = {"CYBORG": "## The Cyborg", "RIVAL": "## The rival (the Anti-hero)", "EMPRESS": "## The Empress", "PROTAGONIST": "## The Protagonist" + (", after the fight" if ln.get("after_fight") else "")}.get(ln["who"], "")
            hard, _ = ll.check(ln["text"], head)
            if hard:
                fail(f"{s['template']} {ln['who']}: {ln['text']} {hard}")
            if ln["who"] == "CYBORG" and not usable(tpl, "CYBORG", {"home_is_own_yard": "Slagholt" in s["slots"]}, rules)[0]:
                fail(f"{s['template']}: a Cyborg sample on a template the filter refuses")
            if s["template"] in rules["place_and_wear_only"]:
                for w in FRONT_BAN:
                    if re.search(r"(?<![\w])" + re.escape(w) + r"(?![\w])", ln["text"], re.I):
                        fail(f"{s['template']}: a place-and-wear template says '{w}': {ln['text']}")
    n_cy = sum(1 for s in d["samples"] for ln in s["lines"] if ln["who"] == "CYBORG")
    print(f"{path}: {len(d['templates'])} templates, {len(d['samples'])} samples, {n_cy} Cyborg lines, {bad} failing")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "pending", "beat_templates.json")))
