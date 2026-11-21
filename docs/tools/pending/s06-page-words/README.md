# S-06: the page build tool dropped every match word after GW1a (Tools, parked 2026-11-21)

The stand-in's GW1a review (S-06): once main has its own planet entry (`_planet_setup`, A-CODE-03) the page build tool skipped its three planet edits, so the page's own setup function (`_preview_planet`: travel, flat-out and their sliders, power, dash, tier, peak, kick, hit-stop, and the hooks on it) was called by no match start. Orb's shortcuts use `travel=1.5` and `peak=1`.

**Confirmed on a real page, then fixed.** I built the page twice from main (b0e20f9a, the GW1a landing), started a match through the new menus with keys and read the match's setup back from the black box's record (`?planet=7&go=1&blackbox=1&flatout=3500&travel=1.5&peak=1`):

| Build | The match's setup |
| :--- | :--- |
| the tool as it is on main | `{aiLevel, assists, planet 7, planetGen 3, slots, touch 3, v2}`: **no `flatOut`, no `travel`, no `startTier`, no `dash`** (the words were dropped) |
| with this patch | `{aiLevel, assists, **dash true, flatOut 3500**, planet 7, planetGen 3, slots, **startTier 4**, touch 3, **travel 1.5**, v2}` |

`s06-page-words.patch` (sha1 `859fb34c08ce861809dff09bac126bd318644f2c`, applies to HEAD, three files, all Tools'):

| File | Change |
| :--- | :--- |
| `tools/preview/switches.mjs` | three new edits (`onlyIf: 'func _planet_setup('`) route main's real call sites through the page's setup: `var plain := _planet_setup()`, `su.merge(_planet_setup())` and `var su := _planet_setup()` (read from `render/core/main.gd` as it is, not guessed) become `_preview_planet()`; on such a main the page's base IS `_planet_setup()` (a menu-started planet and `?planet=N` still work), and the rows' setup keys (gen3's `planetGen: 3`) are added when the address names the planet, as before. The older three edits stay for a main without the entry. The page's probe also says whether the start menu is open, its page, rows and focus (read only) |
| `tools/preview/smoke.mjs` | the boot-and-play check **pressed screen points of the old Rail menu, so on the A1 menus no match ever started and every page build after GW1a failed its own smoke** (I had to use `--no-smoke`). It now presses the keys the menu answers (Down, Enter) by the probe's own rows (the list of modes: solo; the setup: Start); a tree whose probe has no menu field keeps the old clicks |
| `tools/preview/preview-selftest.mjs` | the old fixture **guessed** main's call sites and asserted the skip (the cause of S-06: "routes nothing through the scratch entry"). It now patches main's real `render/core/main.gd` and asserts: the three starts read `_preview_planet()` and none still reads `_planet_setup()` directly, the base is main's own entry, the page words reach the setup (travel, flat-out, tier, kick, hit-stop, dash), a row's setup key is added, and a main WITHOUT the entry is still routed by the older edits |

## Proof

- `preview-selftest` **186 checks, 0 failed** (181 before; one old check replaced by six), `stack-selftest` ok, `switch-diff-selftest` 11, `build-check-selftest` 12, `pck-verify-selftest` 12; `check-workflows` ok, `check-workflow-shell` ok.
- **The patched smoke on the fixed page:** "the match was running after 2 rounds", 1,204 more ticks in 20 s of play, no script error; its setup read back: `dash true, flatOut 3500, travel 1.5, startTier 4`. (My driver for that read passed no switch list, so it also printed "planetGen reads 3, expected 2": a property of that driver, not of the page; the real build run passes the page's switches.)
- Not proven: Orb's own shortcuts (`make-shortcuts.mjs` words `meteor=loud&tiles=1&go=1&blackbox=1&audiolog=1`, `travel=1.5`, `peak=1`) were not each opened in a browser: the proof is the words `flatout`, `travel`, `peak` (and the dash the power model adds), read from the match. `kick`, `hitstop`, `tier` and `instant`/`climbTicks` go through the same function and are covered by the self-test's text, not by a played match. The smoke's key navigation was proven on this one tree; a future menu change moves the row names it reads.
- Side effect: `EDITS_FINGERPRINT` changes, so every cached page build is rebuilt once.

## What it does not do

The page's old `go=1` word still only sets the menu preferences (Player 1 a controller, intros off, the card seen); it never started the match by itself: the player (or the smoke) chooses a mode and Start, as on the A1 menus. Orb's shortcut therefore opens on the list of modes.
