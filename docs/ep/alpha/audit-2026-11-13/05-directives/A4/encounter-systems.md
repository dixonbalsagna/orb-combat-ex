# A4: Encounter Systems

Leads: A-AI-01, A-AI-06, A-AI-08, A-AI-09
Supports: A-MODES-02, A-COMBAT-04, A-COMBAT-06, A-COMBAT-12, A-CODE-05, A-QA-06

Goal: Weak enemies in a horde come at the player in turns and are fun to clear; a solo player can start a 2v2 with a computer partner who helps without carrying; and the computer opponent throws the same right-stick strikes the player does.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4 and the resize table); Game Design's horde page (written ahead of this brief; the EP gives the path); spike S3's page and A-AI-13's result (does the parked one-against-many work still apply); `docs/director/one-v-many.md`; `docs/director/pending/one-v-many-s3/README.md`; `docs/combat/henchmen-grades.md`; `sim/director/ai.gd`; `data/director/ai.json`; `sim/core/cross.gd`; `docs/ep/alpha/audit-2026-11-13/02-areas/AI.md` (findings F-AI-01, F-AI-06, F-AI-08, F-AI-10).
- A-AI-01 (L, blocker): no computer control for many weak enemies: henchmen are paper only, the one-versus-many director ("the ring", which places guards around a principal) is parked and not on main, and a match holds five bodies at most with no waves or respawn. Evidence: `docs/combat/henchmen-grades.md:3`; `sim/core/roster.gd:36-40`; `docs/director/pending/one-v-many-s3/README.md:3`.
- A-AI-09 (S, minor): the computer's level is one value for the whole match, not one per fighter. Evidence: `sim/director/ai.gd:390-392`; `sim/director/ai.gd:432-434`; `sim/core/sim.gd:156-157`; `data/director/ai.json:3` (its own note: "step 4 makes it a per-slot setup key").
- A-AI-08 (M, major): there is no computer ally: the only 2v2 line-up puts both computers on the enemy team, and no menu or host can start a match with a computer on a human's side. Evidence: `net/lan.gd:34` and `:35` (`AI2`: p2 and p4 are the computers); `sim/core/cross.gd:5`.
- A-AI-06 (M, nice, placed here): the computer never throws a right-stick strike; the only right-stick input it writes is the beam's hold. Evidence: `sim/director/beam_move.gd:157`; `sim/director/beam_move.gd:175-188`; `sim/director/ai.gd:262-283`.
- Supporting rows: A-COMBAT-04 (the move table's routing lives in `sim/director/brawl.gd`, `stance.gd`, `interrupt.gd`, `blast.gd`); A-COMBAT-06 and A-COMBAT-12 (forms and a blow in flight, `sim/director/exchange.gd:961-968`); A-CODE-05 (`sim/director/brawl.gd` holds 34 of the two-fighter places, `exchange.gd` 32, `zip.gd` 18).

You own: `sim/director/`, `data/director/`, `docs/director/`.
- ask under NEEDS FROM EP for a grant: `sim/core/sim.gd` (the per-slot level key for A-AI-09; list the lines first)
- ask under NEEDS FROM EP for a grant: `data/fight/` (reading or adding horde numbers Game Design placed there)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (any data shape you change)
- Menu rows, the LAN line-up in `net/lan.gd`, and the sim's waves and respawn belong to UI, Netcode and Simulation: list what you need from each under NEEDS FROM EP.

Acceptance criteria:
1. (A-AI-09) The level is a per-slot setup key: a check in `sim/director/` runs one match with two slots at different levels and shows each slot plays at its own; a match that sets one level for all plays as before. First to land.
2. (A-AI-01) Weak enemies are driven by data-described behaviour from the horde page: who attacks, who waits, how they close, how they fall. A headless horde check runs a scripted player through a full run with no error. Written for the smaller version the path proposes: at most three weak bodies at a time inside today's five-body limit. Full version if Orb declines the proposal: control for bigger, graded waves once the body limit is raised.
3. (A-AI-01) The check's debug feed names, for each enemy decision, why it was made (pillar: every decision is explainable).
4. (A-AI-01) Versus is unchanged with no horde in the match: the 1v1 golden records move only by what GW3 as a whole re-records, and CI's parity job is green after the window.
5. (A-AI-08) A line-up of one human and a computer partner against two computers can be started from a setup; the partner's level is set apart from the enemies' (uses criterion 1). A check in CI plays it to a result.
6. (A-AI-08) A written quality bar for the partner, agreed with Game Design through the EP, and a first reading against it (for example the share of the team's damage the partner does). The tool exists and the reading is saved; QA's band (A-QA-06) judges it.
7. (A-AI-06) The computer throws right-stick strikes at Medium and Hard at rates held in `data/director/ai.json`; a batch counts strikes thrown per match per level, and QA re-reads every level's win rate through the EP. It lands before A5's difficulty tuning, not after.
8. (support, A-COMBAT-04) Each cell Combat fills is reachable through the director's routing; (A-COMBAT-12) the director's side of the in-flight rule is in; (A-CODE-05) no new place in `sim/director/` names exactly two fighters, and the ratchet's count does not rise.
9. Evidence: every check's output is saved under `docs/director/runs/<sha>/`. Anything here that changes what a player sees (enemy placement on screen, the partner's position) goes through the look gate (ADR 0010): a side-by-side against the reference build in `docs/ep/taste.md`, made with `node tools/flash/side-by-side.mjs`, before it is committed.

Constraints:
- Tokens: about 6.7M as an estimate (L 4M + M 1.2M + M 1.2M + S 0.25M).
- All four rows change the sim's state hash. They land only in golden window GW3, "Many bodies and the full fighter".
- Machine: Godot headless only; at most 3 Godot processes for a short gate; a batch over about ten minutes at below-normal priority, and a reading taken on a saturated machine is marked invalid; no browser capture of your own (Tools' launcher only).
- Determinism: seeded RNG, fixed step, no rendering state in the sim; the computer gets an outcome only by an input (ADR 0008); numbers in data, schema updated in the same commit as a shape change.
- Originality: enemy behaviours and names are our own.
- Orb's rules: must complement high-speed combat; nothing drawn on, over or between the fighters to show who is the partner or who attacks next; bystanders are never killed; plain words in the feed and in reports.
- The parked ring's patches are a month old and apply by exact text: do not point an apply script at the repository root; rebuild on today's code.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: A-AI-09 needs nothing and goes first. A-AI-01 waits on Game Design's horde page (A-MODES-02) and on Simulation's waves and respawn. A-AI-08 waits on A-MODES-03 (a 2v2 that can be started on one PC). A-AI-06 goes after the horde's enemy control. Waiting on this: A-QA-06 (team and horde bands), the mode smoke suite's horde and partner runs, and A5's difficulty tuning (A-AI-02, A-QA-05).
