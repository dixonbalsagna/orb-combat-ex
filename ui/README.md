# ui/: the HUD

Owner: UI and UX. The spec is `docs/ui/hud-spec.md`. There are no health bars: damage is read on the aura crown, the silhouette and the wound cards. Everything here reads sim state and events and never writes them, draws no random numbers, and animates by wall time only.

## Run the demo

Import once so the `class_name` scripts register, then open the demo scene:

```
godot --headless --path . --import
godot --path . res://ui/demo/hud_demo.tscn
```

The demo draws the real HUD over a greybox backdrop, driven by `ui/mock/ui_mock_feed.gd`, a scripted feed shaped like spec-wounds.md §4's events. Keys: Tab scenario, Space pause, R restart, S silhouette (off by default), F4 feed, C captions, M reduced motion, K keep the crown up, B brink ring, D simulated split screen, X flip sides, T arc thickness, Z clear zones, L region label, V viewport size, +/- fighter size, H legend. The crown is transient: it pops on a hit, a stage change, the brink, a Rally or a tier-up and fades back; at rest the fighters are clean.

Options after `--`: `--scenario=hero_vs_proud|empress_vs_cyborg|placeholders|stress|controls`, `--at=SECONDS` (fast-forward the feed), `--frames=N --shot=file.png` (save a frame), `--portrait`, `--clear`, `--nofeed`, `--sil`, `--crown`, `--reduced`, `--nolegend`, `--prompts`. Add Godot's `--fixed-fps 60 --resolution 1920x1080` for a known frame.

## Check

```
godot --headless --path . --script res://ui/tools/hud_check.gd
```

Exits 0 when the terms, the layout at ten sizes, the hub's rules, the mock scenarios against the readability caps, a draw of every scenario, and the bridge against the live sim all pass. If the sim does not compile (another director's working tree), the bridge check prints SKIP.

## Layout of the folder

