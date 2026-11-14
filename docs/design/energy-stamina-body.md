# Energy, stamina and the body: the one model

Owner: Game Design. 2026-11-13, sprint A1 row A-ENERGY-02, with the comeback's numbers for A-ENERGY-05. **This is the one page for the model.** Every older page that touches it points here, and where they disagree, this page wins.

It builds on:
- Orb's answers (`docs/ep/vision.md`, 2026-11-13: the brainstorm, the workshop, and the audit's decisions 6 and 11);
- the stand-in's two workshop pages (`docs/ep/proposals/alpha-feature-workshop.html`, `alpha-feature-workshop-2.html`);
- the code as it is: wounds, energy, the ladder.

**Status:**
- **The comeback** (§6) lands in GW1 with the old meters set to zero.
- **The rest of the loop** is built in A3 (A-ENERGY-01) as shared rules with each fighter's numbers in data, and switched on only after QA's comeback measurement (decision 11).
- **Every number here is a first value, as data.**

## 1. The numbers at a glance

| Number | What it is | Refills | Shown by (no bars) |
| :--- | :--- | :--- | :--- |
| **Body** | The deep number a fighter finally runs out of. **It's the old hidden hit-point number, reused** (`maxhp`, 1,600 today, per fighter), not a new one | **Never, in a match.** It's the attrition clock | How he gets up (slower), his voice (strained), damage on the torso that stays through a form |
| **The four parts** (head, arms, legs, and **the core**) | Injuries, as built: wear with stages at 30, 60 and 90 (bruised, battered, broken). Limbs stop at battered and spill into the core, and a limb breaks only in a crippling moment. **The core is the most important part:** it's the gate to the body, and the brink | Wear fades out of exchanges, as built. A new form eases it | The part itself: an arm that hangs, a leg that drags, an arm across the ribs for the core |
| **Stamina** (new) | Your wind, 0 to 100 at base. **The rhythm of a fight:** big moves spend it, plain blows that land earn it back | Seconds | Breathing and posture (heaving, a sag, slower flat-out flight), and a slow heartbeat in your own pad when low |
| **Energy** (ki) | What big moves cost, as today: 0 to 100, starting at 60 | Tens of seconds | The aura: how large and how steady. The corner plate keeps its energy line |
| **Power** (the ladder) | 0 to 100, with thresholds at 35, 65 and 100 making a form ready, as built | Over the fight | The power pips (UI fixes the 25-per-tier misread, F-ENERGY-09) and the form-ready flare |

## 2. What spends and refills each

