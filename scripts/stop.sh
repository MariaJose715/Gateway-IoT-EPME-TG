#!/usr/bin/env bash
# Detiene el stack sin eliminar los datos persistidos.
set -euo pipefail

cd "$(dirname "$0")/.."
docker compose down
echo "Stack detenido. Los datos de ./data se conservan."
