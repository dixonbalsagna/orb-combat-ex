@echo off
rem Orb Combat EX native frame-time bench: see orb-native-bench.ps1 for what it does. It opens a game window for 1 to 2 minutes a pass.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0orb-native-bench.ps1" %*
echo.
pause
