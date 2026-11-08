# Creative rulebook: pose, gesture and look rules (DRAFT, Animation, 2026-11-07)

**Status: a draft, not in force.** Orb ruled on 2026-11-07 (docs/ep/vision.md; CD-15 in docs/ep/corrective-plan-2026-11-07.md) that pose, gesture and look rules are creative rules, owned by Art and Animation under Orb, and no longer a Legal gate. Legal's role is names, the likeness of whole characters, trademarks and copied assets. This draft collects the rows Legal filed as the RL-218 family (the held-pose rules h01 to h10 and k01 of `docs/legal/movegen-banned.json`, and the conditions of RL-218, RL-250 and RL-255) so each can be kept, loosened or dropped on purpose. Legal re-tags the rows (which stay as originality, which move here); until the EP passes that list, nothing in this file changes a gate, a test or a lint.

## How this rulebook works

- **One owner, one reason.** Every rule says *why we want it* (what it protects on screen), not what law it comes from. A rule with no reason a player or Orb would recognise is a candidate to drop.
- **Thresholds are Orb's.** The numbers (32 units for arms wide, 12 ticks for a held pose, 68 ticks for a held chamber, 80 for a limb's height) were Legal's first guesses and were never measured against how a pose reads. Each row names its number so Orb can move it.
- **The lint stays; its words change.** `render/anim/anim_held_lint.gd`, `pose_lint.gd` (`_legal` marks) and `anim_check.gd` read these thresholds from constants. The rulebook states the rule; a change to a number is a change to the constant and this row in the same commit, reported to the EP like any look change (the look gate, ADR 0010, still applies to anything the player sees).
- **What stays out of here.** Names, whole-character likeness, a pose or move copied from a specific work, trademarks and assets with an origin: those remain Legal's (`docs/legal/originality-rules.md`). A rule that says "this pose is too like a franchise's best-known one" (the b rows) is likeness, so it stays Legal's until Legal says otherwise.

## The rows

Each row: **id** (the old Legal id, kept so old reports still read), the rule as it stands, **what it protects**, the **number**, and **proposed** (keep, loosen, drop, or ask Legal first).

| Id | Rule as it stands | What it protects on screen | Number | Proposed |
| :--- | :--- | :--- | :--- | :--- |
| **h01** | A pose held 12 ticks or more is checked: the pair test (both hands together in the hip zone) for every held pose, the emitter test (an open hand held at the hip or above 82) for the charge, tell, signature, energy and hold classes | A held pose should look like a stance, not a posed power-up | 12 ticks; hip zone x 14 or less, height 24 to 44 | **Keep as a creative guard**; likeness of one famous pose is Legal's, the general "hands at the hip" look is ours |
| **h02** | No held crossed forearms; no held arms-wide invitation (both arms near straight, both hands 32 or more out, held 12 ticks or more); a shrug is not arms wide | Keeps the stance from reading as a taunt or a power pose | 12 ticks; 32 units; elbows within 25 degrees of straight | **Keep, number Orb's**; the arms-wide look is a creative choice we can allow for a chosen moment (a finisher, a rival's attitude) with a named exception |
| **h03** | A signature's tell is its own stance, never a crouch with fists clenched at the sides, and carries no scream | Stacking of marks (see k01) | none | **Keep as part of k01** |
| **h04** | Class assignments so the lint reaches new holds; an open-hand chamber keeps the wrist at x 9 or more; a closed-fist chamber at the hip is allowed | Lint coverage | wrist x 9 | **Keep** (it is a lint rule, not a look rule) |
| **h05** | A medium or heavy wind-up of 12 ticks or more is held: loaded limb at shoulder height or lower (a leg may be chambered), never at a hip, never both hands together, no limb held above 80 until the last 6 ticks, no held crossed forearms, no light or aura; both-hand blows keep hands at least shoulder width apart | A wind-up reads as a blow being thrown, not a charge | 12 ticks; 80 units; last 6 ticks; 20 apart | **Keep, number Orb's**; the "no light or aura" part moves to VFX's look rules |
| **h06** | A deep sink is a lunge-low stance, the striking limb loaded, the other hand up in guard; never both fists clenched at the sides in a crouch; no scream, aura or ground cracking while held | Same stacking, held sink | none | **Keep** |
| **h07** | A manner (the rival's show-off, the Protagonist's pointed) is a way of throwing, not a gesture: no arms spread as an invitation, no beckon; a limb left out after landing lasts 12 ticks or fewer; no taunt pose is part of a blow | Keeps style from becoming mockery inside a fight | 12 ticks | **Keep as a creative rule**; the beckon is a taste call, ours |
| **h08** | A heave may take one sliding half step of about 22 units; no leap | Grounded, not the jumping rising uppercut | 22 units | **Ask Legal first** (the leap is the likeness part of b03) |
| **h09** | Folded arms are a held crossed-forearms pose: a moment under 12 ticks is fine; never an idle, stand-off or intro pose | The Anti-hero's attitude should not become a pose from a specific character | 12 ticks | **Keep as a creative rule** |
| **h10** | A finisher's closing pose must not mock a beaten rival: an offered hand is one hand, fingers together and still, palm sideways, held low; a raised hand stays at shoulder height or lower | Tone | shoulder height | **Keep as a creative rule** (tone is ours) |
| **k01** | At any tick, no more than two of the seven marks (crouch with clenched fists, scream, upward flame aura, rubble ring with ground crack and wind, lightning on the body, hair change, a flash with a shouted form name) | Each mark alone is a familiar look; seven together is a copy. Our look should have its own mix | 2 of 7 | **Ask Legal first**: this is the likeness-by-accumulation row; keep it with Legal unless Legal re-tags it |

