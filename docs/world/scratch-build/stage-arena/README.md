# The ring picker's story-stage entry point (World, 2026-10-23): parked, not applied

For Simulation's run host (`docs/architecture/run-core.md`): one call, and a stepped form the host spends across the previous stage's beats. A thin wrapper over what the picker already had (`pick`, `beginPick`, `firstRing`, `bossRing`, `arenaOf`); golden unchanged (no versus match and no setup without `arena` reads any of it). `stage-arena.diff` (6 files); `git apply --check` ok on HEAD and in either order with `calm-turn/move-450.diff`.

## The calls (`sim/world/ringpick.gd`)

```
var job := WorldRingPick.beginStage(P, stage, stream)    # a StageJob
while not job.step(1): ...                               # a few candidates a frame; job.progress() is 0 to 1, job.total the candidates
job.result                                               # when done
WorldRingPick.stageArena(P, stage, stream)               # all at once (120 to 330 ms native)
```

**stage** (a Dictionary):

| Key | Meaning |
| :--- | :--- |
| `kind` | `"first"` (a Close ring centred on the player's home, `firstRing`), `"early"`, `"mid"`, `"late"` (the stage before the boss), `"proving"` (a Proving ground), `"boss"` (the Whole circle through the boss's home and the most populous other place still standing, `bossRing`) |
| `opponent` | the opponent's roster id (RIVAL, EMPRESS, CYBORG, PROTAGONIST): the key of his claim in Narrative's `data/narrative/opponent_grounds.json` (read by `WorldRingPick.grounds()`). A first stage and a boss's ring read no claim |
| `home` | a place id: the player's home for first, the boss's for boss, the claim's for the rest; -1 for none. Absent: **the stand-in, the most populous city still standing** (`standInHome`), until Orb names the homes (homework 39) |
| `standing` | the places still standing (a byte each); absent: all |
| `damaged` | the wear, as the picker takes it; absent: none |
| `size` | forces `"close"`, `"half"` or `"whole"`; absent: from the claim |

**stream**: the run's seeded stream for this stage (the host's keyed hash), as `pick` takes it. The whole call is a pure function of the planet, the stage, the stream and the data, so a run replays; stepped or all at once it is the same answer.

**result**: `{ok, arena, spec, stage, opponent, size, home, place, kind, score, must, relaxed, tried}`. **`arena` is what goes into `setup.arena`** ({cols, c, t} as exact bits: a stage header carries it as it carries `touch` and `pick`; the match takes it as it is). `ok` false with `error` and an empty `arena` for an opponent with no claim, or for a first stage with no home.

**Sizes** (Game Design 2c, rulings-2026-10-19b section 3) come from the data: `data/biomes/rings.json` `stage.claimKey` says which of a claim's `size` keys a kind reads (early reads `early`, mid and late read `mid`, boss reads `boss`: the fallback for a boss with no ring through two places), and `stage.proving` is a Proving ground's size (Close). So RIVAL and PROTAGONIST open Close, EMPRESS and CYBORG open Half, the middle is Half, the boss is Whole. Schema in `tools/schemas/biomes-rings.schema.json`, one Tools case (`rings-stage-proving-unknown`).

## Cost (native, this PC, planet 7, RIVAL's claim)

Close 48 candidates 123 ms (2.6 ms each, worst step 5.6); Half 48, 253 ms (5.3 each, worst 7.9); Whole 32, 330 ms (10.3 each, worst 15.7). A first stage and a boss's ring are made at once (`total` 0). At the old-laptop x4: one candidate a frame at Close and Half, one every two or three frames at Whole.

## Proof (clean export of HEAD plus the patch)

`stage_check.gd` (new; 14 checks): the data is clean; the claims load by roster id; the stand-in home; a first stage is `firstRing` through `setup.arena` and JSON bit for bit; a boss is `bossRing`; the sizes by claim and kind (RIVAL early Close, EMPRESS early Half, mid and late Half, a Proving ground Close); 16 of 16 picks on planet 7 meet their size's minimum; a stepped pick is the one made at once and the same twice; another stream gives another ring; a fallen home is not the stand-in nor the boss's second place; a forced size; a home as given; an unknown opponent is a refusal, not a crash; the arenas play in a match. `ringpick_check` and World's other checks 0 failed; `node tools/validate.js` 245 files 0 errors, `--self-test` 8,695 of 8,695; `run-all` 5 of 5 (golden unchanged); Rendering's 15 gates.
