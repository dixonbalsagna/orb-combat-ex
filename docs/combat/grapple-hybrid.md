# Grappling on A: the hybrid of the catch and the clinch, the moveset side

Owner: Combat and Choreography. First version 2026-10-16 (02d62328). **This version (2026-10-17) is aligned with Game Design's rules,** `docs/design/grapple.md` (56d4b581), which ruled my nine questions. It is also bound by Legal's rows g06 to g08 and h09 (`docs/legal/homework8-review-screen.md`, RL-151) and sized against Animation's `docs/animation/clinch-sizing.md`. Parked: nothing is built in the sim or in `data/`.

**Orb's pick** (homework 20): "hybrid between catch and clinch, rule in favor of clinch". Orb's note: "I see it as a way to set up combo chains and create varied combat scenarios".

## 1. The rules are Game Design's: what changed from my first version

`grapple.md` is the rule book. My paper now keeps to it:
- **A tapped is the catch,** a reach with a 10-tick tell.
  - On an open fighter it throws at once.
  - On anyone else it starts the clinch, even.
  - On a guard or a wind-up it starts the clinch one ahead.
  - In a perfect window it is the perfect catch: no tell, one ahead, and the chain's count becomes his lead.
- **A held is the catch and carry.** The carry starts from the catch itself, not only from a grip that has been won (my first version had that).
- **The clinch's pulse is its own,** every 20 ticks from the tie-up, not the brawl's beat:
  - **A pummel** is A inside 4 ticks of the pulse (sharp inside 2).
  - **A stray** moves nothing and voids his next pummel, so a masher does no better than a fighter who doesn't press.
  - **Both fighters may throw vicious blows,** four each a clinch.
  - **The brace** lasts at most 40 ticks, then rests 20.
  - **The leader walks the pair** at half speed.
- **A throw is a plain send, never a launch:**
  - **Down** buries him for 20 ticks (an opening).
  - **Up** sends him 4 bh up, open for 16 ticks in the air.
  - **Across** sends him 8 bh along the stick: into a building it is the wall slam and a 24-tick stagger; on open ground the thrower has the first move and the chase.
- **Out of my first version:**
  - **The B break-off.** In its place, a vicious blow that breaks a region ends the clinch with a 24-tick stagger.
  - **A vicious blow on the beat as a perfect,** and **the throw as a chain's ender.** In their place, the perfect catch feeds the clinch, and a throw's opening starts a new chain.
- **The shove is the clinch's push-off:** A on the pulse with the stick away, from even or ahead.

## 2. Combat's part: the throws by stick, for each fighter

`grapple.md` §8 gives Combat the throws, the vicious blows and the pieces.

