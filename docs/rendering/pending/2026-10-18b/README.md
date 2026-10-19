# Parked: the whip melt off (Rendering, 2026-10-18)

**Base:** HEAD 929d50c2. The diff was checked on a copy of that commit, never on the tree.

**Apply** from the project root:

```
git -c core.autocrlf=false apply --check docs/rendering/pending/2026-10-18b/batch.diff
git -c core.autocrlf=false apply docs/rendering/pending/2026-10-18b/batch.diff
```

Then delete this folder.

## What it changes

`RenderLook.PAN_WHIP_ON` goes from true to false. While a pane's camera whipped along the ground, every building melted into the sky and ground behind it. With full effects, that melt is itself the change the frame analyser counts, and it is what kept rushcity and signaturecity over the gate on main. The code stays; the constant brings it back.

It reverses the fallback of 2026-10-15, which shipped after Orb's ruling to try Camera's whip-pan cap first. That fallback was measured on the calm look, because the capture hook ran every clip with Reduce flashing on until Tools' 0654a2e2.

| File | Change |
| :--- | :--- |
| `render/core/look.gd` | `PAN_WHIP_ON` false, and why |
| `render/tools/flash_reg_check.gd` | check 10b asserts the whip haze is off, and still tests it in full whenever `PAN_WHIP_ON` is true |
| `docs/rendering/flash-sources.md` | new section "The whip melt is off", with the readings and what else was tried; the whip lines updated |
| `docs/rendering/README.md` | the pan haze sentence |

## Checked

- Tools' clips at full length on fda9b426, main against this change (the table is in `flash-sources.md`):
  - rushcity normal: 3.5 (fail) becomes 2/2/1;
  - rushcity reduced: 2.5/3.5/2 (fail) becomes 2.5/2.5/2;
  - signaturecity normal: 3/3/3 (over the gate) becomes 2/2/2;
  - collapse, mashcity, ai-43 and both blastdummies: the same or within half a step, all passing.
- `gates9` (17 checks) and `cue_check` pass, on fda9b426 and on 929d50c2 with the diff.
