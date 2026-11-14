# A4: QA & Balance

Leads: A-QA-06
Supports: A-MODES-02, A-AI-01, A-AI-06, A-AI-08, A-COMBAT-06, A-MODES-09

Goal: A tester who plays 2v2 or Horde gets a fair fight: no team line-up wins or loses most of the time, a horde run can be survived and takes 5 to 10 minutes, and there is a measured number behind each of those.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; the tool rule in the top section: a tool is built and gives its first reading in one milestone, and the number must pass from the next); `docs/ep/alpha/audit-2026-11-13/02-areas/QA.md` (F-QA-12); `docs/design/balance-targets.md`; `docs/combat/henchmen-grades.md` (the bands it sets for QA to measure, lines 181-184); Game Design's horde page and line-ups page (the EP gives the paths); `qa/README.md`; `qa/run-godot.js`.
- A-QA-06 (M, major): QA has no script or band for team play or the horde, though the balance page sets 45 to 55% for every 2v2 team. Evidence: a search of `qa/` for co-op, 2v2, team, horde or henchmen on 2026-11-13 finds nothing; `docs/design/balance-targets.md:45` ("Every team composition wins 45 to 55% against each other composition, over both sides").
- Supporting rows: A-MODES-02 and A-AI-01 (the horde's length, survival and clear-time bands); A-AI-08 (the computer partner's quality bar); A-AI-06 (every level's win rate re-read once the computer throws right-stick strikes); A-COMBAT-06 (a mirror batch per fighter and a pairing batch with forms on); A-MODES-09 (the bystander band per fight and for both fights together, a place both fights reached counted once).

You own: `qa/`, `prototype/tools/`.
- ask under NEEDS FROM EP for a grant: `docs/qa/` (where the readings are saved, as `docs/qa/runs/<sha>/`; no director owns it)
- Bands are Game Design's to set: where a band is missing, name it under NEEDS FROM EP; do not invent one.

Acceptance criteria:
1. (A-QA-06) A team batch script in `qa/`: scripted players on Orb's scheme (right-stick attacks, LB guard) and computer fighters play each supported 2v2 line-up from the line-ups page, over both sides, for a stated number of matches, and report each team's win rate against the 45 to 55% band. First reading: the script exists and a reading is saved; a number outside the band is the expected result and is reported, not tuned here.
2. (A-QA-06) A partner reading in the same batch: with one scripted human and a computer partner against two computers, the share of the team's damage and of the team's knock-outs the partner does, against Game Design's written bar. First reading saved.
3. (A-QA-06, X-10) A horde batch script: one scripted player, then two, play full runs; it reports run length (target 5 to 10 minutes), whether the player survived, health lost over the run, and the time to clear a wave, against the horde page's bands. First reading saved.
4. (A-QA-06) Each script reads the match's packed data on the commit it reports (a switch list is the plan, not the proof), prints the commit and the seed list, and gives the same numbers when run twice on the same seeds.
5. (A-QA-06) The bug list gets an entry, with a severity, for every error, hang or state mismatch a batch meets.
6. (support, A-AI-06) After the computer's right-stick strikes land, the solo win rate at every level is re-read with the scripted player on Orb's scheme, 40 matches each, and handed to the EP for A5's tuning.
7. (support, A-COMBAT-06) With forms on: a mirror batch per fighter and the pairing batch, against the 1v1 band. First reading saved.
8. (support, A-MODES-09) The bystander band for a 2v2 is reported per fight and together as a trend.
9. Evidence: every reading, with its commit, seeds, machine load note and the script's version, is saved under `docs/qa/runs/<sha>/`. A reading taken while the machine was saturated is marked invalid and re-run, not reported.

Constraints:
- Tokens: about 1.2M as an estimate (M).
- The row does not change the sim's state hash. The batches are run after golden window GW3's rows have landed, so the readings are on the rules that ship; they feed A5's numbers-only window (GW4), where data values may change and no rule may.
- Machine: Godot always headless; QA runs at `--jobs=3` (one job is two Windows processes); a batch over about ten minutes starts at below-normal priority and gives way to short gates; do not launch the same batch twice; stop only your own processes by PID; make sure every run exits.
- Determinism: seeded RNG, fixed step; a batch is a pure function of its commit, data and seeds.
- Originality: nothing here touches content.
- Orb's rules: plain words in every report (what was pressed, what happened, the number); bystanders bounce or scatter and are never counted as deaths; no report or file names a person.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: the scripts can be written against the 2v2 that exists on LAN setups today; the horde batch waits on A-MODES-02 and A-AI-01 (the built mode), the partner reading on A-AI-08, the team batch's couch line-up on A-MODES-03. All readings are taken after GW3 lands. Waiting on this: A5's tuning (A-AI-02, A-QA-05, A-QA-08) uses these numbers, and X-09 and X-10 are judged with them.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- The team and horde bands read here are the starting gap for A5's numbers window, where they are tuned. (ORD-03)
