@echo off
setlocal
REM ASCII-only on purpose: all Chinese output comes from PowerShell as UTF-8.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set "HEIGE_EXIT=%ERRORLEVEL%"
echo.
if not "%HEIGE_EXIT%"=="0" (
  echo [FAILED] exit code %HEIGE_EXIT%. Read the messages above.
  if /I not "%HEIGE_NO_PAUSE%"=="1" pause
  exit /b %HEIGE_EXIT%
)
echo [OK] Installation finished.
echo      NEXT STEP: double-click apply-theme.bat
echo      Closing in 10 seconds, or press any key to close now.
if /I not "%HEIGE_NO_PAUSE%"=="1" timeout /t 10
exit /b 0
