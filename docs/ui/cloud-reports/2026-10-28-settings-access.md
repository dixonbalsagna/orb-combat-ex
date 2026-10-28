# UI/UX, cloud report: volume controls, the uncut Settings help and the pseudo-locale switch (2026-10-28)

Branch `cloud/ui-ux/settings-access`, from origin/main 31ae23e. Brief: `docs/ep/cloud-briefs/ui-settings-access.md`. Look evidence pending (local).

## SUMMARY
Settings has a Sound section (Master, Effects and Voice volume, Mono sound) that trims Godot's buses through a new hook in `audio/audio_voices.gd` and is saved with the other options. The Settings foot keeps its usual height and grows only while a help longer than two lines is focused, so no help ends in "..." at any of the 14 sizes hud_check tests (the colour-blind help shows whole at 1920x1080, three lines) and a help that fits two lines costs the list nothing (re-cut 2026-10-28 after the EP's look check: the first cut reserved the longest help's height and took a quarter of a phone's list in landscape). The pseudo-locale switch is in `UiData._read` exactly as the audit gives it, off unless the game is started with `-- --pseudo-locale`.

## CHANGES
- `ui/core/ui_data.gd`: the switch (`pseudo_locale`, `_locale_path`, and `path = _locale_path(path)` as `_read`'s first line), word for word from the audit's NEEDS 1.
- `ui/data/options.json`: `volume_master`, `volume_effects`, `volume_voice` (0 to 1, step 0.05, default 1.0, shown as 0% to 100%) and `mono_audio` (default false), group accessibility. No schema change.
- `ui/data/settings.json`: a Sound section between Display and Accessibility.
- `ui/hud/ui_hud.gd`: `set_option` passes the three volumes and mono to Audio's hook (`VOLUME_GROUPS`); the foot's help scroll state (`_set_help_scroll`, reset on a new focus) and `_settings_help_by` (the wheel over the foot, or a tap on it, when a help is longer than the foot).
- `ui/widgets/ui_settings.gd`: the foot is the height it always had (the longest help up to two lines) and grows by the lines the focused help (or Remap status) lacks, while the body keeps `HELP_BODY_ROWS` (2.6) rows; past that the help scrolls by whole lines with a thin bar (`help_wrap`, `help_scroll`), never "...". The redraw key carries the help scroll and line count. `ui/hud/ui_hud.gd` brings the focused row back into the body when the foot's line count changes (`_set_foot`, `_rm_foot`), and only then, so a scroll by hand stays.
- `ui/tools/hud_check.gd`: `_settings_access_rules`, 10 checks (no cut help at any size; the 1080p colour-blind help whole; the rows and defaults; the bus round trip; the pseudo switch's paths).
- `ui/tools/pseudo_switch_check.gd` (new): end-to-end, run plain and with `-- --pseudo-locale`.
- `docs/ui/hud-spec.md` section 26: the Sound rows and the foot rule.
- **Audio grant** (`audio/audio_voices.gd`, the only file outside my paths):
  - new `USER_GROUPS` (master: Master; effects: Sfx, SfxMuffled, Alert, Ambience; voice: Voice, VoiceMuffled; Music has no group yet), `MUTE_DB`, static `_user_db`, `_mix_db`, `mono`;
  - new static `user_db(bus)`, `set_user_volume(group, linear)`, `set_mono(on)` (an `AudioEffectStereoEnhance` with `pan_pullout = 0` on Master, added on first use, then enabled or disabled), `_effect_index(bus, cls)`;
  - `setup_buses`: records each bus's mix.json level in `_mix_db`, sets it plus the player's trim, sets Master to its trim, and finds the limiter by class instead of "Master has no effects" (so a mono effect added first cannot stop the limiter);
  - `_process` duck release and `_hold_down`: base + the player's trim (+ the duck), so a duck comes back to the player's level; `_hold_down` takes the base from `_mix_db`.
  At default settings every bus level is what it was (hud_check: the round trip ends on the mix's own levels).

## DECISIONS
- **Spelling of the new strings.** The brief says British, but the ui-strings check (`tools/check-site-interim.mjs`, Legal's RL-192 condition 2 and RL-193) fails any British spelling in ui/data text a player reads: the game's text is American. The new strings use no word that differs ("Master volume", "Effects volume", "Voice volume", "Mono sound"), so both are satisfied; code comments and docs stay British.
- Volumes are a trim on top of Audio's mix (100% = mix.json's level, 0% = -80 dB), linear to dB with Godot's `linear_to_db`, kept in the audio hook so ducking and a later `setup_buses` keep them. The trims are static, so settings loaded before the buses exist apply when the buses are made (the game loads settings before it adds AudioVoices).
- Effects covers Alert and Ambience as well as Sfx: a player who turns effects down to hear voices wants the world quieter too.
- **The foot grows with the focused help, not with the longest.** Either grow it only while a long help is focused, or keep two lines and scroll the rest. I chose growing: the help is read where the player is looking, a scroll hides the rest of a sentence behind a tap, and on a desktop there is room. The cost is that the list is a line shorter while a long help is focused (on a phone in landscape, four rows to three for the colour-blind help); the focused row is re-anchored so it never leaves the screen. A help that fits two lines changes nothing against main. The foot scrolls rather than cuts on a screen smaller than any tested; at every tested size it never needs to.
- The pseudo files (`localization/pseudo/`, Accessibility's) are not regenerated: they are not mine. Until they are, the pseudo build has no Sound rows (its options.json and settings.json lack them), which is harmless.

## NEEDS FROM EP
1. **Accessibility:** run `node tools/l10n/pseudo.mjs --write` for the new options and Sound section (`--check` now says options.json and settings.json are stale).
2. **Audio:** a look at the grant lines above, and a `music` group (one line in `USER_GROUPS`, one option, one item) when music lands.
3. **Look evidence (local):** side-by-sides of the Settings screen only: desktop 1920x1080 (keyboard), pad, phone landscape and portrait, as in hud-spec section 26's pictures, with the focus on Color-blind mode and on Launch camera (the longest help). Changed: while a help longer than two lines is focused the foot is taller by the lines it lacks (one at 1080p; up to 8 lines on a 360x640 phone) and the list shorter by the same; every other focus is main's, and a Sound section. The Remap screen shares the foot: unchanged wherever its help or status fits two lines (every case I measured). Nothing else on screen changes.
4. **Ruling:** the brief's "British spelling" against RL-192/193's American game text; I followed Legal for player text.

## RISKS
- `set_mono` relies on `AudioEffectStereoEnhance` with `pan_pullout = 0` summing to mono; it is measured only as bus state here (no sound device in the container). Worth one listen on Orb's PC.
- The overflow check (`tools/l10n/overflow_check.gd`) reads `plan()` outputs; the foot's line count can now exceed two for a focused long help, which could move its numbers.
- A tool or bench that calls `load_saved_options` would now also change bus levels; the host already skips it for tools, the bench and scripted runs.

## NEXT
- **Start-menu difficulty (audit NEEDS 4), proposed, not built:** one choice row on the start menu under the fighter picks, "AI" with Easy, Medium and Hard from `data/director/ai.json` `levels`, default Medium, saved in the menu config (`UiPrefs` "menu") beside the fighters, shown only when the AI plays a side. The host passes the level to the AI as a match input (it is part of the setup, like the seed, so replays and determinism stay whole). Needs Encounter to confirm the level is a setup field and Game Design to name the default.
- Then the text-size option (NEEDS 6) and the hold toggles (NEEDS 5) with Controls.

## Gates (this tree)
Godot 4.7.2.stable.official.ed1daf0bf installed as CI does (SHA-512 checked). Every gate exited 0:
- `node tools/validate.js`: "278 files checked, 0 errors, 0 warnings"
- `node tools/validate.js --self-test`: "Self-test: 9711 of 9711 checks passed"
- `node tools/lint-determinism.mjs`: "determinism lint ok: no engine trig, PI/TAU, random numbers or clock in sim/core, sim/director, sim/world, sim/input"
- `npm test --prefix sim`: "all 4 stages passed" (unit, parity, soak, golden; "the frozen JS core reproduces its golden record", golden unchanged, no sim file touched)
- `render/tools/determinism.gd`: "determinism passed"; with `-- --intro`: "determinism passed"
- `ui/tools/hud_check.gd`: "hud_check: 5826 checks, 0 failed" (5816 before, plus 10 new)
- `ui/tools/pseudo_switch_check.gd`: "pseudo switch check passed: the default build reads ui/data"; with `-- --pseudo-locale`: "pseudo switch check passed: the pseudo build reads localization/pseudo"
- `render/anim/tools/anim_check.gd`: "anim check passed"
- `render/camera/tests/split_sweep.gd`: "split sweep passed"
- `sim/core/tools/campaign_episode.gd`: "campaign_episode: the two plays are the same to the bit (1800 ticks a stage; 25.0 s and 16.8 s)"
- `sim/core/tools/parity.gd`: "golden check passed"
- all 40 `sim/world/tools/*_check.gd`: exit 0
- ui-strings: `node tools/check-site-interim.mjs --site <empty> --root . --no-pack-scan` prints no ui/data line (only the six missing-page lines of the empty site and the lock flag, the same as on origin/main).
