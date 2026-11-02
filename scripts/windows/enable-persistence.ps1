$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
& (Join-Path $PSScriptRoot "workbuddy-apply.ps1") -Theme "open-source-placeholder"
Write-Host ""
Write-Host "Persistence requires confirmation in the verified WorkBuddy Theme Center."
Write-Host "Return to WorkBuddy, open Theme, and enable skin persistence."
Write-Host "After it is enabled, wait five seconds and run diagnose.bat."
Write-Host "Manually exiting WorkBuddy keeps it closed; only the controller is kept alive."
