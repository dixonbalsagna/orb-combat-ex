# Park: gw1a-pins, three net checks read under GW1a's data (Netcode, 2026-11-14)

The EP's GW1a stack (main plus every GW1a park: Orb's 9 November data, with the energy model and the Controls switches on) failed three of my checks. I read each one under that data. **None is a desync or a hash fault in Orb's game.** Each came from what a row took for granted about main's data.

| Check | What failed, and why | The pin |
| :--- | :--- | :--- |
| `lan_check --negative-control` | "a LAN setup without its power word must be caught with the model off". The control dropped the word, expecting the model to go off. GW1a's data has the model on, so the setup played it anyway. The check itself still reads the model | The control sets `"power": false`, which turns the model off under any data (`SimPower`: the setup's word wins). Lines in `net/tools/lan_check.gd` only |
| `word_check`, 1 of 646 | "off: a word handed in reaches no hash and no digest". With the right stick off, `NetSession.intentOf` still unpacked a second word handed in. A director rule that GW1a's data turns on reads the stick fields without asking the stick's switch, and moved a per-fighter counter (`act.dirI[610]`: 60 against 0 after 60 ticks, from a probe with the field walk), so SimHash saw it. The cheap digest never did | **`NetSession.intentOf` reads the second word only with the right stick on, as `SimReplay.play` already does** (`net/session.gd`, one line). No real match changes: with the stick off no PC makes a word (NetLan packs 0 and the bots write none, the row's first two checks), and with it on nothing is different |
| `desync_check --profiles lan` (seed 1) | "injection fighter_x healed every time: it tested nothing". The default setup now plays the energy model, and a fighter's x is set outright by his moves at that tick, so the test's change (an ulp, and even a whole unit, tried) is gone by the next checkpoint. The detector caught every other injection. That's a healed test, not a missed desync: both peers end up in the same state | In a match with the energy model, the fighter's injection is his health (`fighter_hp`, minus 1), which nothing puts back. Main's default setup keeps the ulp of x, still caught to the bit. The LAN setups move from a whole unit of x to health. `fighters` setups are unchanged (`net/tools/desync_check.gd`) |

**Plainly, for Orb's game:** no desync and no hash fault.
- The right stick is on in Orb's data, so the second word is real input on both PCs and belongs in the hash.
- With it off, no PC sends one.
- The `intentOf` change closes the one way a word could reach the sim with the stick off: a caller handing it in directly, which only this check does.

`gw1a-pins.patch`, sha1 bd75edd0bfc81086cf33bebee02af8553fadf5b9 (`net/session.gd`, `net/tools/lan_check.gd`, `net/tools/desync_check.gd`). Cut on main after B1 (f70afd08): it applies on HEAD 41768933, alone, and the GW1a parks don't touch these files.

**Left as it was:** `lan_check`'s header still says "without its power word" (one line, changed with my next net batch). The director rule that reads the stick fields without the switch is Combat's or Simulation's code. It does nothing in play once the session holds the word back, so it's named here, not changed.

Runs: `docs/net/runs/b869cdad/gw1a-pins/` (CD-22).
