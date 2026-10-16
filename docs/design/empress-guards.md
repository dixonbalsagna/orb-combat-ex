# The Empress's guards: a fighter who brings her own

Owner: Game Design. Date: 2026-10-14. **Paper only.** Nothing here is built or run, and **every number is a first value.** Versus only: co-op is held. Encounter has sized the director's limit (`docs/director/one-v-many.md`), and its rules are folded into §5. Camera is sizing the framing.

**Orb,** 2026-10-14 (`docs/ep/vision.md`, last section): "Her base form should be able to summon elite troopers to fight alongside her, turning fights into multi-fighter brawls. there should be a compromise of losing certain energy attacks, grabs et cetera, in order to give commands to the semi-autonomous elite guards... I want the empress to, at most, be able to have two elite guards at once, meaning the empress can, with minimal setup, fight 3v1 in her base form in versus mode." And on the same evening: the commands are our call; a guard who falls is resummoned on a cooldown; versus only.

**It replaces** the act-1 goon phase of `spec-wounds.md` §3, where her guard fought one at a time while she watched. They now fight beside her. The guard of honour's salute, the Encore and "fallen guards leave" carry over (§6).

## 0. The rule in one paragraph

**She trades her energy stance for a command stance.** With RB held, her face buttons give orders where another fighter's fire shots. She keeps one bolt to snipe with, and her signature. She has no grabs: her guards take hold for her by fighting. At most two guards stand with her, each called with a press and some ki, and each comes back a while after he falls. **Her guards wear him down; she is the one who breaks him.** A guard never closes on him, launches him or knocks him back, and only one fighter strikes him at a time. So a 3v1 against her is a fight against her, through a screen she has to keep paying for.

## 1. The summon, and what it costs

| | First value |
| :--- | :--- |
| **The press** | RB + A, tapped (§3) |
| **Its price** | 20 ki |
| **Its tell** | She raises her hand. The guard arrives in 60 ticks with the guard of honour's salute, 1 s in which he can't be hit and can't strike |
| **How many** | At most two at once. Each is a place of his own |
| **When a guard falls** | His place reopens 20 s later. She calls again and pays again |
| **At the start of a match** | She enters with one guard, and calls the second. "Minimal setup" is one press and 20 ki. **Orb's choice** (§7) |
| **Through her forms** | Guards serve her base form and her joke revisions. At her first real revision they salute and withdraw, and she fights alone: the duelist of her late stages. **Orb's choice** (§7) |

## 2. What she gives up

Orb's compromise, made structural, so that it is plain on the pad.

| Another fighter has | She has instead |
| :--- | :--- |
| **The energy stance** (RB): bolts, the heavy shot, the charged shot, the blast in reach, the volley | **The command stance** (RB). She keeps the bolt on RB + X, so she can still snipe. The rest are orders |
| **Grabs:** the clinch (A mashed), the tackle (A held), the seize (A + B) | None. A tapped is still the shove, so she can answer a heavy. A mashed or held gives the "empty" tick, as any cell with no move does |
| Everything else | The same: three strengths on X, Y and B, the zip, the guard and its perfect block, her signature on RT + B (the cutting beam), her revisions |

## 3. The commands

**RB is held, and the face buttons give orders.** It is the same hand that would fire a shot, so it needs nothing new on any pad. RT's empty cells are kept free for later.

| Input | The order | What the guards do |
| :--- | :--- | :--- |
| **RB + X** | Not an order: **her bolt** | |
| **RB + Y** | **Engage** | One guard goes in and takes him on: the point. The other supports: a covering volley no more than once in 3 s, or a flank that cuts off his way out. They change places by the tag of §5 |
| **RB + B** | **Fall in** | Both come to her side, 2 bh off her shoulders. When he comes at her, the nearer one steps in front and takes the first blow of his approach. Each guard does that at most once in 3 s |
| **RB + A** | **Summon** | A guard, if a place is free (§1) |

