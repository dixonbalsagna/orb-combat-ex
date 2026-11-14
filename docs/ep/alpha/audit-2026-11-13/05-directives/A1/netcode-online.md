# A1: Netcode & Online Director

Leads: none
Supports: A-NET-05, A-CONTROLS-04, A-WORLD-14, A-SAVES-01, A-TOOLS-01

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: A match saved on one build and opened on another is turned away with a plain sentence on LAN as well as solo, and a LAN match plays the same flight speed and the same kind of planet as the solo game with nothing typed on either PC.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1; decisions 2, 5 and 13); `docs/ep/alpha/audit-2026-11-13/02-areas/NET.md` and `SAVES.md`; `docs/tools/lan-report.md`.
- A-NET-05 (Simulation leads): a replay carries no build id, so a replay from a build with the same data and different code runs and fails at a checkpoint. Evidence: `sim/core/replay.gd:43`, `:116-136`; `net/lan.gd:506-512` (the LAN save already keeps the build's commit beside the replay, `:511`, but nothing in the game reads it).
- A-CONTROLS-04 (Game Design leads): the LAN setup sends no flight speed, so LAN plays the data's 5000 while Orb's solo copy plays 3500. Evidence: `net/lan.gd:30`; `data/fight/power.json:108`; `docs/ep/vision.md:1688`.
- A-WORLD-14 (Orb's decision 2): LAN fixes planet 7. Evidence: `net/lan.gd:30`; `docs/ep/vision.md:1719`.
- A-SAVES-01 (QA leads): the first real LAN save has not been put through the report tool. Evidence: `docs/qa/runs/6a30b4c9/README.md:5`; `docs/ep/alpha/audit-2026-11-13/questions.md:16`.
- A-TOOLS-01 (Tools leads): the desktop packager refuses a preset that does not exclude `net/*`. Evidence: `tools/desktop-package.mjs:219`.

You own: `net/`, `docs/net/`.
- The replay format is Simulation's (`sim/core/replay.gd`) and the packager is Tools': say what you need under NEEDS FROM EP.

Acceptance criteria:
1. (A-NET-05, X-27) Once Simulation's replay carries a build id, the LAN save uses that one id (no second, separate stamp), and a LAN save from another build is refused with the same plain reason as a solo replay. A check under `net/tools/` loads a foreign LAN save. Result saved under `docs/net/runs/<sha>/`.
2. (A-CONTROLS-04) With 3500 as the data's default (if Orb says yes to decision 5), a LAN match plays the same flight speed on both PCs with nothing typed; a line in your report says where LAN takes the speed from. If the LAN setup must carry it, that changes the setup message: say so before building it.
3. (A-WORLD-14) A written line on what LAN does about the planet once Orb answers decision 2 (a fixed planet, or a seed the host draws and sends), with the cost. Nothing is built for this in A1 unless it is one data value.
4. (A-SAVES-01) QA has from you, through the EP, the steps to put Orb's first real LAN save through the report tool, and you read the result.
5. (A-TOOLS-01) One paragraph for Tools, through the EP: what the Windows desktop build of the solo game needs from `net/` and what it must leave out, so the packager's refusal is answered and not worked around. LAN inside the game is A3's work and is not started here.

Constraints:
- Tokens: no rows of your own in A1; allow about 0.25M as an estimate for the supporting work.
- State hash: nothing here changes the sim's state fingerprint. A-NET-05 lands before golden window GW1, "Main is the game", so every replay made from then on is refused plainly by a later build.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; stop only your own processes by PID. Do not start anything on this PC that opens a listening port and brings up a firewall question for Orb: if a check needs one, stop and tell the EP.
- Determinism: both PCs run the same seeded, fixed-step sim; nothing rendering-side enters a LAN message.
- Originality: nothing from an existing franchise.
- Orb's rules: plain words; forward-facing text is seen by Orb before use; nothing leaves a player's PC unless they send it; no network address is written into any file.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Item 1 waits on Simulation's build id (A-NET-05); item 2 on Orb's decision 5 and the energy model being on in data (A-ENERGY-04); item 3 on decision 2. Waiting on this: QA's replay record (A-SAVES-01); Tools' first desktop build (A-TOOLS-01); in A3, LAN inside the game behind a Host and Join row (A-NET-02).
