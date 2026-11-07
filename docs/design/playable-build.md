# The playable build: rulings for Encounter

Owner: Game Design. 2026-11-06, ruling the stand-in's `docs/ep/proposals/controller-vision.md` (51ab2001), which builds on `beams-third-play.md`. **Every number is a first value, as data, and nothing is played.** The claw-law check on the LT take-back is Controls', and point 3 is Orb's to pick.

## 1. Flight strikes (the vision's section 2)

**One grammar: hold LT, point the left stick, press X, Y or B.** It replaces four systems: the zip, LT + X's step strike, LT + Y's hop or circle, and the stances' LT lane. The computer's own dodge exchange stays as it is.

### The twelve moves

**The bearing is read on the tick of the face press,** relative to the line to your opponent, from the left stick:

| Left stick at the press | Path | The blow lands | Where you end |
| :--- | :--- | :--- | :--- |
| **Under 0.5 (neutral)** | **Zip:** straight in, straight back | On arrival | Where you started |
| **Within 45° of toward** | **Line:** through him | As you pass | **1.5 bh past him, his other side.** The swap is yours |
| **Otherwise, up half** | **Arc over:** a loop over him, 1.3 bh above his head at the top | At the top of the loop | Behind him, 0.5 bh up |
| **Otherwise, down half** | **Arc under:** the same, below him. On the ground it's a low sweep round him | At the bottom | Behind him |
| **Within 45° of away** | **Parting shot:** in, the blow, out | On arrival | **Further out than you started:** 3 bh more, at least 6 bh from him, never over 12.5 |

| Button | The blow | Its tell | Worth | Hit-stop |
| :--- | :--- | ---: | :--- | :--- |
| **X** | Quick | 6 ticks | A medium's (2.5) | Medium (3) |
| **Y** | Heavy | 10 ticks | The zip heavy's (today's 132) | Heavy (8) |
| **B** | Biggest | 14 ticks | A tapped B: **a stagger,** by the one rule for B | Heavy (8) |

- **B in a flight strike is never a send.** A held B isn't read inside one, so the one rule for B stays true.
- **The range is from contact to 12.5 bh,** the middle band's edge. Past that, LT + a face button is what it is today (the long strike, the spike off a trail).
- **Travel time:** the tell, then the zip's existing floor, **at least 4 ticks and 3 bh a tick at most,** so it never teleports (RL-076). An arc adds its loop: **24 ticks for a full half-circle up close,** about the same at range, as the approach takes most of it.
- **All twelve are the same for every fighter.** A fighter's style changes only the look.

### LT's other jobs, and the take-back

- **LT alone does what it does today:** a tap and the left stick is the slip, the stick away up close is the dodge-cancel, and held while moving away is the escape stance.
- **The take-back:** a face press within **8 ticks** of LT's press turns it into the flight strike. **The slip or dodge-cancel is undone,** with its energy and cooldown (the dodge-cancel's 15 ki and 3 s) refunded. The body carries on from where it is, and the slip's protection frames end at once. **Controls checks the claw law.** LT and the face buttons are on different hands, so it should hold, but the gate decides.
- **If you can't pay for the flight strike,** the take-back doesn't happen. LT's own move carries on, and the pad knocks once.

### When it isn't read

| State | LT + a face button is |
| :--- | :--- |
| Knocked back or launched | Nothing new. Held LT is the air brake |
| Stunned, dazed, grabbed, in a clinch | Refused, with the knock |
| Charging a beam or a stick strike, or in a beam struggle | Not read. The charge's own rules hold |
| LB held too (LB + LT is the vanish) | The vanish |
| Past 12.5 bh, flying flat out | Today's long strike and trail spike |
| From outside another fight (2v2) | An outside blow: it lands only on an opening (`two-v-two.md`) |

### Chaining and price

- **Price by blow, plus distance:** X **10**, Y **15**, B **20** ki, plus up to **10** more by distance, rising evenly from 3 bh to 12.5 bh. So a zip from the band's far edge costs 20, 25 or 30, as today's zip did.
- **Chaining:** a press in the last **12 ticks** of a flight strike, or within **10 ticks** after it, starts the next as soon as it ends. Its tell is halved (at least 4 ticks).
- **Each link in a chain** costs **×1.5** the one before and is worth **×0.85,** never under 0.5. **There's no fixed count:** energy is the limit, as you picked on 2026-10-05.
- **The same path and button three times running in a chain** gets a full tell again on the third, so a repeat can be read.
- **No energy:** the pad knocks, "No energy" shows at the edge the first three times, and nothing starts. **It never drains you to zero.**

### Counters

