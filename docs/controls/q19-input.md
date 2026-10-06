# Questionnaire 19 and the play notes: the input side

Controls, 2026-10-05, answering the EP's six questions on Orb's play notes (`docs/ep/vision.md`, "questionnaire 19"). Docs only; **nothing in `sim/input` changed, because the investigation found no input bug.** Whole ticks, 60 a second. Every claim about the live build below was run, not read: a scripted human slot through the **real layouts** (`SimLayout`, so the same presses a pad or keyboard makes) into a live brawl at HEAD fa501e6, against a passive rival, in an exported copy (the probe is scratch, not in the repo).

## 1. The reported fault: "RT then a face button gave no special; the context button did nothing"

**Both reports are right, and neither is an input fault.** The presses reach the intent correctly; the director has no move to run for them and says nothing.

What the live build does with each press in a brawl (Arena pad, and the same on the solo keyboard: E then J, K, I, L; I ran the keyboard for RT+X, RT+A and A):

| Press | What reaches the intent | What the director does | Verdict |
| :--- | :--- | :--- | :--- |
| **RT held** | `stanceMask` 4, `power` + `powerPress` | Nothing (the burst needs a threat; the channel changes nothing in a brawl) | not a move yet |
| **RT + X** | `stanceMask` 4, **`special` 1**, no `light`, `powerPress` already spent | **Nothing.** No blow, no cue, no ki spent, no `press_ack` | **missing move**: nothing reads `special` |
| **RT + Y** | `stanceMask` 4, **`special` 2**, no `heavy` | Nothing, silently | missing move |
| **RT + A** | `stanceMask` 4, **`special` 3**, no `context` | Nothing, silently | missing move |
| **RT + B** | `stanceMask` 4, `sig` | The ordinary signature: ends the brawl and fires the beam (ki 63.9 to 33.0 in the run). **The same as B alone**: nothing reads `stanceMask` or `sigHeld`, so there is no charging-stance signature or ultimate | works, but not a different move |
| **A alone** (nothing held) | `context`, `contextHeld` | `DirInterrupt.tick` calls `DirBlast.context`, which returns inside any exchange, and outside one does something only with guard held (the context deflect, needs a seeking shot) or the energy mode (a mine). With nothing held: **nothing, silently** | **missing move** (the martial A: shove, grab, tackle) |
| **B alone** | `sig` | The beam, 45 ki | works |
| **X, Y alone** | `light`, `heavy` | A blow (a brawl light's contact is **2 ticks** after the press, `brawl.light.contactTicks`; a heavy's is 34: wind-up 26 plus 8) | works |

**Where, with the lines.**
- **Input side is correct:** `layout.gd` `_layer_press` (lines 347 to 356) turns "RT down plus X, Y, A" into `_special_edge` 1, 2, 3 and takes the press away from the base action (a press on a layer never also sends `light`, `heavy` or `context`). Tested in `stance_test.gd` ("an armed charging stance makes X special1") and `layout_test.gd`.
- **The sim never reads `special`:** the only references in `sim/` are `wounds.gd:282` (clears it when stunned) and the golden and parity recipes. `grep` finds no consumer in `sim/director/` or `sim/core/`. Nothing reads `stanceMask` or `contextHeld` either (`wounds.gd:290` clears them; the UI reads the mask for the plate).
- **The specials are not defined in the live data.** The Protagonist's three specials exist only in `docs/combat/pending/` (`launch-pair.json`, `kit.*.json`, the movegen cells), parked. So it is not even a placeholder in the build: there is nothing to fire.
- **Context:** `sim/director/blast.gd:215` to `224` (`DirBlast.context`) and `interrupt.gd:355` to `357`, `361` to `363` (the reversal needs `context` and `guard` held and an exchange to reverse).

**What a player is told when a press is refused (`press_ack`).** Almost nothing. The brawl emits `press_ack` kinds `refused` (a signature that cannot start, `brawl.gd:417`), `energy` (a light with the energy family held, `:425`), `held` (a press kept for his line, `:449`) and `lapsed` (`:880`). **The HUD handles only the `weight_` and `sig_` kinds** (`ui_event_hub.gd:638` to `663`), so **none of those four is shown**. The special and context presses do not even emit one. A press that does nothing is silent in both the sim and the HUD.