### Conditions from reviews, kept here as house rules

These came from review rows (RL-218, RL-250, RL-255) as conditions, and each is a creative rule of the same kind:

- **Hands (RL-218 (2), RL-250 (3), RL-255):** the Anti-hero keeps no open hand on any piece (fists, plates, knees, elbows); the Protagonist's open hands are flat blades, edge on, never palm up, never a pointing finger, never curling; nothing is carried. *Protects:* the two fighters' hands are different characters.
- **Targets (RL-218 (3), RL-250 (1), (2)):** no blow lands on the head from above or below; a downed foe takes the torso or the ground, never a stomp on a head; leg blows stay at shin and leg height. *Protects:* tone, and the combat style we chose.
- **Holds (RL-218 (4), (5), RL-255):** a chamber is a tell, not a hold, and is released at once on release; beam holds lower when the beam ends. The air brake's plant lowers within 5 ticks when the brake ends; its rear hand never lifts above the shoulder or draws back as a fist at the hip.
- **The longest brake (RL-255 (1), the EP's call 2026-11-07):** the air brake's plant is held while LT is held. From `sim/core/brake.gd` it lasts at most 36 ticks with ki (0.6 s at the hardest send, 7,000 u/s; about 32 at the largest measured, 6,240) and 72 ticks with no ki (the rate halves). The 72 passes RL-218's 68-tick held-chamber limit, which was written for charged chambers, not a braking body; it is **a rulebook call, not a Legal gate**, and it stands as built: the plant is a moving pose (the judder, the changing lean), not a still one, and it lowers within 5 ticks when the brake ends (`brake.json` `exit_ticks` 5). Orb may move it.
- **No glow, aura or scream on a body pose.** Light belongs to VFX and the energy rules.
- **The flight tilt (RL-250 (1)):** along a path the body leans and eases level around the blow; never a head-first dive or a full somersault over a foe.

## Open for Orb

1. Which numbers do you want to move: the arms-wide width (32), the held-pose threshold (12 ticks), the held-chamber ceiling (68 ticks), the limb height (80)?
2. A named-exception list: moments where a pose Legal's rules avoided is welcome (a finisher with open arms, a long charge with a raised hand), so the rule is "no, unless this list says so".
3. Who signs a rulebook change: Animation proposes, Art agrees for looks that touch a design, you decide; the EP records it as a short note beside the row.

## What this draft does not do

It changes no code, no data and no lint. Legal's re-tag of the rows decides which move; the EP lands the move (and edits `docs/legal/originality-rules.md` line 70 as CD-15 says). Animation then edits the lint's comments and this file in one commit.
