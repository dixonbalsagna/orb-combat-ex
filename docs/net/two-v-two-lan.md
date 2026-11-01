# 2v2 over LAN: can Orb's two PCs do it?

Netcode, 2026-11-01. It combines Simulation's, Game Design's, Camera's and Controls' notes. **Updated for Orb's order of 2026-11-01, which makes LAN co-op a live direction:** "aggressively tune the structure of the project towards a co-op experience that can be played over a local area network". The arena and the pad still come first. Nobody has played any of this, and every session count is a guess.

## The answer

**Yes, it's feasible, on the full globe: about 18 to 24 sessions (Simulation's `docs/architecture/two-v-two-globe.md`), and only about 2 of those are still for the network.** The rest is teaching the game to run two fights at once. This replaces my earlier "don't build it before launch work".

- **The network is the easy part.** Two people on two PCs send only two players' buttons, however many fighters there are, because the computer's fighters run on both PCs and send nothing.
- **The hard part is two fights at once.** The game runs one exchange of blows at a time, and it has one clock, so one fight's hit-stop would freeze the other several times a second.
- **"Each player's own record of the planet" becomes each player's own opponent and camera,** on one shared planet with all four on one line. The world turns while the pairs are close and rests while they're apart, which in Simulation's stand-in is about four-fifths of the time.
- **Two pieces are ready to use now:** a check that the two PCs' processors agree, with no network (`docs/net/two-pc-check.md`), and a plain 1v1 between them that's built but has never run (`docs/net/lan-v1.md`). The firewall click needs Orb's real yes.

## Who plays whom

| Setup | Network | Everything else |
| :--- | :--- | :--- |
| **Both humans against 2 computer fighters** | Two players' buttons | The computer fights without having to cooperate, and nobody loses to a teammate's lag |
| Each human with a computer partner, opposing | The same | A computer teammate that helps, and fairness between a fast PC and a slow one |

**Both humans together first** (Game Design agrees). The other then costs the network almost nothing.

## The steps, smallest first

| Step | What it proves | Size |
| :--- | :--- | :--- |
| **0. The two-PC check, no network** | That two different processors play the same match. No firewall | **Built.** Goes in the old PC's one-click test |
| **1. Plain 1v1 between the two PCs, on the globe** | The firewall step, the link, the feel | **Built, not run.** Waits for step 0 and Orb's yes |
| **2. Both humans against 1 computer fighter, on the globe** | Three fighters over the link, taking turns in one fight, on Encounter's waiting-their-turn work (parked). No second fight, no clock change | About 3 to 5 more, once that's landed |
| **3. Both humans against 2 computer fighters, on the full globe,** Game Design's smallest version: all four on one line with no turning while apart, focus that picks itself with the D-pad to override, rescue by flying in, each fight's own hit-stop, the map and the plate. No assists, revive, pass or meteor | The real question: when your friend calls, do you drop your fight and fly? And is that the best moment of the match? | The full job below |

**The half-size flat ring is gone from these,** by Simulation's sizing: the globe adds only 1 or 2 sessions, and a rescue halfway round is about 5 or 6 seconds flat out, so it needs no shorter road.

**Game Design's rulings that reach the network (`docs/design/two-v-two.md`):** each fight's hit-stop holds only its own fighters, and each fighter's held ticks are saved and compared, so the check numbers read them. A 1v1 keeps today's whole-game hold, so step 1 doesn't change. NetLan's rule for keeping a press back during a freeze then has to read the local fighter's hold. Any blow can reach any enemy and never a partner, which is all sim. If the fights never meet, this is two 1v1s, and QA watches for that.

**What the globe changes for the network:**

