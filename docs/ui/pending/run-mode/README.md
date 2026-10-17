# The run mode's screens as widgets (parked, UI, 2026-10-17)

`docs/ui/run-mode-screens.md`, built in scratch behind `features.json` `run_mode` (**off**). Static draws from records the host passes; the HUD never writes the sim. **Not applied.** Apply after `launch-anywhere`:

```bash
patch -p1 --dry-run < docs/ui/pending/run-mode/run-mode.patch
patch -p1 < docs/ui/pending/run-mode/run-mode.patch
```

## What is in it
- **`ui/widgets/ui_run.gd`** (`UiRun`, with `.uid`): the offers ("Where to next?": three cards on World's strip, each with its biome blocks, its place marks by shape (untouched solid, damaged half-filled with a crack, fallen hollow with a slash) and the start mark; compact cards for a phone on its side, rows upright; the boss as one card under "The last fight"), the beat panel (the places row with this fight's changes ringed, the count in plain type, the beat's lines under their speakers, the final approach's eight pips) and the results (route, the planet as results, the score in its parts, the three buttons; two pages on a phone on its side; the score's parts open on a tap upright). Pure `*_plan`, `*_hit`, `*_sig` and `*_draw` functions; every control a 48 dp target; Legal c08 held (a count is a plain line like its neighbours; no score part for deaths; no menace or Dread).
- **`ui/hud/ui_hud.gd`:** `show_run_offers(rec)`, `show_run_beat(rec)`, `show_run_results(rec)`, `hide_run()`, `is_run_open()`, `run_action(act)`; signals `run_offer_chosen(index)`, `run_beat_next()`, `run_beat_skipped()`, `run_results_action(action)`. The screens hold the match through the same `howto_opened` and `howto_closed` the cards use. Keyboard (arrows or WASD, Enter or Space, any other key skips a beat), pad (d-pad, A, any other button skips) and touch (a tap selects, a second tap or the button confirms).
- **`ui/data/terms.json`:** 57 plain strings, `prompt.run_*` (Narrative's to own). **`features.json`:** `run_mode`.
- **`ui/tools/hud_check.gd`:** `_run_mode_rules` (17 checks): the three screens fit at ten sizes, the modes by shape, hit tests, two offers recentred, the boss card, two results pages, the score's parts, the c08 rows, the HUD flow and signals, each heading drawn.

## The records (shapes in the header of `ui_run.gd`; every key optional)
`offers {fight, of, planet.cities, boss, offers[{kind, name, line, opp, harder, tiers, holds, reward, strip}]}`, `beat {approach, place, step, of_steps, states[12], changed[], changed_text, lost, present, beat_n, beat_of, lines[{who, text}]}`, `results {won, ending, route[], chances, ticks, path, planet{states, cities, towns, lost, present, sky_dark}, score[], total}`. `reward` is one of `rampage`, `proving_cards`, `proving_score`, `crossing`.

## Gates (scratch of HEAD + this patch, switch off): `hud_check` 4,736 checks, 0 failed; `determinism` plain and `--intro`, `hud_words_check`, `pane_check` passed.
## Not done: no picture was taken (the quiet window); the mocks stay local in `homework/mocks/ui/`. The host calls (run state, the offers' stream) are Game Design's, Simulation's and the host's.
