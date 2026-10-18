# Reduce flashing locked on, behind a flag (UI, 2026-10-17)

Owner: UI & UX. **Built in scratch and parked behind `features.json` `lock_reduce_flashing` (off in the tree).** For Legal's addendum 10 (RL-156, `docs/legal/photosensitivity-note.md`): until full effects (Reduce flashing off) have a recorded pass, the interim build must not offer them. The patch is `docs/ui/pending/rf-lock/rf-lock.patch`; it applies on its own on HEAD and in either order with the other four parks (dry runs clean, fuzz only).

## 1. What the flag does

With `lock_reduce_flashing` true:
- **Settings** lists no Reduce flashing row (Reduced motion and the rest stay).
- **The start menu** has four boxes (Intros, Screen shake, Captions, Guide), not five. Its small line under the button is Legal's RL-136 line alone: "Reduce flashing is on. It lowers some effects but does not remove the flagged scenes."
- **Nothing saved or sent can turn it off.** The menu opens with it on whatever the saved menu said; Start hands the host "on"; `settings_set` ignores an Off; `load_saved_options` ignores a saved Off from before the lock (so a visitor who unticked it earlier gets the calm look back).
- **The notice's Open Settings button** lands on Reduced motion, not on a row that is not there.
- **Not locked, on purpose:** `set_option` (the capture hook, `render/tools/flash_capture.gd`, writes the option directly to measure the other mode, and only on a local host). Without that route the full-effects pass could not be recorded at all. No screen, key, link or saved file reaches `set_option`.

## 2. When the toggle is shown (flag off, the tree today)

Legal's sentence is on it, word for word: **"Turning it off restores full effects, which flash more."**
- Settings: the row's help line ends the first sentence with it ("Fewer and gentler flashes. Turning it off restores full effects, which flash more. Reduced motion is a separate setting." This is Legal's wording of RL-157, which dropped the "at most one large flash a second" claim; the change is parked in `docs/ui/pending/rf-words/`.).
- The start menu's small line, with the box ticked: "Reduce flashing: on. Turning it off restores full effects, which flash more." With it unticked: "Reduce flashing: off. Full effects are on, and they flash more."
- Never "safe", "tested" or "compliant" (a check reads the three lines).

## 3. Turning it on

Set `lock_reduce_flashing` to true in `ui/data/features.json` in the interim site's export. **It is one word; if it is forgotten the toggle shows.** A line in Tools' `check-site-interim.mjs` that reads the exported `features.json` and fails when the flag is not true would close that (Tools' file; a request under NEEDS FROM EP).

## 4. Two things that changed on the way

- **The menu's small line, unlocked, no longer carries "does not remove the flagged scenes".** It would not fit the shortest phone screens with Legal's new sentence added, and when the toggle is shown full effects have passed, so there are no flagged scenes to name. The RL-136 line is the locked state's line, unchanged.
- **With four boxes the grid is full**, so Start has no empty cell to take on a short screen. It now takes a row under the boxes when the left column is the taller (the case that needs it), checked at the menu's 19 sizes.

## 5. Gates

Scratch of HEAD + this patch alone, the three rule sets that touch it (`_reduce_flashing_rules`, `_rf_lock_rules` with 14 new checks, `_menu_rules`): 50 checks, 0 failed. **Stacked with the other four parks (order launch-anywhere, run-mode, hud-cache, run-boons, rf-lock, the launch-anywhere patch amended for Encounter's cue fields): `hud_check` 4,789 checks, 0 failed; `determinism` plain and `--intro --seeds=2 --ticks=900`, `hud_words_check` and `pane_check` passed.** New checks: the flag is off in the tree; the row carries the sentence; the menu line carries it when on; never safe/tested/compliant; locked, no row in Settings and four boxes in the menu; locked, the card fits at eight sizes with no control for it; a saved Off is ignored on load; the Settings route cannot turn it off; the menu opens on and Start hands "on"; Open Settings lands on Reduced motion; and the capture hook's route still sets either mode.

## 6. Legal's answers (RL-157, `docs/legal/rewards-and-lock-screen.md`, 2026-10-18)

1. The "at most one large flash a second, and the small ones off" claim is dropped (it is measurable and our calm reads reach 2.5 and 3); the help line is Legal's new one (section 2, `docs/ui/pending/rf-words/`).
2. The off-state line passes as written. Dropping "does not remove the flagged scenes" from the shown-toggle line passes (the toggle shows only after a recorded full-effects pass). The locked line stays; if the next interim's pass has no clip over the limit, Legal gives its words (likely "Reduce flashing is on. It lowers some effects.").
3. The capture hook's `set_option` route is fine. The flag check is a condition for Tools: `check-site-interim.mjs` fails the export when `lock_reduce_flashing` is not true unless a full-effects pass is recorded for the published commit.
