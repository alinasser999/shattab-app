param(
  [switch]$RequirePublicMediaRollout
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'release_check.ps1') `
  -RequireReleaseCredentials `
  -RequirePublicMediaRollout:$RequirePublicMediaRollout
if ($LASTEXITCODE -ne 0) {
  throw "Release credential gate failed with exit code $LASTEXITCODE"
}

Write-Host 'Release credential gate passed.'