| Number | Spends | Refills |
| :--- | :--- | :--- |
| **Body** | Each hit that lands takes **damage × severity × a share** from it. The share is set by the struck part's stage and gated by the core (§3, rule 4) | Nothing in a match (lever: a slow trickle out of exchanges, if fights end on body too often) |
| **Stamina** | **Any move that spends energy also spends 0.7 of that energy as stamina,** at most 30 a move (Orb: "Yes, both"). So a signature (45 energy) costs 30, and a 20-energy special costs 14.<br>Flying flat out (LT held): 6 a second.<br>A slip: 5. The dodge-cancel: its 15 energy, so 10.<br>Guarding a blow: light 1.5, medium 3, heavy 6 | **Plain blows that land:** light 3, medium 5, heavy 8. **×1.5 well timed, ×0.35 mashed** (Controls' press read), **×0.5 blocked**, nothing for a miss.<br>A **quick stick flick** counts as a medium (5), and a **charged stick strike** below its top stage as a heavy (8). In Orb's scheme the stick is the right hand's plain blow. A **grab** that lands counts as a heavy.<br>**Resting** (no spending): 12 a second × (0.6 + 0.6 × body share), ×0.85 with legs battered.<br>**A new form** refills it |
| **Energy** | Each move's own price, as ruled (beam stages, flight strikes, the dodge-cancel, signatures and the rest) | **As today, but every gain is × the stamina factor** (0.75 at empty stamina, rising to 1.25 at full): 5 a second free, 30 a second charging, +0.04 × damage dealt. Guarding drains −0.08 × the damage guarded |
| **Power** | A new form uses it up | As built: time, charging, damage dealt and taken. Charging is × the stamina factor. **Damage taken fills it faster the lower the body:** × (1 + 0.8 × (1 − body share)), so up to 1.8 times |

- **No press is ever refused for stamina.** At zero you're **winded:**
  - your blows land at 0.8 strength;
  - flat-out flight is × 0.8;
  - any stamina you lack is paid from energy at 2 energy a point, with its own sound and pad pulse, so it's never silent.
- **The full hold's send, flight strikes, beams, bolts and blasts are energy moves,** so they spend stamina by the 0.7 rule. They refill nothing.

## 3. How they connect: Orb's rules, as numbers

1. **"High body gives a bonus to stamina regeneration":** resting regen × (0.6 + 0.6 × body share). A healthy fighter catches his wind about twice as fast as a wrecked one.
2. **"High stamina keeps energy gain boosted":** every energy gain × (0.75 + 0.5 × stamina share). Catch your breath, then power up.
3. **"Taking damage with low stamina increases severity of injuries":** each hit's wear × (1 + 0.6 × (1 − stamina share)), so 1.6 times when winded. Stamina is your armour.
4. **"Taking damage with injuries starts affecting body"** (the core as the gate, Orb's "core region should be the most important but perhaps separate"):

| | Sound | Bruised | Battered | Broken |
| :--- | ---: | ---: | ---: | ---: |
| **Share of a hit on head, arms or legs that reaches the body,** by that part's stage | 0 | 0.12 | 0.28 | 0.5 |
| **× the core's gate,** by the core's stage | 0.6 | 1.0 | 1.5 | 2.0 |
| **Share of a hit on the core that reaches the body** | 0.05 | 0.25 | 0.5 | 0.8 |

   A limb's share is capped at 0.9. So the body is safe while everything is sound. A broken core lets twice as much through from everywhere, which makes the core worth guarding and worth attacking.
5. **"Encourages reaching new forms":** a new form refills stamina and raises its ceiling by 15, and eases every part's wear by 20. **The body doesn't heal.** A form gets you back in the fight; it doesn't undo it.
   - **One limit:** a form never lifts a fighter off the brink. If he's on it, the core eases no lower than the brink line. Leaving the brink stays the Rally's job, as built.

## 4. The brink and the end

- **The brink comes when the core breaks** (wear 90, as the code has it today: `wounds.gd` `brinkProgress`) **or when the body runs out,** whichever comes first.
  - The core is the direct road and stays the usual one, because limbs spill into it.
  - The body is the attrition road: a fight that guards its core still ends.
- **Only a finisher ends a match** (unchanged: `HP_ENDS_MATCH` false, `spec-wounds.md` §1b-end). The time cap's rungs are unchanged.
- **`damage-model.md`'s "core breaks, or any two regions break" is superseded.** It never matched the code.
- **The comeback's "vitality" reads the nearer road:** 1 − the larger of (core wear ÷ 90, body lost ÷ body max). Until the body exists (GW1), it's the core alone, as today.

## 5. Forms and injuries, together

- **The hurt fighter reaches a form sooner** (Orb: "yes"), through the power fill in §2.
- **A new form eases injuries** (Orb: "yes"), by §3 rule 5.
- **Render:** body marks must be able to fade (F-ENERGY-10), or the easing can't be seen.

## 6. The comeback, for every fighter (A-ENERGY-05, GW1)

Orb's decision 6: keep the comeback as a rule for every fighter, set every other effect of the old meters to zero in data now, and remove their code after Alpha.

| | Value |
| :--- | :--- |
| **The rule** | A fighter's damage × **(1 + 0.5 × (1 − vitality)²)**. That's +12.5% at half vitality, +32% at a fifth, and +50% on the brink |
| **Who** | **Every fighter.** Today only a fighter with the hero's meter has it (`damage.gd` reads `hasAnguish`). Simulation makes it read every fighter |
| **The numbers** | Cap **0.5** (the Protagonist's live value, so his matches don't move), exponent **2** |
| **Zeroed in data** | The villain's damage, regen and beam bonuses (`menaceDmgCap`, `regen_bonus`, `beam_power`); the hero's regen penalty and composure; every collateral feed to the meters. The files stay until the code goes |
| **QA's measurement, before the loop goes on** | **The fighter who falls behind first wins 30 to 45%** of AI-against-AI matches. "Falls behind" means the first to reach a third of the way to the brink. If it's over 45%: cap 0.35. If it's under 30%: don't raise the cap; the loop's form boost comes next |

- **The rival gains the comeback and loses his meter's bonuses,** so QA also reads the two fighters' win rates before and after.

## 7. The runaway risk: whoever lands blows refuels

**The flag.** In this loop, the fighter who lands clean blows refills stamina, which speeds his energy, which pays for his next big move. The fighter being hit spends stamina guarding and, once winded, takes 1.6 times the injury. Without a check, the leader gets stronger and the trailer gets worse injuries: **a fight that's lost early stays lost.** That would go against "comebacks emerge" (pillar 6), and against the "fair-feeling" Orb asked for.

**What pulls back, already in the model:**
- breaking away refills stamina at 12 a second;
- a new form refills it entirely;
- the hurt fighter's power fills up to 1.8 times faster;
- the comeback's damage near the brink;
- a blocked blow refills the attacker only half;
- mashing refills a third.

**What QA measures before it's switched on** (with the loop on and off, the same seeds):

| Row | Band |
| :--- | :--- |
| The fighter who falls behind first wins | **30 to 45%**, with the loop on as with it off |
| The leader's stamina minus the trailer's, averaged over a match | **At most 25 points** |
| Time the trailing fighter spends winded | **At most 15% of the match** |

**Levers, in order:**
1. A blocked blow refills **0.25** instead of 0.5.
2. Winded severity **1.4** instead of 1.6.
3. Every refill × 0.75.

**Never the comeback's cap upward:** a bigger comeback hides a runaway rather than fixing it.

## 8. The data

- **Shared:** `data/fight/vitals.json` (new), behind `enabled`, off. **Per fighter:** `data/fighters/<id>/vitals.json` overrides any of it. Its schema goes in `tools/schemas/` in the same commit.
- **Energy's literals move to data,** shared with per-fighter overrides (F-ENERGY-03, Simulation): start, cap, regen, the charge rate, hit gain and guard drain.
- **The meter loader** has to accept the new kind (F-ENERGY-11).

```json
{ "enabled": false,
  "body": { "fromMaxHp": true, "refillPerSec": 0,
    "spill": [0, 0.12, 0.28, 0.5], "coreGate": [0.6, 1.0, 1.5, 2.0], "coreSpill": [0.05, 0.25, 0.5, 0.8], "spillCap": 0.9 },
  "stamina": { "max": 100, "formCeiling": 15, "regenPerSec": 12, "bodyRegen": [0.6, 0.6], "legsBatteredMul": 0.85,
    "refill": { "light": 3, "medium": 5, "heavy": 8, "stickQuick": "medium", "stickCharged": "heavy", "grab": "heavy" },
    "timedMul": 1.5, "mashMul": 0.35, "blockedMul": 0.5,
    "ofEnergy": 0.7, "moveCap": 30, "flatOutPerSec": 6, "slip": 5,
    "guard": { "light": 1.5, "medium": 3, "heavy": 6 },
    "winded": { "blowMul": 0.8, "flightMul": 0.8, "energyPerPoint": 2 } },
  "energyFromStamina": [0.75, 0.5],
  "severityMax": 0.6,
  "power": { "hurtBoost": 0.8 },
  "form": { "staminaRefill": true, "mendWear": 20, "neverOffBrink": true },
  "brink": { "coreBroken": true, "bodyEmpty": true } }
```

## 9. Calls this page makes (no question to Orb)

| Open point | Ruling |
| :--- | :--- |
| Knockout rule: "core broken" or "body empty"? | **Either, whichever comes first.** It's still only a finisher that ends a match (§4) |
| Does a blocked blow refill anything? | **Half,** and it's the first runaway lever (§7) |
| Grabs, stick strikes, energy blows | A grab counts as a heavy. A quick flick counts as a medium, and a charged strike below its top stage as a heavy. Energy blows spend energy and stamina and refill nothing (§2) |
| Does a form lift a fighter off the brink? | **No.** The Rally does that (§3, rule 5) |
| A stamina bar? | **None.** Stamina reads from the fighter and a pad pulse, under Orb's no-bars rule and answer 12 (marks as placeholders for diegetic glows). UI may propose a thin line on the corner plate, behind the look gate |

## 10. Who builds it (A-ENERGY-01, A3)

- **Simulation:** the body as the old hit points, stamina, the factors, energy's literals into data, the meter loader. Then the comeback for every fighter in GW1, with A-ENERGY-05.
- **Encounter:** the plain-blow refill at landing, read by weight and press grade; the 0.7 rule on every energy move; the winded blow.
- **Controls:** the press grade (well timed or mashed), which is already built; the winded pad heartbeat; the fall-through pulse.
- **Rendering and Animation:** breathing and posture by stamina; marks that can fade; the core's guard posture.
- **Audio:** breath and the fall-through sound.
- **UI:** the power pip fix.
- **QA:** §6's and §7's measurements.

## 11. Pages this replaces, where they disagree

- `damage-model.md` (the brink);
- `spec-wounds.md` (kept for the wound mechanics it specifies);
- `energy-overhaul.md` §182–190 (energy costs);
- `power-scale.md` (the energy model's launch side stands; this page owns the fighter's own numbers);
- `economy.md` (meters);
- `melee-press-feel.md` (its "stamina" was energy);
- `minimal-hud.md` (the readouts);
- `balance-targets.md` (its bands stand unless this page names a new one).
