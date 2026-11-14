# CAMERA: verifier 2 (commit 8901d351)

| id | verdict | new severity | what I checked | note |
|---|---|---|---|---|
| F-CAMERA-13 | confirmed | unchanged (minor) | render/camera/camera_params.gd:1-628 (628 lines, 503 `const` lines, first at :7, last at :628); `ls data/camera` (swing.json only); data/camera/swing.json:1-7 (two numbers: splitShare, peakRate); DIRECTORS.md:297 (owns `render/camera/, docs/camera/`, no data/camera); CLAUDE.md conventions ("Numbers live in data, not code") | The counts hold: 503 constants in code against one data file with two numbers, and the owns line does not name data/camera. Only slip: the constants start at line 7, not 16; nothing a tester sees depends on it, so minor stands. |
