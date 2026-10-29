# Live barks: report (Narrative & Fighter Identity, 2026-10-28)

Brief: `docs/ep/cloud-briefs/narrative-live-barks.md`, run locally by the EP's message of 2026-10-28. Work in my own paths; the three outside lines and one new class are parked for the EP's grant.

## SUMMARY

Fighters now speak in a match, behind a data switch that is **off** (`data/narrative/live_barks.json`, `"enabled": false`). The emitter is a presentation-layer class that reads the sim's fx events and returns HUD `bark` events. It never writes the sim and draws from its own hash stream (match seed, tick, the event's place in the tick), so the golden and determinism cannot move. Every line is an approved line (Orb's own homework 1 words, or Orb's marks on homework 11), 33 in all, each with a `source`. Switched on, three seeded 120-second matches gave 28 barks (10, 9, 9): 7 kinds, at least 3.7 s apart, one fighter at least 8.0 s apart, no line repeated. Tested in a clean HEAD scratch copy with the patch applied: all gates below pass. The line lint is clean under the EP's ruling (Orb's own words exempt from R1 and R8, keyed on `source`).

## CHANGES

In my paths:
- `data/narrative/live_barks.json` (new): switch, limits, display, 8 beats with 33 lines (cues, priority, source, lint result per line), `excluded_lines` (6, with why), `unmapped` (8 beats with no approved line), provenance.
- `docs/narrative/pending/live-barks/`: `narrative_barks.gd` (target `ui/core/narrative_barks.gd`), `main_gd.patch` (`git apply --check` passes on the live tree), `bark_check.gd` (target `render/tools/bark_check.gd`), `README.md` (exact lines, how to turn on).
- This report.

Outside my paths, parked for the EP's grant (nothing applied):
1. `ui/core/narrative_barks.gd`: new file, no existing line touched.
2. `render/core/main.gd` (three lines): `var barks: NarrativeBarks = null` after `var ui_hud`; `barks = NarrativeBarks.make(host.S, host.setup_used)` in `_mb_begin()` after `ui_hud.setup(...)`; `if barks != null: ui_hud.consume_all(barks.step(host.S, events))` in `_on_drained` after `ui_hud.consume_all(events)`.
3. `render/tools/bark_check.gd`: new tool; add to the gate list.
No sim/director line and no `ui/` widget line changed. Nothing is listed as Encounter's.

## EVIDENCE (scratch HEAD copy + the parked files; Godot 4.7.2 headless, below-normal; last line of each)

- Switch off: `NarrativeBarks.make` returns null with the shipped file; the gameplay hash with the emitter stepping equals the hash without, for 3 seeds (`bark_check`). `determinism`: "determinism passed". `determinism --intro`: "determinism passed". `parity`: "golden check passed". (determinism.gd does not load main.gd; the on/off hash comparison in bark_check is the proof for the switch-on case.)
- Switch on (`bark_check`, seeds 12345, 777, 31337, 7200 ticks): 10, 9, 9 barks. By beat: launch_given 9, guard_caught 5, heavy_taken 4, first_blow 3, heavy_landed 3, flurry_taken 3, missed 1. Spacing: any two at least 3.7 s (min 3.7, 4.5, 5.5), one fighter's at least 8.0 s (8.2, 8.8, 8.0). Same lines at the same ticks on a second run. No line twice inside 180 s; at most 4 a fighter a minute. Every line word for word from the file. Each bark through a real `UiEventHub`: all shown, none cut. Last line: `BARK CHECK: PASS (0 failed)`.
- Synthetic cases (52): every beat makes each of the four fighters say one of his own lines as himself, so the Empress's and Cyborg's lines are proved though the sim has only PROTAGONIST, RIVAL and REFERENCE; REFERENCE (no lines) stays silent; nothing after the KO.
- `hud_check`: "hud_check: 5828 checks, 0 failed". `main.gd` with the patch: `--check-only` exit 0.
- Render gates (16): after, cue --profile=spaced, depth, flash, flash_reg, flight, ground, hud_words, lane, open, pane, patch, shape, sky, stage, city: each exit 0, last lines "... check passed" (city_check's last line is its switches line, exit 0). `load_split`: "ok: the director is a load of its own...". outline_check and cull_check need a window and were not run. Net, rollback, QA and the golden-hash node tools were not run (nothing in sim or net changed).
- Line lint, updated after the EP's ruling (Orb's own words win): `python docs/narrative/line-lint.py --live data/narrative/live_barks.json` gives "33 lines, 10 exempt as Orb's own words, 0 failing". The exemption is keyed on each line's `source` (line-lint.json `orb_own_exemption.sources`: `orb_own_words_hw1`, `orb`), exempts R1 and R8 only (a line, and the batch rate, which then counts non-exempt lines only), and leaves every other rule strict. Negative controls: a 3-word line with a non-Orb source fails R1; an Orb-own line with a banned word still fails R3. Markdown batches carry no source and stay strict. The 4 hw11 lines Orb kept (Claude's) and the 26 Gemini rewrites are Orb's marks, not Orb's own words, so they are not exempt (all pass anyway). 5 ellipsis CHECK items remain for a human (3 of them exempt lines). Before the ruling the batch had 3 R1 fails and 1 R8 fail, all on Orb's own lines.

