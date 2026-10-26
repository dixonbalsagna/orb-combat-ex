# Camera follow-ups, ready (2026-10-25)

Land in this order on main (668aa2ed or later; the half-plane is already on main). Each applies cleanly on the one before:
1. director-16-takeover-divider.patch: the expansion's divider sweep eased by smoothstep(e), in step with the panes' anchors; the slam excluded.
2. director-17-slam-whip.patch: the slam's door as a 12-frame crisp whip (SLAM_TIME 0.2, smootherstep), landing on the contact.
3. rally/director-18-rally-framing.patch: the rally's camera, inert until Encounter's cues (rally/README.md).

All three: split_sweep, the 18 headless render checks, and determinism plain and --intro pass. The flash collapse readings are in director.md section 11. The GIFs are in docs/camera/img/takeover-divider/ and docs/camera/img/slam-whip/; the rally has none until the sim has a rally.
