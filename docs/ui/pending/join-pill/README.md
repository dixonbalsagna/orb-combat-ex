# "P2: press T to join" off the play screen (parked)

EP's ruling 2026-10-22: show it only before the first match and on the pause screen, never during play. With `minimal_hud` on the on-screen join prompt (the pill in the right column) draws nothing; the start menu already has its Players choice, and the pause menu draws its own join line (a check). A launched body could fly past the pill, and Orb's rule is nothing in the fight space. The brief "P2 joined" and "left" notes are kept (they confirm a press).

Apply after `chips-off-bodies`: `patch -p1 < docs/ui/pending/join-pill/join-pill.patch`. Files: `ui/hud/ui_hud.gd` (`join_prompt_alpha`), `ui/tools/hud_check.gd` (one check).
