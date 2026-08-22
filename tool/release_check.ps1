param(
  [switch]$RequireReleaseCredentials,
  [switch]$RequirePublicMediaRollout
)

$ErrorActionPreference = 'Stop'

function Invoke-Checked($FilePath, $Arguments) {
  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$FilePath failed with exit code $LASTEXITCODE"
  }
}

function Require-File($Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing release input: $Path"
  }
}

Write-Host 'Shattab release preflight'
Require-File '.env'

Write-Host 'Running static security contract checks...'
& (Join-Path $PSScriptRoot 'security_contract_check.ps1')
if (-not $?) {
  throw 'Security contract checks failed.'
}

$envText = Get-Content -Raw '.env'
foreach ($name in @('SUPABASE_URL', 'SUPABASE_ANON_KEY')) {
  if ($envText -notmatch "(?m)^$name=.+$") {
    throw "Missing required environment value: $name"
  }
}

if ($envText -match '(?m)^(SUPABASE_SERVICE_ROLE_KEY|SUPABASE_SECRET_KEY)=') {
  throw 'A service-role/secret Supabase key must never be shipped in the Flutter .env.'
}

$pushConfigured = (Test-Path 'android/app/google-services.json') -or
  (Test-Path 'ios/Runner/GoogleService-Info.plist')
if (-not $pushConfigured) {
  $message = 'Native Firebase config is missing. In-app/realtime notifications work, but FCM push is not release-ready.'
  if ($RequireReleaseCredentials) { throw $message }
  Write-Warning $message
}

if (-not (Test-Path 'android/key.properties')) {
  $message = 'android/key.properties is missing. Android release signing is not configured.'
  if ($RequireReleaseCredentials) { throw $message }
  Write-Warning $message
}

$r2Enabled = $envText -match '(?m)^R2_PUBLIC_MEDIA_ENABLED=true$'
$r2Signer = $envText -match '(?m)^R2_SIGNER_URL=\S+'
$r2Public = $envText -match '(?m)^R2_PUBLIC_BASE_URL=\S+'
$r2Categories = $envText -match '(?m)^R2_PUBLIC_MEDIA_CATEGORIES=\S+'
if ($r2Enabled -and (-not ($r2Signer -and $r2Public -and $r2Categories))) {
  throw 'R2_PUBLIC_MEDIA_ENABLED=true requires R2_SIGNER_URL, R2_PUBLIC_BASE_URL, and at least one approved category.'
}
if ($RequirePublicMediaRollout -and (-not $r2Enabled)) {
  throw 'R2 public media rollout was required but R2_PUBLIC_MEDIA_ENABLED is not true.'
}

Write-Host 'Running generated-code, analyzer, tests, and web build checks...'
Invoke-Checked 'C:\flutter\bin\dart.bat' @('run', 'build_runner', 'build')
Invoke-Checked 'C:\flutter\bin\flutter.bat' @('analyze', '--no-pub')
Invoke-Checked 'C:\flutter\bin\flutter.bat' @('test', '--no-pub')
Invoke-Checked 'C:\flutter\bin\flutter.bat' @('build', 'web', '--release', '--no-wasm-dry-run')

if (Test-Path 'admin/package.json') {
  Push-Location admin
  try {
    Invoke-Checked 'npm' @('run', 'typecheck')
    Invoke-Checked 'npm' @('run', 'audit:contracts')
    Invoke-Checked 'npm' @('run', 'build')
  } finally {
    Pop-Location
  }
}

if (Test-Path 'infra/media-signer/package.json') {
  Push-Location infra/media-signer
  try {
    Invoke-Checked 'npm' @('run', 'typecheck')
    Invoke-Checked 'npm' @('run', 'test')
  } finally {
    Pop-Location
  }
}

Write-Host 'Release preflight passed. Review warnings above before store submission.'
