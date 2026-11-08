# Post-notice changes

Measured against the baseline (head 8d9b98a2, working tree fingerprinted 2026-11-07T22:03:01Z). Raw list: `evidence/post-notice-diff.txt` (made by comparing `git hash-object` of every baseline path, plus `git status --porcelain -uall`).

The time the EP was served is not known to the auditor; the baseline was taken before service. Every change below has a file time between 22:03:39Z and 22:08:15Z, i.e. within about five minutes of the baseline, consistent with sessions finishing their safe-pause writes rather than reacting to the notice. Disclosure pack (`audit/disclosure/`): **not present at 22:45Z**; each row's "disclosed" column is filled when it arrives.

## Commits since the baseline
| Commit | Paths | Safety record? | Disclosed |
|---|---|---|---|
| 53b6df82 Rendering: plan for drawing the partner's fight in a 2v2 (RL-249's drawn case) | docs/rendering/2v2-drawn-plan.md (+35) | No (a Rendering plan that cites a Legal row) | n/a |

## Uncommitted edits to paths that existed at the baseline
| Path | Change | Safety record? | Note |
|---|---|---|---|
| docs/vfx/clash-shockwave.md | +12 lines (22:03:58Z) | No, but it restates Legal RL-246's limits | VFX design doc; additive |
| docs/director/pending/orbs-scheme/README.md | edited (22:03:39Z) | No | park README |
| docs/director/pending/stick-slam/README.md | edited (22:03:39Z) | No | park README |
| docs/vfx/pending/shared-register/README.md | edited (22:03:58Z) | Partly: flash-register evidence | additive park README |

## Paths that vanished
| Path | Note |
|---|---|
| docs/tools/pending/shell-snippet-everywhere/README.md, shell.patch | Park folder removed; its change landed in fa10e83a (13:45 PST, before the baseline). Not a safety record. |

## New uncommitted paths (not in the baseline)
| Path | Frozen path? | Note |
|---|---|---|
| docs/net/pending/lan-n4/README.md, lan-n4.patch | **Yes (docs/net/)** | New park, not an edit of an existing record. Created 22:03:57Z to 22:04:15Z. Normal development under the directive's 2b; listed for completeness. |
| docs/vfx/img/shared-register/analyser-readings.txt (+2 PNG) | flash evidence | New evidence file, 22:03:44Z |
| docs/director/pending/orbs-scheme/s16-stack/*.patch (10), docs/director/pending/stick-slam/stick-slam.diff | No | parks |
| docs/rendering/pending/{crater-store,fore-profile,others-near}/* | No | parks |
| docs/vfx/pending/struggle-ring-shape/* | No | park |

## The EP's disclosure (audit/disclosure/8-post-notice-changes.md, read 23:08Z)
- Disclosed: commit 53b6df82 (matches the table above).
- Disclosed: deletion of docs/tools/pending/shell-snippet-everywhere/ (matches "Paths that vanished").
- Disclosed, and not visible to the baseline because it lay outside the repo: before the notice, under Orb's "no leftovers" pause order, the EP deleted its scratch gate trees and results (about 7.7 GB: the run-gate outputs s405-sim to s409-sim for the landings of 3c9005ac, d5582dbd and a8bc66e2), and directors deleted their scratch captures and temporary trees (Tools about 50 GB; Rendering, Netcode, UI, Camera, Performance, Encounter, Animation). Some of that may have held safety evidence; nobody kept a list.
- Not disclosed in item 8 but found by the auditor: the four edited park READMEs, the new park folders and docs/vfx/img/shared-register/analyser-readings.txt listed above. All are additive, timed 22:03 to 22:08Z, before service, and none edits an existing safety record. Not a finding.
- After the notice: the EP reports no commits to frozen paths; audit/disclosure/ written; audit/ added to .git/info/exclude.

The deletions were made before the notice and on the owner's order, so they are not concealment. They are recorded as a practice finding instead: gate results for three landings exist only as one-line verdicts in commit messages (see findings).

## Verdict so far
No existing safety record (docs/legal, docs/accessibility, qa/known-bugs*, docs/qa, tools/flash, .github/workflows, net/, docs/decisions) was edited or deleted after the baseline. No PROCESS finding from this check. Re-run before the report goes out.

## Final re-check (2026-11-08T00:20:30Z)
Re-ran the same comparison (evidence/post-notice-diff-final.txt): the same 4 changed, 2 vanished and 24 new paths as at 22:41Z, and no commit after 53b6df82. Uncommitted edits to docs/legal/review-log.md and qa/ files predate the baseline (their blob hashes equal the baseline's). **No safety record was changed after the notice. No PROCESS finding.**
