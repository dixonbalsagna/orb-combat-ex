# A4: Executive Producer

Leads: none
Supports: A-MODES-02, A-AI-01, A-AI-06, A-AI-08, A-AI-09, A-COMBAT-04, A-COMBAT-06, A-COMBAT-12, A-CODE-05, A-WORLD-02, A-WORLD-09, A-MODES-03, A-MODES-09, A-CONTROLS-01, A-ANIM-01, A-ANIM-02, A-ANIM-03, A-NET-06, A-QA-06

Goal: Orb gets one build in which Horde, couch 2v2, 2v2 with a computer partner, LAN 2v2 with all four fighters seen and a custom planet all start from the menu, each fighter has a move on every button row and two forms of its own, and the rules of the fight are closed for Alpha when the milestone ends.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (the top section's tool rule and "If a milestone misses its exit"; section A4; "Rows proposed smaller for Alpha"; "Change control"; decisions 15 to 17); `docs/ep/alpha/audit-2026-11-13/04-milestone-rows.json` (A4's nineteen rows); the eighteen other briefs in this folder; `docs/ep/playbook.md`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- The EP leads no register row in A4. The work is routing, grants, the golden window, the look gate and the exit check for these rows: game-design A-MODES-02, A-COMBAT-06; encounter-systems A-AI-01, A-AI-06 (nice), A-AI-08, A-AI-09; combat-choreography A-COMBAT-04; simulation-engine A-CODE-05, A-COMBAT-12; world-environment A-WORLD-02, A-WORLD-09; rendering-techart A-MODES-03, A-MODES-09; controls-feel A-CONTROLS-01; art A-ANIM-01, A-ANIM-02; animation A-ANIM-03; netcode-online A-NET-06; qa-balance A-QA-06.
- Three facts to hold while routing: the horde chain is long (page, then waves and respawn, then enemy control, then QA's bands); ten rows change the state hash and must land in one window; Game Design carries about 12M in this milestone, more than one session lands in its weeks, so the horde page is started in A3.

You own: `docs/decisions/`, `docs/ep/`, shared files.
- You grant, per brief, the paths each director asks for under NEEDS FROM EP. Expected: `data/fight/`, `data/combat/`, `data/input/`, `data/anim/`, `data/vfx/`, `data/art/`, `data/camera/`, `render/anim/`, `docs/qa/`, `docs/tools/`, `tools/schemas/`, named files in `data/fighters/`, and named lines in `sim/core/sim.gd`, `sim/director/exchange.gd`, `sim/director/brawl.gd`, `render/core/main.gd`, `tools/world-checks.json`, `.github/workflows/ci.yml`.

Acceptance criteria:
1. Before any A4 brief is sent: Orb's answers to decisions 15, 16 and 17 are recorded verbatim in `docs/ep/vision.md`, and each brief is sent in the smaller or the full version to match. Spike S3's page has been brought to Orb as a change request if it moved the horde's size class.
2. Golden window GW3, "Many bodies and the full fighter", is opened and closed once: A-AI-01, A-AI-06, A-AI-08, A-AI-09, A-CODE-05, A-COMBAT-04, A-COMBAT-06, A-COMBAT-12, A-MODES-02 and A-WORLD-02 land in it; the golden records are re-recorded once; determinism, parity and the full render gate set pass on the closing commit; results saved under `docs/ep/runs/<sha>/`. An ADR records the window and that GW3 is the last that takes rule changes.
3. Every visible change committed in A4 has its side-by-side against the reference build tied to the commit (the record A-RENDER-07 set up in A1); none is landed on a gate result alone. A change that looks worse goes back, whatever the gates say.
4. Every cross-director need in the briefs is routed by you and none by a director: Game Design's pages to Encounter, Simulation, UI, Camera, QA; Combat's table to Animation and Controls; Art's sheets to Animation, VFX, Rendering, Legal; World's dial list to Simulation, Netcode, UI; Tools' clips to Legal.
5. The exit check for A4 is written line by line with its record: X-05, X-10 (Orb's PC), X-09, X-08 for LAN 2v2, X-04, X-03 at the Alpha's bar, X-13 in full, X-14, X-11's dials on both LAN PCs, and X-15's third-fighter line. A missed must-pass line that is not a safety gate goes to Orb within a day as one question with three choices (wait, ship short with the line carried by name, or cut something).
6. The PLAY THIS page for the A4 build is written in plain words from the path's text and names what to try; the build reaches the two Deck friends as a real update with the five-minute bench file asked.
7. The ideas log is kept: every new idea said during A4 is logged the day it is said with one recommendation; nothing from it is built without Orb's yes; after GW3 closes, an idea that changes a rule is marked "after Alpha".
8. CI is read after every push, and a red job is treated as a stop.

Constraints:
- Tokens: no lead rows; the milestone is about 48M of director work as an estimate (2 XL, 6 L, 5 M, 6 S), about 10M less with the smaller versions. Plan about a third of each week for briefs, reviews, gate runs and rework, and give Orb a rough cost line for each big job.
- The state hash changes once, in GW3. No hash-changing work lands outside it, and after it closes no rule changes are taken before Alpha.
- Machine: fifteen or more sessions share one PC: short gates at 3 Godot processes while long runs are going; long runs at below-normal priority; captures only through Tools' launcher; you may stop an abandoned capture; never put a prompt in front of Orb.
- Determinism: a sim or director batch is verified with the full render gate set, and a build is verified from its packed data, not from a switch list.
- Originality: Legal's rows for the new looks, names and enemies are in before anything is shown outside.
- Orb's rules: one clear question at a time; plain words (say what is pressed and seen; no team nicknames); forward-facing text is seen by Orb before use; the AI disclosure wherever the game is shown; in-progress character art never public; the photosensitivity topic stays off Orb's page; stay on what Orb asked.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT), to Orb, with NEEDS FROM EP read as "needs from Orb".

Order: Before this starts: A3 has passed its exit (the stamina, energy and body loop, the signature inputs, LAN inside the game) and GW2 is closed; decisions 15 to 17 are answered. Inside the milestone: A-AI-09 and the horde page first; then waves and respawn, the forms, the dials and the move table in parallel; then enemy control, couch 2v2 and the partner; then QA's readings, the five-match LAN sessions and the smoke suite on the closed window. Waiting on this: A5 (words, pictures and a numbers-only window) starts only when GW3 is closed.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- No build is uploaded to a channel an outside tester holds a key to, or sent to one, unless every gate on the "before an outside tester plays" list (X-02) is green with saved records on that commit. This is an exit line of this milestone. (MIS-01, ORD-02, COS-01, ORB-01, PC-01) Add X-02 to criterion 5, before criterion 6 sends the build.
