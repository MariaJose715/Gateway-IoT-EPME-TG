#!/usr/bin/env bash
# Levanta el stack completo del Gateway IoT EPME-TG.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker no está instalado o no está en el PATH." >&2
  exit 1
fi

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Se creó .env a partir de .env.example."
  echo "Edite .env y defina contraseñas y token antes de continuar."
  exit 1
fi

mkdir -p data/mosquitto data/influxdb data/grafana

docker compose up -d
docker compose ps

echo ""
echo "Servicios disponibles:"
echo "  Node-RED  http://localhost:1880"
echo "  InfluxDB  http://localhost:8086"
echo "  Grafana   http://localhost:3000"
echo ""
echo "Siguiente paso: configure el nodo InfluxDB en Node-RED con el token de .env."
