# 7. Data flows

What the shipped game or its page sends off the machine, writes to disk, or reads from outside its own files. This is from a code search on 2026-11-07, not a full audit.

## Sends off the machine
- **LAN play:** ENet over the home network between the two PCs (`net/enet_transport.gd`, `net/host.gd`, `net/handshake.gd`, `net/transport.gd`). LAN builds only. The kit's firewall scripts (`firewall-allow.ps1`, `firewall-remove.ps1` in the LAN folder) open and close one port.
- **Feedback report:** `ui/widgets/ui_feedback.gd` opens a URL (a GitHub issue link carrying the report text and changed settings) in the browser, only when the player chooses to send it (`open_url`, `OS.shell_open`, `UiWebClip.open_url`). I don't know whether the public pinned build `257a766c` has this.
- **Page loads:** the Web build loads its own files from the same site. I haven't audited the Web template for third-party loads.

## Writes to disk
- `user://ui_prefs.json`, the UI's remembered settings (`ui/core/ui_prefs.gd`). On the Web this is the browser's storage.
- `user://input.json`, control remaps (`sim/input/remap.gd`, `sim/input/input_data.gd`).
- `user://field-cache/`, the planet field cache: IndexedDB on the Web, a folder natively (`sim/world/field_cache.gd`).
- **Private builds only:** the black box (`tools/preview/blackbox.mjs`, injected into private kept builds, not the public site as far as I know) saves a play file `orb-first-play-*.json` to Downloads. It holds the match replay, raw pad input (`rawPad`), slow frames, the audio status and Orb's typed answers. It's only read back by our tools.
- **LAN builds:** a `lan-log-main.txt` or `lan-log-old.txt` beside the exe (`net/tools/lan_kit.mjs`).

## Reads from outside its own files
- The page's address words (`location.search`): `audio/audio_web.gd`, `render/anim/spike/spike.gd` and the page hooks.
- The browser's Gamepad API and AudioContext (`audio/audio_web.gd`, Audio's shell snippet `docs/audio/pending/audio-resume/shell-snippet.js`, now injected into every Web build by `tools/lib/audio-shell.mjs`).
- `audio/audio_voices.gd` reads the page's audio state through `JavaScriptBridge.eval`.
