# menus-a1-sizes (UI & UX, 2026-11-25): one stale line in docs/ui/menus-a1.md

Section 11 said World offers five planet sizes "today". GW1c landed with Medium alone (`data/biomes/sizes.json`: only `medium` is `offered`). The line now says so.

`menus-a1-sizes.patch` (sha1 959406ec1c45): `docs/ui/menus-a1.md`, one line. Docs only.

Next landing, fourth of four: it needs `pad-recommended` first (that park adds section 12 just below, so the patch's context includes it); it does not apply on ac4ba152 alone.
