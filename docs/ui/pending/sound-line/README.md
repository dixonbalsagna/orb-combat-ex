# The start menu's sound line (parked, not committed; lands only if Orb's next play shows a pad does not wake the sound)

The EP's brief of 2026-11-07, from Audio's `docs/audio/pad-start.md`: a browser may not count a pad press as permission to start sound, so a player who starts with the pad alone could hear nothing and not know why. One small line on the start menu, shown only while `audio.web_blocked()` is true. Full account: **docs/ui/sound-line.md** (in the patch).

**Two patches (the second is a grant: render/core/main.gd is not UI's):**
- `sound-line.patch` (sha1 a96be081ac52; 8 files; cut on HEAD c1cc3178): the words (`prompt.menu_sound_blocked`: "Sound starts when you press a key or click"), `UiMenu.plan` (one more small line, last, under Reduce flashing's; a card too short for it drops it first and still fits; never mid-match), `UiHud.web_blocked_fn` (the host's `() -> bool`, read once a frame only while the start menu is up; unset = no line), the redraw key, demo flag `--menu --sound`, 5 hud_check checks, strings.md and the pseudo-locale (terms.json: the new line only; `pseudo --check` current).
- `web-blocked-grant.patch` (sha1 38abea2f217d; render/core/main.gd, one line after `ui_hud.feedback_fn`): `ui_hud.web_blocked_fn = func() -> bool: return audio != null and audio.web_blocked()`. Without it the hook stays unset and nothing shows, so the UI patch alone is inert and safe to land first.

**Apply:** from the repo root, `git -c core.autocrlf=false apply docs/ui/pending/sound-line/sound-line.patch` then the same for `web-blocked-grant.patch`. Independent of `refusal-compact` (both touch ui_hud.gd, hud_check.gd and hud_demo.gd in different places; checked: refusal-compact, then sound-line, then the grant, all apply clean on a HEAD export; the other order was not tried).

**Pictures** (the web build of the demo through `tools/machine/capture.mjs`, 960 by 540): `menu-sound-line-960x540.png` (`?menu&sound`) and `menu-no-line-960x540.png` (`?menu`). The line sits last in the card's foot in the same dim small type, inside the card; with the hook off the card is as it was. A mock of the host (the demo's hook answers true): the real `audio.web_blocked()` needs the browser, so it is not proven here.

**Look gate:** the card grows by one small line (about 12 px at 960 by 540) and is centred as before, so its other rows move up by half a line while the line shows. Nothing is on or near a fighter (the menu holds the match); nothing fades or animates; the line goes in one cut when the sound wakes.

**Gate:** the full hud_check on a HEAD export plus sound-line.patch: 7773 checks, 0 failed (7768 on HEAD, plus the 5 new). Not run: the other render gates (UI-only; nothing near a fighter).

**Not done / not mine:** the pad press's handling and the shell snippet (Audio, Tools). A start card on the web that is not this menu (the first-start "Press any key" hint) is not changed.
