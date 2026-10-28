param([switch]$Demo)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectDirectory

function New-LocalSecret {
    $bytes = New-Object byte[] 32
    $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $generator.GetBytes($bytes) } finally { $generator.Dispose() }
    return [Convert]::ToBase64String($bytes)
}

if (-not (Test-Path -LiteralPath '.env')) {
    $configText = Get-Content -LiteralPath '.env.example' -Raw -Encoding UTF8
    $configText = $configText.Replace('MYSQL_PASSWORD=troque_esta_senha', 'MYSQL_PASSWORD=' + (New-LocalSecret))
    $configText = $configText.Replace('MYSQL_ROOT_PASSWORD=troque_esta_senha_root', 'MYSQL_ROOT_PASSWORD=' + (New-LocalSecret))
    $configText = [regex]::Replace($configText, '(?m)^# ADMIN_USERNAME=.*$', 'ADMIN_USERNAME=admin')
    foreach ($secretName in @('ADMIN_PASSWORD', 'ADMIN_TOKEN_SECRET', 'HARDWARE_API_KEY')) {
        $configText = [regex]::Replace($configText, '(?m)^# ' + $secretName + '=.*$', $secretName + '=' + (New-LocalSecret))
    }
    [System.IO.File]::WriteAllText((Join-Path $projectDirectory '.env'), $configText, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host 'Created private .env with random credentials. Keep it outside Git.'
} else {
    Write-Host 'Existing .env preserved.'
}

docker compose config --quiet
if ($LASTEXITCODE -ne 0) { throw 'Complete the required configuration in .env.' }
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { throw 'Docker startup failed. Review docker compose logs.' }
if ($Demo) {
    docker compose --profile demo run --rm seed
    if ($LASTEXITCODE -ne 0) { throw 'Demo seed failed.' }
}
Write-Host 'Open http://localhost:8080 (or WEB_PORT configured in .env).'
Write-Host 'Administrator: admin (unless customized), password: ADMIN_PASSWORD from .env.'
Write-Host 'Authorize the terminal in the login form before RFID-only teacher access.'
