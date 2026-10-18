# Grappling on A: the hybrid of the catch and the clinch, the moveset side

Owner: Combat and Choreography. First version 2026-10-16 (02d62328). **This version (2026-10-17, updated 2026-10-18 for s08 and the drawn throws) is aligned with Game Design's rules,** `docs/design/grapple.md` (56d4b581), which ruled my nine questions. It is also bound by Legal's rows g06 to g08 (RL-150) and h09 (RL-151) (`docs/legal/homework8-review-screen.md`) and sized against Animation's `docs/animation/clinch-sizing.md`. Parked: nothing is built in the sim or in `data/`.

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

The throws are drawn from my wave 4 grabs (`pending/wave4-grabs.md`), with a new throw for the up send, which wave 4 never had. All eight are now posed in Animation's `pair3` (`zq.*`).

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

**The vicious blows** are generated for each row by the cell `martial.a.clinch` (generator version 21):
- eleven for the Protagonist and twelve for the Anti-hero: every region of the stick covered, and every place in it, so a region held on the stick alternates places (section 5); five or more his alone;
- every one plays on a key set that exists (two derived, a re-aim and a hand-state swap);
- the Protagonist's are pointed and not cruel: a palm under the chin, palms to the chest and the gut, a blade hand and the heel of the fist chopped on the arm, a blade-hand jab to the head, a shoulder check, knees to the thigh and a sweep to the shins;
- the Anti-hero's are an elbow into the same bruise, knees, a headbutt, the plate ground in, the plate hammer to the head and a sweep to the shins.

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
| **s08** | Inside a hold, vicious blows run no more than two in a row **to the same place**. The arm is three places, the head, core and legs two each, so four taps on one region alternate places | The vicious blows (by place, as `grapple.md` now rules: section 5) |

- Legal asks that the lint run on every tick once the held poses are drawn. The pair spec carries g06 to g08 and h09 as asks on each phase (`pending/grapple/hybrid.json`), so Animation's held lint can name them.
- The generator mirrors the four new rows. No generated move is made of them: they are pose rules.

## 5. s08, by place: settled

**Game Design re-ruled it on 2026-10-17** (`grapple.md` §2, on this reading): vicious blows never run more than two in a row to the same place, by Legal's own wording. A region has two or three places, so a stick held on one wound keeps working it, the blows alternating places.
- QA's row is G1 in `qa-rows-2026-10-17.md`.
- `pending/grapple/hybrid.json` carries the places map with `sameplaceMax` 2. The generator's vicious map (`parts.json` `vicious.places`) is the same one.
- **Every place has a piece** (generator version 21), so the alternation is always possible: the head and the jaw, the chest and the gut, the legs and the shins.
  - The shins are reached only by a foot on an arc in, so the clinch takes a foot, low only (the cell bans a foot above the legs). Each fighter's sweep is the shins' piece.
  - The Anti-hero's head place is his plate hammer, since an elbow or a headbutt reaches only the jaw.
  - The arm is one target in the grammar. Its three places (shoulder, elbow, wrist) are assigned by Animation at run time (Legal's `launcher-and-reach-screen.md`), so arm blows alternate there.
- **Encounter's `docs/director/grapple-director.md` still counts s08 by region.** It should take the by-place count when it builds the vicious blows.

## 6. Pieces, and Animation's cost

- **Animation's figure is the one to use:** 25 new poses for the two fighters: 13 shared, with the pin's brace that g07 asks, and 6 of flavour each (`clinch-sizing.md` §6a).
- **The eight throws are drawn,** on main since b328017b: `pair3`'s `zq.hurl`, `zq.sling`, `zq.turn_throw`, `zq.back_throw`, `zq.drive_down`, `zq.spike`, and the two up throws `zq.lift` and `zq.jolt`. Animation's `data/anim/throws.json` maps them by send exactly as section 2's table does (checked against `hybrid.json`).
- **One key to note:** `throws.json` names the Anti-hero `antihero`, where the roster's id is `RIVAL` and the recipes' pool key `rival`.
- **The vicious blows** may cost nothing, if the grip hand can be kept on existing key sets (section 2).

## 7. The data

`pending/grapple/hybrid.json` holds the phases with `grapple.md`'s first values (the tie, pummel, throw and part tick lengths are mine, unruled), the throws by send for each fighter, the vicious blows by region, and Legal's asks on each phase. It is the input for a `pair` kind of part in my generator, which is not built.
