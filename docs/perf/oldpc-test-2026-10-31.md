# The old-PC test: page, plain steps, and what a LAN address does (Performance and Platform, 2026-10-31 night)

For the EP, to hand Orb (homework/2 Up Next/10). Orb's old PC: i5 6600K, GTX 1080, 16 GB at 2133 MHz, HD 530 built-in graphics if the board has a port. **Nothing has been opened to the network**: the server does nothing without `go`, and everything below was tried on this PC's loopback address only.

## Findings first

1. **A plain http LAN address does not just change the page: the game will not start on it.** Tried (a browser on this PC reaching the test server through a made-up name that is not `localhost`, so an insecure, non-local origin exactly like `http://10.0.0.135:8780/`): the page loads, the Godot loader stops with **"The following features required to run Godot projects on the Web are missing: Secure Context - Check web server configuration (use HTTPS)"**, no canvas frame, no game, in 120 s and again in 170 s. Same page at `http://127.0.0.1:8781/`: boots in 47 s, `isSecureContext` true, the match runs (tick 137 reached after two clicks), the page's probe reads the meteor trail on and a gen 3 planet. The insecure origin also lacks service workers and `crypto.subtle`.
   - Even once started, a non-local address would drop the page words `?tiles=1` and `?meteor=` (`main.gd` `LOCAL_ONLY_ARGS`; `UiHud.page_is_local` knows only `localhost`, `127.0.0.1`, `[::1]`, `file:`): the tile ground would be off. Read from the code; not reached, because of the above.
   - **So the old PC must see the page at `http://127.0.0.1:<port>/`.** I wrote the way that needs no installation, no administrator rights and no firewall change: **`docs/perf/oldpc/proxy.ps1`, a ~60-line PowerShell relay Orb runs ON THE OLD PC** that listens on `127.0.0.1:8780` only and passes requests to the test server on this PC. Tried on this PC against my loopback server: `/oldpc/` 200 (15,461 bytes), `/game/index.html` 200, `/game/index.wasm` 38,450,604 bytes through it intact, `/etc/passwd` 404, and the report POST arrives and is saved. It accepts only `/oldpc/*` and `/game/*` paths and the one report POST, only targets a private-network address, and stops by itself after 45 minutes. *Not tried:* the old PC's own Windows PowerShell (it is 5.1 on Windows 10 and 11, as here), and across a real network.
   - Other ways, if the relay is not wanted: `netsh interface portproxy` on the old PC (needs administrator, changes system settings: not tried, not proposed); copy the build folder to the old PC and serve it there on 127.0.0.1 (needs Node or Python there); UI and Rendering treating private-network addresses as local (policy, and it would not fix "Secure Context", which needs https or loopback anyway).
2. **Tools' browser launcher had a bug that put a dialog in front of the user** (my first trial passed a flag with a space; Windows PowerShell 5.1 merged all flags into one argument and Chrome showed "Failed To Create Data Directory"). Tools has landed the fix (commit d7935bf5: flags quoted by the Windows rules, unsafe ones refused before the spawn); the two trials above ran through it with the same flag and raised no dialog. Rule I keep: no whitespace in a launcher flag unless the launcher is on that fix.

## Windows Firewall on this PC (the one that serves)

Read-only look at this PC (no rule created or changed):

- Both network adapters that carry an address are classed **Public**: Ethernet `10.0.0.135/24` (Internet) and ZeroTier One `10.238.114.20/24` (local network only). The firewall is on for Domain, Private and Public.
- **`C:\Program Files\nodejs\node.exe` already has two local Inbound Allow rules (TCP and UDP, any port, profile Public)**, as `C:\Python314\python.exe` does. So **no "Windows Defender Firewall has blocked some features of this app" prompt is expected** when the server listens. It would appear if the network were re-classed Private (the rules are Public only), if the rules were deleted, or if a different node.exe path runs. If it does appear it needs **Allow access** ticked and an Administrator approval: tell Orb before they start, not after. *Not tested: a listen on the LAN address (told not to).*
- **That rule is broad (any port, any remote address on a Public network), so the server must not listen on all addresses.** `oldpc-server.mjs` listens on the ONE address it is given, refuses any caller outside that address's /24 (403), serves only `/oldpc/`, `/game/*` and `POST /oldpc/report`, and stops itself after 45 minutes or 90 seconds after the result arrives. It never listens on the ZeroTier address, so ZeroTier members do not see it. If the old PC is reached through ZeroTier, start it with `--bind 10.238.114.20` and say so.
- The old PC needs nothing opened: the relay listens on its loopback address (no prompt) and only makes an outgoing request to `10.0.0.135:8780`. A **guest or "client isolation" Wi-Fi** between the machines would block it (Orb says same local network; I could not check).

