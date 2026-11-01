@echo off
rem The old-PC test's server on THIS PC (Performance and Platform). See docs\perf\oldpc-test-2026-10-31.md.
rem   start-test.cmd        shows the plan and listens on nothing
rem   start-test.cmd go     listens on this PC's home-network address only, for up to 45 minutes, until a result comes in
rem The build it serves is the private preview's live folder (node tools\preview\stack-preview.mjs makes it).
cd /d "%~dp0\..\..\.."
set SITE=%LOCALAPPDATA%\Temp\meridian-stack-preview\live
if not exist "%SITE%\index.html" (
  echo No build found in %SITE%
  echo Run:  node tools\preview\stack-preview.mjs --no-serve
  pause
  exit /b 1
)
if /i "%1"=="go" (
  node docs\perf\oldpc\oldpc-server.mjs --site "%SITE%" --go
) else (
  node docs\perf\oldpc\oldpc-server.mjs --site "%SITE%"
  echo.
  echo Nothing is listening. To start it for real: start-test.cmd go
)
pause
