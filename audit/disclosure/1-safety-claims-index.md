# 1. Safety claims index

Each entry is a place where the project records a safety concern, warning, gate, waiver or sign-off.

## Legal
- `docs/legal/review-log.md`: Legal's numbered rows RL-001 to RL-255 (255 rows); the main register of rulings, conditions and owed items. RL-247 is in the working copy only, uncommitted, on Orb's hold.
- `docs/legal/photosensitivity-note.md`: the flashing-effects position and its sources.
- `docs/legal/page-fixed-lines.md`: the fixed warning and notice wording for public pages.
- `docs/legal/holding-page-screen.md`: the screen of the public holding page.
- `docs/legal/pre-store-checklist.md` and `docs/legal/steam-readiness.md`: what must be true before a store page or release.
- `docs/legal/public-readiness-edits.md`: edits required before going public.
- `docs/legal/go-to-market.md`: marketing and distribution constraints (it names COPPA and GDPR).
- `docs/legal/guide-stomp-and-ratings.md`: age-rating notes.
- `docs/legal/originality-rules.md`, `never-use-words.md`, `tropes-and-folklore.md`, `tribute-vs-parody.md`, `name-screening.md`, `movegen-banned.json`: originality and IP rules.
- `docs/legal/licence-register.md`, `licence-recommendation.md`, `asset-origins.md`, `contributor-rules.md`, `suno-music.md`: licences and provenance of assets.
- `docs/legal/*-screen.md` (about 35 files, for example `bystander-comedy-screen.md`, `catastrophe-and-city-screen.md`, `zip-screen.md`, `bolus-predator-screen.md`): per-feature screens. `bystander-comedy-screen.md` is in the working copy only, uncommitted, on Orb's hold.
- `docs/legal/fighter-concepts-review.md`: the review of the fighter concepts.

## Accessibility
- `docs/accessibility/audit-2026-10-28.md`, `beam-alert-review.md`, `right-hand-controls.md`, `swing-motion.md`, `l10n-plan.md`, `cloud-reports/`, `pending/`.

## Flash and pixel checking (tools)
- `tools/flash/`: the flash register tools. `wcag.js` holds the thresholds; `release-pass.json` and `release-pass.mjs` the full-set release pass; `signature-gate.json` and `signature-gate.mjs`; `nightly-seeds.json` and `nightly-switches.json`; `flash_worst.gd` the headless worst-case run; `run-pixels.mjs` the pixel half; `README.md`.
- `docs/tools/` flash-related docs (see `docs/tools/site-interim.md` and others named in `tools/flash/README.md`).

## QA
- `qa/known-bugs.md`, `known-bugs-effects.json`, `known-bugs-whatif.json`, `known-bugs-scan.js`, `known-bugs-repro.js`, `known-bugs-whatif.js`.
- `docs/qa/` (baselines, plans, `cloud-reports/`, including the city reads of 2026-11-06 and 2026-11-07).

## Public site and builds
- `tools/site.json`: the one switch for what the public site serves (offline, interim, pin, template).
- `tools/site-interim.json`, `tools/site-interim-owner.json`, `tools/site-notice.json`, `tools/site-notice-offline.json`: the notices and interim terms.
- `tools/check-site-interim.mjs`, `check-site-offline.mjs`, `check-site-hook.mjs`, `site-template.mjs`, `site-name-scan.mjs`: the site checks.
- `docs/tools/site-interim.md`, `docs/tools/site-template.md`: how the site works.

## LAN and private builds
- `net/tools/lan_words.txt` and `net/tools/lan_kit.mjs`: the LAN folder's WHO PLAYS lines, the warning and the checks the kit runs on them.
- `docs/net/`: netcode docs, including RL-230 and RL-241 terms as applied.
- `docs/tools/shortcuts/*.cmd`: the private-build launchers, with the warning text shown before a build opens.
- `docs/perf/oldpc/`: the old-PC kit and its page.

## Rules and decisions
- `CLAUDE.md`: standing rules (look gate, machine discipline, no prompts in front of Orb, originality).
- `docs/decisions/0001` to `0013`: ADRs. Safety-relevant ones: 0007 AI authorship, 0010 look gate, 0011 PC first, 0013 no laptop target.
- `docs/ep/vision.md`: Orb's own words and rulings, including the second player ("Orb 2") ruling at the end.
- `docs/directors/*.md` (25 charters): each director's standing rules.
- `ui/data/settings.json` and `ui/data/features.json`: the shipped defaults, including Reduce flashing and the feedback report.

## Not indexed
I haven't checked every director's `docs/<area>/` folder for safety notes beyond the above. There may be more, for example in `docs/vfx/`, `docs/camera/` and `docs/rendering/`, where flash and look-gate readings are recorded with each change.
