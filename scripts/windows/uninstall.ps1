$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

try { & (Join-Path $PSScriptRoot "workbuddy-restore.ps1") } catch { Write-Warning $_.Exception.Message }
foreach ($taskName in @("HeiGe WorkBuddy Skin Studio Controller", "HeiGe WorkBuddy Skin Session")) {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
    }
}
$base = [IO.Path]::GetFullPath((Join-Path $env:USERPROFILE ".workbuddy"))
$targets = @(
    [IO.Path]::GetFullPath((Join-Path $base "heige-codex-skin-studio")),
    [IO.Path]::GetFullPath((Join-Path $base "HeiGeCodexSkinStudio-workbuddy"))
)
foreach ($target in $targets) {
    if (-not $target.StartsWith($base + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Uninstall target escaped the approved root: $target"
    }
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
}
Write-Host "Uninstall completed. Project tasks, state, themes, and installed copy were removed. WorkBuddy files were unchanged."
