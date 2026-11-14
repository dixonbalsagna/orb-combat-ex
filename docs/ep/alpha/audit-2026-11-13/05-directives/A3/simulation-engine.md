# A3: Simulation & Engine

Leads: A-COMBAT-03, A-ENERGY-03, A-ENERGY-10
Supports: A-ENERGY-01, A-COMBAT-01, A-WORLD-04

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: Up close the two fighters are drawn together into a close fight (the "gravity well": the pull that makes fighters step in and engage), and every energy, stamina and body number is a per-fighter line of data that a new fighter could bring without code.

Context:
- Read first: docs/ep/proposals/gravity-well.html (the packet; line 444 and its section on increments); the page from spike S2 (the gravity well toy run in A1; the EP sends its path); the model page Game Design wrote for A-ENERGY-02 in A1 (under docs/design/; the EP sends its path); docs/ep/proposals/alpha-feature-workshop-2.html lines 42-50 and 133-148; sim/core/fighter_data.gd.
- A-COMBAT-03 (blocker, XL, changes the fingerprint): no gravity well exists in code: no well, zones, draw, snap or intent read, only two pieces of the LT speed ruling behind switches. Evidence: docs/ep/proposals/gravity-well.html:444; data/director/interrupts.json:81; data/fight/power.json:113; a search for SimWell or DirIntent in sim, data, render, tools and qa finds nothing.
- A-ENERGY-03 (major, M, changes the fingerprint): energy's own numbers (start, cap, regain, charge rate, hit gain, guard drain and the older costs) are literals in code, shared by every fighter. Evidence: sim/core/state.gd:1077; sim/core/fighter.gd:685, :711, :767; sim/core/damage.gd:89-90; and in Encounter's code sim/director/exchange.gd:294, :343, :348, :595 and sim/director/beam.gd:101, :134, :140.
- A-ENERGY-10 (minor, S, changes the fingerprint): a new kind of meter cannot be added as data; the loader accepts only the two backburnered meter names. Evidence: sim/core/fighter_data.gd:20-23 (not independently verified by the audit: confirm by reading it first).
- Supporting rows: A-ENERGY-01 (the stamina, energy and body loop; Game Design leads the rules and numbers, you build the state), A-COMBAT-01 (the travelling beam, led by Encounter Systems), A-WORLD-04 (dug ground reads as sea, led by World & Environment; its fix touches sim/core/field.gd).

You own: sim/core/, docs/architecture/
- ask under NEEDS FROM EP for a grant: data/fight/ (the well's data, and energy, stamina and body numbers; data/fight/power.json exists today)
- ask under NEEDS FROM EP for a grant: data/fighters/ (Narrative & Fighter Identity's path) if the model page puts per-fighter numbers in each fighter's file
- ask under NEEDS FROM EP for a grant: sim/director/exchange.gd and sim/director/beam.gd (the literals listed above), or have Encounter Systems move those to your data names

Acceptance criteria:
1. Closes A-COMBAT-03 in the smaller version the path proposes: the well's size, its zones and the snap into a close fight, all numbers in data. Checked by the packet's seam tests (the well behaves the same across the planet's wrap), by a line showing the fingerprint is identical with the well switched off, and by QA's match checklist probe seeing the pull in a normal match (exit X-13, partial). Saved under docs/architecture/runs/<sha>/. Full version if Orb declines the proposal: the whole packet (the far kit, the catch, the swat and the taunt as well), as a second increment after A3 with one more golden window.
2. Closes A-COMBAT-03. Stop rule: if the first cut is not playable at the midpoint of A3, say so that day; A3 then ships size and zones only and the snap moves to GW3, without holding the beam or the stamina loop.
3. Closes A-COMBAT-03. Orb's answer to "up close, does your stick move only your own fighter" is built as answered; until it is answered the packet's default stands and the report says so.
4. Closes A-ENERGY-03. No energy number is a literal in sim/core: each named line above reads from data per fighter, with a schema. The parity gate (the GDScript port against the JS core in sim/) shows no value changed by rounding; the corrected two-fighter ratchet (tools/ratchet-two-fighter.mjs, corrected in A1) finds no fighter-specific code in the energy, stamina and body systems (exit X-15, must pass in the resized form). Saved under docs/architecture/runs/<sha>/.
5. Closes A-ENERGY-10. A meter kind that is not one of the two backburnered names loads from data and is carried in state, shown by a test that loads a fixture fighter with a third meter.
6. Supports A-ENERGY-01: stamina and the body number exist in sim state as the model page defines them, behind a switch that stays off until QA's comeback measurement is in. Supports A-COMBAT-01: any new beam state in sim/core that Encounter Systems lists. Supports A-WORLD-04: the two-hunk change to sim/core/field.gd in World's parked step 2 (docs/world/pending/globe-step2/README.md) is reviewed and applied or redone by you.
7. Every sim window also runs Rendering's render checks; nothing here should change the picture, and if it does it passes the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed.

Constraints:
- Tokens: about 9.5M as an estimate (1 XL, 1 M, 1 S at the register's size classes); the well keeps its XL class until S2 reports.
- State fingerprint: all three lead rows change it. They land only in golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once). Each lands behind its own switch with its own probe.
- The well replaces the three distance bands every close-fight rule reads: change no rule in sim/director/ yourself; list what must read the well and the EP routes it to Encounter Systems.
- Orb's rules: nothing drawn on, over or between the fighters to show the well; RT held stays the charge for Alpha.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Determinism: seeded RNG, fixed step, no rendering state in the sim, shortest-arc wrap maths for every distance. Numbers live in data, not code; a change to a data file's shape updates its schema in tools/schemas/ in the same commit (ask under NEEDS FROM EP for a grant: tools/schemas/).
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: golden window GW1 closed; spike S2's page read and Orb's decision 12 confirmed (how much well; whose stick moves whom); the model page (A-ENERGY-02) exists before A-ENERGY-03, which also needs A-ENERGY-01's rules. Waiting on this: Encounter Systems' close-fight rules; Game Design's loop (it needs your state); transformations and the move table in A4.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Until Orb has answered the close-fight question from spike S2's clip, build size and zones only. Do not build "the packet's default" (today's rule, your stick moves both fighters) in its place. The stop rule is Orb's question unless Orb gave the standing yes in A1. This row is carried at 12M until S2 reports. (ORB-04, ORB-05, COS-02)
