#!/usr/bin/env python3
"""Lint forward-facing lines against Orb's rules (docs/narrative/line-lint.json).

Usage: python docs/narrative/line-lint.py FILE.md [FILE.md ...]

A line is any markdown line of the form  > "the line"  (the homework format).
Standard library only. Exit code 1 if any line fails a hard rule.
Hard rules: R1 length (4 to 12 words), R3 banned words, R8 ellipsis, a line said three times.
Soft (reported, not failing): R2 no contraction, R6 no second person.
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
LINT = json.load(open(os.path.join(HERE, "line-lint.json"), encoding="utf-8"))
BANNED = LINT["banned_words_orb"] + LINT["banned_words_proposed"]
LO, HI = LINT["rules"]["R1_length"]["min_words"], LINT["rules"]["R1_length"]["max_words"]
LINE = re.compile(r'^>\s*"(.*)"\s*$')


def check(line):
    hard, soft = [], []
    n = len(line.split())
    if not (LO <= n <= HI):
        hard.append(f"R1 length {n}")
    for w in BANNED:
        if re.search(r"\b" + re.escape(w) + r"\b", line, re.I):
            hard.append(f"R3 banned word '{w}'")
    if "..." in line or "…" in line:
        hard.append("R8 ellipsis (only where Orb used one)")
    if re.search(r"\b(\w+)[,.!?] \1[,.!?] \1\b", line, re.I):
        hard.append("tell: a word said three times")
    if not re.search(r"\w'\w", line):
        soft.append("R2 no contraction")
    if not re.search(r"\b(you|your|you're|you've|you'll|yours)\b", line, re.I):
        soft.append("R6 not said to the opponent")
    return hard, soft


def main(paths):
    failed = 0
    for p in paths:
        total = 0
        for i, raw in enumerate(open(p, encoding="utf-8"), 1):
            m = LINE.match(raw.rstrip("\n"))
            if not m:
                continue
            total += 1
            hard, soft = check(m.group(1))
            if hard:
                failed += 1
                print(f"{p}:{i}: FAIL {hard}  {m.group(1)}")
        print(f"{p}: {total} lines")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
