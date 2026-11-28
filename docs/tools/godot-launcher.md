# Starting the game without touching anyone's data (Tools, 2026-11-28)

**Every game run by a session or a script goes through the launcher.**

    bash tools/godot-run.sh --path . --script res://render/tools/sky_check.gd      # any Godot arguments; --headless is added
    G="$PWD/tools/godot-run.sh"; "$G" --path . --import                           # where a script keeps the engine in a variable
    bash tools/godot-run.sh --program <built program> -- --seed=4 --bench          # a built program
    eval "$(bash tools/godot-run.sh --print-env)"                                 # before tools that start the engine themselves
    bash tools/godot-run.sh --where                                               # this session's data folder
    bash tools/godot-run.sh --fresh --path . --script res://...                   # a new, empty data folder for this run

- It moves `APPDATA`, `LOCALAPPDATA`, `HOME`, `USERPROFILE` and the XDG folders into `<temp>/orb-run-data/<session id>` (`ORB_RUN_DATA` overrides), then the engine replaces the shell: a `timeout` or a stop reaches it.
- `ORB_GODOT_EXE` (or `GODOT`) names the engine.
- **Exports work isolated.** The installed export templates are hard-linked into the run's data folder (read there, never written; nothing else of the real folder is touched), also from a shell whose environment was moved already (`--print-env`, a gate, a hand isolation). They are found through `ORB_TEMPLATES`, then the environment, then the operating system's own answer. Check: `node tools/godot-export-check.mjs` (a tiny Web export through the launcher; also in the web parity workflow).
- Node tools use `userdataEnv(dir)` from `tools/lib/userdata.mjs` as the environment of what they start.
- `userdataEnv(dir)` places the templates too, so a node tool's export under it works.
- From PowerShell: `& "C:\Program Files\Git\bin\bash.exe" tools/godot-run.sh ...`.

## Fresh folders: gates and shards

**A reused data folder keeps the game's caches, and those are keyed by data, not code.** A session's folder is kept between runs on purpose (a planet baked once is not baked again), so a check that must see what the code does *now* needs an empty one: a golden check once passed at tick 0 in a reused folder when the code had moved it (World, 2026-11-28).

- `--fresh` (first argument), or `ORB_FRESH=1`: a new, empty folder under the data folder, for this run alone.
- A gate or a shard that starts the game several times takes **one** new folder and keeps it for that run: `export ORB_RUN_DATA="$(bash tools/godot-run.sh --fresh --where)"` before the first start (docs/ep/gate does this).
- Old `fresh-*` folders stay in the temp folder until it is cleaned; each is small except for the caches it baked.

**The ratchet** (`tools/lint-godot-launch.mjs`, CI): a new script under `tools/` or `docs/*/tools` that starts the game any other way fails. Older ones are listed in `tools/godot-launch-baseline.json`; the list only gets shorter.

**The guard** (two `.editor` lines in `project.godot`; `tools/userdata-guard-check.mjs`): a run from the project, launcher or not, keeps its data, logs included, in `app_userdata/Orb Combat EX dev`. A built program keeps `app_userdata/Orb Combat EX`, as before.

**What neither stops:** a built program started by hand, not through the launcher, uses the player's folder, as a player's does.
