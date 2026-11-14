# A1: Encounter Systems Director

Leads: A-COMBAT-05, A-COMBAT-11, A-AI-05, A-AI-10, A-AI-13, A-MODES-07
Supports: A-COMBAT-14, A-ENERGY-05, A-CONTROLS-02, A-COMBAT-08, A-CODE-01

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: A build made plainly from main fights, ends its matches and plays its computer opponent exactly as the build Orb played on 9 November did, a stick beam the player let go of never fires later on its own, RT + B is a signature only just after RT, and Orb has a short clip of a beam that can be sidestepped.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1 and "Change control"); `docs/ep/alpha/audit-2026-11-13/01-inventory/I-08-data-schemas-switches.md` (the table of switches: main against the two kept builds); `docs/ep/alpha/audit-2026-11-13/02-areas/COMBAT.md`, `AI.md`, `MODES.md`; `docs/tools/runs/6a30b4c9/switch-list.txt`; `docs/qa/runs/6a30b4c9/README.md`; `docs/ep/vision.md` lines 1683 and 1325.
- A-COMBAT-05: a released stick beam that cannot start waits up to 90 ticks and then fires into whatever the player is doing. Evidence: `sim/director/beam_move.gd:266-272`; `data/director/interrupts.json:296`; `docs/qa/runs/6a30b4c9/beam-trace-orb-1646.txt`.
- A-COMBAT-11: RT + B stays a signature for as long as the fighter is not channelling, not for 12 ticks, because the rule reads state and not time. Evidence: `sim/director/brawl.gd:3178-3179`; `docs/qa/runs/6a30b4c9/README.md`.
- A-AI-05: main's computer-opponent data is not the played build's (Easy's pace matching, beam pacing against a human, the computer's hold-and-release beam). Evidence: `data/director/ai.json:14`, `:56`; `data/director/interrupts.json:294`, `:303`.
- A-AI-10: the fix for "the computer perfect-blocks charged attacks too easily" is parked (finished work waiting outside main) and its data key is in the schema but in no data file and no code. Evidence: `docs/director/pending/perfect-guess/README.md:3`; `tools/schemas/director-ai.schema.json:506`; `sim/director/interrupt.gd:411-431`.
- A-AI-13 (nice to have): the parked one-against-many work applies by exact-text patches last rebuilt on 2026-10-16; whether it still applies is not evidenced. Evidence: `docs/director/pending/one-v-many-s3/README.md:3`, `:7`, `:33`.
- A-MODES-07: the rules that end a match as the played build did (knockout only by a finishing move, wear for an idle player, the last event after the time cap) are off on main. Evidence: `data/director/interrupts.json:250-251`; `sim/director/ending.gd:33-34`; `sim/core/wounds.gd:38`.
- Spike S1 (a throwaway trial on a scratch copy; nothing lands): one beam that leaves the fighter, travels at a speed and misses a defender who steps off its line. Read `docs/design/beam-physics.md` and `sim/director/beamplay.gd:2-4`, `:55-58`, `:398-420`. The register's check note: a stick beam aimed more than 35 degrees off the line already misses (`sim/director/beam_aim.gd:8-9`), but inside the cone it always arrives.