- **The wire doesn't change.** Whether a turn may run is worked out from the fighters' places, which both PCs already agree on. The turn itself is already in the check numbers.
- **The "apart" rule can flip on a rollback.** A late input can move a fighter across the line where turns rest, so a turn starts or stops on one timeline and not the other. The limit on how far a correction can move already covers that, but `swing_check` needs a row for it, with four fighters.
- **Both PCs do all the work, wherever their player is.** The state has to match, so neither can skip the far fight's ground or buildings. Two launches landing on cold ground is the worst tick, and it hits the old PC hardest.
- **Saves stay cheap so far.** The two-PC check reads about 0.45 ms to save or restore on the globe here, well under the older figure. But that's before buildings at every place land, so read it again then.
- **The bent line, Simulation's idea if Orb misses the turning,** needs nothing from me now: the check numbers follow the line's fields by name.

## The size

| Work | Who | Sessions |
| :--- | :--- | ---: |
| Rulings: the shared clock, and whether a blow can hit the other fight | Game Design | Done, first values |
| Two fights at once: `S.dirS.ex`, read 111 times in 26 files | Encounter | 3 to 5 (mine, Encounter hasn't sized it) |
| Each fight's own hit-stop, or a freeze only for big moments | Simulation | 2 to 3 (mine). **The biggest risk to how it feels** |
| Focus and the line, for four fighters | Simulation | 2 to 3 |
| The computer picks targets among two | Encounter | 1 (mine) |
| The D-pad, the extra input bits, a check that a claw grip gains nothing | Controls | 1 (mine) |
| Each player's camera, and only their own fight moves it | Camera | 1 |
| Drawing four fighters: 175 reads | Rendering | 2 to 3 (mine) |
| The swing's sites and the rule for when turns rest, on the globe | Simulation | 1 to 2 (Simulation's) |
| **LAN: the rest, past step 1: the other player isn't "1 minus me", computer-played slots from the first tick, four-fighter checks, the "apart" row** | **Netcode** | **About 2** |
| **Measuring it on the old PC** | Performance | 1 (mine) |

**Must land first, in order:**

1. The arena and the pad in Orb's hands.
2. World's fix for the table a rematch builds late, with `fork_check` in CI.
3. The two-PC check's result, on both PCs. If they disagree, everything else here waits.
4. Launch ticks made cheaper (Performance).

## Focus

- **It mostly picks itself:** whoever you last hit, otherwise whoever's nearest in front of you. Being hit by someone new doesn't change it.
- **D-pad left and right switches it.** If the setting that makes the D-pad copy the right stick is on, it's Back instead.
- **Your screen:** your fight, framed by your own camera. A switch eases over about half a second, with no cut. Your friend is a small chip at the screen's edge when out of view, plus the map. Your friend's meteor never takes your camera.
- **On the network:** focus decides who your attacks close on, so both PCs must agree. It adds 3 bits to the right stick's word, which has 6 spare, so packets stay the same size. Replays and the state checks change with it.

## Rollback with four fighters

- **Input size: unchanged.** About 4 to 5 KB/s each way, nothing on a home network.
- **How often it rolls back: about never on a cable.** The game waits 2 ticks (33 ms) before using an input, and a home network delivers well inside that. Our LAN test row shows 0 rollbacks. Wi-Fi can break that for a moment.
- **Slow ticks are the catch.** If one PC stalls past 33 ms, its buttons arrive late and the other PC has to guess, then re-run those ticks. A launch tick costs 18 to 27 ms on the main PC today, and two can land together. Waiting 3 ticks (50 ms) covers most of it, but the game won't choose that by itself: on a LAN its chooser always says 2, because it reads the link's ping and not slow ticks. So LAN version 1 has a shortcut with the longer wait, for Orb to compare by playing.

**The old PC's frame,** by arithmetic. It uses the two-PC check's readings on this PC, on the globe, on a busy machine: a tick of about 1.2 ms and a save or restore of about 0.45 ms. It assumes four fighters double a tick and a 1.5 times slower PC, which is a guess.

| Frame | Cost, of 16.7 ms |
| :--- | ---: |
| Normal, no rollback | about 4 ms |
| Rolling back 3 ticks | about 18 ms: a visible hitch, but rare |

