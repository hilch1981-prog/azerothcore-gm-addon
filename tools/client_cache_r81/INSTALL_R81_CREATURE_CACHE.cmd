@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Merge-CreatureCache-R81.ps1"
echo.
pause
