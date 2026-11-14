# A second player's joining press isn't a move (for GW1b)

Rendering, 2026-11-14, on Controls' question via the EP. `join_press.diff` (sha1 5e92331e, one line of `render/core/sim_host.gd`) applies on main, and after A-CODE-03's report hook.

## What happens

- **A match started from the menu is clean.** While a menu or any overlay is open, main forwards no pad input to the hub (`main.gd` `_pad_event`), so the press that starts a match never reaches a fighter.
- **A second player joining mid-match carries their joining press.**
  - A new pad's button assigns it slot 1, starting the join, and the hub records the same press on that slot (`sim/input/hub.gd` `pad_button`: `_pad_slot`, then `.press`).
  - The host's `take_players` hands the slot from the computer to the player before the tick's intents.
  - So the joining player's first intent holds the button they pressed to join. With A, that's a `context` edge, which the 9 November bands read as a taunt that eats the next press.
- **The probe** (`docs/rendering/runs/3070ef10/join-press.txt`, on the EP's GW1a stack, through the real main) shows a `context` edge as it is, and nothing with the fix.

## The fix

`take_players` lets go of the joined slot's device as it hands the slot over (`hub._claim_release(s)`, the hub's own release for a slot's device: every held control and pending edge). The joining player starts with an empty intent; their next press plays.

`_claim_release` is Controls' function (`sim/input/hub.gd`), called from the host. If Controls would rather swallow the joining press in the hub itself (not record it on the new slot), that's cleaner, and this line goes. Their call.

## Proof

The probe above. The render gates and ground checks weren't run for this one line (the EP asked for no long runs); they run with the GW1b batch.
