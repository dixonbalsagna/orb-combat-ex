# Controls audit: every input on the live pad map, run in real fights (Controls, 2026-11-01)

Orb's order: "the underlying mechanics and features of the controller layout fully fleshed out." This is the page the EP asked for first. **How it was run:** the real input hub into the real sim, on a copy of the EP's `s400` tree with Controls' work and every park applied (right stick, quick read and the rumble switches on), by `sim/input/tools/audit_probe.gd`. Three kinds of run: a **case table** (each input alone, a new match each, 90 ticks, a standing opponent at 80 or 250 units: 131 rows), a **defence run** (the AI attacks a pad player who does only one input, 600 ticks, 8 seeds, HP lost) and a **soak** (a mash bot against the AI, 6 seeds, 3,000 ticks). Plain words: a control is **working** if the fight changes the way the design says, **thin** if the press arrives but the fight cannot tell it from another press, and **not built** if the press reaches the game and nothing in the fight answers.

## Working in a real fight

| Control | What a real fight shows |
| :--- | :--- |
| **Left stick**, all directions | He moves: 287 units right or left, 244 up, 74 down in 40 ticks; up-right is both |
| **LT (dodge)**, with a direction | Throws a dodge in the stick's direction (785 units right, left or up); with no stick it does not travel (the dodge frames still start). Against the AI it cuts damage taken from 275 to 153 (stick away) or 220 (none) |
| **LB (guard)**, held or tapped | Held halves the damage taken (275 to 129); tapped every 20 ticks takes it to 153 |
| **X, Y, B taps** (martial) | A rush, a blow, a landing: X 9 damage, Y 21, B 52 on a standing foe. Far away (250 units) each lunges first |
| **X, Y, B held / mashed** | The launcher opens (X, Y), a launch plan (B), mashing builds a string: X mash 45, Y mash 70, B mash 103 damage in 48 ticks |
| **RB (mode)** | Toggles energy; with it X is a quick shot (14), Y a blast (25), B the signature beam (141, 32 ki) |
| **RT held (power)** | Charges: ki +20 in 40 ticks, state `charging` |
| **Right stick, quick flick** (no layer, LB, LT, LB+LT) | `stick_start`, `stick_hit`: a stunning strike, 21 damage; the sim reacts on the start tick; far away it lunges first; in the air it lands |
| **Right stick, hold** (the charge ladder) | Rises through levels (hold 40: 37 damage, hold 70: 47) with the three rumble pulses on the rungs; stays held until released |
| **Right stick in energy** (RB, or LT+RB the kite) | The energy strike: a blast, 28 damage; held, it fires the beam |
| **Right stick, mashed** (8 flicks in 48 ticks) | 86 damage, one strike after another |
| **The law** (X then stick, stick then X) | Both orders resolve to the same strike and the same damage (30), no free double |
| **Right stick on RT and on the lay (LB+RB)** | Nothing, as designed (inert) |
| **D-pad (mirror off)**, **Start**, **Back** | Nothing in the fight, as designed (D-pad is the stick's mirror when it is on; Start and Back are the pause and hints) |

## Wired but thin

| Control | What is thin |
| :--- | :--- |
| **The four stick directions** | Up, down, toward and away give the same damage, the same events and the same ki (21.4, one `stick_start`, one `stick_hit`). The direction reaches the director (`rsDir`) and the cue names it, but no piece or effect differs yet. Combat's stick pieces are generic until their waves go live |
| **Stick strike in a real fight** | In the mash-bot soak (6 seeds), 56 stick requests became only 23 director strikes (41%): the rest are swallowed by a busy exchange, a stun or a hit-stop with **no feedback** to the player |
| **LB / LT stances on X and Y** | The same blow as no stance against a standing foe. Whatever the stances change shows only against a reacting foe, which I did not isolate |
| **Transform chord (LT + RT)** | Also throws a dodge on LT's press (a dodge tick every time), and nothing else unless a form is ready |
| **A (context)** | Does nothing with no context on offer |
| **Right stick held in energy at 70 ticks** | Spends ki (-37) but no `beam_fire` event inside 90 ticks: the beam fires on release, so it is real, but I could not see it land in the window. Worth a look by the beam owner |

## Not built: the press arrives in the input layer and the sim does not answer

| Control | Where it stops |
| :--- | :--- |
| **Brace** (LB + a left flick, or the L3 button) | The intent carries `brace` and its direction (215 times in the soak) and nothing in the sim reads it. In the real-fight defence run, LB + flick every 40 ticks takes 132 damage, the same as holding LB alone (129); the L3 button alone takes 310, no better than doing nothing (275). Encounter's README lists "brace and vanish" as not done |
| **Vanish** (LB + LT together) | The intent carries `escape` with the stick vector; the sim only throws the dodge. 242 damage taken in the defence run, the dodge's own effect |
| **Escape (R3)** | Freed by design while the right stick is on; nothing else answers `escape` |
| **Power specials** (RT held, then X, Y or A) | The intent carries `special1` to `special3`; nothing happens at tier 1 even after a full charge (60 ticks). Only the interruption table reads them |
| **The Driver** (RB + B held) | B in energy is the signature beam; the Driver of the energy rulings is not in the sim |
| **The stick's aim** (`rsAim`, the beam sweep) | Not read by anything; a beam cannot be swept |
| **Snap or push, trigger depth, pumping, focus, call** | Pitches or rulings, none built |

## The gaps, biggest first (my next work)

1. **Brace and vanish in the sim.** Two of the three left-hand upgrades do nothing in a fight. They are Encounter's to read; I can give them the exact reads and a test that names the result. This is the largest hole in "the left hand survives".
2. **Feedback for a swallowed stick request** (59% in the soak): a short refusal cue on the stick's pad (the same pad cue the press-ack uses), so a press that cannot start says so. Mine to design with Audio and Animation.
3. **Power specials (RT + X / Y / A)** and the **Driver**: decide, with Game Design, whether they are for this build.
4. **The four stick directions** need different results: Combat's pieces, then my direction table checked against them.
5. **The beam sweep** (`rsAim`) and **Loaded**: the input is ready.

Re-run: `godot --headless --path . --script res://sim/input/tools/audit_probe.gd` (the case table), with `--defence` (HP lost against the AI) or `--soak` (the mash bot). Use a scratch tree with the right-hand work applied.

## Added 2026-11-01 (after the first round)

- **GD's row 42, a far tap after a send** (`row42_probe.gd`). A far tap with no send before it is the taunt (`taunt_start`, no flight) on X, Y and B alike: as ruled. After a heavy launch the idle dummy was sent only 321 units (about 4 body heights), so the far band (past 12.5) cannot be reached by a real send at tier 1 in this test. With the rival put 3,000 units away right after the launch (a stand-in), a far tap **flew in and struck** on X, Y and B at 18, 60, 120 and 180 ticks after the launch, not a taunt. So either the director already lets a far press fly in some state a launch leaves, or the stand-in keeps a launched state a real far send would not. It needs a real far send to settle (the meteor, or a tier 4 power send). **From Encounter** I need only one thing: what state makes a far tap fly today, and a hashed per-fighter "sent at" tick if the 2.5 s window is to be read, since the input layer sends the same X edge in both cases (and reads nothing of the sim).
- **First-press ruling (`docs/design/pad-first-press.md`) against the audit.** Brace: L3 is unbound again (the default I added is removed: `data/input/layouts.json`, `strike_hub_test`), no hint. R3 Escape: already unbound on the right-hand layout (the switch frees it). RT + X / Y / A: new switch `switches.specialsOff` (parked): a press is the plain blow of its base button and the charge drops (tested). The refusal cue: built, parked (`hapticRefused`). The vanish stays as it is for now, off the first press by the EP's word.
- **The pad sheet (`docs/tools/pad-steps.md`)** promised the brace, the vanish, the transform chord, the specials, the beam steer and the grab; each is now removed or marked as not yet, and the four stick directions are said to land the same blow for now.