You own: `sim/director/`, `data/director/`, `docs/director/`.
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (only if a data file's shape changes; the schema moves in the same commit)
- ask under NEEDS FROM EP for a grant: `tools/preview/switches.mjs` (Tools removes each switch-table row once main's data carries it; you name the rows, Tools edits)
- For A-ENERGY-05 the lines in `sim/director/` are yours; Simulation leads the row and the EP routes the list.

Acceptance criteria:
1. (A-MODES-07, A-AI-05) Every switch row in the inventory table whose data sits in `data/director/` reads the same on main as in the played build's packed data, or has a written line saying why it stays off. Checked by the EP's row count and by reading the first desktop build's packed `interrupts.json` and `ai.json`.
2. (A-MODES-07) A director check ends a scripted match each of the three ways (a finishing move, wear on an idle player, the last event after the time cap) on main's own data. Result saved under `docs/director/runs/<sha>/`.
3. (A-COMBAT-05) A released stick beam that cannot start is never fired later into another action: a director check covers it, and QA's count of late fires and refusals on Orb's saved play files and the scripted set is saved before and after (ask the EP to route the count to QA). The count of refusals is reported beside it, since dropping the wait may make beams feel refused more often.
4. (A-COMBAT-11) RT + B gives a signature only inside the tick window in data after RT is pressed; a check presses B at the window's last tick and one tick after. Saved under `docs/director/runs/<sha>/`.
5. (A-AI-10) The perfect-block rate against charged heavies is measured on the played build's packed data first (through the EP to QA). Then either the parked fix lands with its key in a data file and read by code, or the park is withdrawn in writing with the measurement as the reason. No schema key is left that no data file and no code uses.
6. (A-AI-05) Easy's pace matching, the beam pacing against a human and the hold-and-release beam are on in main's data; QA's first win-rate reading for Orb's scheme (X-06, first reading only) is taken on that data.
7. (A-AI-13, and your part of spike S3) A dry run of the one-against-many patches on a scratch copy of HEAD, writing nothing to the repository: one saved page says which anchors still apply and which are dead.
8. (Spike S1) One page under `docs/director/`: what was tried, what it cost, whether A-COMBAT-01 is still a large job, what breaks in the beam struggle and the computer's beam play, and the question for Orb if there is one. If QA's beam escape probe (X-16) is ready, the spike is run through it at three ranges; if not, say so. A clip for Orb is asked for under NEEDS FROM EP.
9. (Supports) A-COMBAT-14: the director code the mixed string needs is on main and reads `data/combat/mixed.json`. A-ENERGY-05: your lines stop reading the backburnered meters once Orb answers decision 6. A-COMBAT-08: QA's probes for X-13 and X-16 can read what they need from the event feed; missing events are listed. A-CODE-01: no `data/director/` row is left differing without a reason.
10. Anything a player sees differently from the 9 November build names the look gate (ADR 0010): a side-by-side against the reference build (`node tools/flash/side-by-side.mjs`) before the EP commits it. Nothing is meant to look different.

Constraints:
- Tokens: about 1.5M as an estimate (six rows of size S at 0.25M), plus your share of the 4.5M set aside for the five spikes.
- State hash: A-COMBAT-05, A-COMBAT-11, A-AI-05, A-AI-10 and A-MODES-07 change the sim's state fingerprint. They land only in golden window GW1, "Main is the game" (the one landing in A1 after which the saved reference matches are re-recorded). A-AI-13 and the spike change nothing on main.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; a run over about ten minutes at below-normal priority; stop only your own processes by PID; no browser of your own (captures only through Tools' launcher, asked for through the EP).
- Determinism: seeded RNG, fixed step, no rendering state in the sim. Numbers live in data; a data shape change updates its schema in the same commit.
- Originality: nothing from an existing franchise.
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves or fades; plain words in anything Orb reads. One owner's rows at a time, each with its own gate run.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Orb's yes to decision 1 (make the 9 November build main's default), the working tree committed or deliberately ignored (A-PROCESS-03), and the played build's patches on main (A-CODE-03). Decision 6 before your A-ENERGY-05 lines. Waiting on this: A-CODE-01 (no row differs) and the golden record (A-CODE-02); the first desktop build (A-TOOLS-01); QA's first readings; and in A3 the beam rework (A-COMBAT-01), which waits on spike S1's page. The spike and the dry run can start on day one on a scratch copy.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- A-AI-10, A-COMBAT-05 and A-COMBAT-11 land in GW1b, after main reproduces the 9 November golden record, not with the switch flip. Spike S3 measures up to five weak bodies; the cost of lifting the five-body limit is given as an estimate. (ORD-01, COS-10)
