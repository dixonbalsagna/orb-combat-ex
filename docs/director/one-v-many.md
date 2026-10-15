# One versus many: what the fight director can take (paper)

Owner: Encounter Systems Director. Date: 2026-10-14. **Paper only: nothing is built.** It answers Orb's question of 2026-10-14 (`docs/ep/vision.md`, last section): "What's the upper limit we can realistically push the fight-choreographer to accept?" Orb's rules: multi-brawls are one versus many; a 2v2 always splits into two 1v1s; a 2v1 is allowed; at most 4v1, "as long as the fight choreographer can meaningfully keep the battle looking exciting and feeling responsive". The Empress has at most two elite guards, so she fights 3v1 in her base form, and a guard knocked out comes back on a cooldown. Versus only; co-op stays unbuilt. Game Design is writing the guards' design and Camera the framing; this paper keeps to the director. Every number below is from main 18724edd unless it says otherwise.

## 1. The answer

**Up to 4v1 is realistic, on one condition: no more than two bodies touch the one at a time.** One guard brawls with him, the others wait in a ring, and at most one of them throws a single blow into the brawl when the director grants it. With that rule the one is hit about as often as in a 1v1 today, his presses stay one blow each, and the cost a tick grows with the bodies and not with the fights.

- **3v1 (the Empress and two guards) is what I would build and ship first.** It is the case Orb named, and it fits every budget below with room.
- **4v1 is reachable behind a data cap,** but only after the 3v1 proof rows pass and a measured probe shows the cost a tick on a low machine.
- **5v1 and beyond: no.** A fifth body adds cost and crowding and no fighting, because the two-touching rule already uses everyone who can fight at once.
- **Free simultaneity (every guard striking whenever it likes): no, at any count.** Section 3.3 says why in numbers.

## 2. What the director does today with two bodies

| Part | What it does today | How it assumes two |
| :--- | :--- | :--- |
| The exchange (`DirExchange`, `S.dirS.ex`) | One exchange at a time, between an attacker `A` and a defender `D`. The brawl is one kind of exchange (`ex.tpl == "brawl"`) with a strike line for each of the two | `S.dirS.ex` is read in 116 places in the director, 19 in the core and 10 in input. "The other one" is written as `ex.D if f == ex.A else ex.A` in 21 places |
| The brawl (`DirBrawl`) | Every press is one blow; two strike lines; the run, the trade, the close, the hammer, the hold. 99 integers a fighter (`f.act.dirI`), many of them "against the rival": his run, his last gut blow, his held press, the first move after a send | Per fighter, not per pair: a fighter's state is about his one rival |
| The bands (`DirBands`) | Approach and range between the pair: close under 3 bh, mid to 12.5 bh, engage at 2.5 bh; the brawl breaks past 4.5 bh, and giving ground has a leash of 2.4 bh | Distances are between two bodies |
| The launch planner (`DirLaunch.chooseLaunch`) | Scores the sends for the launcher against his one target, with World's building candidates | One target; the candidates don't know a third body |
| The AI (`DirAI`) | One AI state a fighter (`f.ai`); it reads its rival | `SimRoster.opp(S, f)`, 26 calls in the director, 7 in the core and 4 in World |
| Keyed draws | Seeded draws keyed by tick and slot, so replays reproduce | 8 keys in the director are built as `n * 2 + slot` |

**One thing is already shaped for one-versus-many:** `SimRoster.opp` gives every fighter who is not fighter 0 fighter 0 as his opponent. With more bodies, every guard's default opponent is already the one.

