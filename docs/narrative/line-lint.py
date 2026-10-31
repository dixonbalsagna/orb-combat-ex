#!/usr/bin/env python3
"""Lint forward-facing lines against Orb's rules (docs/narrative/line-lint.json).

Usage: python docs/narrative/line-lint.py FILE.md [FILE.md ...]
       python docs/narrative/line-lint.py --live data/narrative/live_barks.json   (lines carry a source; Orb's own words are exempt from R1 and R8, EP 2026-10-28)
       python docs/narrative/line-lint.py --names docs/narrative/pending/place_names_table.json
Legal c10 (2026-10-16): the block tier always fails (whole-word); the review tier prints CHECK for a human.

A line is any markdown line of the form  > "the line"  (the homework format).
A speaker block starts at a "## " heading. Standard library only.
Exit code 1 if any line fails a hard rule.

Hard rules: R1 length (4 to 15 words, Orb 2026-10-30), R3 banned words, a word said three times,
            R8 the ellipsis rate (more than one line in ten per fighter in a batch, or two in one line),
            R10 (--live only) a rotation keyword (ribs, shoulder, rhythm, calories) said by one fighter in two neighbouring beats.
Reported for a human to check (not failing): every ellipsis (is it hesitation, regret or
            performative exhaustion?), R2 no contraction, R6 not said to the opponent (Orb's 1v1 aim rule),
            a line under 6 words (a complete clause is preferred to a telegram).
--live: an Orb-approved line may be waived by id for the exact rule it breaks (line-lint.json orb_approved_waivers).
"""
import json, math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
LINT = json.load(open(os.path.join(HERE, "line-lint.json"), encoding="utf-8"))
BANNED = LINT["banned_words_orb"] + LINT["banned_words_proposed"]
LO, HI = LINT["rules"]["R1_length"]["min_words"], LINT["rules"]["R1_length"]["max_words"]
LINE = re.compile(r'^>\s*"(.*)"\s*$')
ELL = re.compile(r"\.\.\.|…")


C10 = LINT["c10_tiers"]


def _word(w, text):
    # whole word, so "bombardment" never matches "bomb"; hyphens and slashes inside a term are literal
    return re.search(r"(?<![\w])" + re.escape(w) + r"(?![\w])", text, re.I)


def c10(text):
    """Legal c10: returns (block, review) hits for a line or a place name."""
    block = [w for w in C10["block"] if _word(w, text)]
    review = [w for w in C10["review"] if _word(w, text)]
    near = C10["review_near"]
    words = re.findall(r"[\w']+", text.lower())
    for i, w in enumerate(words):
        if w in near["words"]:
            span = words[max(0, i - near["window_words"]): i + near["window_words"] + 1]
            if any(c in span for c in near["casualty_words"]):
                review.append(f"{w} near a casualty word")
                break
    return block, review


GEM = LINT["gemini_review_2026_10_16"]


def speaker_of(heading):
    h = heading.lower()
    for key in GEM["speaker_bans"]:
        if key in h:
            return key
    if "anti-hero" in h or "rival" in h:
        return "rival"
    return None


CY = LINT["cyborg_ln04_ln05"]


def cyborg_people(line):
    """Legal ln04 and ln05: a Cyborg line never names people, a toll or a casualty. Returns (hard, soft)."""
    hard, soft = [], []
    for w in CY["people_toll_words"]:
        if re.search(r"(?<![\w])" + re.escape(w) + r"(?![\w])", line, re.I):
            hard.append(f"ln05: '{w}' is a people, toll or casualty word, banned in any Cyborg line")
    for w in CY["review_words"]:
        if re.search(r"(?<![\w])" + re.escape(w) + r"(?![\w])", line, re.I):
            soft.append(f"ln05 REVIEW '{w}' (a human reads: it must not be about people)")
    return hard, soft


