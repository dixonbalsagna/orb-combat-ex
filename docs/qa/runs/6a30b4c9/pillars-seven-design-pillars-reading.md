# X-13: the seven pillars seen in a match, first reading (QA, 2026-11-14)

Tool: `qa/godot/pillars.js` (the tests are stated at its top). Records: AI v AI at Easy, 60 matches, seeds 1 to 60, whole ring (gen 3, 4,800 columns), the energy model on, travel 1.5, on the **6a30b4c9 build's own tree** (data hash as in x06-first-reading.md). The matches are those of `qa/godot/records.gd` through `run-arm.js` (919 s, 3 jobs, below normal).

### AI v AI easy, 6a30b4c9 tree: 60 matches

| Pillar | Matches that saw it | Share |
| :--- | ---: | ---: |
| P1 The planet is the arena | 60 of 60 | 100.0% |
| P2 Stances, not combos | 60 of 60 | 100.0% |
| P3 Never out of range | 60 of 60 | 100.0% |
| P4 Power has weight | 58 of 60 | 96.7% |
| P5 Characters are personalities | 1 of 60 | 1.7% |
| P6 Fights tell stories | 60 of 60 | 100.0% |
| P7 Signatures adapt | 59 of 60 | 98.3% |
| **All seven in one match** | 1 of 60 | 1.7% |

The first match (seed 1): P1 seen, P2 seen, P3 seen, P4 seen, P5 NOT seen, P6 seen, P7 seen

**What it says.** Six pillars show in nearly every match. **P5, characters are personalities, shows in 1 of 60:** the test is that both meters of the design (menace and anguish) moved in the match, and in 59 of 60 they stayed at zero. That is the placeholder fighters (care 0) and the rule that nobody dies (RL-257 and the Monday batch): the meters were fed by civilian deaths; what feeds them now (destruction, trauma) is not in the records. The pillar may be present in play and invisible to this test; Game Design should state the event that marks it, and QA will read that. P4 missed in 2 matches and P7 in 1 (fewer than two signature variants thrown).
