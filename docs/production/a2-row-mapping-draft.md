# A2: draft mapping from register rows to commits

**Status: draft, nothing new applied.** Written 2026-11-28 by Production Operations at HEAD c3d703cb, from commit subjects since 13 November (read-only git log; no diffs read, nothing run) and the register's row texts. Confidence as in the GW1a and GW1b drafts: **placed** (a commit plainly does what the row says), **likely** (it matches by subject). † marks a row kept off Orb's page.

## A. Rows the commits close

| Row | State on the tracker / proposed | Commit | Basis | Confidence |
| --- | --- | --- | --- | --- |
| A-QA-02 | applied (landed) | 2701e69c; 7570ccd6, 68d5b9f3 | soak harness; both two-hour soaks; memory growth gone | placed |
| A-CONTROLS-03 | applied (landed) | d0e48be5 | unplug pause, Orb's yes | placed |
| A-TOOLS-04 | applied (landed) | dc6079b3; bf5994ac, 8e7d81d9 | crash marker and logs; crash check on Windows and Linux. The hang half is read by the same check, per its subject | placed |
| A-CAMERA-02 † | landed | 0e3b7db3 | the parked camera safeguards (cd04) in the small-and-big window; re-cut 98254b30 | placed |
| A-LEGAL-06 | landed | a4f98516 | report scan: size limits, no folder paths, account or PC names, emails, addresses; dc6079b3 cleans the logs | likely |
| A-TOOLS-06 | landed | 186aa252 | testers' packages made on Orb's PC with refusals; Legal RL-278 (cb748e09) | likely: whether every conflicting rule is rewritten is not checked |

Confirming this section would add three landed A2 rows (A-CAMERA-02, A-LEGAL-06, A-TOOLS-06).

## B. Rows with part of the work in (proposed "reported", not landed)

| Row | Commits | What is still missing |
| --- | --- | --- |
| A-TOOLS-02 | 7ae0cd49, 89efe028 (store-page checklist), 6f2e3164, b154aea2 (upload refusals and files) | no store page, key procedure run or rehearsal record |
| A-TOOLS-03 | b154aea2 (roll-back files) | no release checklist or named build to return to seen |
| A-LEGAL-03 | b181b934 (gate page current), cb748e09 (G23) | the list exists; several gates have no saved record |
| A-LEGAL-05 | 43de88fe, 2d2153a8 | words are drafts until Orb reads them; no adult confirmation or terms agreement seen |
| A-LEGAL-12 | 43de88fe, e8943864 | testers' words corrected together; the in-game About page not seen changed |
| A-PERF-01 | 1c3eebf3 (Linux picture), f3384380, c3697a63 | nothing has run on a Steam Deck |
| A-AUDIO-04 | c3697a63, 312c323f | sound proof on exported Linux and Windows programs; no Deck, no CI audio check seen |
| A-LEGAL-08 † | c75b937e, 7b155321 | nightly windows hold their events again; the rest of the ordered repairs not matched |
| A-LEGAL-01 † | 7e833c6f, dac1e0ec | two clips read on the landing tree; no full reading on a candidate |
| A-TOOLS-05 | dc6079b3, a4f98516 | the desktop build writes and cleans the report folder; use by an outside tester or a Deck not shown |

## C. Rows with no commit seen (25 of 41)

A-ACCESS-01, A-ACCESS-02, A-ACCESS-04, A-AUDIO-03, A-CAMERA-03, A-CONTROLS-07, A-CONTROLS-08, A-LEGAL-07, A-LEGAL-13, A-MARKET-01, A-MARKET-02, A-MARKET-03, A-MARKET-04, A-MARKET-07, A-PERF-03, A-PERF-05, A-QA-11, A-RENDER-02, A-RENDER-03, A-RENDER-08, A-SAVES-02, A-TEXT-01, A-UI-03, A-UI-07, A-UI-10.

No commit subject matched them. That is not proof of no work: a commit may carry a row without naming it.
