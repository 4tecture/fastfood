$ErrorActionPreference = 'Stop'

if (-not (Get-Command mkcert -ErrorAction SilentlyContinue)) {
    throw 'mkcert is required: https://github.com/FiloSottile/mkcert'
}

$certificateDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
& mkcert `
    -cert-file "$certificateDirectory/_wildcard.localtest.me.pem" `
    -key-file "$certificateDirectory/_wildcard.localtest.me-key.pem" `
    '*.localtest.me'

Write-Host "Generated local-only Traefik TLS material in $certificateDirectory"
