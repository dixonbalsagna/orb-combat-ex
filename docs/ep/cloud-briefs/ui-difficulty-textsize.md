# Cloud brief: UI/UX, the AI difficulty choice and a text-size option

**Who you are.** You are the UI/UX Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/ui-ux.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/ui-ux/*`, never main; report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read:
- your settings-access report and its NEXT (`docs/ui/cloud-reports/2026-10-28-settings-access.md`);
- Accessibility's audit `docs/accessibility/audit-2026-10-28.md`, the difficulty and text items;
- ADR 0011: PC first, so don't add phone-specific layout work;
- `data/director/ai.json` `levels`.

**Branch:** `cloud/ui-ux/difficulty-textsize` from origin/main.

**Build:**
1. **The AI difficulty choice.** Build it as your NEXT proposed: one choice row on the start menu, Easy, Medium and Hard, default Medium. It's saved with the menu choices and shown only when the AI plays a side. The level reaches the AI as part of the match setup, like the seed, so replays and determinism stay whole.
   - Find where the setup is read. If the sim already takes a level in the setup, use it.
   - If a sim or director line must change, write it under this brief's grant and list it under CHANGES as Encounter's: the setup field only, no tuning.
   - Medium must give byte-identical matches to today's default.
2. **Text size.** A Settings option, Normal, Large and Larger, that scales the HUD's and the menus' text. Layouts must still fit: no text cut and no "..." at the PC sizes hud_check tests (1280x720, 1920x1080, 4K, and the Steam Deck's 1280x800).

**Rules.**
- UI never writes the sim: the level enters only through the setup.
- Strings go in `ui/data/`, in American English, the game's text rule.
- The ui-strings check passes.

**Acceptance criteria:**
- the golden is byte-identical; determinism passes plain and with `--intro`, at each difficulty;
- `hud_check` and the standard gate set pass, each one's last line in the report;
- a check that the start menu's choice reaches the AI's level, and that the setting round-trips through save and load;
- text size: no cut text at the PC sizes, at each step.

**Look evidence.** You can't take browser captures here, so list exactly which screens changed. The EP takes side-by-sides locally.

**Report** as `docs/ui/cloud-reports/2026-10-28-difficulty-textsize.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.
