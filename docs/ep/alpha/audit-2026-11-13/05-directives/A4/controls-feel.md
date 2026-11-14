# A4: Controls & Game Feel

Leads: A-CONTROLS-01
Supports: A-COMBAT-04, A-MODES-03

Goal: Two people with two pads on one PC can play as a team in couch 2v2, each pad always driving its own fighter, and the supported pad line-ups are written down so nobody has to guess.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; the resize table's row for A-CONTROLS-01; decision 16); `docs/ep/alpha/audit-2026-11-13/02-areas/CONTROLS.md` (F-CONTROLS-02 and its verify note; line 25 on what two pads already do; F-CONTROLS-03); `docs/controls/two-v-two-input.md`; `docs/controls/local-two-player.md` (the two-pad checklist at lines 51-69); `sim/input/hub.gd`; `sim/input/layout.gd`; Game Design's line-ups page (the EP gives the path).
- A-CONTROLS-01 (M, major): couch 2v2 with four pads cannot be played: the input hub holds two human slots per PC and every pad routine loops over two. Evidence: `sim/input/hub.gd:26-29` (`slot_device`, `slot_pad`, `claimed`, `humans` are two long); `sim/input/hub.gd:294-304`; `docs/controls/two-v-two-input.md:30` ("the hub keeps two human slots per machine"); `render/core/main.gd:1350-1361`.
- From the audit's verification: X-09 asks for the supported line-ups to be stated, and two humans with two computer partners fits two slots. The hub limit alone rules out only three- and four-pad line-ups; that couch 2v2 cannot be started at all is A-MODES-03 (Rendering leads).
- Supporting rows: A-COMBAT-04 (the move table: you run the pad coverage probe from A1 and own the input side of any empty cell, for example `sim/input/layout.gd:522-524`, where a special press becomes the plain blow while `data/input/timing.json:48` keeps `specialsOff` true); A-MODES-03 (which sim slot each pad drives in a two-fight match).

You own: `sim/input/`, `docs/controls/`.
- ask under NEEDS FROM EP for a grant: `data/input/` (press timing or layout data; no director owns it)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (any data shape you change)
- The menu's device rows are UI's and the match start in `render/core/main.gd` is Rendering's: list what each needs from the hub under NEEDS FROM EP.

Acceptance criteria:
1. (A-CONTROLS-01) Written for the smaller version the path proposes: in a couch 2v2 (two people as a team against two computer fighters) the two pad slots drive the two human fighters of a two-fight match, the first connected pad is player one, and a pad's presses reach only its own fighter. An input test with a verdict (an extension of the existing join test) proves it for the two-fight setup. Full version if Orb declines the proposal: four pad slots with per-slot settings and remap files (M), plus a four-way picture that does not exist.
2. (A-CONTROLS-01, X-09) The supported line-ups page in `docs/controls/` says in plain words which pads and keyboard combinations work for couch 2v2 and for 2v2 with a computer partner, and what happens with a third or fourth pad plugged in (it is ignored, with no crash and no stolen slot). An input test covers the extra-pad case.
3. (A-CONTROLS-01, X-07) A pad unplugged mid-match in couch 2v2 pauses with the plain notice built in A2 (A-CONTROLS-03), for either player. Checked by the input test and by one line on the manual checklist.
4. (A-CONTROLS-01) The manual two-pad checklist is extended to couch 2v2 and run once by a person on Orb's PC: each pad drives its own fighter, player one starts on the left, settings and remaps for each player are remembered. The signed-off checklist is saved.
5. (support, A-COMBAT-04) The pad coverage probe is run on each fighter at the start of the milestone and after each batch of Combat's cells; each report is handed to the EP. Any cell that is empty because the input layer blocks it is fixed on the input side or listed with its lines.
6. (support, A-MODES-03) The slot map for a two-fight match on one PC is written (which pad, which sim slot) and matches what LAN 2v2 already uses for its local player.
7. Evidence: test output, probe reports and the signed checklist are saved under `docs/controls/runs/<sha>/`. Nothing here should change the picture; if it does (a join prompt, a pause notice), it goes through the look gate (ADR 0010): a side-by-side against the reference build in `docs/ep/taste.md` before it is committed.

Constraints:
- Tokens: about 1.2M as an estimate (M); about 0.25M (S) if the smaller version stands.
- The lead row does not change the sim's state hash: the slot map is setup, not a new input word. If a change would alter the packed input word (`docs/controls/two-v-two-input.md` section 2 describes one), stop: that is a hash change and must go to the EP for golden window GW3.
- Machine: Godot headless only; at most 3 Godot processes for a short gate; scripted pads over the existing recipe; no browser capture of your own.
- Determinism: input is recorded per tick and replayable; seeded RNG, fixed step; numbers in data, schema updated in the same commit as a shape change.
- Originality: nothing here touches content.
- Orb's rules: the right stick is the attacking hand and the left stick moves and defends; beams only from the right stick and the signature inputs; plain words in notices and on the line-ups page (forward-facing text is seen by Orb first); nothing drawn on, over or between the fighters to show which pad is whose.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Orb's answer to decision 16 (two people against two computers); the pause-on-unplug notice (A-CONTROLS-03, A2); the pad coverage probe (A-CONTROLS-06, A1). Waiting on this: A-MODES-03 (couch 2v2 from the menu) needs the slot map, and through it A-AI-08 (the computer partner); Combat's table needs the probe reports.
