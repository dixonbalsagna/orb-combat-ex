# One flash register for a screen with two fights on it (VFX, 2026-11-07; Legal RL-249)

The ask (through the EP): Orb's first 2v2 showed two fighters on each screen, never all four, and Orb wants to see the partner's fight when it is near. Legal's RL-249 (1) to (7) say what drawing the other fight may do to the flash register. This is the register's half: one count per screen, the other fight's hub as a feeder, the other fight giving way, calm forms counted, and the desktop switch. Rendering leads the drawn-case plan (the panes, the beams, the hits); what Rendering needs from this is the API at the end.

## What was wrong
Each other fight's hub (`stage_feed.gd`) made its own `VfxFlashRegistry`, so its flashes asked a register that never saw the screen's own fight: the limits applied to each hub, not to the sum. Rendering's drawn beams of the other fight were calm and asked nothing.

## What it is now
- **One object.** The main hub's register is the screen's. Every other hub holds that same object (`VfxHub.adopt_register`, called by `VfxStageFeed.feed` the moment it makes the hub) and asks it on its own **channel**: 0 is the screen's own fight, `fight index + 1` an other fight. The hub sets the channel around its own `consume` and puts it back, so every flash a hub asks is tagged with whose it is, with no change at any of the ask sites (shots, press, reach, zip, biome, the blast cloud).
- **One clock.** Only the main hub runs `begin_tick`, sizes the register (`ppu`, `cam_dist`) and resets it. An other hub does none of these (`shares_register`).
- **The limits apply to the sum** (RL-249 (1)): the 2.5 gate (`TOTAL_GATE`) counts every grant on the screen, own, other and calm forms. The other fight's asks also meet the low, big and rate counts over the sum.
- **The other fight gives way** (3): its full flashes are held to `OTHER_CAP` (1.0 of weight at once, none under Reduce flashing). The own fight's asks are measured against the own fight's grants and the gate, so the other fight never takes the own fight's budget. No dissolve, fade, blur or marker anywhere: giving way is the source's own calm form (what every refusal already draws).
- **Calm is counted** (2): a refused other-fight flash draws its calm form and the register counts it at `OTHER_CALM_K` (0.2) of the flash's weight, up to `OTHER_CALM_CAP` (0.3) in a window. A calm form that does not fit is left to the source and shows in `calm_unfit` (the check wants none in the 2v2 scene).
- **Only what is drawn counts** (4): `flashes.set_visible(ch, on)` is the host's word for whether fight `ch` is on this screen. Off, its asks go to a shadow window and count for nothing; the tick it comes into view what it did in the last 60 ticks is counted from that tick (`swing_in` rows in the log). Unset, a fight counts as on screen (the safe default).
- **One catastrophe envelope** (1): ids are made per channel (a sim counter in each fight can be the same number), the other fight's event waits out the 2 s gap of any event, the own fight's event is never held by the other's, and the other fight's light is `min(its envelope, cat_room())` where `cat_room()` is one event's peak less the own fight's light now. So the light on screen never passes one peak and no tick steps more than the floor's (0.104 of the peak). Under Reduce flashing the cap is the calm peak (0.6).
- **Touching fights** (5): a hit from outside lands in the fight it lands in and is met in that fight's hub, so it counts in the register on that hub's channel with every other flash. Nothing to add.
- **The log carries the channel** (`log_rows()` index 8, `summary().by_channel`), so Orb's own count is printed per fight and together.

## The desktop switch (6)
`VfxHub.other_fights_enabled`: off by default (`VfxLook.OTHER_FIGHTS_DEFAULT` false). It goes on with `--otherfx` on a desktop run's command line (`VfxStageFeed.desktop_word`, never read on the web, so no public page or pin can turn it on) or `?otherfights=1` on a local page (unchanged). **Turning it on locks Reduce flashing on in the hub** (`reduced_flashing` takes `v or other_fights_enabled`), whatever the setting is written as, so every flash on the screen is the calm register. The warning is UI's line (NEEDS FROM EP); the effects stay off until Orb has seen them in the side-by-side.

