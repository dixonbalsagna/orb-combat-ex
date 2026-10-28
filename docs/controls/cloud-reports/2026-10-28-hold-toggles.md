# Hold toggles: report, 2026-10-28

Controls & Game Feel. Brief: `docs/ep/cloud-briefs/controls-hold-toggles.md`, run locally in the shared tree on main with params-cache (0ebe6520). Design: `docs/controls/hold-toggles.md`.

## SUMMARY

Guard, the manoeuvre stance (dodge), the charging stance (power) and Transform each have a hold-or-toggle style per player, default hold, built like `energy_style`. A toggle is fed to the same held state a button reaches, in the layout, so the intent is bit for bit what holding builds from the matching presses; the sim learned no new input. Held and toggled sequences give the same packed intent on all 160 ticks and the same state hash, on the keyboard and the Arena pad, for every action.

## CHANGES

In Controls' paths (in the tree):
- `sim/input/layout.gd`: `press` / `release` wrap `_real_press` / `_real_release`; `hold_styles`, `set_hold_style`, `let_go_toggles`, the transform latch (single control and chord).
- `sim/input/hub.gd`: `set_hold_style`, `hold_style_of`, `let_go_toggles`, the styles applied to each layout on every `intent()` (keyboard and pad; touch not covered, ADR 0011).
- `sim/input/test/hold_toggle_test.gd` (+ `.uid`): 76 checks.
- `docs/controls/hold-toggles.md`, `README.md` (index line), `input-gates.md` (20 tests, the new row), this report.

Outside Controls' paths, parked in `docs/controls/pending/hold-toggles/` (`hold-toggles-outside.patch`, `options-rows-only.patch`, `README.md`):
- `ui/data/options.json`: eight rows (granted by the brief); `ui/data/settings.json`: the rows and labels; `ui/widgets/ui_settings.gd`: player two's rows only for two humans; `render/core/main.gd`: forward the options to the hub; `localization/pseudo/ui/data/options.json` and `settings.json`: regenerated.

## DECISIONS

- **Where the toggle lives:** the layout, by wrapping the press and release that reach the old code. That is what makes the equality exact (same code, same tick) and keeps the sim out of it.
- **Transform is a latch on the count,** not a hold: both controls down together once, let go, sent half a second later; one press of either before then cancels it and does nothing else. The chord still needs both down at once for a moment, as it always has.
- **What ends a toggle:** the stop press, a new match (`release_all`), the style set back to hold, a sent transform (it takes the chord's toggled stances with it). **Not** a hit (the sim gates held states during stun, for a latch as for a finger), **not** a launch or a KO (the layout is never told; a finger is not lifted by them either). `hub.let_go_toggles(slot)` is built and tested for a host that wants a KO or launch to end them; nobody calls it.
- **Another stance pressed:** newest wins, as with two fingers; the older toggle returns when the newer is toggled off. Not changed.
- Option names: `guard_style`, `manoeuvre_style`, `charge_style`, `transform_style`, each with `_p2`.

## NEEDS FROM EP

1. Apply `hold-toggles-outside.patch` (UI, Rendering, Accessibility lines; the options rows alone are `options-rows-only.patch`). Checked: `git apply --check` clean on HEAD 20fd1129; `hud_check` 5828 checks, 0 failed; pseudo-locale check current.
2. **Game Design question: does a toggled Guard need a balance change?** My view: no change now. Holding Guard costs a shoulder finger (pad) or the little finger (keyboard), so the hand-cost difference is small. Toggle is also weaker in one way: the perfect-block edge comes from a fresh press, and a toggled player needs a stop press and a start press to make one. The way it could go wrong is an AI-or-human who sits in a toggled guard through everything; that is a question for QA's arms and masher stages with a toggled-guard variant before anyone tunes. Nothing tuned.
3. UI's legend words ("Guard (hold)", Remap's "Hold to guard.") and `docs/ui/strings.md` will say hold for a player who chose toggle, as the energy legend is handled by `UiHints.energy_style`. UI's, not in the patch.
4. Whether a KO or a launch should call `hub.let_go_toggles(slot)` (Rendering's host, a few lines). Default: no, to match a held finger.

## RISKS

- A toggle can be left on by mistake (a launch, then the fighter rises already guarding). That matches a held finger; the fix, if wanted, is item 4.
- Touch has no hold styles. Existing touch code is untouched.
- Equality is proved for the sequences in the test, not for every sequence; the mutation run (toggle made inert) fails 24 of 76, so the checks bite.
- Not run: Rendering's render gates, the net checks (rollback, desync), split_sweep, World tools, QA. The sim is untouched, so the golden and determinism are the gate that matters; the EP's local gate covers the rest.

## NEXT

EP applies the patch and commits. Then: QA's toggled-guard variant if wanted. Idle after that; the energy overhaul and right-stick builds still wait on Orb.

## Gates (clean `git archive HEAD` export of 20fd1129 plus my three input files; the parked patch applied for `hud_check` and pseudo)

| Gate | Last line |
| :--- | :--- |
| `hold_toggle_test` | `hold_toggle_test: 76 checks, 0 failed` |
| all input tests (20) | each `0 failed`, `exit 0` (agency 105, aim 233, brake_grapple 66, brake_ready 15, charge 97, haptics 80, hold_toggle 76, hub 60, join 53, layout 128, mode 55, params_cache 36, press_read 439, remap 138, stance 186, struggle 105, t1_latency 62, touch_full 848, touch_glue 16, touch 181) |
| `npm test --prefix sim` | `all 5 stages passed` (golden `golden check passed`, byte-identical) |
| determinism plain | `determinism passed` |
| determinism `-- --intro --seeds=2 --ticks=900` | `determinism passed` |
| `tools/validate.js` | `279 files checked, 0 errors, 0 warnings` |
| `validate.js --self-test` | `self-test: 9724 of 9724 checks passed` |
| `tools/lint-determinism.mjs` | `determinism lint ok: no engine trig, PI/TAU, random numbers or clock in sim/core, sim/director, sim/world, sim/input` |
| `hud_check` (patch applied) | `hud_check: 5828 checks, 0 failed` |
| `pseudo.mjs --check` (patch applied) | `pseudo-locale is current (10 files)` |
