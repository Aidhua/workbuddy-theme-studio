$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\common.ps1")
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$app = Resolve-WorkBuddyApp
$runtime = Get-NodeRuntime -App $app
$port9342 = @(Get-NetTCPConnection -State Listen -LocalAddress 127.0.0.1 -LocalPort 9342 -ErrorAction SilentlyContinue)
$port9341 = @(Get-NetTCPConnection -State Listen -LocalAddress 127.0.0.1 -LocalPort 9341 -ErrorAction SilentlyContinue)
$controller = Get-ScheduledTask -TaskName "HeiGe WorkBuddy Skin Studio Controller" -ErrorAction SilentlyContinue
$session = Get-ScheduledTask -TaskName "HeiGe WorkBuddy Skin Session" -ErrorAction SilentlyContinue
$terminals = @(Get-Process WindowsTerminal -ErrorAction SilentlyContinue)
$visibleConhosts = @(Get-Process conhost -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })

[pscustomobject][ordered]@{
    WorkBuddyFound = Test-Path -LiteralPath ([string]$app.ExecutablePath)
    WorkBuddyVersion = [string]$app.Version
    NodeVersion = [string]$runtime.Version
    Port9342Listening = $port9342.Count -eq 1
    Port9342OwnerPid = if ($port9342.Count -eq 1) { [int]$port9342[0].OwningProcess } else { $null }
    Port9341Listening = $port9341.Count -gt 0
    CodexPortTouched = $false
    PersistenceTask = if ($controller) { [string]$controller.State } else { "NotInstalled" }
    SessionTask = if ($session) { [string]$session.State } else { "NotInstalled" }
    PersistenceHeadless = if ($controller) { [string]$controller.Actions[0].Execute -match 'conhost\.exe$' -and [string]$controller.Actions[0].Arguments -match '^--headless ' } else { $null }
    KeepAlivePT1M = if ($controller) { @($controller.Triggers | Where-Object { [string]$_.Repetition.Interval -eq 'PT1M' }).Count -eq 1 } else { $null }
    WindowsTerminalProcesses = $terminals.Count
    VisibleConhostWindows = $visibleConhosts.Count
} | Format-List
