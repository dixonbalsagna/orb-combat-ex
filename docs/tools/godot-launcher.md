# Starting the game without touching anyone's data (Tools, 2026-11-28)

**Every game run by a session or a script goes through the launcher.**

    bash tools/godot-run.sh --path . --script res://render/tools/sky_check.gd      # any Godot arguments; --headless is added
    G="$PWD/tools/godot-run.sh"; "$G" --path . --import                           # where a script keeps the engine in a variable
    bash tools/godot-run.sh --program <built program> -- --seed=4 --bench          # a built program
    eval "$(bash tools/godot-run.sh --print-env)"                                 # before tools that start the engine themselves
    bash tools/godot-run.sh --where                                               # this session's data folder

- It moves `APPDATA`, `LOCALAPPDATA`, `HOME`, `USERPROFILE` and the XDG folders into `<temp>/orb-run-data/<session id>` (`ORB_RUN_DATA` overrides), then the engine replaces the shell: a `timeout` or a stop reaches it.
- `ORB_GODOT_EXE` (or `GODOT`) names the engine.
- An export gets the engine's export templates hard-linked into the scratch folder.
- Node tools use `userdataEnv(dir)` from `tools/lib/userdata.mjs` as the environment of what they start.
- From PowerShell: `& "C:\Program Files\Git\bin\bash.exe" tools/godot-run.sh ...`.

**The ratchet** (`tools/lint-godot-launch.mjs`, CI): a new script under `tools/` or `docs/*/tools` that starts the game any other way fails. Older ones are listed in `tools/godot-launch-baseline.json`; the list only gets shorter.

**The guard** (two `.editor` lines in `project.godot`; `tools/userdata-guard-check.mjs`): a run from the project, launcher or not, keeps its data, logs included, in `app_userdata/Orb Combat EX dev`. A built program keeps `app_userdata/Orb Combat EX`, as before.

**What neither stops:** a built program started by hand, not through the launcher, uses the player's folder, as a player's does.
