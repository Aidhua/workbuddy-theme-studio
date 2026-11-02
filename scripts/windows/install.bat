@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
if errorlevel 1 pause & exit /b 1
echo.
echo Installation completed. See README.md for persistence and verification.
pause