def check(line, heading="", exempt=False):
    """exempt: the line's source is Orb's own words (line-lint.json orb_own_exemption): R1 and R8 do not apply to it."""
    hard, soft = [], []
    who = speaker_of(heading)
    if who:
        h = heading.lower()
        for w in GEM["speaker_bans"][who]:
            if who == "empress" and w.startswith("guard") and "3v1" in h:
                continue
            if who == "protagonist" and w in ("sorry", "apologise", "apologize", "apology") and "after the fight" in h:
                continue
            if re.search(r"(?<![\w])" + re.escape(w) + r"(?![\w])", line, re.I):
                hard.append(f"Gemini bible: '{w}' is banned for {who}")
    if who == "cyborg":
        h5, s5 = cyborg_people(line)
        hard += h5
        soft += s5
    blk, rev = c10(line)
    for w in blk:
        hard.append(f"c10 block '{w}'")
    for w in rev:
        soft.append(f"c10 REVIEW '{w}' (a human reads this line)")
    n = len(line.split())
    if not (LO <= n <= HI):
        hard.append(f"R1 length {n}")
    for w in BANNED:
        if re.search(r"\b" + re.escape(w) + r"\b", line, re.I):
            hard.append(f"R3 banned word '{w}'")
    if re.search(r"\b(\w+)[,.!?] \1[,.!?] \1\b", line, re.I):
        hard.append("tell: a word said three times")
    if len(ELL.findall(line)) > 1:
        hard.append("R8 more than one ellipsis in a line")
    if exempt:
        hard = [h for h in hard if not (h.startswith("R1 length") or h.startswith("R8 "))]
    if n < LINT["rules"]["R1_length"].get("telegram_check_below_words", 0):
        soft.append(f"R1 telegram: {n} words (a complete clause is preferred)")
    if not re.search(r"\w'\w", line):
        soft.append("R2 no contraction")
    if not re.search(r"\b(you|your|you're|you've|you'll|yours)\b", line, re.I):
        soft.append("R6 not said to the opponent")
    return hard, soft