## For Rendering (through the EP)
- **Whether fight `ch` is on screen:** each frame `vfx.flashes.set_visible(ch, in_view)` for each other fight's channel (`fight index + 1`), the pane's own decision (the fight's bodies in the pane's frame).
- **Beams and hits Rendering draws for the other fight** ask `vfx.flashes.ask_in(ch, source, col, tick, area_px, step)` (a flash) or `ask_cat_in(ch, ...)` (a catastrophe event) and draw the calm form when it answers false. The answer is the sum's.
- **A beam on screen is a light event** once it is on screen, drawn calm or not.

## The API shape I picked for Rendering's plan (docs/rendering/2v2-drawn-plan.md)
Rendering proposed `ask(kind, own_fight, catastrophe, first_tick) -> form`. The register already takes the kind (its source), so the shape is:
- **`flashes.ask_form(ch, source, col, tick, area_px, step) -> "full" | "calm" | "later"`** for a flash with a calm form (the other fight's beam, a hit, a shared-world glow). `ch` is `own_fight` as a channel: 0 the screen's own fight (never made to give way beyond its own rules), `fight index + 1` an other fight. "full": draw it. "calm": draw the thin, slow form; it is counted. "later": even the calm form does not fit: start it `flashes.ticks_until_room(w)` ticks from now, or draw none of its light. Nothing is hidden, dissolved, faded or marked.
- **`flashes.ask_cat_in(ch, ...)`** for a catastrophe-class event (`catastrophe`); its light is bounded by `flashes.cat_room()` so the two fights share one envelope.
- **`first_tick` is not an argument.** The count starts on the tick the caller first asks, and `flashes.set_visible(ch, in_view)` is the on-screen test (off, asks go to a shadow window and count for nothing until the fight is in view).
- **Shared-world light** (a crater's glow and colours, a collapse, whichever fight made it) asks as the own channel (0), the same way the main hub's craters do, so it is in the sum once.

## Hard cuts (CD-04, with Camera)
The audit's CD-04 asks the camera's hard cuts that change most of the screen (`split_rig.gd` `_mark_cut` callers: side_swap, relocate, rush_pin, solo_cut_in, insert, transform, intro and the rest) to ask the register. The register's half, built here: **`flashes.ask_cut(why, area, step, tick) -> {"form": "cut" | "ease" | "wait", "wait": ticks}`**.
- A cut is one transition and the analyser counts a flash as a pair, so a cut is weighed as a whole flash on purpose (cut, cut back: two). Its weight is its area against the standard's window (a cut over 2.8% of the frame is a full flash), its step the luminance change it makes there (under 0.10 it costs nothing; unknown, weighed by area).
- "cut": granted, cut now. "ease": refused and no room within half a second: the frame eases to the new view, as a whip does, instead of jumping. "wait": refused, room in `wait` ticks (30 or fewer): the cut may be held that long. Never a dissolve, fade or marker. Under Reduce flashing the budget is 1.0, so a second whole-screen cut inside a second eases.
- **What Camera does:** call `ask_cut` (or the existing `ask_register("hard_cut", area, step)`, which is the same ask) before each `_mark_cut` call that changes most of the screen, with the area and the step it can read from the two views; on "ease" take its whip path (`_catch_up`'s) and on "wait" hold. VFX does not touch `split_rig.gd`. The numbers (the area and step of each cut, which cuts are exempt) are Camera's to measure; a saved reading in reduced mode (CD-04 (1) and (3)) comes from Camera's run on the fixed analyser (CD-09).
- A whole-screen brightness guard (checks-review M-07) is the other option in CD-04; it needs the frame's luminance, which the register does not have. This is the cheaper of the two and it counts the cuts the sim and the camera already know about.

## Checks (`effects_check` `_shared_register`)
The other fight's first beam is granted, its second gives way and its calm form is counted; the own fight's beam is not refused; the sum is the three and under the gate; a hundred refused asks never hold more than the calm cap; under Reduce flashing the other fight has calm forms only and the own fight keeps its whole 1.0; 4,000 ticks of heavy random asks with every own difference counted; off-screen counts nothing, and counts from the tick it swings in; two events with the same counter, one in each fight, are two events; the gap rule both ways; both fights' catastrophe events in the same second in both modes (peak and steepest tick); the switch off by default and locked calm on; and 1,500 ticks of two computer fights with the other fight's hub on the one register and the own fight's rows unchanged.

## Not built
- The panes' own visibility call and the drawn beams' asks (Rendering's).
- The warning line and the lock's UI (UI's).
- The clips (both fights drawn, both modes, day and night, the worst-case scenes) go to Legal after the park is gated.
