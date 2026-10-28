# ADR 0011: PC first. Mobile is parked until after the PC launch

- Status: accepted (Orb, 2026-10-28)
- Context: the vision lists mobile among the launch platforms (docs/ep/vision.md). Every UI change has been checked at 14 screen sizes, phone portrait and landscape among them. Performance has budgeted against a phone four times slower than Orb's PC, and a friend's Android freeze was being chased. Touch controls for a fighting game remained an open worry: Orb raised the phone control scheme twice, and a friend's phone test found the controls hard to use. iOS needs a Mac and a yearly fee, which zero budget (ADR 0005) does not cover. Orb asked to focus on a tight PC build.

## Decision

1. **The launch platforms are PC:** Windows, Linux (Steam Deck included) and macOS, plus the browser on a computer. Mobile (Android and iOS, native or touch-first) is **parked until after the PC launch**: not scrapped, and not worked on.
2. **No new phone-specific work.** That means touch controls, portrait layouts, phone-only HUD rules, the phone speed budget and the Android freeze investigation. What exists stays in the tree as it is. Directors don't delete it and don't maintain it beyond keeping CI green. A check that only guards a phone case may be dropped from a gate when it gets in the way, with the EP's word.
3. **The minimum hardware stays "old laptops".** Performance budgets against an old laptop with integrated graphics in place of the four-times-slower phone. Speed work that helps both, such as boot time and stutter, keeps going.
4. **Input is keyboard and gamepad,** equally (ADR 0008 unchanged for those).
5. **Phones that open the browser demo** see a short note before the flashing notice ("best on a computer, with a keyboard or a controller") and a button to continue anyway, as today. The words go through Legal's public-copy checks like any page line.
6. **Revisit** after the PC launch, if the game finds an audience. Godot can still export to Android, so the door stays open at no cost.

## Consequences

- UI, Controls and Performance drop phone work from their queues. Briefs stop asking for phone sizes and phone timings.
- The browser demo keeps working on phones as it does today, with the note in front.
- Tonight's boot and stutter fixes, made for the Android report, stay: they help slow laptops and browsers too.
