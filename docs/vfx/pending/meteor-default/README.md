# Park: meteor-default (VFX, 2026-11-14; the grant for GW1a, A-RENDER-01)

The meteor trail on by default, with the loud profile Orb plays (`?meteor=loud`), so a build made plainly from main shows it with no launch word. Stacks after Rendering's two look diffs (`docs/rendering/pending/globe-default/`, `crater-look-default/`): they touch `render/core/main.gd` and `render/tools/`, this touches only `render/vfx/`, so the three apply in any order.

**Apply:** `git apply docs/vfx/pending/meteor-default/apply.patch` against main (clean on main 49fa623e, working tree; sha1 9bdef7027d04c6776f435615fcf3c73e33bc1074). Four files, all VFX's:
- `render/vfx/vfx_look.gd`: `METEOR_DEFAULT` true; new `METEOR_PROFILE = "loud"`.
- `render/vfx/meteor.gd`: `page_word()` now sets the default profile when there is no word and the default is on. This is the line the EP named: with the default on, `page_word()` was never called, so the profile was never set.
- `render/vfx/vfx_hub.gd:110`: `VfxMeteor.page_word() != "" or VfxLook.METEOR_DEFAULT` (the word is read first, so the default is never a short-circuit that skips the profile). `?meteor=quiet` still picks the base values on a local page.
- `render/vfx/tools/effects_check.gd`: the "off by default" check now asserts on by default with the loud profile, and the loud values arrive with no word; three checks that assumed the meteor off or the base profile say so explicitly (the data-frame check reads the `quiet` profile, the model-off check switches it off, the flight-lines checks set the burn off).

**What does not change:** the sim (hash_check passes on seeds 12345, 4 and 7 to tick 3,600, six ways, with the meteor ON by default: 279 s), the flight lines (still off: `FLIGHT_DEFAULT` false), the trail's start speed and the data in `data/vfx/meteor.json` (no grant needed; if the flight-speed default moves the start speed, that is the GW1 window's).

**Checks:** `effects_check` 1,168 ok, 0 failing; `validate` 0 errors. Saved: `docs/vfx/runs/8007de44/meteor-default-gates.txt`.

**The look gate:** nothing is meant to look different from the 9 November build, which plays `?meteor=loud`. Rendering's side-by-sides (`docs/rendering/img/lookgate/a1-globe-vs-nov9-*`) used `meteor=loud` as the stand-in for this grant, so the picture is theirs and already recorded; the EP's commit of this park is the change from the stand-in to the default.

**Flash:** the meteor trail is now on in every default clip. Its own readings are in `docs/vfx/meteor-trail.md` section 12 (scripted launch, both modes); the GW1a stack's readings (globe ground + crater look + this) are what A-LEGAL-01 needs, and the meteor is a switch in my controls (`docs/vfx/flash-readings-tile-ground-plan.md`).
