# load-split: the director as a load of its own (parked)

Owner: Simulation and Engine. 2026-10-27, on the EP's brief from Rendering's boot entry (`render/core/boot_entry.gd`, a5777f00). The page is `../../load-split.md`.

## What it changes

- **`sim/core/dir.gd` (new, `SimDir`):** the 11 director functions the core and the world call, each a one-line forward to the director's own function by its script's path. With it, loading the core and the world no longer compiles the director.
- **The core's five scripts call `SimDir`** in place of the director's class names: `damage.gd`, `fighter.gd`, `forms.gd`, `fx.gd`, `shots.gd`.
- **World's two scripts call `SimDir` too:** `brunt.gd` (the wall kick) and `contact.gd` (the brawl's pay).
- **`sim/core/tools/load_split.gd` (new), the check:**
  - the sim's loads in the entry's order, with each one's time;
  - it fails if the core's load compiles any of the director;
  - it fails if a function SimDir names is not in its script.
- No behaviour changes. No data or schema changes.

| File | Whose | What |
| :--- | :--- | :--- |
| `sim/core/dir.gd`, `.uid` | mine (`load_split.py`) | new: `SimDir` |
| `sim/core/tools/load_split.gd`, `.uid` | mine (`load_split.py`) | new: the check |
| `sim/core/damage.gd`, `fighter.gd`, `forms.gd`, `fx.gd`, `shots.gd` | mine (`load_split.py`) | 9 lines call `SimDir` |
| `sim/world/brunt.gd`, `contact.gd` | World (`grant_world.py`) | 3 lines call `SimDir` |

## Apply

On main (811134ef or later), from the repo root, in one commit and in this order:

```
python docs/architecture/pending/load-split/load_split.py .
python docs/architecture/pending/load-split/grant_world.py .
```

Or use `git -c core.autocrlf=false apply docs/architecture/pending/load-split/load-split.diff`: 11 files, sha1 c6da65ae1c46, cut on 811134ef. Applied to the base's files, it gives the scripted copy (0 files differ). Apart from line numbers, it is the same as the cut on 11a2edfb.

Then `--import` (a new class).

## For others after it lands

- **Rendering (`STEPS` in `render/core/boot_entry.gd`, on main since a5777f00):** the load order in `../../load-split.md` §4. Four steps go in after `act.gd`, whose comment becomes "the core and the world"; the rest stay as they are:
  1. `sim/core/act.gd`;
  2. `sim/core/shots.gd`;
  3. `sim/input/press_read.gd`;
  4. `sim/input/aim.gd`;
  5. `sim/director/exchange.gd`;
  6. `sim/core/campaign.gd`;
  7. `sim/input/hub.gd`;
  8. then the rest as they are.
- **Tools (CI):** one step after the GDScript parity in `.github/workflows/ci.yml`:

  ```
  - name: The sim's load split (the core's load compiles none of the director)
    run: 'node tools/gate.mjs -- "$GODOT" --headless --path . --script res://sim/core/tools/load_split.gd'
  ```

## Results

**The full proof, on 11a2edfb (scratch export with both scripts applied; one Godot job at a time, below-normal priority):**

- Import clean. The golden is byte-identical. Parity ok 77, fail 0.
- Determinism passes, plain and `--intro`.
- These pass:
  - the seam sweep;
  - the flash run and its count;
  - validate (275 files) and its self-test (9636);
  - QA (7 files);
  - npm 5/5;
  - the loader check;
  - the flash self-test.
- Rendering's 15 gates pass. So do `city_check`, `effects_check`, `hash_check`, `split_sweep` and `anim_check`.
- The determinism lint is ok.
- World's 38 checks pass, except one: `climate_check`'s timing ratio (surfAt in gen 2 against gen 1).
  - It measured 2.89 times against that version's limit of 2.5 times, with the machine loaded.
  - World's 37611912 changed that check to the best of 7 runs at 3 times.
  - On 811134ef's check, with the park, it passes at 2.52 times.
  - The cut doesn't touch surfAt.
- `campaign_episode` on the base and the park: the same 11 lines apart from the timings ("the same to the bit").
- `load_split`:
  - the park: ok;
  - the base: FAIL ("the core's load compiles the director");
  - with `damageMul` renamed in `dir.gd`: FAIL ("SimDir calls damageMull in wallkick.gd ... not a static function").

**Re-proved on 811134ef** (after World's aftermaths, 37611912, which changed `contact.gd`, and Rendering's boot entry, a5777f00):

- Both scripts apply.
- Import is clean, parity is ok 78, fail 0, and the golden is byte-identical.
- `load_split` is ok, with SimDir's 11 calls all found.
- The script graph splits as it did:
  - before: one cycle of 80 scripts, 38,339 lines;
  - after: core and world, 45 scripts and 20,201 lines; the director, 27 scripts and 15,182 lines.

**Native load times** (`load_split`, quiet machine, three runs; the figures in `../../load-split.md` §4):

| | Before | After |
| :--- | :--- | :--- |
| `act.gd` | 2.21 to 2.30 s | 0.98 to 1.01 s |
| `exchange.gd` | | 1.21 to 1.29 s |

The 811134ef run was on a loaded machine (1.37 s and 1.73 s), so its times are not a measurement.