- **Semi-autonomous.** A guard follows the last order with an elite AI of his own: medium's shares, whatever her level. He picks his own blows, moves on his own, and never strikes her.
- **A new guard falls in** until she gives an order.
- **The orders are few on purpose.** Two orders and a summon are what a player can give while she is also fighting. More can come once these are played.
- **On Simple,** and on a phone, the director summons her guards and gives her orders, as it picks the energy stance for a Simple player. She just fights.
- **The AI Empress** uses the same orders by level: she summons when a place is free and she has the ki, sends her guards in while she charges or snipes, and calls them back when he comes for her.

## 4. The guards

| | First value | Why |
| :--- | :--- | :--- |
| **Their body** | Art's guard of honour: one shared model, two looks, the marksman and the speedster (`spec-wounds.md` §3's Encore) | Cheap, and already designed |
| **Their kit** | Lights and mediums from the common pool, one heavy, a bolt. No signature, no forms, no ki of hers | Troopers, not fighters |
| **What a blow of theirs is worth** | Half a fighter's | Two of them shouldn't double her damage |
| **What they can't do** | **Close on him, launch him, or knock him back.** Their blows don't build a run against him. Every decisive exchange in the match is hers or his | The fairness rule: he knows where the danger is |
| **Toughness** | A guard falls to two decisive exchanges won against him, or to 250 damage, whichever comes first. He has no wound regions and no brink | Fast to break: each fall is a small win for the fighter facing three |
| **When one falls** | He salutes and withdraws, and leaves the field. It is never a casualty: nobody dies (the goons' rule Orb approved) | |
| **Speed** | Hers, but they never fly further than 25 bh from her | They are an escort, not a hunting party |

## 5. Facing three: why it is fair

**One striker at a time.** Only one fighter brawls with him at a time: her or the guard on point. The others support at range, flank, or wait. **He is never hit by blows from two fighters within 8 ticks** (a hard test). So he reads one rhythm, as in any brawl.

**A partner and a ring** (Encounter's `docs/director/one-v-many.md`, ruled 2026-10-15). At most two bodies touch him at a time. One is his partner, in an ordinary brawl with him. The rest are the ring: in reach, outside the brawl's pull, circling, feinting and waiting. The director may grant one ring blow into the brawl: an interjection.

| | The rule | First value |
| :--- | :--- | :--- |
| **His partner** | The one his stick points at within striking distance; else the partner he has; else the nearest in front of him | |
| **The tag** | A ring body becomes the partner when the partner is sent (a launch, a knock-back, a wall slam), when he turns his stick on a ring body in reach, when the partner has held him for a slice with nothing decisive, or on the Empress's order. **No guard tags himself in** in any other way | The slice: 6 s. At most one tag in 30 ticks |
| **The Empress as partner** | No slice. She keeps the brawl until a decisive exchange, a parting or her own order | |
| **A player as partner** (ruled 2026-10-15, on Encounter's stage 3) | **Her press is never held, and the row is kept.** With a human partner the director grants an interjection only while her line is committed: a medium or a heavy winding, a charge, or a reel or stagger on her, when no blow of hers can land in the next 8 ticks anyway. So her guard covers her while she winds up, and never steps on her rhythm. If that leaves her guards too quiet, the fallback is Encounter's as built: her line waits up to 8 ticks after an interjection lands. The row itself never relaxes: he is never hit by two fighters within 8 ticks. A player's press answers at once, which is the brawl's first rule, and the 8 ticks are the defender's, who is a player too | No wait on her press. The fallback's wait: 8 ticks at most |
| **His run on a tag** | **Carried.** His pressure is against all of them. If a tag wiped his run, she could rotate guards to keep him from ever closing | |
| **A partner's run on a tag** | Fresh. A guard's blows build no run against him anyway (§4) | |
| **An interjection** | One blow from the ring: **a light or a medium, never a heavy, a launcher or a grab.** Its wind-up is in sight for at least 8 ticks, and it can be guarded and perfect-blocked like any blow. A guard's covering volley is an interjection too, by bolt | At most one in 1.5 s, and never within 8 ticks of the partner's contact |
| **A press of his across a tag** | Goes to the new partner, and is still one blow | |

**The cap** (Encounter's sizing). 3v1 is built and ships. 4v1 waits behind a cap until a measured probe shows the old machines can carry it. There is no 5v1. The Empress's two guards make her a 3v1, so she needs nothing past the first.

**What he has, and it is plenty:**
1. **Break the escort.** Two decisive exchanges and a guard is gone for 20 s and 20 of her ki. Each one gives him 10 ki.
2. **Go for the head.** When she is staggered, launched or knocked back, her guards drop their order and fall in to her until she is free.
3. **His stick picks his target.** His attack goes to the one his stick points toward. With no stick, it goes to the one he hit last. Nothing new is pressed. Controls to confirm.
4. **One hit, many bodies.** A launch can carry a guard into another or into her. His signature hits every enemy on its line. A knock-back can drive a guard into the next.
5. **Outnumbered.** While he faces two or more, his ki comes back half again as fast.
6. **She pays for her screen.** 20 ki a guard, and her energy stance and her grabs for the right to give orders.

**The bands:** she wins 45 to 55% of each pairing, as every fighter does. Her guards fall 2 to 6 times a match. The fight is 3v1 for 20 to 60% of her base form's time. Encounter's director keeps it readable or the cap comes down (§7).

### What the core counts, with more than two bodies

Ruled for Simulation's stage 1 (`docs/architecture/pending/n-bodies/`) and World's notes (`docs/world/scratch-build/near-offers/README.md`), 2026-10-15. "The principals" are the two fighters the match is between: the Empress and the one she fights.

| | The ruling | Why |
| :--- | :--- | :--- |
| **A guard knocked out** | **Doesn't end the match.** Only a principal's KO does. A guard falls: he salutes, leaves the field, and his place reopens after its cooldown (§1). Only a principal can win a finisher | A guard has no brink and no finisher (§4) |
| **The mood's "both aggressive" and "both guarded"** | **The principals' stances only.** A guard's landed blow feeds the mood at full, as Simulation built it (re-ruled 2026-10-16: one striker at a time means his blows replace hers, so at half a 3v1 would read calmer than a 1v1) | A guard's stance is his order, not a choice. Counting it would let the AI set the mood |
| **The acts** | **The principals' forms and wounds only.** Guards have neither. Their falls reach the acts through her Wrath, which drives her revisions | |
| **The hit-stop and the pauses** | **One for the whole match, as now.** It is one fight: a partner, a ring, and one interjection at most. Freezes that overlap merge and don't add. An interjection or a volley's bolt freezes as a light does, 2 ticks at most | So the freeze share stays readable, and nobody is frozen twice by one moment |
| **Later, when a 2v2 splits into two 1v1s** | **Each fight gets its own hit-stop.** A hit in one fight mustn't still the other | Not needed for the Empress's 3v1. It is written down now so the core isn't built against it |
| **The collateral budget** | **Unchanged by the number of bodies.** The window and the ceiling go by the highest tier, as now. More launches spend it sooner, and the director then picks sends that miss buildings | The budget is the world's pace of loss. People are people, whoever's flight hit them |
| **Room in a street** | **The ring stands along the street and in the air, not across it.** A 5 bh street has 4 bh of depth (`depth.md` §2), which holds the pair at its line's angle. The ring takes two places a side along the street, at striking distance and 2 bh more, and the air above it. An avenue or a crossing gives it the whole band. The streets aren't widened, and the bodies aren't spread over two streets | Flight goes over anything. The ring is three-dimensional where the street is narrow |
| **The start** | **The principals stand astride the crossing as now. Her guards stand 2 bh behind her, along the street** | One x for each body, from World's start |

- **QA reads** launches that take a building in a 3v1 beside a 1v1. If a 3v1 reads tamer in its buildings than a 1v1, that is the budget binding, and it is a question for Orb then, not a number to move now.

## 6. Wrath, collateral, and what carries over

- **Her meter is Wrath, filled by her own losses.** A guard who falls adds to it. Losing her escort drives her toward her revisions, and toward fighting alone.
- **What her guards break is hers.** A building or a person hit by a guard's blow or volley counts on her account, for every meter and budget: she gave the order.
- **What he breaks with a guard is his.** A guard launched through a full building is the launcher's collateral. The Protagonist's anguish pays for it.
- **Every body counts in the budgets.** The rolling casualty budget and the chain limits cover the guards' launches and his launches of them alike.
- **The guard of honour's salute,** 1 s and unhittable, is every guard's arrival.
- **The Encore stays her comeback,** once a match, within 3 s of reaching the brink. It now brings **both** guards back at once, fresh, whatever their places' cooldowns, with the mend gauge as written. It brought three when it was designed. **Orb's choice** (§7).
- **The act-1 goon phase is retired.** **Orb's choice** to confirm (§7).
- **At tier 1** she is the duelist of her late revisions, alone (`fighter-pipeline.md` §3). The guards are her tier 2 mechanic, with an off switch, so her balance can be read with and without them.

## 7. Open questions, for the homework sheet

Each is a short choice. "Orb" marks the ones that are theirs. "Ours" marks the ones we have decided and Orb may change.

| # | Question | Choices | Whose |
| ---: | :--- | :--- | :--- |
| 1 | How does she start a match? | With no guard / **with one, and calls the second** / with both / your call | Orb |
| 2 | When do her guards leave? | **At her first real revision: she fights alone after that** / never: they stay through every form / your call | Orb |
| 3 | The Encore brought three. With two the most at once, it brings | **Both of her two** / three, as an exception for the comeback / your call | Orb |
| 4 | The act-1 goon phase, where her guard fought one at a time while she watched | **Retired: they fight beside her now** / kept as an opening, before she joins in / your call | Orb |
| 5 | Her command stance is her energy stance: RB with a face button gives orders, and she keeps one bolt | **Yes** / commands somewhere else / your call | Ours |
| 6 | What she gives up | **Her energy stance but the bolt, and every grab** / something else / your call | Ours |
| 7 | Her guards never close on him, launch him or knock him back: only she breaks him | **Yes** / guards can win exchanges too / your call | Ours |
| 8 | Only one fighter strikes him at a time | **Yes** / two at once is fine / your call | Ours |
| 9 | A guard falls to two decisive exchanges or 250 damage, and comes back 20 s after he falls | **Yes** / tougher / weaker / your call | Ours |
| 10 | The fighter facing her guards gets his ki back half again as fast while outnumbered | **Yes** / no help / your call | Ours |
| 11 | When the guards fight beside her, can she be the striker too, taking turns with the guard on point? | **Yes, one striker at a time** / she stays back while they engage / your call | Ours |
| 13 | When the fighter facing her is passed from one partner to the next, does the pressure he has built carry over? | **Yes: his run carries** / it starts again / your call | Ours |
| 12 | The cap on how many fight one, for later fighters | **Three on one at most for now, and four on one only if the director keeps it readable** / your call | Orb, with Encounter's sizing |

## 8. QA's rows, and the order

| Row | Bound |
| :--- | :--- |
| Her win rate in each pairing, with her guards on | 45 to 55% |
| The same, with her guards switched off | Read beside it, to see what the mechanic does |
| Blows from two fighters on him within 8 ticks | Never (hard) |
| An interjection that isn't a light, a medium or a volley's bolt; two in 1.5 s | Never (hard) |
| His run kept across a tag | Every tag (hard) |
| A guard closing on him, launching him or knocking him back | Never (hard) |
| A guard striking during his salute | Never (hard) |
| Guards fallen a match | 2 to 6 |
| Fight time at 3v1 in her base form | 20 to 60% |
| The Encore's bands (`spec-wounds.md` §3), with two guards | As written |
| The director's time a tick with three fighters | Encounter's budget |
| The summons' salutes and the volleys | Inside the flash register |

**The order to build:**
1. One guard: the summon and its cooldown, Engage and Fall in, one striker at a time, a guard who can't close.
2. The second guard, and the supports: the volley, the flank, the step in front.
3. The hand-off at her first real revision, and the Encore with two.
4. The AI Empress's orders.
5. Simple's orders from the director.
