@echo off
title Orb Combat EX - Monday afternoon build
rem The KEPT folder is a build made by tools\preview\stack-preview.mjs and copied by tools\preview\handover.mjs into the repository's homework\Files\builds (git-ignored), never rebuilt. It is served on its own port, 8772, so it never meets the builds before it.
set "KEPT=%~dp0..\Files\builds\orb-first-play-6a30b4c9-6627cb9d"
for %%I in ("%KEPT%") do set "KEPT=%%~fI"
set "ADDR=http://127.0.0.1:8772/index.html?planet=7&meteor=loud&tiles=1&go=1&blackbox=1&audiolog=1&travel=1.5"
echo.
echo Warning: this build has a camera move (the launch swing and the meteor shot) that flashes
echo far more than the safe limit, and Reduce flashing does not lower it. For your own screen only.
echo Do not share the build, clips, recordings or screenshots, and keep anyone sensitive to flashing
echo away from it. If you feel unwell, stop.
echo.
echo If you play in Opera GX: its limiter (GX Control) can slow a tab. Turn it off for this.
echo.
pause
powershell -NoProfile -Command "try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 'http://127.0.0.1:8772/index.html').StatusCode | Out-Null; exit 0 } catch { exit 1 }"
if %errorlevel%==0 (
  start "" "%ADDR%"
  exit /b
)
if not exist "%KEPT%\serve.mjs" (
  echo The kept build is not where this shortcut expects it:
  echo   %KEPT%
  echo Nothing was built or changed. Tell Tools.
  pause
  exit /b 1
)
echo The page is not running, so its server is started in a new window that stays open.
start "Orb Combat EX - the game server (port 8772)" node "%KEPT%\serve.mjs" 8772
powershell -NoProfile -Command "$ok=$false; for ($i=0; $i -lt 30 -and -not $ok; $i++) { try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 'http://127.0.0.1:8772/index.html').StatusCode | Out-Null; $ok=$true } catch { Start-Sleep 1 } }; if ($ok) { exit 0 } else { exit 1 }"
if %errorlevel%==0 (
  start "" "%ADDR%"
  exit /b
)
echo The server did not answer in 30 seconds. Look at the server window for why.
pause
