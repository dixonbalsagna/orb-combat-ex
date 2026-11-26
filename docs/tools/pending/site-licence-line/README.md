# Park: the licence line on the site's front page (Tools, 2026-11-25; RL-265)

`site-licence-line.patch`, cut on HEAD 643693aa. One line of `tools/build-site.mjs`. `git apply docs/tools/pending/site-licence-line/site-licence-line.patch`.

"license not chosen yet, all rights reserved for now" becomes Legal's line, word for word: **License:** all rights are reserved during the Alpha. See "What you may do with Orb Combat EX". Whether the code is made public is decided at Beta.

**Run:** the interim site self-test, 254 checks. The site is offline, so nothing a visitor sees changes today.

**For Legal and the EP:** the line says "See 'What you may do with Orb Combat EX'", and the public site has no such page. Either publish it there when the site comes back, or Legal gives the public page its own wording. **Other old copies, not mine:** `ui/data/howto.json:98` and `ui/tools/hud_check.gd` (UI, parked as howto-licence), and `README.md:7` ("Licence: not chosen yet").
