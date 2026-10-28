# Steam Deck readiness (Tools, 2026-10-28)

What the Deck needs from us, what the repo now does about it, and what only a Deck can answer. Background: the Linux section of `docs/perf/desktop-boot-2026-10-27.md`.

## The build

- **Native Linux, not Proton.** The `Linux` preset in `export_presets.cfg` (release, Compatibility renderer, `x86_64`, pck embedded, the Windows preset's filters) gives one file, about 82 MB (the 73.5 MB template plus about 8.5 MB of game). Godot's Linux build runs on SteamOS through Mesa's OpenGL driver, so no Vulkan path and no Proton layer is needed. Proton running the Windows exe would also work, but adds a translation layer and its own shader cache for no gain; ship the native build as the Deck's default and keep Proton as the fallback a player can force.
- **Built on Linux.** `.github/workflows/linux-export.yml` (by hand) exports on an Ubuntu runner, sets the executable bit, plays the game's bench headless from the project and from the binary and fails unless both print the same gameplay hash, then uploads the binary. The artifact zip drops the executable bit: the depot upload (or a launch script) must set it again.
- **Same match as web and Windows.** Measured in the cloud container on 9631fc7: the exported Linux binary, run headless with `--fixed-fps 60 -- --seed=4 --frames=2400 --bench`, prints `gameplay hash at tick 2400: d4f6342a1009bdbc`, the hash the Windows native and both web runs printed in desktop-boot-2026-10-27.md. The Deck is x86_64, the measured case.

## What the Deck needs, and where we stand

| Need | Where we stand |
|---|---|
| **Resolution 1280 by 800 (16:10)** | Not set or tested. The project has no `[display]` section, so the window starts at Godot's default 1152 by 648. The game must fill 1280 by 800 at launch (fullscreen, or the window size and stretch mode set for 16:10) and its HUD and split view must hold at 16:10. Rendering's and UI's call. |
| **Controller glyphs** | The HUD has device families for prompts and names `deck` among them (`ui/hud/ui_hud.gd`), but nothing detects a Deck: through Steam Input the built-in controls usually appear as an Xbox-style pad, so Xbox glyphs show. Showing Deck glyphs needs either Steam Input's own glyph API (Steamworks, not in the project) or detecting SteamOS (`SteamDeck=1` in the environment) and mapping to `deck`. UI's call. |
| **Steam Input** | Untested. The game reads Godot joypads; with Steam Input on (the default), Steam presents a virtual pad, which should work. A default controller layout has to be published for the game on Steamworks. |
| **Suspend and resume** | Untested. On resume the fixed-step loop sees one long frame; it must not try to catch up hundreds of ticks (check the loop's step cap) and audio must come back. Online play would drop on suspend, which is expected. |
| **Text size** | Verified-badge rule: text readable at 1280 by 800 on a 7-inch screen (Valve asks for at least 9 px tall). Not checked. |
| **Frame time** | Unmeasured. The web bench on a fast PC is CPU-side bound (3 to 4 ms of view update and tick), so the Deck's Zen 2 cores are the thing to watch, not its GPU. |
| **No launcher, no on-screen keyboard needs** | Met: the game boots straight into play and needs no text entry. |

## What can't be checked without a Deck

Frame time and battery draw on the hardware; Mesa's OpenGL behaviour on the Deck's GPU (shader compile stalls on first launch); Steam Input's actual mapping and glyphs; suspend and resume; the 16:10 layout on the real screen; Steam Deck Verified review itself. The headless run here proves the binary boots, loads its pck and plays the same match. It drew nothing (headless uses the dummy renderer), so it says nothing about the GPU.
