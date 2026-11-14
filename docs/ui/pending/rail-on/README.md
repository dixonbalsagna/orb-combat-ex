# rail-on: the three older hud_check rules made Rail-aware (UI & UX, 2026-11-09)

Patch against the working-tree `ui/tools/hud_check.gd` (the one with `_menus_rail_rules`): `rail-rules.patch` (apply with `git apply`; checked with `git -c core.autocrlf=false apply --check`).

- `_foot_text(hud)`: the pause card's foot words, the old card's `join_lines`, or on the Rail the chip plus the detail card's lines (`facts_lines`: facts, a save's status, where saved reports go). Used by the "where saved reports go" rule (both checks) and the "save this match" status check.
- The "damage facts" rule compares the drawn words upper-cased, so the old card's MATCH OVER and the Rail's "Match over" both pass.
- Results (scratch copy, one run at a time): `gate-pinned-on.txt` (menus_rail pinned on) **8288 checks, 0 failed**; `gate-switch-off.txt` (as shipped) **8288 checks, 0 failed**, unchanged from before.
- Changes only a test file. To turn the Rail on for the build is one line in `ui/data/features.json` (`menus_rail`: true).
