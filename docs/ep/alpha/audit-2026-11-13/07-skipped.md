# Alpha audit: what was skipped or done at reduced depth

Kept current by the judgment session. Nothing here was cut silently.

## Reduced depth

- **ANIM, TEXT, ACCESS, AUDIO (phase 2).** Reviewed mainly from the inventory and the reading-request answers, with code opened only where a blocker or major might hide; aim of 6 to 12 findings each; no sampling of minor findings for verification. Why: the first four areas cost 0.47M tokens each against a plan of 0.34M, and the specification's drop order names these four as the least likely to hold blockers (section 12, item 4). Decided 2026-11-13 20:38 PST.

## Not done

- **Platform pages were read through search results, not opened.** The audit runs no browser. `02-areas/web-checks.md` says which lines need confirming in a rehearsal.
- **Not looked up yet:** Windows' warning on unsigned programs and the price of code signing; itch.io's app on a Steam Deck and adding a non-Steam game to the Deck's library; whether Steam's two-week "coming soon" rule and its wait after the fee can overlap.
- **Weekly token figures for the last three weeks** do not exist in clean form (the EP's answer to AQ-01), so the path's "weeks at Orb's usual pace" is an estimate.

## Dropped to stay inside the meters

- **The second adversarial round (phase 6).** Phase 2 cost 8.86M tokens against 7.4M planned, and the all-models weekly meter stood at 18% after it, against a stop at 30%. Dropped first, as the specification's drop order says (section 12, item 1). Decided 2026-11-13 20:53 PST.

## Not done by others

- **The directors' fact check of phase 2.** The specification has each director correct facts in their own blockers and majors. The EP decided not to wake them (2026-11-13 21:00 PST): it would cost more than it was likely to change, and the independent verifiers had refuted nothing. The EP read the blockers itself and found no error of fact. So findings were checked by a second agent and by the EP, not by the owning directors; a director may still correct a fact when its first brief arrives.

## At the end of the audit (2026-11-13)

- **The adversarial round's amendments were not themselves attacked** (the second round was dropped, above). The fixes for the 58 surviving criticisms were written by the auditor in one pass: into the path, into nine register rows, and as an "Amendments" section at the end of 44 briefs that overrides the text above it. The older text of those briefs was not rewritten line by line.
- **Not every brief was read line by line by the auditor.** Lead coverage, owners and milestones were checked by script for all 100; three were read in full; the adversarial reviewers read A1's and A2's and sampled the rest.
- **Phase 6 cost 2.16M against 1.5M planned**, which left no room for anything further under the 30% stop on the all-models meter.
- **Costing and detail for rows placed after Alpha** were kept at one line each (the specification's drop order, item 2).
- **Verification of minor findings:** one in five in 18 areas, none in ANIM, TEXT, ACCESS and AUDIO; 99 register rows are marked `verified: no` and 33 `sampled`.
- **Still not looked up:** Windows' warning on unsigned programs and the price of code signing; how a tester installs and updates through itch.io's app on a Steam Deck, and how files come off a Deck (the path now makes this the first step of Performance's A2 brief); whether Steam's two-week "coming soon" rule and its wait after the fee can overlap; how Valve schedules the Deck compatibility review.
- **Nothing was run.** No Godot, no browser, no Steam Deck, no measurement asked of the EP. Every finding is from files, saved records, the commit log and CI's run list.
