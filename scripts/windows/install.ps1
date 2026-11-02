param([switch]$SkipApply)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$sourceRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$expectedInstallRoot = [IO.Path]::GetFullPath((Join-Path $env:USERPROFILE ".workbuddy\heige-codex-skin-studio"))
$installRoot = $expectedInstallRoot
$sourceFull = [IO.Path]::GetFullPath($sourceRoot)

$node = Get-Command node.exe -ErrorAction SilentlyContinue
if ($null -eq $node) { throw "Node.js was not found. Install Node.js 22 or newer first." }
$versionText = (& $node.Source --version 2>$null | Select-Object -First 1)
if ($versionText -notmatch '^v(\d+)\.') { throw "Cannot read the Node.js version: $versionText" }
if ([int]$Matches[1] -lt 22) { throw "Node.js is too old: $versionText. Version 22 or newer is required." }

if ($sourceFull -ine $installRoot) {
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    foreach ($directory in @("src", "scripts", "themes")) {
        $destination = [IO.Path]::GetFullPath((Join-Path $installRoot $directory))
        if (-not $destination.StartsWith($installRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Install destination escaped the approved root: $destination"
        }
        if (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination -Recurse -Force }
        Copy-Item -LiteralPath (Join-Path $sourceFull $directory) -Destination $destination -Recurse -Force
    }
    foreach ($file in @("package.json", "package-lock.json", "LICENSE", "NOTICE.md", "README.md", "README.en.md", "SECURITY.md", "ASSET_PROVENANCE.md")) {
        Copy-Item -LiteralPath (Join-Path $sourceFull $file) -Destination (Join-Path $installRoot $file) -Force
    }
}

Write-Host "Install root: $installRoot"
Write-Host "Node.js: $versionText"
Write-Host "WorkBuddy files are unchanged; this project uses only 127.0.0.1:9342."
if (-not $SkipApply) {
    & (Join-Path $installRoot "scripts\windows\workbuddy-apply.ps1") -Theme "open-source-placeholder"
}
Write-Host "Installation completed."
