# Parked: limb smears for 4 ticks, not 8 (VFX, 2026-10-19, on HEAD 02a37e53)

Research's cinematic paper, rec 12: "Smears on limbs for 1 to 2 frames only" (fighters stay sharp). A one-line change in render/vfx/press.gd's defaults: `crescent_life` (the crescent smear of a heavy) 8 to 4 ticks and `ghost_life` (the limb and body echoes of tech and heavy blows) 8 to 5. Fewer ghosts alive at once, so Legal's f01 and m05 caps are only easier.

`git apply --check` clean. effects_check passes. Side by side on the mash scenario (a brawl with lights and heavies, Reduce flashing on), ticks 150 to 240, GIF in homework/short-smears/ (private). Honest note: the difference is subtle at normal speed (the smear is gone sooner, the body is sharp sooner); the look gate is Orb's eye on the GIF. Speed lines already draw behind the fighters (z -9) and stop short of the hit point, so the rest of rec 12 is already true. Not a Legal clearance; flash readings not re-run.
