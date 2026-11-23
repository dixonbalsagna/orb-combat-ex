# Park: enet-slots, the ENet listener keeps spare slots (Netcode, 2026-11-23)

The late-host row in CI's "Network checks 5 of 6" failed twice on 9d6911e7 and passed on 3310e80c, 0d21624b and fe92da75, with no change in `net/` or the sim between them: `FAIL lan host: timed out after 70 s at tick (handshake)`. This park is the cause, read from the code, and a fix with a CI row that forces the race and a control.

## The race

- **The joiner calls again from a new port every 3 s** (`--redial`, NetLan's rule), until the host answers.
- **The host's listener had one peer slot.** A call that reaches the listener takes a slot as soon as the host answers it, and keeps it until the caller acknowledges. A call the joiner has already dropped never acknowledges, and the joiner's PC never says so: neither Linux nor Godot on Windows passes up the "port closed" reply for this kind of socket. ENet gives up on it about 31 s later. Meanwhile the live call finds no free slot and is ignored.
- **It happens when the host opens its port, then leaves it unserviced for more than about 1.5 s while the joiner is calling.** The queue then starts with a call the joiner has dropped. Past 4.5 s it's certain, because any call's port lives at most 3 s and calls go out at most 1.5 s apart.
- **In `enet_peer.gd` the host made its match key after `listen()`.** `NetHandshake.keyOf` hashes the data on its first call: 1.6 s on the main PC (run record below), more on a CI runner. So the row raced on that gap.
- **Whenever the race happened, the joiner gave up first.**
  - The joiner's limit (70 s from its own start, 40 s of it the late host's wait) runs out about 30 s after the host opens its port.
  - The host's slot frees about 31 s after its first service, so it is still held then.
  - The host then waited out its own 70 s. A run passed when the gap was short, or fell where no call was dropped.

**In the game:** `NetLan._open` makes the key before `listen()`, so it has no 1.6 s gap. But any host frame longer than about 1.5 s just after Host is pressed does the same: the first frames of a big planet, or the old PC. The game's joiner calls forever, so there it costs about 30 s more of "Waiting for the other PC", not a failure.

## The change

- **`net/enet_transport.gd`:**
  - The listener has 8 slots (`SLOTS`): room for the dropped calls of a host whose first frames ran about 18 s late, plus the live one.
  - It keeps the first peer that connects and turns any later one away (`peer_disconnect_now`), as it already did for an address off the home network.
  - `listenSlots` is a test switch.
- **`net/tools/enet_peer.gd`:**
  - The key is made before `listen()`, as NetLan does.
  - `--listen-stall=MS`: the host's port is open but unserviced for MS.
  - `--slots=N` sets the listener's slots.
  - The result records the joiner's calls.
- **`net/tools/enet_check.gd`:**
  - `--listen-stall=MS`, a `--one-slot` control and `--timeout=S`, passed to both peers.
  - The stall row also needs the joiner to have called again at least twice before the host answered. That proves the row really staged dropped calls.
- **`docs/net/rollback.md` section 11:** one paragraph on the slots and the row.

No rule, limit, packet or protocol changes. The handshake and PROTO are unchanged. RL-230's home network filter is unchanged, and the listener still keeps one peer.

## CI lines (job "Network checks 5 of 6", after the late-host step)

```yaml
      - name: Two-process ENet match, calls left over while the host's port goes unserviced for 8 s (the listener's spare slots must let the live call in; CI only, it opens a port)
        run: 'node tools/gate.mjs -- "$GODOT" --headless --path . --script res://net/tools/enet_check.gd -- --ticks=600 --profiles=lan --late-host=4000 --listen-stall=8000'
      - name: Two-process ENet match, calls left over, control (one slot, the old listener; the peers must not meet within 20 s)
        run: 'node tools/gate.mjs -- "$GODOT" --headless --path . --script res://net/tools/enet_check.gd -- --ticks=600 --profiles=lan --late-host=4000 --listen-stall=8000 --one-slot --timeout=20'
```

**Time:** about a minute each: the build, then 4 s and 8 s of staging, then 10 s of play or the control's 20 s limit. The job measured 12.9 minutes against a limit of 45.

**Why the control is caught:** with an 8 s stall, the first call in the queue is one the joiner dropped. One slot holds it for about 31 s, and the joiner quits at 20 s. If ENet gave up sooner than I read (I read its timeout rule; I didn't measure it), the joiner still quits well before the slot frees.

**Why the stall row stages the race:** the same reasoning, and the row checks the joiner's calls.

## Checks

Not run: `enet_check` runs only in CI.
- **Parse checks.** On a scratch tree of fe92da75 with the patch, `--check-only` passes for the three scripts and for `net/lan.gd` and `net/host.gd`. A deliberately broken script fails the same check.
- **Gap probe.** It measured the 1.6 s gap with no socket.

Run record: `docs/net/runs/fe92da75/enet-slots/`.
