# 2v2 over LAN: can Orb's two PCs do it?

Netcode, 2026-11-01, for Orb's spitball at the end of `docs/ep/vision.md`. It combines Simulation's, Game Design's, Camera's and Controls' notes. **Paper only: nothing was built, and nothing was run on either PC.** Every session count is a guess.

## The answer

**Yes, it's feasible, but don't build it before launch work.** About 16 to 22 sessions in all, and only 2 or 3 of those are for LAN. The rest is teaching the game to run two fights at once, which launch's 2v2 needs anyway. So 2v2 belongs on the launch list, where it already is, and LAN comes cheaply after it. That fits Orb's own call that online waits until after launch.

- **The network is the easy part.** Two people on two PCs send only two players' buttons, however many fighters there are, because the computer's fighters run on both PCs and send nothing.
- **The hard part is two fights at once.** The game runs one exchange of blows at a time, and it has one clock, so one fight's hit-stop would freeze the other several times a second.
- **"Each player's own record of the planet" becomes each player's own opponent and camera,** on one shared planet with all four on one line. A true separate planet view per fight costs 6 to 10 more sessions, and nobody has worked out what happens when the two fights meet.
- **If Orb wants to feel something sooner:** a plain 1v1 between the two PCs, about 2 sessions and no fighter work. It answers the biggest network risk, below. I'd still wait until the arena and the pad are in Orb's hands.

## Who plays whom

| Setup | Network | Everything else |
| :--- | :--- | :--- |
| **Both humans against 2 computer fighters** | Two players' buttons | The computer fights without having to cooperate, and nobody loses to a teammate's lag |
| Each human with a computer partner, opposing | The same | A computer teammate that helps, and fairness between a fast PC and a slow one |

**Both humans together first** (Game Design agrees). The other then costs the network almost nothing.

## The smallest versions, smallest first

| Version | What it proves | Size |
| :--- | :--- | :--- |
| **1. Plain 1v1 between the two PCs** | The firewall step, the link, and that two different processors agree | About 2 sessions |
| **2. Both humans against 1 computer fighter** | Three fighters over the link, taking turns in one fight, on Encounter's waiting-their-turn work (parked). No second fight, no clock change | About 3 to 5 more, once that's landed |
| **3. Game Design's: both humans against 2 computer fighters** on a half-size planet, all four on one line, no pass, assists, revive or meteors | The real question: when your friend calls, do you drop your fight and fly? | The full job below |

A half-size planet is the older flat ring, because Orb's new turning planet only runs at full size. So version 3 **has no turning and doesn't show the 3D world.** Moving it to the full planet is a later step: there, the world turns by itself only when all four are close, since the turn slows to almost nothing while a fighter stands far away.

## The size

| Work | Who | Sessions |
| :--- | :--- | ---: |
| Rulings: the shared clock, and whether a blow can hit the other fight | Game Design | 1 |
| Two fights at once: `S.dirS.ex`, read 111 times in 26 files | Encounter | 3 to 5 (mine, Encounter hasn't sized it) |
| Each fight's own hit-stop, or a freeze only for big moments | Simulation | 2 to 3 (mine). **The biggest risk to how it feels** |
| Focus and the line, for four fighters | Simulation | 2 to 3 |
| The computer picks targets among two | Encounter | 1 (mine) |
| The D-pad, the extra input bits, a check that a claw grip gains nothing | Controls | 1 (mine) |
| Each player's camera, and only their own fight moves it | Camera | 1 |
| Drawing four fighters: 175 reads | Rendering | 2 to 3 (mine) |
| **LAN: starting a networked game, the firewall step, four-fighter checks** | **Netcode** | **2 to 3** |
| **Measuring it on the old PC** | Performance | 1 (mine) |

**Must land first, in order:**

1. The arena and the pad in Orb's hands.
2. World's fix for the table a rematch builds late, then a two-process comparison in my checks.
3. Launch ticks made cheaper (Performance).
4. The old PC's speed result.

## Focus

- **It mostly picks itself:** whoever you last hit, otherwise whoever's nearest in front of you. Being hit by someone new doesn't change it.
- **D-pad left and right switches it.** If the setting that makes the D-pad copy the right stick is on, it's Back instead.
- **Your screen:** your fight, framed by your own camera. A switch eases over about half a second, with no cut. Your friend is a small chip at the screen's edge when out of view, plus the map. Your friend's meteor never takes your camera.
- **On the network:** focus decides who your attacks close on, so both PCs must agree. It adds 3 bits to the right stick's word, which has 6 spare, so packets stay the same size. Replays and the state checks change with it.

## Rollback with four fighters

- **Input size: unchanged.** About 4 to 5 KB/s each way, nothing on a home network.
- **How often it rolls back: about never on a cable.** The game waits 2 ticks (33 ms) before using an input, and a home network delivers well inside that. Our LAN test row shows 0 rollbacks. Wi-Fi can break that for a moment.
- **Slow ticks are the catch.** If one PC stalls past 33 ms, its buttons arrive late and the other PC has to guess, then re-run those ticks. A launch tick costs 18 to 27 ms on the main PC today, and two can land together. Waiting 3 ticks (50 ms) covers most of it, and the game already chooses its wait from each PC's speed.

**The old PC's frame,** by arithmetic on older one-to-one figures. It assumes four fighters double a tick, which Simulation says is about right or a little high, and a 1.5 times slower PC, which is a guess.

| Frame | Cost, of 16.7 ms |
| :--- | ---: |
| Normal, no rollback | about 5 ms |
| Rolling back 3 ticks | about 23 ms: a visible hitch, but rare |

## What the old PC can run

i5 6600K, GTX 1080, 16 GB. **The graphics card is well above our budget** of an old laptop's built-in graphics. **The processor is the question,** because the game logic runs on one core, and two full fights are the costliest thing it could do. Its speed test hasn't reported, and four fighters can't be measured until two fights exist.

## Native or browser

**Native.** The native link (ENet) is built and tested between two programs in CI. The browser link isn't built, needs a go-between to connect, and is slower on the PC that can least afford it. The browser page won't even start from a plain LAN address.

## Setting it up with no surprises

**One known approval, once, on one PC. It can't be zero with native.** The PC that hosts waits on a port (`listen` in `net/enet_transport.gd`), which is what makes Windows ask, and it needs an Administrator's yes. The PC that joins only calls out (`dial`) and shouldn't be asked. **This is from reading the code. It hasn't been run,** because ENet stays off Orb's PC and CI has no Windows firewall.

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

**They've never played the same match.** Everything so far compared programs on one PC or in CI. The native and browser builds do match, which is a good sign, not proof. Simulation just found a table that a rematch builds late, which no single-program test can see. So the first LAN test is version 1, with the game's check numbers compared every second, so a mismatch gets reported rather than felt.

## Rest of Game Design's list

- **Far buildings breaking off-screen:** both PCs must run them, because the state has to match. Nothing can be skipped because one player can't see it.
- **A signature's pause and a finisher's camera:** the same problem as hit-stop. They can't stop the other fight, and the camera side is already separate per PC.

## For Orb, when it's time

1. **Does a fight need to turn its own world while the other fight is far away?** If yes, that's the 6 to 10 extra sessions, plus World's. Playing one line with four fighters is the cheapest way to find out, so it isn't a question for now.
2. **Who's the second player?** Legal's conditions for the old-PC test say Orb alone watches, so anyone else playing is a new question for Legal, through the EP.
