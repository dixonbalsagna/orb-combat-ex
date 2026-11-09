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

## After the first 2v2 together (2026-11-07)

Orb's first real 2v2 together stuttered in bursts, and for a stretch the old PC seemed to show the main PC's fight. The logs said the old PC dropped real time in heavy late-match moments (frames past the game loop's 100 ms catch-up), the main PC waited for it and then rolled back 16 to 20 ticks, and a 20-tick rollback of two fights costs about 45 ms on the main PC. So, in `net/lan.gd`:

| What | Why |
| :--- | :--- |
| A PC runs at most 8 ticks past what the other has confirmed (`LAN_AHEAD`; 20 elsewhere) | On a LAN, past 133 ms the other PC has stalled, not the link. Holding costs less than re-running 20 ticks afterwards: a rollback's worst drops from 20 ticks to 8, its mean cost from 45 ms to 19 |
| Time sync waits a frame or two at a time, deciding every 10 frames (`SYNC_MAX_WAIT`, `SYNC_EVERY`; 8 and 30 elsewhere) | Catching up is a skipped tick, not a visible hold |
| A snapshot every second predicted tick (`SAVE_EVERY`; every tick elsewhere) | A re-run tick is its step and half a save |
| Every ten seconds the log says how the frames went: the worst, those over 50 and 100 ms, the ticks the game loop dropped, the most re-run in one frame, time sync's waits, the stalls | The next test says which PC hitches, and whether it's the picture, the sim or a rollback |
| S holds this PC's fight before every tick, through a pause, and at the end of every frame (`view()`, which the kit's `SimHost.advance` calls). Every change of the view, and S ever found holding another fight at the start of a tick, gets a line in the log with the tick and why | A pause's rollback re-runs ticks, and a step leaves fight 0 in S: until now a PC paused while the other's late inputs arrived showed fight 0. The log will say if anything else ever does |
| A PC whose player is out shows his partner's fight 2 sim ticks after the tick on which his fight's KO clock first reads 1.8 (`PARTNER_AT`, from Camera's `CamParams.WRECK_AT` in the game, and `PARTNER_TICKS`). That clock runs slowed through the KO's slow motion | The camera's KO close-up plays out on his own fight first (Camera's rule) |

None of it changes what the sim does or the packets: only when a PC waits, what a rollback costs and what it shows.