The throws are drawn from my wave 4 grabs (`pending/wave4-grabs.md`; Animation's `pair3`), with one new throw for the up send, which wave 4 never had.

| Send (the stick) | The Protagonist: open, athletic, a turning send | The Anti-hero: economical, the arm left out at full reach |
| :--- | :--- | :--- |
| **Across, toward** | `hurl`: both hands at the collar and the hip, a hip throw with the robe flaring | `sling`: one hand on the collar, the arm straight at the release |
| **Across, away** | `turn_throw`: he pivots half a turn with the rival carried round him, and lets go with his back to the line | `back_throw`: he drops under the arm and sends the rival over his shoulder, behind him, into whatever stands there |
| **Across, no stick** | `hurl`, as toward | `sling`, as toward |
| **Down** (the bury) | `drive_down`: both forearms under the rival, down and forward | `spike`: risen a body length, the rival hanging from one hand on the collar, then down |
| **Up** (open in the air) | **New, the lift:** open hands under the arms at the shoulders, and a rising turn that sends him up (Legal g03: the body whole and in view) | **New, the jolt:** the plate set at the collar, and a straight shove upward from the hips |

- **The reversal** (a sharp pummel two behind, on the leader's throw) throws with his own stick, by the same table.
- **The catch's quick throw** on an open fighter uses the same table.
- **The AI picks by personality and care,** as `grapple.md` §6 has it: the hero away from people (up and the turn), the Anti-hero into a building (across) or the ground (down).

**The vicious blows** are generated for each row by the cell `martial.a.clinch` (generator version 20):
- ten for each fighter, at least two in every region of the stick and three in the core, five his alone;
- every one plays on a key set that exists (two derived, a re-aim and a hand-state swap);
- the Protagonist's are pointed and not cruel: a palm under the chin, palms and blades to the joints, a shoulder check, knees to the thigh;
- the Anti-hero's are an elbow into the same bruise, knees, a headbutt, the plate ground in.

Animation's sizing counts five close blows a fighter as new key sets. Mine name existing ones, played with the grip hand kept (Animation's `limb2`). If that holds, it saves those ten poses.

## 3. The looks of the clinch, for each fighter

Animation's habits, with my identity lines:

| | The Protagonist (playful and technical) | The Anti-hero (exact and punishing) |
| :--- | :--- | :--- |
| **The catch and the tie** | A boxer's tie-up: open hands at the collar and the elbow, the head tucked beside the other's | One hand takes the collar. The other arm is a **one-arm fold**, a forearm across his body with the hand free or at the chin (h09) |
| **The pummel** | Hand-fighting: a wrist turned, an elbow lifted, a palm slid under the chin | The collar hand presses down; nothing else moves |
| **The brace** (up to 40 ticks) | Wide, his feet sliding: he is pushed rather than thrown | Narrow and still, the one-arm fold kept. **Never the crossed-arm fold:** h09 forbids it held 12 ticks or more |
| **The carry** | A turning walk that swings the pair away from people | A straight march into the nearest wall |
| **The pin** (vertical, against a wall) | The shoulder in, both hands open, the knee set | The armoured shoulder leads in, the forearm across the collar and never the throat (g07) |

## 4. Legal, binding

| Row | What it asks | Where it binds here |
| :--- | :--- | :--- |
| **g06, the tied pose** | Collar and elbow or the waist (g05); the hands never lock or lace; the held fighter's hands stay free, never limp, bound or pinned behind him; both upright, heads and torsos apart by at least a forearm's length | The tie, the grip's three grades, the pummel, the brace |
| **g07, the pin** | Vertical against a surface, at the shoulder, collar or upper arm; no forearm or hand across the throat or face; no ground pin, mount or straddle; hips apart; the pinned fighter's feet bear weight and he is shown struggling or bracing | The pin. **There is no pin on the ground:** a clinch carried into the ground ends in a crater and a stagger (`grapple.md` §3), never a pin |
| **g08, the carry** | Over the shoulder, or by the collar and the waist; never by the head, neck, hair or tail; the carried body whole and in view every tick, face and chest never hidden or pressed to the holder; no glow at the hands; the throw a launch through the planner | The carry. Both fighters carry by the collar and the waist |
| **h09** | Crossed forearms are a held pose and fail h02 at 12 ticks or more; a one-arm fold is allowed | The Anti-hero's brace and his stand-off. His clinch arm is a one-arm fold |
| **s08** | Inside a hold, vicious blows run no more than two in a row **to the same place**. The arm is three places, the head, core and legs two each, so four taps on one region alternate places | The vicious blows (section 5 has the difference from `grapple.md`) |

- Legal asks that the lint run on every tick once the held poses are drawn. The pair spec carries g06 to g08 and h09 as asks on each phase (`pending/grapple/hybrid.json`), so Animation's held lint can name them.
- The generator mirrors the four new rows. No generated move is made of them: they are pose rules.

## 5. One difference left with Game Design

**s08 is by place; `grapple.md` writes "region".** `grapple.md` says vicious blows are "never more than two in a row to the same region (Legal s08)". Legal's s08 counts places: four taps on one region are allowed when they alternate places, so a stick held toward the core can throw chest, gut, chest, gut.

Read as regions, a player who holds his stick on one wound gets two blows and must change region. That cuts against what a vicious blow is for, in Game Design's own pitch: "It works on one wound. All of its wear goes to a single region". I propose keeping Legal's wording. The generator's places map already follows it.

## 6. Pieces, and Animation's cost

- **Animation's figure is the one to use:** 24 new poses for the two fighters (12 shared, and 6 of flavour each), plus five of `pair3`'s throws, which must be posed first (`clinch-sizing.md`).
- **This version needs `pair3`'s throws by send:** `hurl`, `sling`, `drive_down`, `spike`, `back_throw` and `turn_throw` (six), against the three Animation sized (hurl, back throw, the reversal). **The two new up throws** (the Protagonist's lift, the Anti-hero's jolt) are one new key set each.
- **The vicious blows** may cost nothing, if the grip hand can be kept on existing key sets (section 2).

## 7. The data

`pending/grapple/hybrid.json` holds the phases with `grapple.md`'s first values, the throws by send for each fighter, the vicious blows by region, and Legal's asks on each phase. It is the input for a `pair` kind of part in my generator, which is not built.
