#!/usr/bin/env bash
# Verifica el estado del stack y de los servicios principales.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  # shellcheck disable=SC1091
  set -a
  . ./.env
  set +a
fi

echo "== Estado de los contenedores =="
docker compose ps

echo ""
echo "== Salud de los servicios =="
printf "InfluxDB : "
curl -fsS http://localhost:8086/health | head -c 200 || echo "sin respuesta"
echo ""
printf "Grafana  : "
curl -fsS http://localhost:3000/api/health | head -c 200 || echo "sin respuesta"
echo ""
printf "Node-RED : "
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:1880/ || echo "sin respuesta"

echo ""
echo "== Prueba MQTT =="
docker compose exec -T mosquitto \
  mosquitto_pub -h localhost -t datos \
  -m '{"voltaje":121.5,"corriente":5.2,"energia":12.34,"timestamp":"2026-11-20T15:30:00-05:00"}'
echo "Mensaje de prueba publicado en el tópico «datos»."
