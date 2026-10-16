# The Protagonist's branching forms, and anguish reworked

Owner: Game Design. Date: 2026-10-16. **Paper only.** Nothing here is built or run by me, and **every number is a first value.** Narrative writes the why and the voice alongside this page, and names the branches and the forms. The names here are working names.

**Orb** (homework 5, `docs/ep/vision.md`): building up anguish "by intentionally killing civilians is a perverse incentive for the protagonist", and a fight against another good guy "might be lame and boring if neither can power up because they're avoiding civilian deaths". Orb's idea: branching forms, "one branch achieved by witnessing civilian deaths at the hands of his opponent, perhaps one achieved by allowing his opponent to power up first and testing himself against a higher form".

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
| **Fills from** | Each person the opponent kills within 3,000 units of him (shortest arc): +1, times 425 / pop0, like every gain per person. A guard's kills are the Empress's | The opponent takes a form while his own tier is no higher: +15, or +25 if his own form was ready and he held it. While the opponent's tier is above his: +1 a second of fight time, and +2 for each blow of a medium or more that he lands. The opponent commits fully (a finisher fired, a clash at full ki, fighting on at the brink): +5 each |
| **Never from** | A person he kills. **Each one takes 2 off it:** he can't claim the anger of deaths he caused | Anything he does to the world |
| **His forms play as** | Anger aimed at the one who did it. On top of the ladder at each step: damage +4% and launch force +8%. His launches lean away from people more strongly (his care +0.5 in these forms) | The student meeting a higher form. On top of the ladder at each step: speed +4%. His perfect-block window is 1 tick wider at the first step and 2 at the second, and his perfect follow-ups are worth 1 more |

## 4. The tree

| Tier | His form |
| ---: | :--- |
| 1 | His base |
| 2 | A Witness form or a Trial form |
| 3 | A Witness form or a Trial form, whichever he took at tier 2 |
| 4 | **One top form, where both roads meet.** It wears the branch he came by, in its colour and its signature's variant, with that branch's extra at its tier-3 size |

- **He takes the branch with the higher fill,** at each step, when he holds Transform (as now: `manualTierUp`).
- **A tie** goes to the branch he is on. At the first step, a tie (both under 10, or equal) goes to Trial: testing himself is his own road.
- **He may cross at the tier-3 step.** A Witness form at tier 2 and a Trial form at tier 3 is a story: Narrative voices the turn.
- **That is five forms to make, where today's ladder has three.** A first version can tell the branches apart by markings and aura over the shared body. The silhouettes can come later.

## 5. How a fight between two good guys escalates

- **The ladder brings both up** at the pace of any fight: the first form at about 1:30 (`spec-wounds.md` §8b). Nothing in it needs anyone to die.
- **The first to step up gives the other his Trial.** The follower's Trial fills while he is a tier down, and his form answers it. So two good guys climb in turns, each testing himself against the other's higher form. That is how the fight escalates without a death.
- **If both hold a ready form and wait,** nobody's Trial fills, since it fills only while the other is above. Waiting earns nothing, and the staredown is theirs to break.
- **The AI** holds a ready form for up to 10 s when its rival's form is ready too, so that Trial is seen, and takes it then. Otherwise it takes it as now.

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
| `data/fighters/PROTAGONIST/forms.json` (new) | The tree: for each tier, each branch's form id and its extras (damage, launch, speed, perfect window, follow-up worth, care); the pick rule (higher fill; a tie to the branch he is on; the first tie to Trial); one top form | Simulation, with Narrative's ids |
| The meters' sources (Tools' schema) | `whose: opponent` with a `within` distance. New events: `opponent_form` (with the held-ready bonus), `deficit_second`, `blow_up` (a landed blow of medium or more while the opponent's tier is above) and `opponent_commit` | Simulation, Tools |
| The transform | The form is picked at the step, and the fighter carries his branch (hashed) | Simulation |
| `data/fighters/RIVAL/meters.json` | The +0.09 power a casualty moves here from `sim/world/collateral.gd`, where it is a constant, since numbers live in data. Its value doesn't change | Simulation |
| The AI | The 10 s hold of §5 | Encounter |
| The HUD | The two fills by his power bar, so it reads which way he leans; the form's name at a step | UI, with Narrative's words |
| The looks | Four branch forms and one top form | Art, Animation, VFX |

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
