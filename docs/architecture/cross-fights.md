# 2v2: hits across fights, the sim's part

Simulation, 2026-11-02, the EP's brief: blows, shots and beams across fights, replays of two fights, and the stage left as found between ticks. The rules are Game Design's "Hits across fights" in `docs/design/two-v-two.md`, on the fight swap (`fight-swap.md`). `sim/core/cross.gd`, `SimCross`. **Off on main:** `data/fight/cross.json` `enabled` false, or a setup's `"cross"`. It does nothing outside a `{"fights": 2}` match, so every other match is byte-identical.

## Who's who

**Teams are by the slot a body started in: 0 and 2 against 1 and 3,** which is how Netcode seats two players against the computer. A body keeps his team through a trade. **A hit can reach any enemy and never a partner.** With the switch on, a trade must be between partners, so each fight stays one of each team.

## The rule that holds it together

**Whatever reaches a body of another fight is met in his fight, on its clock and by its rules.** Nothing touches him from the fight it was thrown in. So:

- **A hit on someone held lands the tick his fight is free,** as Game Design ruled. It can't be dodged out of or broken into.
- **A hit holds only the fight it lands in.** The thrower's fight runs on.
- **A fight with a KO takes nothing more.**

## Shots from outside (Game Design's 3)

**A shot that meets an enemy of another fight goes over into his fight,** from the point where it met him, as a shot from outside: owner -1, and `from` names its shooter. His fight steps it from its next tick, and meets it with the same rules as its own shots. **Guard, dodge and the perfect block answer it, whoever fired it,** and a shot that hits a brawler mid-blow lands. It passes the shooter's partner, and trades with the enemy's shots as its team's. What a shooter does to his own rival with a shot stays his: a shot from outside makes no knock-back, driver landing or barrage.

**A shot fired across** (`SimCross.fireAt(S, A, kind, D)`, for Encounter's focus) is made in D's fight from the start, seeking him from A's chest, so his fight sees it coming and he can perfect-block it. A deflected shot from outside goes back the way it came, as the deflector's, and can come back over to the shooter.

**A shot inside another fight's beam is eaten:** a beam struggle stays two fighters.

**A shot from outside that meets a building or the ground is its shooter's there** (parked: `pending/outside-shots/`). His tier sets what it does, and he's its cause: the dead, his menace, his anguish and, with forms, his Witness are counted as for his own shot. `SimShots.outsider` hands him to World's blast, which reads him in place of a slot. **Open, for Game Design:** the fight it lands in counts those dead as someone else's (`anguishOther`), and an enemy's kills across fill nobody's Witness, since Witness fills from your own rival's kills. World's events name no slot for him (owner -1), as for anything a body of another fight causes. Before the fix, a building read the fight's last body by Godot's negative index, and the ground blasted nothing.

## Beams (Game Design's 4)

After each fight's tick, **each of its beams stops at the first enemy of another fight on its line, ahead of its own target, and passes the shooter's partner.** Whoever is first is named on the beam (`b.first`: his warning, from that moment; `SimCross.warned(S, f)` finds it). When the front reaches him he takes 230 through `SimDamage.hit`, less by his guard, with a 0.14 s hold, and the beam stops there (`b.stopAt`) and carves no further. In his dodge it passes him and goes on. An enemy past the beam's own target is never first.

## Blows and mines

**A blow** is Encounter's to throw: `SimCross.enemiesNear(S, f, reach)` lists the enemies in other fights within reach, nearest first, and `SimCross.strike(S, A, D, dmg, o)` sends it. It waits on the stage (`S.stage.mail`), addressed to him by his keys so it follows him through a trade, and lands at the start of his fight's next live tick through `SimDamage.hit`, by A's multipliers and D's stance then. **A mine** of one fight is set off by an enemy of the other and its blast reaches him the same way, less by his guard.

What's on its way is in the hash, the digest and a rollback's snapshot.

## Not mine

**Encounter's:**
1. **Who strikes across, and when:** focus, openings, one blow per opening a team, the whiff. Until then no blow crosses in a match, only shots, mines and beams.
2. **What a blow from outside does to the fight it lands in:** breaking a finisher, ending a string, no reel credit, "one stun a string" across a team. Until then it damages and holds, and the exchange runs on.
3. **A beam that stops on someone else:** its own target mustn't take the planned outcome, and the exchange it belongs to has to end. The struggle when the first enemy fires back. The warning's cue and the AI's answer to `b.first`.
4. **A shot fired across:** calling `fireAt` when focus is across.

**Rendering's:** drawing the other fight; a shot whose owner is -1 is its shooter's (`SimCross.shooter`), not the fight's last fighter's; a beam drawn only to `b.stopAt`.

## A match's own switches (co-op)

A setup can set both of these for its match, over the data's switches. They're read only in a match of two fights, so a 1v1 never sees them.
- **`"cross"`:** hits across fights, over `cross.json`'s `enabled` (`S.stage.cross`).
- **`"outside"`:** blows from outside, over `interrupts.json`'s `outside.enabled` (`S.stage.outside`: 1 on, 0 off, -1 the data's), parked in `pending/coop-switches/`. `DirOutside` reads it both where a blow starts and where it lands. It does nothing without hits across.

