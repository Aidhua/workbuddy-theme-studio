# HeiGe Codex Skin Studio - 启动方式管理（Windows / WorkBuddy）
#
# 为什么需要这个脚本：
#   Electron 的单实例锁决定了只有「第一个」启动的进程能带上 CDP 端口。
#   从桌面图标、开始菜单、Windows 11 的「登录后自动重启应用」启动的实例都没有端口，
#   皮肤注入会失效，于是会话任务不得不反复重拉，形成「开机没皮肤 / 退出又自己回来」。
#
# 三种模式：
#   Manual  - 你点图标才启动，点开就带皮肤；退出就是退出，不会被强行拉回来。（默认推荐）
#   Auto    - 允许后台会话任务在 WorkBuddy 退出后自动拉起带端口的实例，开机即有皮肤。
#   Restore - 撤销本脚本做过的全部改动，回到干净的官方启动行为。
#
# 用法：
#   setup-startup.bat                 交互菜单
#   setup-startup.bat -Mode Manual    直接指定
#   setup-startup.bat -Mode Manual -UseShortcut
#                                     不用用户级环境变量，改为改写桌面快捷方式
#   setup-startup.bat -Mode Restore   撤销

#requires -Version 5.1
param(
    [ValidateSet("Manual", "Auto", "Restore")][string]$Mode,
    [switch]$UseShortcut,
    [ValidateRange(1024, 65535)][int]$Port = 9342
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

. (Join-Path $PSScriptRoot "lib\common.ps1")
. (Join-Path $PSScriptRoot "lib\workbuddy-session.ps1")

$app = Resolve-WorkBuddyApp
$exePath = [string]$app.ExecutablePath
$stateDir = Join-Path (Join-Path $env:USERPROFILE ".workbuddy") "HeiGeCodexSkinStudio-workbuddy"
$recordPath = Join-Path $stateDir "startup-mode.json"
$launcherDir = Join-Path $env:LOCALAPPDATA "HeiGeSkinLauncher"
$launchPs1 = Join-Path $launcherDir "launch.ps1"
$launchVbs = Join-Path $launcherDir "launch.vbs"
$winlogon = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
$sessionTaskName = $script:HeiGeWorkBuddySessionTaskName
$envName = "WORKBUDDY_REMOTE_DEBUGGING_PORT"

New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

# ---------------------------------------------------------------------------
# 小工具
# ---------------------------------------------------------------------------
function Get-RestartAppsValue {
    try { return (Get-ItemProperty -LiteralPath $winlogon -Name "RestartApps" -ErrorAction Stop).RestartApps }
    catch { return $null }
}

function Set-RestartAppsValue {
    param([AllowNull()][object]$Value)
    if (-not (Test-Path -LiteralPath $winlogon)) { New-Item -Path $winlogon -Force | Out-Null }
    if ($null -eq $Value) {
        # 没有原值时按「关闭自动重启应用」处理，这是安全方向：不会抢跑出无端口实例。
        New-ItemProperty -LiteralPath $winlogon -Name "RestartApps" -PropertyType DWord -Value 0 -Force | Out-Null
    } else {
        New-ItemProperty -LiteralPath $winlogon -Name "RestartApps" -PropertyType DWord `
            -Value ([int]$Value) -Force | Out-Null
    }
}

function Get-StartupRecord {
    if (-not (Test-Path -LiteralPath $recordPath -PathType Leaf)) { return $null }
    try { return (Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 | ConvertFrom-Json) }
    catch { return $null }
}

function Save-StartupRecord {
    param([Parameter(Mandatory = $true)]$Record)
    $Record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $recordPath -Encoding UTF8
}

function Get-WorkBuddyShortcuts {
    $shell = New-Object -ComObject WScript.Shell
    $dirs = @(
        [Environment]::GetFolderPath("Desktop"),
        [Environment]::GetFolderPath("CommonDesktopDirectory"),
        [Environment]::GetFolderPath("Programs"),
        (Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar")
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique

    foreach ($dir in $dirs) {
        foreach ($file in @(Get-ChildItem -LiteralPath $dir -Filter *.lnk -Recurse -ErrorAction SilentlyContinue)) {
            try {
                $shortcut = $shell.CreateShortcut($file.FullName)
                if ([string]$shortcut.TargetPath -notlike "*\WorkBuddy.exe") { continue }
                [pscustomobject]@{ Path = $file.FullName; TargetPath = [string]$shortcut.TargetPath }
            } catch {}
        }
    }
}

function New-LauncherFiles {
    $template = @'
$ErrorActionPreference = "Stop"
$logPath = Join-Path $env:LOCALAPPDATA "HeiGeSkinLauncher\launch.log"
function Write-LaunchLog([string]$Message) {
    try {
        ("{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message) |
            Out-File -LiteralPath $logPath -Append -Encoding utf8
    } catch {}
}
try {
    . "__LIBDIR__\common.ps1"
    . "__LIBDIR__\workbuddy-session.ps1"
    $app = Resolve-WorkBuddyApp
    $exe = [string]$app.ExecutablePath
    $port = __PORT__

    $listener = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -ne $listener) {
        Write-LaunchLog "port $port already listening (pid $($listener.OwningProcess)); activating window"
        Start-Process -FilePath $exe -WindowStyle Normal
        return
    }

    $running = @(Get-Process -Name "WorkBuddy" -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        $shell = New-Object -ComObject WScript.Shell
        $answer = $shell.Popup(
            "WorkBuddy 已经在运行，但它不是从换肤入口启动的，没有带上换肤端口，皮肤不会生效。`n`n点「是」= 自动重启并加载皮肤（未发送的内容请先发送）`n点「否」= 保持现状",
            25, "HeiGe 换肤启动器", 4 + 32)
        if ($answer -ne 6) { Write-LaunchLog "user declined restart"; return }
        Write-LaunchLog "closing unskinned instance(s): $($running.Count)"
        foreach ($p in $running) { if ($p.MainWindowHandle -ne 0) { [void]$p.CloseMainWindow() } }
        $deadline = (Get-Date).AddSeconds(10)
        while ((Get-Process -Name "WorkBuddy" -ErrorAction SilentlyContinue) -and ((Get-Date) -lt $deadline)) {
            Start-Sleep -Milliseconds 250
        }
        Get-Process -Name "WorkBuddy" -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800
    }

    $launched = Start-HeiGeWorkBuddyDetachedProcess -ExecutablePath $exe -Port $port
    Write-LaunchLog ("launched pid={0} method={1}" -f $launched.Pid, $launched.Method)
} catch {
    Write-LaunchLog ("ERROR: " + $_.Exception.Message)
}
'@
    $libDir = Join-Path $PSScriptRoot "lib"
    $content = $template.Replace("__LIBDIR__", $libDir).Replace("__PORT__", [string]$Port)
    [System.IO.File]::WriteAllText($launchPs1, $content, (New-Object System.Text.UTF8Encoding($true)))

    $vbsContent = @'
