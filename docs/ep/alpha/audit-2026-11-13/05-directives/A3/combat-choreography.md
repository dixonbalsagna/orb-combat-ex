# A3: Combat & Choreography

Leads: none
Supports: A-COMBAT-02, A-ENERGY-01

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: Each of the two fighters has a martial signature of his own to throw on RT + a flick of the right stick, beside the energy signature on RT + RB + a flick.

Context:
- Read first: data/combat/templates.json round line 964 (today's signature row); data/fighters/PROTAGONIST/fighter.json line 5; docs/ep/vision.md line 1710 (Orb's inputs); docs/combat/ (your own pages on each fighter's kit); Game Design's model page for stamina, energy and body (the EP sends its path).
- A-COMBAT-02 (blocker, L; led by Encounter Systems): signatures are not on Orb's inputs: RT + RB + a right-stick flick and RT + a flick cannot be pressed, RT + B is the only signature input, and no martial signature exists for either fighter. Evidence: sim/director/brawl.gd:3178-3179; data/input/timing.json:49; data/combat/templates.json:964.
- A-ENERGY-01 (blocker, L; led by Game Design): no stamina exists; Orb's rule is that plain blows refill stamina and specials and signatures cost it as well as energy (docs/ep/vision.md:1787-1788).
- Fighter ids in data are PROTAGONIST and RIVAL (RIVAL is the Anti-hero).

You own: data/atoms/, data/exchanges/, docs/combat/
- ask under NEEDS FROM EP for a grant: data/combat/templates.json (no director owns data/combat/): the martial signature's row for each fighter
- ask under NEEDS FROM EP for a grant: data/fighters/ (Narrative & Fighter Identity's path) if a signature is named in the fighter's own file

Acceptance criteria:
1. Supports A-COMBAT-02. One martial signature for each fighter is authored as data from atoms (the small authored pieces of motion a move is built from): distinct from that fighter's energy signature and from the other fighter's, with its outcomes against a guarding, a dodging and an attacking defender. Checked by Encounter Systems' scripted pad firing it on RT + a flick, and by the data job in CI (schema updated in the same commit if the shape changes). A page under docs/combat/ describes each one in plain words.
2. Supports A-COMBAT-02. The page for each signature says what the player presses and what they see, for the EP to put to Orb before it is used; names are screened by Legal through the EP.
3. Supports A-ENERGY-01. Every special and signature you own carries a stamina cost as a line of data, with values from Game Design's page; plain face-button blows carry the refill. None is a number in code.
4. A signature changes what a player sees: it passes the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed.

Constraints:
- Tokens: no lead rows in A3; supporting work is not sized in the register. Your large row (A-COMBAT-04, the move table, XL; L if Orb accepts the smaller table) is in A4.
- State fingerprint: new signature data and stamina costs change it. They land only in golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once).
- Orb's rules: combos look choreographed but stay in the player's hands in real time; each press is a blow; pose, gesture and look rules come from the creative rulebook kept by Art and Animation, not from Legal; no name, move or catchphrase from an existing franchise; in-progress character art is never public.
- Parked work in docs/combat/pending may be stale: check main before building on a park.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Determinism: seeded RNG, fixed step, no rendering state in the sim, shortest-arc wrap maths for every distance. Numbers live in data, not code; a change to a data file's shape updates its schema in tools/schemas/ in the same commit (ask under NEEDS FROM EP for a grant: tools/schemas/).
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: Orb's inputs for the two signatures confirmed; Controls & Game Feel's stick change and Encounter Systems' input rows far enough that a flick with RT held is read. Waiting on this: exit X-13's "both signatures" line and X-17. Working ahead for A4: the move table starts the day the signature inputs are fixed, behind a switch.
