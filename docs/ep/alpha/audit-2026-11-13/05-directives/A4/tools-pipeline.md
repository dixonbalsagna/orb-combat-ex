# A4: Tools & Pipeline

Leads: none
Supports: A-MODES-02, A-MODES-03, A-MODES-09, A-WORLD-09, A-ANIM-03, A-CODE-05

Goal: Every mode the Alpha ships can be shown, by one command on Windows and on Linux, to start from the menu with a pad, reach a result, rematch and leave; and the new checks from this milestone run in CI with a verdict.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4's exit criteria; X-05 under "Exit criteria this audit proposes to change"); the mode smoke suite you built in A1 (A-MODES-08); `.github/workflows/ci.yml` (the world job at line 389; the LAN and real-socket checks at lines 354-382); `tools/world-checks.json`; `tools/ratchet-two-fighter.mjs` and `.json`; `docs/rendering/2v2-drawn-plan.md` (the row for Netcode and Tools); `tools/flash/side-by-side.mjs`.
- A-MODES-02 (Game Design leads), A-MODES-03 (Rendering leads): Horde, couch 2v2 and 2v2 with a computer partner are new menu entries the suite must drive. Evidence: `docs/combat/henchmen-grades.md:3`; `render/core/main.gd:1337-1362`.
- A-MODES-09 (Rendering leads): two fights drawn on one screen need the two-fights clips (both flash modes, day and night, the two worst cases) through the analyser and the guarded launcher, per the plan.
- A-WORLD-09 (World leads): the planet fingerprint tool has no verdict and is not in CI. Evidence: `tools/world-checks.json:32`; `sim/world/tools/planet_digest.gd:2-4`; `.github/workflows/ci.yml:389`.
- A-ANIM-03 (Animation leads): the animation coverage check runs in no gate. Evidence: `render/anim/render_anim.gd:28`.
- A-CODE-05 (Simulation leads): the two-fighter ratchet counts four spellings across all code; the smaller version needs a count per system. Evidence: `tools/ratchet-two-fighter.json:10`.

You own: `tools/`, `build/`, `.github/`.
- ask under NEEDS FROM EP for a grant: `docs/tools/` (where run records go, as `docs/tools/runs/<sha>/`; no director owns it)
- Checks that live in other directors' folders (`sim/world/tools/`, `render/anim/tools/`, `net/tools/`) are theirs to change; you list them in CI.

Acceptance criteria:
1. (X-05; A-MODES-02, A-MODES-03) The mode smoke suite drives, from the menu with a scripted pad: solo, two on one PC, Horde for one and for two, couch 2v2, 2v2 with a computer partner, and a custom planet with non-default dials. Each run reaches a result, rematches once and leaves. It passes on Windows and on Linux.
2. (X-05) The LAN modes are covered on Windows by the suite and on Linux by the two-program check in CI, as the path proposes; the suite's report says which is which.
3. (X-05) The suite finds menu rows by name, not by screen position, and fails with the row's name when one is missing.
4. (A-WORLD-09) `planet_digest`, once World gives it a verdict line and a pinned file, is listed as a check in `tools/world-checks.json` and runs in CI's world job; the job's summary names the platform that wrote the pinned file.
5. (A-ANIM-03) Animation's coverage check runs in CI with its verdict line.
6. (A-CODE-05) The two-fighter ratchet reports its count per system as well as in total, fails if the total rises, and fails if the energy, stamina, body or forms systems are above zero. A negative control (a planted line) proves it fails.
7. (A-MODES-09) The two-fights-drawn clips are made through the guarded launcher and read by the analyser in both modes; the results go to the EP for Legal. A capture that was starved by other work is void and re-run.
8. (X-10) The frame record at the largest horde wave is taken with the existing frame bench on Orb's PC for Performance, through the EP, and the bench file a Deck tester runs includes the same wave.
9. Evidence: every suite run, CI run id and clip reading is saved under `docs/tools/runs/<sha>/`; CI is read after every push (it once ran nothing for a day while the workflow file failed to parse).

Constraints:
- Tokens: supporting work, counted under the lead rows; plan for about an M (1.2M) as an estimate.
- No change to the sim's state hash. Tools run after golden window GW3's rows land, and the suite must pass on the re-recorded golden records.
- Machine: headless Chrome is started only through your launcher (`tools/flash/capture-web.mjs`, `tools/machine/capture.mjs`), with a time limit, below-normal priority and the session's name on its profile folder; one software-rendered capture at a time per session; a flag with a space in it breaks the launcher; Godot headless only, at most 3 processes for a short gate; long runs at below-normal priority; the real-socket check runs in CI only.
- Determinism: a suite run is seeded and repeatable; a failure prints the seed and the commit.
- Originality: nothing here adds content.
- Orb's rules: never put a prompt in front of Orb (guard every variable in a delete; if a command needs approval, stop and tell the EP); nothing is sent anywhere automatically; plain words in every report.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: the smoke suite (A1) passing for solo, two on one PC and LAN 1v1 (A3). Each new suite run waits on its mode landing and on UI's row names; criteria 4 to 6 wait on World's, Animation's and Simulation's changes. Waiting on this: the X-05 must-pass line that closes A4, and Legal's reading of the two-fights clips.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Add a clip of the largest horde wave, in both modes, to the standard clip set. Drop the duplicate line that builds the per-system count tool; it exists since A1. Every upload to itch.io is Orb's own action, listed on Orb's page for this milestone; no session uses Orb's sign-in, so "or the EP" does not apply. (PC-08) (MIS-01, ORD-07)
