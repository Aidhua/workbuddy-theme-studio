@echo off
setlocal
REM ASCII-only on purpose: all Chinese output comes from PowerShell as UTF-8.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
set "HEIGE_EXIT=%ERRORLEVEL%"
echo.
if not "%HEIGE_EXIT%"=="0" (
  echo [FAILED] exit code %HEIGE_EXIT%. Read the messages above.
  if /I not "%HEIGE_NO_PAUSE%"=="1" pause
  exit /b %HEIGE_EXIT%
)
echo [OK] Uninstalled. Project copy, state and user themes are gone.
echo      WorkBuddy itself is untouched.
echo      Closing in 5 seconds, or press any key to close now.
if /I not "%HEIGE_NO_PAUSE%"=="1" timeout /t 5
exit /b 0
