# A push on a layer where the right stick is inert is told (switches.inertKnock)

Owner: Controls. Park: `docs/controls/pending/inert-knock/`. Records: `docs/controls/runs/c974e451/inert-knock-*` (CD-22). From the EP's overnight brief of 2026-11-08, item 3 ("the RT + right-stick worded knock, still silent").

## The silence

`strike.inertMasks` (`data/input/timing.json`, default `[3, 4]`) names the stance layers where the strike stick does nothing: RT held (mask 4, the power charge owns the stick, pure 4a) and LB + RB together (mask 3). A push there takes the strike reader from IDLE to IGNORED (`sim/input/strike_read.gd`): no request, no strike, no `rsStart`, so the hub has nothing to wait for and the director nothing to refuse. The press just does nothing and says nothing.

## The fix

With `switches.inertKnock` (off), on the build the reader goes IDLE to IGNORED the layout adds one refusal to the dropped list it already keeps (`take_dropped`): `{k: "stick", why: "charging"}` for RT, `"warding"` for LB + RB. The hub already turns every dropped press into one pad knock (`stick_refused`, with the reason) and one row for UI (`take_refusals`), so nothing else changes. The reader stays IGNORED until the stick rests, so a stick held out for two seconds is one knock; a second push after it rests is a second.

Not told: a struggle's flick (it means surge or let-go), a stick-push struggle, the Driver's bank (B held in the energy layer: also inert). RB held alone is the beam layer (a request), and LB alone is not inert, so neither is told here.

Words (UI owns the final strings): `charging` "Charging", `warding` "Warding" (`SimHaptics.REFUSALS`, owner Controls).

Needs `rightStick` and `hapticRefused` (the hub's refusal cues).

## Conflict to settle (Game Design's ruling of 2026-11-08 (b)); the EP's plan: RT + stick becomes the signature, then `charging` goes and `warding` stays

The signature is meant to move to RT + the right stick (`docs/design/beam-answers.md`, `overnight-2026-11-08.md` (b)). That path is not built; today RT + stick is inert, so this park's `charging` knock tells a player, truthfully, that RT + stick does nothing. When RT + stick becomes the signature, `charging` must go: a data line (`strike.inertMasks` without 4) switches the read on, and this switch's RT case should be dropped with it. `warding` (LB + RB) is unaffected.

## Tested

- `inert_knock_test` (11): RT held and a push is one knock and one row, code `charging`, and no strike started; the stick held 90 ticks is still one; a second push after a rest is a second; LB + RB is `warding`; no layer or RB held is a strike request and nothing told; LB alone and RT with no push say nothing; both codes have their word. Off (the control): the same RT and LB + RB pushes start nothing and say nothing.
- Negative control: with `layout.gd` put back, the four knock checks fail.
- All 41 input tests pass; lint and validate clean (321 files, 0 errors); the patch reproduces the tested tree byte for byte and applies to the working tree at 4b090e10 alone and together with `b-no-beam`.
- Not run: the parity golden (a human's right stick under RT only), director checks, `hud_check`. Nothing in the sim or the intent changes (a refusal row and a pad knock only), and the switch is off.

## Risks

- With RT held to charge a power, a thumb resting on the right stick will knock the pad on each push. That is what was asked for; if Orb finds it noisy, `strike.inertMasks` without 4 stops it (and the stick does nothing, as before).
- UI needs the two words (`charging`, `warding`); until then UI drops a code with no word (the knock still comes).

## To turn it on

Flip `switches.inertKnock` (a Tools page row, or in the landing commit).
