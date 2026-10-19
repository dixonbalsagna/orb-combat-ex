# The Protagonist's branching forms, and anguish reworked

Owner: Game Design. Date: 2026-10-16. **Paper only.** Nothing here is built or run by me, and **every number is a first value.** Narrative writes the why and the voice alongside this page, and names the branches and the forms. The names here are working names.

**Orb** (homework 5, `docs/ep/vision.md`): building up anguish "by intentionally killing civilians is a perverse incentive for the protagonist", and a fight against another good guy "might be lame and boring if neither can power up because they're avoiding civilian deaths". Orb's idea: branching forms, "one branch achieved by witnessing civilian deaths at the hands of his opponent, perhaps one achieved by allowing his opponent to power up first and testing himself against a higher form".

**Orb** (homework 23, 2026-10-16): "Yes, build toward this": transformations "exciting and feel like an achievement rather than a burden or an obstacle", the Protagonist "unique in that he has a variety of transformations that give him modest all-arounder buffs", and his "sling-shot" (§4b). Rule of cool always applies. The Witness branch is a cold quiet, as Narrative wrote it (`docs/narrative/anguish-branches.md`). Its name on screen, and Trial's, are Narrative's to pitch.

## 1. What was wrong

- **Today his meter fills when people die.** Anguish gains 0.9 for each person he kills and 0.5 for each one anybody else kills, and costs him ki regen. It never powered him, but it is his meter on the HUD, and it rises with deaths. So it reads as "deaths make my hero".
- **The villain's side is real.** The rival's menace and his power (+0.09 a casualty on the ladder) both grow with the people he kills.
- **The ladder already escalates every fight.** Nine tenths of power comes from damage dealt and taken (`data/fight/ladder.json`). So two fighters who both avoid people still climb. But nothing made the Protagonist's three steps more than the same three steps.

## 2. The rule

**Power comes from the fight, for every fighter: the ladder, as now. People dying never powers the hero. What the fight was like decides which form he becomes at each step.**

## 3. The two branches

Two fills, both shown by his power bar. Neither decays in a match. Taking a form empties the fill of its branch, and the other branch keeps its own. So each step reads what happened since the last one.

| | **Witness** (working name) | **Trial** (working name: Respect in `economy.md` §4.2) |
| :--- | :--- | :--- |
| **The story** | He has watched his opponent kill people | He let his opponent rise first, and tested himself against the higher form |
| **Fills from** | Each person the opponent kills within 3,000 units of him (shortest arc): +4, times 425 / pop0 (0.94 a person at 1,800; it was +1 until 2026-10-18, `rulings-2026-10-18.md`), like every gain per person. A guard's kills are the Empress's | The opponent takes a form while his own tier is no higher: +15, or +25 if his own form was ready and he held it. While the opponent's tier is above his: +1 a second of fight time, and +2 for each blow of a medium or more that he lands. The opponent commits fully (a finisher fired, a clash at full ki, fighting on at the brink): +5 each |
| **Never from** | A person he kills. **Each one takes 2 off it:** he can't claim the anger of deaths he caused | Anything he does to the world |
| **His forms play as** | A cold quiet aimed at the one who did it. On top of his step gains, at II and at IV: damage +4% and launch force +8%. His launches lean away from people more strongly (his care +0.5 in these forms) | The student meeting a higher form. On top of his step gains, at II and at IV: speed +4%. His perfect-block window is 1 tick wider at II and 2 at IV, and his perfect follow-ups are worth 1 more |

## 4. Five steps, each a modest all-rounder

Orb (homework 23): "Yes, build toward this", and "Protagonist should be unique in that he has a variety of transformations that give him modest all-arounder buffs". Each must feel like an achievement, never a burden.