| What meets it | Result |
| :--- | :--- |
| **A heavy timed to land in its tell or travel** (within 6 ticks of its arrival, the zip's existing `heavyBefore`), or **a charged stick strike** | **It stops where it's reached.** The striker takes the counter's blow at ×1.25 and reels for 8 ticks, **never knocked down or launched,** and he's free after that. His energy's spent |
| A light, or a medium | It doesn't stop. They land as normal |
| A guard | Blocks the blow, with chip as usual. The path completes |
| A perfect block | A reversal, as for any blow |
| A dodge | A miss: he's open for 20 ticks |

**The computer's dodge exchange:** you only follow it round if you're still pressing toward it (`beams-third-play.md`).

### Data, for Encounter

```json
{
  "flightStrikes": {
    "enabled": false,
    "rangeBh": [0, 12.5],
    "bearing": { "deadzone": 0.5, "towardDeg": 45, "awayDeg": 45 },
    "takeBackTicks": 8,
    "blows": {
      "x": { "tell": 6, "worth": 2.5, "ki": 10 },
      "y": { "tell": 10, "damage": 132, "ki": 15 },
      "b": { "tell": 14, "ki": 20, "result": "stagger" }
    },
    "kiByDistance": { "fromBh": 3, "toBh": 12.5, "add": 10 },
    "line": { "pastBh": 1.5 },
    "arc": { "ticks": 24, "riseBh": 1.3, "endUpBh": 0.5 },
    "parting": { "addBh": 3, "minBh": 6, "maxBh": 12.5 },
    "travel": { "minTicks": 4, "bhPerTick": 3 },
    "chain": { "lateTicks": 12, "afterTicks": 10, "tellMul": 0.5, "tellMin": 4, "kiMul": 1.5, "worthMul": 0.85, "worthFloor": 0.5, "repeatFullTell": 3 },
    "counter": { "heavyBefore": 6, "mul": 1.25, "reelTicks": 8 },
    "missOpenTicks": 20
  }
}
```

It replaces `stances.circle` and the LT lane of `stances`, and lets the zip start up close. `zip.band.minBh` goes from 3 to 0.

## 2. Beams (the vision's section 3)

| Open point | Ruling |
| :--- | :--- |
| **A beam's charge is protected from lights from tick 0** | **Confirmed, for beams.** A plain stick strike's hold keeps 0.2 s, since a quick flick has its own rule (a light takes its stun, `stick-lands.md`). `armour.beamFromTicks` 0, `armour.fromTicks` stays 12 |
| **A medium in the first 0.5 s stops it** | **Confirmed, and aligned to stage 2 at 28 ticks.** `armour.mediumUntilTicks` 30 to 28. After that, a medium does its damage and doesn't stop the charge |
| **The medium line restored** | **Yes.** That rule is in the data, but the charge armour that carries it is off on Orb's page, so it goes on with it |
| **A held charge never fires by itself** | **Confirmed,** for beams and stick holds, with a staged charge or an answer window running. `autoGoTicks` 68 goes. **Holding past your top stage costs energy:** 4 a second for a beam, as ruled, and **2 a second for a stick strike,** so an armoured hold isn't free. When you can't pay, it steps down a stage |
| **The point-blank throw-back** | **Confirmed:** out to 9 bh over 15 ticks, with no damage and no stun. **Always the way he already faces, never through you,** and it stops at a wall |
| **Charge stages 2 to 6 by power** | **Confirmed:** `2 + round(4 × level)`, on 12, 28, 46, 66, 90 and 120 ticks (`beam-answers-2.md`) |
| **The swat's timing** | **Confirmed:** from 12 ticks before the beam arrives to 2 after, judged on the release tick. No narrower until the drill with a moving beam |
| **The beam's own move, no lock, the 0.3 s rule, the computer on the same path, and every refusal said** | **As ruled in `beams-third-play.md`** |
| **The incoming-beam rumble** | **On** |

## 3. Pushing in a beam struggle: an option for each player

**Orb's pick (2026-11-06):** "Put it in options, let players choose whether they want rhythm on right stick (easiest), rhythm on face buttons (hard), or another undecided mode potentially." With the stand-in's calls (`controller-vision.md` section 8):

| | Ruling |
| :--- | :--- |
| **The setting** | **`struggle.pushMode`: `"stick"` (version A, the default) or `"face"` (version B).** A third value is reserved and not built (below) |
| **Whose** | **Each player's own,** in their options, kept with their controls. It's carried in the match's setup for each slot, so replays, LAN and 2v2 all read it. The computer isn't affected |
| **Strength** | **Every mode pushes equally hard:** the same window, the same push of 0.1 (sharp 0.15), and the same stray rule. A mode changes only what you press, never how much it counts |
| **Teaching** | The first three clashes of a match show the push for **your** mode in the left panel: a stick arrow for `stick`, X, Y and B for `face` |
| **Re-ruled** | **`right-hand-attacks-rulings.md` §3's "in a struggle the stick does nothing"** now holds only in `face` mode. In `stick` mode the stick pushes and the face buttons do nothing. **The walk-in's steps** are your mode's push: a flick toward in `stick`, X, Y or B in `face` |
| **The third mode** | **A stub:** the key's third value is reserved, with nothing behind it until Orb names it. Choosing it isn't offered yet |

```json
{ "struggle": { "pushMode": { "default": "stick", "values": ["stick", "face"], "reserved": ["third"], "perPlayer": true } } }
```

**Shared by both:** a pulse every 20 ticks, a window of 4 ticks either side (2 for a sharp push), a push of 0.1 (sharp 0.15), a press off the beat cancels your next good one, 15 pulses. Walking into a beam is a struggle: your steps count double. The computer hits pulses at its level's rate, as now.

### Version A, `stick`, the default: flick the right stick toward them on the beat

| | |
| :--- | :--- |
| **Push** | **Flick the right stick toward them on the beat,** however the beam was fired (RB, your signature, or walking in). A flick is the stick crossing the request line within 45° of toward, inside the window. **It has to come back under the release line before the next one counts,** so holding or scrubbing does nothing |
| **Let go** | Flick the right stick **away** on the beat. Off the beat, you're caught letting go and overwhelmed, as today |
| **Face buttons** | Do nothing in a struggle |
| **Re-rules** | `right-hand-attacks-rulings.md` §3's "in a struggle the stick does nothing" is reversed. The walk-in's presses become flicks toward |
| **Claw law** | Stick only, so no pairing. Controls' gate gets the row |
| **Mirrors** | The D-pad toward, on the same tick. The keyboard's strike arrows |
| **Teaching** | The left panel shows a stick arrow pulsing toward them on each beat |
| **Its case** | One thing to learn, on the hand that fires beams |

### Version B, `face`, an option: X, Y or B on the beat

| | |
| :--- | :--- |
| **Push** | **X, Y or B on the beat.** A second press in the same window is a stray |
| **Let go** | **A on the beat** |
| **The stick** | Does nothing in a struggle, as ruled |
| **Re-rules** | None |
| **Teaching** | The left panel lights X, Y and B on each beat (`beams-third-play.md`) |
| **Its case** | It works today, and the stray rule already stops a mash from winning |

## 4. Pressing into the city, step one (the vision's section 4)

**Turning on what's built, and the follow-through.** It comes after QA reads the civilian band and match length, and **nothing about bystanders changes while Legal's RL-247 hold stands.**

| Piece | Ruling | Data |
| :--- | :--- | :--- |
| **Only he is held** | The slammed fighter is held at the face, and the rest of the fight goes on | `brunt.lodgeHold` "world" to "body" |
| **No ping-pong** | He stays at the face for the hold, with no bounce back out | New `brunt.wallRebound` 0 (today's 0.25 of his speed) |
| **The world turns on impact** | A slam can start a big swing, easing the city toward the street behind the building, up to 45°, from the contact, under the rate law (60°/s in builds). It counts in the 6 to 12 big swings | A new swing cause, `slam` |

### The follow-through window

**It's open for as long as he's held:** 0.5, 0.5, 0.7 and 0.9 s by the attacker's tier, today's `lodgeSeconds`. **One follow-through a slam,** and it's the attacker's first press in the window:

| You press, in the window | What happens |
| :--- | :--- |
| **B with the left stick toward him** | **The tower ladder,** as ruled: at base he's driven into the tower and lodges, at tier 2 he goes through one tower and on into the next, and from tier 3 through as many as his energy carries (`power-scale.md`). **Here a tapped B drives him,** because he's already pinned: it's the one place a tap isn't just a stagger. A weak send through a tower stays never |
| **Y** | **Slammed again** into the same face: a medium's blow and a second slam. The building remembers (`wallMemory` 0.25), so repeated slams break it, by `giveWay` 2 |
| **LT + toward, and a face button** | **The line flight strike, stopping in front of him** rather than passing through into the wall. Its blow lands as you arrive |
| **Anything else** | As normal |

### His way out

- **The wall kick** (built, off, now on): **a dodge tap in the last 4 ticks** before he meets the face, arriving at **1,500 a second or more.** He kicks off toward his stick at 60% of his speed, takes half the slam's damage, with no hold, and **the attacker's follow-through is void.** Data as today: `wallKick` beforeTicks 4, minIntoWall 1,500, keep 0.6, damageMul 0.5, pushTicks 8.
- **A perfect block** against the follow-through blow is a reversal, as for any blow.
- **His guard still works** against the follow-through, except a tapped B toward, which drives through the guard into the building.

**Brief or pinned:** your choice by playing, Orb. The pinned hold goes to Legal first.

## What this changes elsewhere

- **`press-decides.md`'s circle (LT + Y)** gives way to the flight strikes. Its numbers fold into the arc.
- **`pad-first-press.md`'s LT + X step strike** is the line.
- **Charged stick holds** now cost 2 energy a second past their top stage.
