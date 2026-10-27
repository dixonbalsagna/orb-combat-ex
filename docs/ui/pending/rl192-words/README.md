# Park: Legal's RL-192 word swap in the in-game notice, with RL-193's spellings (2026-10-27)

UI, on the EP's urgent brief. Words only, copied from `docs/legal/page-fixed-lines.md` (the 2026-10-27 addendum). Based on HEAD 6de9aeb7; it applies alone (a dry run is clean on HEAD's four files, and the result is byte for byte the scratch tree's).

```
patch -p1 < docs/ui/pending/rl192-words/rl192-words.patch      # UI's own files only, no grant needed
```

sha1 rl192-words.patch 11d664531ae45e7d4f2cb9b1e0d1cebb1f82afe4. 5 files (RL-192 and RL-193).

## What changes

- `ui/data/terms.json` under `prompt`: `menu_notice`, `photo_body_a`, `photo_body_b`, `menu_rf_locked` as Legal's addendum gives them (menu_notice and menu_rf_locked match Tools' OWNER_FLASH and OWNER_LOCK in `tools/check-site-interim.mjs` word for word). `photo_title`, `photo_settings_line` and every other word are untouched.
- `ui/data/settings.json`, the Flashing effects notice help: "...and that no independent photosensitivity analyzer has been run."
- `ui/data/options.json`: the label "Color-blind mode" (the id `colour_vision` stays).
- **RL-193 (eleven spelling-only changes, ids stay):** `ui/data/howto.json`: every Licence/licence in text becomes License/license ("License and privacy", "MIT license", "SIL Open Font License 1.1", "Third-party licenses", "The full license texts", "its licenses", the first-run About line); the page id `licences` stays. `ui/data/options.json` helps: colour to color in `colour_vision` and `you_marker` (the ids and keys stay), "licence check" to "license check" in `glyph_style`.
- `ui/tools/hud_check.gd` (its expected words, moved with the data): `GATE_TEXT`, `LEGAL_MENU`, the gate's drawn-words list ("do not play this version", "not fixed yet"), and the About expectations (ABOUT_LICENCE, ABOUT_GODOT, ABOUT_OPENSANS, ABOUT_FULLTEXTS, the two page titles and the first-run line), and the locked-line test (it asserted the line began "Reduce flashing is on."; it now asserts Legal's whole lock line).

## The rf-lock flag (Legal's condition 1)

`lock_reduce_flashing` in `ui/data/features.json` (UiData.rf_locked()): false in the tree, so the toggle shows in a normal build. The interim export sets it true: `tools/site-pin.mjs` (`exportPinned`, `lock: !!config.interim`) rewrites it in the exported tree's features.json, and `tools/check-site-interim.mjs` fails the export if it is not true (the check Legal mentions). With it true `menu_rf_on`, `menu_rf_off`, the Reduce flashing row and its options help ("Turning it off restores full effects") show nowhere: the start menu draws `menu_rf_locked` under the button. Nothing in this patch changes that.

## Gates (a scratch tree of HEAD + this patch, below-normal, one Godot at a time)

- hud_check 5816 checks, 0 failed (two earlier runs failed on expected words only: the gate's drawn-words list, then four About checks still quoting "Licence"; fixed in the check, not the data); determinism plain and `--intro --seeds=2 --ticks=900`, hud_words and pane_check passed; `after_check` passed.
- `node tools/validate.js` 269 files, 0 errors, 0 warnings; `--self-test` 9154 of 9154; determinism lint ok.
- Stills from a web export of the scratch tree with the lock flag set true as the interim export does (guarded launcher, session tag `ui-ux`): `menu-notice-locked-1280x720.png`, `menu-notice-locked-390x844.png`. The notice reads Legal's words, the lock line sits under the button, no Reduce flashing box shows, and everything fits. Words only: layout and look are unchanged, so no side-by-side or flash run.

- **Tools' acceptance test (docs/tools/pending/ui-strings-check.patch, sha1 8078f3a4...):** on a scratch copy of HEAD with this patch and Tools' patch (its tools/site-ui-spelling.json is `"allow": []`), with the lock flag true as the interim export sets it, `node tools/check-site-interim.mjs --site <empty> --root . --no-pack-scan` prints no ui/data failure (only the six missing-page lines of the empty site). Controls: putting back "MIT licence", or a changed photo_body_b, makes it fail on exactly that string. Without the lock flag it fails on the flag alone, as it should for the tree.

## Not in this patch

`docs/ui/*.md` and the older parks' patches still quote some old words (history); only data, the check and the labels move. Tools' own scan of `ui/data/*.json` for British spellings is theirs.
