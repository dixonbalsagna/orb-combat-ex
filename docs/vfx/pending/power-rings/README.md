# Parked: the power-up rings hug the fighter (VFX, 2026-10-19, on HEAD 72cc1b9d)

Orb (via the EP): the purple concentric rings around a fighter powering up obscure him (homework/camera/3-chase-not-hold/1-a-launch-t00181.png). One data file, no code, no grants.

## Apply
`git apply docs/vfx/pending/power-rings/apply.patch` (checked with `git apply --check` on a clean HEAD export). It changes data/vfx/transform.json only:
- break ring: radius 0.7 to 4.2 fighter heights becomes 0.55 to 1.2, thickness 0.045 to 0.04, alpha 0.95 to 0.8 (the ring leaves at the aura's own size)
- gather: the lines drawn inward start at 1.4 heights (was 2.6), 0.4 long (was 0.55); the dimming disc (6 heights wide, alpha 0.16) is off (dim_alpha 0)
- break flash: the coloured disc over the body is off (flash_alpha 0); the aura swapping and the ring are the break

## Checks
validate 0 errors; transform shapes and counts are as before (data only). Side by side before and after on the Protagonist's tier-4 power-up at ticks 1240 to 1310 (homework/power-rings/, private).

## Honest limits
Not a Legal clearance (nothing added; a flash, a disc and a dim removed). Flash readings not re-run. The "POWERS UP TIER N" banner is Rendering's and UI's. If Orb wants the flash back, a thin rim is the form that keeps the body clear. The standing aura's look is the aura rework's (next).
