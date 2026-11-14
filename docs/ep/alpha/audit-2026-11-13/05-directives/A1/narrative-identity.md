# A1: Narrative & Fighter Identity Director

Leads: none
Supports: A-MODES-06, A-ENERGY-05

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: When a player picks a fighter for the first time, each of the two is shown by a name and one short line Orb has seen, and the old hero and villain meter numbers kept in the fighters' files stop changing a fight.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1; decisions 6 and 17); `docs/ep/alpha/audit-2026-11-13/02-areas/MODES.md` and `ENERGY.md`; `docs/ep/vision.md` for Orb's words on the two fighters.
- A-MODES-06 (UI leads): there is no fighter select; a match's fighters default to the first two ids of the roster file. Evidence: `sim/core/sim.gd:202`; `data/fighters/roster.json:1`; `ui/widgets/ui_menu.gd:8`.
- A-ENERGY-05 (Simulation leads): the backburnered hero and villain meters still act in every match, and their numbers sit in your files. Evidence: `data/fighters/PROTAGONIST/meters.json:57-60`; `data/fighters/RIVAL/meters.json:5`; `sim/core/damage.gd:50-56`. Orb's decision 6, as recommended: keep the comeback as a rule for every fighter, set every other effect to zero in data now, remove the code after Alpha.

You own: `docs/narrative/`, `data/fighters/`.
- The pick screen is UI's (`ui/`); the text it shows comes from your files or from UI's strings: say which under DECISIONS.

Acceptance criteria:
1. (A-MODES-06) For each fighter in `data/fighters/roster.json`: the name a player reads on the pick screen and one line of at most about ten words, in a data file UI can read, keyed by the roster id (PROTAGONIST, RIVAL) so a third fighter is added by data alone. Checked by UI's pick screen showing them with no fighter named in code.
2. (A-MODES-06) The two names and two lines are forward-facing text: they go to the EP as a short list for Orb to see before use, and nothing is shown to a tester until Orb has. The placeholder names in `CLAUDE.md` are not used on screen.
3. (A-ENERGY-05) Once Orb answers decision 6, the meter values in `data/fighters/PROTAGONIST/meters.json` and `data/fighters/RIVAL/meters.json` are set as Simulation's list says (you make the edit, or you grant Simulation the named lines, within a day of the ask). The files' shape does not change; if it must, the schema in `tools/schemas/` moves in the same commit (ask under NEEDS FROM EP for a grant: `tools/schemas/`).
4. (A-ENERGY-05) A short note in `docs/narrative/`: which lines of fighter text, if any, still speak of the hero's or the villain's meter, so they are not shown while the meters are off.

Constraints:
- Tokens: no rows of your own in A1; allow about 0.25M as an estimate for the supporting work.
- State hash: the meter values in item 3 change the sim's state fingerprint and land only in golden window GW1, "Main is the game", in Simulation's landing. The names and lines change nothing in the sim.
- Machine: no Godot runs are needed for this brief; if you make one, headless only and at most 3 processes.
- Determinism and data: per-fighter numbers live in data keyed by roster id; a data shape change updates its schema in the same commit.
- Originality: every name and line is our own; nothing from an existing franchise. Names shown to an outside tester need Legal's screening, which the EP routes.
- Orb's rules: plain words; forward-facing text is seen by Orb before use; characters are personalities; the villain never feeds on civilian deaths; in-progress character art is never public.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Item 1 can start on day one. Item 3 waits on Orb's decision 6 and on Simulation's list. Waiting on this: UI's fighter pick (A-MODES-06), which follows the mode list (A-MODES-01); Simulation's meter work in GW1 (A-ENERGY-05).
