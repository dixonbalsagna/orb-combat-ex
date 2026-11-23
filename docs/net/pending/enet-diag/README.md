# Park: enet-diag, the two-process ENet check names both peers' errors (Netcode, 2026-11-23)

CI on 9d6911e7, job "Network checks 5 of 6", failed twice (the first run and the EP's rerun) on one row only: "Two-process ENet match, a late host (the PC that joins started 40 s first)": `FAIL lan host: timed out after 70 s at tick (handshake)`. The other two-process rows pass, both lan and p200 at 1,800 ticks with identical digests, and so do their controls.

**What the logs say:**
- **It isn't the planet build.**
  - Each peer builds its match before the late host's 40 s wait and before its own clock starts (`net/tools/enet_peer.gd:58-61`, `:91-92`), so the build isn't inside the 70 s limit.
  - The row passed on 3310e80c and 0d21624b, which already started on the planet. There the host built in about 11 s and the joiner called for 40 s (handshake in 283 / 39,967 ms).
- **Nothing in `net/` or the sim changed between that pass and 9d6911e7:** only ci.yml (a flash set split, the hold-answer step in another job), flash data and UI words.
- **In the two failures the host built in about 20 s.** Then it listened its full 70 s and never got a session.
- **The joiner's own result isn't in the log.** `_compare` returned only the first peer's error, the host's (`net/tools/enet_check.gd:146-148`). So the log can't say whether the joiner gave up, failed its handshake, was refused, or never reached the host.

**The change (diagnostics only; no rule, limit or timing changes):**
- `net/tools/enet_check.gd`: `_compare` returns both peers' errors, joined (`host: ...; join: ...`). The negative control's test (`err.contains("tick N ")`) still holds.
- `net/tools/enet_peer.gd`: a calling peer (`--redial`) that times out says how many times it called again, when the last call went out, and whether ENet reports it connected.

`enet-diag.patch`, sha1 in the report. Both scripts parse (`--check-only`, headless, on a scratch tree of HEAD; nothing ran and no port opened). Not run otherwise: `enet_check` runs only in CI. After it lands, the job's next run names the joiner's side, and the fix follows from that.
