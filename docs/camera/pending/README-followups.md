# Camera follow-ups parked at Orb's pause (2026-10-23)

Land in this order, on bf34d1d4 or later. Each applies cleanly on the one before:
1. pane-visible-half-plane.patch (sha1 59c4babd...): lands with Rendering's 22l.
2. director-16-takeover-divider.patch: the expansion's divider sweep eased by smoothstep(e), in step with the panes' anchors; the slam excluded.
3. director-17-slam-whip.patch: the slam's door as a 12-frame crisp whip (SLAM_TIME 0.2, smootherstep), landing on the contact.

Done for 16 and 17 together (scratch tree = bf34d1d4's camera + 1 + 2 + 3): split_sweep (new rows `takeover divider eased`, `slam door whip`), the 18 headless render checks and determinism plain and --intro pass. 16 leaves the camera digests byte-identical; 17 lowers the mass probe's velocity steps (director.md section 11).

Still to do before they are reported ready:
- The flash collapse clip in both modes on before (1), after 2, and after 3.
- The slam's before/after GIF: rushcity from tick 415 and ai 7 from 655; the slams are at 428 and 667.
- 16's GIF is done: docs/camera/img/takeover-divider/.
The Camera session's scratch script c8.sh does both.
