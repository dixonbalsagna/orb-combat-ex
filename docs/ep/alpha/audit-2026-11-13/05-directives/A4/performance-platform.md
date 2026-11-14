# A4: Performance & Platform

Leads: none
Supports: A-MODES-02, A-AI-01, A-MODES-03, A-WORLD-02

Goal: The new modes run as smoothly as a normal match: a horde at its largest wave and a couch 2v2 with both fights on screen hold 60 frames a second on Orb's PC, and a Steam Deck tester can send back the same reading in a file.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4's exit line for X-10; decision 19); spike S3's page (what six, eight and twelve weak bodies cost in frame time; the EP gives the path); `docs/perf/README.md`; the frame record and the one-click bench from A1 and A2 (A-PERF-04, A-PERF-03); `docs/decisions/0010-look-gate.md` (item 5: a visual effect that copies the frame or adds a full-screen pass needs your timing before it is committed).
- A-MODES-02 (Game Design leads) and A-AI-01 (Encounter leads): the horde does not exist; X-10 asks that the frame rate holds with the largest wave on screen. Evidence: `sim/core/roster.gd:36-40` (five bodies at most today); `docs/combat/henchmen-grades.md:183`.
- A-MODES-03 (Rendering leads): two fights on one screen means up to four panes; frame rate is the early warning the row names. Evidence: `render/core/main.gd:1337-1362`; `docs/ep/proposals/co-op-2v2.md:37`.
- A-WORLD-02 (World leads): the planet dials change what is generated and drawn (more cities, more water). Evidence: `data/biomes/planet.json:92`.

You own: `docs/perf/`.
- The bench and frame-record tools live in `tools/` (Tools owns them): ask under NEEDS FROM EP for a grant: `tools/` (only the bench scenes you add), or ask for Tools to add them.

Acceptance criteria:
1. (X-10; A-MODES-02, A-AI-01) A frame record on Orb's PC of a horde run at its largest wave, for one player and for two: the record holds 60 frames a second with no frame longer than 50 ms outside loading, or the miss is reported with the stage that costs most and the lever. Must pass on Orb's PC at A4.
2. (X-10) The one-click bench file a Deck tester runs includes the largest horde wave, and the reading from each friend's Deck is asked for through the EP when the A4 build reaches them as an update. First reading: the reading is saved; it is judged at A6.
3. (A-MODES-03) A frame record of couch 2v2 with both fights in view, with the other fight's bodies drawn. First reading saved; a miss is reported with its cause.
4. (A-WORLD-02) Generation and load time, memory and a frame record for the planet at each end of each dial (most cities, most water, and the default). First reading saved against the X-26 loading line (15 seconds on Orb's PC).
5. Any full-screen pass, frame copy or read-back proposed by Rendering, VFX or Camera in this milestone gets a timing on the web build before it is committed; the answer goes to the EP.
6. Every reading names its commit, scene, seed, machine and what else was running; a reading taken while the machine was saturated is marked invalid and taken again in a quiet window.
7. Evidence: readings and the bench files returned by testers are saved under `docs/perf/runs/<sha>/`.

Constraints:
- Tokens: supporting work, counted under the lead rows; plan for about an S to an M (0.25M to 1.2M) as an estimate.
- No change to the sim's state hash. Readings are taken after golden window GW3's rows land.
- Machine: benches run in a quiet window and at below-normal priority if over about ten minutes; Godot headless for sim timing, and windowed frame records only through the existing bench recipe; at most 3 Godot processes for a short gate; browser captures only through Tools' launcher.
- Determinism: a bench scene is seeded and repeatable.
- Originality: nothing here adds content.
- Orb's rules: no metric overrides the look (a change made to hit a frame-rate number that also changes the picture goes to Orb as a short visual question first); there is no target machine below the minimum specs set before launch, so the old PC is never reported as a gap; plain words; a tester's file carries nothing personal.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: the frame record on the played build (A-PERF-04, A1), the Deck bench (A-PERF-03, A2) and the Deck's first real reading from A2. Each reading waits on its mode landing. Waiting on this: X-10's must-pass line on Orb's PC, the horde page's lever if it misses, and A5's choice of the Deck's default quality.
