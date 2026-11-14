# Rail menus run record (UI & UX, 2026-11-09, scratch copy of 592a807b plus the Rail files)

- `rail-rules.txt`: the new `_menus_rail_rules` alone: 549 checks, 0 failed.
- `gate-switch-off.txt`: the whole hud_check gate as shipped (switch off): 8288 checks, 0 failed.
- `gate-switch-pinned-on.txt`: the gate with `menus_rail` pinned on: 3 failed, all older rules that read the old card's drawn words or foot lines (the card says MATCH OVER in capitals and keeps the join and where-saved lines in `join_lines`; the Rail says "Match over" and puts them in the detail card). Expected, and the switch ships off.
- `negative-control.txt`: four faults injected in a scratch copy, all caught.
- `flash-count.txt`: flash count half, both modes.
- Stills: only the start screen (no fighters). The pause, match-over and options stills show the demo's grey-box fighters, so they stay on this PC (scratchpad).
