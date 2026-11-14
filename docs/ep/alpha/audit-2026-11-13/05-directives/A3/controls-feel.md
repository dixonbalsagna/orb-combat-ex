# A3: Controls & Game Feel

Leads: A-COMBAT-07
Supports: A-COMBAT-02, A-CONTROLS-05

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: A player who has never been told the buttons gets a transformation in a normal match, because the game says how and the press is read.

Context:
- Read first: record docs/qa/runs/6a30b4c9/beam-trace-orb-1646.txt (the BEAM lines at t=12120, 16625 and 18516); docs/design/pad-first-press.md line 26; data/fight/ladder.json line 13; data/input/layouts.json line 98; ui/data/features.json lines 3 and 40; ui/widgets/ui_howto.gd line 198; ui/data/howto.json line 36.
- A-COMBAT-07 (major, S): in Orb's last full match the player's fighter never left tier 1 while the computer reached tier 3; the transform chord (LT + RT) has no hint. The cause is not evidenced: no hint, power too slow for a player, or the chord unread. One replay read of slot 0's power and transform edges settles it. Evidence: the record above; docs/design/pad-first-press.md:26; data/fight/ladder.json:13.
- Supporting rows: A-COMBAT-02 (signatures move to RT + RB + a flick of the right stick and RT + a flick; the right stick is switched off in the input layer while RT is held: sim/input/layout.gd:1050-1051, :1263; sim/input/strike_read.gd:28; data/input/layouts.json:91; led by Encounter Systems), A-CONTROLS-05 (the count of unanswered presses; docs/controls/refusals.md, uncommitted; led by Encounter Systems).

You own: sim/input/, docs/controls/
- ask under NEEDS FROM EP for a grant: data/input/layouts.json and data/input/timing.json (no director owns them)
- ask under NEEDS FROM EP for a grant: ui/data/howto.json, ui/data/features.json and ui/widgets/ui_howto.gd (UI & UX's path: the hint's words and where it shows are theirs; write what it must say)
- ask under NEEDS FROM EP for a grant: data/fight/ladder.json (no owner) only if the read shows power comes too slowly for a player; that is a numbers change and goes to Game Design through the EP

Acceptance criteria:
1. Closes A-COMBAT-07. A written read of Orb's saved match names the cause: slot 0's power over time, every transform press and whether each was read, saved under docs/controls/runs/<sha>/. The fix follows the cause and nothing else.
2. Closes A-COMBAT-07. The game tells the player the transform buttons where the how-to and the legend already speak (UI & UX builds it from your wording), and a scripted pad on Orb's scheme reaches at least the second tier in a normal match. A person's check: Orb gets a transformation on the A3 build (the PLAY THIS line).
3. Supports A-COMBAT-02: with RT held, a flick of the right stick is read (and with RT + RB held), without stealing the stick's plain strikes, the beam aim or the transform chord. Checked by an input test over scripted pads with a refusal count per input, saved under docs/controls/runs/<sha>/. The old RT + B signature read is removed in the same change.
4. Supports A-CONTROLS-05: docs/controls/refusals.md states the one counting rule for an unanswered press that the ledger then uses, so counts are like for like from here on.
5. The hint changes what a player sees: it passes the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed.

Constraints:
- Tokens: about 0.25M as an estimate (1 S at the register's size class); the support on the signature inputs is the larger piece and is counted under Encounter Systems' row.
- State fingerprint: A-COMBAT-07 does not change it if the fix is a hint; the input change for A-COMBAT-02 does, and lands only in golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once). If the read says the ladder's numbers must change, that also waits for the window.
- Orb's rules: beams are on the right stick only; RT held stays the charge for Alpha; the left stick moves and defends, the right hand attacks; no hint drawn on, over or between the fighters; plain words (say what to press and what you will see), seen by Orb before use.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Determinism: seeded RNG, fixed step, no rendering state in the sim, shortest-arc wrap maths for every distance. Numbers live in data, not code; a change to a data file's shape updates its schema in tools/schemas/ in the same commit (ask under NEEDS FROM EP for a grant: tools/schemas/).
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: golden window GW1 closed with the pad as Orb plays it (A-CONTROLS-02); the move coverage probe (A-CONTROLS-06, A1) exists. The stick change for A-COMBAT-02 comes first in A3, because Encounter Systems' signatures and Combat & Choreography's move table wait on it. Waiting on A-COMBAT-07: exit X-13's transformation line and X-04, both first required at A4.