Option Explicit
Dim sh, fso, ps1, cmd
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
ps1 = fso.BuildPath(sh.ExpandEnvironmentStrings("%LOCALAPPDATA%"), "HeiGeSkinLauncher\launch.ps1")
cmd = "conhost.exe --headless powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File """ & ps1 & """"
sh.Run cmd, 0, False
'@
    [System.IO.File]::WriteAllText($launchVbs, $vbsContent, (New-Object System.Text.UTF8Encoding($false)))
}

function Set-ShortcutMode {
    New-LauncherFiles
    $shell = New-Object -ComObject WScript.Shell
    $wscript = Join-Path $env:SystemRoot "System32\wscript.exe"
    $patched = New-Object System.Collections.Generic.List[object]

    foreach ($item in @(Get-WorkBuddyShortcuts)) {
        try {
            $backup = $item.Path + ".heige-bak"
            if (-not (Test-Path -LiteralPath $backup)) {
                Copy-Item -LiteralPath $item.Path -Destination $backup -Force
            }
            $shortcut = $shell.CreateShortcut($item.Path)
            $shortcut.TargetPath = $wscript
            $shortcut.Arguments = '"' + $launchVbs + '"'
            $shortcut.WorkingDirectory = $launcherDir
            $shortcut.IconLocation = $exePath + ",0"
            $shortcut.Description = "WorkBuddy（带换肤启动）"
            $shortcut.Save()
            $patched.Add([pscustomobject]@{ Shortcut = $item.Path; Backup = $backup })
        } catch {}
    }

    if ($patched.Count -eq 0) {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $newPath = Join-Path $desktop "WorkBuddy.lnk"
        $shortcut = $shell.CreateShortcut($newPath)
        $shortcut.TargetPath = $wscript
        $shortcut.Arguments = '"' + $launchVbs + '"'
        $shortcut.WorkingDirectory = $launcherDir
        $shortcut.IconLocation = $exePath + ",0"
        $shortcut.Description = "WorkBuddy（带换肤启动）"
        $shortcut.Save()
        $patched.Add([pscustomobject]@{ Shortcut = $newPath; Backup = $null })
    }
    return @($patched)
}

function Restore-Shortcuts {
    param($Shortcuts)
    $restored = 0
    foreach ($item in @($Shortcuts)) {
        if (-not $item) { continue }
        try {
            if ($item.Backup -and (Test-Path -LiteralPath ([string]$item.Backup) -PathType Leaf)) {
                Copy-Item -LiteralPath ([string]$item.Backup) -Destination ([string]$item.Shortcut) -Force
                Remove-Item -LiteralPath ([string]$item.Backup) -Force
                $restored++
            } elseif (Test-Path -LiteralPath ([string]$item.Shortcut) -PathType Leaf) {
                Remove-Item -LiteralPath ([string]$item.Shortcut) -Force
                $restored++
            }
        } catch {}
    }
    return $restored
}

function Disable-SessionTaskIfPresent {
    $task = Get-ScheduledTask -TaskName $sessionTaskName -ErrorAction SilentlyContinue
    if ($null -eq $task) { return "NotInstalled" }
    $state = [string]$task.State
    if ($state -ceq "Running") { Stop-ScheduledTask -TaskName $sessionTaskName -ErrorAction SilentlyContinue }
    Disable-ScheduledTask -TaskName $sessionTaskName | Out-Null
    return "Disabled"
}

function Enable-SessionTaskIfPresent {
    $task = Get-ScheduledTask -TaskName $sessionTaskName -ErrorAction SilentlyContinue
    if ($null -eq $task) { return "NotInstalled" }
    Enable-ScheduledTask -TaskName $sessionTaskName | Out-Null
    return "Ready"
}

# ---------------------------------------------------------------------------
# 交互菜单
# ---------------------------------------------------------------------------
if (-not $Mode) {
    Write-Host ""
    Write-Host "请选择 WorkBuddy 的启动方式：" -ForegroundColor Cyan
    Write-Host "  1) 手动（推荐）  我点图标才启动，点开就有皮肤；退出就是退出"
    Write-Host "  2) 自动          退出后由后台任务自动拉回来，开机就有皮肤"
    Write-Host "  3) 还原          撤销本脚本的改动，回到官方启动行为"
    Write-Host ""
    $choice = Read-Host "输入 1 / 2 / 3"
    switch ($choice.Trim()) {
        "1" { $Mode = "Manual" }
        "2" { $Mode = "Auto" }
        "3" { $Mode = "Restore" }
        default { throw "无效选择：$choice" }
    }
}

$record = Get-StartupRecord
if ($null -eq $record -or -not $record.BaselineCaptured) {
    # 只在第一次运行时抓取基线，之后无论切换多少次都用这份基线精确回滚。
    $currentEnv = [Environment]::GetEnvironmentVariable($envName, "User")
    $currentRestart = Get-RestartAppsValue
    $record = [pscustomobject]@{
        BaselineCaptured = $true
        BaselineEnvironmentValue = $currentEnv
        BaselineRestartApps = $currentRestart
        BaselineRestartAppsHadValue = ($null -ne $currentRestart)
        CurrentMode = $null
        Shortcuts = @()
    }
}

if ($Mode -eq "Manual") {
    Set-RestartAppsValue -Value 0
    # 先还原上一次改过的快捷方式，避免和本次模式叠加
    [void](Restore-Shortcuts -Shortcuts $record.Shortcuts)

    if ($UseShortcut) {
        [Environment]::SetEnvironmentVariable($envName, $null, "User")
        $patched = Set-ShortcutMode
        $record.Shortcuts = @($patched)
        $shortcutCount = @($patched).Count
        $envText = "未设置（改用快捷方式）"
    } else {
        [Environment]::SetEnvironmentVariable($envName, [string]$Port, "User")
        $record.Shortcuts = @()
        $shortcutCount = 0
        $envText = "$envName=$Port（用户级）"
    }

    $taskState = Disable-SessionTaskIfPresent
    $record.CurrentMode = "Manual"
    Save-StartupRecord -Record $record

    Write-Host ""
    Write-Host "已切换到「手动启动」。" -ForegroundColor Green
    Write-Host ("  环境变量    : " + $envText)
    Write-Host ("  快捷方式改写: " + $shortcutCount + " 个")
    Write-Host ("  会话任务    : " + $taskState + "（不再自动拉起 WorkBuddy）")
    Write-Host  "  登录自启动  : 已关闭 (RestartApps=0)"
    Write-Host ""
    Write-Host "现在做这一步：完全退出 WorkBuddy（托盘也要退），再双击桌面图标。" -ForegroundColor Yellow
    if (-not $UseShortcut) {
        Write-Host "环境变量对已经打开的 explorer 不生效，重启电脑或注销一次之后就固定生效。" -ForegroundColor Yellow
    }
    exit 0
}

if ($Mode -eq "Auto") {
    [Environment]::SetEnvironmentVariable($envName, $null, "User")
    Set-RestartAppsValue -Value 0

    $restored = Restore-Shortcuts -Shortcuts $record.Shortcuts
    $taskState = Enable-SessionTaskIfPresent
    $record.Shortcuts = @()
    $record.CurrentMode = "Auto"
    Save-StartupRecord -Record $record

    Write-Host ""
    Write-Host "已切换到「自动启动」。" -ForegroundColor Green
    Write-Host ("  用户级环境变量: 已清除（改由会话任务注入端口）")
    Write-Host ("  快捷方式还原  : " + $restored + " 个")
    Write-Host ("  会话任务      : " + $taskState)
    Write-Host  "  登录自启动    : 已关闭 (RestartApps=0)，避免抢跑出无端口实例"
    if ($taskState -ceq "NotInstalled") {
        Write-Host "会话任务还没注册：先运行 apply-theme.bat，再回来说一次。" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "下次登录后 WorkBuddy 会由会话任务带端口拉起。" -ForegroundColor Yellow
    exit 0
}

if ($Mode -eq "Restore") {
    if ($null -ne $record.BaselineEnvironmentValue) {
        [Environment]::SetEnvironmentVariable($envName, [string]$record.BaselineEnvironmentValue, "User")
    } else {
        [Environment]::SetEnvironmentVariable($envName, $null, "User")
    }
    if ($record.BaselineRestartAppsHadValue) {
        New-ItemProperty -LiteralPath $winlogon -Name "RestartApps" -PropertyType DWord `
            -Value ([int]$record.BaselineRestartApps) -Force | Out-Null
    } else {
        Remove-ItemProperty -LiteralPath $winlogon -Name "RestartApps" -ErrorAction SilentlyContinue
    }
    $restored = Restore-Shortcuts -Shortcuts $record.Shortcuts
    $taskState = Enable-SessionTaskIfPresent
    Remove-Item -LiteralPath $recordPath -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "已撤销启动方式改动。" -ForegroundColor Green
    Write-Host ("  用户级环境变量: 已清除")
    Write-Host ("  快捷方式还原  : " + $restored + " 个")
    Write-Host ("  登录自启动设置: 已恢复原值")
    Write-Host ("  会话任务      : " + $taskState)
    Write-Host ""
    Write-Host "皮肤本身没有被卸载；要恢复官方界面请运行 restore-official.bat。" -ForegroundColor Yellow
    exit 0
}
