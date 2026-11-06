# LAN test, version 1: a match between two PCs

Netcode, 2026-11-01. **Ready, not started. It has never connected two programs, and it must not be run until Orb says so,** because the firewall step needs Orb's real yes.

## What it is

One fight on the globe (planet 7, `planetGen` 3), one player on each PC, over the native link. Or, with the 2v2 shortcuts, two fights on one globe, a player in each against the computer (`docs/net/two-v-two-lan.md`). It's a private build only.

- **`net/lan.gd`, `NetLan`:** the game's own loop steps the sim through a `NetHost`, and the local pad is the host's bot. The window's title says "Waiting for the other PC", "Connected" or what went wrong. A log (ping, step counts) goes next to the game.
  - **Either PC can start first, however long apart.** The PC that joins calls again every 3 seconds until it's answered, because ENet gives up on a single call.
  - **Each PC's pad is its own fighter's slot.** The old PC plays the second fighter, so its pad is the hub's second slot, and its rumble and a struggle's stick follow that fighter.
  - **The camera treats this PC's player as the human,** so their pane is the bigger one, as against the computer (Camera's split share, 0.7).
  - **A pad leaving can't hand a fighter to the AI** on one PC only, which would part the two PCs.
  - **`--lan-2v2`:** each PC keeps its own fight in the state between ticks, so to the game it's a 1v1 against the computer. The step puts fight 0 in place itself (Simulation's cross-fights), and after a trade the PC follows its player into the fight he's in.
- **`net/session.gd`:** `presentOut` keeps a new tick's feed and fx for the game to draw and drops a re-run's. `slotOf` maps the players to slots 0 and 2 in two fights. Off, as on main, nothing changes.
- **`net/enet_transport.gd`:** an optional filter on who may connect, and `redial`. Off, as everywhere but here, nothing changes.
- **`net/tools/lan_kit.mjs`:** makes the folder from a scratch copy. It refuses a tree with a `.git`.
- **`net/tools/lan_words.txt`:** what Orb reads first, which becomes `READ ME FIRST.txt`.

**The public builds don't change.** They exclude `net/`, and `tools/desktop-package.mjs routes` refuses otherwise (Legal RL-204). So the kit patches the game's calls into its scratch copy: `render/core/sim_host.gd` (3 edits), `render/core/main.gd` (6), the meteor trail's page word in `render/vfx/meteor.gd` (1, if it's there), and `export_presets.cfg`'s exclude becomes `net/tools/*`. It stops if a line no longer fits. It also locks Reduce flashing on, as the desktop builds do. **It fits both main and the tree Tools' stack exports for a kept build,** whose host steps through the black box's `_bb_step`.

**So `export_presets.cfg` on main must keep `net/*` out.** `tools/desktop-package.mjs routes` on the kit's patched tree fails with exactly that. Having the network code in costs about 80 KB of the 119 MB build. When LAN becomes a real feature, this needs Rendering's and Legal's proper version.

## The input wait

**On a LAN the wait is always 2 ticks (33 ms), whatever the PC's speed.** `NetDelay.choose` only raises it to shorten rollbacks it expects from the link's ping, and a LAN's ping predicts none. It can't see a slow tick. So `--lan-delay=N` sets a floor, on `Host` or `Join`. The larger proposal wins, so one PC asking is enough, and the window's title says what was agreed.

## A press and a freeze

A press lands 2 ticks later, and a frozen tick reads no input. So while the freeze lasts past the delay, `NetLan` sends the held controls only and keeps the press, as the hub already does offline. It goes once, when it can land. With two fights it reads this PC's own fight's freeze.

## Making the folder

```
node net/tools/lan_kit.mjs --tree=SCRATCH_COPY --out=FOLDER --godot=PATH\Godot_v4.7.2-stable_win64_console.exe --host-ip=10.0.0.135 --build=<name>
```

Build it on the main PC: the kit stops if the address isn't that PC's own. `10.0.0.135` comes from Performance's look on 2026-10-31.

**From a kept build:** the kept folder holds only `sim/`, `data/`, `net/` and `project.godot`. So the whole tree is made again with Tools' own stack code, with no Godot, from the kept commit. Then two checks show it's the build Orb played: those four parts byte for byte against the kept `tree/`, and every file in the folder's game against the kept page's `index.pck`, by the MD5 each package stores per file. Both scripts are kept in Netcode's scratch.

| File | What it does | Where |
| :--- | :--- | :--- |
| `READ ME FIRST.txt` | The steps | |
| `Allow through the firewall (main PC, once).cmd` | Adds one inbound rule, after Windows' one approval box: this game, UDP 47100, addresses in the host's /24 only, so ZeroTier members can't reach it | Main PC |
| `Host (main PC).cmd` | Starts the game, listening on that one address | Main PC |
| `Host with a longer wait (main PC).cmd` | The same, with `--lan-delay=3`, so Orb can compare by playing | Main PC |
| `Join (old PC).cmd` | Starts the game and calls the main PC. It asks for nothing | Old PC |
| `Host 2v2 (main PC).cmd`, `Join 2v2 (old PC).cmd` | Two fights, one on each PC, each against the computer | Each PC |
| `Remove the firewall rule (main PC, afterwards).cmd` | Takes the rule away, and any Windows added | Main PC |

