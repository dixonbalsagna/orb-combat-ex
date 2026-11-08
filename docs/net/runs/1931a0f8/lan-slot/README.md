# Netcode run, 2026-11-08: lan_check's slot control with no script error (lan-slot) (CD-22)

CI on 4890bdd9 failed "LAN game side check, negative control": the CD-10 control that sends a takeover of slot 200 with the host's checks off reached `NetSession.takeover`, which indexed past its players (4 SCRIPT ERROR lines, which `tools/gate.mjs` rejects).

Fix (`docs/net/pending/lan-slot/lan-slot.patch`, sha1 efeff0c83b4c):
- `NetSession.takeover` refuses a slot the match doesn't have and counts it (`takeoverRefused`), and `NetSession._switch` skips one (the other erroring line, session.gd:421).
- The control now reads that count: the bad slot reaches the session, which refuses it.
- The row with the checks on also asserts the session refused nothing (the host dropped it first).

Run on a scratch tree of **1931a0f8** (`git archive` of sim, data, net, docs/net and project.godot; class cache from an import) with the patch applied. Every line went through `node tools/gate.mjs -- <godot> --headless --path <tree> --script ...`, as CI runs it. No `enet_check`. The Windows profile path in the files is written `<user>`.

| File | Line | Result |
| :--- | :--- | :--- |
| `lan_check.txt` | `lan_check.gd -- --ticks=1200` | 0 failed, gate: no SCRIPT ERROR lines |
| `lan_check_neg.txt` | `lan_check.gd -- --ticks=1200 --negative-control` | 0 failed, gate: no SCRIPT ERROR lines. The slot control reads "it reached the session, which refused it 1 time(s) (slot 200 taken: false)" |
| `rb_takeover.txt`, `rb_takeover_neg.txt` | `rollback_check.gd -- --takeover=150 --seeds=1 --ticks=300 --profiles=lan,p120,far`, and with `--negative-control` | PASS, 3,600 comparisons; control 4 caught, 0 missed; no SCRIPT ERROR |
| `rb_drop.txt`, `rb_drop_neg.txt` | `--drop=150`, the same | PASS, 900 and 900 comparisons; control 3 caught; no SCRIPT ERROR |
