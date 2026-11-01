# LAN test, version 1: a plain 1v1 between two PCs

Netcode, 2026-11-01. **Ready, not started. It has never connected two programs, and it must not be run until Orb says so,** because the firewall step needs Orb's real yes.

## What it is

One fight, on the globe (planet 7, `planetGen` 3), one player on each PC, over the native link. It's a private build only.

- **`net/lan.gd`, `NetLan`:** the game's own loop steps the sim through a `NetHost`, and the local pad is the host's bot. The window's title says "Waiting for the other PC", "Connected" or what went wrong. A log (ping, step counts) goes next to the game.
- **`net/session.gd`:** one switch, `presentOut`. A new tick's feed and fx stay for the game to draw, and a re-run's are dropped. Off, as on main, nothing changes.
- **`net/tools/lan_kit.mjs`:** makes the folder from a scratch copy. It refuses a tree with a `.git`.
- **`net/tools/lan_words.txt`:** what Orb reads first, which becomes `READ ME FIRST.txt`.
- **`net/enet_transport.gd`:** an optional filter on who may connect. Off, as everywhere but here, nothing changes.

**The public builds don't change.** They exclude `net/`, and `tools/desktop-package.mjs routes` refuses otherwise (Legal RL-204). So the kit patches the game's calls into its scratch copy: 2 edits in `render/core/sim_host.gd`, 5 in `render/core/main.gd`, and `export_presets.cfg`'s exclude becomes `net/tools/*`. It stops if a line no longer fits. It also locks Reduce flashing on, as the desktop builds do.

**So `export_presets.cfg` on main must keep `net/*` out.** `tools/desktop-package.mjs routes` on the kit's patched tree fails with exactly that: "the Windows Desktop preset does not exclude net/* (online play stays out of the package: RL-204 condition 1)". The desktop package self-test doesn't read the kit, and passes. Having the network code in costs about 80 KB of the 119 MB build. When LAN becomes a real feature, this needs Rendering's and Legal's proper version.

## The input wait

**On a LAN the wait is always 2 ticks (33 ms), whatever the PC's speed.** `NetDelay.choose` only raises it to shorten rollbacks it expects from the link's ping, and a LAN's ping predicts none. It can't see a slow tick. So `--lan-delay=N` sets a floor, on `Host` or `Join`. The larger proposal wins, so one PC asking is enough, and the window's title says what was agreed. 3 ticks (50 ms) gives a stutter of up to 50 ms before the other PC has to guess. Whether that's worth the later response is for Orb's hands.

## A press and a freeze

A press now lands 2 ticks later, and a frozen tick reads no input. Sent as it is, a press during a hit-stop would be lost, and if the hub kept it, it would go out several times. So while the freeze lasts past the delay, `NetLan` sends the held controls only and keeps the press, as the hub already does offline. It goes once, when it can land.

## Making the folder

```
node net/tools/lan_kit.mjs --tree=SCRATCH_COPY --out=FOLDER --godot=PATH\Godot_v4.7.2-stable_win64_console.exe --host-ip=10.0.0.135 --build=<commit>
```

It takes under a minute. The folder has the game (about 113 MB) and these:

| File | What it does | Where |
| :--- | :--- | :--- |
| `READ ME FIRST.txt` | The steps | |
| `Allow through the firewall (main PC, once).cmd` | Adds one inbound rule, after Windows' one approval box: this game, UDP 47100, addresses in the host's /24 only, so ZeroTier members can't reach it | Main PC |
| `Host (main PC).cmd` | Starts the game, listening on that one address | Main PC |
| `Host with a longer wait (main PC).cmd` | The same, with `--lan-delay=3`, so Orb can compare by playing | Main PC |
| `Join (old PC).cmd` | Starts the game and calls the main PC. It asks for nothing | Old PC |
| `Remove the firewall rule (main PC, afterwards).cmd` | Takes the rule away, and any Windows added | Main PC |

Build it on the main PC: the kit stops if the address isn't that PC's own. `10.0.0.135` comes from Performance's look on 2026-10-31.

## Proof, and what's missing

No socket was opened, no firewall script was run, and `enet_check` wasn't run. On the EP's base tree:

| Test | Result |
| :--- | :--- |
| `lan_check`: two `NetLan`s over the loopback's links, a 12-tick freeze every 97 ticks, on lan and p120 | Every press went exactly once (52 of 52 a peer). At most 2 landed on a frozen tick. No desync. Both peers' games got the same fx on lan. The chooser says 2 on a LAN, and 3 asked on one PC holds on both |
| `lan_check --negative-control` | With the freeze rule off, 14 presses landed on frozen ticks. With output cleared, no fx reached the game. Both caught |
| The built game, headless, `--lan-loop` (the other PC simulated in-process, no socket), 1,500 frames | lan: 0 rollbacks. p120: about 220 rollbacks by tick 1,200, deepest 14. 19 checks matched and none failed on both, no script errors |
| Both firewall scripts | They parse. **Never run** |

**Not proven, and only Orb's first try can show these:**

1. **Whether the rule stops Windows' own box.** If the box appears anyway, the words say to click Allow access.
2. **The real link between two programs with `NetLan`.** `enet_check` covers the same transport with bots, in CI, on 127.0.0.1.
3. **The start menu and the pads in a real window.** Headless runs skip the menu, and nothing here has drawn a window.
4. **Two different processors.** Run `docs/net/two-pc-check.md` first: if they disagree, this can't work.

**Known rough edges, all in the words:** one fight only, no rematch; pausing freezes the other PC; a lost link just stops. The first try's log gives real ping and rollback numbers.

## Legal's terms (RL-230)

**Orb alone, on both PCs.** A second person isn't covered: Orb names them first and Legal rules on that name.

| Term | Where it's met |
| :--- | :--- |
| The warning before play on both PCs, not bypassed | The game's own start menu carries it, and the shortcuts pass no skip word. `--lan-loop` skips the menu only with no window. Asked of the game's own rule on the kit's tree, for all three shortcuts: locked, no bypass, the warning shows. **Nobody has seen it in a window** |
| Reduce flashing locked on | `desktop-package lock`, and the kit stops if the flag isn't on or the capture hook is |
| Orb alone, nobody else in either room | The WHO PLAYS line, verbatim, and the kit stops if it isn't |
| Home network only, the /24 filter, no ZeroTier | The kit stops unless the address is this PC's own, on a real adapter. The rule allows that /24 only, and the host also refuses any other address itself (`NetEnetTransport.allowPrefix`). **The filter's rule is tested, but not over a real link.** The words rule out the rest |
| The firewall rule removed afterwards | Step 8, "do this every time" |
| Nothing recorded or shared, the kit and address stay on Orb's PCs | The WHO PLAYS line and step 3. The logs hold no address or PC name, and handing them over is Orb's choice |
| Private preview, never the public pin | Built only by this kit, and the public builds' guard refuses it |
| No flash number from it counts | It reads none |
| The words say the game opens a link | The first line, and the kit stops if it's gone |
| RL-204's privacy line stays out | The kit stops if the words hold it. The kit copies no README from the public package |
