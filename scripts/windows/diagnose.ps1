$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\common.ps1")
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$controllerTaskName = "HeiGe WorkBuddy Skin Studio Controller"
$sessionTaskName = "HeiGe WorkBuddy Skin Session"

$app = Resolve-WorkBuddyApp
$runtime = Get-NodeRuntime -App $app
$port9342 = @(Get-NetTCPConnection -State Listen -LocalAddress 127.0.0.1 -LocalPort 9342 -ErrorAction SilentlyContinue)
$port9341 = @(Get-NetTCPConnection -State Listen -LocalAddress 127.0.0.1 -LocalPort 9341 -ErrorAction SilentlyContinue)
$controller = Get-ScheduledTask -TaskName $controllerTaskName -ErrorAction SilentlyContinue
$session = Get-ScheduledTask -TaskName $sessionTaskName -ErrorAction SilentlyContinue
$terminals = @(Get-Process WindowsTerminal -ErrorAction SilentlyContinue)
$visibleConhosts = @(Get-Process conhost -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })

# 9342 的持有者到底是不是官方 WorkBuddy —— 这是唯一真正重要的判据
$ownerPid = $null
$ownerPath = $null
$ownerIsWorkBuddy = $null
if ($port9342.Count -eq 1) {
    $ownerPid = [int]$port9342[0].OwningProcess
    $ownerProcess = Get-Process -Id $ownerPid -ErrorAction SilentlyContinue
    if ($null -ne $ownerProcess) { $ownerPath = [string]$ownerProcess.Path }
    if ($ownerPath) { $ownerIsWorkBuddy = ((Split-Path $ownerPath -Leaf) -ieq "WorkBuddy.exe") }
}

