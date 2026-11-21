#!/usr/bin/env bash
# Publica una muestra de telemetría en el tópico «datos».
set -euo pipefail

cd "$(dirname "$0")/.."
TS="$(date +%Y-%m-%dT%H:%M:%S%z)"
PAYLOAD="{\"voltaje\":121.5,\"corriente\":5.2,\"energia\":12.34,\"timestamp\":\"${TS}\"}"

docker compose exec -T mosquitto \
  mosquitto_pub -h localhost -t datos -q 1 -m "${PAYLOAD}"

echo "Publicado: ${PAYLOAD}"
