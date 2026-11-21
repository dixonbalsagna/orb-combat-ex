# a1-boot-menu: the start menu waits while the game makes its first planet (UI & UX, 2026-11-20; park for GW1a)

**The fault (found by Tools' smoke run on the GW1a stack, s422):** with the round planet as the default, the game makes a planet at boot (the loading screen, phase "places" and the rest; about 10 seconds on this PC, longer on a Steam Deck). The Rail start menu opens by itself at boot and paints an opaque backdrop **over** the loading screen, while `UiHud._unhandled_input` sends every press to the loading screen (`if is_loading(): _loading_input(event)`; it answers only Back). So a player who launches the first build sees the start menu and every press does nothing until the planet is made. Before GW1a there was no boot load, so this is new with the default planet. A press after the load works (a real pad A opened the setup in a probe on s423 after 10.3 s).

**The fix (UI only; a plain show and hide, no fade, as the EP ruled):** while the game is loading the start menu is not drawn, so the loading screen with its words shows alone; when the load ends the menu appears and answers. `UiHud.start_menu_visible()` says which; the notice layer's sig and `_paint_notice` use it.

- `boot-menu.patch` (sha1 b29586c02071): **on the final GW1a tree with `a1-save-reason` applied** (the EP's order); `ui/hud/ui_hud.gd` and `ui/tools/hud_check.gd` (`_boot_load_menu_rules`).
- `boot-menu-without-save-reason.patch` (sha1 6940254f866b): the same change on the tree **without** save-reason (the two collide on `hud_check.gd`'s call list and its end); apply whichever matches the order.
- **Test:** a menu open, a load running: the menu is not on the screen and A does nothing; the load ends: it is on the screen and A opens the setup. Partial run with the neighbouring menu rules: 766 checks, 0 failed.

**With it, and the smoke waiting for the load (`a1-mode-smoke`), on a copy of s423 plus save-reason:** solo 19 steps, 0 failed; two people 19 steps, 0 failed, the matches played with the picked fighters (`runs/`). Scratch user-data folder (the runner isolates it).
