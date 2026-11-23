@echo off
rem The one-click first run (tools/first-run/first-run.mjs). Double-click this file.
rem It starts the newest private Windows build in homework\Files\desktop (made by: node tools/desktop-local-build.mjs), plays one fixed match, saves stills, records the frame rate and loading times,
rem saves a report beside the stills (homework\Files\first-run\...) and closes the game. Nothing is uploaded; nothing leaves this PC.
title Orb Combat EX, first run
echo.
echo  ORB COMBAT EX, FIRST RUN
echo  The game will open a window and show its warning about flashing effects. Read it and press Enter in the game.
echo  After that it plays by itself for about two minutes and closes. Please do not use the keyboard or the mouse then.
echo  This is a performance and screens check, not a flashing-effects check. You alone should watch it.
echo.
pause
cd /d "%~dp0\..\.."
node tools\first-run\first-run.mjs %*
echo.
echo  The report is in homework\Files\first-run (the newest folder). Send that folder's first-run-report.md and the pictures.
pause
