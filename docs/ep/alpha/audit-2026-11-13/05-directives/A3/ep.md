# A3: Executive Producer

Leads: none
Supports: none

No register row in A3 is led by the Executive Producer (EP). This page is the EP's own work list for the milestone: what to settle before the briefs go out, the order to land in, and what closes A3. Ready to use once Orb approves the plan.

Goal: Orb gets the first build with new rules to press (a beam you can dodge, both signatures, the stamina loop, the pull into a close fight, LAN from the menu), and every exit line of A3 has a saved record on one commit.

Context:
- docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md: the A3 section, "Rows proposed smaller for Alpha", "Change control", risk 3 and decisions 11 to 14.
- docs/ep/alpha/audit-2026-11-13/04-milestone-rows.json (A3: 27 rows) and 03-gap-register.json.
- The briefs beside this page: encounter-systems, simulation-engine, game-design, world-environment, netcode-online, camera, controls-feel, ui-ux, vfx, legal-ip (lead rows); qa-balance, tools-pipeline, combat-choreography, rendering-techart (supporting work only).
- The pages from spikes S1 (the beam) and S2 (the gravity well), written in A1.
- docs/decisions/0010-look-gate.md and docs/ep/taste.md.

You own: docs/decisions/, docs/ep/, shared files. Commits and git state are yours alone.

Acceptance criteria:
1. Before any A3 brief is sent: golden window GW1 is closed; Orb's decisions 11 to 14 are confirmed from the spikes' pages and recorded in Orb's words in docs/ep/vision.md; each spike's page has been treated as a change request (a row a class bigger goes to Orb as one choice before it starts); the four smaller versions in A3 (A-COMBAT-03, A-NET-02, A-LEGAL-04, A-PERF-02) are accepted or declined and the briefs sent match.
2. Grants are answered in one pass: sim/input/layout.gd, data/input/, data/combat/templates.json, data/fight/, data/fighters/, sim/core/field.gd, sim/core/constants.gd, data/director/launch.json, export_presets.cfg (one editor only), tools/schemas/, tools/desktop-package.mjs, render/core/main.gd, render/anim/render_anim.gd, data/camera/, data/vfx/, docs/qa/, docs/tools/. Each grant names the lines.
3. GW2, "The fight's rules", lands as one window holding exactly A-COMBAT-01, A-COMBAT-02, A-COMBAT-03, A-CONTROLS-05, A-ENERGY-01, A-ENERGY-03, A-ENERGY-10, A-WORLD-03, A-WORLD-04, A-WORLD-07 and A-WORLD-10; each behind its own switch with its own probe; the golden records are re-recorded once; CI is read after the push. A record of the window is saved under docs/ep/runs/<sha>/.
4. The stop rule is applied on the day: if the gravity well's first cut is not playable at the midpoint of A3, A3 ships its size and zones only, the snap moves to GW3, and Orb is told in one line.
5. Every visible landing in A3 has its side-by-side tied to its commit (the look gate, ADR 0010), looked at by you before the commit; landings are not batched past the point where a picture can be tied to a change.
6. A3's exit is read from saved records on one commit: X-16, X-17, X-15 (resized), X-13 (partial), X-08 for LAN 1v1 and X-05 (partial) pass; X-14 and X-03 have readings; the gates on A2's list are re-run on this commit. A line that is missed goes to Orb within a day as one question with three choices (wait, ship short with the line carried by name, or cut something).
7. The PLAY THIS page for A3 is written in plain words from the path's text and seen by Orb with the build; the build reaches the two friends as an update with the five-minute bench file asked for (the EP asks Performance & Platform to read the two files; no register row).
8. Ideas said during A3 go into the ideas log the day they are said, with your one-line recommendation within a working day; nothing from the log is built without Orb's yes.

Constraints:
- Tokens: the milestone is about 48M as an estimate (1 XL, 7 L, 8 M, 11 S at the register's size classes), none of it the EP's own rows; the path counts about a third of each week for briefs, reviews, gate runs and rework. Give Orb the rough cost of each large job.
- State fingerprint: eleven A3 rows change it, all in GW2. Replays and LAN saves from before the window stop verifying and must be refused plainly (the build id in a replay, from A1).
- Encounter Systems' queue sets the date: if only one queue can have full attention, it is that one. Netcode carries the heaviest load in A3 (about 12.3M) and should have started in A2 behind a switch.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Verify sim and director batches with the full set of render gates; verify a build from its own packed data, not from a switch list.
- Orb's rules: one clear question at a time, in plain words; nothing drawn on, over or between the fighters; no dissolves or fades; forward-facing text is seen by Orb before use; the AI disclosure up front; in-progress character art is never public; never put a prompt in front of Orb.
- A director never briefs or messages another director; everything across directors in these briefs is routed by you.

Return: to Orb, the milestone report in plain words: what is new to press, what passed, what was carried, what it cost, and the next question.

Order: A1 and A2 closed (GW1 closed; the A2 gate list green). Inside A3: Legal's exception and Controls' stick change first; Tools' lint patch, then World's step 2; the beam, the signature inputs, the loop and the well each behind a switch; GW2 closes; then the LAN five-match record, the cable pull, the readings and the gate re-run on that commit. A4 (the move table, transformations, the horde, teams) waits on GW2.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- No build is uploaded to a channel an outside tester holds a key to, or sent to one, unless every gate on the "before an outside tester plays" list (X-02) is green with saved records on that commit. This is an exit line of this milestone. (MIS-01, ORD-02, COS-01, ORB-01, PC-01)
- X-15 at A3 reads "numbers are data per fighter; the count of fighter-specific code is read"; zero is first required at A4. (ORD-07)
- The gravity well's close-fight part does not start until Orb has answered from spike S2's clip. The stop rule for the snap applies without asking only if Orb gave the standing yes in A1; otherwise it is the question on `A3/orb.md` and nothing moves until the answer. (ORB-04, ORB-05)
- Order: A3's fight work proceeds during A2's tester round; A3 does not wait for the friends' files. X-14's keep, restate or tune choice is made on this milestone's reading before GW2 closes. (ORD-10, ORD-04)
