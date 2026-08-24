$ErrorActionPreference = 'Stop'

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$localEnvironment = Join-Path $scriptDirectory '.env'
$legacyLocalEnvironment = Join-Path $scriptDirectory '.env.local'
$certificateScriptDirectory = Join-Path $scriptDirectory '../infrastructure-dev/dapr/certs'
$certDirectory = Join-Path $certificateScriptDirectory 'generated'
$fullComposeFile = Join-Path $scriptDirectory 'docker-compose.full.yml'
$fullMode = $args -contains '--full'
$passThroughArguments = @($args | Where-Object { $_ -ne '--full' })

foreach ($tool in @('docker', 'step', 'mkcert')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "Missing prerequisite: $tool"
    }
}

if (-not (Test-Path $localEnvironment)) {
    if (Test-Path $legacyLocalEnvironment) {
        Copy-Item $legacyLocalEnvironment $localEnvironment
        Write-Host 'Migrated local Compose secrets from .env.local to .env'
    }
    else {
        $randomBytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(24)
        $randomPart = [Convert]::ToHexString($randomBytes).ToLowerInvariant()
        "MSSQL_SA_PASSWORD=FastFood-$randomPart!A" | Set-Content -Path $localEnvironment -Encoding utf8NoBOM
        Write-Host "Created local-only Compose secrets in $localEnvironment"
    }
}

$certificateFiles = @('ca.crt', 'ca.key', 'issuer.crt', 'issuer.key', 'mtls.env')
$certificatesMissing = $certificateFiles.Where({
    $path = Join-Path $certDirectory $_
    -not (Test-Path $path) -or (Get-Item $path).Length -eq 0
}).Count -gt 0
$rotateCertificates = $env:FASTFOOD_ROTATE_CERTIFICATES -eq 'true'

if ($rotateCertificates -or $certificatesMissing) {
    New-Item -ItemType Directory -Path $certDirectory -Force | Out-Null
    & step certificate create cluster.local "$certDirectory/ca.crt" "$certDirectory/ca.key" `
        --profile root-ca --no-password --insecure --force
    & step certificate create cluster.local "$certDirectory/issuer.crt" "$certDirectory/issuer.key" `
        --ca "$certDirectory/ca.crt" --ca-key "$certDirectory/ca.key" `
        --profile intermediate-ca --not-after 8760h --no-password --insecure --force
    & "$certificateScriptDirectory/generate-env.ps1" -CertsPath $certDirectory
}
else {
    Write-Host 'Using existing local Dapr certificates. Set FASTFOOD_ROTATE_CERTIFICATES=true to rotate them.'
}

$proxyCertificateDirectory = Join-Path $scriptDirectory '../infrastructure-dev/proxy/certs'
$proxyCertificateFiles = @('_wildcard.localtest.me.pem', '_wildcard.localtest.me-key.pem')
$proxyCertificatesMissing = $proxyCertificateFiles.Where({
    $path = Join-Path $proxyCertificateDirectory $_
    -not (Test-Path $path) -or (Get-Item $path).Length -eq 0
}).Count -gt 0
if ($rotateCertificates -or $proxyCertificatesMissing) {
    & "$proxyCertificateDirectory/generate.ps1"
}
else {
    Write-Host 'Using existing local Traefik certificate.'
}

$composeArguments = @(
    '--env-file', $localEnvironment,
    '--file', "$scriptDirectory/docker-compose.yml"
)
if ($fullMode) {
    $composeArguments += @('--file', $fullComposeFile, '--profile', 'full')
    Write-Host 'Starting the full stack (SQL and observability enabled).'
}
else {
    Write-Host 'Starting the simplified HOL stack. Use --full for SQL and observability.'
}

& docker compose @composeArguments up --build @passThroughArguments