**My recommendation (not built, it is not mine).** (1) Encounter emits `press_ack` `empty` for a cell with no move in the current stance (RT+X, Y, A until the specials exist; the martial A until it does), and UI shows it as a short grey tick on the pressed button (and on the stance chip); a press that does nothing must at least say so. (2) The refused kinds that exist today should reach the HUD the same way. (3) Until the specials ship, UI may keep the legend's special cells greyed "not yet". I made no change: there is no plain input bug in `sim/input` to fix.

## 2. Two-button power attacks: A+B, X+A, Y+B, X+Y

**Recommendation in one paragraph.** Read a pair **in the director from the press edges it already receives**, with a **3-tick window** and a **freshness rule** (neither button pressed in the 8 ticks before). **The first press is never delayed:** it is a blow on its own tick; if the partner comes inside the window, the director **replaces** the un-landed blow with the pair attack. **No intent bit, no version bump, 0 ticks of input delay on a single press.** The layout adds optional one-key pair actions for the keyboards and one-handed play. There is no cross-pad pair worth having.

**The cells.** Define a pair by the **cell** (X, Y, A, B), not by the key, so it follows remapping and the charging layer. The sim already has each cell as an edge: X is `light` (or `special` 1 under RT), Y is `heavy` (or 2), A is `context` (or 3), B is `sig`. The four pairs are the diamond's four edges: **X+Y, Y+B, B+A, A+X**. The pads' two cross pairs are X+B and Y+A (Orb's list reads "Y+X" as Y+A, to confirm).

**The window.**
- **3 ticks (50 ms), data `read.pairWindow`.** Two fingers aiming at "together" land within 1 to 2 ticks of each other; 3 catches nearly all of them. It must stay **below the 6-tick mash floor**: a mash or an X/Y alternation is at least 6 ticks between presses, so it can never be read as a pair by the window alone.
- **The freshness rule: both buttons must be fresh, `read.pairFresh` 8.** Neither button of the pair may have been pressed in the 8 ticks before the pair. This is the guard against the real risk: a player who mashes two buttons with two fingers produces near-simultaneous X and Y presses by accident, and would throw the power attack by mashing. With the rule a mash never pairs; a deliberate pair from rest (or after 8 ticks) does. A player who ends a flurry and wants a pair waits 8 ticks, which is the cost.
- The accessibility factor (`assistFactor` 2) doubles the window to 6 for a player who cannot press two buttons together.
- **QA's measure:** the share of a scripted two-finger masher's presses that read as a pair, which should be under 5%.

**What the first press does if the second never comes: it is the blow, thrown at once, unchanged.** The layout builds an intent every tick and an edge cannot be held back without a delay, so nothing is held back: X is a light on its press tick whether or not A follows. **Corrected 2026-10-05 (the EP's check): a brawl light lands 2 ticks after its press, not 6 (6 is the skill strike's contact), so a light is the one first press that can land before the partner arrives.** The rule: **a light that was pressed first is kept** (it is a real blow, it lands, its damage stands, it counts toward the run) and **the pair is still thrown from the partner's press**, with the partner's own motion becoming the pair attack. **Any other first press (Y, A, B) has a motion that is far from landing** (the heavy's contact is 34 ticks after the press, the energy bolt leaves 6 after, a lunge's crouch is 6 or 10 before it moves), so the director **replaces** that motion with the pair attack. A partner that is an X (light) is never thrown as its own light: it completes the pair. If both edges arrive **in the same build** (about half of deliberate pairs), there is no first blow to undo, and the pair simply starts. A pair is **one press in the log** (a new `PAIR` kind), counted once in the mix.

**How it sits with the rest.**
- **Debounce (2 ticks)** is per button, on its own re-press; the two buttons of a pair are different buttons, so it never touches a pair.
- **Mash and flurry:** the 3-tick window and the freshness rule keep them apart. A pair is a power attack and should end the run like a skill strike does (Game Design's call), and **should cost ki** (Game Design's number), which is the second defence against pair-mashing.
- **Tap and hold:** a pair is a tap by default. A *held pair* (both buttons down for the longer cell's hold, 16) is a separate charged pair, **not to be built until Game Design says charged pairs exist.** A held X plus a new A press after the hold has begun is not a pair (the X edge is old).
- **Stances:** the pair is read with the `stanceMask` at the second press, so every stance can have its own four pair moves (Game Design: 5 stances times 4 pairs is the content cost). Under RT the cells are the specials (X special 1, Y 2, A 3) and B is the signature, so a pair under RT is two specials, or special and signature; the cell mapping above makes that work with no new field. One edge case: two specials in the **same** build overwrite each other (`special` is one number), so an RT pair pressed in one tick loses one. If Game Design wants pairs under RT I will make the layout keep both (a small change in `layout.gd`; no new bit needed with a 3-bit-wide `special` plus the pair read, to be checked then).
- **The hold bridge on Simple** delivers the attack on release; Simple has no X, Y, A, B diamond, so **Simple has no pairs by button: the director throws pair moves for a Simple player, as it picks the rest of the spectacle** (Orb, Q13).

**Keyboards (the solo and shared layouts).** By the fingers, not the picture:
- **Solo** (right hand: J light, K heavy, L signature, I context; I is above K): **X+Y is J+K, Y+B is K+L, A+X is I+J, A+B is I+L: all four are neighbouring fingers (index, middle, ring) and comfortable.** The pair that would cross the pad, Y+A, is K+I: **one finger cannot press both**, so the solo keyboard rejects it by geometry; X+B (J+L) skips a finger and is awkward.
- **Shared P1** (left hand: F light, G heavy, R signature, V context, all within the index finger's reach): **X+Y (F+G) and X+A (F+V) are possible with one finger lying across two keys; Y+B (G+R) and A+B (V+R) are not comfortable.** Shared P2 (H, M, U, comma) has the same shape.
- **The fix is one-key pair actions:** four new remappable actions **`pair_xy`, `pair_yb`, `pair_ba`, `pair_ax`**, each bound to one key in the layout editor; the layout expands one into both cell presses in **the same build**, so the sim sees exactly what two fingers would send. They are defined by action (cell), so they follow the layer and the remap. They also serve one-handed play. No default key is set on the shared layouts until Orb picks (they have no spare keys on the left hand and right hand respectively beyond the cluster). Cost: four rows in `actions.json` (Tools' schema first), about 40 lines in `layout.gd` and the tests.

**Full touch.** The diamond's buttons are 83 dp apart with 30 dp radii, so one thumb cannot cover two. **Pairs are two fingers**, read with the same window (the touch window gets `touchBeatHalf`'s extra tick on the window if wanted). I would not add pair buttons now (the layout is full); an optional **pair chip at each of the four seams** is a UI change for later, behind a setting, and a one-finger path for players who cannot use two. **Pads:** adjacent buttons are a thumb's width apart, so a thumb can roll across two (the usual fighting-game technique) and the window of 3 may be tight for a roll; the assist factor (6) covers it.

**Remapping.** A pair is the pair of **actions** (light and context is X+A), so if a player remaps the keys the pair follows the actions, not the keys' positions. If they put X and A far apart the pair is still defined, but hard to press; **UI's remap screen should show a pair as "uses keys J and I" with a warning when two keys of a pair are not neighbours** (the layout can say which two controls make each pair from the layout data).

**Does it need intent bits or a version bump?** **No.** The pair is read from the edges in the intent (`light`, `heavy`, `sig`, `context`, `special`), their true ticks (`waited`) and the stance (`stanceMask`), all in version 4. The 10 spare bits (53 to 62) stay free. **Cost on a single press: 0 ticks.** What I can build in `sim/input`, pure and tested, when asked: `SimPressRead.pair_read(log, now, opts)` returning the pair and the two ticks (the `PAIR` kind, `pairWindow`, `pairFresh`), and the four one-key actions in the layout. The director's side (replace the blow, the pair attacks, their ki) is Encounter's and Game Design's.

**Is there a case for a cross-pad pair (X+B, Y+A)? No.** On a pad one thumb cannot press the two buttons that lie across the diamond; it needs a second finger or the other thumb off the stick, which is exactly the loss of control Orb asked the scheme to avoid ("players should always feel like they are able to control their character"). The only version that works is a one-key action (the pair macro above), which is not a cross-pad pair on the pad but a keyboard or accessibility binding, and it can carry any two cells. I have no pitch beyond that.

### Pair timing, checked against the live data (2026-10-05)

| Press | Contact after the press | In the pair window (3 ticks)? |
| :--- | :--- | :--- |
| Brawl light (X) | **2 ticks** (`brawl.light.contactTicks`; the first light from the close band steps in for at most `stepInTicks` 2 first, so 2 to 4) | **It can land first.** Kept; the pair is still thrown |
| Brawl heavy (Y) | 34 (26 wind-up, 8 to land) | Never lands first: replaced by the pair |
| Energy bolt | leaves 6 after the press (`blast.light.windupTicks`) | Replaced |
| Mid-band lunge | crouch 6 (light) or 10 (heavy), then the flight | Replaced |
| A (shove), B (signature) | A's shove wind-up is 8 (Game Design's clinch rule); B starts its motion at the press | Replaced |

**The freshness rule does not change.** It looks backward from the pair (neither button pressed in the 8 ticks before), and a light kept as the first press is the pair's own first press, not an earlier one. A light mash still never pairs (its presses are 6 or more ticks apart and each fails the rule for the next).

### "Decide at the release" for Y, and the same for A and B

**Y: no delay.** The heavy's motion starts at the press, its usual contact is 34 ticks later, and a release at 5 to 8 ticks (or anywhere up to 15) is far inside that, so the quick move lands at its usual time, 34 ticks after the press (the release plus 2 is 7 to 10, which is earlier, so "whichever is later" is 34). It costs a tapped Y nothing. At exactly 16 ticks still down it is the hold (the classifier's `held >= 16`), so a release at 15 is the quick move and one at 16 is not.

**A and B can be delayed, and that should be checked.** The quick move lands at the later of its usual time and 2 ticks after the release. For **A** the usual contact is the shove's 8-tick wind-up and the hold point is 18, so **an A that is released between 9 and 17 ticks after the press lands its shove at the release plus 2: up to 11 ticks later than a tap released inside 8** (19 ticks after the press against 8). For **B** (hold point 12) the same shape applies, with the zone being the ticks between its usual contact and 12. A **tap's length depends on the device**: a pad tap is about 3 to 6 ticks, a keyboard 4 to 8, a **touch tap 5 to 12**, so a touch player's A or B tap is the one that falls in the zone and gets a late shove. Two cheap mitigations if QA shows it: (1) land the quick move at its **usual time** and let a continued hold start the charge after it (the rule X already has, an instant move then a charge), which removes the wait for A and B at the price of a shove before every tackle; or (2) raise the hold points on touch by the touch tap's extra length. The first is simpler. I would have QA measure the share of A and B taps released in the 9-to-17 and usual-to-12 zones per device before choosing.

## 3. Mash, hold and alternation on X and Y

**What the layouts and the reader deliver now.**
- **Mash:** every press is an edge on its tick; the reader's `mash` is **kind-agnostic** (`press_read.gd` classify: the last 4 presses of any kind each within 10 ticks, still going within 20), so **a heavy mash and an X/Y alternation already read as a mash**, and the mix says how much of each: `mix_short` counts light, heavy, sig and context in the last 5, and the `recipe` is "blur" (no heavy), "combo" (heavies up to 60%) or "power" (over it), so an alternation is "combo". Nothing in the input stops Y mashing: the gap is the same 6-tick floor.
- **Hold:** `lightHeld` and `heavyHeld` are levels in the intent, and the per-cell hold is `holdLight` 8 and `holdHeavy` 16 (the reader's `hold_ticks_for`). The held X is the "set light" and the held Y the charged heavy.
- **What the director does with them is the gap:** the brawl's flurry follows light taps only (`TAP_GAP` in `brawl.gd:press`, `weight == LIGHT`); a heavy is a committed 34-tick blow, and a held Y is the heavy charge (`_hold`); **X's hold does nothing in the brawl** (the layout reports it, nothing reads it).

**What changes (all small, all in `press_read.gd`, pure, tested, when asked; no intent bit).**
1. **`alternation(log, n)`**: the number of switches between light and heavy in the last `n` presses that are each within the mash gap of the last, so the brawl can see "X Y X Y" as a mixup and not as a mix of two mashes. (The classifier today gives the share, not the order.)
2. **`mash_of(log, kind)`**: a heavy mash (Y presses only) and a light mash read separately, so "heavy mashing has the rapid attack pattern" is a rule the director can state. Data: `read.mashHeavyGap` if heavies are allowed a longer gap than 10 (Game Design's number).
3. Nothing in the layouts: every layout delivers the edges and levels the above needs, **except Simple**, where X is the Attack button (tap on release, hold 12 ticks is the heavy), so Simple has no light charge or alternation by button; its director picks.

**How a tap is told from the start of a hold without delaying the tap's blow.** It is not told apart before the blow, and **it cannot be for a light**: the press is an edge on its tick, the blow starts at once, and the hold shows later as `lightHeld` still true. A light's contact is 2 ticks after the press, and X's hold threshold is 8, so the decision comes after the blow has landed. Two ways to give Orb's "holding charges a light":
- **A (recommended): the tap's blow stays instant, and a held X becomes the charge of the next blow.** The press throws the light at once; if the button is still down at 8 ticks the fighter winds up a charged light (faster to charge than Y, less power, no knockback), released on the flash like a held heavy. Cost: every charge is preceded by one ordinary light, which suits a brawl (a light is the opener anyway) and costs the input nothing.
- **B: the press starts the wind-up and a quick release throws the tap.** Cost: every light's contact moves from 2 ticks after the press to about 8 or 9 (the release plus a wind-up), which breaks the "instant" the whole brawl is measured on (press to contact within 10 is Encounter's band). I would not do this.
- **Y needs neither:** the heavy's wind-up already starts at the press and is 34 ticks long, so its tap and hold are told apart at 16 ticks, well before contact.

## 4. Movement in a brawl

**Today the stick is read and carried in the intent (`mx`, `my`, 8-bit each, always), but inside a brawl the director uses it for one thing only: leaving.** `brawl.gd:867`: a boost with the stick away (`mx` times the rival's side below `-SimAct.awayDead`, 0.3) is the escape at the dodge-cancel's price. **Nothing else reads it in a brawl:** both fighters are in the `locked` state, and the only movement is the magnet (`brawl.gd:891` to `905`): while they are in the brawl it pulls them to striking distance and one height at `pullBhPerSec`, and lets go past `breakBh`. So the stick does not steer the pair, which is exactly Orb's "locked" and "the attraction was too strong".

**What Encounter needs from me for the stick to steer the pair: nothing new in the intent.** `f.input.mx` and `f.input.my` are already the nudge, per player, deterministic (on the 1/127 grid after `canon`), with the stick's dead zone (0.2 for movement) and the keyboard's full deflection. The rule is Encounter's and Game Design's (a bounded offset of the pair's centre that each player's stick moves at a rate and the magnet pulls back, shared by both players' nudges, clamped). Three input-side notes for it:
1. **A keyboard or a D-pad is full deflection or nothing**, so a nudge by position would be coarse for them; **make the nudge a rate** (the stick moves the centre at up to N bh a second), and for digital input ramp it by how long the direction has been held (about 0.4 to 1.0 over 12 ticks, data) so a tap is a small nudge. The director can count the held ticks itself from `mx` and `my`; I can give a pure helper (`SimAim`-style, data in `timing.json`) if it prefers one number.
2. **The escape and the nudge must not collide:** the escape needs **boost held** (LT held 12 ticks) **and** the stick away; the nudge is the stick **without** boost. They are already separate in the intent (`sprint`).
3. **Knockbacks and the `stunned` states** clear the stick in `wounds.gd` (it zeroes `mx` and `my` there), which is the "few exceptions" Orb allows.

## 5. A's three readings

A is the **context** cell: `context` is the press edge on its tick, **`contextHeld`** is the level (bit 51, built), and the classifier has the `CONTEXT` kind with its own hold **`holdContext` 18** (the prototype's number, Game Design to confirm).

| Orb's reading | Input it is | What exists | What is missing |
| :--- | :--- | :--- | :--- |
| **Tap: a shove** | One `context` edge, instant | The edge, with its true tick | The shove is a move (the director). It must start on the press like a light (contact within 6) |
| **Mash: a clinch into a trip into a throw** | Repeated `context` edges (3 or more within 10 ticks) | The classifier counts presses of any kind; the CONTEXT kind is logged | A kind-specific reading: **`mash_of(log, CONTEXT)` and a `clinch_read`** (3 presses in the gap is the clinch, 4 or more the trip, a count that Game Design sets; it is the same function as the zip's speed reading), pure, no bit |
| **Hold: a charged tackle** | `contextHeld` for 18 ticks | The level and the cell hold (the zip tackle already uses it: `zip_read`) | The tackle is a move; its charge, the crater and the no-damage-to-the-tackler are the director's and Game Design's |

**The same tap-against-hold rule as X:** the shove is instant at the press; holding past 18 ticks after the shove turns the held A into the tackle's charge. **A+B** (the grab pair, section 2) is the clean way to a grab that does not need a mash: an instant, deliberate pair. If Orb wants the clinch to start without a mash, that is the pair.

## 6. Rumble

**Orb picked:** every landed blow; closes, launches and landings; buildings breaking; beam struggles. Not the player's beat.

**Where the setting lives: not in the sim and not in the intent.** Rumble is output. It must never reach the sim, the replay or the hash, so **it belongs in the player's settings (UI's options, beside `left_handed` and the others), per player**, read by the host. **Proposal:** a per-player setting **Rumble: off, light, full** (default full on a pad and a phone), with a strength (the motors' scale) and, if wanted, four switches matching Orb's four picks (blows, closes and launches and landings, buildings, beam struggles). Nothing in `sim/input` stores it.

**What the host needs from the input layer: which device a slot is on, and whether it can rumble.** The hub knows the slot's device (`slot_device`, `slot_pad`) but exposes it as bare variables. **I will add a read-only `hub.rumble_target(slot) -> {kind: "pad"|"touch"|"kb"|"none", id: int}`** (the Godot joypad id for a pad; `Input.vibrate_handheld` has no id; a keyboard has nothing), plus the slot-to-device mapping can change when a pad joins or is lost, so the host should ask each time it pulses and not cache it. Same shape and risk as the armed accessors: read-only, no intent change, no hash change, a test. Not done yet because you asked for docs only.

**Mapping events to pulses (a Game Feel proposal for Rendering; the sim events are the existing fx).**
- **Every landed blow:** the **attacker** gets a short light tick (about 40 ms, the high motor at 0.3, a hit confirm), the **defender** a thump that scales with the damage (30 to 90 ms, the low motor 0.4 to 1.0). A heavy and a skill strike are stronger.
- **Closes, launches, landings:** both players, a full strong pulse (150 to 250 ms, both motors), the landing scaled by impact.
- **Buildings breaking:** both, medium, scaled by the structure (100 to 400 ms).
- **Beam struggles:** both, a continuous rumble for the struggle's length ramping with its pulse, ending with a strong pulse at the result.
- **A rate limit:** pulses nearer than 4 ticks merge, and a new one only replaces a running one if it is stronger, so a mash is a steady buzz and not 10 separate starts a second.
- **Capabilities:** the browser's gamepad vibration is patchy (Chromium supports it, others do not) and touch haptics only run on a handheld; the host should treat "cannot rumble" as off with no error, and **the web build's default should be off** unless the device reports support. Players who cannot feel a rumble lose nothing, because the beat's cue stays the sound and the glint, and rumble remains optional.

## Questions that go to Orb

1. **Which of the two cross-pad pairs, if any:** none recommended (section 2). Confirm "Y+X" is "Y+A".
2. **Should pairs cost ki, and may a pair be read right after a mash?** Recommended: yes, a price, and the 8-tick freshness rule.
3. **One-key pair actions on the keyboards and for one-handed play:** recommended yes (section 2).
4. **A held X charges the next blow, after an instant first light** (section 3, option A): recommended.

## What I can build next, in `sim/input`, on a brief

`SimPressRead.pair_read` (+ the `PAIR` kind, `pairWindow`, `pairFresh`), `alternation`, `mash_of`, `clinch_read`; the four pair actions in the layout and `actions.json`; `hub.rumble_target`. All pure or read-only, no intent bit, no version change, no golden change; data keys under `read` for Tools' schema first.
