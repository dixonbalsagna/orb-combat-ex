#!/usr/bin/env python3
"""Lint forward-facing lines against Orb's rules (docs/narrative/line-lint.json).

Usage: python docs/narrative/line-lint.py FILE.md [FILE.md ...]
       python docs/narrative/line-lint.py --names docs/narrative/pending/place_names_table.json
Legal c10 (2026-10-16): the block tier always fails (whole-word); the review tier prints CHECK for a human.

A line is any markdown line of the form  > "the line"  (the homework format).
A speaker block starts at a "## " heading. Standard library only.
Exit code 1 if any line fails a hard rule.

Hard rules: R1 length (4 to 12 words), R3 banned words, a word said three times,
            R8 the ellipsis rate (more than one line in ten per fighter in a batch, or two in one line).
Reported for a human to check (not failing): every ellipsis (is it hesitation, regret or
            performative exhaustion?), R2 no contraction, R6 not said to the opponent.
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


def check(line, heading=""):
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
                if s.startswith("c10 REVIEW"):
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


def names(path):
    """Check a place-name table (JSON {kind: [names]}) against the blocklist and the c10 tiers."""
    table = json.load(open(path, encoding="utf-8"))
    block = set(json.load(open(os.path.join(HERE, "pending", "place_names.json"), encoding="utf-8"))["blocklist_start"])
    bad = 0
    for kind, lst in table.items():
        for n in lst:
            b, r = c10(n)
            if n.lower().replace(" ", "") in block or b or r or (kind != "landmark" and len(n) > 12):
                bad += 1
                print(f"{path}: FAIL {kind} '{n}' {b + r}")
    print(f"{path}: {sum(len(v) for v in table.values())} names, {bad} failing")
    return 1 if bad else 0


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--names":
        sys.exit(names(sys.argv[2]))
    sys.exit(main(sys.argv[1:]))