## DECISIONS

1. Emitter lives in the presentation layer, not in sim/director. That makes the golden byte-identical by construction.
2. "Approved" means Orb-marked: hw1 own words and hw11 marks. The `combat_barks.json` drafts are not used (unmarked; the Cyborg, Empress and Rival taunts are retired-voice).
3. Timing from each event's own tick, so a frame that drains several ticks says the same lines.
4. One bark per event; when hitter and hit both could speak, the hash picks. Silence after the KO.
5. Limits (data, tunable): fighter gap 8 s, 4 a minute, global gap 3 s, beat hold-off 12 s, line cooldown 180 s, caption 1.6 to 2.6 s, priority 2 (missed: 1).

## NEEDS FROM EP

1. Grants: the three outside items above (new `ui/core/narrative_barks.gd`, the `main.gd` patch, new `render/tools/bark_check.gd` plus its place in the gate list). Then switch on locally for the side-by-side.
2. (Done 2026-10-28 on the EP's ruling) The lint exempts Orb's own words from R1 and R8 by `source`; see EVIDENCE. Changed: `docs/narrative/line-lint.py` (new `--live` mode, exemption in `check`), `docs/narrative/line-lint.json` (`orb_own_exemption`). No line changed.
3. Beats with no approved line (not written, per the brief): taunt_start (drafts exist, retired voice); signature shouts (move names still placeholders); last_stand_ready; absorb_signature (Rival's bravado is Legal-cleared, not Orb-approved); finisher_landed and finisher_survived; win/loss at the KO (hw15); first blow for the Empress and Cyborg; Empress miss. Also held: hw11 #19 (Orb's burn/flatten swap), #23 (chimney only, no such event), #06/#14/#22 (through a wall: needs a building-hit event read), #10 (glasses event).
4. The Empress and Cyborg are not in the sim yet (only PROTAGONIST, RIVAL, REFERENCE), so their lines cannot be seen live until they join.

## RISKS

- Look change: by UI's `UiFaces` rules an ordinary line may also bring a face cut-in (rate-capped per minute). Barks add text to the bark lane; run the flash clips in both modes before landing.
- Bark rate: 9 to 10 in 120 s is deliberately sparse; Orb may want more or fewer (data only).
- Accessibility audit item 7 is addressed only when the switch is on; Captions-on tags come from the cues' gestures (grunt, wince, scoff...), not new text.
- A line like "You're really strong!" said by the Protagonist after a heavy blow reads fine; whether the lines fit each moment is Orb's ear, not tested by a machine.

## LOOK EVIDENCE (for the EP's side-by-side; captures only through tools/machine/capture.mjs)

Default pair PROTAGONIST v RIVAL, AI vs AI, switch on, in the match HUD's bark lane under each fighter (the existing lane, plain and with Captions on):
- seed 12345: 1.3 s Protagonist first blow ("First hit's mine! Show me what you've got!"); 9.4 s Protagonist launches ("Don't tell me that's enough to keep you down!"); 35.2 s Rival in a flurry; 89.3 s Rival launches.
- seed 777: 1.2 s Rival first blow; 20.4 s Protagonist's miss ("Clean slip!..."); 38.5 s Protagonist launch; 75.2 s Rival flurry.
- seed 31337: 2.0 s Rival first blow; 17.7 s Protagonist perfect block (Orb's line, with an ellipsis); 63.0 s Protagonist heavy.
No other screen changes; the start menu, intro and result screens are untouched.

## NEXT

Frozen until the EP confirms. Then: fold in the lint ruling, write lines for the unmapped beats only when Orb marks them, add Empress/Cyborg live once they are in the roster, and a `building_hit` read for the through-wall lines.
