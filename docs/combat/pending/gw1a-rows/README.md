# gw1a-rows: Combat's two data rows for GW1a (A-COMBAT-14)

Combat, 2026-11-14. Main must play like Orb's 9 November build. With the whole GW1a stack applied, two of Combat's rows still differed from the kept tree (`homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree`): `enabled` in `data/combat/mixed.json` and `data/combat/phrases.json`, on in Orb's build.

**Apply:** `git -c core.autocrlf=false -c core.eol=lf apply docs/combat/pending/gw1a-rows/gw1a-rows.patch`. Two lines, `false` to `true`. It applies to HEAD (26fd27b0) and to HEAD plus the EP's GW1a folder.

## Checked, on a copy of HEAD plus the GW1a folder

| Check | Result |
| :--- | :--- |
| Both files after the patch against the kept tree | **Byte for byte the same,** and all of `data/combat/` now matches the kept tree |
| `phrase_check.gd` (Encounter's), patched | 0 failed. It forces the switch both ways, so the row doesn't pin it |
| `parity.gd` (golden), before and after | Fails, **with identical lines both times:** the GW1a stack's own golden change. The patch adds no new failure |
| Validator | 0 errors, 2 warnings |
| Validator self-test | 1 failure, the same with and without the patch: `ui-modes.schema.json`'s invalid cases (UI's or Tools') |

No check of Combat's pins either row off. My old `mixed_check.gd` and the phrase generator aren't on main.

## What it changes, and what it doesn't

- **phrases.json on changes play,** as it did in Orb's build: a press inside a phrase takes the phrase's next piece. The combat data hash changes too, because the phrase text joins it when on.
- **mixed.json on changes nothing.** No code on main, in the GW1a stack or in Orb's build reads it: `sim/director/mixed.gd` exists in none of them. The mixed string never ran in Orb's build; only its switch was on. Making main *play* the string needs `mixed.gd` and its hooks (`docs/combat/pending/mixed-string/`; the hooks are Encounter's lines).
- **The combat data hash still isn't the kept build's,** for reasons outside Combat's files: `data/director/interrupts.json` and `data/fight/` `brake`, `hitstop`, `kick`, `ladder` and `power` differ from the kept tree after the stack.

## For others

- **Tools:** `tools/preview/switches.mjs` rows `phrases` (line 217) and `mixed` (line 232) say `from: false`. With this landed they're already true on main. The `mixed` row's probe looks for `sim/director/mixed.gd`, which doesn't exist.
- **Not in the repo:** the phrase generator (`gen_phrases.mjs`, named in `phrases.json`'s `_about`) was never committed, so the lists can't be regenerated. Nothing breaks today; it matters only if the lists change.
