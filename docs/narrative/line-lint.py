#!/usr/bin/env python3
"""Lint forward-facing lines against Orb's rules (docs/narrative/line-lint.json).

Usage: python docs/narrative/line-lint.py FILE.md [FILE.md ...]

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


def check(line):
    hard, soft = [], []
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
            hard, soft = check(line)
            b = blocks.setdefault(current, {"n": 0, "ell": []})
            b["n"] += 1
            if ELL.search(line):
                b["ell"].append((i, line))
                print(f"{p}:{i}: CHECK ellipsis (hesitation, regret or performative exhaustion?)  {line}")
            if hard:
                failed += 1
                print(f"{p}:{i}: FAIL {hard}  {line}")
        for name, b in blocks.items():
            cap = max(1, b["n"] // 10)
            if len(b["ell"]) > cap:
                failed += 1
                print(f"{p}: FAIL R8 ellipsis rate in '{name}': {len(b['ell'])} of {b['n']} lines (cap {cap})")
        print(f"{p}: {total} lines")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