## The folder of 2026-11-01, from the kept build 3d997381

**Same commit, the same 92 parks.** `sim/`, `data/`, `net/` and `project.godot` are byte for byte the kept tree's, but for the `.uid` files an import makes. Of the 1,287 files in the game's package, 1,268 have the kept page's MD5. The 19 that differ:

- **The kit's own:** `main`, `sim_host` and `meteor`, the three `net/` scripts, `build_info.json`, `features.json` (the lock), and the exported scenes and caches that follow from them.
- **UI's work since the page was made:** `ui_event_hub`, `ui_hints` and `terms.json`, saved between 23:10 and 23:18, after the page's 22:48. The wording changes ("LOST HIM" becomes "LOST SIGHT", a line under the brink), and the new hints sit behind UI's own switches. The stack takes UI's files from its working tree, so they can't be had as they were.
- **One Camera test file,** not part of play.

## Proof, and what's missing

No socket was opened, no firewall script was run, and `enet_check` wasn't run.

| Test | Result |
| :--- | :--- |
| Net checks on the stacked tree, every page switch on | `rollback_check` field, right stick, field with right stick and four fighters; `desync_check` field; `swing_check`; `two_pc_check`; `lan_check`: all pass. `word_check` fails one row, "off", because the page's switches are on. Not a LAN risk, as the stick is on |
| `lan_check`, two `NetLan`s over the loopback's links, a 12-tick freeze every 97 ticks, on lan and p120, one fight and two | Every press went exactly once (52 of 52 a peer). At most 2 landed on a frozen tick. No desync. Two fights: each PC's state holds its own fight between ticks, and each player's fighter acts |
| `lan_check --negative-control` | With the freeze rule off, 14 presses landed on frozen ticks. With output cleared, no fx reached the game. Two fights run with a PC's own fight in place: the checks part. No map of players to slots: the second player's fighter never acts. All caught |
| `rollback_check --setup=fights2` (players in slots 0 and 2), with the right stick | 6 sessions, 7,200 hash comparisons, 0 failures. Negative control 4 of 4 |
| `swing_check`'s apart rows | A late input crossed the line where turns rest 3 times on far, and the peers still equal the straight run. A body moved on one peer only parts them |
| **The kept build's folder, its game run headless** (`--lan-loop`, the other PC simulated in-process, no socket), as the main PC and as the old PC | lan: 0 rollbacks, every check matched. p120: hundreds of rollbacks, deepest 7, every check matched. No script errors |
| Both firewall scripts | They parse. **Never run** |
| `enet_check --late-host=40000` (the old PC started 40 s first) | Written for CI. **Never run here** |

**Not proven, and only Orb's first try can show these:**

1. **Whether the rule stops Windows' own box.** If the box appears anyway, the words say to click Allow access.
2. **The real link between two programs with `NetLan`.** `enet_check` covers the same transport with bots, in CI, on 127.0.0.1.
3. **The start menu, the warning and the pads in a real window.** Headless runs skip the menu, and nothing here has drawn a window.
4. **That calling again works over a real link.** It's written for CI and hasn't run there yet.

The two processors already agree: Performance's old PC test ran Netcode's two-PC check on both (`docs/perf/oldpc-result-2026-11-01.md`).

**Known rough edges, all in the words:** one match only, no rematch; pausing freezes the other PC; a lost link just stops. In 2v2 the other fight can't be seen or reached yet. The first try's log gives real ping and rollback numbers.

## Legal's terms (RL-230, RL-241)

**Orb alone, on both PCs.** A second person isn't covered: Orb names them first and Legal rules on that name. In 2v2, Orb plays one seat on each PC, or both.

| Term | Where it's met |
| :--- | :--- |
| The warning before play on both PCs, not bypassed | The game's own start menu carries it, and the shortcuts pass no skip word. `--lan-loop` skips the menu only with no window. Asked of the game's own rule on the kit's tree, for all three shortcuts: locked, no bypass, the warning shows. **Nobody has seen it in a window** |
| Reduce flashing locked on | `desktop-package lock`, and the kit stops if the flag isn't on or the capture hook is |
| Orb alone, nobody else in either room | The WHO PLAYS line, verbatim, and the kit stops if it isn't |
| RL-241's sentence for two fights | In WHO PLAYS. The kit stops without it, and the 2v2 shortcuts go in only with it |
| Home network only, the /24 filter, no ZeroTier | The kit stops unless the address is this PC's own, on a real adapter. The rule allows that /24 only, and the host also refuses any other address itself (`NetEnetTransport.allowPrefix`). **The filter's rule is tested, but not over a real link** |
| The firewall rule removed afterwards | Step 8, "do this every time" |
| Nothing recorded or shared, the kit and address stay on Orb's PCs | The WHO PLAYS line and step 3. The logs hold no address or PC name, and handing them over is Orb's choice |
| Private preview, never the public pin | Built only by this kit, and the public builds' guard refuses it |
| No flash number from it counts | It reads none. **When either PC draws the other fight, RL-241 wants both fights' light counted together on one screen, and the 2v2 flash clips run, before anyone but Orb sees it** |
| The words say the game opens a link | The first line, and the kit stops if it's gone |
| RL-204's privacy line stays out | The kit stops if the words hold it. The kit copies no README from the public package |
