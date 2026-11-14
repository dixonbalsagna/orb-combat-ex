# The gates that must be green before an outside tester plays (A-LEGAL-03, RL-266)

Legal owns this list. Written 2026-11-13 against def3445a, from the audit's draft (`docs/ep/alpha/audit-2026-11-13/02-areas/LEGAL.md`, Q1) and this sprint's rulings. A screen, not legal advice. **Outside testers do not share Orb's or Orb 2's standing** (RL-253), so every gate below applies to them in full. Orb and Orb 2 are covered by RL-253, RL-224 and RL-262 and are not held by these gates.

**How it is used.** For the candidate commit `<sha>` each gate has one saved record (a text file, a run id or a row), listed in `docs/legal/runs/<sha>/README.md` (a folder for each candidate, started by `runs/def3445a/` this sprint). When every gate is green, the EP asks Orb one question ("yes to desktop test builds for named outside testers?") and records the approval line in RL-263's wording. A gate is green only with its record; "I think so" is red. If a gate cannot be made green, Legal says which part of the plan changes, not that the gate is waived.

| # | Gate | Who checks | Record, saved for `<sha>` | State on 2026-11-13 and what closes it |
|---|---|---|---|---|
| G1 | All CI jobs green on the candidate | Tools (EP reads `gh run list`) | The run id in `docs/tools/runs/<sha>/` | Red until a candidate has a green run |
| G2 | The EP's local gate | EP | `docs/ep/runs/<sha>/` | Per candidate |
| G3 | The build's own packed data matches the plan | Tools | `docs/tools/runs/<sha>/pck-verify.txt` | Per candidate |
| G4 | Flash reading of the candidate, both modes, on the ground players see, within 2.5 / 3 / 2 (RL-203 condition 2) | Tools, Camera, VFX | `tools/flash/release-pass.json` for `<sha>` and the clips | **Red.** Clash reads 6.5 reduced, 5.5 normal; closes only by a passing reading on the candidate |
| G5 | The flash measuring chain repaired (CD-09) | Tools | Commits, and the self-test failing on the old tie code | **Red.** No commit yet |
| G6 | The notice shows before play; no route skips it | Tools | `desktop-package.mjs routes` and `verify` output | Green in code; the output is saved per candidate |
| G7 | Reduce flashing on by default and locked in every outside package | Tools | Same as G6 (lock flag true in the packed data) | Closes with the packaging step for outside testers (RL-262) |
| G8 | Orb's recorded yes | EP | `docs/ep/approvals/desktop-test-builds.txt` in the commit | **Red.** Wording ready (RL-263); needs Orb's word, asked only when G1 to G7 and G9 to G19 are green |
| G9 | README.txt and NOTICES.txt carry the notice, the AI line, the privacy line and the licences | Tools | `verify` output | **Red.** Final wording written (RL-264, `tester-folder-notices.md`); closes when Orb has seen it and Tools has placed `tools/site-tester.json` |
| G10 | Nothing leaves the PC unless the tester sends it | Tools | `routes` output; no `net/*` in the package; no public issue link as a feedback target | Green for a package with no network code; the check covers the feedback target once Tools adds it (RL-262) |
| G11 | Bystanders never die; no death count is shown (RL-257) | Tools | CI world job run id | Green |
| G12 | No personal details or banned words in the public repository | Tools | The run id | Green |
| G13 | A report file holds no account name or path | Tools | A scan result under `docs/tools/runs/<sha>/` | **Red.** No check exists yet |
| G14 | Tester paperwork signed off item by item | Legal | One row each: itch page (RL-261), builds and run files (RL-262), approval line (RL-263), notices (RL-264), permission page and contributor note (RL-265) | **Written;** Orb sees the words before use, the EP records it |
| G15 | The report channel is set up privately | Orb, Legal | Orb's line in `docs/ep/vision.md`, and a Legal row | **Red.** Orb: "I will make the Discord soon". Open points kept for when Orb sets it up: a new private server and not a converted one; whether the delete-on-request promise is kept (`alpha-discord-flags.md`) |
| G16 | Each tester told, an adult, and acknowledged | Orb | A dated private list kept by Orb, never in the repository. The acknowledgement is one reply from the friend in the report channel: "I have read the note and the README, I am an adult" | **Red.** No mechanism until the channel exists |
| G17 | The licence line recorded | EP | `docs/ep/vision.md` | Orb said "GO" on 2026-11-13 (all rights reserved through Alpha, public code at Beta); the EP records it; the permission page replaces the old line (RL-265) |
| G18 | The title on the itch.io page cleared or excused in writing | Legal | RL-261 | **Excused in writing** by RL-261 (restricted, unlisted, unpromoted, "working title"); the paid search still waits before any public page, store page or promotion |
| G19 | LAN for outside testers ruled on | Legal | RL-230, RL-241, RL-253, RL-262 | **Not applicable by Orb's decision 13:** LAN is for Orb and Orb 2 only; the outside package has no LAN row and no `net/*`. If outside testers ever get LAN, it comes to Legal first |
| G20 | The accessibility baseline in the build | Accessibility | `docs/accessibility/runs/<sha>/` | Per the ACCESS area page |

**Counting.** Today: green or ready G2 (per candidate), G3, G6, G11, G12, G14 (written), G17, G18, G19; red G4, G5, G8, G9 (until placed), G13, G15, G16; per candidate G1, G7, G10, G20. G4 is still the most serious: it is the only gate where a person could be hurt.

**Two rules that keep the list honest.**
1. A gate is never marked green on a wording ruling alone when it needs a measurement (G4, G5, G13) or a run (G1, G3).
2. Nothing in this list changes what Orb and Orb 2 may play; it holds only the files outside friends receive.
