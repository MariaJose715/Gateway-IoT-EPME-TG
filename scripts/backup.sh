#!/usr/bin/env bash
# Comprime los datos y las configuraciones del stack (excluye .env).
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p backups
STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVO="backups/seriot-${STAMP}.tar.gz"

tar -czf "${ARCHIVO}" data config
echo "Respaldo creado: ${ARCHIVO}"
echo "Recuerde guardar .env en un gestor de secretos, no dentro del repositorio."