**The link hardened (the audit's CD-10, finding F-10).** The other PC could freeze or exhaust this one, and a gone PC froze the match:

| What | Where |
| :--- | :--- |
| A peer asking for an input wait past 8 ticks fails the handshake: the title says "Couldn't start" and why (the wait sizes the session's first inputs) | `NetHandshake.MAX_DELAY` |
| Every game packet is checked before anything in it is used: its fields of the right kinds, at most 128 inputs from a tick no more than 240 past this PC's frame, takeovers of a real slot at a tick not already final, at most 16 checkpoints. One that fails is dropped whole and counted | `NetHost.valid`, `rejected` |
| When the link closes, or nothing comes from the other PC for 8 s, the computer plays its seat from the next untaken tick (`NetSession.dropSlot`) and the match goes on. The title says "The other PC has gone: the computer plays its fighter", the log gets a line, and the game shows a banner, THE OTHER PC HAS GONE, then THE COMPUTER PLAYS ITS FIGHTER, now and again for 15 s | `NetLan._checkDrop`, `_notice` |
| With two fights, a takeover hands over the player's body where it is now (slot 2 for the old PC's player), not the session's index | `NetSession._switch` |

`lan_check` plays a hostile second PC through the codec (a hello asking for 100,000 ticks, one packet handing slot 200 to the AI, a flood of inputs far ahead) and a gone one, with a negative control for each. Before any internet play: encryption (ENet DTLS) and a security review (CD-10, not in this).

**The energy model (Sunday's play-test, 2026-11-08).** Only the page turned the energy model on, through its setup word, so the LAN round played the old launches and flight. NetLan's three setups (`SETUP`, `SETUP2`, `SETUP2X`) now carry `"power": true`, the page's `"travel": 1.5` and `"dash": true` (Simulation's power-dash: the dash at any range; a sim without it ignores the word); the data stays off. Both PCs read the same setup and the match key holds it. `rollback_check` and `desync_check` gain a `lan` setup (the 1v1 exactly), and their `fights2` and `together` setups are NetLan's own, so they play it too.

## Saved matches and reports (2026-11-08, after Orb's lost seed-77 match)

Each PC saves the match as `lan-<commit8>-<main|old>-<yyyymmdd-hhmmss>-<reason>.json` in `saved\` beside the game (the build's commit in the name, so files from different builds never mix): at "The match is over", on entering each pause, when the window closes (the kit's hook in `main.gd`), and on a report (F9, or View + RB on a pad, or UI's panel calling `NetLan.report(tag, note)`). `--lan-save=DIR` moves the folder; `--lan-save-at=T` saves once at tick T (tests).

| Field | What it holds |
| :--- | :--- |
| `kind`, `pc`, `slot`, `mode`, `build`, `reason`, `savedAt`, `tick` | `orb-lan-match`; main or old; the player's starting slot; 1v1, 2v2 or 2v2-together; the exe's `build_info.json`; over, pause, quit, report or test; the local time; the session's frame |
| `marks` | every report this match: `{tick, kind: "report", tag, note, at}`, as the page's black box marks |
| `frames` | `slow`: [tick, ms] of every frame over 50 ms; `rollbacks`: [frame, depth] of every rollback |
| `net` | delay, rollbacks, deepest, checks matched, round trip, packets dropped by the checks, the tick a gone PC's seat went to the computer |
| `replay` | SimReplay (`meridian-replay`, v4): every player's confirmed inputs to `finalTo`, the toggles (a dropped seat on its sim slot), SimHash's gameplay hash at each final checkpoint (every 60 ticks; `NetSession.hashChecks`), and the final hash when the confirmed tick is the present (on a LAN, most of the time) |

It plays back through the project's own replay path: `node tools/preview/blackbox-verify.mjs <file> --tree <the LAN folder>	ree` (the folder's tree is the page's). `lan_check` proves both PCs' files play back (1v1, 2v2 together, a dropped seat), with negative controls for a changed input and a toggle on the wrong body.

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
| `Host 2v2 together (main PC).cmd`, `Join 2v2 together (old PC).cmd` | The same, a team: hits across the fights and Encounter's blows from outside on, the partner's fight not drawn. Both PCs must use them | Each PC |
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

**Known rough edges, all in the words:** one match only, no rematch; a pause holds the other PC, which says so, and the link stays up; a lost link just stops. In 2v2 the other fight isn't drawn; together, it can still reach you. The first try's log gives real ping and rollback numbers.

## Legal's terms (RL-230, RL-241, RL-249, RL-253)

**Orb and Orb 2, one on each PC (RL-253).** Orb 2, the old PC's player, stands where Orb stands for private builds and tests, on Orb's ruling; no real name is recorded anywhere. Each reads the flashing-effects warning on their own PC, either may stop at any moment, and any report of a symptom stops the tests and goes to Legal through the EP. A third person is a new name for Legal.

| Term | Where it's met |
| :--- | :--- |
| The warning before play on both PCs, not bypassed | The game's own start menu carries it, and the shortcuts pass no skip word. `--lan-loop` skips the menu only with no window. Asked of the game's own rule on the kit's tree, for all three shortcuts: locked, no bypass, the warning shows. **Nobody has seen it in a window** |
| Reduce flashing locked on | `desktop-package lock`, and the kit stops if the flag isn't on or the capture hook is |
| Orb and Orb 2, one on each PC, nobody else in either room (RL-253) | The WHO PLAYS line, verbatim, and the kit stops if it isn't |
| Each reads the warning on their own PC and either may stop (RL-253 (2), (3)) | Step 5 of the words |
| RL-241's sentence for two fights | In WHO PLAYS. The kit stops without it, and the 2v2 shortcuts go in only with it |
| RL-249's sentence for 2v2 together, the partner's fight not drawn | In WHO PLAYS. The kit stops without it. The together shortcuts don't pass `--others` |
| RL-249: the beam warning from the other fight (`beam_warn`) steady, thin, a 6-tick ramp (RL-227) | UI's and VFX's: the edge alert that shows it |
| Home network only, the /24 filter, no ZeroTier | The kit stops unless the address is this PC's own, on a real adapter. The rule allows that /24 only, and the host also refuses any other address itself (`NetEnetTransport.allowPrefix`). **The filter's rule is tested, but not over a real link** |
| The firewall rule removed afterwards | Step 8, "do this every time" |
| Nothing recorded or shared, the kit and address stay on Orb's PCs | The WHO PLAYS line and step 3. The logs hold no address or PC name, and handing them over is Orb's choice |
| Private preview, never the public pin | Built only by this kit, and the public builds' guard refuses it |
| No flash number from it counts | It reads none. **When either PC draws the other fight, RL-241 wants both fights' light counted together on one screen, and the 2v2 flash clips run, before anyone but Orb sees it** |
| The words say the game opens a link | The first line, and the kit stops if it's gone |
| RL-204's privacy line stays out | The kit stops if the words hold it. The kit copies no README from the public package |
