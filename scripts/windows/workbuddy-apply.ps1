param(
    [ValidateNotNullOrEmpty()][string]$Theme = "open-source-placeholder",
    [ValidateRange(1024, 65535)][int]$Port = 9342,
    [switch]$Restart,
    [switch]$NoRestart,
    [ValidateRange(0, 60)][int]$RestartDelaySeconds = 3
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\common.ps1")
. (Join-Path $PSScriptRoot "lib\workbuddy-session.ps1")
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$app = Resolve-WorkBuddyApp
$runtime = Get-NodeRuntime -App $app
$env:HEIGE_WORKBUDDY_APP = [string]$app.ExecutablePath
$env:HEIGE_WINDOWS_APP_IDENTITY = ConvertTo-HeiGeCodexAppIdentityToken -App $app

function Test-HeiGeWorkBuddyCdpSession {
    param(
        [Parameter(Mandatory = $true)]$AppInfo,
        [Parameter(Mandatory = $true)][int]$CdpPort
    )
    if (-not (Test-CdpEndpoint -Port $CdpPort)) { return $false }
    try {
        Get-CdpOwner -Port $CdpPort -App $AppInfo | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Start-HeiGeWorkBuddyCdpSession {
    param(
        [Parameter(Mandatory = $true)]$AppInfo,
        [Parameter(Mandatory = $true)][int]$CdpPort
    )
    $previousPort = $env:WORKBUDDY_REMOTE_DEBUGGING_PORT
    try {
        $env:WORKBUDDY_REMOTE_DEBUGGING_PORT = [string]$CdpPort
        Start-HeiGeWorkBuddySession -AppInfo $AppInfo -Port $CdpPort | Out-Null
    } finally {
        $env:WORKBUDDY_REMOTE_DEBUGGING_PORT = $previousPort
    }
}

function Wait-HeiGeWorkBuddyCdpSession {
    param(
        [Parameter(Mandatory = $true)]$AppInfo,
        [Parameter(Mandatory = $true)][int]$CdpPort,
        [ValidateRange(1, 3600)][int]$Attempts = 180
    )
    for ($attempt = 0; $attempt -lt $Attempts; $attempt++) {
        if (Test-HeiGeWorkBuddyCdpSession -AppInfo $AppInfo -CdpPort $CdpPort) {
            return $true
        }
        Start-Sleep -Milliseconds 250
    }
    return $false
}

# WorkBuddy 点右上角关闭通常只是收进托盘：进程仍在、9342 没开。
# 以前这里直接 throw，用户看到的只是「点了启动器没反应」。
# 现在默认正常关闭再以 CDP 重启；-NoRestart 保留旧的只报错行为。
if (-not (Test-HeiGeWorkBuddyCdpSession -AppInfo $app -CdpPort $Port)) {
    $running = @(Get-RunningCodex -AppInfo $app)
    if ($running.Count -gt 0) {
        if ($NoRestart) {
            throw "WorkBuddy 正在运行，但没有绑定 $Port 皮肤会话。请先彻底退出 WorkBuddy（含托盘图标退出），再重试启动器。"
        }
        Write-Host "检测到 WorkBuddy 正在运行（可能只是最小化到了托盘）。"
        if (-not $Restart -and $RestartDelaySeconds -gt 0) {
            Write-Host "应用皮肤需要重启 WorkBuddy；$RestartDelaySeconds 秒后自动继续，按 Ctrl+C 可取消。"
            Start-Sleep -Seconds $RestartDelaySeconds
        }
        Write-Host "正在正常关闭 WorkBuddy..."
        Stop-CodexNormally -AppInfo $app | Out-Null
        $remaining = @(Get-RunningCodex -AppInfo $app)
        if ($remaining.Count -gt 0) {
            throw "WorkBuddy 仍在运行（进程 $($remaining[0].Id -join ', ')），无法切换皮肤会话；请在托盘图标中退出后重试。"
        }
    }
    Write-Host "正在以 $Port 调试端口启动 WorkBuddy..."
    Start-HeiGeWorkBuddyCdpSession -AppInfo $app -CdpPort $Port
    if (-not (Wait-HeiGeWorkBuddyCdpSession -AppInfo $app -CdpPort $Port)) {
        throw "WorkBuddy 已启动，但 $Port 端口没有进入皮肤会话（可能被其他进程占用，或 WorkBuddy 启动失败）。"
    }
}

$arguments = @(
    (Join-Path $root "src\cli.mjs"),
    "apply", "--app", "workbuddy", "--theme", $Theme, "--port", [string]$Port
)
$json = Invoke-SkinCli -Node ([string]$runtime.Path) -CliArgs $arguments
$result = $json | ConvertFrom-Json
if ([string]$result.mode -cne "active") {
    throw "WorkBuddy skin did not enter active mode: $json"
}
Write-Host "WorkBuddy skin applied: $Theme (persistence setting unchanged; use the in-app toggle)."
Write-Host "可以关闭本窗口；它不会再带走 WorkBuddy。"
$result