The worst single ticks in that run took 43 to 80 ms here. Those are the hitches that could cause a rollback, and they're Performance's list. **The old PC's own report will replace the guess,** as it holds `tick_ms` and `snapshot_ms`.

## What the old PC can run

i5 6600K, GTX 1080, 16 GB. **The graphics card is well above our budget** of an old laptop's built-in graphics. **The processor is the question,** because the game logic runs on one core, and two full fights are the costliest thing it could do. Its speed test hasn't reported, and four fighters can't be measured until two fights exist. Each player's camera costs the same as in a 1v1.

## Native or browser

**Native.** The native link (ENet) is built and tested between two programs in CI. The browser link isn't built, needs a go-between to connect, and is slower on the PC that can least afford it. The browser page won't even start from a plain LAN address.

## Setting it up with no surprises

**Built: `docs/net/lan-v1.md` has the scripts and the exact words Orb reads. One known approval, once, on one PC. It can't be zero with native.** The PC that hosts waits on a port (`listen` in `net/enet_transport.gd`), which is what makes Windows ask, and it needs an Administrator's yes. The PC that joins only calls out (`dial`) and shouldn't be asked. **This is from reading the code. It hasn't been run,** because ENet stays off Orb's PC and CI has no Windows firewall.

1. **The main PC hosts, always.** Its network is classed Public, and ZeroTier is on it too.
2. **One small script, run once, adds the rule.** Orb's told first and clicks yes once. It allows only the game, one port and addresses from `10.0.0.x`, so ZeroTier members can't reach it. Whether that rule stops Windows asking is untested, so the first try needs Orb warned.
3. **Two shortcuts, no menu:** Host on the main PC, Join on the old PC with the address already in it. A real menu is UI's job later.
4. **The same build on both.** The game already refuses a different version or different data.

A guest network or "client isolation" Wi-Fi between the PCs would block it.

## What hardcodes two fighters

| Where | Count | How bad |
| :--- | ---: | :--- |
| The one running exchange, `S.dirS.ex` | 111 reads in 26 files | **The heart of the job** |
| `fighters[0]`, `fighters[1]` in `sim/` | 39 | Each needs a look |
| "My opponent", `SimRoster.opp` | 64 | One function, so focus is one change, plus a read of each caller |
| `range(2)` in `sim/` | 15, and 24 in input, mostly fine | Small |
| Drawing | 175 | A big job of its own |
| Camera's direct reads | 109 | Mechanical, a thin layer |
| Sound | 11 | Small |
| **`net/`** | **4 lines** | `host.gd` assumes the other player is "1 minus me", and `desync.gd`'s report defaults to two computer-player flags. The session already takes any number of slots and has a computer-played slot, though starting one from the first tick is unproven |

A match can already hold 5 bodies, but as one fight with bystanders, not two fights.

## The network's real risk: two different processors

**They've never played the same match.** Everything so far compared programs on one PC or in CI. The native and browser builds do match, which is a good sign, not proof. So step 0 comes before any link: the same match on each PC, with the two files compared. Simulation also found a table a rematch builds late, which is `fork_check`'s job, not step 0's. Step 1 then compares the check numbers every second, so a mismatch gets reported rather than felt.

## Rest of Game Design's list

- **Far buildings breaking off-screen:** both PCs must run them, because the state has to match. Nothing can be skipped because one player can't see it.
- **A signature's pause and a finisher's camera:** the same problem as hit-stop. They can't stop the other fight, and the camera side is already separate per PC.

## For Orb, when it's time

1. **Does a fight need to turn its own world while the other fight is far away?** If yes, that's the 6 to 10 extra sessions, plus World's. Playing one line with four fighters is the cheapest way to find out, so it isn't a question for now.
2. **Who's the second player?** Legal's RL-230 clears step 1 for Orb alone, on both PCs. A second person has to be named to Legal first, who rules on that name. Likely yes for one named adult at Orb's home, on Orb's own network, told beforehand.
