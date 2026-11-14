# A3: Game Design

Leads: A-ENERGY-01
Supports: A-COMBAT-01, A-COMBAT-03, A-ENERGY-03, A-WORLD-06

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: Stamina, energy and body work as one loop a player can feel: plain face-button blows refill stamina, specials and signatures spend it, low stamina makes injuries worse, and the fighter who falls behind can still come back.

Context:
- Read first: your own model page from A1 (A-ENERGY-02); docs/ep/vision.md lines 1735, 1756 and 1787-1788 (Orb's words); docs/ep/proposals/alpha-feature-workshop-2.html lines 42-50 and 133-148; data/fight/power.json; docs/design/damage-model.md; docs/design/minimal-hud.md.
- A-ENERGY-01 (blocker, L, changes the fingerprint): no stamina and no "body" number exist in any code or data, so the energy, stamina and health loop Orb defined for Alpha is a plan only. Evidence: a search for "stamina" in sim, render, ui, net, data and audio at 8901d351 finds nothing; docs/ep/vision.md:1735, :1756.
- The row's named risk: a runaway (the fighter landing blows gets stronger while the one being hit gets worse injuries). QA's count of how often the fighter who falls behind first still wins shows it early.
- Supporting rows: A-COMBAT-01 (the beam's speed and width numbers; docs/design/beam-physics.md), A-COMBAT-03 (the gravity well's numbers), A-ENERGY-03 (which energy numbers are per fighter), A-WORLD-06 (the crater-width ratio between tiers: restate the criterion or tune the energies).

You own: docs/design/
- ask under NEEDS FROM EP for a grant: data/fight/ (the loop's shared rules and switch; no director owns it)
- ask under NEEDS FROM EP for a grant: data/fighters/ (Narrative & Fighter Identity's path) for each fighter's own numbers, if the model page puts them there
- ask under NEEDS FROM EP for a grant: The code is not yours: stamina and body state is Simulation & Engine's (sim/core/), costs inside exchanges are Encounter Systems' (sim/director/). Write what each must do under NEEDS FROM EP.

Acceptance criteria:
1. Closes A-ENERGY-01. One page under docs/design/ states the whole loop with numbers: what fills and spends stamina, what energy does, what "body" is (Orb's decision 11; the recommendation is to reuse the old hidden health number as the deep number behind the body parts, with the core kept as its own most important part), and how each is read from the fighter with no health bar. Checked by the EP against Orb's words in docs/ep/vision.md.
2. Closes A-ENERGY-01. Every stamina, energy and body number is a line of data per fighter with a schema; none is in code (exit X-15, must pass in the resized form: the corrected ratchet finds no fighter-specific code in those systems). Saved under docs/design/runs/<sha>/.
3. Closes A-ENERGY-01. The loop is switched on only after QA's comeback measurement is saved: over a scripted batch, how often the fighter who falls behind first still wins, with the loop off and on. If the number falls, the page says which lever was moved and the batch is re-run. A person's check as well: Orb fights with stamina empty and sees what a hit does (the PLAY THIS line for A3).
4. Closes A-ENERGY-01. In QA's match checklist probe a normal match shows stamina refilled by plain blows and spent by a special and a signature (part of exit X-13).
5. Supports A-COMBAT-01 and A-COMBAT-03: the beam's speed and width and the well's size and zones are written as numbers with reasons on your pages before the builders tune them. Supports A-ENERGY-03: a list of which of the listed energy literals are per fighter and which are shared. Supports A-WORLD-06: a one-paragraph recommendation to the EP on the X-14 ratio (keep "3 times", restate it, or tune energies inside this window).
6. Any change to what the player sees from this loop (a readout, a pose, an aura) is not yours to build; where your page asks for one it names the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed.

Constraints:
- Tokens: about 4M as an estimate (1 L at the register's size class); supporting work is not counted.
- State fingerprint: A-ENERGY-01 changes it. It lands only in golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once), behind its own switch.
- Orb's rules: no health bar; nothing drawn on, over or between the fighters; whatever is added "has to complement high speed combat"; the hero and villain meters stay on the backburner; plain words on every page Orb reads. The absorb (hold LB, time RB) is in the ideas log, not in this brief.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Determinism: seeded RNG, fixed step, no rendering state in the sim, shortest-arc wrap maths for every distance. Numbers live in data, not code; a change to a data file's shape updates its schema in tools/schemas/ in the same commit (ask under NEEDS FROM EP for a grant: tools/schemas/).
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: the model page (A-ENERGY-02, A1) exists; Orb's decision 11 confirmed; golden window GW1 closed. Waiting on this: A-ENERGY-03 (Simulation & Engine), stamina costs on specials and signatures (Encounter Systems, Combat & Choreography), the move table and transformations in A4, and the last numbers window in A5. Working ahead for A4: the horde page from spike S3.
