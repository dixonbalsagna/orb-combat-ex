# Cloud brief: UI/UX, volume controls, the uncut Settings help and the pseudo-locale switch

**Who you are.** You are the UI/UX Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/ui-ux.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/ui-ux/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read Accessibility's audit `docs/accessibility/cloud-reports/2026-10-28-foundation.md` (NEEDS 1, 3 and 6) and `ui/widgets/ui_settings.gd`.

**Branch:** `cloud/ui-ux/settings-access` from origin/main.

**Build:**
1. **The pseudo-locale switch** in `ui/core/ui_data.gd`, exactly as NEEDS 1 of the audit gives it. It stays off unless the game is started with `-- --pseudo-locale`.
2. **Volume controls** in Settings: master, effects, voice and a mono switch (music later).
   - They set Godot's audio buses and are saved with the other settings. Read the bus names in `audio/` ("Sfx", "Voice" and so on) rather than guessing them.
   - Audio grant for this brief: if a bus-volume hook is missing in `audio/`, you may add one. List those lines under CHANGES.
3. **Settings help that is never cut.** At 1920x1080 the colour-blind help ends in "..." (the foot's two lines). Let the foot grow or scroll.

**Rules:**
- UI never writes the sim: a settings change must not touch a hashed field.
- Strings go in `ui/data/`, and the ui-strings check must pass.
- Use British spelling, as the rest of the project does.

**Acceptance criteria:**
- the default build looks the same everywhere except the Settings screen;
- determinism passes, plain and `--intro`;
- `hud_check` and the standard gate set in cloud-workflow.md pass, each with its last line in the report;
- a settings round trip: set each volume, save, reload, and read back the same values and the same bus dB;
- the pseudo build reads the pseudo files, and the default build doesn't.

**Look evidence.** You can't take browser captures here. List exactly which screens changed, so the EP can take the side-by-side locally before landing.

**Report** as `docs/ui/cloud-reports/2026-10-28-settings-access.md` with these sections: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. The start-menu difficulty choice (NEEDS 4) goes under NEXT: propose it, don't build it. Push and end your turn.