| Path | What |
| :--- | :--- |
| `hud/ui_hud.tscn`, `ui_hud.gd` | The root `Control` a main scene hosts. `setup`, `consume_all`, `advance`, `anchor_fn`, `strip_fn`, `opts` |
| `core/ui_event_hub.gd` | Folds events and state patches into models, cards, barks, banner and feed; enforces the caps |
| `core/ui_fighter_model.gd` | One fighter's view model (stages, meters, windows, hidden) |
| `core/ui_layout.gd` | Every rectangle, for landscape and portrait, and the fighter-clear zone |
| `core/ui_look.gd` | Colour roles, sizes, timings, caps (provisional until Art) |
| `core/ui_data.gd` | Loads `data/terms.json` and `data/readout_profiles.json` |
| `core/ui_text.gd`, `ui_icons.gd`, `ui_body.gd`, `ui_bark_timing.gd` | Text with the arrow fix; vector icons; the body figure; bark reveal timing |
| `core/ui_sim_bridge.gd` | Reads the live greybox sim into the HUD (read only) |
| `widgets/` | Crown, silhouette, plate, cards, barks, centre (toll, banner), strip, feed, `ui_split.gd` (the split-screen divider geometry, ring map and pointer chips), `ui_glyphs.gd` (the neutral prompt glyphs), `ui_prompts.gd` (the prompt row) and `ui_struggle.gd` (the finisher beat rings) and `ui_howto.gd` (the How to play card) `ui_reads.gd` (the weight mark, the finisher telegraph, the tutorial hint line) `ui_feedback.gd` (the feedback panel, its report and the GitHub issue link) and `ui_hints.gd` (the control legend and the YOU label) and `ui_touch_controls.gd` (the touch Simple buttons) and `ui_settings.gd` (the Settings screen): static draw functions |
| `data/` | Player-facing terms (Narrative's glossary), per-fighter readout profiles, and the player options with their defaults (`options.json`: `info_flashes`, `crown_always`, `silhouette`, ...), feature flags (`features.json`: `hiding`, off), the prompt glyph tables (`glyphs.json`) and the How to play card's words (`howto.json`), the telegraph counters and tutorial hint lines (`reads.json`), and the feedback panel's words (`feedback.json`), its Send step (`send.json`) and the control hints' schemes (`hints.json`) and the Settings screen's sections and words (`settings.json`) |
| `mock/`, `demo/`, `tools/` | The mock feed, the demo scene, the checks |

## What a host does

See `docs/ui/hud-spec.md` section 14. In short: instance `ui/hud/ui_hud.tscn`, call `setup`, give it `anchor_fn` and `strip_fn`, call `UiSimBridge.patch` and `consume_all` each tick, `advance(delta)` each frame. Changing `render/` to do it is Rendering's, routed by the EP.

## Rules

- Transient by default: nothing sits over the fighters at rest except the brink ring (option `brink_cue`). Options: `silhouette` (off), `crown_always` (off), `numeral` in a profile (off).
- Original HUD only: no scanner, no numeric power readout, no hair-colour cue, no borrowed font or logo. "ki" is an internal label; the player sees Charge.
- No cue is colour-only. Every colour role is paired with a shape, pattern, icon or motion.
- Every player-facing word is data in `data/terms.json`.
- The Empress's paperwork is never shown (Orb): no stamp cards, no forms, no REJECTED or REGISTERED text.

## Performance

The HUD is a stack of cached layers (`hud/ui_layer.gd`): a layer redraws only when its small signature changes, so at rest nothing is redrawn. To measure it in the live build (a window opens; alternates the UI HUD shown and hidden and prints the cost in wall time, render CPU and GPU, and draw calls):

```
godot --path . --fixed-fps 60 --resolution 1280x720 --script res://ui/tools/hud_bench.gd -- --seed=4 --blocks=6 --block=300
```

Add `--force` to redraw every layer every frame (the cost without caching), or `--rawpolys` to draw polygons unguarded. Results are in `docs/ui/hud-spec.md` section 14.

## Automated playtest

`godot --headless --path . --script res://ui/tools/hud_playtest.gd -- --matches=12 --seed=1` runs whole live AI matches, feeds the HUD model the real events, and reports crown time, brink time, card latency for every break, cap violations and a midpoint "who is closer to losing" proxy for spec tests 8 and 9. Tests 10 and 11 need human eyes.

## Responsive and touch, and the How to play card

- `UiHud.set_density(dp)` (else detected), option `touch_ui`, `touch_rects()` and `touch_target_at(pos)`: see `docs/ui/hud-spec.md` section 16. Text is at least 12 dp on a dense screen, touch targets at least 48 dp. Demo: `--dp=2.6 --touch` with `--resolution 2400x1080`.
- `show_settings()`, `hide_settings()`, `is_settings_open()`, `is_overlay_open()`, `settings_action(act)`, `load_saved_options()`, signals `settings_opened`, `settings_closed`, `settings_action_requested(action)`; every change fires `option_changed`. The host freezes the sim while it is open and leaves pad and keys to the HUD. Section 26. Demo: `--settings[=N]` (N steps of focus down), `--pad`, `--sscroll=PX`.
- Face cut-in (section 29): `UiFaces` (the rules and the portrait), `UiLayout.face[slot]` (the docked square, empty when embedded), `ui/data/faces.json` (rate, kinds, expressions, texture slots for Art). A bark carries `kind`, `fighter`, `face` and `face_expr`; `hub.stats` counts `faces_shown`, `faces_capped` and `banners_move_name`.
- Camera's panel strip (section 29): option `camera_panels`; `lane_colors()` and signal `lane_colors_changed(a, b)` (the borders, for `SplitView.set_panel_colors`); `panel_floor_y()` (where the top band may start).
- The launcher's steady ready or resting mark (plate, legend, Full touch) and the damage event's medium kind and brawl modes (section 52).
- The gate cannot be skipped by a link and fits short phone screens (section 53): whole parameter names, local hosts only; the text scrolls inside the card when it must.
- The flashing gate (section 51): the first thing in a session, opaque, Legal's text, no timeout and only its own two buttons dismiss it; the match is held and nothing of it is shown until "I understand, start".
- Three strengths and Reduce flashing, built behind `three_strengths` and `reduce_flashing` (section 50): the legend, Full touch, Simple's ring, How to play and Remap words, the wind-up ring and the launch window from Encounter's cues, the charge settings, the Reduce flashing row, and the divider's slam flash under `flash_fn`.
- The flashing-effects notice (section 49): `UiNotice`, shown once per session from `setup()` before the demo plays (the fight held through the How to play card's overlay signals), again from a Settings row; what Reduced motion does and does not cover, and a planned separate "Reduce flashing" setting.
- Three strengths on three buttons (section 48): planned behind a `three_strengths` feature flag (legend, touch, Remap and How to play words, the plate's third weight value, the wind-up and charge ring, Simple's two-band hold ring, two settings); nothing built.
- Press marks and greyed cells (section 47): the brawl's `press_ack` kinds (refused, energy, held, lapsed, empty) mark the pressed button's glyph; the Specials row and buttons with no move yet are greyed "not yet" from `stances.json` `_works`; the rumble setting is planned.
- Ahead of the fighter rename (section 46): `fighter_names.json` rows are `{name, title, sigName}`; `UiData.display_title`, `display_sig` and the `<ID>.SIG` key in `display_text`; the bridge reads `f.id`; the stand-in Protagonist keeps its own readout alias (`STAND_IN_PROFILES`).
- First run and the licences wrap (section 45): the first-run card shows the four gameplay pages and a line pointing to Pause, then About; the licences text wraps with a per-word width cache (59 ms, about half a second at 4x CPU throttle).
- Privacy line by feedback target, the Godot and Open Sans notices and the scrolling third-party licences page (section 44): `UiHowto.about_shown` / `privacy_kind`, `UiLicences` (the engine's own licence texts), `UiHud.howto_scroll`.
- About (section 43): two text-only pages of How to play (Legal's statement, the licence line, privacy, credits; the Suno and voice sentences behind `features.json` flags `about_music` and `about_voice`, off), and an About entry in the pause menu that opens them.
- Display names and the computer opponent's word (section 42): `ui/data/fighter_names.json` (roster id to the name drawn), `UiData.display_name` / `display_text`, CPU on the plate and "computer" elsewhere; the About page is planned.
- The plate's first row (section 41): `UiPlate.row1_plan` decides what shows; the stance badge is never dropped, and a long name gives way by the order the spec lists (word, brink mark, tag pill, name letters, tag last).
- Full touch under the plates (section 40): `UiLayout.touch_top_limit` / `UiHud.touch_top_limit()` passed to `SimTouch.layout` (the host passes the same for its hit test); the pointer chip slides clear of every touch button.
- Armed stance and touch labels (section 39): `UiFighterModel.stance_armed` (patch key `stance_armed`), the badge's NEXT BLOW and ring, Full touch's stance words by `_live` and the armed and latched rings from `touch_state_fn()["full"][id]` (`armed` 0..1, `latched`), the crown's five-stance mark; `UiSimBridge.patch(hud, S, hub)` (or `patch_input(hud, hub)`) patches `stance_armed` from Controls' `armed_stance`/`armed_share`.
- How to play's stances page (section 38): a fourth page with the 5 by 4 table (or one stance at a time with tabs on a narrow screen; Up and Down or a tap choose), the live and not-live columns by `stances.json` `_live`; the controls page and the Remap rows name a stance's button for its stance once the stance is live (`_howto`, `_remap`, `_remap_help`).
- Key help for five stances (section 37): the prompt row's five stance chips with the layout's own glyphs and four fit tiers (`UiPrompts.fit_tier`), the legend read by stance for the stances that are live (`UiHints.rows`, `legend_alpha`, `UiStance.live`, `stances.json` `_live`), the telegraph's answers from `stances.json` `_counters`.
- Stance badge and beat ring (section 36): `UiStance` (the five stances from the held-button mask, words in `ui/data/stances.json`), `UiIcons.stance5`, the plate's badge on both fighters; `UiFighterModel.stance_mask`/`stance_kind`/`beats`; `UiBeatRing` and the option `beat_ring` (off by default; `UiSimBridge.beat_windows` reads the exchange's pending blows).
- Incoming marker (section 34): `UiIncoming` draws Camera's `split_record()["incoming"][pane]` as an edge chip in the pane (countdown from `eta`, RUSH or CLOSING, the distance in fighter heights; aimed is a solid ring chip, an estimate a dashed chevron chip with a "~"); `UiSplit.pointers` returns it with kind "incoming" in place of the ordinary pointer; nothing in a single view. The demo scene reads its options from the query string on the web.
- Energy hold or toggle (section 33): options `energy_style`, `energy_style_p2`, `show_recipe`; the legend says Energy (hold) or (toggle) per player (`UiHints.rows(m, scheme, energy)`); `UiFighterModel.energy` (the bridge patches `act.mode == 1`) switches the plate's weight chip to BLAST or BIG BLAST with a small mark; Show recipe is a stub: `UiHud.recipe_fn(slot)`, `UiFighterModel.recipe`, `UiRecipe.text`, `UiSimBridge.recipe`.
- Intro and last stand (section 32): the fight's HUD is hidden from `intro_start` to `clock_start` and fades in (`hub.intro_active`, `intro_kind`; menus stay), `intro_skip_text()` is the skip hint's words for the first human; `last_stand_ready` and `last_stand_end` drive `UiFighterModel.last_stand_left` (the bridge patches the sim's `lastStandLeft`), a card and the plate's signature chip counting down.
- Form-ready prompt (section 31): `UiFormPrompt` (a chip in `UiLayout.form[slot]` with the player's own Transform control, a pulse by scale and alpha, a steady highlight under reduced motion), signal `form_prompt_shown(slot, device)` for the host's haptic, `UiFighterModel.form_free` (the bridge sets it; true if nobody does), `form_shown`, `form_loud` and the reserved `form_cue_left`. The legend and the prompt row give way while it shows; the lit touch button pulses.
- Local two-player (section 30): `set_join_available(available, keyboard_only)`, `show_join_note("joined"|"left")`, `set_slot_layout(slot, layout_id)`, `set_device(slot, family)`, signal `player_two_leave_requested`, options `join_prompt` and `pad_preset_p2`. The join prompt is `UiJoin` in the AI's prompt row; the pause menu has the hand-back entry.
- `toggle_pause_menu()`, `show_pause_menu()`, `is_pause_menu_open()`, `pause_menu_action(act)`, `pause_menu_choose(id)`, signals `pause_menu_opened`, `pause_menu_closed(reason)`, `pause_entry(entry)`, `new_match_requested`. The host's pause key, button and Start call `toggle_pause_menu`. Section 28. Demo: `--pause[=N] [--pconfirm]`. Sim pauses (`pause_start` .. `pause_end`) hold the fight-time timers (`UiEventHub.sim_paused`).
- `show_remap(layout_id)`, `hide_remap()`, `is_remap_open()`, `remap_action(act)`, signals `remap_slot_changed(layout_id, overrides, slot)` (use this one) and the older `remap_changed(layout_id, overrides)`, `pad_slot_fn` (Callable device id to player slot, set to `hub.slot_pad` so the screen opens on the player who pressed), `show_remap(layout_id, player)`; opened from the Settings Remap row. `UiRemapModel` asks Controls' SimInputRemap and SimInputData (docs/controls/remap.md); the host calls `SimInputHub.reload_layouts()` on `remap_slot_changed`; each player has their own copy of a layout and a Player 1 / Player 2 row appears while two people play. Section 27. Demo: `--remap[=LAYOUT] [--rcapture=ACTION] [--rtry=kb:KeyK] [--rfocus=ACTION]`. Full touch: `--touch --full`.
- `show_howto(first_run, page)`, `hide_howto()`, `is_howto_open()`, `howto_seen()`, signals `howto_opened` and `howto_closed`; F1 toggles it. The host freezes the sim while it is open. Section 17. Demo: `--howto=0|1|2`, `--device=xbox`, `--preset=arena|simple-pad|kb-solo|kb-shared-p2` (the layout the legend and the card describe), `--ready` (a form is ready), `--stance=N`, `--target=github|mailto|form` (a send target for the feedback shots).

## Q4 reads (docs/ui/hud-spec.md sections 18 and 19)

The director times every blow; the player reads and answers. The plate shows the weight and the signature intent; a chip names the finisher's kind while it winds up; the struggle's pulses reveal a result; tutorial hints come from `ui/data/reads.json` through `tutorial_hint` events; barks have caption, thought and shout styles. Demo: `--scenario=controls --prompts` (the full Q4 loop), `--at=SECONDS` to jump.
