# The sim's load split

Owner: Simulation and Engine. 2026-10-27, on the EP's brief from Rendering's boot entry (`render/core/boot_entry.gd`, a5777f00; `docs/rendering/boot.md`). The entry loads the game's script graphs one per drawn frame. At x4 on the web the sim was its longest load, 2.8 s, because the sim's scripts compiled together. Applied in 8ce4be37 with World's lines; the CI step runs the check (§3).

## 1. Why the sim compiled as one

- **In Godot a script that names a global class (its `class_name`) compiles that class's script with it.** A `load()` compiles the script and everything it reaches that is not loaded yet.
- **The core and the world named the director's classes in seven scripts:** 11 calls in `damage.gd`, `fighter.gd`, `forms.gd`, `fx.gd`, `shots.gd` (the core) and `brunt.gd`, `contact.gd` (the world). The director names the core's and the world's classes, so they were one cycle.
- So the load of `sim/core/act.gd` reached 88 scripts, 38,873 lines: the core, the world, 29 of the director's 30 scripts and the input's reading. Natively it took 2.2 to 2.3 s here.
- The brief named five references. The graph has those five plus `DirLaunch` and a second `DirExchange` in `damage.gd`, `DirCalm` in `fx.gd` and `DirBrawl` in `contact.gd`. Each one alone keeps the cycle.

## 2. The cut: `SimDir`

- **`SimDir` (`sim/core/dir.gd`) holds the 14 director functions the core and the world call.** Each is a one-line forward to the director's own function, with the same arguments, through the director script's path, not its class name.
  - A script is loaded the first time it is called and kept.
  - In a match it is loaded already, since SimCore's step names the director's classes.
- **SimCore's step, the intro, the replay and the controls still name the director.** They are outside the core's graph and load after it.

| Where | Was | Now |
| :--- | :--- | :--- |
| `sim/core/damage.gd` (a K.O.) | `DirExchange.endEx`, `DirLaunch.doLaunch` | `SimDir.endEx`, `SimDir.doLaunch` |
| `sim/core/fighter.gd`, `forms.gd` (a form's ready tell and break) | `DirExchange.transformSource`, `DirExchange.formBreak` | `SimDir.transformSource`, `SimDir.formBreak` |
| `sim/core/forms.gd` (`canTake`) | `DirBands.who` | `SimDir.bandsWho` |
| `sim/core/fx.gd` (the ready tell) | `DirCalm.atReady` | `SimDir.calmAtReady` |
| `sim/core/shots.gd` (a shot meets a fighter) | `DirBlast.rules`, `DirBlast.hit` | `SimDir.blastRules`, `SimDir.blastHit` |
| `sim/world/brunt.gd` (World's, the wall kick) | `DirWallKick.atWall`, `DirWallKick.damageMul` | `SimDir.wallKickAt`, `SimDir.wallKickMul` |
| `sim/world/contact.gd` (World's, the brawl's pay) | `DirBrawl.payMul` | `SimDir.brawlPayMul` |
| `sim/world/contact.gd` (World's, the flight hooks and the prop smash; 2026-10-28) | `SimDir._d("launch.gd").flightHook`, `.brokenProps`, `.propBroke` | `SimDir.flightHook`, `SimDir.brokenProps`, `SimDir.propBroke` |

- **No behaviour changes:** the same functions, called with the same arguments in the same order. The golden is byte-identical.
- **The cost:** a dictionary lookup and a call by name. These calls are rare: a K.O., a form's tell and break, a shot meeting a fighter, a wall or ground contact.
- **The trade:** a director function renamed or removed is no longer caught when the core compiles, only when the call runs. The check (§3) lists every SimDir call against its script.
- **The rule from here:** a new call from the core or the world into the director goes through a named forward in `SimDir`, never by the director's class name and never by `SimDir._d` itself. The check (§3) fails either.

## 3. The check: `sim/core/tools/load_split.gd`

`godot --headless --path . --script res://sim/core/tools/load_split.gd`

- In a fresh process it loads the sim's scripts in the entry's order (§4). For each step it prints the time and how many of the director's scripts are loaded.
- **It fails if the first load (the core and the world) loads any director script.** It also fails if a function SimDir names is not a static function of its script that takes those arguments.
- **It reads the core's, the world's and the input's scripts** (not their tools and tests) for every `SimDir.name(` call, comments and strings left out. It fails on a name SimDir does not define, and on `SimDir._d(`. It prints the forwards called.
- **`-- --negative-control`:** three breaks on copies of the sources in memory (no file changes), each of which must be caught. They are a forward naming a function its director script lacks, a forward the world calls that SimDir no longer defines, and a world call by `SimDir._d`.
- It names no sim class itself, so it compiles nothing before its steps.
- `-- --steps=res://a.gd,res://b.gd` times another order.
- On HEAD it fails (29 of 30), as it should. With a SimDir call renamed it fails.
- **In CI:** a step after the GDScript parity in `.github/workflows/ci.yml`, run with `tools/gate.mjs`.

## 4. The load order for the boot entry

One `load()` a drawn frame, in this order (the entry's `STEPS`; on a5777f00 it has steps 1, 6 and 7):

| Step | Load | What it compiles | Lines | Native, before | Native, after |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `res://sim/core/act.gd` | the core and the world | 20,918 | 2.2 to 2.3 s (everything) | 0.98 to 1.01 s |
| 2 | `res://sim/core/shots.gd` | the shots | 967 | | 0.09 s |
| 3 | `res://sim/input/press_read.gd` | the input's reading | 1,351 | | 0.04 s |
| 4 | `res://sim/input/aim.gd` | the aim | 337 | | 0.02 s |
| 5 | `res://sim/director/exchange.gd` | the director (29 scripts) | 15,375 | 0 (loaded at 1) | 1.21 to 1.29 s |
| 6 | `res://sim/core/campaign.gd` | SimCore's step, the campaign, the run, the intro, the replay | 2,435 | 0.24 s | 0.24 s |
| 7 | `res://sim/input/hub.gd` | the input layer | 2,164 | 0.06 s | 0.06 s |

- **Natively the longest load goes from 2.2 to 2.3 s to 1.2 to 1.3 s** (three runs each, this PC, the machine at about 25%). Steps 2 to 4 take the director's leaves out of its load. Without them, step 5 takes them and is 1.3 to 1.4 s.
- **At x4 on the web**, scaled by Rendering's 2.8 s for the whole: about 1.5 to 1.6 s for the director and about 1.25 s for the core and the world. This is an estimate. Rendering measures it with the entry.
- The rest of the entry's steps (Audio onwards) are as they are.

## 5. Not done: the world as a load of its own

- **The world's scripts call into the core's cycle in 128 places:**
  - `SimFx` 84;
  - `SimDamage` 11;
  - `FighterData` 10;
  - `SimRicochet` 8;
  - `SimHash` 6;
  - `SimRoster` 5;
  - `SimShots` and `SimForms` 2 each.

  The core names the world too.
- Splitting them means a second facade over World's code, much of it the event calls. That is not cheap.
- Step 1 is under the goal without it, so it is left for a later need.
