@echo off
setlocal
REM ASCII-only on purpose: all Chinese output comes from PowerShell as UTF-8.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply-theme.ps1" %*
set "HEIGE_EXIT=%ERRORLEVEL%"
echo.
if not "%HEIGE_EXIT%"=="0" (
  echo [FAILED] exit code %HEIGE_EXIT%. Read the messages above.
  if /I not "%HEIGE_NO_PAUSE%"=="1" pause
  exit /b %HEIGE_EXIT%
)
echo [OK] Theme applied.
echo      If the skin is not visible yet: open a real chat and wait up to 45 seconds.
echo      Closing in 5 seconds, or press any key to close now.
if /I not "%HEIGE_NO_PAUSE%"=="1" timeout /t 5
exit /b 0
