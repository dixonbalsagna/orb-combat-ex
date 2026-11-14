# A6: Executive Producer

Leads: none
Supports: none

Goal: One commit passes every criterion from X-01 to X-34, two friends complete the checklist on their Steam Decks, and the feature freeze begins.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A6, "If a milestone misses its exit", "Change control", decision 23); `docs/ep/alpha/alpha-audit-specification.md` lines 166 to 201 (the criteria table) and "Exit criteria this audit proposes to change" in the path (use the wording Orb confirmed for X-03, X-05, X-08, X-10, X-11, X-15, X-21, X-22 and X-24); the A5 exit table under `docs/ep/runs/`; the eight director briefs in this folder; `docs/ep/playbook.md` line 19 (keep evidence, CD-22).
- A6 closes no register row. It is the candidate's verification, the second tester round, one fix round and the freeze. Directors active: QA & Balance, Game Design, Encounter Systems, Performance & Platform, Tools & Pipeline, Legal, Accessibility & Localization, Production Operations. A fix outside those eight is briefed to its owner from the fix reserve.

You own: `docs/decisions/`, `docs/ep/`, shared files.

Acceptance criteria:
1. The candidate's commit is named: the commit GW4 landed on plus A5's last words and pictures, with CI green. Every reading in A6 names that commit. Checked by: the first line of the exit table under `docs/ep/runs/<sha>/`.
2. (X-02) Before any friend is invited, Tools' index of gate records, Accessibility's table and Legal's table show every gate on the "before an outside tester plays" list green with a saved record for that commit, and Legal's one line "clear for the two named testers" is recorded. Not green means not invited: this line holds the milestone open. Checked by: the three records.
3. (exit table) One table lists X-01 to X-34, each "passes", "misses" or "decided otherwise by Orb", with the path of the saved record: X-01; X-02; X-06 with team and horde bands; X-23, X-24, X-26; X-25 on Windows, Linux and one friend's Deck; X-27 to X-32 re-read; X-33; X-34; and X-03, X-04, X-05, X-13, X-14, X-16, X-17 re-run because the numbers moved at the end of A5. The criteria not named in A6's exit list (X-07 to X-12, X-15, X-18 to X-22) carry their last passing record forward by path, and any that a fix could have touched is re-read. Checked by: the table.
4. (X-01) The two friends each get a key, the guide, the checklist and Legal's note, sent by Orb; their checklists and report files come back; QA's summary is in your hands the same day. Checked by: the two checklists, filed without the testers' names.
5. (fix round) One round of fixes from what the checks and the friends found, paid from the 8M reserve: each fix is briefed to one owner with its acceptance test; each states that it does not change the sim's fingerprint, with before-and-after fingerprints; each visible fix has its side-by-side (ADR 0010); the candidate moves to the new commit and every criterion a fix could have touched is re-read. A fix that would change the fingerprint is taken to Orb as one question (send the candidate back to A5's numbers window, or leave the fault and name it), and that is said out loud. Checked by: the fix list with one line per fix.
6. (missed lines) A must-pass line that is a safety gate or a blocker holds the milestone open. Any other missed line goes to Orb within a day as one question with three choices: wait, ship short with the line carried forward by name, or cut something. Checked by: the questions, recorded verbatim with Orb's answers in `docs/ep/vision.md`.
7. (X-33) The freeze is recorded on the day the table is all green: Orb's word, the commit and the version; an ADR in `docs/decisions/`; the playbook points to Production Operations' change-control page and the ideas log. Checked by: the ADR and the playbook line.
8. (X-34) The candidate's shot set is in the archive beside the five earlier sets, and you have looked at the six side by side. Checked by: your note in the exit record.
9. The PLAY THIS page for the candidate says, in plain words: nothing is new; this is the A5 build with what the checks and your friends found fixed; play one match at each difficulty and one run of each mode; this is the build your friends get; after it, new ideas go in the ideas log. Checked by: the page.

Constraints:
- Tokens: 13M for the milestone as an estimate: about 5M of verification runs (the soak, the bands, the shot set, the gate re-reads) and an 8M fix reserve. Reviews and routing are in the EP's own allowance.
- State hash: no golden window. Rules and numbers are frozen from the end of A5.
- Machine: the soak, the bands and the shot set are long runs at below-normal priority and are scheduled so none overlaps a frame reading; at most 3 Godot processes for a short gate; headless Godot only; verify the build from its own packed data; stop only your own processes, by PID.
- Determinism: every reading names seeds, commit and data hash.
- Originality: a last name-and-text scan by Legal before the friends are invited.
- Orb's rules: one clear question at a time, in plain words; nothing public, no spend and no Legal flag without Orb's word; no test result justifies a worse look; outside testers get every safety gate in full; the one topic kept off Orb's page stays off it.

Return: to Orb, the exit table, the PLAY THIS page and the freeze record; from each director, the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Starts when A5's exit has passed. Inside A6: name the commit; the measured checks and the gate re-read; then the upload and the invitation; then people's time (allow one to two weeks); then the fix round and the re-reads; then the freeze. Beta planning starts from Production Operations' one page after the freeze.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- No build is uploaded to a channel an outside tester holds a key to, or sent to one, unless every gate on the "before an outside tester plays" list (X-02) is green with saved records on that commit. This is an exit line of this milestone. (MIS-01, ORD-02, COS-01, ORB-01, PC-01)
- Deck readings carry across the fix round only if the fixes touch no drawing or loading code; otherwise a second five-minute ask is made. The outside-tester package carries X-01, X-18, X-19, X-21, X-24, X-32 and the Deck soak; the trusted-two package carries X-08 and the LAN rows of X-05; everything else is read on both, from the one candidate commit. (COS-03, MIS-08)
