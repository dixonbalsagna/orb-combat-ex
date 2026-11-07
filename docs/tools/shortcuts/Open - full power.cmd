@echo off
title Orb Combat EX - private playable, START AT FULL POWER (the kept build)
rem The KEPT folder is the build Orb is handed: a copy made by tools\preview\handover.mjs, named by its commit, kept in the repository's homework\Files\builds (git-ignored; the path below is relative to this shortcut's folder, homework\<a folder>\, so renaming the project folder breaks nothing) and never rebuilt.
set "KEPT=%~dp0..\Files\builds\orb-first-play-018b4edf-fddd34b4"
for %%I in ("%KEPT%") do set "KEPT=%%~fI"
set "ADDR=http://127.0.0.1:8766/index.html?planet=7&meteor=loud&tiles=1&go=1&blackbox=1&peak=1"
echo.
echo Warning: this build has a camera move (the launch swing and the meteor shot) that flashes
echo far more than the safe limit, and Reduce flashing does not lower it. For your own screen only.
echo Do not share the build, clips, recordings or screenshots, and keep anyone sensitive to flashing
echo away from it. If you feel unwell, stop.
echo.
echo This one starts both fighters at full power (tier 4): the meteor, the beams and the forms from the first second.
echo.
echo If you play in Opera GX: its limiter (GX Control) can slow a tab. Turn it off for this.
echo.
pause
powershell -NoProfile -Command "try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 'http://127.0.0.1:8766/index.html').StatusCode | Out-Null; exit 0 } catch { exit 1 }"
if %errorlevel%==0 (
  start "" "%ADDR%"
  exit /b
)
if not exist "%KEPT%\serve.cmd" (
  echo The kept build is not where this shortcut expects it:
  echo   %KEPT%
  echo Nothing was built or changed. Tell Tools.
  pause
  exit /b 1
)
echo The page is not running, so its server is started in a new window that stays open.
start "Orb Combat EX - the game server" "%KEPT%\serve.cmd"
powershell -NoProfile -Command "$ok=$false; for ($i=0; $i -lt 30 -and -not $ok; $i++) { try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 'http://127.0.0.1:8766/index.html').StatusCode | Out-Null; $ok=$true } catch { Start-Sleep 1 } }; if ($ok) { exit 0 } else { exit 1 }"
if %errorlevel%==0 (
  start "" "%ADDR%"
  exit /b
)
echo The server did not answer in 30 seconds. Look at the server window for why.
pause
