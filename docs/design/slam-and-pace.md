# The stick's slam and readable launch speeds

Owner: Game Design. 2026-11-07, on Orb's midday play (the end of `docs/ep/vision.md`; `homework/Files/orb-first-play-20261107-1229.json`):
- "tried to slam my opponent into the ground with the right stick, didn't seem to want to give me the mega slam I was expecting"
- "speed of the fighters still a little bit confusing, high speed launches are cool but a little too fast"

First values, as data. Unplayed.

## 1. The slam: a full stick charge sends, in its direction

**What Orb did.** In that match, Orb's right stick went down 19 times. Seven of those were holds of 0.75 to 2.4 s: Orb was charging a down strike and waiting for it to pay.

**Why it didn't slam.** By the rules as written:
- A charged stick strike never sends (`right-hand-attacks-rulings.md` §2).
- A full down charge stuns ×1.3 and carries 2.5 bh, with no crater (`stick-lands.md`'s direction table).
- The send was a second step: a B pressed and held inside the stun.

So the full hold Orb made gave a stun and a short drop, which is exactly what the rules said, and not what Orb expected. Orb asked for the stick to feel like platform brawlers' directional-charge strikes (2026-10-28), and those send.

**The ruling.** It overturns "the right stick never sends" (the stand-in's call in the physics packet, §9, and my §2) on Orb's own play. **The other half of that rule stays: only a full hold or a string's ender launches. A full stick hold is a full hold.**

| The stick strike | What it does |
| :--- | :--- |
| **A quick flick, or a hold short of his top stage** | As today: a stun, and the direction's carry. **Never a send,** so the brawl stays in your hands |
| **Held to his top stage** (`strikeStages`: 2 stages at base, up to 6 at maximum) | **A send, in the family of its direction,** at the share of a full B (1). The stick picks the family, and the director may bend it about 20° toward a dramatic target, as the physics packet rules |
| **Down, at his top stage, on a foe in the air** | **The slam:** he's driven down into the ground below, and the crater comes from the send's energy (`power-scale.md`). At base that's a small crater or a short trench, at maximum a crater 18 bh across that can bring down what stands round it, as Orb described |
| **Down, at his top stage, on a foe on the ground** | **Pounded in where he stands:** the crater opens under him and he's down in it, with no journey |
| **Up / toward / away, at his top stage** | **Skyward** (the meteor once the force threshold is met, as any launch), **across,** and **across behind you** |

- **B versus the stick, after this.** B is armoured, and the director stages its send. The stick is bare and aimed: a light takes its stun, a medium stops it in the first 28 ticks, and a dodge makes it miss. So it's aim against armour, and both are full holds.
- **This replaces two rules:** "level 3 sets up the send, the next B within the stun launches", and the meteor's ignition through B (`stick-lands.md`). The full hold sends by itself.
- **QA's rows:**
  - full stick holds landed, of those started: 15 to 40% (the existing row);
  - for a bot free to choose, neither the stick nor B is over 70% of sends;
  - slams leave a crater at every tier.

**Data** (`data/director/stick.json`):
```json
"fullSend": { "enabled": false, "atStage": "top", "share": 1.0, "bendDeg": 20,
  "families": { "down": "slamDown", "up": "skyward", "toward": "across", "away": "acrossBehind" },
  "downOnGround": "bury" }
```

**Who builds it:**
- **Encounter:** `stick.gd` (a top-stage landing launches), the families into the launch planner, and burying a grounded foe.
- **Simulation:** the send's energy and crater through `power.json`.
- **World:** the slam's crater, and whether the bowl brings down what's standing in it (already on `power-scale.md`'s list).
- **Camera:** the slam's shot.
- **Animation:** the hammer pose at the top stage.
- **Controls:** the top stage's haptic.
- **Tools:** a page row.
- **Legal:** RL-232 covers the craters, as now.

## 2. Launch speeds a player can read

**Most of "too fast" is a switch.** Orb's page had no `?power=1`, so the energy model was off. Every launch carried the old hidden sideways boost (×6, `TRAV_LAUNCH`), and free flight far from the rival carried its ×10. That's a median of about 10,800 a second on screen. The physics packet's fix takes the boost out, leaving ×2 along the line (4,000 at base, 14,000 at maximum), and flat out drops to 5,000 at base. It's built, but it wasn't in the build Orb played. **Step 1: the energy model on in the next build** (Simulation's setup key and Tools' page, on by default).

**Then the readability budget, as data.** The launch speed (energy) still decides the crater, the buildings, the trail and how far he goes. **The pace is only how fast that's shown,** as the meteor's curve already is. The ends below change timing, not path or energy.

| | First value | Why |
| :--- | :--- | :--- |
| **Pace along the line** | **×2 of the launch speed** (`launchTravel`), **capped at 9,000 a second on screen** for ordinary sends | Camera follows softly to about 7,000 and can't past 10,000. Orb tries ×1.25 to ×2 from a page slider (`?travel=`) in the next play, and their hands pick it. Lever: 1.5, then 1.25 |
| **The held moment on the hit** | **14 ticks for a lit launcher, up to 18 for a full send,** by share. A launch's held moment isn't cut by the freeze budget | The eye catches the start, and the camera gets its head start (Camera asked for 14 to 18) |
| **Slow-in** | He leaves at **40% of his pace, easing to full over 10 ticks** | Hit, then he goes: the direction reads |
| **Slow-out** | The last **10 ticks** before he hits something ease **from full to 50%** of his pace. The impact still spends the full energy | You see where he lands before he lands |
| **The camera** | It knows the flight at the hit and leads it (the packet's published flight plan). **It holds the impact 30 ticks** at a readable size, then eases back to the fight within 1 s | Crater, dust and the fall read, then you're playing again |
| **Size floor** | A fighter is never under 0.06 of the screen's height in a launch, except the meteor's top, which `power-scale.md` §4 already allows for up to 2 s | Never a speck |
| **Flight time** | An ordinary send's cruise: a median of at most 1.5 s, and at most 3 s | Long enough to see, short enough to keep playing |

- **The meteor and the signature curves** keep their shapes and get the slow-in and slow-out. Their hold stays at most 2 s.
- **One family of speeds:** a sent body never outruns a flat-out flyer of his level on screen, so a chase can always catch him (`power-scale.md`).

**Data** (`data/fight/power.json`; `launchTravel` stays where it is):
```json
"readable": { "enabled": false, "paceCapPerSec": 9000, "heldTicks": [14, 18], "heldUncut": true,
  "slowIn": { "startShare": 0.4, "ticks": 10 }, "slowOut": { "ticks": 10, "endShare": 0.5 },
  "cameraHoldTicks": 30, "returnSec": 1.0, "sizeFloor": 0.06, "cruiseSec": { "median": 1.5, "max": 3.0 } }
```

**Who builds it:**
- **Simulation:** the model on by default, then the pace's cap and ends, deterministic, with the golden moving.
- **Encounter:** the held moment by share.
- **Camera:** the lead, the hold and the return. Most of it is built.
- **Tools:** the model on in the page, plus the `?travel=` slider.
- **Animation:** the launch pose through the slow-in.
- **VFX:** the trail reads the launch speed, not the pace.
- **QA:** cruise time, and how many launches stay under the cap.

**Read next:** Orb's next play with the model on, and the slider between ×1.25 and ×2.

## 3. The stand-in's combat-variety packet, checked (2026-11-07, `docs/ep/proposals/combat-variety-packet.html`)

**What it cites from me is right:** the 70% target on easy, the hold, the fold and the words in their order, run points of 1.5, the full hold's send and slam, the pace bands, the dodge exchange's fix, and the stick at 10 to 30% of blows. Corrections and its open asks:

| Packet | Ruling |
| :--- | :--- |
| **Wall kicks 1 to 4 a match** | That band is **with a human**. In AI play from a city start it's **0.2 to 2** (`rulings-2026-10-23.md` 11a), so the 0.26 it quotes is inside it. Ricochets 2 to 8 is right |
| **Orb's downs: 19 with 7 holds (mine) against 34 quick starts (Tools)** | They measure different things. **Mine is the raw stick:** how long it was off centre. **Tools' is the strikes the game started.** If both are right, Orb held and the game threw quick strikes, and the likely place is the air. **So a full hold must charge in the air too,** or the slam never comes where Orb reached for it. Tools settles it from the save, and Encounter checks that a hold above `airAbove` charges |
| **Launch-anywhere reads the piece's target region and its family** | **It reads the cell's class.** What a press is worth is the press's, and a variant only changes how it's delivered |
| **A family of pieces per stick direction, sharing one chamber** | **Yes,** inside the variant rule |
| **The dodger's own step-around still swaps sides: open** | **It stays.** It's his move and his choice, and you aren't locked or carried. The 0.3 s rule already stops a beam straight out of it |
| **"Hold to slam" once, on the first quick down flick that lands on someone in the air** | **Yes,** under the once-only hint rules, with the down charge's pulses and its top-stage haptic |
