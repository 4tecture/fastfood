$ErrorActionPreference = 'Stop'

Write-Warning 'This compatibility script starts only shared infrastructure. Use src/start-compose.ps1 for the full application.'
& "$PSScriptRoot/../src/start-compose.ps1" -d rabbitmq redis placement scheduler sentry dapr-dashboard otel-collector grafana jaeger loki prometheus proxy docker-socket-proxy sqldb
