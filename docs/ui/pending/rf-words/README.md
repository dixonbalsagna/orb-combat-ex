# The Settings help for Reduce flashing, with Legal's wording (parked)

Legal's RL-157 (`docs/legal/rewards-and-lock-screen.md` section 1, item 1): drop "at most one large flash a second, and the small ones off" (a measurable claim our own calm reads go over). The help line is now exactly: "Fewer and gentler flashes. Turning it off restores full effects, which flash more. Reduced motion is a separate setting."

Apply from the repo root, on main with the rf-lock already in: `patch -p1 < docs/ui/pending/rf-words/rf-words.patch` (a dry run is clean). It rides with the interim export. Files: `ui/data/options.json` (the help line) and `ui/tools/hud_check.gd` (one new check in `_rf_lock_rules`: the help is exactly those words and holds no flashes-per-second figure). `docs/ui/strings.md` row 557 is already updated.

Held for Orb's homework 35, not touched: Narrative's two string changes ("Say no to all three and gain a life"; "Lives used").
