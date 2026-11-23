# Forced-crash check, windows, commit ec80e318 (2026-11-23)

- ok: the "Windows Desktop" release export with the probe (121147880 bytes)
- ok: 1 the program died (not a clean quit) (exit 3221225501)
- ok: 2 a log file is in the game's data folder (1 file(s), 3 lines)
- ok: 3 the log says why (the engine's own error line with the reason)
- ok: 4 the next start keeps the dead run's log (rotated to a dated file, not overwritten) (1 then 2 file(s); next start exit 0)
- ok: 5 a hang is stopped by the harness; its log shows the run started (stopped at the limit; a hang leaves no reason line)
- WAITING: 6 the report folder picks the log up (nothing in user://reports (UI's report folder does not copy logs yet: waiting for a grant))

0 failed.