| Step | At power | His tier, for the world | What it is | How it plays |
| ---: | ---: | ---: | :--- | :--- |
| I | 20 | 1 | **Marks on his base:** the first change in his look (markings, the aura's first layer) | A live step: a 0.3 s beat, no pause |
| II | 35 | 2 | **A Witness form or a Trial form** | Like everyone's step: it may pause |
| III | 50 | 2 | **Marks on that form** | Live |
| IV | 65 | 3 | **A Witness form or a Trial form.** He may cross here | May pause |
| V | 100 | 4 | **The top form, where both roads meet.** It wears the branch he came by, in its colour and its signature's variant | May pause |

- **Every step's gains, all-round and modest,** in his own ladder file, in place of the shared ladder's gains a tier:
  - speed +5% and damage +5%;
  - launch force +8%;
  - chip through a guard −5%;
  - ki regen +5%;
  - air recovery 5% sooner.

  His five steps come to speed +25%, damage +25% and launch +40%, near the shared ladder's three tiers (+30%, +27% and +48%). On top of that he has the guard, the regen and the recovery, which only he gets.
- **The branch extras** (§3's table) come on top, at II and IV.
- **His tier for the world** (the collateral budgets, structure reach, the building ladder) steps at 35, 65 and 100, as everyone's does.
- **The pick:** he takes the branch with the higher fill at II and at IV. A tie goes to the branch he is on, and the first tie goes to Trial: testing himself is his own road. A cross at IV is a story, and Narrative voices the turn.
- **An achievement, never an obstacle:** a step is never forced (he holds Transform when it is ready), never lost, and each has its own look and sting.
- **What it costs to make:** four branch bodies (II and IV, by branch), two sets of marks (I and III) and one top form. A first version can tell the branches apart by markings and aura over the shared body.

## 4b. The slingshot (the working rule, pending the lore)

Orb: "he stays in his base form and allows the opponent to grow, when he finally transforms he can get a bigger boost based on how long he waited and the damage traded before transforming." In homework 30, Orb picked **"Waiting only makes your next single form stronger"**, and asked to "delve into the universe lore before we finalize anything on transformations, right track though". So this is the working rule until Narrative's lore paper lands. The jump of several forms at once, the burst and the surge are withdrawn (2026-10-18).

- **Holding back.** When a step is ready he may leave it. Power keeps filling. Every step that comes ready while he waits stays ready, and none is lost.
- **One step at a time.** When he holds Transform, he takes **the next step only.** The steps still ready after it can be taken later, each one as an ordinary transformation.
- **The coil** (working name; Narrative names it).
  - **It starts at the first break** after his step came ready, when he could have taken it and didn't. A step that comes ready mid-brawl coils nothing until then, so nobody, the AI included, coils by accident.
  - It fills at +0.5 a second of fight time, and +0.005 for each point of damage traded, dealt or taken, after patience. It fills twice as fast while the opponent's tier is above his.
  - It goes up to 100, never decays, and nothing takes it away.
- **Patience.** While he holds a ready step and the opponent's tier is above his, he takes 4% less damage for each tier between them, at most 12%. Waiting is a stance, not a burden.
- **The release: his next form is stronger.** At a coil of c, the form he steps into has its step gains × (1 + c/100), so at most twice an ordinary step. It lasts as long as he is in that form, and his next step is an ordinary one again. The coil is spent.
- **The coil is Trial's road.** Each coil point is also a Trial point, so a long wait leads to a Trial form.
- **Its three sizes,** for Narrative's lines (`docs/narrative/waiting-game-lines.md`): short under a coil of 34, long from 34 to 66, the biggest from 67.
- **Simulation's readings that still hold** (`forms-core.md` §2): `minCoil` 1, so a step taken at once has nothing extra; "chip through a guard −5%" is his own guard; damage traded is counted after patience. The burst, the surge's armour and the lasting gain are gone with the jump.
- **Its limits:** a step can't pass the ladder's top or the run's unlocked ceiling (`run-mode.md` §1.1 and §1.4).
- **The AI** takes a ready step at its first break unless it is holding on purpose. At medium it holds for up to 10 s when its rival is above it. At hard it holds until its coil reaches 60, 75 s pass, or a region of its own is battered, whichever comes first. Then it releases at the next break.

## 5. How a fight between two good guys escalates

- **The ladder brings both up** at the pace of any fight: the first form at about 1:30 (`spec-wounds.md` §8b). Nothing in it needs anyone to die.
- **The first to step up gives the other his Trial and his coil.** The follower's Trial fills while he is a tier down, and his coil runs at double. So two good guys climb in turns, each testing himself against the other's higher form, and the one who waits can answer with a slingshot.
- **If both hold and wait,** neither coil runs at double, since neither is above the other. Waiting together earns little, and the staredown is theirs to break.
- **More flavour, for Orb:** Narrative writes lines for these situations:
  - the staredown, when both hold;
  - a release, by the size of the coil;
  - a slingshot answered by a slingshot;
  - a cross between branches;
  - the mirror's greeting;
  - the moment one lets the other rise first.

## 6. The villain's menace, by contrast

- **Menace feeds on what he does to the world:** the people he kills and the people his blows force to flee. It pays now: ki regen, damage (+5% at full), beam power, and +0.09 power a casualty on the ladder. It is the rival's meter today, and Pride's +2 for each building he levels does the same job when Pride lands (`launch-pair-plan.md`).
- **The hero is never paid for a death.** His own kills cost him (§7). The villain's kills decide only which form the hero becomes.
- **So a villain who feeds on a town powers himself now, and hands the hero his angriest form at the next step.** It is a trade, not a free lunch, and it is pillar 5 in play: the villain feeds on collateral, and the hero is pressured by it.
- **Luring the villain into a town to fill Witness doesn't pay.** It feeds menace on the way, and Trial is as strong without a death. The hero's AI keeps its care, and never seeks people out.

## 7. What stays of anguish: the cost

- **The people he kills still cost him,** as now: ki regen −0.01 a point, at most −1, decaying 0.6 a second, with his voice and posture shaken. Only his own kills feed it now. The opponent's go to Witness instead.
- **Its name is Narrative's.** It may stay "anguish".
- **Composure** (off) and **comeback** are unchanged.

## 8. What changes in sim data

| Where | Change | Owner |
| :--- | :--- | :--- |
| `data/fighters/PROTAGONIST/meters.json` | Anguish loses its `opponent` source. Two new meters, `witness` and `trial`: visible, no decay, emptied by a form of their branch, with the sources in §3 | Simulation |
| `data/fighters/PROTAGONIST/forms.json` (new) | The five steps (§4): for each, its power, its tier for the world, live or pausing, its form id by branch, and the gains; the branch extras; the pick rule (higher fill; a tie to the branch he is on; the first tie to Trial); the slingshot (§4b, the working rule: the coil's rates, patience 4% a tier up to 12%, and the next form's gains × (1 + c/100) at most ×2) | Simulation, with Narrative's ids |
| `data/fighters/PROTAGONIST/ladder.json` (new, his differences only) | Thresholds 20, 35, 50, 65 and 100, with his tier stepping at 35, 65 and 100 as everyone's; his step gains in place of the shared tier gains | Simulation |
| The meters' sources (Tools' schema) | `whose: opponent` with a `within` distance. New events: `opponent_form` (with the held-ready bonus), `deficit_second`, `blow_up` (a landed blow of medium or more while the opponent's tier is above) and `opponent_commit` | Simulation, Tools |
| The transform | The form is picked at the step, and the fighter carries his branch (hashed) | Simulation |
| `data/fighters/RIVAL/meters.json` | The +0.09 power a casualty moves here from `sim/world/collateral.gd`, where it is a constant, since numbers live in data. Its value doesn't change | Simulation |
| The AI | The holds of §4b and §5 | Encounter |
| The HUD | The two fills by his power bar, so it reads which way he leans; the form's name at a step | UI, with Narrative's words |
| The looks | Four branch forms, two sets of marks and one top form; a boosted form's look by the coil's three sizes | Art, Animation, VFX |

- **The heat track and Open Hand** (`moveset-rules.md` §10.4, `spec-wounds.md` §3) stay parked for their later update. Whether heat becomes Trial's road is for Orb, with Narrative.
- **Every other fighter's meter is unchanged.** The rule of §2 holds for the roster: no fighter's power-up depends on killing, beyond the villains' own meters.

## 9. QA's rows

| Row | Bound |
| :--- | :--- |
| A person the Protagonist kills raises Witness or Trial | Never (hard) |
| A person the opponent kills beyond 3,000 units raises Witness | Never (hard) |
| Each branch is taken at some step, Protagonist against the rival, default arm | In at least 25% of matches each |
| His win rate with a Witness form first, and with a Trial form first | Within 10 points of each other |
| The Protagonist against himself: both reach tier 3 | In at least 80% of matches |
| ... the first form's time | Within 15 s of the default arm's |
| The hero's fight time near people, after the rework | No higher than before it |
| A ready step lost, or a release that takes more than the next step | Never (hard; the jump of several steps is withdrawn, homework 30) |
| A coil that fills before the first break after the step came ready | Never (hard) |
| The median time from the coil's start to 100, while the opponent is above him | 60 to 100 s |
| His win rate in matches with a release from a coil of 50 or more, and in matches with none | Within 10 points: the slingshot is a style, not a must |
| The AI at hard throws a slingshot | In 20 to 50% of its matches as the Protagonist |
| His five steps' gains against the shared ladder's three tiers, by QA's balance read | Within 5% of each other in worth |
