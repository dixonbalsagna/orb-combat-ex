# Netcode run, 2026-11-07: the lan-n4 park (N1 to N4, the fight view, CD-10, CD-16, RL-253) (CD-22)

Gated on a scratch tree of HEAD **d41ce393**: `git archive` of sim, data, net, docs/net and project.godot, with `docs/net/pending/lan-n4/lan-n4.patch` applied (sha1 0958378583ab, the version in that folder).
- HEAD has since moved to ea398601. In the paths these checks read (sim, data, net, project.godot), only `sim/core/tools/run-all.js`, a JS tool, changed.
- No socket was opened, no firewall script was run, and `enet_check` wasn't run (CI only).

| File | What it is |
| :--- | :--- |
| `gates.txt` | One line per check: exit code, the error-line count of its stderr (Godot's "resources still in use at exit" counts as one; the negative controls' deliberate bad slot adds some) and its verdict line. **All 50 exit 0.** A blank verdict is a negative control or a check whose pass line the summary's pattern doesn't match: read its file |
| `check-lines.txt` | Which file is which check: `tag|script|arguments`. These are CI's 45 network lines (all but `enet_check`), plus five for 2v2 together: rollback with the pairs crosswise, seeds 1 and 2, and its control; desync and its control; the two-PC self-test |
| `checks/*.txt` | Each check's whole stdout |
| `lan-loop-rows.txt` | The LAN kit with an export, on a full stack tree of HEAD (Tools' `stack-preview.mjs` tree-only) with the park's net/, then the built game run headless with `--lan-loop` (the other PC simulated in-process, no socket): 9 rows (1v1, 2v2 apart, 2v2 together; host and join; lan and p120). All exit 0, no script errors, every check matched. The new log fields are in each line: frames, and with two fights the view, "his own" fight |

What the new rows read (from `checks/a06_lan_check.txt`, `checks/b06_lan_check.txt`, `checks/a21_transport_check.txt`, `checks/b20_transport_check.txt`):
- **The view, with the second PC hitching:** each PC began 0 frames off its own player's fight on lan and on p120 (p120 with 228 frames paused). Deepest rollbacks 6 and 9, within the LAN lead of 8 and a save. Time sync's longest wait was 2 frames.
- **The partner's fight** shows at tick 660 for a KO at tick 100, as the fight's KO clock passes 3.8 s (the camera's close-up ends at 1.8 s on that clock).
- **CD-10:**
  - A hello asking for 100,000 ticks gives "Couldn't start: the other PC asked for an input wait of 100000 ticks; at most 8".
  - The packet with slot 200 is dropped, and the match goes on in step.
  - Of a flood of 3,932 far-ahead packets, 3,928 were dropped and the last 4 were still on the way; the second PC's inputs held stay at 1,183.
  - The second PC gone at frame 600, in 1v1 and 2v2 together: the computer plays its seat from tick 594, the match goes on to tick 1,430, 6 banners, and the title "The other PC has gone: the computer plays its fighter".
- **Negative controls, each caught:**
  - the pause without the view fix: 12 frames off;
  - the cap off: 100,000 agreed;
  - the checks off: slot 200 reaches the session, and the flood fills it to 390,223 inputs;
  - the hand-over off: frozen at tick 592;
  - `transport_check`'s waits of up to 8 frames.

**Unverified (no saved output):** the figures in Netcode's 2v2 stutter report of 2026-11-07 and the old README of this park. That is the rollback-probe costs (45 ms for 20 ticks and so on) and the 31,800-tick joiner probe. Their outputs were deleted at the safe pause, before CD-22.
