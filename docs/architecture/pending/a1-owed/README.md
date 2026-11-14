# Parked: my three owed items (sprint A1)

Simulation, 2026-11-14. **No state changes: the golden is byte-identical** (hit-stop by weight is off as shipped and in the 9 November build; power_check is a test).

## 1. The docs: underTicks is 12 (no patch)

`docs/architecture/power-core.md`'s slip section now says 12 ticks, why (the pad's own tap/hold line, `tapHold.holdStart`), and what Encounter's slip-arrive adds. The file was edited in place; it's on the uncommitted list as "commit".

## 2. Hit-stop by weight's never-cut list (`never-cut.patch`)

Game Design (2026-11-13): the weight table never cuts a heavy, a launch or a full launch, the same list as the budget on any table.
- `hitstop.gd`: `NEVER_CUT` is decisive, KO, heavy, launch and launch_full.
- `hitstop.json`'s `_cut` note says so.
- Parity's rows for hit-stop by weight:
  - over the budget: light 2, medium 4, and heavy 8, launch 12 and full launch 14 whole;
  - over the deep line: medium 3, the heavy and launches whole;
  - a tick under the deep line and the budget's return now read the medium (5 → 4 at ×0.7, 3 at ×0.5), since the heavy no longer tells the two steps apart.
- `feel-core.md`'s rows give the new values and the old.

## 3. power_check's close times (`close-rows.patch`)

Needed **before GW1a lands the arrival on in main's data.** On HEAD, four close-time rows fail with the arrival on, because they time to 1.5 bh and the arrival stops him at its 2.5 bh mark.
- **The close times run to striking distance,** the arrival's mark (`interrupts.json` `bands.engageBh`), as Game Design's ruling words it.
- They run **with the arrival off and then on**, through an in-memory switch, so they pass whatever the data says.
- **The slip's rows run with the arrival off,** whatever the data says. Encounter's slip hold keys on the slip, and `arrive_check` tests it.

| Close from | Target | Arrival off | Arrival on |
| :--- | ---: | ---: | ---: |
| 1,000, base | 0.40 s | 0.18 s | 0.25 s |
| 3,000, base | 0.80 s | 0.58 s | 0.65 s |
| 6,000, base | 1.40 s | 1.18 s | 1.25 s |
| 6,000, maximum | 0.75 s | 0.53 s | 0.60 s |

The arrival's ease adds 4 ticks every time. Every row is inside Game Design's targets either way.

## Apply

Each applies alone (they touch different files), on HEAD 0cda3796; checked again on dacaad17, each reproducing the tested files:

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `never-cut.patch` | `hitstop.gd`, `hitstop.json`, `parity.gd`, `feel-core.md` | 0887b92507849e9e81c70c72d3b6caedae2393b0 | 313bd585bbce |
| `close-rows.patch` | `power_check.gd` | f84a5bd97e5eb7a6ee201adf0343fedb14a18800 | 76ab6e1c0d19 |

## Proof

On 0cda3796 (records in `docs/sim/runs/0cda3796/a1-owed/`):
- **Golden byte-identical.** Parity through `gate.mjs`: exit 0, no SCRIPT ERROR lines, golden check passed, hit-stop by weight's rows with the new list.
- `power_check` through `gate.mjs --verdict`, on the shipped data: 0 failed, with the close times above.
- `power_check` with `bands.arrive.enabled` true in the data (main's state once GW1a lands it): 0 failed.
- Its negative control: 0 failed (the switches left unread are seen).
- Rendering's 15: all pass. Validator and self-test, lint.
