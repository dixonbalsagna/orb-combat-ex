# Forced-crash check, windows, commit bc1e5558 (2026-11-23)

- ok: the "Windows Desktop" release export with the probe (121162264 bytes)
- ok: 1 the program died (not a clean quit) (exit 3221225501)
- ok: 2 a log file is in the game's data folder (1 file(s), 3 lines)
- ok: 3 the log says why (the engine's own error line with the reason)
- ok: 4 the next start keeps the dead run's log (rotated to a dated file, not overwritten) (1 then 2 file(s); next start exit 0)
- ok: 5 a hang is stopped by the harness; its log shows the run started (stopped at the limit; a hang leaves no reason line)
- ok: 6 the report folder picks the log up (a log is in user://reports)
- ok: 7 the logs pass the report scan (no folder path, no account or PC name, under the size limit) (9 file(s) scanned, 0 finding(s))

0 failed.
