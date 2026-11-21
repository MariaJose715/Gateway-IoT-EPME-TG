# Levanta el stack completo del Gateway IoT EPME-TG en Windows.
$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker no está instalado o no está en el PATH."
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Se creó .env a partir de .env.example." -ForegroundColor Yellow
    Write-Host "Edite .env y defina contraseñas y token antes de continuar." -ForegroundColor Yellow
    exit 1
}

New-Item -ItemType Directory -Force -Path "data\mosquitto", "data\influxdb", "data\grafana" | Out-Null

docker compose up -d
docker compose ps

Write-Host ""
Write-Host "Servicios disponibles:" -ForegroundColor Green
Write-Host "  Node-RED  http://localhost:1880"
Write-Host "  InfluxDB  http://localhost:8086"
Write-Host "  Grafana   http://localhost:3000"
Write-Host ""
Write-Host "Siguiente paso: configure el nodo InfluxDB en Node-RED con el token de .env."
