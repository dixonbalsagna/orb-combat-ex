# Cloud brief: Accessibility & Localization, the foundation

**Who you are.** You are the Accessibility and Localization Director for Orb Combat EX, working as a cloud session. This is your first brief. Read in this order: CLAUDE.md, your charter `docs/directors/accessibility-localization.md`, **`docs/ep/cloud-workflow.md`** (it overrides your charter where they differ: you commit and push, but only to `cloud/accessibility-localization/*` branches, never to main, and you report in the branch), and `docs/ep/vision.md`. Then read the UI's data and docs: `ui/data/*.json` (terms, options, settings, howto, features) and `docs/ui/`.

**Branch:** `cloud/accessibility-localization/foundation`, from origin/main.

**Goal.** An honest picture of where the game stands, and the groundwork for translation. Make no change to what the player sees by default.
1. **An accessibility audit.** Write `docs/accessibility/audit-2026-10-28.md` against a standard game-accessibility checklist: input remapping, holds and toggles, colour-blind modes, text size and contrast, reduced motion, the flashing notice and lock, subtitles and captions for barks and voice, audio cues for visual-only information, and difficulty and assist options. For each item, say what exists today (cite the file and the key), what's missing, its priority, and which director owns the fix. Don't invent features. Read the code and data to find out what's real.
2. **A string inventory.** Write a tool `tools/l10n/strings.mjs` that lists every player-facing string: ui/data, the code's literals that reach the screen (the HUD, the boot line, the notices), and the director's feed and barks if the player sees them. Record each one's key, source file and length. Flag hard-coded strings that bypass ui/data.
3. **A pseudo-locale.** Write `tools/l10n/pseudo.mjs`, which makes a test locale (accented, about 40% longer, bracketed) from the inventory. Add an opt-in switch, off by default, so a build can show it. Report which screens would overflow; checking that statically against the layout data is fine, since there are no captures here.
4. **A plan.** Write `docs/accessibility/l10n-plan.md`: how translation would work for a free, zero-budget open-source game (the file format, community contributions, which font covers which scripts, right-to-left text), and an effort estimate.

**Rules.**
- Legal's cleared words (`docs/legal/page-fixed-lines.md`) must never be altered by any tool.
- Any code outside your paths (the switch's hookup in ui/ or render/) goes under NEEDS FROM EP as exact lines. Don't edit it.
- You own `docs/accessibility/` and `tools/l10n/`.

**Acceptance criteria:**
- both tools run headless with node;
- validate and the self-test pass;
- the golden is unchanged;
- the audit cites real files for every claim.

**Report** as `docs/accessibility/cloud-reports/2026-10-28-foundation.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push the branch and end your turn.
