# For Tools: two fixes so a black box playback is the recorded match

Encounter, 2026-11-02. Found making Orb's second-play clips with Tools' blackbox-clip: on Tools' stack tree (`018b4edf`, 57 parks) a page playback of Orb's match went off the recording at tick 600. With these two fixes, every checkpoint of all three clips was equal. **Tools' and Rendering's files, not mine:** this is a proposed diff for Tools to land.

**Apply on Tools' stack tree** (it needs the black box playback, which isn't on main): `git -c core.autocrlf=false -c core.eol=lf apply blackbox-clip-fix.diff`. Checked on `018b4edf`.

| File | Fix | Why |
| :--- | :--- | :--- |
| `render/core/sim_host.gd`, `_bb_pb_step` | **On the playback's first step, start the recorded match itself:** `SimCore.newMatch` with the recording's seed, `ai` and `setup` (no hub setup merged in), then `_started`, then each slot's AI as recorded | The hook starts its own match after the playback is armed, so the playback ran on the hook's match. Orb's second match has an intro and the easy AI, which the hook's match didn't |
| `render/tools/flash_capture.gd`, the `ai` scenario | **During a playback, stage nothing** | The `ai` scenario readies forms at 300 and 1500, raises a tier at 900 and sets a stage at 1200, into the sim. A playback is the recorded match, with nothing staged into it |

## Not in it

My scratch copy of the clip tool (`--windows`, `--labels`, the player template read from the repo path) stays scratch. It's how the clips were cut, but Tools didn't ask for it.
