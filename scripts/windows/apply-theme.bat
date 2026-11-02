@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply-theme.ps1" %*
if errorlevel 1 pause & exit /b 1
timeout /t 2 /nobreak >nul
