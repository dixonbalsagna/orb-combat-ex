# A5: Game Design

Leads: A-AI-02, A-QA-05
Supports: A-QA-08

Goal: A newcomer playing the way Orb plays wins about seven first matches in ten on Easy, a player who attacks only with the right stick can win, and Easy, Medium and Hard feel like three different things.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5, "Golden window GW4", "Change control"); `docs/design/gauntlet-plan.md` (section 2 the target table, and lines 131 to 132 for the Easy bands and the pace lever); `docs/design/balance-targets.md`; `docs/design/modes.md`; `docs/director/runs/6eec6a75/hitstop-row/final/table.txt`; `docs/qa/cloud-reports/2026-11-07-city-step-one-reread.md`; `docs/qa/cloud-reports/2026-11-02-kept-build.md`; `data/director/ai.json` (the `levels` block: easy, medium, hard) and `data/director/stick.json`, to read only.
- A-AI-02: Easy is too hard for a scripted player on Orb's scheme (right-stick attacks, LB guard). Evidence: `docs/director/runs/6eec6a75/hitstop-row/final/table.txt:4` (19 of 40, 47.5%); `docs/director/runs/6eec6a75/hitstop-row/final/cells.txt:1-4`; `docs/design/gauntlet-plan.md:22` (your own bar: at least 70% on Easy). The criterion's proposed band is 60 to 80%. Risk on the row: tuning Easy for the scripted pad may make it trivial for a masher (17 of 40 on the same cell), so both pads are read each time.
- A-QA-05: a right-stick-only pad loses almost every match. Evidence: `docs/qa/cloud-reports/2026-11-07-city-step-one-reread.md:38` (0 of 60 against Medium, where the X mash won 16 of 60); `docs/qa/cloud-reports/2026-11-02-kept-build.md:9` (2 of 30 against Easy; the computer wins trade breaks on a stick player far more often than on a masher). Not re-read on the played build, so the first step is QA's re-read.
- A-QA-08 (QA leads): match length against 6 to 8 minutes. Your part is the numbers that set it.

You own: `docs/design/`.
- The numbers themselves live in Encounter Systems' data (`data/director/`). You write the values and the reason on a design page; the EP routes them to Encounter, who applies them. Do not message Encounter or QA.
- If a lever sits outside `data/director/`: ask under NEEDS FROM EP for a grant: `data/combat/stick.json` (or the file the lever is in; name it).

Acceptance criteria:
1. (A-AI-02, A-QA-05) A numbers sheet in `docs/design/` lists every value proposed for GW4: file, key, old value, new value, which band it is meant to move and by how much, and what it must not move. Data values in existing keys only; no new key, no rule. Checked by: the EP reads it against the data files before routing it.
2. (A-AI-02) On the A5 build's packed data, the scripted Orb's-scheme player wins inside the Easy band (X-06: 60 to 80%; your bar of at least 70% is the aim if Orb confirms it), and the masher on the same cell stays inside its own band from `gauntlet-plan.md` section 2. Checked by: QA's saved table, at the match count per cell set by A-AI-11, under `docs/qa/runs/<sha>/`.
3. (A-QA-05) A stick-only player wins a stated share against Easy and against Medium. You write the band and its reason before the tuning starts (QA's report of 2026-11-07 reads the gap between pads against a band within 10 points; start there); the page says plainly what a stick-only player is expected to lack. Checked by: QA's saved stick-only row, and the gap to the X mash on the same cells.
4. (exit X-06) Medium (35 to 55%) and Hard (10 to 30%) hold for the Orb's-scheme player after the same change, and the balance band between the two fighters is re-read in the same window and still holds. Checked by: QA's saved tables. A miss on any band goes to the EP the same day as one question.
5. (supports A-QA-08) After the change, the Orb's-scheme player's median match on Easy and Medium is inside 6 to 8 minutes. Checked by: QA's length table.
6. (all) A short design note records what was changed and why, and what was tried and dropped, linked from the numbers sheet. Gate results behind the landing are saved under `docs/design/runs/<sha>/` or pointed to by path (CD-22).

Constraints:
- Tokens: about 1.45M (one M, one S), an estimate.
- State hash: yes. These values change the sim's state fingerprint. They land only in golden window GW4 "Numbers only", at the end of A5, as one landing; golden records are re-recorded and replays from the A4 build stop verifying, for the last time. If a band cannot be met without a rule change, stop and tell the EP: it is priced as a scope change, not slipped in.
- Machine: you run no long batches yourself; QA does. Any check you do run is headless Godot, at most 3 processes.
- Determinism: numbers live in data; a value change inside an existing key needs no schema change, and a shape change is not allowed in this window.
- Originality: none of the difficulty names, lines or behaviours are taken from another game.
- Orb's rules: the computer plays by the same rules as a player (`docs/design/modes.md`); whatever is tuned "has to complement high speed combat"; plain words on any page Orb reads.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Starts when the A4 build is on main (the move table, transformations and the computer's right-stick strikes, A-AI-06, change every band) and QA's first table on that build is in; it also rests on A-AI-03, A-AI-04, A-AI-11 and A-QA-09 from A1. Encounter's data change, QA's second table and GW4 wait on your sheet. The A6 candidate is measured on these numbers and they do not move again.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- GW4's numbers sheet also names the team bands, the horde band and the horde's run length. (ORD-03)
