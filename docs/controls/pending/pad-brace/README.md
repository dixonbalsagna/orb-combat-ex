# pad-brace: brace_key bound on Arena, so "Button only" never strands a pad player (Controls, 2026-11-07; audit CD-14)

Run record: `docs/controls/runs/cb477edf/`.

## What happened
Controls bound the pad's brace button (`brace_key`) to **L3 on Arena, R3 swapped** on 2026-10-31 (8db493cb, `docs/controls/right-hand-attacks.md`). The landing d5582dbd took it out of `data/input/layouts.json` (the pad-first-press note says brace is off for the first press), so UI's help ("The button is L3 on Arena (R3 if swapped)") was true of nothing, and a pad player choosing `brace_style` "Button only" had no brace. This puts it back.

## Files
- `pad-brace.patch` (2 files), Controls': `data/input/layouts.json` (Arena's `strikeBindings` gets `pad:l3` as `brace_key`; the swapped preset derives R3), `sim/input/test/strike_hub_test.gd` (63 checks, was 61: Arena lists L3 as bound, Arena swapped R3, Simple none, a click of L3 or R3 is a brace read, L3 is a conflict for the strike button).

Apply: `git -c core.autocrlf=false -c core.eol=lf apply pad-brace.patch`.

## Rulings and risks
- **Simple has no strikes and no brace** (the right-hand reader needs a strike control; binding one would turn it on for Simple), so Simple stays unbound. A Simple pad player has no flick brace either, so "Button only" strands nobody there.
- **The strike button's one-stick form** (`strike_key`) can no longer take L3 by default (the brace has it); it was already a Remap row, and Remap names the conflict.
- **A stray L3 click** (a stick press while moving) now sets a brace read, the cost the flick brace has. It is why the first-press note left it off. The read is only a read: it does nothing without a blow to meet.
- UI's strings and `hud_check` already say L3 and R3; nothing for UI to change.

## Checked
All 38 input tests; lint and validate clean; the patch on clean HEAD gives the tested tree byte for byte. Not run: `hud_check` (UI's, untouched).

## NEEDS FROM EP
Nothing. Design may want the pad-first-press note updated (docs/design, not Controls').
