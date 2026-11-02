$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\common.ps1")
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$app = Resolve-WorkBuddyApp
$runtime = Get-NodeRuntime -App $app
$env:HEIGE_WORKBUDDY_APP = [string]$app.ExecutablePath
$env:HEIGE_WINDOWS_APP_IDENTITY = ConvertTo-HeiGeCodexAppIdentityToken -App $app
$arguments = @((Join-Path $root "src\cli.mjs"), "set-persistence", "false", "--app", "workbuddy", "--port", "9342")
Invoke-SkinCli -Node ([string]$runtime.Path) -CliArgs $arguments | Out-Null
Write-Host "Persistence is disabled. This session remains skinned; the next start uses the native UI."
