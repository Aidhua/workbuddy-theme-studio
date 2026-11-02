param(
    [Parameter(Mandatory = $true)][string]$ExecutablePath,
    [ValidateRange(0, 65535)][int]$Port = 0
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\common.ps1")
. (Join-Path $PSScriptRoot "lib\workbuddy-session.ps1")

$app = Resolve-WorkBuddyApp
$expected = [System.IO.Path]::GetFullPath([string]$app.ExecutablePath)
$requested = [System.IO.Path]::GetFullPath($ExecutablePath)
if (
    [string]$app.Kind -cne "Win32" -or
    [string]$app.ProductName -cne "WorkBuddy" -or
    $requested -cne $expected
) {
    throw "WorkBuddy session host executable does not match the verified app identity."
}

# 保活触发器可能在会话宿主异常退出、但 WorkBuddy 主进程仍然存活时重启本脚本。
# Electron 单实例会让此时新启动的占位进程立即退出，任务也就无法继续陪跑。
# 只有当指定 CDP 端口的监听者经路径校验确实是目标 WorkBuddy 时才重新附着；
# 无端口、端口被占或身份不匹配时，仍走下面的原始安全启动路径。
if ($Port -gt 0) {
    $listener = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -ne $listener -and [int]$listener.OwningProcess -gt 0) {
        $existing = Get-Process -Id ([int]$listener.OwningProcess) -ErrorAction SilentlyContinue
        if ($null -ne $existing -and -not [string]::IsNullOrWhiteSpace([string]$existing.Path)) {
            $existingPath = [System.IO.Path]::GetFullPath([string]$existing.Path)
            if ($existingPath -ceq $expected) {
                Wait-Process -Id ([int]$existing.Id)
                return
            }
        }
    }
}

# 会话任务只负责把 WorkBuddy 以脱离控制台的方式拉起并陪跑到它退出，
# 这样任务计划程序的控制台或调用终端都不会成为 WorkBuddy 的生命周期宿主。
$launched = Start-HeiGeWorkBuddyDetachedProcess -ExecutablePath $expected -Port $Port
if ([int]$launched.Pid -le 0) {
    throw "WorkBuddy session host could not start the verified executable."
}
Wait-Process -Id ([int]$launched.Pid)