$userEnvPort = [Environment]::GetEnvironmentVariable("WORKBUDDY_REMOTE_DEBUGGING_PORT", "User")
$restartApps = $null
try {
    $restartApps = (Get-ItemProperty -LiteralPath "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" `
        -Name "RestartApps" -ErrorAction Stop).RestartApps
} catch {}

# 启动方式：优先读 setup-startup.ps1 写入的记录，读不到就按现场特征推断
$stateDir = Join-Path (Join-Path $env:USERPROFILE ".workbuddy") "HeiGeCodexSkinStudio-workbuddy"
$modeFile = Join-Path $stateDir "startup-mode.json"
$modeRecord = $null
if (Test-Path -LiteralPath $modeFile -PathType Leaf) {
    try { $modeRecord = Get-Content -LiteralPath $modeFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
}
$startupMode = "Default"
if ($modeRecord -and $modeRecord.CurrentMode) {
    $startupMode = [string]$modeRecord.CurrentMode
} elseif ($userEnvPort) {
    $startupMode = "Manual (env)"
} elseif ($session -and [string]$session.State -ceq "Ready") {
    $startupMode = "Auto (task)"
}

function ConvertFrom-TaskResult {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return $null }
    $code = [long]$Value
    if ($code -eq 0) { return "0 (正常结束)" }
    if ($code -eq 267009) { return "267009 (0x41301 正在运行)" }
    if ($code -eq 267014) { return "267014 (0x41306 任务被手动停止，切换启动方式时会看到)" }
    if ($code -eq 2147946720) { return "2147946720 (0x800710E0 上一次实例还在跑，本次触发被忽略，属正常)" }
    return "$code (异常，见 docs/TROUBLESHOOTING.md)"
}

$sessionLastResult = $null
$sessionLastRun = $null
if ($session) {
    $sessionInfo = Get-ScheduledTaskInfo -TaskName $sessionTaskName -ErrorAction SilentlyContinue
    if ($null -ne $sessionInfo) {
        $sessionLastResult = $sessionInfo.LastTaskResult
        $sessionLastRun = $sessionInfo.LastRunTime
    }
}

[pscustomobject][ordered]@{
    WorkBuddyFound             = Test-Path -LiteralPath ([string]$app.ExecutablePath)
    WorkBuddyVersion           = [string]$app.Version
    NodeVersion                = [string]$runtime.Version
    Port9342Listening          = $port9342.Count -eq 1
    Port9342OwnerPid           = $ownerPid
    Port9342OwnerIsWorkBuddy   = $ownerIsWorkBuddy
    Port9341Listening          = $port9341.Count -gt 0
    CodexPortTouched           = $false
    StartupMode                = $startupMode
    UserLevelPortVariable      = if ($userEnvPort) { $userEnvPort } else { "(未设置)" }
    RestartAppsOnSignIn        = if ($null -eq $restartApps) { "(未设置，系统默认开启)" } else { $restartApps }
    PersistenceTask            = if ($controller) { [string]$controller.State } else { "NotInstalled" }
    SessionTask                = if ($session) { [string]$session.State } else { "NotInstalled" }
    SessionTaskLastResult      = ConvertFrom-TaskResult -Value $sessionLastResult
    SessionTaskLastRunTime     = $sessionLastRun
    PersistenceHeadless        = if ($controller) { [string]$controller.Actions[0].Execute -match 'conhost\.exe$' -and [string]$controller.Actions[0].Arguments -match '^--headless ' } else { $null }
    KeepAlivePT1M              = if ($controller) { @($controller.Triggers | Where-Object { [string]$_.Repetition.Interval -eq 'PT1M' }).Count -eq 1 } else { $null }
    WindowsTerminalProcesses   = $terminals.Count
    VisibleConhostWindows      = $visibleConhosts.Count
} | Format-List

# ---------------------------------------------------------------------------
# 人话结论：先给判定，再给下一步该点哪个 bat
# ---------------------------------------------------------------------------
Write-Host "`n—— 体检结论 ——" -ForegroundColor Cyan

$verdict = $null
$action = $null

if (-not (Test-Path -LiteralPath ([string]$app.ExecutablePath))) {
    $verdict = "找不到 WorkBuddy.exe，本项目无从下手。"
    $action = "确认 WorkBuddy 已正常安装；如果装在非默认位置，设置环境变量 HEIGE_WORKBUDDY_APP 指向 WorkBuddy.exe 后重跑。"
} elseif ($port9342.Count -ne 1) {
    $verdict = "9342 没有监听：当前这个 WorkBuddy 进程没有带皮肤端口，皮肤不会生效。"
    if ($startupMode -like "Auto*") {
        $action = "等 60 秒再跑一次 diagnose.bat（开机后系统可能先拉起了一个无端口实例，会话任务会在一分钟内纠正）。仍不恢复就运行 apply-theme.bat。"
    } else {
        $action = "完全退出 WorkBuddy（托盘也要退），再双击桌面图标；如果还是不行，运行 apply-theme.bat 重建会话。"
    }
} elseif ($ownerIsWorkBuddy -eq $false) {
    $verdict = "9342 被别的程序占用了（$ownerPath）。"
    $action = "退出那个程序；不要改用 9341，那是 ChatGPT/Codex 的端口。"
} else {
    $verdict = "链路正常：9342 由 WorkBuddy 自己持有，皮肤注入通道是通的。"
    $action = "如果界面还看不到皮肤，先打开一个真实会话——首页没有消息卡片，样式看不出来是正常的。"
}

Write-Host ("判定：" + $verdict)
Write-Host ("下一步：" + $action)

if ($controller -and $controller.Actions[0].Execute -and ([string]$controller.Actions[0].Execute -notmatch 'conhost\.exe$')) {
    Write-Host "警告：控制器任务没有用 conhost --headless 承载，可能会弹黑窗。重新运行 install.bat 可修复。" -ForegroundColor Yellow
}
if ($visibleConhosts.Count -gt 0) {
    Write-Host ("提示：检测到 " + $visibleConhosts.Count + " 个带窗口的 conhost。如果看到一闪而过的黑框，属于内核级瞬时窗口，不影响功能。") -ForegroundColor Yellow
}
if ($startupMode -eq "Default") {
    Write-Host "提示：还没设置启动方式。想让「点图标就有皮肤、退出就是退出」，运行 setup-startup.bat 选 1。" -ForegroundColor Yellow
}
Write-Host ""
