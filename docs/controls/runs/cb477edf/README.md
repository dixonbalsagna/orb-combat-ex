# Controls run, 2026-11-07: flight-strike-b, the pad brace button, the refusal knocks (CD-22)

Cut and run on a scratch tree of HEAD **85e838b6** (`git archive` of sim, data, net, render, ui, audio, tools, qa, localization). Nothing under `sim/input/`, `data/input/` or `tools/schemas/input-timing.schema.json` changed between 85e838b6 and cb477edf, so the run holds for cb477edf. The three patches are in `docs/controls/pending/{flight-strike-b,pad-brace,refusal-knocks}/`; each reproduces the tested tree byte for byte from clean HEAD files.

| File | What it is |
| :--- | :--- |
| `input-suite.txt` | every `sim/input/test/*_test.gd` on the tree with all three patches: 38 tests, 0 failed (new: `flight_strike_b_test` 29; `strike_hub_test` 63, `refusal_cue_test` 44, `refusals_test` 89 changed) |
| `lint-validate.txt` | `node tools/lint-determinism.mjs` ok; `node tools/validate.js` 319 files, 0 errors |
| `knock-audit-kb_*.json` | **the final audit**: a scripted pad on the real hub and director with Encounter's `refusal-reasons.diff` applied and `press.refusedCue` true, wired as the host wires it. Cells: stick/easy, stick/medium, chaos/medium (3 matches each, seeds 1 to 3, 100 s wall a match) |
| `knock-audit-ka_*.json` | the same before the `hit` knock was silenced (stick/easy, stick/medium, chaos/easy): **1,215 `hit` knocks in 3 easy matches** |
| `knock_audit.gd.txt` | the probe (a `.gd` for `tools/feel/`; run `godot --headless --path <tree> --script res://tools/feel/knock_audit.gd -- 3 1 --arm=stick\|chaos --level=easy\|medium --wall=100`) |

Read of the audit (final): in every cell `refusalCues` minus the silenced `stick_refused/hit` equals `knocks`, every knock carries a named reason (`unknownReasons` empty: no `other`, `busy`, `replaced` or `stun_limit`), `silentRefusals` is only `stick_refused/hit`, and a knock on the same tick as a landed blow is 2 to 3 of 466 to 811 (stick) and 43 of 2,142 (chaos), each another blow's refusal and none caused by the landing. Not run: the golden/parity and the director checks (nothing here touches the sim; the switches are off or data-only).
