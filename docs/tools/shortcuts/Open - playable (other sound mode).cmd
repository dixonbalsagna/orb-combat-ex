@echo off
title Orb Combat EX - private playable, the other sound mode (the kept build)
rem The KEPT2 folder is the second build Orb is handed: the same game as "Open - playable", with the web sound played the other way (Sample, the default of the engine, instead of Stream). A copy made by tools\preview\handover.mjs, named by its commit and key, kept in the repository's homework\Files\builds (git-ignored; the path below is relative to this shortcut's folder, homework\<a folder>\, so renaming the project folder breaks nothing) and never rebuilt. It is served on port 8767 so it never meets the normal build on 8766.
set "KEPT2=%~dp0..\Files\builds\orb-first-play-018b4edf-fc994af8"
for %%I in ("%KEPT2%") do set "KEPT2=%%~fI"
set "ADDR=http://127.0.0.1:8767/index.html?planet=7&meteor=loud&tiles=1&go=1&blackbox=1"
echo.
echo This is the same game as "Open - playable", with the sound played the other way:
echo lower delay, but it may be silent. Use it to compare with the normal one.
echo.
echo Warning: this build has a camera move (the launch swing and the meteor shot) that flashes
echo far more than the safe limit, and Reduce flashing does not lower it. For your own screen only.
echo Do not share the build, clips, recordings or screenshots, and keep anyone sensitive to flashing
echo away from it. If you feel unwell, stop.
echo.
echo If you play in Opera GX: its limiter (GX Control) can slow a tab. Turn it off for this.
echo.
pause
powershell -NoProfile -Command "try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 'http://127.0.0.1:8767/index.html').StatusCode | Out-Null; exit 0 } catch { exit 1 }"
if %errorlevel%==0 (
  start "" "%ADDR%"
  exit /b
)
if not exist "%KEPT2%\serve.mjs" (
  echo The kept build is not where this shortcut expects it:
  echo   %KEPT2%
  echo Nothing was built or changed. Tell Tools.
  pause
  exit /b 1
)
echo The server for this build is started in a new window that stays open.
start "Orb Combat EX - the game server, other sound mode (port 8767)" cmd /k node "%KEPT2%\serve.mjs" 8767
powershell -NoProfile -Command "$ok=$false; for ($i=0; $i -lt 30 -and -not $ok; $i++) { try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 'http://127.0.0.1:8767/index.html').StatusCode | Out-Null; $ok=$true } catch { Start-Sleep 1 } }; if ($ok) { exit 0 } else { exit 1 }"
if %errorlevel%==0 (
  start "" "%ADDR%"
  exit /b
)
echo The server did not answer in 30 seconds. Look at the server window for why.
pause
