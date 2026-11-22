# lint-sim-text-float (park, Tools, 2026-11-22; low priority, Simulation's suggestion through the EP)

Simulation's finding (bce578a7): the Windows printf rounds an exact half away from zero and the Linux and web ones to even, so `"%.1f" % -22.25` reads `-22.3` on Windows and `-22.2` elsewhere and the same match prints different text. Simulation added `SimMathx.fixed(v, n)`. This park makes the determinism lint flag the rest.

`lint-sim-text-float.patch` (sha1 `8b37b764826e81eb1d1ea08e92088627dd5b92cf`, three files, applies to bce578a7; `tools/lint-determinism.mjs`, its self-test, `tools/determinism-allow.json`):

- **A new rule `sim-text-float`**: a printf float format in a string (`%.1f`, `%+.2f`, `%5.2f`, `%.0f%%`) in the same four folders the lint already scans (sim/core, director, world, input; not their tools/ and test/ folders). The finding says "use SimMathx.fixed(v, n)". It reads the raw line with the comment cut off (the other rules read the line with strings blanked, which would hide this one), so a `%.1f` in a `#` comment passes, `SimMathx.fixed(...)` passes, `%d`, `%s`, `%05d` and the integer modulo `x % 3` pass, and a `# det-ok: <reason>` waiver works as for the others.
- **The allow list takes a rule per entry**: `{ "path": ..., "rule": "sim-text-float", "why": ... }` allows that rule in that file and nothing else; an entry with no rule still allows the whole file, and an entry naming a rule that does not exist is refused.
- **Eight uses remain on main today, in three files**, and the lint would go red on them, so each file has a rule-scoped entry with a why that names who is to clear it: `sim/director/swing_read.gd` (78 and 79: the debug feed's text), `sim/world/campaign.gd` (405, 409, 414: the campaign's notes), `sim/world/settlements.gd` (139, 228, 230: data-validation error messages). **I have not established that none of them reaches a hashed field**: the text reads like debug, notes and error messages, nothing more. Simulation (the director file) and World (the other two) are to convert them to `SimMathx.fixed` or confirm, then delete the entries; the lint then guards the folders without any entry. The three files are not mine and I did not touch them.

## Checked

- The lint's self-test: 93 checks, all ok (it was 67 before): six uses found, eleven non-uses passed, the waiver, the finding's message, and the allow list (rule-scoped entry allows only its rule in its file; another rule's entry, another file's entry, a whole-file entry, and a made-up rule refused).
- On the real tree with this patch's allow list: `determinism lint ok`. With an empty allow list the same code finds exactly the eight lines above and nothing else (it does not flag the `"%.1f"` named in `mathx.gd`'s and `swing.gd`'s comments).

Not proven: whether the three files' text is hashed (see above); the lint's run in CI (it is the existing step at ci.yml line 86).
