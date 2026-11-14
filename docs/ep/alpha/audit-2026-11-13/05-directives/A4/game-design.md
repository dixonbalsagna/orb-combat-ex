# A4: Game Design

Leads: A-MODES-02, A-COMBAT-06
Supports: A-AI-08, A-AI-06, A-CONTROLS-01, A-MODES-03, A-WORLD-02, A-QA-06

Goal: A player can pick Horde from the menu, alone or with a second pad, fight waves of weak enemies that keep coming back for 5 to 10 minutes and see a result; and each of the two fighters reaches two forms beyond base that are its own, not a shared ladder.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4, "Rows proposed smaller for Alpha", decisions 15 to 17); spike S3's page (the horde trial from A1; the EP gives the path); `docs/combat/henchmen-grades.md`; `docs/research/co-op-brawler.md`; `docs/design/modes.md`; `docs/design/two-v-two.md`; `docs/design/hero-forms.md`; `docs/design/balance-targets.md`; `docs/ep/alpha/audit-2026-11-13/reads/RR-02.md` (the forms as the data and code state them); `docs/ep/vision.md`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-MODES-02 (XL, blocker): the co-op horde mode does not exist: no horde design page, the henchmen page says it is paper only, and the sim's many-body match holds at most five bodies with no waves and no respawn. Evidence: `docs/combat/henchmen-grades.md:3` ("Paper only: no data file, nothing built"); `docs/combat/henchmen-grades.md:183` (a wave of 12, above the limit); `sim/core/roster.gd:36-40` (`MAX_BODIES` 5).
- A-COMBAT-06 (L, major): transformations are the shared three-tier ladder for both fighters: the Protagonist's own forms are switched off, the rival has none, and the only per-tier look is an aura with placeholder poses. Evidence: `data/fight/forms.json:4` (`"enabled": false`); `data/fight/ladder.json:10-13`; `data/anim/forms.json:3`; `RR-02.md:18-36` (no `forms.json` in the rival's folder).
- Supporting rows: A-AI-08 and A-MODES-03 and A-CONTROLS-01 (the supported 2v2 line-ups, X-09); A-WORLD-02 (what each planet dial may be set to); A-QA-06 (the bands QA measures for teams and the horde); A-AI-06 (how often the computer throws a right-stick strike at each level).

You own: `docs/design/`.
- ask under NEEDS FROM EP for a grant: `data/fight/` (the forms switch, and a new horde data file with its schema)
- ask under NEEDS FROM EP for a grant: `data/fighters/PROTAGONIST/forms.json` and a new `data/fighters/RIVAL/forms.json` (Narrative & Fighter Identity's folder)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (any data shape you change)
- The sim, the director, the menu, the camera and the pictures are other directors' work: write the rule and the numbers, and list what each must build under NEEDS FROM EP.

Acceptance criteria:
1. (A-MODES-02) A horde design page exists in `docs/design/` and states, in plain words and numbers: who plays (one or two), what a weak enemy can and cannot do, wave size, how and where enemies come back, how a run ends, the timer, what the result screen shows, and which of the henchmen page's grades are in. Checked by the EP's read. Written for the smaller version the path proposes: at most three weak bodies at a time inside today's five-body limit, with respawn, a timer and a result screen. Full version if Orb declines the proposal: bigger waves and graded henchmen, which adds raising the body limit (L or more) to this golden window and makes the Steam Deck's frame rate at the largest wave the top risk.
2. (A-MODES-02) Every horde number is in a data file with a schema; none is in code. Checked by CI's data job on the commit.
3. (A-MODES-02, X-10) On the built mode, a scripted run lasts between 5 and 10 minutes with waves and respawn and ends at the result screen; the mode smoke suite starts, finishes, rematches and leaves Horde for one player and for two (X-05). Records saved under `docs/design/runs/<sha>/`.
4. (A-MODES-02) The page says what the frame-rate reading at the largest wave must be (60 on Orb's PC; the Deck's reading is asked for by bench file and judged at A6) and names the lever to pull if it misses.
5. (A-COMBAT-06) A forms page states, for each fighter, two forms beyond base: the trigger, what changes in the fight, and what a blow already in flight does when a transformation starts (A-COMBAT-12 builds that rule). The rival's forms are written as his own, not a copy.
6. (A-COMBAT-06, X-04) Forms are on in data for both fighters; the transformation probe built in A1 reaches each form for each fighter in a scripted match. Result saved under `docs/design/runs/<sha>/`.
7. (A-COMBAT-06) A mirror batch per fighter and a pairing batch, run by QA through the EP, show the pairing still inside the balance page's 45 to 55% band, or the page records the miss and the lever. A first reading is enough here; final tuning is A5's numbers window.
8. (X-09) The supported 2v2 line-ups are written on one page: two people as a team against two computer fighters, and one person with a computer partner against two computer fighters. Full version if Orb declines the two-pad proposal: three- and four-pad line-ups are added, which needs a four-way picture that does not exist.
9. (support) One line each, on the pages the leads read: the range of each planet dial (city count, climate, water); the team and horde bands QA measures; the right-stick strike rate per level (recommended: Medium and Hard only).
10. Anything a player will read (the mode's name, form names, result-screen words) is listed for Orb to see before it is used.

Constraints:
- Tokens: about 12M as an estimate (XL 8M + L 4M); about 4M less for the horde if the smaller version stands. This is the largest load in A4, so the horde page is written ahead during A3, from S3's page.
- Both rows change the sim's state hash. They land only in golden window GW3, "Many bodies and the full fighter", with the other GW3 rows, so the golden records are re-recorded once.
- Machine: Godot runs headless only; at most 3 Godot processes for a short gate; a run over about ten minutes starts at below-normal priority, and a reading taken on a saturated machine is marked invalid.
- Determinism: seeded RNG, fixed step, no rendering state in the sim. Wave timing and respawn places depend only on the match's setup and the tick. Numbers live in data; a data shape change updates its schema in the same commit.
- Originality: enemy types, form names and form looks are our own; nothing from an existing franchise.
- Orb's rules: whatever is added must complement high-speed combat; no health bar, and nothing drawn on, over or between the fighters (a wave counter or timer sits with the HUD, not over a body); bystanders bounce or scatter and never die; plain words; forward-facing text is seen by Orb first.
- Change control: a new idea met while writing goes to the ideas log through the EP; it is not built.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Orb's answers to decisions 16 (the horde's first size, the line-ups) and 17 (what a transformation changes); S3's page; A-ENERGY-01 (the stamina, energy and body loop, A3) on main, because the forms sit on it. Waiting on this: A-AI-01 (the horde's enemy control) and Simulation's waves and respawn wait on the horde page; A-ANIM-01 (each form's look) waits on the forms page; A-QA-06 (team and horde bands) waits on the built mode; A-COMBAT-04 (the move table) runs beside the forms.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- The horde and the move table are carried at 16M and 13M until spikes S3 and S4 report. Art supplies the enemy body's look. (COS-02, MIS-06)
