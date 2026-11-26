# Park: the log cleaner's patterns are not words to translate (Tools, 2026-11-25; re-cut on the EP's ruling)

`l10n-skip-report-clean.patch`. `tools/l10n/strings.mjs` leaves out the patterns, allowed lines and marks of `ui/data/report_clean.json`, and **keeps its one sentence** (`header`, written atop a cleaned log copy). A self-test row holds exactly that.

It also adds the generated `localization/pseudo/ui/data/report_clean.json` (from `pseudo.mjs --write`: the sentence pseudo-translated, the patterns as they are). That folder is Accessibility and Localization's.

Run: `strings --self-test`, `pseudo --self-test`, `pseudo --check` (current, 12 files).
