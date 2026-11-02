param([ValidatePattern('^[a-z0-9][a-z0-9-]{0,63}$')][string]$Theme = "open-source-placeholder")
$ErrorActionPreference = "Stop"
& (Join-Path $PSScriptRoot "workbuddy-apply.ps1") -Theme $Theme
