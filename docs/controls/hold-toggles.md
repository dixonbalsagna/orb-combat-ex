# Hold or toggle: Guard, the manoeuvre and charging stances, Transform

Controls, 2026-10-28, for Accessibility's audit item 2 (`docs/accessibility/audit-2026-10-28.md`, "Holds and toggles"). Built the way `energy_style` is: an accessibility option per player, the layout does the work, the sim learns nothing.

## What it is

Four actions that had to be held now each have a **hold** (the default, nothing changes) or **toggle** style, per player:

| Option (and `_p2`) | Hub action | Control (Arena pad / solo keyboard) | Toggle means |
| :--- | :--- | :--- | :--- |
| `guard_style` | `guard` | LB / Shift | press once to guard, press again to stop |
| `manoeuvre_style` | `dodge` | LT / Space | press once to start the manoeuvre stance (its dodge on the press, its sprint after the hold time), press again to stop |
| `charge_style` | `power` | RT / E | press once to charge, press again to stop (a quick start and stop is the power tap, as for a quick hold) |
| `transform_style` | `transform` | LT and RT together / Space and E together, or the transform key | press the controls once together and let go: the half second counts on its own and the transform is sent; one press of either control before then cancels it |

Energy already had its own (`energy_style`) and is untouched.

## How it is fed (the sim reads no new input)

`SimLayout.press` and `release` now sit on top of `_real_press` and `_real_release`, which are the old code. Under **hold** they pass straight through. Under **toggle**, for a control that carries only guard, dodge or power on its own:
- the press that starts a toggle goes to `_real_press` (the same code a held finger reaches, at the same tick);
- the finger's release does nothing;
- the next press goes to `_real_release` at its own tick (the release a held finger would have made then), and the release after it does nothing.

So the layout builds the **same intent, bit for bit,** that a held button builds from the matching presses: `hold_toggle_test.gd` runs both through the real hub into `SimCore` and compares the packed intents tick by tick and the state hash. `SimIntent` has no new field; nothing in `sim/core` or `sim/director` changed.

A key's auto-repeat is not a second press (`_phys` tracks the finger itself).

**Transform** is a count, not a hold, so its toggle is a latch on the count: the chord (or the transform key) counts `transformConfirm` ticks from its press as before, but a release does not end it; it ends when it is sent, or when a press of one of its controls cancels it. That cancelling press does nothing else (no dodge, no power press), and its release is swallowed. Under **toggle** the chord still needs both controls down at once for a moment (inside `chordWindow`), as the chord always has; what toggle removes is holding them for the half second. The ring (`transform_hold`) keeps filling with no finger on it. When it is sent, the toggled dodge and power holds that made the chord go with it, so no stance is left on.

## What ends a toggled state on its own

Only these, and each matches what a held button does:

| Event | What happens | Why |
| :--- | :--- | :--- |
| the stop press | ends it | that is the toggle |
| a new match, a lost pad, focus lost (`release_all`) | ends all | a held button is let go the same way |
| the style set back to hold | ends it at once (a finger still on the control keeps it until it lifts) | the player turned it off |
| Transform sent | ends the chord's toggled dodge and power | the stances were only the chord's fingers |
| **a hit taken** | **nothing** | a held finger is not lifted by a hit either: the sim gates the held states for the stun ticks (`wounds.gd`: guard, power and dodge read false while `stunTicks > 0`) and they resume after, for a latch exactly as for a finger. Ending guard on a hit would end the guard that was just used |
| **a launch** | **nothing** | Game Design's ruling (2026-10-28): a launch keeps the toggles, as it leaves a held finger down. The sim already ignores the held states while the fighter is launched or stunned |
| **a KO** | **both players' toggles go away** | Game Design's ruling (2026-10-28). The host hands the tick's events to `hub.on_events(S.out.fx)`; a `"ko"` event calls `let_go_toggles` for both slots (guard, dodge and power put away, a counting transform cancelled). The host line is parked (`docs/controls/pending/ko-toggles/`) until Rendering's file takes it; until then nothing ends a toggle at a KO |
| another stance button pressed | the newer stance wins, as with two fingers; the older toggle is still on underneath and comes back when the newer is toggled off | `SimStance` is exclusive and newest-wins; the toggle does not change that rule |

After a knock-down (a launch) the toggled guard rises again at once if nobody pressed stop. That is what a held finger does too, and Game Design kept it. A KO ends the match, so a toggle left on would carry into the next fight's first tick; the new match's `release_all` already clears it, and `on_events` clears it at the KO itself so the result screen and any rematch prompt start with no stance on.

## The options and the host

`ui/data/options.json` gets eight rows (`guard_style`, `manoeuvre_style`, `charge_style`, `transform_style`, each with `_p2`), choices `hold` and `toggle`, default `hold`, marked accessibility; `ui/data/settings.json` lists them under Controls after the energy rows and gives the labels; player two's four show only while two people play (`ui_settings.gd`); `render/core/main.gd` forwards each to `host.hub.set_hold_style(action, style, slot)`, at start and on a change. All of that is outside Controls' paths and is parked (`docs/controls/pending/hold-toggles/`).

`SimInputHub.set_hold_style(action, style, slot = -1)` and `hold_style_of(action, slot)` are the hub's side. Touch is not covered (ADR 0011; a thumb on glass has its own one-shot).

## The check

`sim/input/test/hold_toggle_test.gd`, 88 checks (the last 12 are the KO rule: a toggled guard for both players on a real match, then the sim's own `SimFx.launch` event, which leaves both on, then `SimFx.ko`, which puts both away and leaves them away, a fresh press after it toggling guard on again; the negative control runs the same with the host never calling `on_events` and both guards stay on; other events and an empty feed change nothing; mutated to ignore the KO, or to end on a launch too, it fails 2 of the 88 each):
- for guard, dodge, power, the transform chord (sent, and cancelled) and the transform key (sent, and cancelled), on the keyboard and the Arena pad where both exist: held and toggled sequences give the same packed intent on all 160 ticks and the same state hash after the run, and the run has the thing in it (so an empty comparison cannot pass);
- the transform chord with dodge and power toggled too: one transform, the same as holding, and no stance left on after it;
- two negative controls: the toggled stream with the style left at hold is **not** the held one, and with the stop press missing the guard is still on at the end;
- the auto-repeat of a held key, player 2's own style while player 1 holds, the style going back to hold (at once, and with a finger still down), `release_all`, the ring and the cancel, `let_go_toggles`.

A mutation run (`_tog_on` made to return false) fails 24 of the original 76. The test calls `hub.on_events` itself; the one host line that calls it in the game is covered by the render determinism gates (they run `SimHost.tick`), not by this test.

## Left alone

Hint words ("Guard (hold)" in the legend, the Remap helps "Hold to guard.") still say hold for a player who chose toggle; that is UI's, as the energy legend is (`UiHints.energy_style`). Nothing is tuned: whether a toggled Guard needs a balance change is the EP's and Game Design's call (see the report).
