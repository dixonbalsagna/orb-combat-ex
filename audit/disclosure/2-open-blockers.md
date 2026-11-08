# 2. Open blockers to a public release

This is what I currently believe blocks a public (store) release, with the source and owner of each. It isn't a complete reading of every open Legal row: `docs/legal/review-log.md` has 168 lines matching "open" or "owed".

| # | Blocker | Source | Owner |
| ---: | :--- | :--- | :--- |
| 1 | The title clashes with the OrbCombat project on GitHub. | `CLAUDE.md` ("Still open"); `docs/legal/name-screening.md` | Orb, Legal |
| 2 | The licence is undecided; the LICENSE files were removed from the root. | `CLAUDE.md`; `docs/ep/vision.md` (Licence row); `docs/legal/licence-recommendation.md` | Orb |
| 3 | The final AI-disclosure wording isn't read by Legal. | `docs/marketing/first-month-projection-2026-11.md` ("Blockers before any Steam page"); ADR 0007 | Legal |
| 4 | There's no recorded full-set pixel release pass for current main. The public site runs on an interim instead. | `tools/site.json` (interim, pin `257a766c`); `tools/flash/release-pass.json` | Tools, Legal |
| 5 | The public interim expires 2026-11-15. Legal's RL-207 is due 2026-11-15 and RL-200 is due 2026-11-08. | `tools/site.json`; `docs/legal/review-log.md` (RL-200, RL-207); Legal's message of 2026-11-07 | Legal, Tools, Orb |
| 6 | Pillar 5 breach on main: `sim/world/collateral.gd` `_feed` raises the villain's menace and power per casualty. Orb's rule is "never on civilian deaths". The fix is held for Orb's bystander re-ruling. | `docs/ep/proposals/physics-packet.html` (the stand-in's flags); CLAUDE.md pillar 5; EP notes `ep-handover-2026-11-01-night.md` | Orb (re-ruling), then Game Design, World, Legal |
| 7 | The bystander re-ruling: RL-247 and `docs/legal/bystander-comedy-screen.md` are uncommitted on Orb's hold. | `docs/legal/review-log.md` (working copy) | Orb |
| 8 | Two fighters exist; four are the planned minimum for a paid store page. | `CLAUDE.md` (P4); `docs/marketing/first-month-projection-2026-11.md` | Orb, team |
| 9 | The hero's lure reads civilians (QA: the civilians-removed swing gap goes with the lure). Held under RL-247; Legal hasn't been asked. | `docs/qa/cloud-reports/2026-11-07-city-step-one-reread.md` | Orb (hold), then Legal |
| 10 | Known bugs in the register. | `qa/known-bugs.md` | QA |

Feature-level items owed before a feature goes live, not before release as such:
- The beam-clash crater's combined clip and the barred-bowl picture: RL-251, RL-252, RL-254.
- The drawn 2v2 case's clips: RL-249.
- Air-brake hands in the real renderer: RL-255.
