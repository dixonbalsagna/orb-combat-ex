# A5: Executive Producer

Leads: none
Supports: A-QA-01, A-TEXT-01, A-AI-02, A-QA-05, A-QA-08, A-RENDER-06, A-WORLD-05, A-TEXT-04, A-AUDIO-02

Goal: Orb installs the game on the second PC from the real itch.io page with a real key, following the tester guide and nothing else, and after this milestone no rule or number in the fight moves again.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (sections A5 and A6, "If a milestone misses its exit", "Rows proposed smaller for Alpha", "Change control", decisions 18 to 22); `docs/ep/alpha/audit-2026-11-13/04-milestone-rows.json` (A5's 17 rows); the other briefs in this folder; `docs/ep/playbook.md` (line 19, keep evidence, CD-22); `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- No register row is led by the EP in A5. The EP's work is the routing every brief here depends on, because no director may message another:
  - A-QA-01 (blocker, QA leads): the guide needs the A2 Deck record, Performance's marked copy, Community & Marketing's tone pass, Legal's rows and Tools' package.
  - A-TEXT-01 (UI leads): UI's short list goes to Narrative, then to Orb, then Orb's marks go back to Narrative and UI.
  - A-AI-02, A-QA-05, A-QA-08: QA's first table goes to Game Design, Game Design's sheet to Encounter, Encounter's change to QA, and the landing is golden window GW4 "Numbers only".
  - A-RENDER-06 and A-WORLD-05 (Rendering leads): Rendering's level table goes to VFX, Animation, UI and Performance; World's store note goes to Rendering.
  - A-TEXT-04, A-AUDIO-02, A-UI-05: each waits on one answer from Orb.

You own: `docs/decisions/`, `docs/ep/`, shared files. You commit every director's deliverable after review.

Acceptance criteria:
1. Before A5 starts, Orb's answers to decisions 18 to 22 and to the smaller versions of A-RENDER-06 and A-AUDIO-02 are recorded verbatim in `docs/ep/vision.md`, each asked as one plain question with its recommendation. Checked by: the entries, with dates. A brief whose size depends on an answer is sent after the answer.
2. (exit X-12) The campaign decision for Alpha is written with its reason as an ADR in `docs/decisions/` (the recommendation: none at Alpha). Checked by: the file.
3. Every grant asked under NEEDS FROM EP is answered in writing with the exact path and the reason, and the files with no owner that A5 touches (`data/vfx/perf.json`, `data/anim/quality.json`, `render/anim/`, `docs/qa/`, `docs/tools/`, `project.godot`) are each granted to one director at a time. Checked by: the grant list in `docs/ep/`.
4. (look gate, ADR 0010) Every visible landing in A5 (the quality levels, the drawn trenches and scars, the match-over panel, the how-to card, the working-title mark) has its side-by-side against the reference build named in `docs/ep/taste.md`, looked at by you before the commit, and the record ties the landing's commit to its side-by-side. Checked by: one row per landing under `docs/ep/runs/<sha>/`.
5. (GW4) The numbers window opens once, at the end of the milestone, after every other A5 landing: Encounter's data change is values only (you read the diff: no key added, removed or renamed, no code), the golden records are re-recorded on that commit, the full gate set runs on the configuration Orb plays (the render checks included), and PLAY THIS says that replays from the last build stop verifying, for the last time. Checked by: the gate results under `docs/ep/runs/<sha>/` (CD-22), and CI read after the push. If a band needs a rule change, it goes to Orb as a scope change with its cost; it does not enter the window.
6. (exit lines) On the A5 commit you read each exit line and save the result: X-18 and X-19 as a rehearsal by Orb and the trusted second player; X-22 (the 1280 by 800 sweep: nothing clipped, nothing under 9 px); X-20 with the quality level; X-21 and X-32 (Legal's row per paper; the privacy words the same in three places); X-11 (the planet fingerprint matches on Windows and Linux in CI); X-12; X-31 with the real build on both channels, updated once and rolled back once; X-34 (five shot sets side by side); X-06 (bands at each level, and the balance band, in the same window). Checked by: one exit table under `docs/ep/runs/<sha>/`, each line pointing at a saved record.
7. A must-pass line that is a safety gate or a blocker holds the milestone open. Any other missed line goes to Orb within a day as one question with three choices (wait, ship short with the line carried forward by name, or cut something). Checked by: the question in `docs/ep/vision.md`, if one was needed.
8. The PLAY THIS page for the A5 build is written in plain words from the path's own text and tells Orb to be the tester: follow the guide from a blank PC and mark every place they had to guess. Each idea raised during A5 goes into the ideas log the day it is said, with your one-line recommendation within a working day. Checked by: the page and the log.

Constraints:
- Tokens: no row of its own; reviews, gate runs and routing are counted in the path's allowance for the EP (about a third of each week), not in A5's 14M.
- State hash: GW4 is the last landing that changes the sim's state fingerprint before the candidate. After GW3 closed no rule change is taken; A5 is words, pictures and one numbers window.
- Machine: gate runs are headless Godot, at most 3 processes for a short gate while a director's long run is going; long runs at below-normal priority; verify a build from its own packed data, not from a switch list; stop only your own processes, by PID.
- Determinism: a data shape change updates its schema in the same commit, and none is allowed inside GW4.
- Originality: nothing from an existing franchise in any committed file.
- Orb's rules: one clear question at a time, in plain words (what you press, what you see); forward-facing text is seen by Orb before use; no test result justifies a worse look; nothing public, no spend and no Legal flag passes without Orb's word; the one topic kept off Orb's page stays off it.

Return: to Orb, the milestone's exit table and the PLAY THIS page; from each director, the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Starts when A4's exit has passed and GW3 is closed. Inside A5: Orb's answers and UI's short list first (Orb's reading time is the longest wait); Rendering, QA's guide and the text work in parallel; the build is frozen for words and pictures; GW4 last; then the upload, the update, the rollback and the rehearsal. A6 starts from the commit GW4 lands on.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- No build is uploaded to a channel an outside tester holds a key to, or sent to one, unless every gate on the "before an outside tester plays" list (X-02) is green with saved records on that commit. This is an exit line of this milestone. (MIS-01, ORD-02, COS-01, ORB-01, PC-01)
- After the gate re-run, the A5 build goes to the friends with the five-minute speed-test ask, so the Deck's default picture level is read before the candidate; count that wait in A5's weeks. (ORD-09)
- The numbers window GW4 is sized L with one to two weeks of its own: at least three read-and-adjust rounds, each an overnight batch. If a band is still out after three, Orb chooses between another week and shipping with the band stated. (COS-05)
