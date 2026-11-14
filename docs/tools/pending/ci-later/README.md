# CI steps held until the thing they run is on main (Tools, 2026-11-14)

Two steps are written and not in `.github/workflows/`, because the script each one runs is not on main yet: a step that names a missing file fails the job. Each goes in with the change that lands its script, in the same batch.

## 1. Audio's sets check (waits for Audio's group, GW1a)

In the job `godot-audio-vfx` of `.github/workflows/ci.yml`, after the Audio babble check:

```
      - name: Audio sets check (the five things a player should hear are made into sounds on a seeded match)
        run: 'node tools/gate.mjs -- "$GODOT" --headless --path . --script res://audio/tools/sets_check.gd'
```

The scripts table counts the script as CI the moment the step names its path. The other audio checks passed in a scratch run on 14 November (exit 0, no script errors); this one is Audio's new file and has not been run by me.

## 2. Controls' coverage probe on every build (waits for the park `docs/controls/pending/coverage-probe/`, A-CONTROLS-06)

The EP's words (A2): a CI step for the coverage probe on each build, failing only on a SCRIPT ERROR, since the count of cells with no outcome is a reading, not a gate (until A4's table). The probe reads the build's own data, so it runs against the PACKED build, not the checkout: `--main-pack`.

Where: the Linux job of `.github/workflows/desktop-builds.yml`, after "Export Linux", once A-TOOLS-01 makes the first desktop build. Draft (not run):

```
      - name: Coverage probe on the packed build (a reading; fails only on a SCRIPT ERROR)
        run: |
          mkdir -p "${RUNNER_TEMP}/coverage"
          node tools/gate.mjs -- "$GODOT" --headless --main-pack "<the exported pack or the exe that embeds it>" --script res://sim/input/tools/coverage_probe.gd -- --fighters=PROTAGONIST,RIVAL | tee "${RUNNER_TEMP}/coverage/coverage.txt"
      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: coverage-probe
          path: ${{ runner.temp }}/coverage
```

Open points, each to be proven when the park lands (none is proven today):
- **Whether `--main-pack` accepts the exe that embeds the pck** (the desktop presets embed it), or a separate `.pck` has to be exported for this step. Controls' first reading ran it on a kept 9 November build's own tree, and their page says a desktop build's pack works; I have not run it from a pack or from a runner.
- **The editor binary on the runner** (`$GODOT`) reads a pack made by the same Godot version: it is the same pinned 4.7.2, so it should.
- The probe prints one line a cell and COUNT lines; nothing in it is a verdict, so the step has none (tools/gate.mjs fails only on SCRIPT ERROR lines, as the EP asked).
- About 100 s for both fighters on a PC.
