# A4: Simulation & Engine

Leads: A-CODE-05, A-COMBAT-12
Supports: A-MODES-02, A-AI-01, A-AI-09, A-COMBAT-06, A-WORLD-02, A-MODES-03

Goal: A tester sees a transformation finish the same way every time even when a blow was already on its way, and a later third fighter can join the energy, stamina, body and forms systems without anyone writing fighter-specific code.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; the resize table's row for A-CODE-05; "Exit criteria this audit proposes to change", X-15); `docs/ep/alpha/audit-2026-11-13/02-areas/CODE.md` (F-CODE-05, line 75 for the counts) and `02-areas/ENERGY.md` (F-ENERGY-14); `tools/ratchet-two-fighter.json`; `tools/ratchet-two-fighter.mjs`; `docs/ep/alpha/audit-2026-11-13/reads/RR-02.md` (lines 96-106: where a transformation is and is not protected); `docs/architecture/forms-core.md`; `sim/core/forms.gd`; `sim/core/pause.gd`; `sim/core/damage.gd`; `sim/core/roster.gd`; Game Design's horde and forms pages (the EP gives the paths).
- A-CODE-05 (L, major): adding a third fighter needs code today: 365 places in shipped code name exactly two fighters, and per-fighter look tables sit in render and UI code keyed by fighter id. Evidence: `tools/ratchet-two-fighter.json:10` (the count); `render/core/look.gd:489`; `render/vfx/beam_look.gd:16`; also `sim/director/brawl.gd:2318` (a role read as "hero" or "villain") and `data/fight/power.json:91-102` (kit fields keyed by fighter). The ratchet counts four spellings only (`S.dirS.ex`, `fighters[0]`, `fighters[1]`, `SimRoster.opp`); the largest holders are `render/camera/split_rig.gd` 41, `sim/director/brawl.gd` 34, `sim/director/exchange.gd` 32.
- A-COMBAT-12 (S, minor): a live transformation blocks new exchanges, but damage has no transformation guard, so "respected" is not proven for shots already in flight. Evidence: `sim/director/exchange.gd:961-968`; `sim/core/damage.gd` (no check on `breakIn`, `formReady`, a transforming state or `SimPause`); `RR-02.md:105-106`.
- Supporting rows: A-MODES-02 and A-AI-01 (waves and respawn inside `MAX_BODIES`, `sim/core/roster.gd:36-40`); A-AI-09 (the per-slot level key, `sim/core/sim.gd:156-157`); A-COMBAT-06 (per-fighter forms through `sim/core/forms.gd`); A-WORLD-02 (the planet dials in the match key, the replay header and the state hash's data domain); A-MODES-03 (a two-fight match started from the menu's setup; `sim/core/stage.gd:59-62` already takes `fights`).

You own: `sim/core/`, `docs/architecture/`.
- ask under NEEDS FROM EP for a grant: `tools/ratchet-two-fighter.mjs` and `tools/ratchet-two-fighter.json` (or ask for Tools to make the change: a per-system count)
- ask under NEEDS FROM EP for a grant: `data/fight/` (moving the kit fields at `data/fight/power.json:91-102` into each fighter's own data) and `data/fighters/` (where they would go; Narrative & Fighter Identity's folder)
- ask under NEEDS FROM EP for a grant: `sim/director/exchange.gd`, `sim/director/brawl.gd` (list the lines first; Encounter owns them)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (any data shape you change)

Acceptance criteria:
1. (A-COMBAT-12) The rule Game Design wrote for a blow in flight when a transformation starts is in the sim, for the pausing and the live versions. A sim test starts a transformation with a shot in flight and with a melee blow one tick from landing, and asserts the written outcome for each. Result saved under `docs/architecture/runs/<sha>/`.
2. (A-COMBAT-12, X-04) The transformation probe from A1 reports "a blow in flight handled the written way" for both fighters.
3. (A-CODE-05) Written for the smaller version the path proposes: the ratchet reports its count per system, and the count is zero in the energy, stamina, body and forms systems; the count elsewhere is recorded in `tools/ratchet-two-fighter.json` and CI fails if it rises. Full version if Orb declines the proposal: every one of the 365 places and the per-fighter look tables cleared at Alpha (L, about 3M more, in this window).
4. (A-CODE-05) No code in those four systems reads a fighter's id, name or the words "hero", "villain" or "rival" to choose a number: the kit fields keyed by fighter move to each fighter's own data. Checked by a grep recorded in the run folder and by the ratchet.
5. (A-CODE-05, X-15) A third-fighter drill: a data-only third fighter (a copy with changed numbers; never shown to a player) is loaded and a headless match with it runs to a result, exercising energy, stamina, body and forms. The drill is a check with a verdict line; its output is saved.
6. (support, A-MODES-02) Waves and respawn exist in the sim inside the five-body limit: a body that falls can be replaced under the horde page's rule, by setup and tick alone. A 1v1 match is byte-for-byte what it was apart from what GW3 re-records; the determinism and parity checks pass after the window.
7. (support, A-AI-09, A-WORLD-02, A-MODES-03) The per-slot level, the three planet dials and a menu-started two-fight match are each carried in the match's setup, in the replay's key and in the state hash's data domain; a replay made with different dials is refused with a plain message, not a crash.
8. Evidence: gate results (determinism, parity, the render gates that every sim window also runs) saved under `docs/architecture/runs/<sha>/`.

Constraints:
- Tokens: about 4.25M as an estimate (L 4M + S 0.25M); about 1.45M if the smaller version of A-CODE-05 stands (M).
- Both rows change the sim's state hash. They land only in golden window GW3, "Many bodies and the full fighter"; the golden records are re-recorded once for the whole window, and replays from earlier builds stop verifying (the build id in the replay, from A1, makes that a plain refusal).
- Machine: Godot headless only; at most 3 Godot processes for a short gate; long runs at below-normal priority; a reading on a saturated machine is invalid.
- Determinism: seeded RNG, fixed step, float64 and our own trig; no rendering state in the sim; the JS core in `sim/` stays the parity oracle; numbers in data, schema updated in the same commit as a shape change.
- Risk to hold: the largest counts sit in the two riskiest files (`split_rig.gd`, `brawl.gd`); a change there can move the camera or the hash. Under the smaller version those files are left alone.
- Originality: the drill's third fighter is a numbers-only stand-in with no name or look of its own.
- Orb's rules: no health bar; a fighter's health reads from the fighter; plain words in messages a player can meet.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: A-ENERGY-01 and the corrected ratchet (A3) on main; Game Design's forms page (the in-flight rule) and horde page. Waiting on this: A-AI-01 (enemy control needs waves and respawn), A-AI-09 (needs the per-slot key), A-WORLD-02 and A-MODES-03 (need their setup keys), and the single re-recording of the golden records at the end of GW3.
