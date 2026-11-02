$script:HeiGeWorkBuddySessionTaskName = "HeiGe WorkBuddy Skin Session"

function Remove-HeiGeWorkBuddySessionTask {
    $task = Get-ScheduledTask -TaskName $script:HeiGeWorkBuddySessionTaskName `
        -ErrorAction SilentlyContinue
    if ($null -eq $task) { return }
    if ([string]$task.State -ceq "Running") {
        Stop-ScheduledTask -TaskName $script:HeiGeWorkBuddySessionTaskName `
            -ErrorAction SilentlyContinue
    }
    Unregister-ScheduledTask -TaskName $script:HeiGeWorkBuddySessionTaskName `
        -Confirm:$false -ErrorAction SilentlyContinue
}

function Start-HeiGeWorkBuddyScheduledSession {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutablePath,
        [ValidateRange(0, 65535)][int]$Port = 0
    )
    Remove-HeiGeWorkBuddySessionTask
    $hostScript = Join-Path (Split-Path $PSScriptRoot -Parent) "workbuddy-session-host.ps1"
    if (-not (Test-Path -LiteralPath $hostScript -PathType Leaf)) {
        throw "WorkBuddy session host script is missing: $hostScript"
    }
    foreach ($item in @($ExecutablePath, $hostScript)) {
        if ([string]$item -match '[\r\n"]') {
            throw "WorkBuddy session task path contains unsupported characters."
        }
    }
    $powershell = Join-Path $PSHOME "powershell.exe"
    $conhost = Join-Path $env:SystemRoot "System32\conhost.exe"
    if (-not (Test-Path -LiteralPath $conhost -PathType Leaf)) {
        throw "Windows conhost.exe is missing; refusing to create a visible background session."
    }
    $arguments = '--headless "' + $powershell + '" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass ' +
        '-File "' + $hostScript + '" -ExecutablePath "' + $ExecutablePath +
        '" -Port ' + [string]$Port
    $action = New-ScheduledTaskAction -Execute $conhost -Argument $arguments
    $userName = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $principal = New-ScheduledTaskPrincipal -UserId $userName -LogonType Interactive `
        -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew `
        -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero)
    # 只注册不挂触发器的话，重启后会话任务不会自启，Auto 模式就等于失效。
    # 与控制器任务保持同一套：登录触发 + Once/PT1M 保活，IgnoreNew 防止并发。
    $logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $userName
    $keepAliveTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(-1) `
        -RepetitionInterval (New-TimeSpan -Minutes 1) `
        -RepetitionDuration (New-TimeSpan -Days 3650)
    Register-ScheduledTask -TaskName $script:HeiGeWorkBuddySessionTaskName `
        -Action $action -Principal $principal -Settings $settings `
        -Trigger @($logonTrigger, $keepAliveTrigger) -Force | Out-Null
    Start-ScheduledTask -TaskName $script:HeiGeWorkBuddySessionTaskName
    return [pscustomobject][ordered]@{
        Pid = 0
        Method = "scheduled-session"
        TaskName = $script:HeiGeWorkBuddySessionTaskName
    }
}

function Initialize-HeiGeWorkBuddySessionLauncher {
    if ("HeiGe.WorkBuddySessionProcess" -as [type]) { return }
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace HeiGe {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct WorkBuddyStartupInfo {
        public int cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public int dwX;
        public int dwY;
        public int dwXSize;
        public int dwYSize;
        public int dwXCountChars;
        public int dwYCountChars;
        public int dwFillAttribute;
        public int dwFlags;
        public short wShowWindow;
        public short cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput;
        public IntPtr hStdOutput;
        public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct WorkBuddyProcessInfo {
        public IntPtr hProcess;
        public IntPtr hThread;
        public int dwProcessId;
        public int dwThreadId;
    }

    public static class WorkBuddySessionProcess {
        // DETACHED_PROCESS 是关键：没有它，WorkBuddy 会继承启动器的控制台，
        // 控制台窗口里会刷 WorkBuddy 的日志，关掉窗口时 CTRL_CLOSE_EVENT 还会把
        // WorkBuddy 一起结束。脱钩后启动器窗口关不关都与 WorkBuddy 无关。
        public const uint DetachedProcess = 0x00000008;
        public const uint CreateNewProcessGroup = 0x00000200;
        public const uint CreateBreakawayFromJob = 0x01000000;

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool CreateProcess(
            string lpApplicationName,
            StringBuilder lpCommandLine,
            IntPtr lpProcessAttributes,
            IntPtr lpThreadAttributes,
            bool bInheritHandles,
            uint dwCreationFlags,
            IntPtr lpEnvironment,
            string lpCurrentDirectory,
            ref WorkBuddyStartupInfo lpStartupInfo,
            out WorkBuddyProcessInfo lpProcessInformation);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr hObject);

        public static bool Launch(string applicationName, bool breakaway, out int pid, out int win32Error) {
            var si = new WorkBuddyStartupInfo();
            si.cb = Marshal.SizeOf(typeof(WorkBuddyStartupInfo));
            WorkBuddyProcessInfo pi;
            uint flags = DetachedProcess | CreateNewProcessGroup;
            if (breakaway) flags |= CreateBreakawayFromJob;
            var commandLine = new StringBuilder("\"" + applicationName + "\"");
            var workingDirectory = System.IO.Path.GetDirectoryName(applicationName);
            if (!CreateProcess(applicationName, commandLine, IntPtr.Zero, IntPtr.Zero, false,
                flags, IntPtr.Zero, workingDirectory, ref si, out pi)) {
                pid = 0;
                win32Error = Marshal.GetLastWin32Error();
                return false;
            }
            pid = pi.dwProcessId;
            win32Error = 0;
            if (pi.hThread != IntPtr.Zero) CloseHandle(pi.hThread);
            if (pi.hProcess != IntPtr.Zero) CloseHandle(pi.hProcess);
            return pid > 0;
        }
    }
}
"@
}

function Assert-HeiGeWorkBuddySessionTarget {
    param([Parameter(Mandatory = $true)][string]$ExecutablePath)

    $resolved = [System.IO.Path]::GetFullPath($ExecutablePath)
    if (
        [System.IO.Path]::GetFileName($resolved) -cne "WorkBuddy.exe" -or
        -not (Test-Path -LiteralPath $resolved -PathType Leaf)
    ) {
        throw "Verified WorkBuddy executable is unavailable: $resolved"
    }
    if ($resolved -match '[\r\n"]') {
        throw "WorkBuddy executable path contains unsupported characters."
    }
    return $resolved
}

function Start-HeiGeWorkBuddyDetachedProcess {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutablePath,
        [ValidateRange(0, 65535)][int]$Port = 0
    )
    $resolved = Assert-HeiGeWorkBuddySessionTarget -ExecutablePath $ExecutablePath
    Initialize-HeiGeWorkBuddySessionLauncher

    $previousPort = $env:WORKBUDDY_REMOTE_DEBUGGING_PORT
    try {
        if ($Port -gt 0) {
            $env:WORKBUDDY_REMOTE_DEBUGGING_PORT = [string]$Port
        } else {
            Remove-Item Env:WORKBUDDY_REMOTE_DEBUGGING_PORT -ErrorAction SilentlyContinue
        }
        [int]$pidValue = 0
        [int]$win32Error = 0
        $method = "breakaway"
        $ok = [HeiGe.WorkBuddySessionProcess]::Launch(
            $resolved, $true, [ref]$pidValue, [ref]$win32Error
        )
        if (-not $ok) {
            # 宿主作业不允许脱离时再试一次不带 BREAKAWAY 的启动。
            $method = "detached"
            $ok = [HeiGe.WorkBuddySessionProcess]::Launch(
                $resolved, $false, [ref]$pidValue, [ref]$win32Error
            )
        }
    } finally {
        $env:WORKBUDDY_REMOTE_DEBUGGING_PORT = $previousPort
    }
    if (-not $ok -or $pidValue -le 0) {
        return [pscustomobject][ordered]@{
            Pid = 0
            Method = "unavailable"
            Win32Error = [int]$win32Error
        }
    }
    return [pscustomobject][ordered]@{
        Pid = [int]$pidValue
        Method = $method
        Win32Error = 0
    }
}

function Start-HeiGeWorkBuddySession {
    param(
        [Parameter(Mandatory = $true)]$AppInfo,
        [ValidateRange(0, 65535)][int]$Port = 0
    )

    if (
        [string]$AppInfo.Kind -cne "Win32" -or
        [string]$AppInfo.ProductName -cne "WorkBuddy"
    ) {
        throw "WorkBuddy session launcher requires the verified Win32 WorkBuddy identity."
    }
    $resolved = Assert-HeiGeWorkBuddySessionTarget `
        -ExecutablePath ([string]$AppInfo.ExecutablePath)

    $launched = Start-HeiGeWorkBuddyDetachedProcess -ExecutablePath $resolved -Port $Port
    if ($launched.Pid -gt 0) { return $launched }
    return Start-HeiGeWorkBuddyScheduledSession -ExecutablePath $resolved -Port $Port
}
