# The rally: Combat's links, the sells and the variety scoring

Owner: Legal and IP Compliance. 2026-10-25. Screens `docs/combat/pending/rally/` (Combat, committed): README, the four fighter sheets, their `legalAsks` and the scoring file's description. Paper only; the JSON beyond `legalAsks` and any picture were not seen. A screen, not legal advice. RL-183; new row mc04.

## Verdict: **Pass, with conditions.** The rally is an air juggle where the sent fighter can tech out, which is genre-ordinary. The shared sell rules already hold mine (never limp, no taunt over a dazed fighter, one flash event per sold blow). What needs care is the grabs in flight, one name, the stepped flares and the flash count across a whole rally.

## 1. The shared sell rules: **Pass**
- **Never limp, no slowing beyond the hit-stop, no taunt over a dazed fighter, each sold blow at most one flash event:** all as I would have set them. The Empress laughing and the Protagonist grinning are **the dazed fighter's own reaction**, not a taunt by the attacker, so they pass; the attacker's call-outs follow ln06.
- **The camera push** on a sold blow stays brief and eased, never a hold on a dazed fighter longer than the hit-stop (e12's zoom rule is for a bound fighter; this keeps the same spirit).
- **The Cyborg's sensor stutter** under a 10% step and 2 Hz (fx09): pass; **the one burst of neck-seam sparks** is one registered flash event (fx08); his hunger stays in his voice and never in a mouth (ln02).
- **The sells' looks** (folding, a visible gust of breath, a sneer, a plate straightened, a shower of rivets and wire) pass; nothing depicts gore or an injury.

## 2. The grabs in flight (e12, ln06): **Pass, with a rename and a pose rule**
- **Net Haul, Banner Drop, Crane Reel:** binds take arms or torso; the held fighter struggles; one call-out on the throw or in the catch's first 10 ticks; nothing said, zoomed, slowed or finished over a held fighter. The Empress's four staves are never joined by light into a box, barrier or dome (e16); the kneel is the slam's landing only. **Crane Reel's "swings it round once" stays a short turn at body height, never whirled overhead** (e12).
- **Ring Hang: rename to "Ring Hold"** (or "Ring Stay"). "Hang" beside a bound person carries the association of hanging; the thin loop round arms and torso is otherwise fine (e12: never a disc, never overhead, never cuts). While held in the air he **struggles and bracing, never limp, his limbs never dangling slack**, and no taunt, zoom or finisher over him.
- **A shot that lands on a held fighter** (the Rival's next shot, the Protagonist's palm) is a normal hit with the usual hit-stop; no slow motion, no lingering camera, no second shot played as an execution.

## 3. The links, one by one
| Link | Verdict |
| :-- | :-- |
| Palm Turn (open palm turns the body 90 degrees) | Pass. The tell is a turn of the wrist, edge-forward, not a hip draw |
| Pillar Lift (a send across his armed Trip Pillar) | Pass (e14: a solid slab) |
| Plated Ram (a straight ram, plates first) | Pass |
| Stair Spike (three steps down, the third the crater) | **Pass with a flash condition:** see section 4 |
| Rope Return (a send across her Velvet Rope, her level-1 beam fires) | Pass; the beam start and end are registered |
| Guard's Wall (a guard braces, the body rebounds) | No legal issue; Game Design rules the design. The guard speaks only in a 3v1 and never launches |
| Wreck Toss (a wreck hurled at the flying body) | Pass **if every wreck is empty and nothing living is near it**; wreckage only (ln04) |
| Slag Catch (rolling slag pops him up) | Pass; slag rolls and never seeks people |
| Names: Palm Turn, Net Haul, Pillar Lift, Plated Ram, Stair Spike, Rope Return, Banner Drop, Guard's Wall, Crane Reel, Wreck Toss, Slag Catch (+ Ring Hold) | CLEAR as working labels; plain words, no franchise echo (general knowledge, no web search this round) |

## 4. Flash conditions for rallies
- **A rally is a chain of effects in a short time.** The flash cap of 3 a second holds **across the whole rally**: the zip trail, a catch flash, a spike's flares, a beam start, a crater burst and each sold blow all share it. A link that would exceed the cap draws as dust, trail and ember, not a white flash.
- **Stair Spike's three stepped flares** count as **one** burst only if they merge into one glow (the first two dim plate flares that never fall 10% between steps) or if only the third (the crater) is a bright flash. Otherwise they are three events. Prove it in a clip (the same rule as Stair Split).
- **Sold blows:** one flash event at most each, with the neck-seam sparks counted inside it.
- **Clips before any public pin:** a rally of three or four links through a city and over water, in both modes, margin rule, red read 0 (fx09: the Cyborg's and Empress's hues).

## 5. The variety scoring: **Pass, with one rule**
The points are the AI's and Simple's choice of link; the player's stick wins by 200. They are internal and never shown as a score. **The scoring never reads casualties, deaths or a count of people** (no term for "killed", "toll" or "bystanders hit"); "the hero sends away from people, a villain toward them" is the existing personality term (a landing place's occupancy), not a reward for deaths (c08, ln04). No achievement, bonus or unlock for a rally's casualties.

## Rows
`mc04` is in `movegen-banned.json` under "mechanics".

## Addendum (2026-10-26, RL-186): World's reading of "nothing living near it" for Wreck Toss
Read: `docs/world/wreck-toss.md` (World, 2026-10-25). **The reading holds, with two additions.**
- **Holds:** (1) a wreck is a fallen building and holds no one: yes. (2) Fighters are not counted near the wreck, because the thrower stands within 2 bh and the target is a combatant: yes, and the same goes for a partner and for henchmen, who are all combatants.
- **Addition 1: count every living civilian, indoors or out.** The query reads "no living civilian in a standing building within 3 bh of the wreck's edge". Civilians on a street, fleeing or in a crowd are not in a building. **Read any living civilian within 3 bh of the wreck's edge, in a building or in the open,** and refuse the pick-up if there is one.
- **Addition 2: the landing is the other half of "near".** The pick-up check protects people at the wreck. The burst damages standing buildings near the landing by the brunt ladder, and the landing is wherever the flying fighter is. That is ordinary collateral under the same rules as a sent body (E110's budget, no toll or score), and it is allowed. But **Wreck Toss is never chosen or aimed for its landing near people:** for the Cyborg the planner's "villain toward people" care term does not apply to his wreck link (ln04: nothing in his set targets or uses bystanders), and the scoring still never reads casualties (mc04).
- The burst's look stays the existing debris, dust and shake: no remains, no bodies, a fallen building's people never shown (c08).
