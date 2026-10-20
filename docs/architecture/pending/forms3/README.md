# forms3: the forms' working rule (parked)

Owner: Simulation and Engine. 2026-10-19. Game Design's working rule of 2026-10-18 (`docs/design/rulings-2026-10-18b.md` item 2) and Witness's `perPerson` 4 (`rulings-2026-10-18.md`), behind the forms switch (`data/fight/forms.json`, off). The page is `../../forms-core.md` section 8.

## Apply

On a clean export of f91ad3c9 or later, from the repo root:

```
python docs/architecture/pending/forms3/forms3.py .
python docs/architecture/pending/forms3/grant_tools.py .
```

`grant_tools.py` is Tools': the forms schema's release block (`minCoil`, `perPoint`, `maxMul`), the self-test's fixture hero and its release cases. It goes in the same commit, since the schema is closed.

## What it changes

- `sim/core/forms.gd`: a release takes the next step only; the coil sets the form's factor (`formMul`); the burst, the surge, its armour and the lasting gain are gone.
- `sim/core/state.gd`: `FormState.formMul` in place of `surgeT`, `surgeMul`, `armour` and `lasting`.
- `data/fighters/PROTAGONIST/forms.json`: the release block and its note; `perPerson` 4.
- `sim/core/tools/parity.gd`: the two forms checks follow the rule.
- `docs/architecture/fx-events.md`: `form_release`'s `n` is 1.
- Three comments in `damage.gd` and `fighter.gd` that named the surge.

## Results (scratch, on f91ad3c9)

- Import clean. Parity on the committed golden: 63 of 63.
- The golden regenerates byte-identical.
- Validator: 0 errors, 0 warnings; self-test all passed (with every park of this batch, 8,566 of 8,566).
