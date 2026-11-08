# The creative rulebook's rows (Animation, 2026-11-07)

Every pose, gesture and look row Legal handed over (`docs/legal/creative-rulebook-handover.md`, commit cb477edf), kept under its old id so old reports still read. Generated from `docs/legal/movegen-banned.json`, which stays where the generator and lints read it; the text below is a trimmed copy, the file is the full text. **Status for every row: in force as a studio rule, owned by Art and Animation under Orb (RL-258), until Orb, Art or Animation change it here.** The *read by* column names the lint or generator that still enforces a row; everything else is a taste note that no tool reads.

Two rows are mixed (the handover splits them): **k03** (charge flash or ring: colour and size are ours; never a white or red flash is a flash-safety limit and stays with Legal under k05) and **e13, e14** (mines, snares, trap pillars: the shapes are ours; a glow's rate of at most 1 Hz with 6-tick fades is a light limit and stays with Legal under k05 and k06). Withdrawn w01 and w02 are not carried.

## Banned shapes (b01 to b14)

| Id | Rule (trimmed) | Read by |
| :--- | :--- | :--- |
| **b01** | two hands with wrists together pushed forward: a famous beam-release pose | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b02** | hands cupped at a hip, or drawn back to one hip and thrust: the franchise's best-known wind-up. Applies to every weight and every form, including held heavies | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b03** | a rising blow with a leap or a spin, by hand, elbow or knee: the jumping, turning uppercut | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b04** | more than a single turn, or a spin that travels: a multi-hit whirling kick | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b05** | two clasped fists brought down: the double axe-handle smash | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b06** | a clawed hand or grip on the face | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b07** | grips on the throat, hair or tail are never used (the grab rules) | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b08** | an arm passing through the body | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b09** | a melee piece never carries light, a ball or a raised charging pose | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b10** | two fingers or a pointing finger, or a hand to the forehead: the franchise's beam and teleport poses | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b11** | a beckoning hand | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b12** | a held or charged medium or heavy is loaded with one arm drawn back at shoulder height, never at a hip and never with both hands together; the new words medium and charged loosen nothing | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b13** | no vanish or blink between blows; the fighter is drawn the whole way | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **b14** | the jumping rising uppercut and its kin; ruled 2026-10-12 for the Hopper | movegen generator (movegen-banned.json read by the move generator and its lint) |

## Banned sequences (s01 to s09)

| Id | Rule (trimmed) | Read by |
| :--- | :--- | :--- |
| **s01** | a barrage of identical blows is a famous shouted-barrage signature | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **s02** | a stomach-punch trade; also keeps Blow for Blow ours | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **s03** | a chanted barrage; audio and the generator both enforce it | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **s04** | a multi-turn whirl; also the grammar's light rule | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **s05** | an aerial uppercut chain | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **s06** | the double smash ender (see b05) | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **s07** | the vanishing-step staging | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **s08** | s02 applied to the clinch; Orb's design and the rating question are still open (not cleared by this row) | movegen generator (movegen-banned.json read by the move generator and its lint) |
| **s09** | ratings (PEGI 18 treats violence towards defenceless people as its own descriptor; stricter markets) rather than IP; the Hopper's stomp, ruled 2026-10-12 | movegen generator (movegen-banned.json read by the move generator and its lint) |

## Motion (m01 to m12)

| Id | Rule (trimmed) | Read by |
| :--- | :--- | :--- |
| **m01** | a zip (any reading) is drawn on every tick: the body is visible and opaque on each tick of the way in and the way out, never hidden, faded or swapped for a copy | taste note, no tool |
| **m02** | a zip's way in and its way out each last at least 4 ticks, and consecutive drawn positions are at most 3 body heights apart (ticks >= max(4, ceil(distance in bh / 3))) | taste note, no tool |
| **m03** | the path is continuous: the body passes through every point between start and arrival, and any copy or echo trails behind the body, never ahead of it, never at the arrival point before the body gets there | taste note, no tool |
| **m04** | a far-side exit is its own drawn travel that starts after the strike hold, over the rival or round him, with the rival's body in view throughout; he never appears behind the rival in the same tick as the strike | taste note, no tool |
| **m05** | a zip ghost is a flat single tint in the fighter's lane colour (never the body's own colours or face), opacity 0.35 or less and fainter for older ones, at most 5 per zip, on the body's real recent path, each overlapping the next by about a third so they read… | ghost_tally.gd (a code constant) |
| **m06** | the body is always drawn on top of its ghosts at full opacity, and no ghost stays behind as a stationary copy | taste note, no tool |
| **m07** | a heavy's wind-up ring is hollow, thin, in the lane colour, shrinks onto the striking fist and never grows or holds, lasts the wind-up only (10 ticks or fewer), and never fills or becomes a ball at the hand | taste note, no tool |
| **m08** | outcome marks (counter bar, closing ring, brackets, guard fragments) carry no text or numbers, never sit on the eyes or face, and are never a full-screen or body-wide gold, white or red flash | taste note, no tool |
| **m09** | in a zip chain each hop meets m01 to m08 on its own: the strike pose is held at least 4 ticks at contact with the body drawn, the ghosts on screen across the whole chain are at most 5, no ghost is left behind or placed round the target, and there is no camera… | taste note, no tool |
| **m10** | a zip at a launched rival follows his drawn body along a continuous path; it never snaps to where he will land | taste note, no tool |
| **m11** | a slip or a step that goes behind the rival is drawn travel of at least 4 ticks with the rival in view (m04) | taste note, no tool |
| **m12** | body ghosts (whole-figure copies from any source: zip, press styles, tech echoes, Animation's after-images) are budgeted per fighter at any instant: at most 5 round one fighter from all sources together, so at most 10 on screen with two fighters; limb ghosts… | taste note, no tool |

## Energy poses and looks (e01 to e10, e12 to e16)

| Id | Rule (trimmed) | Read by |
| :--- | :--- | :--- |
| **e01** | no sphere or ball in or at the hand, at rest or growing; a charge is light on the forearm plate or hand edge, and the blast leaves along a line | taste note, no tool |
| **e02** | an energy hand is open or a blade, no higher than the shoulder; never cupped, never both hands pushed from the chest or drawn to a hip, never wrists together (b01, b02) | taste note, no tool |
| **e03** | no two extended fingers, no single pointing finger as an emitter; the pinch is thumb to forefinger only (b10) | taste note, no tool |
| **e04** | a short beam or charged shot is a plain straight line: no spiral, drilling or twisting beam; a second hand may brace the arm but never grips the firing wrist and never sits cupped under it | taste note, no tool |
| **e05** | a volley is one motion of one hand or arm (a sweep, a flick or a single thrust) that releases the fan; never both palms pumping forward in turn or one hand pumping repeatedly, and no repeated shouted syllable across it (s03) | taste note, no tool |
| **e06** | a burst, a blast and a ki-style flurry (B), and an energy blow in reach (RB + X or Y), are thrown by one hand at shoulder height or lower: an open hand, a blade hand, or the rival's lit fist with the light on its plate and knuckle edges only (the cleared fist… | taste note, no tool |
| **e07** | a beam held and steered by the player stays a plain straight line; steering moves the aim or the origin only, never twists, spirals or whips the beam, and the firing pose does not change while it is held | taste note, no tool |
| **e08** | R1 adopted: an energy blow in reach is one open, blade or lit-fist hand at shoulder height or lower, lit as a thin edge before it lands, the shot going off at contact as a thin edge or short cone, each body taking a rim of its colour on the near side and neve… | taste note, no tool |
| **e09** | a mashed run of point-blank bolts must read as varied on screen, not only in data: no two bolts in a row with the same arm, path and place; no regular left-right alternation (an irregular order, with the free arm taking a bolt now and then); at least three di… | taste note, no tool |
| **e10** | a beam cast pose (the signature beam and any other): one arm out, the palm or its heel leading, is allowed when the other hand never grips, braces or cups the firing wrist or forearm and stays at least shoulder width from it (open, in guard, or low at the rea… | taste note, no tool |
| **e12** | energy grabs: the ring binds and never cuts (no spinning disc, no edge, no sparks, never held, charged or raised above the head, never a saw); binds take arms, torso or body, never throat, face or hair; the held fighter is drawn struggling or bracing, never l… | taste note, no tool |
| **e13** | mines, traps and snares: small, in the fighter's colour, dim arming, a slow glow at or under 1 Hz, a 6-tick flare; fizzle after 12 s and never survive their fight, never a lasting hazard for the places or people of a run; never moved toward people or laid on… | taste note, no tool |
| **e14** | energy looks from the v2 names: a trap pillar is ground or a solid lane-colour slab (a post a few bh tall) rising over several ticks, never a vertical beam of light into the sky and never round a body; a sheaf of lances is straight, parallel, thin and unrotat… | taste note, no tool |
| **e15** | the four energy kits: no net or ring wind-up drawn to the hip (draw to chest or shoulder height); an open palm chambered for a heavy stays at chest height and passes the lint at every tick; a lob's object forms as it leaves the hand and never on the palm duri… | taste note, no tool |
| **e16** | the Empress's banner cage: four banner staves stamped into the ground round him with cloth banners wrapping his arms and torso only; no lines of light joining the staves into a box or a four-point barrier, no dome, no cell, no hand sign, never six plates pinn… | taste note, no tool |

## Grabs (g01 to g08)

| Id | Rule (trimmed) | Read by |
| :--- | :--- | :--- |
| **g01** | a hold point is the collar, shoulder, upper arm, body, waist or ankle; never the throat, the hair or a tail (b07), never a clawed hand on the face (b06) | taste note, no tool |
| **g02** | no hands locked or laced between the two fighters at any time, and nothing glowing at the hands in a hold | taste note, no tool |
| **g03** | a lift or carry is drawn whole: the carried fighter's body is in view and never hidden by a zip or a cut; a throw is a launch (the planner), not a vanish | taste note, no tool |
| **g04** | a tackle takes the body at the waist or shoulders; the carry is drawn travel (m01 to m04 apply: at least 4 ticks, the carried body in view every tick, 3 bh a tick at most); the arrival crater is local, with debris falling and no rising ring of rubble, no ligh… | taste note, no tool |
| **g05** | a clinch is a collar-and-elbow or waist hold; the trip and the throw never lift by the throat, hair or a tail, and the two fighters' hands are never locked or laced together; no sparks or glow at the hands in the clinch | taste note, no tool |
| **g06** | the tied pose (the clinch hold): collar-and-elbow or waist (g05); the holder's hands never lock or lace with the held fighter's; the held fighter's hands stay free and are never drawn limp, bound or pinned behind the back; both fighters upright, heads and tor… | taste note, no tool |
| **g07** | the pin is vertical against a surface (wall, building, cliff) at the shoulder, collar or upper arm; no forearm or hand across the throat or face, no choke (g01); no ground pin, mount or straddle of a downed fighter (s09's defenceless case); hips apart; the pi… | taste note, no tool |
| **g08** | the carry: over the shoulder or by the collar and waist; never by the head, neck, hair or tail; the carried body is drawn whole and in view every tick (g03, g04), face and chest never hidden or pressed to the holder; no sparks or glow at the hands (g02); the… | taste note, no tool |

## Held poses (h01 to h10)

| Id | Rule (trimmed) | Read by |
| :--- | :--- | :--- |
| **h01** | held 12 ticks or more, scoped by class (see heldScope): the pair test applies to every held pose; the emitter test applies to the charge, tell, signature, energy and hold classes only | held lint (anim_held_lint.gd pair and emitter tests) |
| **h02** | no held crossed forearms; no held arms-wide invitation. Arms wide means both arms near straight (elbows within 25 degrees of straight) and both hands 32 or more out to opposite sides, held 12 ticks or more; a shrug (elbows bent 40 degrees or more, palms up, s… | held lint (arms wide, crossed forearms) |
| **h03** | a signature's tell is its own stance, never a crouch with fists clenched at the sides, and carries no scream | taste note, no tool |
| **h04** | held-lint classes for the new holds: a held X, Y or B charge pose and the tackle's coil are class charge; the seize, breaker, lift and slip tells are class tell; the clinch hold is class hold; the 45-tick taunt is class gesture; an open-hand chamber in a char… | held lint classes |
| **h05** | a medium or heavy wind-up of 12 ticks or more is a held pose of class charge and is judged at every tick by h01 to h04: the loaded limb at shoulder height or lower (a leg may be chambered), never at a hip for any hand state, never both hands together, no limb… | held lint (windups) and anim_check |
| **h06** | a deep sink (the heaving drive) is a lunge-low stance with the striking limb loaded and the other hand up in guard; never both fists clenched at the sides in a crouch, and never with a scream, an aura or ground cracking; the falling drive's rise is the body s… | taste note, no tool |
| **h07** | a manner (the rival's show-off, the Protagonist's pointed) is a way of throwing, not a gesture: the rival's open tell keeps the limb drawn back (never arms spread as an invitation, never a beckon), and his limb left out after landing lasts 12 ticks or fewer;… | taste note, no tool |
| **h08** | a heave (the deep-sink rising blow) may take one sliding half step of up to about 22 units when the closing slack needs it: the rear foot stays on the ground, no leap, no rise before the blow (the stand is the heave's own), the other foot never leaves the gro… | taste note, no tool |
| **h09** | folded arms are a held crossed-forearms pose and fail h02 at 12 ticks or more: allowed on a sheet and as a moment under 12 ticks, never as an idle, stand-off or intro pose; a one-arm fold (a single forearm across the body, the other hand free or at the chin)… | taste note, no tool |
| **h10** | a finisher's closing pose is a held gesture after a blow and must not mock a beaten rival: an offered hand is one hand, fingers together and still (no curling, no wiggle), palm sideways or toward the fallen rival and not at the camera, held low (forearm out,… | taste note, no tool |

## Marks and stacking (k01 to k04)

| Id | Rule (trimmed) | Read by |
| :--- | :--- | :--- |
| **k01** | at any tick, no more than two of the seven marks (crouch with clenched fists, scream, upward flame aura, rubble ring with ground crack and wind, lightning on the body, hair change, a flash with a shouted form name); a held tell or a 45-tick charge is checked… | taste note, no tool |
| **k02** | a stance tell's aura is a thin outline or short scattered streaks in the lane colour; a manoeuvre trail is thin and in the lane colour; a defensive rim of light sits on the guarding side only | taste note, no tool |
| **k03** | a charge flash or ring (a tier mark at 16 or 24 ticks for a medium, 32 or 44 for a heavy, a full-charge flash, or the wind-up ring) is a thin ring or edge flash on the charging hand, forearm or plate, in the lane colour, 4 ticks or fewer, never body-wide, nev… | taste note, no tool |
| **k04** | a mutual throw-back, a spark-lock between two heavy commitments, a power-attack tell and a taunt's finish show no rubble ring with cracks and wind, no lightning on bodies, no body-wide aura and no gold, white or red flash; sparks sit at the contact point only | taste note, no tool |

## Flurry (f01 to f05)

| Id | Rule (trimmed) | Read by |
| :--- | :--- | :--- |
| **f01** | a flurry's or burst's blur follows each striking limb's real path: at any instant at most 2 ghosts of any limb and at most 4 limb-ghosts on screen in all; never extra arms, legs or fists drawn at once, never a fan of limbs round the target. This replaces the… | held lint (ghost count) |
| **f02** | targets and pieces rotate across the whole string, whatever mix of X, Y and B made it: s01 and s02 count the string, not the button (no more than 2 blows in a row to the same target, never two gut blows running, no more than 3 of the same limb, tip and path) | taste note, no tool |
| **f03** | vocal sounds in a flurry: no repeated shouted syllable across it, no shouted word, and at most one grunt for every two blows, varied | taste note, no tool |
| **f04** | a gap of under 6 ticks between blows never runs for more than 3 blows in a row, and only inside the opening of a burst; blows then slow (a held X's 4, 4, 5, 6, 8, 11, 15 gaps are within this) | taste note, no tool |
| **f05** | a burst (held X, eight lights) never repeats the last blow's limb, tip, path or place; no more than 2 blows in a row on one path; no piece twice in one burst; the hands alternate; the sound is one breath for the eight, never a syllable for each; no slow-motio… | taste note, no tool |

## Look rows (w03, fx01, fx02, sg01, mc04, mc05)

| Id | Rule (trimmed) | Read by |
| :--- | :--- | :--- |
| **w03** | a landmark has no clock face, no red and white striping, no stripes or beams of light, no antenna mast on a stepped tower, no multicolour night lighting on a tower top, and no pair of thin pale spires on a dark tower that reads as horns | taste note, no tool |
| **fx01** | the shine on a striking hand (timing cue): two thin edge lines and a small hollow ring in his colour lightened, steady (no pulse or flicker), never a ball or glow, never white, on one hand at a time (k01), gone when the window closes; it is a rendering cue an… | taste note, no tool |
| **fx02** | the cash-in: a thin committed line and four closing corner brackets (no numbers or text, not on the face), then a double ring, a crossed crack, one thin vertical cut and two puffs of dust, 10 ticks or fewer, in lane colours | taste note, no tool |
| **sg01** | built from cleared parts; screened as a whole 2026-10-12 | taste note, no tool |
| **mc04** | the rally: the sell is one flash event at most per sold blow, never limp, no slowing beyond the hit-stop, no attacker's taunt over a dazed fighter (the dazed fighter's own laugh or grin is allowed), the camera push brief and eased; grabs in flight follow e12,… | taste note, no tool |
| **mc05** | elite henchmen under mc01: a trick is picked from the fixed list of six by the stage's seed and stage data only (column, boss, difficulty), never by anything the player did (how he beat the last elite, his habits, the ledger, to counter him); an elite appears… | taste note, no tool |