**What a tick costs today** (my probe `cpu1.gd`, scratch; the AI against itself, 6 matches, 197,024 ticks, Orb's PC with other sessions at 40 to 47% load, so these read high if anything):

| What the director is doing | Share of ticks | Mean | 99th percentile |
| :--- | ---: | ---: | ---: |
| A brawl | 37% | 474 µs | 1,131 µs |
| No exchange | 30% | 301 µs | 792 µs |
| A planned exchange | 15% | 252 µs | 987 µs |
| A tick that makes a launch decision | 0.1% | 649 µs | 1,881 µs |
| A hit freeze (nothing steps) | 17% | 10 µs | 22 µs |

So a brawl adds about 170 µs a tick over two bodies standing apart, and a launch decision about 175 µs more, about 13 times a match.

**How dense a brawl is today:** 11.4 blows land a second between the two, 5.8 of them on each; 27% of a brawl's ticks are hit freeze (a light or a medium freezes 2 ticks, a heavy 6); a freeze runs 2 ticks at the median and 7 at the most.

## 3. What a third, fourth and fifth body need

### 3.1 Turn-taking or simultaneity

**Turn-taking, with one licensed exception.** The one has exactly one partner at a time, and the brawl is the brawl of today between him and that partner. Every other guard is in the ring: in reach of the fight but outside the brawl's magnetism, circling, feinting, holding his distance, and waiting for the tag. The director grants one thing more: **an interjection**, a single blow from a ring guard into the running brawl, on an opening the one gave (a miss, a stagger he took, a launch he lands and stands over). At most one is in flight at a time, at most one every 1.5 s, and never within 8 ticks of the partner's own contact. An interjection is a beat in the partner's exchange and not an exchange of its own, so `S.dirS.ex` stays one exchange.

### 3.2 Who the one fights

- **His partner,** by these rules in order: the guard his stick points at within striking distance; else the partner he has; else the nearest guard in front of him.
- **The tag.** A ring guard becomes the partner when the partner is sent (a launch, a knock-back, a wall slam), when the one turns his stick on a ring guard in reach, or when the partner has held him for a slice of time with nothing decisive (a first value of 6 s). At most one tag in 30 ticks, so the fight never strobes between bodies.
- **A press made across a tag goes to the new partner,** and is still one blow.

### 3.3 How many can touch him in a second

| Rule | Blows that land on the one a second, in a brawl | Freeze share of the brawl |
| :--- | ---: | ---: |
| Today, 1v1 | 5.8 | 27% |
| One partner and one interjection in 1.5 s | about 6.4 | about 28% |
| Two guards striking freely | about 11.5 | about 35% |
| Three guards striking freely (the Empress's case) | about 17.3 | about 42% |

The free rows multiply today's rate on the one by the strikers, with his own 5.6 a second on his partner. The freeze share adds 1.9 freeze ticks for every blow landed in either direction, which is today's average (26,557 freeze ticks for 13,903 blows).

- **Free simultaneity breaks the brawl's own rules, not just its look.** The run closes on a fighter who takes four unanswered lights in a row. With two guards striking freely, the one takes four lights in about 0.35 s (one guard alone needs 0.7 s) while he can answer one guard at a time, so he is closed on (staggered) every time he turns. That is a lock, not a fight. Two fifths of the brawl would stand still in hit freeze, and the flash register's cap (3 big flashes a second, a weight of 2.5 in any 60 ticks) would be met by its throttle rather than by choreography.
- **Two touching is the limit that keeps the 1v1's feel.** About 1.1 times today's blows on him, one more freeze point, and every rule of the brawl unchanged.

### 3.4 A press stays one blow

- **The one's press:** one blow, at his partner, inside the light's 2 ticks, as today. It never splits between two guards. A sweep or a spin that hits several is a piece of its own, designed as such (Combat's), and never what a tap does.
- **A guard's press:** only the partner presses blows at the one. A ring guard's AI doesn't press; the director's grant is its one blow. So no guard's blow arrives that the choreography didn't place.
- **Proof rows:** every press of the one puts exactly one blow on its way; no press is lost on a tag; a ring guard lands no blow without a grant; never two grants in flight.

### 3.5 Determinism and the golden

- **1v1 must stay bit-identical.** Every new path runs only with more than two bodies, and the 1v1 goldens don't move. The 8 keys built as `n * 2 + slot` keep their form for slots 0 and 1, and slots 2 and up get a namespace of their own (`"guard." + key`), so no 1v1 draw changes.
- **The core's part is Simulation's:** N fighters in the roster, the hash and the replay format (input for every slot), and what `opp` means past two. The director needs `DirBrawl.partner(S, f)` in place of `SimRoster.opp` where it means "the one I fight now": about 47 sites (the 26 calls and the 21 "other one" expressions), read one by one.
- **The per-fighter state stays per fighter.** A guard's brawl integers are about his fight with the one. When he is tagged in, they start fresh. The one's, his run among them, carry from one partner to the next: that is a design question (section 6).
- **A new golden** for 3v1, once the plumbing lands, beside today's.

### 3.6 The cost a tick

Measured today: 301 µs for two bodies apart, 474 µs in a brawl (section 2). Taking the worst case, that all of the 301 µs is two bodies' own step and AI (about 150 µs a body), and adding one brawl and an interjection beat:

| Bodies | Estimate, mean a tick on Orb's PC | 99th percentile | On a machine three times slower, mean |
| :--- | ---: | ---: | ---: |
| 2 (1v1, measured) | 474 µs | 1.1 ms | 1.4 ms |
| 3 (2v1) | about 0.62 ms | about 1.5 ms | about 1.9 ms |
| 4 (3v1, the Empress) | about 0.77 ms | about 1.9 ms | about 2.3 ms |
| 5 (4v1) | about 0.92 ms | about 2.3 ms | about 2.8 ms |
| 6 (5v1) | about 1.07 ms | about 2.7 ms | about 3.2 ms |

- **These are estimates.** A third body can't be run in a match today, so they can't be measured yet. Measuring them is stage 1's last row.
- **The cost grows with the bodies, not with the fights,** because the two-touching rule keeps one brawl however many wait. A launch decision adds about 175 µs about 13 times a match, whatever the count.
- **On the oldest machines Orb names, 4v1's tail is the one to watch:** about 7 ms at the 99th percentile on a machine three times slower, against a 16.7 ms frame that Rendering also needs. That is why 4v1 waits for a measured probe.

## 4. The limit I recommend, and why

| Count | Verdict | Why |
| :--- | :--- | :--- |
| 2v1 | Yes | Orb allows it; it is the first proof of everything |
| **3v1** | **Yes: build and ship it** | The Empress's base form. Under 0.8 ms a tick on Orb's PC by the estimate; the ring holds two waiting bodies easily |
| 4v1 | Yes, behind `oneVsMany.maxOpponents` | Only after the 3v1 proof rows pass and a measured probe on a slower machine |
| 5v1 and up | No | Two can touch him at once whatever the count, so a fifth body adds cost and crowding and no fighting |
| 2v2 | Not in this build | It splits into two 1v1s, which needs two exchanges at once (`S.dirS.ex` as a list). That is co-op's shape, and co-op is held |

**What "meaningfully exciting" means for the director,** as rows: the one is never hit by more than two bodies in any second; blows on him stay within 1.2 times a 1v1's; the freeze share stays under 32%; every tag is readable (at most one in 30 ticks); the ring guards are never idle props (each makes a feint, a step or a threat at least every 3 s); an interjection lands in at least half of the openings it is granted on, so it reads as the gang punishing a mistake.

## 5. The order to build it in

| Stage | What | Whose | Proof |
| :--- | :--- | :--- | :--- |
| 0 | This paper; Game Design's guard design; Camera's framing | Encounter, Game Design, Camera | Orb's yes on the limit |
| 1 | **Plumbing.** N bodies in the roster, hash and replay; `DirBrawl.partner`; the keyed draws namespaced; guards present and idle | Simulation (the core), Encounter | 1v1 goldens byte-identical; a 3-body match runs deterministically with the guards standing; the cost a tick measured at 3, 4 and 5 bodies |
| 2 | **The partner and the ring.** One brawl with the partner; the ring AI (circle, feint, hold); the tag; the one's targeting | Encounter; Controls for the targeting input | One blow a press; no press lost on a tag; no ring blow without a grant; tags at most one in 30 ticks |
| 3 | **The interjection.** One granted blow from the ring on an opening, spaced and budgeted | Encounter | Blows on the one at most 1.2 times a 1v1's; freeze share under 32%; the flash register never throttles a brawl |
| 4 | **Launches with bodies.** The planner sees the guards: a guard sent into another (a chain of bodies), the one sent away from the pack, the first move after a send with N | Encounter, World for the contact | No send goes through the launcher's own guard; first-move rows per pair |
| 5 | **The Empress's commands and the resummon.** Her orders reach the director as intents for the ring (attack, hold, guard her); a guard knocked out comes back on a cooldown | Game Design and Controls for the orders; Encounter for the director's side | The commands change the ring within 10 ticks; the resummon never lands inside a brawl's blow |
| 6 | **4v1,** if stage 1's measured cost and the 3v1 rows allow | Encounter | The same rows at 4v1, and the cost on a slower machine |

## 6. Open questions

- **For Game Design:** the one's run on a tag, carried or fresh. Carried rewards a player who keeps hitting. Fresh is easier to read.
- **For Game Design:** the slice a partner may hold the one before a tag (6 s is my first value), and whether a guard may tag himself in.
- **For Game Design and Combat:** what an interjection may be (a light only, or up to a medium; never a launcher).
- **For Simulation:** what the replay's input looks like for a guard, an AI body with no input stream, and whether the hash grows by slot or by a list.
- **For Camera:** the ring needs room either side of the pair. In a street that is two bodies a side on the plane, more with depth (`docs/director/depth-d1.md`). The ring's shape is the director's, the frame is Camera's.
