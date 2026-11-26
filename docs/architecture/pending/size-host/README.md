# The planet size through the host: the planet made ahead and New match (Simulation, 2026-11-26)

**Parked, not landed.** This is item 1 of the un-hide list in `docs/world/pending/planet-sizes/README.md`: "the one a player can walk into from the menu". It goes with the small-and-big flip, before or with it.

## What was wrong (read from the code, then shown by the check without the fix)

1. **The planet made ahead ignored the size.** `SimHost.planet_key` (`render/core/sim_host.gd`) was the planet, its generation, the touch-down and the arena.
   - The menu prefetches for its choice (`main._on_menu_changed` → `host.prefetch(planet_part(cfg))`). After a size change the key stayed the same, so the work for the old size went on.
   - At Start, `new_match` took up that work as "the planet made ahead for this very choice". The loading screen then finished the **old size's** planet. `load_step` then started the match with strict off, so the planet of the size actually picked was made cold **inside the match's start**: the long stall the loading screen exists to prevent.
   - The match itself did play the picked size, because `beginMatch` reads the setup's size and World's planet memo is keyed by columns. The cost was a wasted load plus a stall.
2. **New match dropped the picked size.** `main._on_menu_started` clears `_planet_next` after Start. The pause menu's New match (and N) calls `start_match(fresh_seed())`, whose setup names no size, so it played medium.

## The fix: `grant-rendering-size-host.patch` (Rendering's two files; needs Rendering's yes)

sha1 `3b0c22f24f5138b34f035f7bee1be8224c6fd805`, sha256 `a90a92512a51…`, 63 lines.

- **`render/core/sim_host.gd`, `planet_key`:** the key also names the size, as its columns (`WorldPlanetSize.colsOf(setup)`). The planet is made at those columns and World's planet memo is keyed by them. So an unnamed size and "medium" are one key, and small, medium and big are three.
- **`render/core/main.gd`:** `_size_picked`, set at Start from the menu's `planet_size`, the way `_ai_level` keeps the computer's level.
  - `_planet_setup()` adds it as `planetSize` when `_planet_next` is empty, so New match and N keep the size. It does so only where the match is a planet (a planet named, or the default world is a planet: `planet_part`'s own rule), so an arena setup never carries a size into its replay stamp.
  - Before any Start it is "", so the boot, the demo match, tools and the soak are unchanged.
  - The loading screen's Back resets it to the size of the match still under the menu, or "" when there is none. So the demo match after a Back never starts a cold load of the size the player backed out of.

## The check: `size-host-check.patch` (mine: `sim/core/tools/size_host_check.gd` and its `.uid`)

sha1 `f731354dc3a5e5ac70e38bff69bbaf2f2e792b64`, sha256 `113ad770383d…`. It has 15 rows and ends on `SIZE HOST: N check(s) failed`, so it runs under `node tools/gate.mjs --verdict`. It follows `sim/core/tools/coop_check.gd` in using the host from a sim tool.

| Group | Rows |
| :--- | :--- |
| key | small, medium and big give three keys; an unnamed size gives medium's key; no planet gives no key |
| prefetch (strict on) | a size change starts over at the new size's columns; the same size again leaves the work alone |
| start | Start with big after medium was made ahead loads big; after big was made ahead, Start takes that work up |
| new match (the main scene) | before any Start, medium; Start with big plays big, and **a New match after it plays big**; after a Start with medium, New match plays medium |

## Apply

Both patches apply strictly (`git -c core.autocrlf=false -c core.eol=lf apply`) on HEAD (1e6048e2), and on HEAD plus World's `unhide-small-big.diff`. Order: World's flip (and its UI grant), then the grant, then the check. Then add the check to CI, for example job 1 c beside `memo_check`: `node tools/gate.mjs --verdict -- "$GODOT" --headless --path . --script res://sim/core/tools/size_host_check.gd` (about 1 minute). That line is Tools'.

## Proof

Tree: a clean export of 3c95f5af, plus `unhide-small-big.diff`, plus the grant and the check. One Godot at a time, below normal, own data folders. Records are in `docs/sim/runs/3c95f5af/size-host/`.

| Run | Result | Record |
| :--- | :--- | :--- |
| `size_host_check` with the grant | **15 of 15 pass**, `SIZE HOST: 0 check(s) failed`, gate exit 0 | `size_host_check.txt` |
| the same **without** the grant (negative control) | **7 fail**: the two size keys, the two prefetch restarts, Start taking medium's work, and both New match rows | `size_host_check-negative-control.txt` |
| parity through `tools/gate.mjs` (the golden check) | exit 0, 88 rows, 0 FAIL, **golden check passed** (the golden doesn't move: the change is the host's and main's, never the sim's) | `parity.txt` |
| two-fighter ratchet | ok, 365 against a baseline of 365 | `ratchet-two-fighter.txt` |
| fighter-specific ratchet | 0 places, baseline 0 | `ratchet-fighter-specific.txt` |
| UI's `difficulty_check` (New match keeps the level) | exit 0, 0 FAIL | `difficulty_check.txt` |
| UI's `load_check` | 1 FAIL, "no planet: the match starts at once". **It fails the same without the grant**: the setup `{"intro": false}` now gets the default world's planet (a cold gen 3 planet 7), so it loads. That row is out of date since the default world became a planet; it's UI's to update | `load_check.txt`, `load_check-without-grant.txt` |
| Rendering's 15 | all pass | `render15/` |

## Not changed (noticed on the way)

New match plays the default world's **fixed** planet (`SimHost.new_match` applies `WorldDefault.apply(su, seed, true)`), even after a Start that drew a quick match's planet. That was so before this fix, and the fix keeps only the size.
