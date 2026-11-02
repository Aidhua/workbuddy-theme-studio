$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = Split-Path $PSScriptRoot -Parent
$errors = @()
Get-ChildItem -LiteralPath $root -Recurse -Filter *.ps1 -File | ForEach-Object {
    $tokens = $null
    $parseErrors = $null
    [Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    foreach ($parseError in @($parseErrors)) { $errors += "$($_.FullName): $($parseError.Message)" }
}
if ($errors.Count -gt 0) { throw ($errors -join [Environment]::NewLine) }
& node --test
if ($LASTEXITCODE -ne 0) { throw "Node tests failed." }
& node (Join-Path $root "scripts\audit-release.mjs")
if ($LASTEXITCODE -ne 0) { throw "Release audit failed." }
Write-Host "PowerShell syntax, Node tests, privacy scan, secret scan and file audit passed."
