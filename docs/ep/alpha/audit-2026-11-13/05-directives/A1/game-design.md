# A1: Game Design Director

Leads: A-COMBAT-15, A-ENERGY-02, A-CONTROLS-04
Supports: A-ENERGY-05, A-MODES-01, A-AI-10

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: Orb flies at the speed they liked in every mode without a private slider, the team has one page that says how energy, stamina and health work, and each of Orb's six open "workshop this" fight questions reaches Orb as one plain question with a recommendation.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1, "Rows proposed smaller for Alpha", "Change control", decisions 5, 6, 11, 12, 14 and 16); `docs/ep/alpha/audit-2026-11-13/02-areas/ENERGY.md`, `COMBAT.md`, `CONTROLS.md`; `docs/ep/vision.md` lines 1635-1642, 1688, 1694, 1707-1712 and 1735-1788.
- A-COMBAT-15: six of Orb's "workshop this" items have no decision: beam stages, the timed swat, the catch, what RT held does, the taunt before a signature, and whose stick moves whom up close. Evidence: `docs/ep/vision.md:1635-1642`, `:1694`, `:1707-1712`.
- A-ENERGY-02: no single page states the model; it is spread over six design pages, the oldest still a proposal that disagrees with the code on the brink, and none covers stamina. Evidence: `docs/design/damage-model.md:3`, `:24`; `sim/core/wounds.gd:13`, `:236-241`; `docs/design/energy-overhaul.md:182-190`. Also `docs/design/spec-wounds.md` (its line 15 already gives the brink as the core broken), `docs/design/power-scale.md`, `docs/ep/proposals/alpha-feature-workshop-2.html`, and `docs/design/melee-press-feel.md:181` and `:202` (the only stamina prices on a design page).
- A-CONTROLS-04: the flight speed Orb preferred (3500) exists only as a slider on the private browser page; the data's default is 5000, the model that reads it is off on main, and the LAN setup sends no flight speed. Evidence: `docs/ep/vision.md:1688`; `data/fight/power.json:4`, `:108`; `sim/core/power.gd:119`; also `tools/preview/blackbox.mjs:462-474`, `net/lan.gd:30`. What else is keyed to absolute speeds: the dash's closing-time table (`data/fight/power.json:113`), the glow (`data/fight/power.json:107`), the trail's start speed (`data/vfx/meteor.json:6`), Simulation's range check (`sim/core/tools/power_check.gd:97-104`), a probe that sets 5000 by hand (`sim/director/tools/dash_probe.gd:28`). 3500 is also the bottom of the allowed range.
- Spike S3 (a throwaway trial on a scratch copy; nothing lands), yours with Encounter Systems: the horde. Read `docs/combat/henchmen-grades.md`, `docs/research/co-op-brawler.md:141-172`, `sim/core/roster.gd:36-40` (five bodies at most today).

You own: `docs/design/`.
- ask under NEEDS FROM EP for a grant: `data/fight/power.json` (the flight-speed default and anything keyed to it; Simulation edits line 4 of the same file in the same window, so the EP lands both together)
- ask under NEEDS FROM EP for a grant: `data/vfx/meteor.json` (only if the trail's start speed must move with the default)
- The private page's slider (`tools/preview/`) is Tools'; the range check is Simulation's; `net/lan.gd` is Netcode's. List what you need under NEEDS FROM EP.

Acceptance criteria:
1. (A-ENERGY-02, X-15) One page in `docs/design/` states the model: energy, stamina, health and the body, what spends and refills each, and the brink as the code has it. Each older page carries a line at the top pointing to it. Where Orb has not yet answered (decision 11: how much of the loop is in Alpha, and whether "body" is a new number), the page marks the line open with the recommendation, and does not guess. Checked by the EP's read and by Simulation's and Encounter's comments, routed through the EP.
2. (A-COMBAT-15, X-13) One page in `docs/design/` lists the six items. Each has: what it is in plain words, a recommendation (now, at a named milestone, or after Alpha), a size class, and whether it changes the sim's fingerprint. The path's own recommendations are the starting point (gravity well: size, zones and the snap; RT held stays the charge for Alpha; beam stages decided from spike S1; the catch, swat and taunt after Alpha). The EP puts them to Orb one question at a time and records the answers word for word.
3. (A-CONTROLS-04, X-13, X-20) If Orb says yes to decision 5: 3500 is the default flight speed in `data/fight/power.json` for every mode, the slider is gone from the private page, and a LAN match plays the same speed on both PCs with nothing typed. A short note in `docs/design/` lists each number keyed to absolute speed and whether it moved. `power_check` passes (Simulation). Checked by reading the first desktop build's packed `power.json`.
4. (A-CONTROLS-04, look) The trail and the dash at 3500 name the look gate (ADR 0010): a side-by-side against the reference build (`node tools/flash/side-by-side.mjs`) before the EP commits, since the 9 November build already flew at 3500 and nothing is meant to look different.
5. (Spike S3) One page in `docs/design/`: does the parked one-against-many work still apply (Encounter's dry run, A-AI-13); what six, eight and twelve weak bodies cost in frame time (a reading asked for through the EP); does respawn fit the five-body limit; whether the horde and its computer control (A-MODES-02 with A-AI-01) are nearer 12M or 20M tokens; and the question for Orb if there is one. The proposal on the table is at most three weak bodies at a time inside today's limit.
6. (Supports) A-ENERGY-05: a short ruling on the comeback as a rule for every fighter, with its numbers, once Orb answers decision 6. A-MODES-01: the list of the eight modes in the words a player will read, with which exist today and which show as "coming". A-AI-10: the perfect-block rate you would accept against a charged heavy, so QA's measurement has something to be read against.
7. Records: the pages themselves are the evidence; any reading you quote names its saved file under the owner's `docs/<area>/runs/<sha>/`.

Constraints:
- Tokens: about 0.75M as an estimate (three rows of size S at 0.25M), plus your share of the 4.5M set aside for the five spikes.
- State hash: A-CONTROLS-04 changes the sim's state fingerprint once the model is on, and lands only in golden window GW1, "Main is the game". The two pages and the spike change nothing.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; no browser of your own.
- Determinism: numbers live in data, not code; a data shape change updates its schema in the same commit.
- Originality: nothing from an existing franchise, in names or in rules text.
- Orb's rules: plain words; every question to Orb goes through the EP, one at a time, with one recommendation; a new idea goes in the ideas log and is not built; "workshop this" means a page or a toy, not a change to the game. Whatever comes back must complement high-speed combat.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: The two pages and the spike start on day one. The flight speed waits on Orb's decision 5 and on Simulation switching the energy model on in data (A-ENERGY-04), and lands with it in GW1. Waiting on this: the stamina, energy and body loop (A-ENERGY-01, A3) needs the model page; the gravity well and the beam rework (A3) need Orb's answers to the six items; the horde (A-MODES-02, A4) needs spike S3's page; UI's mode list needs your mode names.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- A-CONTROLS-04 (flight at 3500) lands in GW1b, after main reproduces the 9 November golden record. Spike S3 measures up to five weak bodies. (ORD-01, COS-10)