## The plain steps for Orb

The PC that serves is this one; the old PC runs a small relay and opens a web page.

**On this PC**
1. The EP makes sure the private preview's build is current (`node tools\preview\stack-preview.mjs --no-serve`).
2. Double-click `docs\perf\oldpc\start-test.cmd`. It shows the plan and listens on nothing. Read the address it prints: `http://10.0.0.135:8780/oldpc/`.
3. When ready, run it again as `start-test.cmd go` (in a Command Prompt in that folder). A black window says "Listening on 10.0.0.135:8780". Leave it open.

**On the old PC (monitor plugged into the graphics card, the GTX 1080, first)**
4. Copy `proxy.ps1` to the old PC (USB stick or a shared folder). Close games and other browser windows; plug the PC in the wall.
5. Right-click the Start button, open **Windows PowerShell** (no administrator needed), and run: `powershell -ExecutionPolicy Bypass -File proxy.ps1 -Target http://10.0.0.135:8780` (in the folder you copied it to). It prints "Relaying http://127.0.0.1:8780/ ...". Leave it open.
6. Open Chrome or Edge and go to **`http://127.0.0.1:8780/oldpc/`** (not the 10.0.0.x address).
7. Do nothing for about a minute: the page looks at the PC, times a short job and loads the game.
8. A yellow message says **click START in the game window**. Close any card (How to play), click **I understand, start**, then **leave the mouse and keyboard alone for two minutes**. Keep the window in front.
9. The page says **Done**. The result goes to the other PC by itself (its black window prints it). If it says it could not send, press **Copy the result** and paste it into your message.

**Second run, on the built-in graphics (HD 530)** if the board has a video port (HDMI or DisplayPort on the back panel beside the USB ports): turn the old PC off, move the monitor cable from the card to the board's port, turn it on and repeat steps 5 to 9. Some boards switch the built-in graphics off while a card is fitted; if there is no picture, plug back into the card and tell the EP, who will give the BIOS steps. The report names the graphics it ran on (the line "graphics:"), so a run on the wrong one is plain.

**After**: close the black windows on both PCs (the server stops itself in 45 minutes anyway).

## What the page measures and says

`docs/perf/oldpc/page.html`: the graphics name and driver strings, whether the browser draws in software (flagged BAD), cores, memory, a fixed 1.5 s job (so this PC can be set beside the dev PC through the same page), the game's load phases, then 120 s of play: frames a second, frame time p50/p95/p99/max, frames over 20/34/50/100 ms, the six worst frames and when, the sim's ticks a second (from the game's probe), long tasks, and a verdict: OK holds 60 (p99 under 25 ms), WARN below that, BAD under 30. It warns if the window was hidden, if there is no WebGL 2, and if the game dropped the page words (a non-local address; cannot happen through the relay). The frames are counted by the page's own frame clock, so a game that cannot keep up shows as fewer frames, not a hidden stall.

## Limits

No browser has run the page itself (its logic is proved in a stub, `page-selftest.mjs`, and it parses); the two browser trials were of the game's own page at the two kinds of address. The relay and server were tried only on this PC. The test plays the live AI-against-AI scene on planet 7 with the stack's switches, for 120 s: a reading, not the frame-bench's controlled scene. The build is whatever is in the preview's `live` folder.

## Files

`docs/perf/oldpc/`: `oldpc-server.mjs` (dry run unless `--go`), `page.html`, `proxy.ps1` (for the old PC), `start-test.cmd`, `page-selftest.mjs` (no browser), `words-trial.mjs` (the two-address browser trial, through Tools' launcher).
