param([ValidateRange(1024, 65535)][int]$Port = 9342)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\common.ps1")
. (Join-Path $PSScriptRoot "lib\workbuddy-session.ps1")
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$app = Resolve-WorkBuddyApp
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$runtime = Get-NodeRuntime -App $app
$env:HEIGE_WORKBUDDY_APP = [string]$app.ExecutablePath
$env:HEIGE_WINDOWS_APP_IDENTITY = ConvertTo-HeiGeCodexAppIdentityToken -App $app
if (-not (Test-CdpEndpoint -Port $Port)) {
    Write-Host "WorkBuddy is already running without the HeiGe skin session."
    return
}
Get-CdpOwner -Port $Port -App $app | Out-Null
Write-Host "Closing the skinned WorkBuddy session and reopening the native UI..."
$disableArguments = @(
    (Join-Path $root "src\cli.mjs"),
    "set-persistence", "false", "--app", "workbuddy", "--port", [string]$Port
)
Invoke-SkinCli -Node ([string]$runtime.Path) -CliArgs $disableArguments | Out-Null
Stop-CodexNormally -AppInfo $app | Out-Null
Remove-HeiGeWorkBuddySessionTask

$previousPort = $env:WORKBUDDY_REMOTE_DEBUGGING_PORT
try {
    Remove-Item Env:WORKBUDDY_REMOTE_DEBUGGING_PORT -ErrorAction SilentlyContinue
    Start-HeiGeWorkBuddySession -AppInfo $app -Port 0 | Out-Null
} finally {
    if ($null -ne $previousPort) {
        $env:WORKBUDDY_REMOTE_DEBUGGING_PORT = $previousPort
    }
}
Write-Host "Native WorkBuddy restored."
