# A2: Controls & Game Feel

Leads: A-CONTROLS-03, A-CONTROLS-07
Supports: A-CONTROLS-08, A-UI-10

Goal: When a pad drops out mid-match the game pauses and says so in plain words, and the team knows from two real Steam Decks whether the Deck's own controls drive the game.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2; decision 20), `02-areas/CONTROLS.md` (F-CONTROLS-06, F-CONTROLS-10), `docs/controls/local-two-player.md`, `docs/tools/steam-deck.md`.
- A-CONTROLS-03: a pad unplugged mid-match does not pause: player two's fighter is handed to the computer and player one is moved to the keyboard while the match runs on. Evidence: `sim/input/hub.gd:294-304`, `:209-217`; `render/core/main.gd:1495-1499`; `docs/controls/local-two-player.md:19`. Verified detail: player two's unplug does leave a brief "left" line (`sim/input/hub.gd:216`, shown at `ui/hud/ui_hud.gd:2346`); player one's goes through with no note; neither is the pause X-07 asks for.
- A-CONTROLS-07: the Steam Deck's built-in controls have never been tried: no run on a Deck or through Steam's pad layer is on record. Evidence: `docs/tools/steam-deck.md:16-17`, `:25`; `render/core/main.gd:1067-1077`; `docs/perf/desktop-boot-2026-10-27.md:62`.

You own: `sim/input/`, `docs/controls/`.
- ask under NEEDS FROM EP for a grant: `render/core/main.gd` (lines 1495-1499, where the unplug is acted on) or have Rendering make that change through the EP
- ask under NEEDS FROM EP for a grant: `ui/` (the notice) or have UI build it through the EP; the brief to UI asks for it
- ask under NEEDS FROM EP for a grant: `docs/tools/steam-deck.md` (to replace "untested" with what the friends found; `docs/tools/` has no owner)

Acceptance criteria:
1. (A-CONTROLS-03, exit line X-07, must pass) In every local mode, unplugging a pad that a person is playing on pauses the match and shows one plain notice naming which player's pad dropped and what to press; plugging it back, or pressing on another pad or the keyboard, resumes for that player. A pad nobody is playing on (the join test's third-pad row) does not pause anything. Check: an input test in `sim/input/` covering player one, player two and the idle third pad; a manual check on Orb's PC with two pads; outputs under `docs/controls/runs/<sha>/`.
2. (A-CONTROLS-03) The pause is a pause of the match loop, not a change to what the sim computes: a replay of a match with an unplug in it verifies. Check: the replay verify on that test's match.
3. (A-CONTROLS-03) The notice changes what a player sees, so it ships with a side-by-side against the reference build recorded in `docs/ep/taste.md` (the look gate, ADR 0010; `node tools/flash/side-by-side.mjs`) before it is committed. It appears and goes without a fade.
4. (A-CONTROLS-07, first reading) The friends' sheet asks, in plain words: did the Deck's sticks, triggers and buttons work in the menu and in a match without changing anything; did the game show pad prompts; did anything need the touch screen or a keyboard. Both answers are saved under `docs/controls/runs/<sha>/deck/` and `docs/tools/steam-deck.md` states what was found. A "no" on either Deck is reported to the EP the same day as a finding that stops a newcomer step.
5. (A-CONTROLS-07) A short page in `docs/controls/` says how a game added to a Deck by hand (not from Steam's own store) is expected to receive its controls, and what the tester guide should tell a friend to set if it does not; each claim names where it was read or is marked "not evidenced".
6. (supports) A-CONTROLS-08: give Performance the scripted pad presses (stick flick and face button) its latency bench needs. A-UI-10: confirm the remap file (`sim/input/remap.gd:13`) is covered by UI's real-restart test, and add the failed-write line there if UI asks through the EP.

Constraints:
- Tokens: about 0.5M as an estimate (two S rows at the size classes); the Deck answer waits on people, not tokens.
- State hash: no change. The pause sits outside the sim; if the fix cannot be made without touching hashed state, stop and report: it would wait for GW2 (A3's window, "The fight's rules"), because A2 has no golden window.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; browser captures only through Tools' launcher.
- Determinism: input to intent stays deterministic and replayable; seeded RNG and fixed step untouched; any new number (a grace time before the pause) lives in data, with its schema updated in the same commit.
- Originality: no prompt art or wording copied from another game.
- Orb's rules: nothing drawn on, over or between the fighters (the notice sits clear of them); no dissolves or fades; plain words (say what to press and what you will see), seen by Orb before use; the right stick stays the attacking hand and the left stick moves and defends.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: criterion 1 waits on Orb's answer to "pause with a notice?" (recommended yes; the team takes yes if no answer comes) and on A1's input rows (A-CONTROLS-02, A-CONTROLS-04, A-CONTROLS-06) being on main. Criterion 4 waits on the two friends' session (A-PERF-01), which waits on Legal's gates. Waiting on this brief: X-07 in the A2 exit, and the tester guide's controls section.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- X-07 must pass in full here: run and sign the existing two-pad checklist (`docs/controls/local-two-player.md`, updated for the pause) inside A2's manual check. (MIS-10)