Neither is hashed: each is a constant of the setup, and replays and the LAN's handshake carry the setup.

## 2v2's time cap (parked: `pending/coop-switches/`)

**With hits across on, both fights reach the time cap and the ending's last event on the same tick.** They're `cross.json`'s `timeCapAt` (840, Game Design's 14:00) and `lastAt` (900: a 1v1's minute after the cap, a first value). Both are read on the stage's clock, `S.stage.clock`: the longer of the two fights' clocks as a tick starts (`SimStage.clockTick`). A fight that's held on that tick (a hit-stop or a pause) reaches them on its next live tick.

A 1v1, and two fights with hits across off, keep `finishers.json`'s 660 on each fight's own clock.

The clock isn't hashed: it's remade from the fights' clocks (which are hashed) at the start of every tick, before anything reads it, and a snapshot carries it.

## Holds, for Netcode

**There are no per-body holds yet.** A hold is its fight's (`dirS.stop`), and a hit from outside holds the fight it lands in. NetLan's freeze rule reads the hold of its player's fight. When Game Design's per-body hold is built, its field will be `Fighter.stop`, seconds left, as `dirS.stop` is for a fight.

## For the picture: a fight's events

**A fight's events (`out.fx`, and its feed) stay as its step left them until that fight's next tick.** The sim never clears, drains or reuses them in between:
- It clears fight i's list (i past 0) at the start of fight i's own next tick, and nowhere else.
- Each event is a new object.
- A step of one fight never touches another fight's list.

So a host can read `S.stage.fights[i].out.fx` any time between ticks without swapping the fight into S (Rendering's `SimHost.other_events()`).

- **Fight 0's list** is `S.out` between ticks, the host's to drain, as ever.
- **A rollback's restore gives every fight a new, empty list.** Lists aren't in a snapshot (`Fight`'s `SNAPSHOT` skips `out`), and the restore makes the stage and its fights anew. So a host must read `S.stage.fights[i].out` again after a restore, never through a list it kept from before.
- **Netcode's `NetSession._run` clears the lists** on a re-run tick, whose events were drawn the first time, and on a tick it doesn't present. On a new tick it presents, it keeps every fight's list for the picture, and clears only fight 0's from the last tick shown. `NetLan` clears nothing.

None of this touches the sim: it never reads another fight's list, and the lists aren't hashed.

## Between ticks

**The step puts fight 0 back itself,** and every walk of the fights (the hash, the digest, `trade`) leaves S holding whichever fight it found. So a host can hold its own player's fight between ticks and swap nothing back. `S.stage.cur` is still 0 after every step.

## Replays of two fights

The recorder and playback take every slot: four in a two-fight match, by place (fight i's pair are slots 2i and 2i + 1, as `SimCore.step` takes them). The header names `p3` and `p4`, and a toggle works on any slot. With the switch on, the replay's data hash folds in `cross.json`.

## Proof

`sim/core/tools/cross_check.gd`, verdict `CROSS: n check(s) failed`, and `--negative-control`.

- **A shot from outside lands exactly as the same shot from inside:** 13.00 by the plain rule, 13.83 clean, 4.69 guarded, 0 dodged, each the same to the bit. It goes over on one tick and lands on that fight's next, and passes a partner.
- A shot fired across is seen coming in his fight and perfect-blocked; it then goes wild, as `scatter` is on.
- On someone held, a shot lands on the first tick his fight is live.
- A beam hits the first enemy once and stops at him, 800.0 along; his guard takes some, his dodge lets it pass, a partner is passed, and an enemy past its own target isn't first. A shot inside it is eaten.
- A mine's blast; a blow, once, holding his fight and not the striker's; a partner refused; a blow following its body through a trade; a trade between teams refused.
- A rollback across hits and a shot on their way, by hash and digest. Holding fight 1 between ticks changes nothing, and the hash and digest leave it held.
- A replay of two fights, players in slots 0 and 2 with a toggle, reproduces, and fails without slot 2's entries.
- Two runs of four computer fighters together, one hash. With the fights apart, the switch on changes neither fight on any tick.
- The negative control loses what's sent, lands it twice, and loses a shot going over, and each is caught.

**Four computer fighters near each other sent nothing across** in 2,400 ticks, 833 of them within 2,000 units: their shots and beams find their own rivals first. Whether the fights touch in play is QA's row, with Encounter's blows from outside.