def main(paths):
    failed = 0
    for p in paths:
        blocks, current, total = {}, "(none)", 0
        for i, raw in enumerate(open(p, encoding="utf-8"), 1):
            t = raw.rstrip("\n")
            if t.startswith("## "):
                current = t[3:].strip()
            m = LINE.match(t)
            if not m:
                continue
            total += 1
            line = m.group(1)
            hard, soft = check(line, current)
            b = blocks.setdefault(current, {"n": 0, "ell": [], "all": []})
            b["n"] += 1
            b["all"].append((i, line))
            if ELL.search(line):
                b["ell"].append((i, line))
                print(f"{p}:{i}: CHECK ellipsis (hesitation, regret or performative exhaustion?)  {line}")
            for s in soft:
                if s.startswith(("c10 REVIEW", "ln05 REVIEW")):
                    print(f"{p}:{i}: CHECK {s}  {line}")
            if hard:
                failed += 1
                print(f"{p}:{i}: FAIL {hard}  {line}")
        for name, b in blocks.items():
            who = speaker_of(name)
            for title, tcap in GEM["title_caps_per_block"].get(who or "", {}).items():
                used = sum(len(re.findall(r"\b" + title + r"\b", ln, re.I)) for _, ln in b["all"])
                if used > tcap:
                    failed += 1
                    print(f"{p}: FAIL title budget in '{name}': '{title}' x{used} (cap {tcap})")
            cap = max(1, b["n"] // 10)
            if len(b["ell"]) > cap:
                failed += 1
                print(f"{p}: FAIL R8 ellipsis rate in '{name}': {len(b['ell'])} of {b['n']} lines (cap {cap})")
        print(f"{p}: {total} lines")
    return 1 if failed else 0


HEAD_OF = {"PROTAGONIST": "## The Protagonist", "RIVAL": "## The rival (the Anti-hero)", "EMPRESS": "## The Empress", "CYBORG": "## The Cyborg"}
OWN = LINT.get("orb_own_exemption", {}).get("sources", [])
WAIVERS = LINT.get("orb_approved_waivers", {}).get("ids", {})
ROT = LINT["rules"].get("R10_rotation", {}).get("keywords", [])


def live(path):
    """Lint a data file whose beats hold lines with a source (data/narrative/live_barks.json). A line whose source is in
    orb_own_exemption.sources is exempt from R1 and R8 (and does not count in the ellipsis rate); all else is strict."""
    d = json.load(open(path, encoding="utf-8"))
    failed, total, exempt, nwaived = 0, 0, 0, 0
    blocks = {}
    seen_ids = set()
    names = list(d.get("beats", {}))
    for bk, b in d.get("beats", {}).items():
        for fid, ls in b.get("lines", {}).items():
            for l in ls:
                total += 1
                own = l.get("source", "") in OWN
                exempt += 1 if own else 0
                head = HEAD_OF.get(fid, "")
                hard, soft = check(l["text"], head, own)
                if l["id"] in seen_ids:
                    hard.append(f"duplicate line id {l['id']}")
                seen_ids.add(l["id"])
                waived = [h for h in hard if h in WAIVERS.get(l["id"], [])]
                hard = [h for h in hard if h not in WAIVERS.get(l["id"], [])]
                nwaived += len(waived)
                for s in soft:
                    if s.startswith("R1 telegram"):
                        print(f"{path}: CHECK {s} [{bk}/{fid}] {l['text']}")
                blk = blocks.setdefault(head, {"n": 0, "ell": []})
                if not own:
                    blk["n"] += 1
                    if ELL.search(l["text"]):
                        blk["ell"].append(l["text"])
                if ELL.search(l["text"]):
                    print(f"{path}: CHECK ellipsis{' (Orb own words, exempt)' if own else ''} [{bk}/{fid}] {l['text']}")
                for s in soft:
                    if s.startswith(("c10 REVIEW", "ln05 REVIEW")):
                        print(f"{path}: CHECK {s} [{bk}/{fid}] {l['text']}")
                if hard:
                    failed += 1
                    print(f"{path}: FAIL {hard} [{bk}/{fid}] {l['text']}")
    for head, b in blocks.items():
        cap = max(1, b["n"] // 10)
        if len(b["ell"]) > cap:
            failed += 1
            print(f"{path}: FAIL R8 ellipsis rate in '{head}': {len(b['ell'])} of {b['n']} non-exempt lines (cap {cap})")
    # R10: a rotation keyword said by one fighter in two neighbouring beats (the file's beat order)
    for fid in HEAD_OF:
        for kw in ROT:
            hit = [i for i, bk in enumerate(names)
                   if any(re.search(r"\b" + kw + r"\b", l["text"], re.I) for l in d["beats"][bk].get("lines", {}).get(fid, []) if l.get("source", "") not in OWN)]
            for a, c in zip(hit, hit[1:]):
                if c - a == 1:
                    failed += 1
                    print(f"{path}: FAIL R10 rotation: {fid} says '{kw}' in back-to-back beats {names[a]} and {names[c]}")
    print(f"{path}: {total} lines, {exempt} exempt as Orb's own words, {nwaived} rule breaks waived by id, {failed} failing")
    return 1 if failed else 0


def names(path):
    """Check a place-name table (JSON {kind: [names]}) against the blocklist and the c10 tiers."""
    table = json.load(open(path, encoding="utf-8"))
    block = set(json.load(open(os.path.join(HERE, "pending", "place_names.json"), encoding="utf-8"))["blocklist_start"])
    bad = 0
    for kind, lst in table.items():
        for n in lst:
            b, r = c10(n)
            r = [w for w in r if w not in C10.get("review_ok_in_place_names", [])]
            if n.lower().replace(" ", "") in block or b or r or (kind != "landmark" and len(n) > 12):
                bad += 1
                print(f"{path}: FAIL {kind} '{n}' {b + r}")
    print(f"{path}: {sum(len(v) for v in table.values())} names, {bad} failing")
    return 1 if bad else 0


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--live":
        sys.exit(live(sys.argv[2]))
    if len(sys.argv) > 2 and sys.argv[1] == "--names":
        sys.exit(names(sys.argv[2]))
    sys.exit(main(sys.argv[1:]))
